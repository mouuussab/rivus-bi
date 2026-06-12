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
CONF_DIR="$METATRON_HOME/conf"

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

# Stop Druid (if started by start_rivus_bi.sh)
DRUID_PIDFILE=/tmp/druid.pid
if [ -f "$DRUID_PIDFILE" ]; then
  DRUID_PID=$(cat "$DRUID_PIDFILE" 2>/dev/null || true)
  if [ -n "$DRUID_PID" ] && ps -p "$DRUID_PID" >/dev/null 2>&1; then
    echo "Stopping Druid (PID $DRUID_PID)..."
    kill "$DRUID_PID" || true
    sleep 5
    if ps -p "$DRUID_PID" >/dev/null 2>&1; then
      echo "Druid still running; sending KILL..."
      kill -9 "$DRUID_PID" || true
    fi
    rm -f "$DRUID_PIDFILE" || true
  else
    echo "Stale or missing Druid PID in $DRUID_PIDFILE; removing file."
    rm -f "$DRUID_PIDFILE" || true
  fi
else
  # Try to find Druid by scanning java processes started from DRUID_HOME
  if [ -L "$ROOT_DIR/third_party/druid-latest" ]; then
    DRUID_HOME=$(readlink -f "$ROOT_DIR/third_party/druid-latest")
  else
    DRUID_HOME=$(find "$ROOT_DIR/third_party" -maxdepth 3 -type d -name 'druid-2021.2' -print -quit || true)
  fi
  if [ -n "$DRUID_HOME" ] && [ -d "$DRUID_HOME" ]; then
    echo "Looking for Druid java processes under $DRUID_HOME..."
    PIDS=""
    for pid in $(pgrep -f 'ServerRunnable' 2>/dev/null || true); do
      if [ -d "/proc/$pid" ]; then
        cwd=$(readlink -f /proc/$pid/cwd 2>/dev/null || true)
        case "$cwd" in
          "$DRUID_HOME"*) PIDS="$PIDS $pid";;
        esac
      fi
    done
    if [ -n "$PIDS" ]; then
      echo "Found Druid PIDs:$PIDS; sending TERM..."
      kill $PIDS || true
      sleep 5
      STILL=""
      for pid in $PIDS; do
        if ps -p "$pid" >/dev/null 2>&1; then STILL="$STILL $pid"; fi
      done
      if [ -n "$STILL" ]; then
        echo "Processes still running, sending KILL..."
        kill -9 $STILL || true
      fi
    else
      echo "No Druid process found."
    fi
  else
    echo "No Druid installation detected; skipping Druid stop."
  fi
fi

# Deduplicate discovery-server processes: keep the most recently started
PIDS_ALL=$(pgrep -f 'discovery-server.*\.jar' || true)
if [ -n "$PIDS_ALL" ]; then
  echo "Deduplicating discovery-server processes: $PIDS_ALL"
  pids_arr=()
  for pid in $PIDS_ALL; do
    if [ -d "/proc/$pid" ]; then
      cmd=$(tr '\0' ' ' < /proc/$pid/cmdline 2>/dev/null || true)
      if echo "$cmd" | grep -q 'discovery-server'; then
        pids_arr+=("$pid")
      fi
    fi
  done

  if [ ${#pids_arr[@]} -gt 1 ]; then
    # keep the most recently started (smallest etimes)
    keep=${pids_arr[0]}
    keep_etimes=$(ps -p "$keep" -o etimes= | tr -d ' ' || echo 99999999)
    for pid in "${pids_arr[@]}"; do
      etimes=$(ps -p "$pid" -o etimes= | tr -d ' ' || echo 99999999)
      if [ "$etimes" -lt "$keep_etimes" ]; then
        keep=$pid
        keep_etimes=$etimes
      fi
    done

    echo "Keeping PID $keep; stopping others: ${pids_arr[*]}"

    for pid in "${pids_arr[@]}"; do
      if [ "$pid" != "$keep" ]; then
        echo "Sending TERM $pid"
        kill "$pid" || true
      fi
    done

    sleep 3

    for pid in "${pids_arr[@]}"; do
      if [ "$pid" != "$keep" ] && ps -p "$pid" >/dev/null 2>&1; then
        echo "KILL $pid"
        kill -9 "$pid" || true
      fi
    done
  else
    echo "No duplicate discovery-server processes found."
  fi
fi

