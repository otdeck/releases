#!/usr/bin/env bash
# Installs an OTDeck .deb, .rpm or .tar.gz, checks the files and the
# version, talks to otdeck-mcp, starts the app as a normal user under Xvfb
# with a D-Bus session (as a desktop has) for 20 s, checks that its window
# exists (screenshot), then removes it. Runs as root (container) or with
# sudo (GitHub's Ubuntu machine).
# Usage: linux.sh <package file> <version> [tool count] [screenshot dir]
set -euxo pipefail
pkg=$(readlink -f "$1") want=$2 tools=${3:-} shots=${4:-}
here=$(cd "$(dirname "$0")" && pwd)
sudo=(); [ "$(id -u)" = 0 ] || sudo=(sudo -E)

case "$pkg" in *.tar.gz) kind=tar ;; *.deb) kind=deb ;; *.rpm) kind=rpm ;; *) echo "unknown package $pkg"; exit 1 ;; esac
if command -v apt-get >/dev/null; then
  export DEBIAN_FRONTEND=noninteractive
  # The runner image's own apt timers can hold the dpkg lock for minutes.
  "${sudo[@]}" systemctl stop unattended-upgrades apt-daily.timer apt-daily-upgrade.timer apt-daily.service apt-daily-upgrade.service 2>/dev/null || true
  # The man-db trigger can hang for many minutes on the runner images.
  "${sudo[@]}" rm -f /var/lib/man-db/auto-update
  apt=("${sudo[@]}" apt-get -o DPkg::Lock::Timeout=300)
  "${apt[@]}" update -qq
  "${apt[@]}" install -y -qq xvfb xauth python3 procps x11-utils dbus-x11 imagemagick >/dev/null
  if [ $kind = deb ]; then
    "${apt[@]}" install -y "$pkg"
    got=$(dpkg-query -W -f='${Version}' otdeck)
    remove=("${apt[@]}" remove -y otdeck)
  else
    # The tar.gz needs the same libraries the .deb depends on.
    "${apt[@]}" install -y -qq libgtk-4-1 libwebkitgtk-6.0-4 >/dev/null
  fi
else
  "${sudo[@]}" dnf install -y -q xorg-x11-server-Xvfb xorg-x11-xauth python3 procps-ng xwininfo dbus-daemon dbus-x11 ImageMagick
  if [ $kind = rpm ]; then
    "${sudo[@]}" dnf install -y -q "$pkg"
    got=$(rpm -q --qf '%{VERSION}-%{RELEASE}' otdeck)
    remove=("${sudo[@]}" dnf remove -y otdeck)
  else
    "${sudo[@]}" dnf install -y -q gtk4 webkitgtk6.0
  fi
fi

if [ $kind = tar ]; then
  root=$(mktemp -d /opt/otdeck-smoke.XXXX 2>/dev/null || "${sudo[@]}" mktemp -d /opt/otdeck-smoke.XXXX)
  "${sudo[@]}" tar -xzf "$pkg" -C "$root"
  "${sudo[@]}" chmod 755 "$root"
  find "$root" -maxdepth 2 | sort
  app=$(find "$root" -maxdepth 2 -type f -name otdeck | head -1)
  mcp=$(find "$root" -maxdepth 2 -type f -name otdeck-mcp | head -1)
  [ -n "$app" ] && [ -n "$mcp" ] || { echo "otdeck or otdeck-mcp missing in the tar.gz"; exit 1; }
  got=$want  # no package database; otdeck-mcp -version below checks it
  remove=("${sudo[@]}" rm -rf "$root")
else
  app=/usr/bin/otdeck mcp=/usr/bin/otdeck-mcp
  test -f /usr/share/applications/otdeck.desktop
  test -f /usr/share/icons/hicolor/1024x1024/apps/otdeck.png
fi
test -x "$app"
test -x "$mcp"
echo "installed version: $got"
[ "${got%%-*}" = "$want" ] || { echo "installed $got, expected $want"; exit 1; }
mv=$("$mcp" -version)
echo "otdeck-mcp -version: $mv"
grep -qF " $want " <<<"$mv " || { echo "otdeck-mcp is not version $want"; exit 1; }
grep -q 'licence=on' <<<"$mv" || { echo "otdeck-mcp was built without the licence check"; exit 1; }

# A fresh app directory, no licence: the Free plan must answer.
appdir=$(mktemp -d)
python3 "$here/mcp-check.py" "$mcp" "$appdir" "$tools"

# A normal user, not root: that is how people run it, and WebKit's sandbox
# behaves differently for root.
runas=()
if [ "$(id -u)" = 0 ]; then
  id kd >/dev/null 2>&1 || useradd -m kd
  runas=(su kd -c)
fi
rm -f /tmp/otdeck-linux.png /tmp/otdeck.log
cat > /tmp/kd-start.sh <<SH
set -u
"$app" > /tmp/otdeck.log 2>&1 &
pid=\$!
sleep 20
if ! kill -0 "\$pid" 2>/dev/null; then cat /tmp/otdeck.log; echo "OTDeck exited"; exit 1; fi
xwininfo -root -tree | grep -i otdeck || { cat /tmp/otdeck.log; echo "no OTDeck window"; exit 1; }
ps -o rss=,args= -p "\$pid"
import -window root /tmp/otdeck-linux.png 2>/dev/null || true
kill "\$pid"
echo "OTDeck started and showed its window"
SH
chmod 755 /tmp/kd-start.sh
cmd='dbus-run-session -- xvfb-run -a -s "-screen 0 1440x900x24" bash /tmp/kd-start.sh'
start() { if [ ${#runas[@]} -gt 0 ]; then "${runas[@]}" "$cmd"; else bash -c "$cmd"; fi; }
started=0
start && started=1
tail -n 20 /tmp/otdeck.log || true
if [ -n "$shots" ] && [ -f /tmp/otdeck-linux.png ]; then mkdir -p "$shots"; cp /tmp/otdeck-linux.png "$shots/"; chmod -R a+rw "$shots" || true; fi
[ "$started" = 1 ] || { echo "OTDeck did not start"; exit 1; }

"${remove[@]}"
test ! -e "$app"
echo "removed"
