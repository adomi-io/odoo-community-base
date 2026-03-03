
> [!TIP]
> Upstream image source code
> [adomi-io/odoo](https://github.com/adomi-io/odoo)

# adomi-io/odoo-community-base

This extends our upstream [`odoo/odoo`](https://github.com/adomi-io/odoo) image.

This contains a selection of OCA packages we commonly use in our projects.

> [!NOTE]
> Adomi is an Odoo partner and consulting company. This repo is a foundation for
> our open-source Odoo projects and the way we prefer to ship Odoo for modern
> software teams.

> [!WARNING]
> This is not the official Odoo image.
> If you’re looking for the official upstream image, see
> [`odoo/docker`](https://github.com/odoo/docker).

## Highlights
- **OCA Upstream** Grabs up-to-date plugins and bakes them into `/volumes/extra_addons` via a multi-stage
  [`Dockerfile`](./Dockerfile) for ease of use in downstream projects
- **Meta addon**: [`extra_addons/adomi_community`](./extra_addons/adomi_community) auto-installs
  the bundled community dependencies
- **Setup hook**:
  [`hooks/setup/000.setup_adomi_community.sh`](hooks/setup/000.setup_adomi_community.sh) can create/init a DB and install
  `adomi_community` once per persisted data directory

## What’s included

This repo currently bakes in (at build time) addons from these OCA repos:

| Repository | Addon | Description |
|---|---|---|
| [OCA/web](https://github.com/OCA/web) | `web_responsive` | Responsive web interface for Odoo |
| [OCA/server-brand](https://github.com/OCA/server-brand) | `disable_odoo_online` | Disable Odoo Online features |
| | `mail_debranding` | Remove Odoo branding from emails |
| | `portal_debranding` | Remove Odoo branding from portal |
| | `sale_portal_debranding` | Remove Odoo branding from sale portal |
| | `website_debranding` | Remove Odoo branding from website |
| [OCA/bank-statement-import](https://github.com/OCA/bank-statement-import) | `account_statement_import_base` | Base for bank statement import |
| | `account_statement_import_online` | Online bank statement import |
| | `account_statement_import_online_plaid` | (Pending) Online bank statement import via Plaid |

The module [`adomi_community`](./extra_addons/adomi_community/__manifest__.py) depends on
those addons and is set to `auto_install`.

## Getting started

> [!WARNING]
> This project is designed to run via Docker.
> Install Docker Desktop on Windows/Mac:
> [Download Docker Desktop](https://www.docker.com/products/docker-desktop/)

### Docker Compose (recommended)

Copy the environment file, and check the values:
`cp .env.example .env`

Start Odoo + Postgres:
```sh
docker compose up --build
```

Then open:
http://localhost:8069

Run in the background:

```sh
docker compose up -d --build
```

### Add your own addons
Place your custom addons under `./addons/`.

### Add or remove OCA/community addons

Edit [`Dockerfile`](./Dockerfile).
Each OCA repo is cloned in its own build stage, and selected addons are copied into
`/volumes/extra_addons`.

To add a new addon:

- Add a new build stage that clones the OCA repo/branch you want
- Copy the addon folder(s) into `/tmp/extra_addons/`
- Add a `COPY --from=...` into the final image stage
- Add the addon as a dependency in
   [`extra_addons/adomi_community/__manifest__.py`](./extra_addons/adomi_community/__manifest__.py)

## Common commands
Open a shell in the running container:

```sh
docker compose exec app_odoo /bin/bash
```

> [!TIP]
> For running Python commands inside the container, use:
>
> - `docker compose exec -T app_odoo python -m <module>`
> - `docker compose exec -T app_odoo odoo-bin <args> --stop-after-init`