Set-Location $env:Temp
Copy-Item -Path ".\sshd_config_final" -Destination ([System.IO.Path]::Combine($env:ProgramData, "ssh", "sshd_config")) -Force
Copy-Item -Path ".\key_pub.pem" -Destination ([System.IO.Path]::Combine($env:ProgramData, "ssh", "administrators_authorized_keys")) -Force
Copy-Item -Path ".\oobeUnattend.xml" -Destination "C:\Temp" -Force
[Microsoft.Win32.Registry]::SetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccount\UserList", $env:USERNAME, 0, [Microsoft.Win32.RegistryValueKind]::DWord)

Write-Output "running dism /StartComponentCleanup"
Start-Process "dism.exe" -ArgumentList "/online /Cleanup-Image /StartComponentCleanup /ResetBase" -Wait

Write-Output "running sysprep"
Start-Process "$([System.IO.Path]::Combine($env:windir, "System32\Sysprep\sysprep.exe"))" -ArgumentList "/generalize /oobe /quit /unattend:`"$($env:Temp)\oobeUnattend.xml`"" -Wait

[System.Environment]::Exit(0)

