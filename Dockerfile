# This is the docker image we want to use as a base image
# If you have your own image, update the package url here
# By default, we will use the Adomi Odoo upstream image
#
# You can find the source code here:
# https://github.com/adomi-io/odoo

ARG ODOO_BASE_IMAGE=ghcr.io/adomi-io/odoo:19.0


FROM alpine:3.20 AS oca_base

RUN apk add --no-cache \
    git

WORKDIR /tmp/oca


FROM oca_base AS oca_server_brand

RUN mkdir -p /tmp/extra_addons

RUN git clone \
        --depth 1 \
        --branch 19.0 \
        https://github.com/OCA/server-brand.git \
        /tmp/oca/server-brand \
    && cp -a \
        /tmp/oca/server-brand/disable_odoo_online \
        /tmp/extra_addons/ \
    && cp -a \
        /tmp/oca/server-brand/mail_debranding \
        /tmp/extra_addons/ \
    && cp -a \
        /tmp/oca/server-brand/portal_debranding \
        /tmp/extra_addons/ \
    && cp -a \
        /tmp/oca/server-brand/remove_odoo_enterprise \
        /tmp/extra_addons/remove_odoo_enterprise \
    && cp -a \
        /tmp/oca/server-brand/sale_portal_debranding \
        /tmp/extra_addons/ \
    && cp -a \
        /tmp/oca/server-brand/website_debranding \
        /tmp/extra_addons/


FROM oca_base AS oca_web

RUN mkdir -p /tmp/extra_addons

RUN git clone \
        --depth 1 \
        --branch 19.0 \
        https://github.com/OCA/web.git \
        /tmp/oca/web \
    && cp -a \
        /tmp/oca/web/web_responsive \
        /tmp/extra_addons/

FROM oca_base AS oca_bank_statement_import

RUN mkdir -p /tmp/extra_addons

RUN git clone \
        --depth 1 \
        --branch 19.0 \
        https://github.com/OCA/bank-statement-import.git \
        /tmp/oca/bank-statement-import \
    && cp -a \
        /tmp/oca/bank-statement-import/account_statement_import_base \
        /tmp/extra_addons/ \
    && cp -a \
        /tmp/oca/bank-statement-import/account_statement_import_online \
        /tmp/extra_addons/


FROM oca_base AS account_reconcile

RUN mkdir -p /tmp/extra_addons

RUN git clone \
        --depth 1 \
        --branch 19.0 \
        https://github.com/OCA/account-reconcile.git \
        /tmp/oca/account-reconcile \
    && cp -a \
        /tmp/oca/account-reconcile/account_statement_base \
        /tmp/extra_addons/


FROM ${ODOO_BASE_IMAGE} AS configuration_layer

# Set user to root so we can install dependencies
USER root

# Here, you can install python dependencies
# For example:
# RUN pip install  \
  #    python-slugify  \
  #    stripe  \
  #    mailerlite  \
  #    mailerlite \
  #    pika \
  #    betterproto \
  #    typeform \
  #    meilisearch

# Extend the layer with our python dependencies installed
FROM configuration_layer

# Odoo will run as a non-root user
# UID 1000 is the default user for Ubuntu
USER 1000

# We will work in the volumes directory, where our addons
# and mounted files are located
WORKDIR /volumes

# OCA: Copy UI related packages
COPY --from=oca_server_brand /tmp/extra_addons/ /volumes/extra_addons/
COPY --from=oca_web /tmp/extra_addons/ /volumes/extra_addons/

# OCA: Accounting related packages
COPY --from=oca_bank_statement_import /tmp/extra_addons/ /volumes/extra_addons/
COPY --from=account_reconcile /tmp/extra_addons /volumes/extra_addons/

# OCA: Pending upstream
#COPY --from=oca_bank_statement_import_plaid /tmp/extra_addons/ /volumes/extra_addons/
COPY hooks /hooks/

# Copy your configuration into the container
COPY config/odoo.conf /volumes/config/odoo.conf

# Copy extra addons for downstream images
COPY extra_addons /volumes/extra_addons

# Copy your custom addons into the container
COPY addons /volumes/addons