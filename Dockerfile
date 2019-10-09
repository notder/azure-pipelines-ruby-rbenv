FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update \
    && apt-get install --no-install-recommends \
        gcc \
        g++ \
        make \
        bzip2 \
        ca-certificates \
        curl \
        wget \
        jq \
        git \
        iputils-ping \
        libcurl3 \
        libicu55 \
        libpq-dev \
        libmysqlclient-dev \
        ruby-dev \
        libreadline-dev \
        libssl-dev \
        apt-transport-https \
        gnupg-agent \
        software-properties-common \
        tzdata \
        file \
        libmagickwand-dev \
        imagemagick \
    && curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && curl -sL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && add-apt-repository "deb https://dl.yarnpkg.com/debian/ stable main" \
    && sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-cache policy docker-ce \
    && apt-get install nodejs \
                       yarn \
                       docker-ce \
                       docker-ce-cli \
                       containerd.io \
                       google-chrome-stable \
    && npm install -g bower \
    && npm install -g phantomjs --unsafe-perm

RUN git clone https://github.com/rbenv/rbenv.git /root/.rbenv \
    && cd /root/.rbenv && src/configure && make -C src \
    && git clone https://github.com/sstephenson/ruby-build.git /root/.rbenv/plugins/ruby-build \
    && echo 'export PATH="/root/.rbenv/bin:$PATH"' >> /root/.bashrc \
    && echo 'eval "$(rbenv init -)"' >> /root/.bashrc

WORKDIR /azp
COPY ./start.sh /azp/
RUN chmod +x /azp/start.sh
CMD ["/azp/start.sh"]