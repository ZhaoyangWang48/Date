# ZhiYi (ZhiYi) — HarmonyOS Mobile Application

A sentiment-memory mobile app built with HarmonyOS (ArkTS) + Spring Boot + MySQL/H2.

## Prerequisites

| Tool | Expected Path | Version |
|---|---|---|
| Java JDK | `E:\Java21` | 21 |
| Maven | `E:\apache-maven-3.9.9` | 3.9+ |
| MySQL | `E:\SQL\mysql-8.0.20-winx64` | 8.0 |

Edit `start-server.cmd` if your paths differ.

## Quick Start

### 1. Start MySQL

```
start-mysql.cmd
```

This starts the MySQL Windows service and creates the `zhiyi` database if it does not exist.
If MySQL is unavailable, the server falls back to a local H2 file database automatically.

### 2. Start the Server

```
start-server.cmd
```

You will be prompted for two optional API keys:

- **Kimi API Key** — used for image recognition. Press Enter to skip.
- **DeepSeek API Key** — used for memory summaries and the memory guardian agent. Press Enter to skip.

Both keys are optional — the app works without them, just with reduced AI functionality.

### 3. Access the Server

The server listens on `http://localhost:8080`.
Swagger UI is available at `http://localhost:8080/swagger-ui.html`.

## Configuration

Default settings are in `server/src/main/resources/application.yml`. All values can be overridden via environment variables:

| Variable | Description | Default |
|---|---|---|
| `ZHIYI_DB_URL` | MySQL JDBC URL | `jdbc:mysql://127.0.0.1:3306/zhiyi` |
| `ZHIYI_DB_USERNAME` | MySQL username | `zhiyi_app` |
| `ZHIYI_DB_PASSWORD` | MySQL password | `REMOVED_SECRET` |
| `ZHIYI_KIMI_API_KEY` | Kimi API key | (empty) |
| `ZHIYI_AI_API_KEY` | DeepSeek API key | (empty) |
| `PORT` | Server port | `8080` |
| `ZHIYI_JWT_SECRET` | JWT signing secret | (built-in dev default) |

## Project Structure

```
Date/
├── entry/              # HarmonyOS frontend (ArkTS)
├── server/             # Spring Boot backend (Java)
├── AppScope/           # HarmonyOS app config
├── start-mysql.cmd     # MySQL startup script
├── start-server.cmd    # Server startup script
└── README.md           # This file
```
