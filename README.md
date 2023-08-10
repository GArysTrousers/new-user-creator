# New User Creator

## What it does
Takes eduhub data and creates student accounts.
- Creates account if missing
- Updates info if different
- Adds Student Group
- Adds Year Level Group (in the form "Year XX")
- Disables Ex-Students
- Moves Accounts to their rightful place

## How to use
1. Change the name of example.config.conf to config.conf
2. Fill out details in config.conf
3. Open terminal in new-user-creator directory (probably on a server)
4. Run Create-Users.ps1

## Future Features
- Year Level OUs
- Password Generation (Currently Static)

## If you want to action other statuses

"LVNG" {
  "({0}) {1} {2}" -f $stu.STKEY, $stu.FIRST_NAME, $stu.SURNAME | Write-Host -ForegroundColor Magenta
}
"INAC" {
  "({0}) {1} {2}" -f $stu.STKEY, $stu.FIRST_NAME, $stu.SURNAME | Write-Host -ForegroundColor Gray
}
"FUT" {
  "({0}) {1} {2}" -f $stu.STKEY, $stu.FIRST_NAME, $stu.SURNAME | Write-Host -ForegroundColor Blue
}