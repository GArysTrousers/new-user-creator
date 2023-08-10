# New User Creator

## How to use
1. Change the name of example.config.conf to config.conf
2. Fill out details in config.conf
3. Open terminal in new-user-creator directory (probably on a server)
4. Run Create-Users.ps1

## If there is more to status you want to action

"LVNG" {
  "({0}) {1} {2}" -f $stu.STKEY, $stu.FIRST_NAME, $stu.SURNAME | Write-Host -ForegroundColor Magenta
}
"INAC" {
  "({0}) {1} {2}" -f $stu.STKEY, $stu.FIRST_NAME, $stu.SURNAME | Write-Host -ForegroundColor Gray
}
"FUT" {
  "({0}) {1} {2}" -f $stu.STKEY, $stu.FIRST_NAME, $stu.SURNAME | Write-Host -ForegroundColor Blue
}