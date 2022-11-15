FROM ubuntu:latest

STOPSIGNAL SIGTERM

# Add a label pointing to my GitHub repo!?
LABEL maintainer="https://github.com/LouisT/GeneShiftAuto-docker"

# Default args
ARG PORT=11235
ARG USERNAME=docker
ARG SOURCE=https://geneshiftauto.com/downloads/GeneShiftAuto-latest.tar.gz
ARG CONFIG=default.ini

# setup env
ENV PORT="$PORT" \
  USERNAME="$USERNAME" \
  SOURCE="$SOURCE" \
  CONFIG="$CONFIG" \
  PUID=1000 PGID=1000

# Setup base folders/files + install needed deps
RUN mkdir -m 777 -p /tmp
RUN apt-get update ; apt-get install -y --no-install-recommends wget bash tar ca-certificates

# Install latest su-exec
RUN set -ex; \
  wget -nv -O /usr/local/bin/su-exec.c https://raw.githubusercontent.com/ncopa/su-exec/master/su-exec.c; \
  fetch_deps='gcc libc-dev'; \
  apt-get install -y --no-install-recommends $fetch_deps; \
  rm -rf /var/lib/apt/lists/*; \
  gcc -Wall /usr/local/bin/su-exec.c -o/usr/local/bin/su-exec; \
  chown root:root /usr/local/bin/su-exec; \
  chmod 0755 /usr/local/bin/su-exec; \
  rm /usr/local/bin/su-exec.c; \
  apt-get purge -y --auto-remove $fetch_deps

# Clear unused files
RUN apt-get clean && \
  rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# Create user and fix permissions
RUN useradd -rm -d /home/GSA -s /bin/bash -g root -G sudo -u ${PUID} gsa
WORKDIR /home/GSA
RUN chown -R gsa:root /home/GSA

# Fetch and uncompress latest Gene Shift Auto
RUN wget -nv "$SOURCE" -O "/home/GSA/Source.tar.gz" \
  && tar -xf /home/GSA/Source.tar.gz -C /

# Copy files and fix permissions
COPY files/*.sh /
COPY configs/${CONFIG} /GeneShiftAuto/data/config.ini
RUN chmod +x /gsa-*.sh && chown -R gsa:root /gsa-*.sh

# Cleanup
RUN apt-get purge -y --auto-remove wget ca-certificates

# Start Gene Shift Auto!
ENTRYPOINT ["/gsa-entrypoint.sh"]
