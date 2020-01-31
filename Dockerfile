# https://hub.docker.com/_/php
FROM php:cli

# Debian set Locale
# tzdataのapt-get時にtimezoneの選択で止まってしまう対策でDEBIAN_FRONTENDを定義する
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
  apt -y install task-japanese locales-all locales && \
  locale-gen ja_JP.UTF-8 && \
  rm -rf /var/lib/apt/lists/*
ENV LC_ALL=ja_JP.UTF-8 \
  LC_CTYPE=ja_JP.UTF-8 \
  LANGUAGE=ja_JP:jp
RUN localedef -f UTF-8 -i ja_JP ja_JP.utf8

# Debian set TimeZone
ENV TZ=Asia/Tokyo
RUN echo "${TZ}" > /etc/timezone && \
  rm /etc/localtime && \
  ln -s /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
  dpkg-reconfigure -f noninteractive tzdata

# コンテナのデバッグ等で便利なソフト導入しておく
RUN apt update && \
  apt -y install vim && \
  apt -y install git && \
  apt -y install curl && \
  apt -y install wget && \
  apt -y install zip && \
  apt -y install unzip && \
  apt -y install net-tools && \
  apt -y install iproute2 && \
  apt -y install iputils-ping && \
  rm -rf /var/lib/apt/lists/*

# install GD & exif
RUN apt update && apt -y install zlib1g-dev \
  libfreetype6-dev \
  libjpeg62-turbo-dev \
  libmcrypt-dev \
  libpng-dev \
  && rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j$(nproc) gd exif

# PostgreSQL
RUN apt update && apt -y install libpq-dev && rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-install -j$(nproc) pdo pgsql pdo_pgsql

# maria mysql
RUN docker-php-ext-install -j$(nproc) mysqli pdo_mysql

# other
RUN apt update && apt -y install libzip-dev libicu-dev libonig-dev && rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-install -j$(nproc) bcmath zip json fileinfo sockets iconv intl mbstring opcache

# PECL
RUN apt update && apt -y install autoconf \
  libz-dev \
  && rm -rf /var/lib/apt/lists/*

# xdebug
RUN pecl install xdebug && docker-php-ext-enable xdebug

# mailparse
RUN pecl install mailparse && docker-php-ext-enable mailparse
# grpc
RUN pecl install grpc && docker-php-ext-enable grpc

RUN { \
  echo 'short_open_tag = On'; \
  echo 'fastcgi.logging = 1'; \
  echo 'opcache.enable=1'; \
  echo 'opcache.optimization_level=0x7FFFBBFF' ; \
  echo 'opcache.revalidate_freq=0'; \
  echo 'opcache.validate_timestamps=1'; \
  echo 'opcache.memory_consumption=128'; \
  echo 'opcache.interned_strings_buffer=8'; \
  echo 'opcache.max_accelerated_files=4000'; \
  echo 'opcache.revalidate_freq=60'; \
  echo 'opcache.fast_shutdown=1'; \
  echo 'xdebug.remote_enable=1'; \
  echo 'extension=grpc.so'; \
  } > /usr/local/etc/php/conf.d/overrides.ini

# Composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
