#!/bin/bash
# Usage: getaudio --url "URL" [--artist "Artist"] [--title "Title"] [--year "Year"] [--genre "Genre"] [--output-dir "OutputDir"]

if [ -z "$1" ]; then
    echo "Usage: getaudio --url \"URL\" [--artist \"Artist\"] [--title \"Title\"] [--year \"Year\"] [--genre \"Genre\"] [--output-dir \"OutputDir\"]"
    exit 1
fi

command -v yt-dlp >/dev/null 2>&1 || { echo "yt-dlp not found. Please install it."; exit 1; }
command -v ffmpeg >/dev/null 2>&1 || { echo "ffmpeg not found. Please install it."; exit 1; }

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --url) URL="$2"; shift 2 ;;
    --artist) ARTIST="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    --year) YEAR="$2"; shift 2 ;;
    --genre) GENRE="$2"; shift 2 ;;
    --outputDir) OUTPUT_DIR="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [ -z "${URL:-}" ]; then
  echo "Error: --url is required"
  exit 1
fi

OUTPUT_DIR="${OUTPUT_DIR:-./}"
if [ ! -d "$OUTPUT_DIR" ]; then
  echo "Error: Output directory \"$OUTPUT_DIR\" does not exist."
  exit 1
fi

# Sanitize filename parts
sanitize() {
  echo "$1" | tr '/\\?%*:|"<>.' '_'
}

if [ -n "$ARTIST" ] && [ -n "$TITLE" ]; then
  safe_artist=$(sanitize "$ARTIST")
  safe_title=$(sanitize "$TITLE")
  OUTPUT_FILE="${safe_artist} - ${safe_title}"
else
  OUTPUT_FILE="%(title)s"
fi

mkdir -p /tmp/mp3get
TEMP_FILE="/tmp/mp3get/$(date +%s%N).%(ext)s"

echo "Downloading bestaudio..."
downloaded_file=$(yt-dlp -f "bestaudio" --output "$TEMP_FILE" --print after_move:filepath "$URL")

if [ $? -ne 0 ]; then
  echo "Download failed!"
  exit 1
fi

ext="${downloaded_file##*.}"

# Decide final extension and filename
if [[ "$ext" == "webm" ]]; then
  echo "Re-containering webm to opus"
  final_ext="opus"
else
  final_ext="$ext"
fi

FINAL_FILE="${OUTPUT_DIR}/${OUTPUT_FILE}.${final_ext}"

# Build ffmpeg command: copy streams, add metadata, output directly to final file
ffmpeg_cmd=(ffmpeg -hide_banner -i "$downloaded_file" -c copy)

[ -n "$ARTIST" ] && ffmpeg_cmd+=(-metadata artist="$ARTIST")
[ -n "$TITLE" ] && ffmpeg_cmd+=(-metadata title="$TITLE")
[ -n "$YEAR" ] && ffmpeg_cmd+=(-metadata date="$YEAR")
[ -n "$GENRE" ] && ffmpeg_cmd+=(-metadata genre="$GENRE")

ffmpeg_cmd+=("$FINAL_FILE")

"${ffmpeg_cmd[@]}"

if [ $? -ne 0 ]; then
  echo "Tagging/re-containering failed!"
  rm -f "$downloaded_file"
  exit 1
fi

rm -f "$downloaded_file"

echo "Done! File saved to: $FINAL_FILE"
