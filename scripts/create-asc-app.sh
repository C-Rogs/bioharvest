#!/usr/bin/env bash
set -euo pipefail

# Creates the App Store Connect app record for bioharvest.
# Run once in Terminal (interactive Apple ID login).
#
# After this succeeds:
#   ./scripts/testflight.sh export

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="/opt/homebrew/bin:$PATH"

fastlane produce create \
  -u "${APPLE_ID:-cameronfoxrogers@gmail.com}" \
  -a com.cameronro.bioharvest \
  --app_name bioharvest \
  --sku bioharvest \
  --team_id SXWJBD2V3V \
  --platform ios

echo ""
echo "App record created. Upload with:"
echo "  cd $ROOT && ./scripts/testflight.sh export"
