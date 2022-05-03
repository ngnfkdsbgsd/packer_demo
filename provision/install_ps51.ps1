$file = [System.IO.Path]::Combine($env:Temp, "Win8.1AndW2K12R2-KB3191564-x64.msu")
$log1 = [System.IO.Path]::Combine($env:Temp, "ps51_install.log")
$log2 = [System.IO.Path]::Combine($env:Temp, "ps51_install_err.log")
$proc = Start-Process wusa.exe -ArgumentList "$file /quiet /norestart" -Wait -PassThru 
return $proc.ExitCode