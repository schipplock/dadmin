# -------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <andreas@schipplock.de> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Andreas Schipplock
# -------------------------------------------------------------------------------

FROM ubuntu:22.04
SHELL ["/bin/bash", "-c"]

ENV LANG de_DE.utf8
ENV TZ Europe/Berlin
ENV DEBIAN_FRONTEND=noninteractive

COPY entrypoint.sh /entrypoint.sh
COPY ping.pl /var/www/html/ping.pl

RUN apt-get update && apt-get install -y \
  locales \
  tzdata \
  nano \
  apache2 \
  libapache2-mod-perl2 \
  libmoose-perl \
  libjson-perl \
  libdbd-pg-perl \
  libhtml-strip-perl \
  libany-uri-escape-perl \
  libdigest-sha-perl \
  libcgi-session-perl \
  libhtml-template-perl \
  make \
 && locale-gen ${LANG} \
 && update-locale LANG=${LANG} \
 && cp -vf /usr/share/zoneinfo/${TZ} /etc/localtime \
 && echo ${TZ} | tee /etc/timezone \
 && dpkg-reconfigure --frontend noninteractive tzdata \
 && ln -sf /proc/1/fd/2 /var/log/apache2/error.log \
 && ln -sf /proc/1/fd/1 /var/log/apache2/access.log \
 && a2enmod cgid \
 && chmod +x /entrypoint.sh /var/www/html/ping.pl \
 && echo | cpan \
 && cpan CGI::Minimal

ENTRYPOINT ["/entrypoint.sh"]
