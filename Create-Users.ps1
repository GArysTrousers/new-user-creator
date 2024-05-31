Import-Module ActiveDirectory -Force
Import-Module ./Password-Generator.ps1 -Force
$TextInfo = (Get-Culture).TextInfo

$runLog = ''
$config = Get-Content .\config.conf | ConvertFrom-StringData
$students = Import-Csv $config.eduhubFilePath
$props = @("DisplayName", "EmailAddress", "MemberOf", "HomeDirectory", "HomeDrive")
$newStudents = @()
$yearLevelGroups = @()
for ($i = 0; $i -le 12; $i++) { 
  $yearLevelGroups += "CN=Year {0:d2},{1}" -f $i, $config.yearLevelGroupOU 
}
$yearLevelOUs = @()
for ($i = 0; $i -le 12; $i++) { 
  $yearLevelOUs += "OU=Year {0:d2},{1}" -f $i, $config.studentOU 
}
$inactivePath = $config.homeDriveDir + "\Inactive"
if ((Test-Path $inactivePath) -eq $false) {
  New-Item -ItemType Directory -Path $inactivePath | Out-Null
}

try {
  foreach ($stu in $students) {
    try {
      $curStu = "({0}) {1} {2}" -f $stu.STKEY, $stu.FIRST_NAME, $stu.SURNAME
      $log = ""
      $err = ""
      $user = $null
      $userData = $null
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
            HomeDirectory     = '{0}\{1}' -f $config.homeDriveDir, $stu.STKEY
            HomeDrive         = "Y:"
          }
          try {
            $user = Get-ADUser -Identity $stu.STKEY -Properties $props -ErrorAction Stop
            $log += " [Exists   ]"
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
            $userData["YearLevel"] = $stu.SCHOOL_YEAR
            $newStudents += $userData
            $log += " <Enabling Account>"
            $user | Enable-ADAccount
          }

          # Add Folder if it doesn't exist
          if ((Test-Path $userData.HomeDirectory) -eq $false) {
            $log += " <Creating Directory>"
            New-Item -ItemType Directory -Path $userData.HomeDirectory | Out-Null
          }
          # Check/Set the Permissions
          $acl = New-Object System.Security.AccessControl.DirectorySecurity
          $acl.SetAccessRuleProtection($true, $false) # Disable Inherited Permissions
          $acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule "NT AUTHORITY\SYSTEM", "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow"))
          $acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule "$($config.domainPrefix)\Domain Admins", "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow"))
          $acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule "$($config.domainPrefix)\$($config.staffGroupName)", "Read", "ContainerInherit, ObjectInherit", "None", "Allow"))
          $acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule "$($config.domainPrefix)\$($stu.STKEY)", "Modify", "ContainerInherit, ObjectInherit", "None", "Allow"))
          if ($acl.AccessToString -ne (Get-Acl $userData.HomeDirectory).AccessToString) {
            $log += " <Setting Permissions>"
            Set-Acl -Path $userData.HomeDirectory -AclObject $acl
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
            $log += " [Exists   ]"
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
          catch {
            $log += " [Not in AD]"
            $user = $null
          }
          # Move files to inactive folder
          $homeDrive = "$($config.homeDriveDir)\$($stu.STKEY)"
          if (Test-Path $homeDrive) {
            $log += " <Moving Directory to Inactive>"
            Move-Item -Path $homeDrive -Destination "$inactivePath\" | Out-Null
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
          if ($log -ne " [Exists   ]" -and $log -ne " [Not in AD]") {
            Write-Host ("{0,-35} {1}" -f $curStu, $stu.STATUS) -ForegroundColor Red -NoNewline
            Write-Host $log
            $runLog += "{0,-35} {1}{2}`n" -f $curStu, $stu.STATUS, $log
          }
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
  if (Test-Path ".\email.conf") {
    & ".\Email-NewUsers.ps1" -NewStudents $newStudents
  }
  if (Test-Path ".\Custom-End.ps1") {
    & ".\Custom-End.ps1" -Students $students -NewStudents $newStudents -RunLog $runLog
  }
}
