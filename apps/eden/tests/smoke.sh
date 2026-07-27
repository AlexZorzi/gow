#!/usr/bin/env bash
source /smoke-common/lib.sh

assert_path /Applications/eden.AppImage
assert_path /opt/gow/startup.sh

if [[ -x /Applications/eden.AppImage ]]; then
  ok "eden.AppImage is executable"
else
  bad "eden.AppImage is executable"
fi

assert_has xfce4-session xfce4-panel xfwm4 xfdesktop xfce4-terminal \
           xfce4-settings-manager firefox bwrap

assert_version xfce4-session --version
assert_version xfwm4 --version
assert_version firefox --version

# bwrap needs setuid so sandboxed launches work.
if [[ -u /usr/bin/bwrap ]]; then
  ok "bwrap is setuid root"
else
  bad "bwrap is setuid root"
fi

assert_path /opt/gow/xfce4

smoke_report
