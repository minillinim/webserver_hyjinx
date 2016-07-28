FROM debian:stretch

MAINTAINER Dr. Mike "michael.imelfort@gmail.com"

RUN apt-get update \
	&& apt-get install -y \
		nginx \
		gettext-base \
		rsyslog \
		rsyslog-elasticsearch \
		liblognorm2 \
	&& rm -rf /var/lib/apt/lists/*

# copy necessary config
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./nginx.rb /opt/rsyslog/nginx.rb
COPY ./nginx-rsyslog.conf /etc/rsyslog.d/nginx-rsyslog.conf
COPY ./kibana.htpasswd /etc/nginx/kibana.htpasswd

EXPOSE 80 8080

# add a start-up script
COPY start-server /usr/bin/start-server
RUN chmod +x /usr/bin/start-server
CMD ["/usr/bin/start-server"]
