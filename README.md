> [!TIP]
> Want to see a project built with this image?
> Check out [Listing Lab](https://github.com/adomi-io/listing-lab) for a complete example.

# adomi-io/odoo-adomi-community

This extends our upstream [`odoo/odoo`](https://github.com/adomi-io/odoo) image.

This repository builds a community-focused Odoo base image.

It contains a selection of OCA packages and utilities to make it easier to get started when developing 
applications based on Odoo community edition.


> [!NOTE]
> Adomi is an Odoo partner and consulting company. This repo is a foundation for
> our open-source Odoo projects and the way we prefer to ship Odoo for modern
> software teams.

> [!WARNING]
> This is not the official Odoo image.
> If you’re looking for the official upstream image, see
> [`odoo/docker`](https://github.com/odoo/docker).

## Highlights

- **Curated community stack** baked into `/volumes/extra_addons` via a multi-stage
  [`Dockerfile`](./Dockerfile)
- **Meta addon**: [`addons/adomi_community`](./addons/adomi_community) auto-installs
  the bundled community dependencies
- **Dynamic configuration**: configuration is generated at runtime via `envsubst`
  using [`config/odoo.conf`](./config/odoo.conf)
- **Setup hook**:
  [`hooks/hook_setup.sh`](hooks/setup/000.setup_adomi_community.sh) can create/init a DB and install
  `adomi_community` once per persisted data directory

## What’s included

This repo currently bakes in (at build time) addons from these OCA repos:

- `OCA/account-reconcile`
  - `account_statement_base`
  - `account_reconcile_oca`
- `OCA/bank-statement-import`
  - `account_statement_import_base`
  - `account_statement_import_online`
  - `account_statement_import_online_plaid`
- `OCA/server-brand`
  - `disable_odoo_online`
  - `mail_debranding`
  - `portal_debranding`
  - `sale_portal_debranding`
  - `website_debranding`
- `OCA/web`
  - `web_responsive`

The module [`adomi_community`](./addons/adomi_community/__manifest__.py) depends on
those addons and is set to `auto_install`.

## Getting started

> [!WARNING]
> This project is designed to run via Docker.
> Install Docker Desktop on Windows/Mac:
> [Download Docker Desktop](https://www.docker.com/products/docker-desktop/)

### Docker Compose (recommended)

This repo includes a ready-to-run compose file:

- [`docker-compose.yml`](./docker-compose.yml)

Start Odoo + Postgres:

```sh
docker compose up --build
```

Then open:

- `http://localhost:8069`

Run in the background:

```sh
docker compose up -d --build
```

### What this compose file does

The `odoo` service in [`docker-compose.yml`](./docker-compose.yml):

- Builds the image from [`Dockerfile`](./Dockerfile)
- Mounts `./config` to `/volumes/config`
  - This lets you edit `config/odoo.conf` locally
  - It also lets you inspect the generated config (`config/_generated.conf`)
- Mounts [`hooks/hook_setup.sh`](hooks/setup/000.setup_adomi_community.sh) to `/hook_setup`
- Persists Odoo data in a named volume (`/volumes/data`)

## Configuration

### Environment variables

Database connection is configured via environment variables (see
[`docker-compose.yml`](./docker-compose.yml)):

- `ODOO_DB_HOST`
- `ODOO_DB_PORT`
- `ODOO_DB_USER`
- `ODOO_DB_PASSWORD`
- `ODOO_DB_NAME` (optional; defaults to `odoo` in the setup hook)

> [!TIP]
> Use a `.env` file next to your `docker-compose.yml` to keep secrets out of your
> command line.

### Dynamic `odoo.conf`

`config/odoo.conf` is treated as a template and values are substituted at runtime.
The resulting file is written to:

- `config/_generated.conf` on the host (because `./config` is mounted)
- `/volumes/config/_generated.conf` inside the container

If you need to hardcode a value, replace the `$ODOO_*` placeholder with a literal.

## Extending this image

### Add or remove OCA/community addons

Edit [`Dockerfile`](./Dockerfile).
Each OCA repo is cloned in its own build stage, and selected addons are copied into
`/volumes/extra_addons`.

To add a new addon:

1. Add a new build stage that clones the OCA repo/branch you want
2. Copy the addon folder(s) into `/tmp/extra_addons/`
3. Add a `COPY --from=...` into the final image stage
4. Add the addon as a dependency in
   [`addons/adomi_community/__manifest__.py`](./addons/adomi_community/__manifest__.py)

### Add your own addons

Place your custom addons under `./addons/`.

## Common commands

Open a shell in the running container:

```sh
docker compose exec app_odoo /bin/bash
```

Run an Odoo command (stop after init):

```sh
docker compose exec -T app_odoo \
  odoo-bin \
  -c /volumes/config/_generated.conf \
  -d odoo \
  --stop-after-init
```

> [!TIP]
> For running Python commands inside the container, use:
>
> - `docker compose exec -T <service> python -m <module>`
> - `docker compose exec -T <service> odoo-bin <args> --stop-after-init`

## License

See [`LICENSE`](https://github.com/adomi-io/odoo/blob/master/LICENSE) in the upstream
repository.
