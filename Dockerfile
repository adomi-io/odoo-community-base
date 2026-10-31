# This is the docker image we want to use as a base image
# If you have your own image, update the package url here
# By default, we will use the Adomi Odoo upstream image
#
# You can find the source code here:
# https://github.com/adomi-io/odoo

ARG ODOO_BASE_IMAGE=ghcr.io/adomi-io/odoo:19.0


# OCA addons are checked out as git submodules under oca/
# Copy the ones we ship into /tmp/extra_addons
FROM alpine:3.20 AS oca_addons

WORKDIR /tmp/extra_addons

# OCA/server-brand
COPY oca/server-brand/disable_odoo_online ./disable_odoo_online
COPY oca/server-brand/mail_debranding ./mail_debranding
COPY oca/server-brand/portal_debranding ./portal_debranding
COPY oca/server-brand/remove_odoo_enterprise ./remove_odoo_enterprise
COPY oca/server-brand/sale_portal_debranding ./sale_portal_debranding
COPY oca/server-brand/website_debranding ./website_debranding

# OCA/web
COPY oca/web/web_responsive ./web_responsive

# OCA/bank-statement-import
COPY oca/bank-statement-import/account_statement_import_base ./account_statement_import_base
COPY oca/bank-statement-import/account_statement_import_online ./account_statement_import_online

# OCA/account-reconcile
COPY oca/account-reconcile/account_statement_base ./account_statement_base
COPY oca/account-reconcile/account_reconcile_oca ./account_reconcile_oca

# OCA/account-financial-tools
COPY oca/account-financial-tools/account_usability ./account_usability

# OCA/account-analytic
COPY oca/account-analytic/account_analytic_tag ./account_analytic_tag

# OCA/server-env
COPY oca/server-env/server_environment ./server_environment

# OCA/storage
COPY oca/storage/fs_storage ./fs_storage
COPY oca/storage/fs_attachment ./fs_attachment
COPY oca/storage/fs_attachment_s3 ./fs_attachment_s3

# OCA/server-auth
COPY oca/server-auth/auth_oidc ./auth_oidc


# Addons can also be cloned straight from a repository instead of a submodule
# For example:
#
# FROM alpine:3.20 AS oca_bank_statement_import_plaid
#
# RUN apk add --no-cache \
#     git
#
# RUN mkdir -p /tmp/extra_addons
#
# RUN git clone \
#         --depth 1 \
#         --branch 19.0 \
#         https://github.com/OCA/bank-statement-import.git \
#         /tmp/oca/bank-statement-import \
#     && cp -a \
#         /tmp/oca/bank-statement-import/account_statement_import_online_plaid \
#         /tmp/extra_addons/


FROM ${ODOO_BASE_IMAGE} AS configuration_layer

# Set user to root so we can install dependencies
USER root

# Here, you can install python dependencies
# For example:
RUN pip install  \
      requests \
      packaging \
      "fsspec[s3]" \
      python-slugify \
      python-jose \
      inotify \
      openupgradelib

# Extend the layer with our python dependencies installed
FROM configuration_layer

# Odoo will run as a non-root user
# UID 1000 is the default user for Ubuntu
USER 1000

# We will work in the volumes directory, where our addons
# and mounted files are located
WORKDIR /volumes

# Copy the OCA addons
COPY --from=oca_addons /tmp/extra_addons/ /volumes/extra_addons/
# COPY --from=oca_bank_statement_import_plaid /tmp/extra_addons/ /volumes/extra_addons/

# Copy the startup hooks
COPY hooks /hooks/

# Copy your configuration into the container
COPY config/odoo.conf /volumes/config/odoo.conf

# Copy extra addons for downstream images
COPY extra_addons /volumes/extra_addons

# Copy your custom addons into the container
COPY addons /volumes/addons

# Fail the build if an addon needs a python package that is not installed
RUN --mount=type=bind,source=scripts/check_addon_deps.py,target=/tmp/check_addon_deps.py \
    python3 /tmp/check_addon_deps.py /volumes/extra_addons /volumes/addons
