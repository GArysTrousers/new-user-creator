$config = Get-Content .\config.conf | ConvertFrom-StringData

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
    $group | Write-Host -ForegroundColor Green
  }
  catch {
    $group | Write-Host -ForegroundColor Red
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
    $ou | Write-Host -ForegroundColor Green
  }
  catch {
    $ou | Write-Host -ForegroundColor Red
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