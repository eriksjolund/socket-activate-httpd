# socket-activate-httpd

A demo of how to socket activate an [httpd](https://httpd.apache.org) container with Podman.

### Requirements

* __podman__  version 3.4.0 (released September 2021) or newer
* __container-selinux__ version 2.181.0 (released March 2022) or newer

(If you are using an older version of __container-selinux__ and it does not work, add `--security-opt label=disable` to `podman run`)

### Installation

1. Install __socat__
    ```
    sudo dnf -y install curl
    ```

### About the container image

The container image [__ghcr.io/eriksjolund/socket-activate-httpd__](https://github.com/eriksjolund/socket-activate-httpd/pkgs/container/socket-activate-httpd)
is built by the GitHub Actions workflow [.github/workflows/publish_container_image.yml](.github/workflows/publish_container_image.yml)
from the file [./Containerfile](./Containerfile).

### Activate an instance of a templated systemd user service

1. Start the httpd server socket
    ```
    git clone https://github.com/eriksjolund/socket-activate-httpd.git
    mkdir -p ~/.config/systemd/user
    cp -r socket-activate-httpd/systemd/httpd* ~/.config/systemd/user
    systemctl --user daemon-reload
    systemctl --user start httpd.socket
    ```

2. Run curl
    ```
    $ curl -s localhost:8080 | head -6
    <!doctype html>
    <html>
      <head>
	<meta charset='utf-8'>
	<meta name='viewport' content='width=device-width, initial-scale=1'>
	<title>Test Page for the HTTP Server on Fedora</title>
    $
    ```

3. Try establishing an outgoing connection
    ```
    $ podman exec -t httpd curl https://podman.io
    curl: (6) Could not resolve host: podman.io
    $
    ```
    (The command-line option `--network=none` was added to prevent the container from establishing outgoing connections)

### Socket activate httpd with systemd-socket-activate

1. Socket activate the httpd server
    ```
    $ systemd-socket-activate -l 8080 podman run --rm --name httpd2 --network=none ghcr.io/eriksjolund/socket-activate-httpd
    ```

2. In another shell
    ```
    $ curl -s localhost:8080 | head -6
    <!doctype html>
    <html>
      <head>
	<meta charset='utf-8'>
	<meta name='viewport' content='width=device-width, initial-scale=1'>
	<title>Test Page for the HTTP Server on Fedora</title>
    $
    ```

3. Try establishing an outgoing connection
    ```
    $ podman exec -t httpd2 curl https://podman.io
    curl: (6) Could not resolve host: podman.io
    $
    ```

### Limitation of httpd socket activation support

__htttpd__ has a limitation in its socket activation implementation.

The passed in TCP socket's port number needs to match a configured listening port in the __httpd__ configuration.
For example, here the port number 8080 needs to used both in the Containerfile and in __ListenStream__

```
    $ grep 8080 systemd/httpd.socket
    ListenStream=127.0.0.1:8080
    $ grep 8080 Containerfile
    RUN sed -i "s/Listen 80/Listen 127.0.0.1:8080/g" /etc/httpd/conf/httpd.conf
    $
```

Normally socket activation is implemented in such a way that servers do not need to configure the sockets by themselves.

### Troubleshooting

#### The container takes long time to start

Pulling a container image may take long time. This delay can be avoided by pulling the container
image beforehand and adding the command-line option `--pull=never` to `podman run`.

A good way to diagnose problems is to look in the journald log for the service:

```
journalctl -xe --user -u httpd.service
```
