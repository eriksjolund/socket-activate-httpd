FROM docker.io/library/fedora:latest

RUN dnf install -y httpd

# The package iproute is just installed to provide
# easy access to the command /usr/sbin/ip
# for demonstration purposes of the "podman run" option
# "--network=none".
# The iproute package is not required by httpd.

RUN sed -i "s/Listen 80/Listen 127.0.0.1:8080/g" /etc/httpd/conf/httpd.conf

CMD ["/usr/sbin/httpd", "-DFOREGROUND"]
