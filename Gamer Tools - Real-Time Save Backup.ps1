# Ask the user for name of game and save folder location and check it's valid
$gameName = Read-Host "Please enter the name of your game"
do { $saveFolder = Read-Host "Please enter your game's save folder path"
    if (!(Test-Path $saveFolder)) {
        Write-Host "Invalid Path! Please enter a valid save folder path"
    }
} until (Test-Path $saveFolder)

# Ask user for desired backup location
# Added error handling for backup - 23/05/2025
$backupMain = Read-Host "Please enter your preferred backup location"

# Added handling for leading and trailing quote marks - 23/05/2025
$backupMain = $backupMain -replace '^"|"$', ''

# Warn if the folder doesn’t exist and create it if needed
if (!(Test-Path $backupMain)) {
    Write-Host "Warning: The folder does not exist. It will be created."
    try {
        New-Item -Path $backupMain -ItemType Directory -Force
        Write-Host "Backup folder created: $backupMain"
    } catch {
        Write-Host "Error: Could not create backup folder at $backupMain"
        exit
    }
} else {
    Write-Host "Backup folder exists: $backupMain"
}

# Added functionality to backup the save file initially - 23/05/2025
# Define game-specific backup folder
$gameBackupFolder = "$backupMain\$gameName"

# Check if backup folder exists
if (!(Test-Path $gameBackupFolder)) {
    New-Item -Path $gameBackupFolder -ItemType Directory -Force
    Write-Host "Created backup folder for game: $gameBackupFolder"
}
# Copy all existing save files to backup folder
Copy-Item -Path "$saveFolder\*" -Destination $gameBackupFolder
Write-Host "Initial backup complete: All existing saves copied to $gameBackupFolder"

# Create watcher instance for saveFolder
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $saveFolder
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::LastWrite

# Register watcher as an event
Register-ObjectEvent $watcher "Changed" -Action {
    $backupSub = "$gameBackupFolder\Backup-$([DateTime]::Now.ToString('dd-MM-yyyy_HH-mm-ss'))"
    New-Item -ItemType Directory -Path $backupSub -Force
    try {
        Copy-Item -Path $event.SourceEventArgs.FullPath -Destination $backupSub -Recurse
    } catch {
        Write-Host "Error backing up file: $_"
    }

    if ($event.SourceEventArgs.ChangeType -eq [System.IO.WatcherChangeTypes]::Created) {
        Write-Host "New save file detected & backed up: $event.SourceEventArgs.Name"
    }
    else {
        Write-Host "Backup created for modified save: $event.SourceEventArgs.Name"
    }
}

# Added confirmation to end of script to keep Powershell alive - 23/05/2025
Write-Host "Monitoring save files for changes... Press Ctrl+C to finish monitoring"
try { while ($true) { Start-Sleep -Seconds 5 } }
finally {Write-Host "Save monitoring stopped. Your backups are safe."}
