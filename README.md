# Omarchy Directory (Rails + PostgreSQL)

A minimal Rails app that lists webapps and supports one-click installs via the `omarchy://` URL scheme, calling your local `omarchy-install-handler` script.

## Quick Start

- Ensure Ruby, Bundler, and PostgreSQL are installed and running locally.
- Create database and run migrations:

```
cd Omarchy_Directory
bundle install
bin/rake db:create db:migrate db:seed
bin/rails s
```

Visit `http://localhost:3000`.

Production runs at `https://omarchy.app` (set `APP_HOST=omarchy.app`).

## URL Scheme Setup

Visit `/setup` for instructions and downloads to register the `omarchy://` handler.

## JSON API

- `GET /webapps.json` → `{ apps: [{ id, name, url, icon }] }`

## Notes

- Database config is in `config/database.yml` (defaults user/password `omarchy/omarchy`). Override with `PG*` env vars as needed.
- Minimal app without Sprockets; styling is inline.

## Docker

Local dev via Docker + Compose:

```
docker compose up --build
```

Then visit `http://localhost:3000`.

Quick checks:

```
curl -s http://localhost:3000/webapps.json | jq .
xdg-open 'http://localhost:3000/setup'
```

Notes:
- Compose starts `postgres:16` and the Rails app. The entrypoint waits for DB, runs `db:prepare` and seeds.
- Gems are cached in the `bundle` volume. Code is bind-mounted from `./Omarchy_Directory` for live reload.
