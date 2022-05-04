Set-Location $PSScriptRoot
Start-Process msiexec -ArgumentList "/i OpenSSH-x64-v8.9.1.0.msi /quiet" -Wait
Get-Service "ssh*" | Stop-Service -Force

$env_path = [System.Environment]::GetEnvironmentVariable("path")
$path = ";$($env:SystemDrive)\Program Files\OpenSSH"
[System.Environment]::SetEnvironmentVariable("path", $($env_path.Insert($env_path.Length, $path)), "Machine")

New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name "DefaultShell" -Value "$($env:SystemDrive)\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" | Out-Null	
Copy-Item -Path ".\sshd_config_wim" -Destination ([System.IO.Path]::Combine($env:ProgramData, "ssh", "sshd_config")) -Force

Get-Service "ssh*" | Start-Service