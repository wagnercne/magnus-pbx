FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Dependências e correção de tempo
RUN echo "Acquire::Check-Valid-Until \"false\";" > /etc/apt/apt.conf.d/99-ignore-time && \
    apt-get update && apt-get install -y \
    build-essential wget curl uuid-dev libxml2-dev libncurses-dev \
    libsqlite3-dev libssl-dev libjansson-dev libedit-dev libpq-dev \
    python3-dev pkg-config subversion libbcg729-dev libopus-dev \
    autoconf automake libtool recode libasound2-dev libnewt-dev git && \
    apt-get clean

# 2. CRIA��O DO USU�RIO (Resolve o erro da image_9927d0)
RUN groupadd -r asterisk && \
    useradd -r -g asterisk -d /var/lib/asterisk -s /sbin/nologin asterisk

# 3. Asterisk 22 LTS
WORKDIR /usr/src
RUN wget "http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-22-current.tar.gz" && \
    tar -zxf "asterisk-22-current.tar.gz" && \
    cd asterisk-22.* && \
    ./contrib/scripts/get_mp3_source.sh && \    yes | ./contrib/scripts/install_prereq install || true && \    ./configure --with-pjproject-bundled --with-postgres --with-bcg729 --with-opus && \
    make menuselect.makeopts && \
    menuselect/menuselect --enable format_mp3 --enable res_config_pgsql asterisk.makeopts && \
    make -j$(nproc) && \
    make install && \
    make config

# 4. Codec G.729 (Link arkadijs + Fix de headers)
RUN mkdir -p /usr/src/asterisk-g72x && \
    wget https://github.com/arkadijs/asterisk-g72x/archive/refs/heads/master.tar.gz -O /tmp/g729.tar.gz && \
    tar -zxf /tmp/g729.tar.gz -C /usr/src/asterisk-g72x --strip-components=1 && \
    cd /usr/src/asterisk-g72x && \
    ./autogen.sh && \
    CFLAGS="-I/usr/src/asterisk-22.*/include" ./configure --with-bcg729 && \
    make && \
    make install

# 5. Sons PT-BR (GitHub Marcel Savegnago)
RUN mkdir -p /var/lib/asterisk/sounds/pt_BR && \
    wget https://github.com/marcelsavegnago/issabel_sounds_pt_BR/archive/refs/heads/master.tar.gz -O /tmp/sounds.tar.gz && \
    tar -zxf /tmp/sounds.tar.gz -C /var/lib/asterisk/sounds/pt_BR --strip-components=1 && \
    rm -rf /tmp/sounds.tar.gz /tmp/g729.tar.gz

# 6. Permiss�es Finais (Agora com o usu�rio criado)
RUN chown -R asterisk:asterisk /etc/asterisk /var/lib/asterisk /var/log/asterisk /var/spool/asterisk

# 7. Criar diretórios para CDR e logs (Fix para erros de Master.csv)
RUN mkdir -p /var/log/asterisk/cdr-csv && \
    mkdir -p /var/log/asterisk/cdr && \
    mkdir -p /var/spool/asterisk/monitor && \
    mkdir -p /var/spool/asterisk/voicemail && \
    chown -R asterisk:asterisk /var/log/asterisk && \
    chown -R asterisk:asterisk /var/spool/asterisk && \
    chmod -R 755 /var/log/asterisk && \
    chmod -R 755 /var/spool/asterisk

CMD ["asterisk", "-f", "-vvv"]