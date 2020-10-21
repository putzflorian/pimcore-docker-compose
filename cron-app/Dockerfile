FROM pimcore/pimcore:PHP7.4-fpm-buster
#FROM ubuntu
MAINTAINER putzflorian@gmail.com

WORKDIR /cron
ADD mycron .
ADD do.sh .
ADD mysql-dump-backup.sh .
 
RUN apt-get update
RUN apt-get -y install cron
RUN apt-get -y install sudo
RUN apt-get -y install mariadb-client
 
RUN touch /cron/cron.log

RUN chmod +x do.sh 
RUN chmod +x mysql-dump-backup.sh
RUN chmod 0600 mycron
 
RUN crontab -u root mycron
 
ENTRYPOINT ["cron", "-f"]
