#!/usr/bin/env bash
set -euo pipefail

# start_rivus_bi.sh — start Rivus BI
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set Java home - using system Java if /home/rivus/tools/jdk8 doesn't exist
if [ -d "/home/rivus/tools/jdk8" ]; then
  export JAVA_HOME="/home/rivus/tools/jdk8"
else
  export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
fi
export PATH="$JAVA_HOME/bin:$PATH"

echo "Using JAVA_HOME: $JAVA_HOME"
java -version

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

# Ensure metatron-env.sh has correct Java path (idempotent)
if [ -f "$CONF_DIR/metatron-env.sh" ]; then
  if grep -q '^export JAVA_HOME=' "$CONF_DIR/metatron-env.sh"; then
    sed -i "s|^export JAVA_HOME=.*$|export JAVA_HOME=\"$JAVA_HOME\"|" "$CONF_DIR/metatron-env.sh"
  else
    echo "export JAVA_HOME=\"$JAVA_HOME\"" >> "$CONF_DIR/metatron-env.sh"
  fi
else
  # create file and add export
  echo "export JAVA_HOME=\"$JAVA_HOME\"" > "$CONF_DIR/metatron-env.sh"
fi

# Ensure application-local.yml exists with local overrides (binding, port, simple cache, disable Infinispan clustering)
if [ ! -f "$CONF_DIR/application-local.yml" ]; then
  cat > "$CONF_DIR/application-local.yml" << 'EOF'
server:
  address: 0.0.0.0
  port: 8180
spring:
  cache:
    type: simple
infinispan:
  cluster:
    enabled: false
EOF
fi

# Start Druid (if present) then Rivus BI
DRUID_HOME=$(find "$ROOT_DIR/third_party" -maxdepth 4 -type d -name 'druid-2021.2' -print -quit || true)
if [ -n "$DRUID_HOME" ] && [ -f "$DRUID_HOME/start-single.sh" ]; then
  echo "Found Druid at $DRUID_HOME"
  PIDFILE=/tmp/druid.pid
  # If pidfile exists and process is alive, skip starting
  if [ -f "$PIDFILE" ] && ps -p "$(cat \"$PIDFILE\")" >/dev/null 2>&1; then
    echo "Druid pidfile exists and process $(cat \"$PIDFILE\") is running"
  elif ss -tuln 2>/dev/null | grep -q ':8081\b'; then
    echo "Druid appears to be already running (port 8081)"
  else
    echo "Starting Druid (single) ..."
    (cd "$DRUID_HOME" && nohup ./start-single.sh > /tmp/druid.log 2>&1 & echo $! > /tmp/druid.pid)
    sleep 1
    if [ -f "$PIDFILE" ]; then
      echo "Druid started with PID $(cat \"$PIDFILE\")"
    fi
    for i in $(seq 1 60); do
      sleep 2
      if curl -s http://127.0.0.1:8081/status/health 2>/dev/null | grep -q 'true'; then
        echo "Druid coordinator healthy"
        break
      fi
      echo "Waiting for Druid (attempt $i/60)..."
    done
  fi
else
  echo "No Druid distribution found under $ROOT_DIR/third_party"
fi

# Start Rivus BI: prefer directly running the discovery server jar with local config; fallback to metatron.sh
echo "Starting Rivus BI..."
cd "$METATRON_HOME"
JAR_FILE=$(ls "$METATRON_HOME"/*.jar 2>/dev/null | grep -E 'discovery-server.*\.jar' | head -n1 || true)
if [ -n "$JAR_FILE" ]; then
  echo "Starting discovery server jar: $JAR_FILE"
  nohup "$JAVA_HOME/bin/java" -Dfile.encoding=UTF-8 -Xms512m -Xmx1024m -Dspring.config.location=file:conf/application-local.yml -Dserver.address=0.0.0.0 -Dspring.cache.type=simple -jar "$JAR_FILE" > /tmp/rivus-server.log 2>&1 &
  echo "Started PID: $!"
else
  echo "No discovery server jar found; falling back to ./bin/metatron.sh start"
  ./bin/metatron.sh start
fi

echo "Rivus BI startup initiated."
echo "To check status: ./bin/metatron.sh status (run inside $METATRON_HOME)"
echo "To stop: $ROOT_DIR/stop_rivus_bi.sh"

