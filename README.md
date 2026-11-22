# Surplus Food Batch Register

A web application for a community pantry coordinator to record surplus food batches that are
available for collection. The coordinator can add, view, edit and delete batches. Each batch has an
item name, a quantity and unit, an expiry date and an optional collection note. The register lists
batches grouped by expiry date, soonest first, and can be searched by item name.

The application only keeps records: it does not reserve or match food to people and makes no
food-safety claims.

## Technology

| Layer | Choice |
| --- | --- |
| Backend | Java 17, Spring Boot 4, Spring Data JPA, Flyway migrations |
| Frontend | React 19, React Router, Vite |
| Database | PostgreSQL 16 (Amazon RDS in AWS, Docker locally) |
| Web server | Nginx serving the React build and proxying `/api/` to the backend |

## Repository layout

```text
api/    Spring Boot backend, Flyway migrations and API tests
web/    React frontend
infra/  Nginx site config and the local Docker Compose stack
```

## Data model

A batch records an item name (2 to 80 characters), a quantity greater than zero with at most two
decimal places, a unit (kg, g, litres, ml, items, packs, boxes or trays), an expiry date and an
optional collection note of up to 300 characters. The API validates every field and the database
enforces the positive quantity and the allowed units.

## API

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/api/health` | Health check including a database query and the running release |
| GET | `/api/batches?q=&hideExpired=` | Batches ordered by expiry date, optionally searched by name and without expired ones |
| GET | `/api/batches/{id}` | One batch |
| POST | `/api/batches` | Add a batch |
| PUT | `/api/batches/{id}` | Edit a batch |
| DELETE | `/api/batches/{id}` | Delete a batch |

Validation errors return `422` with a message for each field.

## Running locally

Requirements: Docker, Java 17, Node.js 22.

```bash
docker run -d --name surplus-db -e POSTGRES_USER=surplus -e POSTGRES_PASSWORD=surplus \
  -e POSTGRES_DB=surplus -p 5432:5432 postgres:16-alpine
cd api && ./mvnw spring-boot:run
cd web && npm ci && npm run dev
```

The frontend runs at http://localhost:5173 and proxies `/api/` to the backend on port 8080.

To run the same layout as the server (PostgreSQL, the API and Nginx with the production site
config) in containers:

```bash
docker compose -f infra/local/docker-compose.yml up -d --build
```

The app is then at http://localhost:8088.

## Tests

The API tests run against a real PostgreSQL 16 database:

```bash
docker run -d --rm --name surplus-testdb -e POSTGRES_USER=surplus -e POSTGRES_PASSWORD=surplus \
  -e POSTGRES_DB=surplus -p 55433:5432 postgres:16-alpine
cd api && ./mvnw test
cd web && npx oxlint && npm run build
```
