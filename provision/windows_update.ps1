#region extreme cases
    $systemInformation = New-Object -ComObject 'Microsoft.Update.SystemInfo'
    if ($systemInformation.RebootRequired) {
        Write-Output "[WU.ps1] Need to reboot, scheduling a restart"
        Start-Process shutdown.exe -ArgumentList "/r /t 10"
        [System.Environment]::Exit(-1)
    }
#endregion

#region helpers
    function MapResult($action, $container, $expected_codes){
        $operation_result = @{
            0 = "The operation is not started."
            1 = "The operation is in progress."
            2 = "The operation was completed successfully."
            3 = "The operation is complete, but one or more errors occurred during the operation. The results might be incomplete."
            4 = "The operation failed to complete."
            5 = "The operation is canceled."
        }

        if ($container.ResultCode -notin $expected_codes) { 
            Write-Output "[WU.ps1][WRN] - $($action):`nUnexpected result code: '$($container.ResultCode)' ($($operation_result[$container.ResultCode]))`nHRESULT: '$($container.HResult)'"
        }
    }

    function Wait-Condition([scriptblock]$condition, [int]$timeout){
        Write-Output "[WU.ps1] Waiting for condition '$($condition.ToString())' with timeout '$timeout' seconds."
        $start = [datetime]::now
        do {
            $current = [datetime]::now
            $result = $condition.InvokeReturnAsIs()
            Start-Sleep -Milliseconds 300
        } while (($result -eq $false) -and (($current - $start).TotalSeconds -lt $timeout))

        if ($result -eq $false) { Write-Output "[WU.ps1][WRN] - at least one TiWorker.exe process did not finish its job; rebooting forcefully (wait time - $timeout seconds)" }
    }
    
    function ErrorBootstrap($action, $container){
        throw [System.Exception]::new("[WU.ps1][ERR] - $($action):`nException: '$($container.Exception)'`nDetails: '$($container.ErrorDetails)'`nST: '$($container.ScriptStackTrace)'")
    }

    $installerCondition = [scriptblock]({(Get-Process "tiworker*" -ErrorAction SilentlyContinue).Count -eq 0})
#endregion

###################################### main region ############################################

$searchCriteria = "IsInstalled=0 and IsHidden=0 and BrowseOnly=0 and Type='Software'"
#region searcher
    Write-Output "[WU.ps1] Searching updates..."
    try {
        $action = "searching updates"
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSession.ClientApplicationID = "packer-windows-update"
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $searchResult = $updateSearcher.Search($SearchCriteria)

        MapResult -action $action -container $searchResult -expected_codes @(2, 3)
    } catch {
        ErrorBootstrap -action $action -container $_
    }

    if ($searchResult.Updates.Count -eq 0){
        Write-Output "[WU.ps1] Found 0 updates to install."
        Wait-Condition -condition $installerCondition -timeout 300
        Write-Output "Exiting gracefully."
        [System.Environment]::Exit(0)
    }

$out = @"
[WU.ps1] Searching updates - finished
$([string]::Join("`n", $($searchResult.Updates | ft Title -Wrap | Out-String)))
Total:$($searchResult.Updates.Count)
Warnings:$($searchResult.Warnings | fl)
"@

    Write-Output $out
#endregion

$updatesToGet = New-Object -ComObject "Microsoft.Update.UpdateColl"

foreach($update in $searchResult.Updates) {
    if ($update.InstallationBehavior.CanRequestUserInput) {
        Write-Output "[WU.ps1][WRN] - The update '$updateTitle' has the CanRequestUserInput flag set (if the install hangs, you might need to exclude it)"
    }

    $update.AcceptEula() | Out-Null
    $updatesToGet.Add($update) | Out-Null
}

#region downloader     
    try {
        $action = "downloading updates"
        $updateDownloader = $updateSession.CreateUpdateDownloader()
        $updateDownloader.Priority = 3 # https://docs.microsoft.com/ru-ru/windows/win32/api/wuapi/ne-wuapi-downloadpriority
        $updateDownloader.Updates = $updatesToGet

        $downloadJob = $updateDownloader.BeginDownload([object]::new(), [object]::new(), [object]::new())
        do {
            Start-Sleep -Seconds 150
            $progress = $downloadJob.GetProgress()
            Write-Output "[WU.ps1] Downloading updates - $("{0:N1}/{1:N1} MB {2:N}%" -f ($progress.TotalBytesDownloaded/1mb), ($progress.TotalBytesToDownload/1mb), ($progress.PercentComplete))"
        } while(!$downloadJob.IsCompleted)
        $downloadResult = $updateDownloader.EndDownload($downloadJob)

        MapResult -action $action -container $downloadResult -expected_codes @(2, 3)
    } catch {
        ErrorBootstrap -action $action -container $_
    }

    Write-Output "[WU.ps1] Download done"
#endregion

#region installer
    try {
        $action = "[WU.ps1] installing updates"
        $updateInstaller = $updateSession.CreateUpdateInstaller()
        $updateInstaller.Updates = $updatesToGet

        $installerJob = $updateInstaller.BeginInstall([object]::new(), [object]::new(), [object]::new())
        do {
            Start-Sleep -Seconds 150
            $progress = $installerJob.GetProgress()
            Write-Output "[WU.ps1] Installing updates - $($progress.PercentComplete)%"
        } while(!$installerJob.IsCompleted)

        $installResult = $updateInstaller.EndInstall($installerJob)
        MapResult -action $action -container $installResult -expected_codes @(2, 3)

        #bad practice
        if (($installResult.RebootRequired -ne $true) -and ($installResult.ResultCode -eq 2)) {
            Write-Output "[WU.ps1] Updates were installed, reboot is not needed."
            Wait-Condition -condition $installerCondition -timeout 300
            Write-Output "Exiting gracefully."
            [System.Environment]::Exit(0)
        }
        else {
            Write-Output "[WU.ps1] Updates were installed, reboot is needed."
            Wait-Condition -condition $installerCondition -timeout 300
            Start-Process shutdown.exe -ArgumentList "/r /t 30"
            Write-Output "[WU.ps1] Rebooting."
            [System.Environment]::Exit(-1)
        }
    } catch {
        ErrorBootstrap -action $action -container $_
    }
#endregion

###############################################################################################             