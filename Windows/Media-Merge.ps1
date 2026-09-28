param (
    [switch]$Reset
);

Add-Type -AssemblyName System.Windows.Forms;
Add-Type -AssemblyName System.Drawing;

$configDir = Join-Path -Path ($env:APPDATA) -ChildPath "MediaMerge";
$configFile = Join-Path -Path ($configDir) -ChildPath "config.json";

function Select-FolderDialog($Description, $InitialDir) {
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog;
    $folderBrowser.Description = ($Description);
    $folderBrowser.ShowNewFolderButton = ($true);
    if (($InitialDir) -and (Test-Path -Path ($InitialDir))) {
        $folderBrowser.SelectedPath = ($InitialDir);
    };
    if ($folderBrowser.ShowDialog() -eq ([System.Windows.Forms.DialogResult]::OK)) {
        return ($folderBrowser.SelectedPath);
    };
    return ($null);
};

function Get-FileName($Title, $Filter, $StartFolder) {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog;
    $dialog.Title = ($Title);
    $dialog.Filter = ($Filter);
    if (($StartFolder) -and (Test-Path -Path ($StartFolder))) {
        $dialog.InitialDirectory = ($StartFolder);
    };
    if ($dialog.ShowDialog() -eq ([System.Windows.Forms.DialogResult]::OK)) {
        return ($dialog.FileName);
    };
    return ($null);
};

function Show-StartupChoiceDialog($CurrentInputDir, $CurrentOutputDir) {
    $form = New-Object System.Windows.Forms.Form;
    $form.Text = "Media Merge - Default Settings";
    $form.Size = New-Object System.Drawing.Size(480, 230);
    $form.StartPosition = "CenterScreen";
    $form.FormBorderStyle = "FixedDialog";
    $form.MaximizeBox = ($false);
    $form.MinimizeBox = ($false);

    $label = New-Object System.Windows.Forms.Label;
    $label.Location = New-Object System.Drawing.Point(20, 20);
    $label.Size = New-Object System.Drawing.Size(430, 95);
    $label.Text = "Current Default Media Folder:`r`n" + ($CurrentInputDir) + "`r`n`r`nCurrent Default Output Folder:`r`n" + ($CurrentOutputDir) + "`r`n`r`nWould you like to change these defaults?";
    $form.Controls.Add(($label));

    $btnChange = New-Object System.Windows.Forms.Button;
    $btnChange.Location = New-Object System.Drawing.Point(20, 135);
    $btnChange.Size = New-Object System.Drawing.Size(130, 35);
    $btnChange.Text = "Change Defaults";
    $btnChange.DialogResult = [System.Windows.Forms.DialogResult]::Yes;
    $form.Controls.Add(($btnChange));

    $btnKeep = New-Object System.Windows.Forms.Button;
    $btnKeep.Location = New-Object System.Drawing.Point(165, 135);
    $btnKeep.Size = New-Object System.Drawing.Size(130, 35);
    $btnKeep.Text = "Keep Current";
    $btnKeep.DialogResult = [System.Windows.Forms.DialogResult]::No;
    $form.Controls.Add(($btnKeep));

    $btnNever = New-Object System.Windows.Forms.Button;
    $btnNever.Location = New-Object System.Drawing.Point(310, 135);
    $btnNever.Size = New-Object System.Drawing.Size(140, 35);
    $btnNever.Text = "Do Not Ask Again";
    $btnNever.DialogResult = [System.Windows.Forms.DialogResult]::Ignore;
    $form.Controls.Add(($btnNever));

    $form.AcceptButton = ($btnKeep);
    return ($form.ShowDialog());
};

