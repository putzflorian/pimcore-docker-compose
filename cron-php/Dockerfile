#FROM php:7.4-cli
FROM pimcore/pimcore:PHP7.4-cli-buster

RUN apt-get update && apt-get install -y cron

#RUN touch /etc/crontab /etc/cron.*/*
#COPY crontab /etc/crontab
#RUN chmod 644 /etc/crontab
#RUN crontab /etc/crontab
#RUN touch /opt/cron.log
#CMD /usr/sbin/cron -f

#WORKDIR /var/www/html

#COPY cron/ bin/cron/

#RUN chown -R www-data:www-data bin/cron
#RUN chmod -R +x bin/cron

#CMD /var/www/html/bin/cron/entrypoint-cron.sh

#ENTRYPOINT /bin/bash

#ENTRYPOINT /var/www/html/bin/cron/entrypoint-cron.sh



ENV APP_USER www-data

#RUN adduser -g 1000 -D $APP_USER

COPY crontab /var/spool/cron/crontabs/$APP_USER
RUN chmod 0600 /var/spool/cron/crontabs/$APP_USER
RUN touch /opt/cron.log

#ENTRYPOINT "crond"

#CMD ["-f", "-d", "8"]

ENTRYPOINT ["cron", "-f"]
