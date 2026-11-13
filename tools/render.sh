#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
output=${1:-"$root/backgrounds/1-osaka-blue-night-animated.mp4"}
[[ ! -e "$output" ]] || { echo "Output already exists: $output" >&2; exit 1; }
for command in ffmpeg magick g++; do
  command -v "$command" >/dev/null || { echo "Required: $command" >&2; exit 1; }
done
temp_dir=$(mktemp -d)
trap 'rm -rf -- "$temp_dir"' EXIT
ffmpeg -hide_banner -loglevel error -i "$root/backgrounds/0-osaka-blue-night.png" \
  -vf crop=1672:940 -frames:v 1 -f rawvideo -pix_fmt rgb24 "$temp_dir/base.rgb"
magick -size 1672x940 xc:black -fill white \
  -draw 'polygon 560,0 1480,0 1450,225 1380,280 1370,345 1300,395 1280,470 1180,540 1130,552 1080,510 990,485 950,440 875,425 850,380 730,345 610,340 550,265' \
  -blur 0x10 -depth 8 "gray:$temp_dir/sky.gray"
g++ -O3 -o "$temp_dir/animate" "$root/tools/animate.cpp"
"$temp_dir/animate" "$temp_dir/base.rgb" "$temp_dir/sky.gray" | \
  ffmpeg -hide_banner -loglevel warning -f rawvideo -pixel_format rgb24 \
    -video_size 1672x940 -framerate 24 -i pipe:0 -an \
    -vf scale=1920:1080:flags=lanczos -c:v libx264 -preset medium \
    -tune stillimage -crf 14 -pix_fmt yuv420p -movflags +faststart "$output"
