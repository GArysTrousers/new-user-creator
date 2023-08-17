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
4. Run Check-Config.ps1 to check that OUs and Groups are correct (Optional)
5. Run Create-Users.ps1

## Future Features
- Send email about new accounts

## About Password Generator
New accounts have a password generated for them with a hash based algorithm.
The Get-Password function takes an input (student username) adds the password salt string and creates a password based on the input pattern.
This should mean that as long as the salt is secure, no one else should be able to replicated the passwords.

## Config
```
eduhubFilePath: Path to eduhub student data file
  Eg: \\\\server/eduhub/ST_CODE.csv

domainEmail: The school domain
  Eg: schoolname.vic.edu.au

passwordPattern: This is the pattern for new passwords to follow
  A: Upper Case Letter
  b: Lower Case Letter
  0: Number
  !: Symbol
  Eg: Abb000!

passwordSalt: A string of characters used when generating passwords
  - This should be a string of ~32 random characters
  - You should keep this string secret

studentOU: The dname for the student OU
  - This is where the year level OUs should be
  Eg: OU=Students,DC=mydomain,DC=local

inactiveStudentOU: OU for inactive student accounts
  Eg: OU=Inactive,OU=Students,DC=mydomain,DC=local

studentGroup: The dname for the all students security group
  Eg: CN=Students,OU=Groups,DC=mydomain,DC=local

yearLevelGroupOU: The dname for the OU containing the year level sec groups
  Eg: OU=Year Levels,OU=Groups,DC=mydomain,DC=local

newAccountWaitTime: The max number of seconds to wait for a new account
  Eg: 15

minYearLevel: The lowest year level at the school 0=Prep
  Eg: 0 for Primary, 7 for Secondary

maxYearLevel:
  Eg: 6 for Primary, 12 for Secondary

logFile: The file name that the log file will be saved as
  Eg: ./last_run.log

newAccountFile: The file name that new account details will be saved into
  - This file will contain username, password for accounts created
  Eg: ./new_accounts.log
```
## Other Status Codes
```
"LVNG", "INAC", "FUT"
```