# socket-activate-httpd

A demo of how to socket activate an [httpd](https://httpd.apache.org) container with Podman.

When using socket activation, there are some changes to how to run `podman run`:

* [`--publish`](https://docs.podman.io/en/latest/markdown/podman-run.1.html#publish-p-ip-hostport-containerport-ip-containerport-hostport-containerport-containerport) is not used
* [`--network=none`](https://docs.podman.io/en/latest/markdown/podman-run.1.html#network-mode-net) can be used to prevent outgoing connections

### Requirements

* __curl__
* __podman__  version 3.4.0 (released September 2021) or newer
* __container-selinux__ version 2.181.0 (released March 2022) or newer

(If you are using an older version of __container-selinux__ and it does not work, add `--security-opt label=disable` to `podman run`)

### About the container image

The container image [__ghcr.io/eriksjolund/socket-activate-httpd__](https://github.com/eriksjolund/socket-activate-httpd/pkgs/container/socket-activate-httpd)
is built by the GitHub Actions workflow [.github/workflows/publish_container_image.yml](.github/workflows/publish_container_image.yml)
from the file [./Containerfile](./Containerfile).

### Socket activate an httpd systemd user service

1. Start the httpd socket unit
    ```
    git clone https://github.com/eriksjolund/socket-activate-httpd.git
    mkdir -p ~/.config/systemd/user
    cp -r socket-activate-httpd/systemd/httpd* ~/.config/systemd/user
    systemctl --user daemon-reload
    systemctl --user start httpd.socket
    ```
    The user service _httpd.service_ will be started as soon as a client connects to the listening socket.

2. Run curl on the host to download a webpage from  __httpd__ in the container.
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

3. Try to establish an outgoing connection by running curl in the container
    ```
    $ podman exec -t httpd curl https://podman.io
    curl: (6) Could not resolve host: podman.io
    $
    ```
    (The command-line option `--network=none` was added to `podman run` to prevent the container from establishing outgoing connections)

### Socket activate httpd with systemd-socket-activate

If you just ran the previous example, first run `systemctl --user stop httpd.service` and `systemctl --user stop httpd.socket`. The TCP port 8080 needs to be available for this example.

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

### httpd socket activation configuration

The passed in sockets need to match corresponding `Listen` directives in the __httpd__ configuration.
For example, here the port number 8080 needs to used both in the file _httpd.conf_ and in the socket unit _httpd.socket_.

```
    $ grep 8080 systemd/httpd.socket
    ListenStream=127.0.0.1:8080
    $ grep 8080 Containerfile
    RUN sed -i "s/Listen 80/Listen 127.0.0.1:8080/g" /etc/httpd/conf/httpd.conf
    $
```

### Troubleshooting

#### The container takes long time to start

Pulling a container image may take long time. This delay can be avoided by pulling the container
image beforehand and adding the command-line option `--pull=never` to `podman run`.

A good way to diagnose problems is to look in the journald log for the service:

```
journalctl -xe --user -u httpd.service
```
