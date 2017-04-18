FROM ruby:2.4.1
MAINTAINER david.morcillo@codegram.com

# Environment
ENV WORKDIR=/code
ENV LANG=C.UTF-8
ENV GITHUB_ORGANIZATION=
ENV GITHUB_REPO=
ENV GITHUB_USER=
ENV GITHUB_PASSWORD=
ENV DATABASE_HOST=db
ENV DATABASE_USERNAME=postgres
ENV DATABASE_PASSWORD=
ENV DATABASE_NAME=
ENV DECIDIM_GITHUB_ORGANIZATION=
ENV DECIDIM_GITHUB_REPO=
ENV DECIDIM_VERSION=
ENV GIT_USERNAME=decidim-updater-bot
ENV GIT_EMAIL=decidim-updater-bot@foo.bar

# Volumes
VOLUME /usr/local/bundle

# Install system dependencies
RUN apt-get update && apt-get install -y \
  git \
  build-essential \
  libxml2-dev \
  libxslt-dev \
  nodejs \
  && rm -rf /var/cache/apt/*

# Install hub
RUN wget https://github.com/github/hub/releases/download/v2.3.0-pre9/hub-linux-amd64-2.3.0-pre9.tgz && \
    tar -xvzf hub-linux-amd64-2.3.0-pre9.tgz && \
    ln -s /hub-linux-amd64-2.3.0-pre9/bin/hub /bin/hub

# Create working directory
RUN mkdir -p $WORKDIR
WORKDIR $WORKDIR

# Run docker-entrypoint.sh by default
ADD docker-entrypoint.sh .
ENTRYPOINT sh docker-entrypoint.sh
