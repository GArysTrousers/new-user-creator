param (
  [array] $NewStudents
)

$config = Get-Content .\email.conf | ConvertFrom-StringData

if ($NewStudents.Count -gt 0) {
  $rows = ''

  foreach ($stu in $NewStudents) {
    $rows += "<tr>
    <td>$($stu.DisplayName)</td>
    <td>$($stu.Password)</td>
    </tr>"
  }

  $body = "
  <html>
  <body>
  Hi,<br>
  <table>
  <tbody>
  $($rows)
  </tbody>
  </table
  <br>
  -Mr Roboto 🤖
  </body>
  </html>"

  Invoke-WebRequest -Uri "http://10.128.128.70:4003" -Method POST -Body @{
    to      = $config.to;
    subject = "New Students";
    html    = $body
  }
}