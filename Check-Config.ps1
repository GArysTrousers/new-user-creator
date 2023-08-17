$config = Get-Content .\config.conf | ConvertFrom-StringData
$tick = [char]0x00002713
$cross = [char]0x00002715

""
"Check Config File"
if (Test-Path $config.eduhubFilePath) {
  Write-Host "$tick EduHub File Access" -ForegroundColor Green
} else {
  Write-Host "$cross EduHub File Access" -ForegroundColor Red
}

if ($config.domainEmail -ne "") {
  Write-Host "$tick Domain Email" -ForegroundColor Green
} else {
  Write-Host "$cross Domain Email" -ForegroundColor Red
}

if ($config.passwordPattern -match "^[Ab0!]+$") {
  Write-Host "$tick Password Pattern" -ForegroundColor Green
} else {
  Write-Host "$cross Password Pattern" -ForegroundColor Red
}

if ($config.passwordSalt -ne "") {
  Write-Host "$tick Password Salt" -ForegroundColor Green
} else {
  Write-Host "$cross Password Salt" -ForegroundColor Red
}

try {
  Get-ADOrganizationalUnit $config.studentOU -ErrorAction Stop | Out-Null
  Write-Host "$tick Student OU" -ForegroundColor Green
}
catch {
  Write-Host "$cross Student OU" -ForegroundColor Red
}

try {
  Get-ADOrganizationalUnit $config.inactiveStudentOU -ErrorAction Stop | Out-Null
  Write-Host "$tick Inactive Student OU" -ForegroundColor Green
}
catch {
  Write-Host "$cross Inactive Student OU" -ForegroundColor Red
}

try {
  Get-ADGroup $config.studentGroup -ErrorAction Stop | Out-Null
  Write-Host "$tick Student Group" -ForegroundColor Green
}
catch {
  Write-Host "$cross Student Group" -ForegroundColor Red
}

try {
  Get-ADOrganizationalUnit $config.yearLevelGroupOU -ErrorAction Stop | Out-Null
  Write-Host "$tick Student Year Level Group OU" -ForegroundColor Green
}
catch {
  Write-Host "$cross Student Year Level Group OU" -ForegroundColor Red
}

""
"Year Level Groups"
$missing = @()
for ($i = 0; $i -le 12; $i++) { 
  if ($i -lt $config.minYearLevel -or $i -gt $config.maxYearLevel) {
    continue
  }
  $group = "CN=Year {0:d2},{1}" -f $i, $config.yearLevelGroupOU
  try {
    Get-ADGroup $group -ErrorAction Stop | Out-Null
    Write-Host "$tick $group" -ForegroundColor Green
  }
  catch {
    Write-Host "$cross $group" -ForegroundColor Red
    $missing += @{
      DName = $group
      Name  = ("Year {0:d2}" -f $i)
    }
  }
}
if ($missing.Length -gt 0) {
  $input = Read-Host "Create Missing? (y/n)"
  if ($input -ieq 'y') {
    foreach ($ou in $missing) {
      try {
        New-ADGroup -Name $ou.Name -Path $config.yearLevelGroupOU -GroupCategory Security -GroupScope Global -ErrorAction Stop
        "{0} Created" -f $ou.DName | Write-Host -ForegroundColor Green
      }
      catch {
        $_
        "{0} Failed" -f $ou.DName | Write-Host -ForegroundColor Red
      }
    }
  }
}

""
"Year Level OUs"
$missing = @()
for ($i = 0; $i -le 12; $i++) { 
  if ($i -lt $config.minYearLevel -or $i -gt $config.maxYearLevel) {
    continue
  }
  $ou = "OU=Year {0:d2},{1}" -f $i, $config.studentOU
  try {
    Get-ADOrganizationalUnit $ou -ErrorAction Stop | Out-Null
    Write-Host "$tick $ou" -ForegroundColor Green
  }
  catch {
    Write-Host "$cross $ou" -ForegroundColor Red
    $missing += @{
      DName = $ou
      Name  = ("Year {0:d2}" -f $i)
    }
  }
}
if ($missing.Length -gt 0) {
  $input = Read-Host "Create Missing? (y/n)"
  if ($input -ieq 'y') {
    foreach ($ou in $missing) {
      try {
        New-ADOrganizationalUnit -Name $ou.Name -Path $config.studentOU -ErrorAction Stop
        "{0} Created" -f $ou.DName | Write-Host -ForegroundColor Green
      }
      catch {
        $_
        "{0} Failed" -f $ou.DName | Write-Host -ForegroundColor Red
      }
    }
  }
}