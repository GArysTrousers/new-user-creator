$config = Get-Content .\config.conf | ConvertFrom-StringData

""
"Year Level Groups"
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
  }
}

""
"Year Level OUs"
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
    $input = Read-Host "Create? (y/n)"
    if ($input -ieq 'y') {
      # Make it
    }
  }
}
