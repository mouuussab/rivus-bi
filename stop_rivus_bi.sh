#!/usr/bin/env bash
set -euo pipefail

# stop_rivus_bi.sh — stop Rivus BI
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export JAVA_HOME="/home/rivus/tools/jdk8"
export PATH="$JAVA_HOME/bin:$PATH"

echo "Locating Rivus BI binary home..."
METATRON_HOME=$(find "$ROOT_DIR/discovery-distribution/target" -type d -name "conf" | head -n 1 | xargs dirname 2>/dev/null || true)

if [ -z "$METATRON_HOME" ] || [ ! -d "$METATRON_HOME" ]; then
  echo "Error: Rivus BI binary not found." >&2
  exit 1
fi

echo "Found Rivus BI Home: $METATRON_HOME"

# Run the metatron stop script
echo "Stopping Rivus BI..."
cd "$METATRON_HOME"
./bin/metatron.sh stop
