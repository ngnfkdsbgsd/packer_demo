Set-Location $(Split-Path $(Get-Location) -Parent)

$vmx = Get-ChildItem ".\out\*" -Filter "*.vmx" | Select-Object -First 1
$vmx_content = Get-Content $vmx -Encoding utf8
$vmx_content = $vmx_content -replace "bios.bootorder = `"hdd,cdrom`"", "bios.bootorder = `"hdd`""
$vmx_content = $vmx_content -replace "remotedisplay.*", ""
$vmx_content = $vmx_content -replace "ide.*", ""
$vmx_content | Out-File $vmx -Encoding utf8 -Force