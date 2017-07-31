# Official Docker-In-Docker based on Alpine
FROM docker:stable-dind

MAINTAINER Maxim Pak

RUN apk update && apk add --no-cache \
    bash \
    bash-doc \
    bash-completion \
    coreutils \
    findutils \
    net-tools \
    curl \
    openssl \
    openssl-dev \
    py-pip \ 
    jq \
    wget \
    openssh \
    man \
    man-pages \
    grep \
    screen \
    less \
    build-base \
    ctags \
    git \
    libx11-dev \
    libxpm-dev \
    libxt-dev \
    make \
    ncurses-dev \
    python \
    python-dev \
    libice \
    libsm \
    libx11 \
    libxt \
    ncurses \
    cmake \
    cmake-doc \
    rsync \
    rsync-doc \
    ack \
    ack-doc \
    diffutils \
    git-doc

RUN ln -f /bin/bash /bin/sh

# Build Vim
RUN cd /tmp \
    && git clone https://github.com/vim/vim \
    && cd /tmp/vim \
    && ./configure \
    --disable-gui \
    --disable-netbeans \
    --enable-multibyte \
    --enable-pythoninterp \
    --prefix /usr \
    --with-features=big \
    --with-python-config-dir=/usr/lib/python2.7/config \
    && make install

COPY requirements.txt /root
RUN pip install --upgrade pip && pip install  -r ~/requirements.txt
RUN rm -rf /tmp/pip* && rm -f /root/requirements.txt
 
# Install ultimate VIM config
RUN git clone https://github.com/zucler/vimrc.git ~/.vim_runtime
RUN sh ~/.vim_runtime/install_awesome_vimrc.sh
RUN python ~/.vim_runtime/update_plugins.py

# We want to run ifconfig from net-tools and ip from iproute2
# Note that you cannot del /sbin/ip.  the installation of 
# apk add iproute2 adds a trigger into busybox for the real "ip".
RUN rm -f /sbin/ifconfig

   
# Set up sshd
RUN /usr/bin/ssh-keygen -A
RUN mkdir /var/run/sshd
RUN mkdir /root/.ssh/ && touch /root/.ssh/authorized_keys
RUN touch /var/log/btmp && chmod 660 /var/log/btmp 
RUN echo 'root:root' |chpasswd
RUN sed -ri 's/^#PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/\/bin\/ash/\/bin\/bash/g' /etc/passwd

# Installing git-lfs
RUN cd /tmp && curl -sLO https://github.com/github/git-lfs/releases/download/v2.0.1/git-lfs-linux-amd64-2.0.1.tar.gz \
    && tar zxvf git-lfs-linux-amd64-2.0.1.tar.gz \
    && mv git-lfs-2.0.1/git-lfs /usr/bin/ \
    && rm -rf git-lfs-2.0.1 \
    && rm -rf git-lfs-linux-amd64-2.0.1.tar.gz

# docker-entrypoint would start sshd
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
COPY bash_profile /root/.bash_profile
COPY bashrc /root/.bashrc

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bash"]
