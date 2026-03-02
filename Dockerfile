# This is the docker image we want to use as a base image
# If you have your own image, update the package url here
# By default, we will use the Adomi Odoo upstream image
#
# You can find the source code here:
# https://github.com/adomi-io/odoo

ARG ODOO_BASE_IMAGE=ghcr.io/adomi-io/odoo:19.0


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

# Copy your configuration into the container
COPY config/odoo.conf /volumes/config/odoo.conf

# Copy extra addons for downstream images
COPY extra_addons /volumes/extra_addons

# Copy your custom addons into the container
COPY addons /volumes/addons