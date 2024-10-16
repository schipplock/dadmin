# -------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <andreas@schipplock.de> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Andreas Schipplock
# -------------------------------------------------------------------------------

FROM postgres:14.3
COPY sql/*.sql /docker-entrypoint-initdb.d/
COPY conf/db.conf /etc/postgresql/db.conf
ENV LANG=de_DE.utf8
ENV TZ=Europe/Berlin
RUN localedef -i de_DE -c -f UTF-8 -A /usr/share/locale/locale.alias de_DE.UTF-8 \
 && cp -vf /usr/share/zoneinfo/${TZ} /etc/localtime \
 && echo ${TZ} | tee /etc/timezone \
 && dpkg-reconfigure --frontend noninteractive tzdata
CMD [ "postgres", "-c", "config_file=/etc/postgresql/db.conf"]
