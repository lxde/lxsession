#!/bin/sh

# FIXME: pgrep is not portable.
# Replace it with better cross-platform solution later.

# gnome-screensaver
if pgrep gnome-screensaver >/dev/null 2>&1; then
    gnome-screensaver-command --lock && exit 0
fi

# xscreensaver
if pgrep xscreensaver >/dev/null 2>&1; then
    xscreensaver-command -lock && exit 0
fi

# other locking tools
for cmd in "xlock -mode blank"
do
    $cmd >/dev/null 2>&1 && exit 0
done

# locking failed
exit 1
