Add-Type -AssemblyName System.Windows.Forms;

function Select-InstallFolder($Description, $InitialDir) {$dialog = New-Object System.Windows.Forms.FolderBrowserDialog;
    $dialog.Description = ($Description);
    $dialog.ShowNewFolderButton = ($true);
    if (Test-Path -Path ($InitialDir)) {
        $dialog.SelectedPath = ($InitialDir);
    };
    if ($dialog.ShowDialog() -eq ([System.Windows.Forms.DialogResult]::OK)) {
        return ($dialog.SelectedPath);
    };
    return ($null);
};

$sourceScript = Join-Path -Path ($PSScriptRoot) -ChildPath "Media-Merge.ps1";
if (-not (Test-Path -Path ($sourceScript))) {
    Write-Host "Error: Media-Merge.ps1 must be in the same folder as Install-Windows.ps1." -ForegroundColor Red;
    Pause;
    exit 1;
};

$defaultInstallBase = Join-Path -Path ($env:LOCALAPPDATA) -ChildPath "Programs";
[System.Windows.Forms.MessageBox]::Show("Select the folder where you want to store the Media Merge script.", "Media Merge Installer", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null;

$chosenFolder = Select-InstallFolder "Select Installation Folder for Media Merge Script" ($defaultInstallBase);
if (-not ($chosenFolder)) {
    Write-Host "Installation canceled by user." -ForegroundColor Yellow;
    exit 0;
};

$installDir = Join-Path -Path ($chosenFolder) -ChildPath "MediaMerge";
if (-not (Test-Path -Path ($installDir))) {
    New-Item -ItemType Directory -Path ($installDir) -Force | Out-Null;
};

$destScript = Join-Path -Path ($installDir) -ChildPath "Media-Merge.ps1";
Copy-Item -Path ($sourceScript) -Destination ($destScript) -Force;

$wshShell = New-Object -ComObject WScript.Shell;

# Create Desktop Shortcut
$desktopPath = [Environment]::GetFolderPath("Desktop");
$desktopShortcutPath = Join-Path -Path ($desktopPath) -ChildPath "Media Merge.lnk";
$shortcut =$wshShell.CreateShortcut(($desktopShortcutPath));$shortcut.TargetPath = "powershell.exe";
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$destScript`"";
$shortcut.WorkingDirectory = ($installDir);$shortcut.IconLocation = "shell32.dll,115";
$shortcut.Description = "Merge Video and Audio Streams with FFmpeg";
$shortcut.Save();

# Create Start Menu Shortcut
$startMenuPath = [Environment]::GetFolderPath("Programs");
$startShortcutPath = Join-Path -Path ($startMenuPath) -ChildPath "Media Merge.lnk";
$startShortcut =$wshShell.CreateShortcut(($startShortcutPath));$startShortcut.TargetPath = "powershell.exe";
$startShortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$destScript`"";
$startShortcut.WorkingDirectory = ($installDir);$startShortcut.IconLocation = "shell32.dll,115";
$startShortcut.Description = "Merge Video and Audio Streams with FFmpeg";
$startShortcut.Save();

Write-Host "Media Merge installed to: $destScript" -ForegroundColor Green;
Write-Host "Desktop and Start Menu shortcuts created!" -ForegroundColor Green;
Write-Host "Launching Media Merge for initial setup..." -ForegroundColor Cyan;

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File ($destScript) -Reset;