#!/usr/bin/env bash
set -euo pipefail

# start_rivus_bi.sh — start Rivus BI
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export JAVA_HOME="/home/rivus/tools/jdk8"
export PATH="$JAVA_HOME/bin:$PATH"

echo "Locating Rivus BI binary home..."
METATRON_HOME=$(find "$ROOT_DIR/discovery-distribution/target" -type d -name "conf" | head -n 1 | xargs dirname 2>/dev/null || true)

if [ -z "$METATRON_HOME" ] || [ ! -d "$METATRON_HOME" ]; then
  echo "Error: Rivus BI binary not found. Please build the project first." >&2
  exit 1
fi

echo "Found Rivus BI Home: $METATRON_HOME"

# Check and copy config templates if they do not exist
CONF_DIR="$METATRON_HOME/conf"
if [ ! -f "$CONF_DIR/application-config.yaml" ]; then
  echo "Creating application-config.yaml from template..."
  cp "$CONF_DIR/application-config.templete.yaml" "$CONF_DIR/application-config.yaml"
fi
if [ ! -f "$CONF_DIR/metatron-env.sh" ]; then
  echo "Creating metatron-env.sh from template..."
  cp "$CONF_DIR/metatron-env.sh.templete" "$CONF_DIR/metatron-env.sh"
fi

# Run the metatron start script
echo "Starting Rivus BI..."
cd "$METATRON_HOME"
./bin/metatron.sh start

echo "Rivus BI startup initiated."
echo "To check status: ./bin/metatron.sh status (run inside $METATRON_HOME)"
echo "To stop: $ROOT_DIR/stop_rivus_bi.sh"
