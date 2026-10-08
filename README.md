# Media Merge

A lightweight, cross-platform utility for **Windows** and **Linux** that losslessly merges separate video and audio files (such as `.mp4` video and `.ts` audio streams) using **FFmpeg** with native graphical file dialogs.

Developed and maintained by **CybTekSol [ https://github.com/CybTekSol ]**.

**DISCLAIMER:**  
This application is provided free of charge, **AS-IS**, no warranties or guarantees (expressed or implied)... use is at your own risk and is licensed as stated in the README.md located in this repository.

---

## Features

* **Instant Lossless Stream Copy:** Combines video and audio tracks in seconds without re-encoding or quality loss (`-c:v copy -c:a copy`).
* **Smart Two-Step Fallback:** If the target video container rejects the audio codec, Media Merge automatically extracts and converts the audio stream to high-quality `256k AAC` (`.m4a`), merges it cleanly with the video, and deletes the temporary file.
* **Universal Format Support:** Accepts virtually all FFmpeg-supported video (`.mp4`, `.mkv`, `.webm`, `.avi`, `.mov`, `.ts`, etc.) and audio (`.ts`, `.mp3`, `.aac`, `.m4a`, `.flac`, `.opus`, `.wav`, etc.) formats.
* **Dedicated Folder Routing:** Remembers your distinct preferred **Video** input, **Audio** input, and **Output** storage directories across sessions, with a startup option to **Change Defaults**, **Keep Current**, or **Do Not Ask Again**.
* **Native GUI Dialogs:** Uses Windows Forms on Windows and GTK (`yad`) on Linux—no command-line typing required during everyday use.

---

## Repository Structure

```text
Media-Merge/
├── Windows/
│   ├── Media-Merge.ps1
│   └── Install-on-Windows.ps1
├── Linux/
│   ├── media-merge.sh
│   └── install-on-linux.sh
└── README.md
```

---

## Windows Installation & Usage

### Prerequisites
* **Windows 10 / 11** (PowerShell 5.1+ included by default)
* **FFmpeg:** Either installed in your system `PATH` or saved as a portable executable (`ffmpeg.exe`). If it is not in your `PATH`, the first-run wizard will prompt you to select `ffmpeg.exe`.

### Automated Installation
1. Download or clone this repository and open the `Windows` folder.
2. Right-click `Install-on-Windows.ps1` and select **Run with PowerShell** (or run it from a PowerShell terminal):
   ```text
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-on-Windows.ps1;
   ```
3. Choose the folder where you want the script stored (defaults to `%LOCALAPPDATA%\Programs\MediaMerge`).
4. The installer will create **Desktop** and **Start Menu** shortcuts named **Media Merge** and launch the First-Run Setup wizard to configure your default video, audio, and output folders.

**NOTE:**
I have created and included a variety of custom icons in multiple resolutions that are located in ./Icons folder for you to replace the default icon of the created Windows shortcuts or Linux .desktop file if you desire. This is done in Windows by right-clicking the shortcut, selecting "Properties", clicking the "Change Icon", then browse for the icon you wish to use, select it and then click "OK". In Linux, this is achieved in a similar fashion. Linux users know! :-)

### Resetting Saved Defaults (Windows)
If you previously selected **Do Not Ask Again** and want to reconfigure your default folders or FFmpeg path, run the script with the `-Reset` switch:

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\Programs\MediaMerge\Media-Merge.ps1" -Reset;

*(You can also delete `%APPDATA%\MediaMerge\config.json` manually).*

---

## Linux Installation & Usage

### Prerequisites
* **Linux Mint Debian Edition (LMDE) / Debian / Ubuntu** (`apt`) or **EndeavourOS / Arch Linux** (`pacman`), or any standard Linux distribution.
* **`ffmpeg`** and **`yad`** (automatically installed by `install-on-linux.sh` on Debian- and Arch-based distributions).

### Automated Installation
1. Clone the repository and navigate to the `Linux` directory:
   ```text
   git clone [https://github.com/CybTekSol/Media-Merge.git](https://github.com/CybTekSol/Media-Merge.git);
   cd Media-Merge/Linux;
   ```
2. Make the scripts executable and run the installer:
   ```text
   chmod +x install-on-linux.sh media-merge.sh;
   ./install-on-linux.sh;
   ```
3. The installer will verify `ffmpeg` and `yad`, ask where to store the `media-merge` executable (defaults to `~/.local/bin`), create a desktop application launcher (`~/.local/share/applications/media-merge.desktop`), and launch the First-Run Setup dialog.

### Resetting Saved Defaults (Linux)
If you selected **Do Not Ask Again** and want to change your default directories later, run:

```text
~/.local/bin/media-merge --reset;
```

*(You can also delete `~/.config/media-merge/config.conf` manually).*

---

## How It Works

1. **Select Video:** Choose your source video file from the file picker (opens automatically in your configured **Default Video Folder**).
2. **Select Audio:** Choose your source audio file (opens automatically in your configured **Default Audio Folder**).
3. **Automatic Muxing:**
   * **Pass 1 (Direct Copy):** Runs `ffmpeg -map 0:v:0 -map 1:a:0 -c:v copy -c:a copy` to mux the first video stream and first audio stream without touching the encoding.
   * **Pass 2 (Compatibility Fallback):** If Pass 1 returns a non-zero exit code due to container/codec restrictions, Media Merge strips any residual video data from the audio source (`-vn`), converts the audio track to `256k AAC`, muxes the converted audio with the original video stream (`-c:v copy`), and removes the temporary audio file.
4. **Output:** Saves `<OriginalVideoName>_merged.<ext>` directly into your configured **Default Output Folder**.

---

## License

Released under the [MIT License](LICENSE).
