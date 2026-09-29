#!/usr/bin/env bash

CONFIG_DIR="${HOME}/.config/media-merge";
CONFIG_FILE="${CONFIG_DIR}/config.conf";

if [[ ($1) == "--reset" ]]; then
    rm -f "${CONFIG_FILE}";
fi;

run_initial_setup() {
    mkdir -p "${CONFIG_DIR}";
    local start_dir="${DEFAULT_VIDEO_DIR:-${HOME}}";

    zenity --info --title="Media Merge Setup" --width=380 \
        --text="Please select your Default Video Input folder.";

    local new_video;
    new_video=$(zenity --file-selection --directory --title="Select Default Video Input Folder" --filename="${start_dir}/");
    if [[ -z ($new_video) ]]; then
        exit 1;
    fi;

    zenity --info --title="Media Merge Setup" --width=380 \
        --text="Next, select your Default Audio Input folder.";

    local new_audio;
    new_audio=$(zenity --file-selection --directory --title="Select Default Audio Input Folder" --filename="${new_video}/");
    if [[ -z ($new_audio) ]]; then
        new_audio="${new_video}";
    fi;

    zenity --info --title="Media Merge Setup" --width=380 \
        --text="Finally, select your Default Output Storage folder for merged files.";

    local new_output;
    new_output=$(zenity --file-selection --directory --title="Select Default Output Storage Folder" --filename="${new_video}/");
    if [[ -z ($new_output) ]]; then
        new_output="${new_video}";
    fi;

    DEFAULT_VIDEO_DIR="${new_video}";
    DEFAULT_AUDIO_DIR="${new_audio}";
    DEFAULT_OUTPUT_DIR="${new_output}";
    DO_NOT_ASK_AGAIN="false";

    cat <<EOF > "${CONFIG_FILE}"
DEFAULT_VIDEO_DIR="${DEFAULT_VIDEO_DIR}"
DEFAULT_AUDIO_DIR="${DEFAULT_AUDIO_DIR}"
DEFAULT_OUTPUT_DIR="${DEFAULT_OUTPUT_DIR}"
DO_NOT_ASK_AGAIN="${DO_NOT_ASK_AGAIN}"
EOF
};

if [[ -f "${CONFIG_FILE}" ]]; then
    source "${CONFIG_FILE}";
    # Handle migration from older config versions seamlessly
    if [[ -z "${DEFAULT_VIDEO_DIR}" ]]; then
        run_initial_setup;
    fi;
else
    run_initial_setup;
fi;

if [[ ($DO_NOT_ASK_AGAIN) != "true" ]]; then
    choice=$(zenity --question \
        --title="Media Merge - Default Settings" \
        --width=460 \
        --text="<b>Current Video Folder:</b>\n${DEFAULT_VIDEO_DIR}\n\n<b>Current Audio Folder:</b>\n${DEFAULT_AUDIO_DIR}\n\n<b>Current Output Folder:</b>\n${DEFAULT_OUTPUT_DIR}\n\nWould you like to change these defaults?" \
        --ok-label="Keep Current" \
        --cancel-label="Change Defaults" \
        --extra-button="Do Not Ask Again");
    rc=$?;

    if [[ ($choice) == "Do Not Ask Again" ]]; then
        DO_NOT_ASK_AGAIN="true";
        cat <<EOF > "${CONFIG_FILE}"
DEFAULT_VIDEO_DIR="${DEFAULT_VIDEO_DIR}"
DEFAULT_AUDIO_DIR="${DEFAULT_AUDIO_DIR}"
DEFAULT_OUTPUT_DIR="${DEFAULT_OUTPUT_DIR}"
DO_NOT_ASK_AGAIN="${DO_NOT_ASK_AGAIN}"
EOF
    elif [[ ($rc) -ne 0 ]]; then
        run_initial_setup;
    fi;
fi;

VIDEO_FILE=$(zenity --file-selection \
    --title="Select Video File" \
    --filename="${DEFAULT_VIDEO_DIR}/" \
    --file-filter="Supported Video Files | *.mp4 *.mkv *.avi *.mov *.wmv *.flv *.webm *.ts *.mts *.m2ts *.vob *.ogv *.m4v *.mpg *.mpeg *.m2v *.3gp" \
    --file-filter="All Files | *");

if [[ -z ($VIDEO_FILE) ]]; then
    exit 0;
fi;

AUDIO_FILE=$(zenity --file-selection \
    --title="Select Audio File" \
    --filename="${DEFAULT_AUDIO_DIR}/" \
    --file-filter="Supported Audio Files | *.ts *.mp3 *.aac *.m4a *.wav *.flac *.ogg *.opus *.wma *.ac3 *.eac3 *.dts *.aiff *.alac *.mka" \
    --file-filter="All Files | *");

if [[ -z ($AUDIO_FILE) ]]; then
    exit 0;
fi;

if [[ ! -d "${DEFAULT_OUTPUT_DIR}" ]]; then
    DEFAULT_OUTPUT_DIR=$(dirname "${VIDEO_FILE}");
fi;

FILENAME=$(basename -- "${VIDEO_FILE}");
VID_EXT="${FILENAME##*.}";
BASENAME="${FILENAME%.*}";
OUTPUT_FILE="${DEFAULT_OUTPUT_DIR}/${BASENAME}_merged.${VID_EXT}";

echo "Attempting instant stream copy...";
ffmpeg -y -i "${VIDEO_FILE}" -i "${AUDIO_FILE}" -map 0:v:0 -map 1:a:0 -c:v copy -c:a copy "${OUTPUT_FILE}";
FFMPEG_STATUS=$?;

if [[ ($FFMPEG_STATUS) -eq 0 ]]; then
    zenity --info --title="Success" --width=380 --text="Merged file saved to:\n${OUTPUT_FILE}";
else
    echo "Incompatibility detected. Switching to Two-Step AAC Conversion...";
    TEMP_AUDIO="${DEFAULT_OUTPUT_DIR}/temp_audio_converted.m4a";

    ffmpeg -y -i "${AUDIO_FILE}" -vn -c:a aac -b:a 256k "${TEMP_AUDIO}";
    CONV_STATUS=$?;

    if [[ ($CONV_STATUS) -eq 0 ]]; then
        ffmpeg -y -i "${VIDEO_FILE}" -i "${TEMP_AUDIO}" -map 0:v:0 -map 1:a:0 -c:v copy -c:a copy "${OUTPUT_FILE}";
        MERGE_STATUS=$?;
        rm -f "${TEMP_AUDIO}";

        if [[ ($MERGE_STATUS) -eq 0 ]]; then
            zenity --info --title="Success (Converted Audio)" --width=380 --text="Audio was converted to AAC and merged!\n\nSaved to:\n${OUTPUT_FILE}";
        else
            zenity --error --title="Merge Error" --width=380 --text="FFmpeg encountered an error during the final merge phase.";
        fi;
    else
        rm -f "${TEMP_AUDIO}";
        zenity --error --title="Conversion Error" --width=380 --text="Critical error: FFmpeg failed to convert the audio file.";
    fi;
fi;