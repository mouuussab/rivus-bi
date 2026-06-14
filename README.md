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
5. **Custom Druid**: Requires the customized and patched Druid engine. Download it from the [Google Drive link](https://drive.google.com/file/d/1q_iL574KOQFTDbAVqpKOrDUiAdW_x9yv/view).

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

### 4. Running the Druid Engine
Extract the downloaded customized Druid archive (`druid-2021.2.tar.gz`) and start it inside its directory:
```bash
tar -xzf druid-2021.2.tar.gz
cd druid-2021.2
JAVA_HOME=/path/to/jdk8 PATH=$JAVA_HOME/bin:$PATH ./start-single.sh
```
*(This starts the custom Druid services: Zookeeper, Coordinator, Broker, Historical, MiddleManager, and Overlord).*

### 5. Running the Application
Start the Rivus BI server using the root startup script:
```bash
./start_rivus_bi.sh
```
The script locates the compiled distribution, initializes the default configuration profiles (`application-config.yaml` and environment settings), and starts the service in daemon mode.

- **Access Console**: Open your browser and navigate to `http://localhost:8180` (or `http://localhost:8180/app/v2/user/login`).
- **Default Login**:
  - **Username**: `admin`
  - **Password**: `admin` (or the custom password set during configuration)

### 6. Stopping the Application
Stop the running server instance with:
```bash
./stop_rivus_bi.sh
```

To stop the custom Druid engine:
```bash
cd druid-2021.2
./stop-single.sh
```


## Screenshots

![Rivus dashboard](docs/screenshots/rivus-bi/rivus%20dashboard.png)

![Rivus login](docs/screenshots/rivus-bi/rivus%20login.png)

