#!/usr/bin/env bash
set -euo pipefail

MODULES_DIR="$(dirname "$0")/modules"

echo "=== Starting provisioning ==="

# List of modules to run
modules=(
  "install_chromium.sh"
  "install_new_relic.sh"
)

for module in "${modules[@]}"; do
  module_path="$MODULES_DIR/$module"
  if [[ -f "$module_path" ]]; then
    echo "=== Running module: $module ==="
    bash "$module_path"
    echo "=== Finished module: $module ==="
  else
    echo "Module $module_path not found, skipping..."
  fi
done

echo "=== Provisioning complete ==="

# Usage:
# chmod +x provisioning/provision.sh
# chmod +x provisioning/modules/*.sh
# ./provisioning/provision.sh
