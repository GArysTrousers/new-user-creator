$config = Get-Content .\config.conf | ConvertFrom-StringData
$data = Import-Csv $config.eduhubFilePath
$yearLevelGroups = @()
for ($i = 0; $i -le 12; $i++) {
  $yearLevelGroups += "CN=Year {0:d2},{1}" -f $i, $config.yearLevelGroupOU
}
$props = @("DisplayName", "EmailAddress", "MemberOf")

$data | ForEach-Object {
  $stu = $_
  switch ($_.STATUS) {
    "ACTV" { 
      "({0}) {1} {2}" -f $stu.STKEY, $stu.FIRST_NAME, $stu.SURNAME | Write-Host -ForegroundColor Green
      $name = '{0} {1} ({2})' -f $stu.FIRST_NAME, $stu.SURNAME, $stu.STKEY
      $userData = @{
        GivenName         = $stu.FIRST_NAME
        Surname           = $stu.SURNAME
        DisplayName       = '{0} {1}' -f $stu.FIRST_NAME, $stu.SURNAME
        SamAccountName    = $stu.STKEY
        UserPrincipalName = '{0}@{1}' -f $stu.STKEY, $config.domainEmail
        EmailAddress      = '{0}@{1}' -f $stu.STKEY, $config.domainEmail
      }
      try {
        $user = Get-ADUser -Identity $stu.STKEY -Properties $props -ErrorAction Stop
        "[Account exists]"
      }
      catch {
        "<Making account>"
        New-ADUser -Name $name -OtherAttributes @userData -Path $config.studentOU
        $userFound = $false
        while ($count -le $config.newAccountWaitTime) {
          Start-Sleep -Seconds 1
          Write-Host '.' -NoNewline
          try {
            $user = Get-ADUser -Identity $stu.STKEY -Properties $props -ErrorAction Stop
            $userFound = $true
            break
          }
          catch {
            $count += 1
          }
        }
        if ($userFound -eq $false) {
          "Waiting for account took too long"
          return
        }
        Set-ADAccountPassword -Identity $stu.STKEY -Reset -NewPassword (ConvertTo-SecureString $config.defaultPassword -AsPlainText -Force)
      }
      $updateUser = $false
      foreach ($data in $userData.GetEnumerator()) {
        if ($user[$data.Key] -ne $data.Value) {
          $updateUser = $true
          break
        }
      }
      if ($updateUser) {
        "<Updating Profile>"
        $userData["Identity"] = $stu.STKEY
        Set-ADUser @userData
      }
      if ($user.Enabled -eq $false) {
        "<Enabling account>"
        $user | Enable-ADAccount
      }
      if ($user.MemberOf -notcontains $config.studentGroup) {
        "<Adding to student group>"
        Add-ADGroupMember $config.studentGroup -Members $user
      }
      if ($user.MemberOf -notcontains $yearLevelGroups[$stu.SCHOOL_YEAR]) {
        "<Setting year level group>"
        $user.MemberOf | Where-Object { $yearLevelGroups -contains $_ } | ForEach-Object { 
          "<Removing group: {0}>" -f $_.Name
          Remove-ADGroupMember $_ -Members $user -Confirm:$false
        } # remove any current year groups
        Add-ADGroupMember $yearLevelGroups[$stu.SCHOOL_YEAR] -Members $stu.STKEY
      }
      if ($user.DistinguishedName -match 'CN=[^,]+,(.+)') {
        if ($Matches.1 -ne $config.studentOU) {
          "<Moving to students OU>"
          $user | Move-ADObject $config.studentOU
        }
      }
    }
    "LEFT" { 
      "({0}) {1} {2}" -f $stu.STKEY, $stu.FIRST_NAME, $stu.SURNAME | Write-Host -ForegroundColor Red
      try {
        $user = Get-ADUser -Identity $stu.STKEY -ErrorAction Stop
        "[Account exists]"
      }
      catch {
        "[Not in AD]"
        return
      }
      if ($user.Enabled -eq $true) {
        "<Disabling account>"
        $user | Disable-ADAccount
      }
      if ($user.DistinguishedName -match 'CN=[^,]+,(.+)') {
        if ($Matches.1 -ne $config.inactiveStudentOU) {
          "<Moving to inactive OU>"
          $user | Move-ADObject $config.inactiveStudentOU
        }
      }
    }
  }
}
