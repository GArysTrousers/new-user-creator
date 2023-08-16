Function Get-StringHash 
{ 
    param
    (
        [String] $String,
        $HashName = "MD5"
    )
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
    $algorithm = [System.Security.Cryptography.HashAlgorithm]::Create('MD5')
    $StringBuilder = New-Object System.Text.StringBuilder 
  
    $algorithm.ComputeHash($bytes) | 
    ForEach-Object { 
        $null = $StringBuilder.Append($_.ToString("x2")) 
    } 
  
    $StringBuilder.ToString() 
}

Function Get-Password 
{
    param (
        [String] $Base,
        [String] $Pattern = "Abb000!",
        [String] $Salt
    )

    $Upper = @()
    (65..90) | ForEach-Object {
        $Upper += [char]$_
    }
    $Lower = @()
    (97..122) | ForEach-Object {
        $Lower += [char]$_
    }
    $Num = (0..9)
    $Sym = ('!', '@', '#', '$', '%')

    $Hash = Get-StringHash($Base.ToUpper() + $Salt)
    $Password = "";
    for ($i = 0; $i -lt $Pattern.length; $i++) {
        $number = [Convert]::ToInt64($Hash[$i*2]+$Hash[$i*2+1],16);

        switch ($Pattern[$i]) {
            "A" {$Password += $Upper[$number % $Upper.Length]}
            "b" {$Password += $Lower[$number % $Lower.Length]}
            "0" {$Password += $Num[$number % $Num.Length]}
            "!" {$Password += $Sym[$number % $Sym.Length]}
        }
    }
    return $Password
}