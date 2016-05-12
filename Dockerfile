FROM    ubuntu:14.04
RUN     apt-get update && \
        apt-get -y --no-install-recommends install software-properties-common && \
        add-apt-repository ppa:serge-hallyn/virt && \
        apt-get update &&\
        DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \
            xserver-xspice \
            libpam-ldapd \
            x11-xserver-utils \
            ratpoison \
            gnome-themes-standard \
            xserver-xorg-video-qxl \
            spice-vdagent \
            nodejs \
            npm \
            nodejs-legacy \
            git \
            && \
        apt-get clean

# Removed breeze and frameworksintegration

RUN     mv /usr/sbin/spice-vdagentd /usr/sbin/spice-vdagentd.old && \
        /usr/sbin/locale-gen es_ES.UTF-8 en_US.UTF-8

ENV     BROWSER eyeos-open
COPY    spice-vdagentd /usr/sbin/
COPY    .gtkrc-2.0 /root/
COPY    spiceqxl.xorg.conf /etc/X11/
COPY    resolution.desktop /etc/xdg/autostart/
COPY    keyboard.desktop /etc/xdg/autostart/
COPY    setcustomresolution /usr/bin/setcustomresolution
COPY    ratpoisonrc /etc/skel/.config/
COPY    eyeos-open/eyeos-open.sh /usr/bin/eyeos-open
COPY    eyeos-open/mimeapps.list /etc/xdg/
COPY    eyeos-open/eyeos-open.desktop /usr/share/applications/eyeos-open.desktop

## Install open365-services
COPY    npmrc /root/.npmrc
COPY    package.json /root/
COPY    netrc /root/.netrc
RUN     apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            cups \
            cups-pdf \
            davfs2 \
            vim \
            build-essential \
            wget \
            sudo \
            pyqt5-dev-tools && \
        mkdir -p /code && cd /code && \
        git clone https://bitbucket.org/eyeos/open365-services.git && \
        cd /code/open365-services && npm install && \
        cd /root && npm install && \
        npm install -g json && \
        /code/open365-services/install.sh && \
        ln -s /usr/bin/env /bin/env && \
        rm /root/.netrc && \
        rm /root/.npmrc && \
        apt-get purge -y build-essential

# General stuff
COPY    cups /etc/cups
COPY    system_clipboard.py /usr/bin/system_clipboard.py
COPY    office_clipboard.py /usr/bin/office_clipboard.py
COPY    davfs2.conf /etc/davfs2/davfs2.conf

VOLUME  ["/home"]
EXPOSE  5900
CMD     ["node", "/root/start.js"]

# Kmail
RUN     apt-get update && apt-get install -y wget
RUN     echo 'deb http://obs.kolabsys.com/repositories/Kontact:/4.13/Ubuntu_14.04/ /' >> /etc/apt/sources.list.d/kolab.list && \
        wget http://obs.kolabsys.com/repositories/Kontact:/4.13/Ubuntu_14.04/Release.key && \
        apt-key add Release.key && \
        rm Release.key && \
        apt-get update && \
        apt-get install -y kolab-desktop-client && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*

RUN     chmod +s /usr/bin/Xorg
RUN     apt-get update && apt-get install -y libboost-all-dev libqt4-xml libqt4-sql qdbus akonadi-backend-mysql vim

# We seem to get a lot of Xorg erros without this
ENV     QT_X11_NO_MITSHM 1

# Install Breeze
COPY    breeze-kde4-5.6.2-1-x86_64.pkg.tar.xz /tmp/
RUN     cd /tmp/ && tar -xf breeze* && cp -rf usr /

ENV     KDE_FULL_SESSION true
ENV     KDE_SESSION_VERSION 4

RUN     mkdir /tmp/breeze-icons
COPY    breeze-icons-5.21.0-1-any.pkg.tar.xz /tmp/breeze-icons/
RUN     cd /tmp/breeze-icons && tar -xf breeze* && cp -rf usr /

# vdagent
COPY    vdagent /tmp/vdagent
RUN     cd /tmp/vdagent && \
        dpkg -i libgpg-error0_1.17-3ubuntu1_amd64.deb && \
        dpkg -i --ignore-depends=libsystemd0 libgcrypt20_1.6.2-4ubuntu2_amd64.deb && \
        dpkg -i libsystemd0_219-7ubuntu3_amd64.deb && \
        dpkg -i spice-vdagent_0.15.0-1.2_amd64.deb && \
        rm -rf /tmp/vdagent

# Without this version of xspice the vdagent doesn't get the correct permissions for /tmp/xspice-uinput
RUN     DEBIAN_FRONTEND=noninteractive apt-get install -y xserver-xspice-lts-utopic

COPY    config/ /etc/skel/.config/
COPY    kwallet /etc/skel/.local/share/kwallet

COPY    ak_debs /ak_debs
RUN     dpkg -i /ak_debs/libakonadiprotocolinternals1_1.12.42.5-0~kolab1_amd64.deb
RUN     dpkg -i /ak_debs/akonadi-backend-mysql_1.12.42.5-0~kolab1_all.deb
RUN     dpkg -i /ak_debs/akonadi-server_1.12.42.5-0~kolab1_amd64.deb
RUN     DEBIAN_FRONTEND=noninteractive apt-get -y autoremove \
            curl \
            g++ \
            gcc \
            netcat \
            netcat-openbsd \
            netcat-traditional \
            ngrep \
            strace \
            wget \
            && \
            apt-get clean && \
            rm -rf /var/lib/apt/lists/*

COPY    [ \
            "exec.sh", \
            "mail", \
            "configureKontact.sh", \
            "updateKontactPassword.sh", \
            "/usr/bin/" \
        ]
COPY    [ \
            "bind-mount-libraries", \
            "start.js", \
            "run.sh", \
            "/root/" \
        ]
