FROM debian:stretch

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get upgrade && \
    apt-get install git

RUN git clone https://github.com/SomethingWithHorizons/mailserver.wiki.git /tmp/wiki

RUN sed -n '/```shell/,/```/p; 1d' /tmp/wiki/Mail-server_Package-installation.md | sed '$d; 1d' | bash

