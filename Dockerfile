FROM docker:stable-dind

RUN apk update && apk add bash \
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
    build-base openssl-dev libffi-dev python-dev \
    btrfs-progs \
    e2fsprogs \
    xfsprogs \
	openvswitch \
    xz \
    jq \
    wget \
    vim \
    ssh \
    openssh-server \
    libglib2.0-0 \

RUN ln -f /bin/bash /bin/sh

# We want to run ifconfig from net-tools and ip from iproute2
# Note that you cannot del /sbin/ip.  the installation of 
# apk add iproute2 adds a trigger into busybox for the real "ip".
RUN rm -f /sbin/ifconfig

COPY docker-entrypoint.sh /usr/local/bin/

COPY requirements.txt ~
RUN pip install --upgrade pip && pip install  -r ~/requirements.txt
RUN rm -rf /tmp/pip*

# Install Azure CLI
RUN curl -L https://aka.ms/InstallAzureCli | bash

# Install Dropbox
RUN cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
RUN cd /usr/local/bin && wget -O ./dropbox.py "https://www.dropbox.com/download?dl=packages/dropbox.py"
RUN  chmod +x /usr/local/bin/*

# Set up sshd
RUN mkdir /var/run/sshd
RUN echo 'root:root' |chpasswd
RUN sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-d"]