function Set-Configuration($ExistingConfig) {
    if (-not (Test-Path -Path ($configDir))) {
        New-Item -ItemType Directory -Path ($configDir) -Force | Out-Null;
    };

    $startInput = if ($ExistingConfig) { ($ExistingConfig.DefaultInputDir) } else { ($env:USERPROFILE) };
    $inputDir = Select-FolderDialog "Select Default Download / Media Input Folder" ($startInput);
    if (-not ($inputDir)) {
        Write-Host "Setup canceled. Exiting." -ForegroundColor Yellow;
        exit 1;
    };

    $outputDir = Select-FolderDialog "Select Default Output Storage Folder for Merged Media" ($inputDir);
    if (-not ($outputDir)) {
        $outputDir = ($inputDir);
    };

    $ffmpegPath = "ffmpeg.exe";
    $sysFfmpeg = Get-Command "ffmpeg.exe" -ErrorAction SilentlyContinue;
    if ($sysFfmpeg) {
        $ffmpegPath = ($sysFfmpeg.Source);
    } elseif (($ExistingConfig) -and (Test-Path -Path ($ExistingConfig.FFmpegPath))) {
        $ffmpegPath = ($ExistingConfig.FFmpegPath);
    } else {
        $defaultPortable = "C:\Program Files\Portable\Media Related\FFmpeg\bin\ffmpeg.exe";
        if (Test-Path -Path ($defaultPortable)) {
            $ffmpegPath = ($defaultPortable);
        } else {
            [System.Windows.Forms.MessageBox]::Show("FFmpeg was not found in your system PATH. Please locate ffmpeg.exe.", "Locate FFmpeg", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null;
            $ffmpegPath = Get-FileName "Locate ffmpeg.exe" "Executable (ffmpeg.exe)|ffmpeg.exe|All Files (*.*)|*.*" ($env:ProgramFiles);
            if (-not ($ffmpegPath)) {
                Write-Host "FFmpeg executable is required. Exiting." -ForegroundColor Red;
                exit 1;
            };
        };
    };

    $newConfig = [PSCustomObject]@{
        DefaultInputDir  = ($inputDir);
        DefaultOutputDir = ($outputDir);
        FFmpegPath       = ($ffmpegPath);
        DoNotAskAgain    = ($false);
    };

    $newConfig | ConvertTo-Json | Set-Content -Path ($configFile) -Encoding UTF8;
    return ($newConfig);
};

# Load or initialize configuration
$config = ($null);
if ((Test-Path -Path ($configFile)) -and (-not ($Reset))) {
    try {
        $config = Get-Content -Path ($configFile) -Raw | ConvertFrom-Json;
    } catch {
        $config = ($null);
    };
};

if (-not ($config)) {
    [System.Windows.Forms.MessageBox]::Show("Welcome to Media Merge! Let's configure your default folders.", "First Run Setup", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null;
    $config = Set-Configuration ($null);
} elseif (-not ($config.DoNotAskAgain)) {
    $choice = Show-StartupChoiceDialog ($config.DefaultInputDir) ($config.DefaultOutputDir);
    if ($choice -eq ([System.Windows.Forms.DialogResult]::Yes)) {
        $config = Set-Configuration ($config);
    } elseif ($choice -eq ([System.Windows.Forms.DialogResult]::Ignore)) {
        $config.DoNotAskAgain = ($true);
        $config | ConvertTo-Json | Set-Content -Path ($configFile) -Encoding UTF8;
    };
};

$defaultDir = ($config.DefaultInputDir);
$outputDir  = ($config.DefaultOutputDir);
$ffmpeg     = ($config.FFmpegPath);

$videoFilter = "Supported Video Files|*.mp4;*.mkv;*.avi;*.mov;*.wmv;*.flv;*.webm;*.ts;*.mts;*.m2ts;*.vob;*.ogv;*.m4v;*.mpg;*.mpeg;*.m2v;*.3gp|All Files (*.*)|*.*";
Write-Host "Please select the Video file...";
$videoFile = Get-FileName "Select Video File" ($videoFilter) ($defaultDir);
if (-not ($videoFile)) { Write-Host "No video selected. Exiting."; exit 0; };

$audioFilter = "Supported Audio Files|*.ts;*.mp3;*.aac;*.m4a;*.wav;*.flac;*.ogg;*.opus;*.wma;*.ac3;*.eac3;*.dts;*.aiff;*.alac;*.mka|All Files (*.*)|*.*";
Write-Host "Please select the Audio file...";
$audioFile = Get-FileName "Select Audio File" ($audioFilter) ($defaultDir);
if (-not ($audioFile)) { Write-Host "No audio selected. Exiting."; exit 0; };

if (-not (Test-Path -Path ($outputDir))) {
    $outputDir = [System.IO.Path]::GetDirectoryName(($videoFile));
};

$baseName   = [System.IO.Path]::GetFileNameWithoutExtension(($videoFile));
$vidExt     = [System.IO.Path]::GetExtension(($videoFile));
$mergedName = ($baseName) + "_merged" + ($vidExt);
$outputFile = Join-Path -Path ($outputDir) -ChildPath ($mergedName);

# Attempt 1: Instant Stream Copy
$arguments = @(
    "-y",
    "-i", ($videoFile),
    "-i", ($audioFile),
    "-map", "0:v:0",
    "-map", "1:a:0",
    "-c:v", "copy",
    "-c:a", "copy",
    ($outputFile)
);

Write-Host "Attempting instant stream copy... Please wait." -ForegroundColor Cyan;
& ($ffmpeg) ($arguments);

if (($LASTEXITCODE) -eq 0) {
    Write-Host "Success! Merged file saved to: $outputFile" -ForegroundColor Green;
} else {
    Write-Host "`nIncompatibility detected during direct copy." -ForegroundColor Yellow;
    Write-Host "Switching to Two-Step Process: Extracting and converting audio first..." -ForegroundColor Cyan;

    $tempAudio = Join-Path -Path ($outputDir) -ChildPath "temp_audio_converted.m4a";

    # Attempt 2 - Step A: Convert Audio to AAC
    $convertArgs = @(
        "-y",
        "-i", ($audioFile),
        "-vn",
        "-c:a", "aac",
        "-b:a", "256k",
        ($tempAudio)
    );

    Write-Host "Converting audio to AAC format..." -ForegroundColor Yellow;
    & ($ffmpeg) ($convertArgs);

    if (($LASTEXITCODE) -eq 0) {
        Write-Host "Audio conversion successful. Merging with video..." -ForegroundColor Cyan;

        # Attempt 2 - Step B: Merge Original Video with Temp Audio
        $mergeArgs = @(
            "-y",
            "-i", ($videoFile),
            "-i", ($tempAudio),
            "-map", "0:v:0",
            "-map", "1:a:0",
            "-c:v", "copy",
            "-c:a", "copy",
            ($outputFile)
        );

        & ($ffmpeg) ($mergeArgs);

        if (($LASTEXITCODE) -eq 0) {
            Write-Host "Success! Audio was converted and merged. File saved to: $outputFile" -ForegroundColor Green;
        } else {
            Write-Host "FFmpeg encountered an error during the final merge phase." -ForegroundColor Red;
        };

        Write-Host "Cleaning up temporary files...";
        Remove-Item -Path ($tempAudio) -ErrorAction SilentlyContinue;
    } else {
        Write-Host "Critical error: FFmpeg failed to convert the audio file." -ForegroundColor Red;
    };
};

Pause;