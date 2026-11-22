#!/bin/bash
# CodeDeploy copies the bundle into incoming/; the live release in current/ is
# left alone so Nginx keeps serving the page while the new one is prepared.
set -euo pipefail
rm -rf /opt/surplus-food/incoming
mkdir -p /opt/surplus-food/incoming /opt/surplus-food/releases
