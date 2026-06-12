# Rivus BI

Welcome to **Rivus BI**, a powerful and highly scalable Business Intelligence tool powered by an embedded Apache Druid analytical engine. This repository contains the backend and frontend components needed to manage and explore your Data Storage.

If you are a complete beginner, don't worry! This guide will walk you through exactly how to run this project on your machine.

## Prerequisites

Before you start, make sure you have the following installed on your computer:
1. **Java 8**: Rivus BI requires Java 8. Ensure `JAVA_HOME` is set properly.
2. **Node.js**: Required to build the frontend.
3. **Maven**: Required to build the backend Java application.
4. **Python 3**: Used to start the embedded database.

## How to Start Rivus BI

We have provided simple, automated scripts to make running Rivus BI as easy as double-clicking a button.

1. **Open your terminal** and navigate to the `rivus-bi` folder.
   ```bash
   cd /path/to/rivus-bi
   ```

2. **Start the application** by running the start script:
   ```bash
   ./start_rivus_bi.sh
   ```
   *What this script does:* 
   - It starts an embedded **H2 Database** on port 9092.
   - It spins up the **Apache Druid** analytical engine (this is what holds your data and makes it incredibly fast to query).
   - It starts the **Rivus BI Web Server** on port `8180`.

3. **Access the Web Interface**
   Once the terminal says the server has started, open your web browser and go to:
   ```
   http://localhost:8180
   ```
   *Default Login:* `admin` / `admin`

## How to Stop Rivus BI

When you are finished using Rivus BI, you should stop it properly to avoid leaving background processes running on your computer.

1. In your terminal, run:
   ```bash
   ./stop_rivus_bi.sh
   ```
   This will safely shut down the web server, Apache Druid, and the H2 database.

## Next Steps

Rivus BI is part of a larger ecosystem! Once you have prepared your data snapshots in Rivus BI, you can seamlessly connect them to AI. 
Check out the **[bi-ai-link](https://github.com/mouuussab/bi-ai-link)** repository to set up the automated Data Lake bridge!
