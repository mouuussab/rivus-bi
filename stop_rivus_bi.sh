#!/usr/bin/env bash
set -euo pipefail

# stop_rivus_bi.sh — stop Rivus BI
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set Java home - using system Java if /home/rivus/tools/jdk8 doesn't exist
if [ -d "/home/rivus/tools/jdk8" ]; then
  export JAVA_HOME="/home/rivus/tools/jdk8"
else
  export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
fi
export PATH="$JAVA_HOME/bin:$PATH"

echo "Using JAVA_HOME: $JAVA_HOME"

echo "Locating Rivus BI binary home..."
METATRON_HOME=$(find "$ROOT_DIR/discovery-distribution/target" -type d -name "conf" | head -n 1 | xargs dirname 2>/dev/null || true)

if [ -z "$METATRON_HOME" ] || [ ! -d "$METATRON_HOME" ]; then
  echo "Error: Rivus BI binary not found." >&2
  exit 1
fi

echo "Found Rivus BI Home: $METATRON_HOME"

# Stop Rivus BI: prefer stopping discovery server jar processes, fallback to metatron.sh stop
echo "Stopping Rivus BI..."
cd "$METATRON_HOME"

# source metatron-env.sh if present to pick up JAVA_HOME set by start script
if [ -f "$CONF_DIR/metatron-env.sh" ]; then
  # shellcheck disable=SC1090
  . "$CONF_DIR/metatron-env.sh"
fi

JAR_FILE=$(ls "$METATRON_HOME"/*.jar 2>/dev/null | grep -E 'discovery-server.*\\.jar' | head -n1 || true)
if [ -n "$JAR_FILE" ]; then
  BASENAME=$(basename "$JAR_FILE")
  PIDS=$(pgrep -f "$BASENAME" || true)
  if [ -n "$PIDS" ]; then
    echo "Found discovery server PIDs: $PIDS; sending TERM..."
    kill $PIDS || true
    sleep 5
    STILL=$(pgrep -f "$BASENAME" || true)
    if [ -n "$STILL" ]; then
      echo "Processes still running, sending KILL..."
      kill -9 $STILL || true
    fi
    echo "Stopped discovery server."
    exit 0
  fi
fi

# Fallback to metatron.sh stop
if [ -x "./bin/metatron.sh" ]; then
  echo "No direct jar process found; running ./bin/metatron.sh stop"
  ./bin/metatron.sh stop
else
  echo "No discovery server process found and metatron.sh not present."
fi

