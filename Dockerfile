FROM        debian
MAINTAINER  Love Nyberg "love.nyberg@lovemusic.se"

# Update the package repository
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \ 
	DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y wget curl locales

# Configure timezone and locale
RUN echo "Europe/Stockholm" > /etc/timezone && \
	dpkg-reconfigure -f noninteractive tzdata
RUN export LANGUAGE=en_US.UTF-8 && \
	export LANG=en_US.UTF-8 && \
	export LC_ALL=en_US.UTF-8 && \
	locale-gen en_US.UTF-8 && \
	DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales

# Added dotdeb to apt
RUN echo "deb http://packages.dotdeb.org wheezy-php55 all" >> /etc/apt/sources.list.d/dotdeb.org.list && \
	echo "deb-src http://packages.dotdeb.org wheezy-php55 all" >> /etc/apt/sources.list.d/dotdeb.org.list && \
	wget -O- http://www.dotdeb.org/dotdeb.gpg | apt-key add -

# Install PHP 5.5
RUN apt-get update; apt-get install -y vim php5-cli php5 php5-mcrypt php5-curl php5-pgsql php5-mysql
 
# Let's set the default timezone in both cli and apache configs
RUN sed -i 's/\;date\.timezone\ \=/date\.timezone\ \=\ Europe\/Stockholm/g' /etc/php5/cli/php.ini
RUN sed -i 's/\;date\.timezone\ \=/date\.timezone\ \=\ Europe\/Stockholm/g' /etc/php5/apache2/php.ini

# Setup Composer
RUN curl -sS https://getcomposer.org/installer | php && \
	mv composer.phar /usr/local/bin/composer

# Setup conf for Zend Framework
RUN sed -i 's/;include_path = ".:\/usr\/share\/php"/include_path = ".:\/var\/www\/library"/g' /etc/php5/cli/php.ini
RUN sed -i 's/\;include_path = ".:\/usr\/share\/php"/include_path = ".:\/var\/www\/library"/g' /etc/php5/apache2/php.ini
# Activate a2enmod
RUN a2enmod rewrite
RUN a2enmod ssl 

#deactivate default host
RUN a2dissite 000-default

ADD ./apache/ /etc/apache2/sites-available/
RUN a2ensite ssl-host
RUN a2ensite ssl-host-444 
RUN a2ensite ssl-host-445
RUN a2ensite ssl-host-443
RUN echo "Listen 444" >> /etc/apache2/ports.conf
RUN echo "Listen 445" >> /etc/apache2/ports.conf
# Set Apache environment variables (can be changed on docker run with -e)
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_SERVERADMIN admin@localhost
ENV APACHE_SERVERNAME localhost
ENV APACHE_SERVERALIAS docker.localhost
ENV APACHE_DOCUMENTROOT /var/www

EXPOSE 80 443 444 445
ADD start.sh /start.sh
RUN chmod 0755 /start.sh
COPY www-data /var/www
COPY ./ssl/ /etc/ssl/certs/
COPY ./ca-ssl/ /etc/ssl/auth/
RUN chown www-data:www-data /var/log/apache2 
CMD ["bash", "start.sh"]
