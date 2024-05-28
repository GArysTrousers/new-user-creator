param (
  [array] $NewStudents
)

if ($NewStudents.Count -gt 0) {
  $config = Get-Content .\email.conf | ConvertFrom-StringData

  $smtpClient = New-Object System.Net.Mail.SmtpClient($config.server, $config.port)
  $smtpClient.EnableSsl = $true
  $smtpClient.Credentials = New-Object System.Net.NetworkCredential($config.username, $config.password)
  $message = New-Object System.Net.Mail.MailMessage($config.from, $config.to)
  $message.IsBodyHtml = $true
  $message.Subject = "New Student Accounts"

  $rows = ''

  foreach ($stu in $NewStudents) {
    $rows += "<tr>
    <td>$($stu.DisplayName)</td>
    <td>$($stu.Password)</td>
    </tr>"
  }

  $message.Body = "
  <html>
  <body>
  Hi everyone!
  <br>
  <br>
  I made some new accounts:
  <br>
  <br>
  <table>
  <tbody>
  $($rows)
  </tbody>
  </table
  <br>
  <br>
  -Mr Roboto 🤖
  </body>
  </html>"

  try {
    $smtpClient.Send($message)
    Write-Host "Email sent to $($config.to)" -ForegroundColor Green
  }
  catch {
    Write-Host "Email failed to send" -ForegroundColor Red
  }
}