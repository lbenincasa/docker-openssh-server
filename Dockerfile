FROM ghcr.io/linuxserver/baseimage-alpine:3.16

# set version label
ARG BUILD_DATE
ARG VERSION
ARG OPENSSH_RELEASE
ARG KOPIA_RELEASE=0.12.1
ARG RCLONE_RELEASE=1.61.1
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

RUN \
  echo "**** install runtime packages ****" && \
  apk add --no-cache --upgrade \
    logrotate \
    nano \
    mc \
    netcat-openbsd \
    sudo && \
  echo "**** install openssh-server ****" && \
  if [ -z ${OPENSSH_RELEASE+x} ]; then \
    OPENSSH_RELEASE=$(curl -sL "http://dl-cdn.alpinelinux.org/alpine/v3.16/main/x86_64/APKINDEX.tar.gz" | tar -xz -C /tmp && \
    awk '/^P:openssh-server-pam$/,/V:/' /tmp/APKINDEX | sed -n 2p | sed 's/^V://'); \
  fi && \
  apk add --no-cache \
    openssh-client==${OPENSSH_RELEASE} \
    openssh-server-pam==${OPENSSH_RELEASE} \
    openssh-sftp-server==${OPENSSH_RELEASE} && \
  echo "**** setup openssh environment ****" && \
  sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config && \
  usermod --shell /bin/bash abc && \
  rm -rf \
    /tmp/*

# add local files
COPY /root /

# add kopia and rclone
ADD https://github.com/kopia/kopia/releases/download/v${KOPIA_RELEASE}/kopia-${KOPIA_RELEASE}-linux-arm64.tar.gz /tmp
ADD https://github.com/rclone/rclone/releases/download/v${RCLONE_RELEASE}/rclone-v${RCLONE_RELEASE}-linux-arm64.zip /tmp
RUN \
  echo "*** install kopia & rclone ***" && \
  tar xfv /tmp/kopia-${KOPIA_RELEASE}-linux-x64.tar.gz -C /tmp && \
  unzip   /tmp/rclone-v${RCLONE_RELEASE}-linux-amd64.zip -d /tmp && \
  cp /tmp/kopia-${KOPIA_RELEASE}-linux-x64/kopia /usr/bin && \
  cp /tmp/rclone-v${RCLONE_RELEASE}-linux-amd64/rclone /usr/bin && \
  rm -rf /tmp/*

EXPOSE 2222

VOLUME /config
