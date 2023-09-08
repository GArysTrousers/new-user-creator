Import-Module ./Password-Generator.ps1 -Force
$TextInfo = (Get-Culture).TextInfo

$runLog = ''
$config = Get-Content .\config.conf | ConvertFrom-StringData
$students = Import-Csv $config.eduhubFilePath
$props = @("DisplayName", "EmailAddress", "MemberOf")
$newStudents = @()
$yearLevelGroups = @()
for ($i = 0; $i -le 12; $i++) { 
  $yearLevelGroups += "CN=Year {0:d2},{1}" -f $i, $config.yearLevelGroupOU 
}
$yearLevelOUs = @()
for ($i = 0; $i -le 12; $i++) { 
  $yearLevelOUs += "OU=Year {0:d2},{1}" -f $i, $config.studentOU 
}

try {
  foreach ($stu in $students) {
    try {
      $curStu = "({0}) {1} {2}" -f $stu.STKEY, $stu.FIRST_NAME, $stu.SURNAME
      $log = ""
      $err = ""
      switch ($stu.STATUS) {
        "ACTV" { 
          $surname = $TextInfo.ToTitleCase($stu.SURNAME.ToLower())
          $name = ('{0} {1} ({2})' -f $stu.PREF_NAME, $surname, $stu.STKEY)
          $userData = @{
            GivenName         = $stu.FIRST_NAME
            Surname           = $surname
            DisplayName       = '{0} {1}' -f $stu.PREF_NAME, $surname
            SamAccountName    = $stu.STKEY
            UserPrincipalName = '{0}@{1}' -f $stu.STKEY, $config.domainEmail
            EmailAddress      = '{0}@{1}' -f $stu.STKEY, $config.domainEmail
          }
          try {
            $user = Get-ADUser -Identity $stu.STKEY -Properties $props -ErrorAction Stop
            $log += " [Exists]"
          }
          catch {
            $log += " [Not Exists] <Making account>"
            New-ADUser -Name $name -Path $yearLevelOUs[$stu.SCHOOL_YEAR] @userData
            $userFound = $false
            while ($count -le $config.newAccountWaitTime -and $userFound -eq $false) {
              Start-Sleep -Seconds 1
              $log += '.'
              try {
                $user = Get-ADUser -Identity $stu.STKEY -Properties $props -ErrorAction Stop
                $userFound = $true
              }
              catch {
                $count += 1
              }
            }
            if ($userFound -eq $false) {
              $log += "[Waiting for account took too long]"
              break
            }
          }

          # Check to see if user info needs updating
          $updateUser = $false
          foreach ($data in $userData.GetEnumerator()) {
            if ($user[$data.Key] -cne $data.Value) {
              $updateUser = $true
              break
            }
          }
          if ($updateUser) {
            $log += " <Updating Profile>"
            $userData["Identity"] = $stu.STKEY
            Set-ADUser @userData
          }
          if ($user.Enabled -eq $false) {
            $log += " <Setting Password>"
            $newPassword = Get-Password -Base $stu.STKEY -Pattern $config.passwordPattern -Salt $config.passwordSalt
            Set-ADAccountPassword -Identity $stu.STKEY -Reset -NewPassword (ConvertTo-SecureString $newPassword -AsPlainText -Force)
            "{0},{1}" -f $stu.STKEY, $newPassword | Out-File $config.newAccountFile -Append
            $userData["Password"] = $newPassword
            $newStudents += $userData
            $log += " <Enabling Account>"
            $user | Enable-ADAccount
          }

          # Add Student Group
          if ($user.MemberOf -notcontains $config.studentGroup) {
            $log += " <Adding Student Group>"
            Add-ADGroupMember $config.studentGroup -Members $user
          }
          # Add Year Level Group
          if ($user.MemberOf -notcontains $yearLevelGroups[$stu.SCHOOL_YEAR]) {
            $log += " <Adding Year Level Group>"
            $user.MemberOf | Where-Object { $yearLevelGroups -contains $_ } | ForEach-Object { 
              $log += " <Removing Old Group>"
              Remove-ADGroupMember $_ -Members $user -Confirm:$false
            } # remove any current year groups
            Add-ADGroupMember $yearLevelGroups[$stu.SCHOOL_YEAR] -Members $stu.STKEY
          }

          # User Object Location
          if ($user.DistinguishedName -match 'CN=[^,]+,(.+)') {
            if ($Matches.1 -ne $yearLevelOUs[$stu.SCHOOL_YEAR]) {
              $log += " <Moving to OU>"
              Move-ADObject $user.DistinguishedName -TargetPath $yearLevelOUs[$stu.SCHOOL_YEAR]
            }
          }
        }
        "LEFT" { 
          try {
            $user = Get-ADUser -Identity $stu.STKEY -ErrorAction Stop
            $log += " [Exists]"
          }
          catch {
            $log += " [Not in AD]"
            break
          }
          if ($user.Enabled -eq $true) {
            $log += " <Disabling account>"
            $user | Disable-ADAccount
          }
          if ($user.DistinguishedName -match 'CN=[^,]+,(.+)') {
            if ($Matches.1 -ne $config.inactiveStudentOU) {
              $log += " <Moving to inactive OU>"
              Move-ADObject $user.DistinguishedName -TargetPath $config.inactiveStudentOU
            }
          }
        }
      }
    }
    catch {
      $err = $_
    }
    finally {
      switch ($stu.STATUS) {
        "ACTV" { 
          Write-Host ("{0,-35} {1}" -f $curStu, $stu.STATUS) -ForegroundColor Green -NoNewline
          Write-Host $log
          $runLog += "{0,-35} {1}{2}`n" -f $curStu, $stu.STATUS, $log
        }
        "LEFT" { 
          Write-Host ("{0,-35} {1}" -f $curStu, $stu.STATUS) -ForegroundColor Red -NoNewline
          Write-Host $log
          $runLog += "{0,-35} {1}{2}`n" -f $curStu, $stu.STATUS, $log
        }
      }
      if ($err -ne "") {
        Write-Error $err
        $runLog += "Error: $err`n"
      }
    }
  }
}
catch {
  $runLog += "Error Ended Program:`n"
  $runLog += $_
}
finally {
  $runLog | Out-File $config.logFile
  Write-Host ("Log File Saved: {0}" -f $config.logFile)
  if (Test-Path "On-Finished.ps1") {
    & "On-Finished.ps1" -Config $config -NewStudents $newStudents
  }
}
