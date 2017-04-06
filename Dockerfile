FROM alpine
MAINTAINER david.morcillo@codegram.com

# Install git
RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh