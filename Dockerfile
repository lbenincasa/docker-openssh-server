FROM ghcr.io/linuxserver/baseimage-alpine:3.20

# set version label
ARG BUILD_DATE
ARG VERSION
ARG OPENSSH_RELEASE
ARG TARGETPLATFORM

# Kopia
ARG KOPIA_RELEASE=0.12.1
ARG KOPIA_TARGET_OS
ARG KOPIA_TARGET_ARCH

# Rclone
ARG RCLONE_RELEASE=1.61.1
ARG RCLONE_TARGET_OS
ARG RCLONE_TARGET_ARCH


LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="beni"

RUN \
  echo "**** install runtime packages ****" && \
  apk add --no-cache --upgrade \
    logrotate \
    nano \
    mc \
    lsblk \
    rsync \
    restic \
    bridge-utils \
    netcat-openbsd \
    sudo && \
  echo "**** install openssh-server ****" && \
  if [ -z ${OPENSSH_RELEASE+x} ]; then \
    OPENSSH_RELEASE=$(curl -sL "http://dl-cdn.alpinelinux.org/alpine/v3.20/main/x86_64/APKINDEX.tar.gz" | tar -xz -C /tmp && \
    awk '/^P:openssh-server-pam$/,/V:/' /tmp/APKINDEX | sed -n 2p | sed 's/^V://'); \
  fi && \
  apk add --no-cache \
    openssh-client==${OPENSSH_RELEASE} \
    openssh-server-pam==${OPENSSH_RELEASE} \
    openssh-sftp-server==${OPENSSH_RELEASE} && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** setup openssh environment ****" && \
  sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config && \
  sed -i 's/AllowTcpForwarding no/AllowTcpForwarding yes/g' /etc/ssh/sshd_config && \
  usermod --shell /bin/bash abc && \
  rm -rf \
    /tmp/*

# add local files
COPY /root /

# add kopia and rclone
RUN \
  echo "*** install kopia & rclone for ${TARGETPLATFORM} ***" && \
  case ${TARGETPLATFORM} in \
    "linux/amd64") KOPIA_TARGET_OS=linux;KOPIA_TARGET_ARCH=x64; RCLONE_TARGET_OS=linux;RCLONE_TARGET_ARCH=amd64;  ;; \
    "linux/arm64") KOPIA_TARGET_OS=linux;KOPIA_TARGET_ARCH=arm64; RCLONE_TARGET_OS=linux;RCLONE_TARGET_ARCH=arm64;  ;; \
    "linux/arm/v7") KOPIA_TARGET_OS=linux;KOPIA_TARGET_ARCH=arm; RCLONE_TARGET_OS=linux;RCLONE_TARGET_ARCH=arm-v7;  ;; \
                *) echo "target platform not found!!";; \
  esac && \
  curl -sL "https://github.com/kopia/kopia/releases/download/v${KOPIA_RELEASE}/kopia-${KOPIA_RELEASE}-${KOPIA_TARGET_OS}-${KOPIA_TARGET_ARCH}.tar.gz" | tar -xz -C /tmp && \
  curl -sL "https://github.com/rclone/rclone/releases/download/v${RCLONE_RELEASE}/rclone-v${RCLONE_RELEASE}-${RCLONE_TARGET_OS}-${RCLONE_TARGET_ARCH}.zip" -o /tmp/rclone.zip && \
  unzip /tmp/rclone.zip -d /tmp && \
  cp /tmp/kopia-${KOPIA_RELEASE}-${KOPIA_TARGET_OS}-${KOPIA_TARGET_ARCH}/kopia /usr/bin && \
  cp /tmp/rclone-v${RCLONE_RELEASE}-${RCLONE_TARGET_OS}-${RCLONE_TARGET_ARCH}/rclone /usr/bin && \
  rm -rf /tmp/*

#ADD https://github.com/kopia/kopia/releases/download/v${KOPIA_RELEASE}/kopia-${KOPIA_RELEASE}-linux-x64.tar.gz /tmp
#ADD https://github.com/rclone/rclone/releases/download/v${RCLONE_RELEASE}/rclone-v${RCLONE_RELEASE}-linux-amd64.zip /tmp
#RUN \
#  echo "*** install kopia & rclone ***" && \
#  tar xfv /tmp/kopia-${KOPIA_RELEASE}-linux-x64.tar.gz -C /tmp && \
#  unzip   /tmp/rclone-v${RCLONE_RELEASE}-linux-amd64.zip -d /tmp && \
#  cp /tmp/kopia-${KOPIA_RELEASE}-linux-x64/kopia /usr/bin && \
#  cp /tmp/rclone-v${RCLONE_RELEASE}-linux-amd64/rclone /usr/bin && \
#  rm -rf /tmp/*

EXPOSE 2222

VOLUME /config
