# Requires Powershell installed on MacOS
# Change below paths to the ones matching your EVE Online logs directory
# For MacOS you need to find one, for Windows the provided one is a default

$macOSPath = "~/<PATH TO EVE LOGS DIRECTORY>"
$windowsPath = $HOME + "\Documents\EVE\logs\"

# Define the directory path
if ($IsMacOS) { $logDir = $macOSPath }
elseif ($ENV:OS = "Windows_NT") { $IsWindows = "True" ; $logDir = $windowsPath }
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
    elseif ($IsWindows) { $logTypes = $directoryPath -replace '.*\\([^/]+)\\?$', '$1'}

    Write-Host "Archiving $($oldFiles.Count) files in $logTypes"
    # Update the zip file with older .txt files
    if ($oldFiles.Count -gt 0) {
        cd $directoryPath
        if ($IsWindows) {
            Compress-Archive -Path $oldFiles.FullName -Update -DestinationPath "$($logTypes) - $year.zip"
        } else {
            # macOS does not have Compress-Archive cmdlet; using zip command instead
            zip -u "$logTYpes - $year.zip" -j -m $oldFiles 2>&1 >/dev/null
        }
    }

    # Remove the older .txt files from the system
    $oldFiles | Remove-Item -Force -ErrorAction SilentlyContinue
}
Read-Host -Prompt "Press enter to close"
