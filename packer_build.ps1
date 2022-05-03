Set-Location $PSScriptRoot
Remove-Item .\packer_cache -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item .\out -Force -Recurse -ErrorAction SilentlyContinue
Start-Process ".\packer.exe" -ArgumentList "build -on-error=ask $(Get-Location)" -NoNewWindow -Wait
