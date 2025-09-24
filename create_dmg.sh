#!/usr/bin/env bash
# run from the archive directory to create a release .dmg from .app
create-dmg \
  --window-pos 200 120 \
  --icon "Keydion.app" 22 111 \
  --app-drop-link 250 111 \
  "Keydion.dmg" \
  "Keydion.app"
