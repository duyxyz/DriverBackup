$URL = 'https://raw.githubusercontent.com/DuyNguyen2k6/Tool/main/MAS_AIO.cmd'
$rand = [Guid]::NewGuid().Guid
$FilePath = "$env:USERPROFILE\AppData\Local\Temp\MAS_$rand.cmd"
Invoke-WebRequest -Uri $URL -OutFile $FilePath
Start-Process "cmd.exe" -ArgumentList "/c `"$FilePath`"" -Verb RunAs -Wait
Remove-Item $FilePath -ErrorAction SilentlyContinue
