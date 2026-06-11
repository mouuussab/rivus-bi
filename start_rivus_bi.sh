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

