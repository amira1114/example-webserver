FROM ubuntu:18.04

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y nginx -qq && \
    apt-get clean && \
    rm -fr /var/lib/apt/lists
ADD nginx.conf /etc/nginx/nginx.conf
ADD custom /etc/nginx/sites-available/custom
ADD index.html /var/www/html-custom/index.html
RUN rm /etc/nginx/sites-enabled/default && \
    ln -sf /etc/nginx/sites-available/custom /etc/nginx/sites-enabled/custom
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log
CMD ["/usr/sbin/nginx"]
