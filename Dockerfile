FROM docker:stable-dind

RUN apk update && apk add --no-cache bash \
    util-linux \
    pciutils \
    usbutils \
    coreutils \
    binutils \
    findutils \
    procps \
    grep \
    net-tools \
    iproute2 \
    bridge-utils \
    curl \
    iptables \
    openssl \
    git \
    py-pip \ 
    jq \
    build-base openssl-dev \
    libffi-dev \
    python-dev \
    btrfs-progs \
    e2fsprogs \
    xfsprogs \
    openvswitch \
    xz \
    wget \
    vim \
    openssh \
    man \
    ca-certificates \
    gnupg \
    screen

RUN ln -f /bin/bash /bin/sh

# We want to run ifconfig from net-tools and ip from iproute2
# Note that you cannot del /sbin/ip.  the installation of 
# apk add iproute2 adds a trigger into busybox for the real "ip".
#RUN rm -f /sbin/ifconfig

COPY requirements.txt /root
RUN pip install --upgrade pip && pip install  -r ~/requirements.txt

# Install Azure CLI
RUN pip install azure-batch azure.mgmt azure.mgmt.network

RUN rm -rf /tmp/pip* && rm -f /root/requirements.txt

# Install Dropbox
RUN cd /root && wget https://www.dropbox.com/download?dl=packages/dropbox.py -O /usr/local/bin/dropbox-cli \
    && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf - \
    && chmod +x /usr/local/bin/dropbox-cli \
    && chown root:root /usr/local/bin/dropbox-cli
    
# Set up sshd
RUN /usr/bin/ssh-keygen -A
RUN mkdir /var/run/sshd
RUN mkdir /root/.ssh/ && touch /root/.ssh/authorized_keys
RUN touch /var/log/btmp && chmod 660 /var/log/btmp 
RUN echo 'root:root' |chpasswd
RUN sed -ri 's/^#PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# Here we install GNU libc (aka glibc) and set C.UTF-8 locale as default. This is required to run Dropbox
RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.25-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    wget \
        "https://raw.githubusercontent.com/andyshinn/alpine-pkg-glibc/master/sgerrand.rsa.pub" \
        -O "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

ENV LANG=C.UTF-8

RUN apk add glib

# Installing git-lfs
RUN cd /tmp && curl -sLO https://github.com/github/git-lfs/releases/download/v2.0.1/git-lfs-linux-amd64-2.0.1.tar.gz \
    && tar zxvf git-lfs-linux-amd64-2.0.1.tar.gz \
    && mv git-lfs-2.0.1/git-lfs /usr/bin/ \
    && rm -rf git-lfs-2.0.1 \
    && rm -rf git-lfs-linux-amd64-2.0.1.tar.gz

# docker-entrypoint would start sshd
COPY docker-entrypoint.sh /usr/local/bin/
COPY bash_profile /root/.profile
COPY bashrc /root/.bashrc

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bash"]
