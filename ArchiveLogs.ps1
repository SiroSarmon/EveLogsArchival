# Requires Powershell installed on MacOS
# Change below paths to the ones matching your EVE Online logs directory
# For MacOS you need to find one, for Windows the provided one is a default

$macOSPath = "~/<PATH TO EVE LOGS DIRECTORY>"
$windowsPath = $HOME + "\Documents\EVE\logs\"  # This is default location - if changed, you need to modify this line

# Define the directory path
if ($IsMacOS) { $logDir = $macOSPath }
elseif ($ENV:OS = "Windows_NT") { $IsItWindows = "True" ; $logDir = $windowsPath }
else {exit}

$logsPath = @()
$logsPath += $logDir + "Chatlogs"
$logsPath += $logDir + "Gamelogs"

foreach ($directoryPath in $logsPath) {

    # Get files older than 1 hour with .txt extension
    $1hourAgo = (Get-Date).AddHours(-1)
    $oldFiles = Get-ChildItem -Path $directoryPath -Filter *.txt | Where-Object { $_.LastWriteTime -le $1hourAgo }

    # Get the current year for the zip file name
    $year = Get-Date -Format "yyyy"

    # Define the zip file name
    if ($IsMacOS) { $logTypes = $($directoryPath -match '\/([^\/]+)\/?$' | Out-Null; $matches[1]) }
    elseif ($IsItWindows) { $logTypes = $directoryPath -replace '.*\\([^/]+)\\?$', '$1'}

    Write-Host "Archiving $($oldFiles.Count) files in $logTypes"
    # Update the zip file with older .txt files
    if ($oldFiles.Count -gt 0) {
        Set-Location $directoryPath
        if ($IsItWindows) {
            Compress-Archive -Path $oldFiles.FullName -Update -DestinationPath "$($logTypes) - $year.zip"
        } else {
            # macOS does not have Compress-Archive cmdlet; using zip command instead
            zip -u "$logTYpes - $year.zip" -j -m $oldFiles 2>&1 >/dev/null
        }
    }

    # Remove the older .txt files from the system
    $oldFiles | Remove-Item -Force -ErrorAction SilentlyContinue
}

$riftProcess = Get-Process -name "RIFT Intel Fusion Tool" -ErrorAction SilentlyContinue
$riftSqlFilesLoc = $HOME + "\AppData\Local\Packages\" +
                   (Get-ChildItem $HOME"\AppData\Local\Packages" -Filter "*RIFTIntelFusionTool*" -Directory).Name +
                   "\LocalCache\Local\Temp"
$riftSqlFiles = Get-ChildItem $riftSqlFilesLoc -File -Filter "sqlite-jdbc-tmp-*"
$riftSqlFilesCount = $riftSqlFiles.Count
$riftFilesDeletionCounter = 0

if ($riftProcess) {
    $riftStartTime = $riftProcess.StartTime
    $riftSqlFiles | ForEach-Object {
        Write-Progress -Status "Removing RIFT files" -PercentComplete $($riftFilesDeletionCounter / $riftSqlFilesCount) -Activity "RIFT files removal"
        if ($_.CreationTime -lt $riftStartTime) {
            Remove-item $_.FullName
        }
    }
}
else {
    $riftSqlFiles | ForEach-Object {
        Write-Progress -Status "Removing RIFT files" -PercentComplete $($riftFilesDeletionCounter / $riftSqlFilesCount) -Activity "RIFT files removal"
        Remove-item $_.FullName
        $riftFilesDeletionCounter++
    }
}
Write-Host "Cleared $($riftFilesDeletionCounter) old RIFT database files."
Read-Host -Prompt "Press enter to close"

