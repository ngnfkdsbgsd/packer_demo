$iso_path = [System.IO.Path]::Combine($env:temp, "windows.iso")
Mount-DiskImage $iso_path

$disk = Get-PsDrive -PSProvider FileSystem | where-object { $(Test-Path $([System.IO.Path]::Combine($_.Root, "setup64.exe"))) -eq $true } | select-object -ExpandProperty Root
$arch = "setup.exe"
if ([System.Environment]::Is64BitOperatingSystem) { $arch = "setup64.exe" }

$log = [System.IO.Path]::Combine($env:Temp, "vmware_tools_install.log")
$log2 = [System.IO.Path]::Combine($env:Temp, "vmware_tools_install_err.log")
$installer = [System.IO.Path]::Combine($disk, $arch)
$process = Start-Process $installer -ArgumentList "/S /v `"/qn REBOOT=R ADDLOCAL=ALL`"" -PassThru -Wait -RedirectStandardError $log2 -RedirectStandardOutput $log

return $process.ExitCode