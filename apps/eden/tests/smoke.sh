#!/usr/bin/env bash
source /smoke-common/lib.sh

assert_path /Applications/eden.AppImage
assert_path /opt/gow/startup-app.sh

if [[ -x /Applications/eden.AppImage ]]; then
  ok "eden.AppImage is executable"
else
  bad "eden.AppImage is executable"
fi

smoke_report
