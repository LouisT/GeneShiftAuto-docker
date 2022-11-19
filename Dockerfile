FROM ubuntu:latest

STOPSIGNAL SIGTERM

# Add a label pointing to my GitHub repo!?
LABEL maintainer="https://github.com/LouisT/GeneShiftAuto-docker"

# Default args
ARG PORT=11237
ARG USERNAME=docker
ARG SOURCE=https://geneshiftauto.com/downloads/GeneShiftAuto-latest.tar.gz
ARG CONFIG=default-config.ini
ARG WEAPONS=default-weapons.ini
ARG APPLYWEAPONS=false
ARG PUID=1000
ARG PGID=1000

# Install deps
ARG DEPS="wget curl bash tar ca-certificates"

# setup env
ENV PORT="$PORT" \
  USERNAME="$USERNAME" \
  SOURCE="$SOURCE" \
  CONFIG="$CONFIG" \
  WEAPONS="$WEAPONS" \
  APPLYWEAPONS="$APPLYWEAPONS" \
  PUID="$PUID" \
  PGID="$PGID"

# Setup initial GSA user + home dir/bash scripts
RUN mkdir -p /opt/GSA /opt/data
RUN useradd -d /opt/GSA gsa
ADD files/*.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/gsa-*.sh && chown -R gsa /usr/local/bin/gsa-*.sh

# Setup base folders/files + install needed deps
RUN apt-get update ; apt-get install -y --no-install-recommends $DEPS

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

# Fetch and uncompress Gene Shift Auto
RUN curl -fL "$SOURCE" | tar -xz -C /opt/GSA

# Copy configs
COPY configs/${CONFIG} /opt/GSA/GeneShiftAuto/data/config.ini
COPY configs/${WEAPONS} /opt/GSA/weapons.tmp.ini
RUN [ "${APPLYWEAPONS}" = "true" ] && echo "Applying weapons!" && mv /opt/GSA/weapons.tmp.ini /opt/GSA/GeneShiftAuto/data/weapons.ini || echo "Not applying weapons!"

# Start Gene Shift Auto!
ENTRYPOINT ["/bin/bash"]
CMD ["/usr/local/bin/gsa-run.sh"]
