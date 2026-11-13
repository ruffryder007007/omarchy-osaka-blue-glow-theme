#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bash install.sh [--animated | --still] [--no-apply]

Install Osaka Blue Glow, including its custom Hyprland window glow.
The animated wallpaper is selected by default. --no-apply only installs files.
Existing installations are backed up before replacement. No sudo is needed.
EOF
}

wallpaper=1-osaka-blue-night-animated.mp4
apply=1
for arg in "$@"; do
  case "$arg" in
    --animated) wallpaper=1-osaka-blue-night-animated.mp4 ;;
    --still) wallpaper=0-osaka-blue-night.png ;;
    --no-apply) apply=0 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$arg" >&2; usage >&2; exit 1 ;;
  esac
done

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
theme_name=osaka-blue-glow
themes_dir="$HOME/.config/omarchy/themes"
target="$themes_dir/$theme_name"
files=(colors.toml hyprland.lua btop.theme icons.theme preview.png LICENSE CREDITS.md)
for file in "${files[@]}" backgrounds/0-osaka-blue-night.png backgrounds/1-osaka-blue-night-animated.mp4; do
  [[ -f "$source_dir/$file" ]] || { printf 'Missing theme file: %s\n' "$file" >&2; exit 1; }
done
if (( apply )); then
  command -v omarchy >/dev/null || { echo 'Omarchy is required. Use --no-apply to only install files.' >&2; exit 1; }
fi

mkdir -p -- "$themes_dir"
stage=$(mktemp -d "$themes_dir/.osaka-blue-glow.XXXXXXXX")
trap 'rm -rf -- "$stage"' EXIT
mkdir -p -- "$stage/backgrounds"
for file in "${files[@]}"; do cp -- "$source_dir/$file" "$stage/$file"; done
cp -- "$source_dir/backgrounds/0-osaka-blue-night.png" "$stage/backgrounds/"
cp -- "$source_dir/backgrounds/1-osaka-blue-night-animated.mp4" "$stage/backgrounds/"

# An explicit local installation retains the custom Hyprland Lua. Git
# metadata, development tools and old animation renders are never installed.
if [[ -e "$target" || -L "$target" ]]; then
  backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/theme-backups/$theme_name"
  mkdir -p -- "$backup_root"
  backup="$backup_root/$(date +%Y%m%d-%H%M%S)-$$"
  mv -- "$target" "$backup"
  printf 'Previous theme saved to %s\n' "$backup"
fi
mv -- "$stage" "$target"
printf 'Installed %s\n' "$target"

if (( apply )); then
  omarchy theme set "Osaka Blue Glow"
  omarchy theme bg set "$HOME/.local/state/omarchy/current/theme/backgrounds/$wallpaper"
  if command -v hyprctl >/dev/null; then
    hyprctl reload
    errors=$(hyprctl configerrors)
    if [[ -n ${errors//[[:space:]]/} ]]; then
      printf 'Hyprland reported configuration errors:\n%s\n' "$errors" >&2
      exit 1
    fi
  fi
  echo 'Osaka Blue Glow is active. Switch wallpapers with: omarchy theme bg next'
fi
