#!/usr/bin/env bash

echo "=== Media Merge Linux Installer (LMDE / EndeavourOS) ==="

# 1. Check and install dependencies (ffmpeg and yad)

MISSING_DEPS=()

if ! command -v ffmpeg >/dev/null 2>&1; then
    MISSING_DEPS+=("ffmpeg")
fi

if ! command -v yad >/dev/null 2>&1; then
    MISSING_DEPS+=("yad")
fi

if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then

    echo "Installing missing dependencies: ${MISSING_DEPS[*]}"

    if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y "${MISSING_DEPS[@]}"

    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm "${MISSING_DEPS[@]}"

    else
        echo "Please install ${MISSING_DEPS[*]} manually using your package manager."
        exit 1
    fi

fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SOURCE_SCRIPT="${SCRIPT_DIR}/media-merge.sh"
SOURCE_ICON="${SCRIPT_DIR}/media-merge.png"

if [[ ! -f "${SOURCE_SCRIPT}" ]]; then
    echo "Error: media-merge.sh must be in the same directory as install-on-linux.sh."
    exit 1
fi

if [[ ! -f "${SOURCE_ICON}" ]]; then
    echo "Error: media-merge.png must be in the same directory as install-on-linux.sh."
    exit 1
fi

# 2. Prompt for script installation directory

DEFAULT_BIN_DIR="${HOME}/.local/bin"

mkdir -p "${DEFAULT_BIN_DIR}"

yad --info \
    --title="Media Merge Installer" \
    --width=380 \
    --text="Select the directory where you want to store the Media Merge script (Default: ~/.local/bin)."

INSTALL_DIR=$(yad \
    --file-selection \
    --directory \
    --title="Select Script Storage Location" \
    --filename="${DEFAULT_BIN_DIR}/")

INSTALL_DIR="${INSTALL_DIR%|}"

if [[ -z "${INSTALL_DIR}" ]]; then
    echo "Installation canceled."
    exit 0
fi

mkdir -p "${INSTALL_DIR}"

TARGET_SCRIPT="${INSTALL_DIR}/media-merge"
TARGET_ICON="${INSTALL_DIR}/media-merge.png"

# Copy the application script and icon

cp "${SOURCE_SCRIPT}" "${TARGET_SCRIPT}"
cp "${SOURCE_ICON}" "${TARGET_ICON}"

chmod +x "${TARGET_SCRIPT}"

# 3. Create Desktop Application Entry

APP_DIR="${HOME}/.local/share/applications"

mkdir -p "${APP_DIR}"

DESKTOP_FILE="${APP_DIR}/media-merge.desktop"

cat <<EOF > "${DESKTOP_FILE}"
[Desktop Entry]
Version=1.0
Type=Application
Name=Media Merge
Comment=Join Video and Audio Streams Losslessly with FFmpeg
Exec="${TARGET_SCRIPT}"
Icon=${TARGET_ICON}
Terminal=true
Categories=AudioVideo;Video;AudioVideoEditing;
EOF

chmod +x "${DESKTOP_FILE}"

echo "Installed script to: ${TARGET_SCRIPT}"
echo "Installed icon to: ${TARGET_ICON}"
echo "Created desktop launcher at: ${DESKTOP_FILE}"
echo "Running initial folder setup..."

"${TARGET_SCRIPT}" --reset