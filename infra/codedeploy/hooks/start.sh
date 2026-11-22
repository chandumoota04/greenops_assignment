#!/bin/bash
# Switches current/ to the new release in one rename, so a request never finds
# the web root missing, then restarts the API on the new jar.
set -euo pipefail
cd /opt/surplus-food
release=$(cat incoming/RELEASE)

ln -sfn "releases/$release" current.next
if [ -d current ] && [ ! -L current ]; then rm -rf current; fi
mv -Tf current.next current

systemctl enable surplus-food
systemctl restart surplus-food
systemctl reload nginx || systemctl restart nginx

# Keep the three newest releases on disk.
ls -1dt releases/* | tail -n +4 | xargs -r rm -rf
