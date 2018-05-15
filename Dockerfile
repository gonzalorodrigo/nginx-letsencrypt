FROM nginx:1.13.12

ADD ./create_cert.sh /create_cert.sh
ADD ./backports.list /etc/apt/sources.list.d/backports.list
ADD ./entry_point.sh /entry_point.sh
ADD ./cli.ini /cli.ini
ADD ./default.conf.tmplt /default.conf.tmplt
RUN mkdir /webroot

RUN apt-get update
RUN apt-get install -y -f python-certbot-nginx -t stretch-backports
RUN apt-get install -y -f sudo
RUN apt-get -y -f install cron
RUN apt-get -y -f install procps
ADD ./crontab.renew /etc/cron.d/renew.certbot

ARG SPIN_UID=60805
ARG SPIN_GID=72483

# Replace with your USER:GROUP
RUN usermod  --non-unique --uid $SPIN_UID nginx 
RUN groupmod --non-unique --gid $SPIN_GID nginx

CMD ["./entry_point.sh"]