
# Ask the user for name of game and save folder location and check it's valid
$gameName = Read-Host "Please enter the name of your game"
do { $saveFolder = Read-Host "Please enter your game's save folder path"
    if (!(Test-Path $saveFolder)) {
        Write-Host "Invalid Path! Please enter a valid save folder path"
    }
} until (Test-Path $saveFolder)

# Ask user for desired backup location
$backupMain = Read-Host "Please enter your preferred backup location"

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $saveFolder
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::LastWrite

Register-ObjectEvent $watcher "Changed" -Action {
    $backupSub = "$backupMain\$gameName-Backup-$([DateTime]::Now.ToString('dd-MM-yyyy_HH-mm-ss'))"
    New-Item -ItemType Directory -Path $backupSub -Force
    Copy-Item -Path $event.SourceEventArgs.FullPath -Destination $backupSub
    
    if ($event.SourceEventArgs.ChangeType -eq [System.IO.WatcherChangeTypes]::Created) {
        Write-Host "New save file detected & backed up: $event.SourceEventArgs.Name"
    }
    else {
        Write-Host "Backup created for modified save: $event.SourceEventArgs.Name"
    }
}
