docker-nmap-scans
=================

A simple Docker container that uses `nmap` to scan a set of servers on a
regular interval and sends an email when `ndiff` detects a change.

Configuration
-------------

Store configuration files in an environment file, such as `/etc/default/docker-nmap-scans`, Example:

```
# TARGETS is a space separated list of targets passed to nmap to scan and
# supports all targets that nmap supports. Required.
TARGETS=host.example.com 192.0.2.1 198.51.100.0/24

# MAILTO is the email address ndiff results are sent to. Required.
MAILTO=user@example.com

# INTERVAL is the runtime in seconds between scans. Required.
INTERVAL=86400

# OPTIONS is the arguments passed to nmap. Optional, defaults to '-Pn'.
# OPTIONS=-Pn -T5 -p 22,80 -oA

# SMTP configuration
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=username
SMTP_PASS=password
SMTP_FROM=user@example.com
```

Running
-------

```
docker volume create nmap_results
docker run -d --restart=always -v nmap_results:/results --env-file=/etc/default/docker-nmap-scans --name=nmap-scans hleroy/nmap-scans
docker logs -f nmap-scans
```

systemd
-------

An example systemd service file and installation instructions. Alternative use the `--restart` [Docker argument](https://docs.docker.com/reference/run/#restart-policies-restart).

```
cp systemd-docker-nmap-scans.service /etc/systemd/system/docker-nmap-scans.service
systemctl enable docker-nmap-scans
systemctl start docker-nmap-scans
systemctl status docker-nmap-scans
```
