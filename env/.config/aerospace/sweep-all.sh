#!/usr/bin/env bash
# Sweep every app into its designated AeroSpace workspace.
# Run after editing rules or when windows drift out of place.

set -u
AS=/opt/homebrew/bin/aerospace

# bundle-id → workspace (keep in sync with aerospace.toml and rules.ts)
declare -a MAP=(
  "company.thebrowser.Browser:B"
  "com.apple.Safari:B"
  "com.jetbrains.intellij:I"
  "net.whatsapp.WhatsApp:W"
  "md.obsidian:O"
  "com.kapeli.dashdoc:D"
  "com.spotify.client:M"
  "com.apple.Music:M"
  "com.apple.iCal:C"
  "com.apple.systempreferences:Y"
  "org.pqrs.Karabiner-Elements.Settings:Y"
  "com.mitchellh.ghostty:T"
  "com.apple.Terminal:T"
  "com.apple.finder:E"
  "us.zoom.xos:Z"
)

for entry in "${MAP[@]}"; do
  bundle="${entry%:*}"
  ws="${entry##*:}"
  wids=$("$AS" list-windows --monitor all --app-bundle-id "$bundle" --format '%{window-id}' 2>/dev/null)
  [ -z "$wids" ] && continue
  echo "→ $bundle → $ws"
  while read -r w; do
    [ -n "$w" ] && "$AS" move-node-to-workspace --window-id "$w" "$ws"
  done <<< "$wids"
  "$AS" balance-sizes --workspace "$ws"
done

echo "Done."
