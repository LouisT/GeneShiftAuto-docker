FROM alpine:latest

LABEL maintainer="https://github.com/LouisT/GeneShiftAuto-docker"

# Default args
ARG PORT=11237
ARG USERNAME=docker
ARG SOURCE=https://geneshiftauto.com/downloads/GeneShiftAuto-latest.tar.gz
ARG CONFIG=default-config.ini
ARG WEAPONS=default-weapons.ini
ARG APPLYWEAPONS="false"
ARG GLIBC_VERSION=2.35-r0

# Install deps
ARG DEPS="wget bash tar ca-certificates gcompat"

# setup env
ENV PORT="$PORT" \
  USERNAME="$USERNAME" \
  SOURCE="$SOURCE" \
  CONFIG="$CONFIG" \
  WEAPONS="$WEAPONS" \
  APPLYWEAPONS="$APPLYWEAPONS" \
  GLIBC_VERSION="${GLIBC_VERSION}"

# Setup initial GSA user + home dir/bash scripts
RUN mkdir -p /opt/GSA /opt/data
RUN apk add doas; \
  adduser gsa; \
  # TODO: Improve password setting!? This is used for `docker exec` for shell access.
  echo 'gsa:gsa-password' | chpasswd; \
  echo 'permit gsa as root' > /etc/doas.d/doas.conf \
  echo 'permit persist :wheel as root' >> /etc/doas.d/doas.conf
ADD files/*.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/gsa-*.sh && chown -R gsa /usr/local/bin/gsa-*.sh

# Setup base folders/files + install needed deps
RUN apk add --update $DEPS

# Download and install glibc
RUN wget -nv -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
  && wget -nv https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk \
  && apk add --force-overwrite glibc-${GLIBC_VERSION}.apk

# Install latest su-exec + cleanup
RUN set -ex; \
  wget -nv -O /usr/local/bin/su-exec.c https://raw.githubusercontent.com/ncopa/su-exec/master/su-exec.c; \
  fetch_deps='gcc libc-dev'; apk add --update $fetch_deps; rm -rf /var/lib/apt/lists/*; \
  gcc -Wall /usr/local/bin/su-exec.c -o/usr/local/bin/su-exec; chown root:root /usr/local/bin/su-exec; \
  chmod 0755 /usr/local/bin/su-exec; rm /usr/local/bin/su-exec.c; apk del $fetch_deps \
  rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# Fetch and uncompress Gene Shift Auto
RUN wget -nv -O- "$SOURCE" | tar -xz -C /opt/GSA

# Copy configs
COPY configs/${CONFIG} /opt/GSA/GeneShiftAuto/data/config.ini
COPY configs/${WEAPONS} /opt/GSA/weapons.tmp.ini
RUN [ "${APPLYWEAPONS}" = "true" ] && echo "Applying weapons!" && mv /opt/GSA/weapons.tmp.ini /opt/GSA/GeneShiftAuto/data/weapons.ini || echo "Not applying weapons!"

# Start Gene Shift Auto!
ENTRYPOINT ["/bin/bash"]
CMD ["/usr/local/bin/gsa-run.sh"]
