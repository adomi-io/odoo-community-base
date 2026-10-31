# Adomi - Odoo Community Base

This extends our upstream [`adomi-io/odoo`](https://github.com/adomi-io/odoo) image and contains a selection of OCA
packages we commonly use in our projects.


> [!TIP]
> **Looking for Enterprise?**
>
> See our [adomi-io/boilerplate-odoo-enterprise](https://github.com/adomi-io/boilerplate-odoo-enterprise) repository.
> It will build your team a custom image with Enterprise.
>

> [!NOTE]
> Upstream image source code
>
> - [adomi-io/odoo](https://github.com/adomi-io/odoo)
> - [adomi-io/boilerplate-odoo](https://github.com/adomi-io/boilerplate-odoo)

## Highlights

* 🚀 **OCA packages included**: a selection of community addons baked into `/volumes/extra_addons` by the
  [`Dockerfile`](./Dockerfile) from pinned OCA checkouts (git submodules under [`oca/`](./oca)), kept current by
  Dependabot and merged automatically once the image builds and boots (see *How updates flow*).
* 🧩 **Community bundle addon**: [`extra_addons/adomi_community`](./extra_addons/adomi_community) acts as a meta addon
  that auto-installs the bundled community dependencies.
* 🪝 **Automated install via setup hook**: [
  `hooks/setup/000.setup_adomi_community.sh`](hooks/setup/000.setup_adomi_community.sh) can create/init a DB and install
  `adomi_community` once per persisted data directory.

## Getting started

> [!WARNING]
> This project is designed to run via Docker.
> Install Docker Desktop on Windows/Mac:
> [Download Docker Desktop](https://www.docker.com/products/docker-desktop/)

### Quickstart

- Create a repo using the [Odoo boilerplate](https://github.com/adomi-io/boilerplate-odoo)
- Change the [ODOO_BASE_IMAGE in the Dockerfile](https://github.com/adomi-io/boilerplate-odoo#changing-the-base-image)
  to

```dockerfile
ARG ODOO_BASE_IMAGE=ghcr.io/adomi-io/odoo-community-base:latest
```

- Copy the `.env.example` file to `.env`
- Run `docker compose up --build`

When this image starts, it
will [automatically install the community addons](https://github.com/adomi-io/odoo-community-base/blob/master/hooks/setup/000.setup_adomi_community.sh),
and setup a database.

The default credentials are:

- Username: `admin`
- Password: `admin`

### Docker Compose

Clone this repository

Copy the environment file, and check the values:

`cp .env.example .env`

Start Odoo + Postgres:

```sh
docker compose up --build
```

Then open:
http://localhost:8069

### Add your own addons

Place your custom addons under `./addons/`.

## What’s included

This repo currently bakes in (at build time) addons from these OCA repos:

| Repository                                                                    | Addon                                   | Description                                      |
|-------------------------------------------------------------------------------|-----------------------------------------|--------------------------------------------------|
| [OCA/web](https://github.com/OCA/web)                                         | `web_responsive`                        | Responsive web interface for Odoo                |
| [OCA/server-auth](https://github.com/OCA/server-auth)                         | `auth_oidc`                             | Log in via OpenID Connect (e.g. Authentik SSO)   |
| [OCA/server-brand](https://github.com/OCA/server-brand)                       | `disable_odoo_online`                   | Disable Odoo Online features                     |
|                                                                               | `mail_debranding`                       | Remove Odoo branding from emails                 |
|                                                                               | `portal_debranding`                     | Remove Odoo branding from portal                 |
|                                                                               | `remove_odoo_enterprise`                | Remove Odoo Enterprise features                  |
|                                                                               | `sale_portal_debranding`                | Remove Odoo branding from sale portal            |
|                                                                               | `website_debranding`                    | Remove Odoo branding from website                |
| [OCA/bank-statement-import](https://github.com/OCA/bank-statement-import)     | `account_statement_import_base`         | Base for bank statement import                   |
|                                                                               | `account_statement_import_online`       | Online bank statement import                     |
|                                                                               | `account_statement_import_online_plaid` | (Pending) Online bank statement import via Plaid |
| [OCA/account-reconcile](https://github.com/OCA/account-reconcile)             | `account_statement_base`                | Base for account bank statements                 |
|                                                                               | `account_reconcile_oca`                 | OCA account reconciliation                       |
| [OCA/account-financial-tools](https://github.com/OCA/account-financial-tools) | `account_usability`                     | Account usability improvements                   |
| [OCA/account-analytic](https://github.com/OCA/account-analytic)               | `account_analytic_tag`                  | Adds tags to analytic accounts                   |
| [OCA/server-env](https://github.com/OCA/server-env)                           | `server_environment`                    | Server environment configuration                 |
| [OCA/storage](https://github.com/OCA/storage)                                 | `fs_storage`                            | Filesystem storage backend                       |
|                                                                               | `fs_attachment`                         | Store attachments on filesystem storage          |
|                                                                               | `fs_attachment_s3`                      | Store attachments on S3-compatible storage       |

The module [`adomi_community`](./extra_addons/adomi_community/__manifest__.py) depends on
those addons and is set to `auto_install`.

### Add or remove OCA/community addons

The OCA repositories are git submodules under [`oca/`](./oca), each pinned to a commit on its `19.0`
branch (`.gitmodules`). Clone with `git clone --recurse-submodules` (or run `git submodule update --init`
in an existing checkout). The `oca_addons` stage of the [`Dockerfile`](./Dockerfile) copies the addons we
ship out of those checkouts into `/volumes/extra_addons`.

To add an addon from a repository that is already a submodule: add a `COPY oca/<repo>/<addon> ./<addon>`
line to the `oca_addons` stage and the addon to `depends` in
[`extra_addons/adomi_community/__manifest__.py`](./extra_addons/adomi_community/__manifest__.py).

To add a repository: `git submodule add --depth 1 -b 19.0 https://github.com/OCA/<repo>.git oca/<repo>`,
then the two steps above. If the addon needs a Python package, add it to the `pip install` step: the build
fails otherwise (below).

### How updates flow

1. Dependabot ([`.github/dependabot.yml`](./.github/dependabot.yml)) opens one grouped pull request a day when any
   OCA submodule is behind its `19.0` branch, and a weekly one for the GitHub Actions versions.
2. The build workflow ([`docker-publish.yml`](./.github/workflows/docker-publish.yml)) builds the image on the pull
   request. The build fails if an addon needs a python package the image does not have
   ([`scripts/check_addon_deps.py`](./scripts/check_addon_deps.py)), then the image is started against a fresh
   database until `/web/health` answers ([`tests/smoke-test.sh`](./tests/smoke-test.sh)).
3. [`automerge.yml`](./.github/workflows/automerge.yml) merges the pull request once the build passed. A failed
   build leaves it open.
4. Every merge or push to `master` publishes `latest`, `master` and `sha-<short>`.
5. [`upstream-image.yml`](./.github/workflows/upstream-image.yml) checks the digest of `ghcr.io/adomi-io/odoo:19.0`
   every two hours (stored in the repository variable `UPSTREAM_ODOO_DIGEST`) and starts a build when it changed.

Deployments run dated tags (`master-YYYY-MM-DD`) and move to a new build by hand.

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