FROM registry.fedoraproject.org/fedora:latest

RUN dnf install -y httpd

RUN sed -i "s/Listen 80/Listen 127.0.0.1:8080/g" /etc/httpd/conf/httpd.conf

CMD ["/usr/sbin/httpd", "-DFOREGROUND"]
