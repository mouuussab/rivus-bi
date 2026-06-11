# Rivus BI

Rivus BI is an end-to-end big data self-discovery solution, built for interactive data analysis, preparation, and beautiful visualization.

## Key Features

- **Interactive Dashboards**: Numerous preloaded charts and customizable data widgets.
- **Data Wrangling & Preparation**: GUI-based data wrangling and query (SQL) based exploration.
- **Various Data Source Connections**: Connect to database engines, Hive, or Kafka streams.
- **Geo-Spatial Analysis**: Geospatial analysis support with map visualizations.
- **Metadata Management**: Fine-grained schema management and data dictionary options.
- **Access Control**: Workspace-level permissions and fine-grained access control of users.
- **Full API Support**: Completely backed by APIs for easy integration.

---

## Prerequisites

Before building and running the project, make sure the following dependencies are installed:

1. **Java Development Kit (JDK) 8**: The backend compilation and runtime require JDK 8. Ensure `JAVA_HOME` is set to your JDK 8 path.
2. **Apache Maven**: Required to compile the project.
3. **Node.js & NPM**: The frontend build uses Node.js `v14.15.4` and NPM `6.14.10`. These will automatically be downloaded and installed locally under `discovery-frontend` during the Maven build using the `frontend-maven-plugin`.
4. **Git**: Required to clone the repository.

---

## Build and Run Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/mouuussab/rivus-bi.git
cd rivus-bi
```

### 2. Set Environment Variables
Point your environment to Java 8 and make sure Maven is available in your shell `PATH`:
```bash
export JAVA_HOME="/path/to/jdk8"
export PATH="$JAVA_HOME/bin:$PATH"
```

### 3. Build the Project
Compile the frontend and backend, then package the final server distribution by running:
```bash
mvn clean install -Dmaven.test.skip=true
```
*(This process compiles the Java classes, packages the Angular frontend production bundle, and builds the target distribution package in `discovery-distribution/target/`.)*

### 4. Running the Application
Start the Rivus BI server using the root startup script:
```bash
./start_rivus_bi.sh
```
The script locates the compiled distribution, initializes the default configuration profiles (`application-config.yaml` and `metatron-env.sh`), and starts the service in daemon mode.

- **Access Console**: Open your browser and navigate to `http://localhost:8180` (or `http://localhost:8180/app/v2/user/login`).
- **Default Login**:
  - **Username**: `admin`
  - **Password**: `admin` (or the custom password set during configuration)

### 5. Stopping the Application

Stop the running server instance with:
```bash
./stop_rivus_bi.sh
```

## Important notes

Follow this checklist to run Rivus BI on a fresh machine and avoid the issues encountered here:

- Install JDK 8 and set JAVA_HOME: ensure `JAVA_HOME` points to Java 8. The start script prefers `/home/rivus/tools/jdk8` if present; otherwise update `JAVA_HOME` to your system JDK (e.g. `/usr/lib/jvm/java-8-openjdk-amd64`).
- Build the project: run `mvn clean install -Dmaven.test.skip=true` to produce the distribution under `discovery-distribution/target/`.
- Use the provided start script: run `./start_rivus_bi.sh` from the repo root. The script will create or update `conf/metatron-env.sh` (idempotently) and will create `conf/application-local.yml` with sensible defaults (bind to `0.0.0.0`, port `8180`, `spring.cache.type: simple`, and Infinispan disabled).
- If your deployment requires plugins, restore the PluginManager and provide the plugins directory; the current default in this repo is a NoOp PluginManager to avoid plugin-related crashes during local runs.
- Logs: runtime logs are written to `/tmp/rivus-server.log` by the start script; run the server in foreground for debugging with:

```bash
# from METATRON_HOME (distribution root)
java -Dfile.encoding=UTF-8 -Xms512m -Xmx1024m -Dspring.config.location=file:conf/application-local.yml -jar discovery-server-*.jar
```

- Firewall/Network: ensure port 8180 is reachable from your client and no host firewall blocks it. For local tests use `http://localhost:8180`; for remote access use the machine IP (e.g., `http://192.168.x.y:8180`).

If the server crashes or the browser shows ERR_CONNECTION_REFUSED, collect `/tmp/rivus-server.log` and the timestamp from the browser DevTools and open an issue or contact for troubleshooting.

## Screenshots

![Rivus dashboard](docs/screenshots/rivus-bi/rivus%20dashboard.png)

![Rivus login](docs/screenshots/rivus-bi/rivus%20login.png)

