FROM debian:buster-slim

MAINTAINER hleroy <hleroy@hleroy.com>

# Install nmap ndiff msmtp and mailutils
RUN apt-get update && DEBIAN_FRONTEND=noninteractive \
     apt-get install -q -y --no-install-recommends \
     nmap ndiff msmtp msmtp-mta bsd-mailx ca-certificates && \
     apt-get clean && \
     rm -rf /var/lib/apt/lists/*

COPY scan.sh /app/

VOLUME ["/results"]

CMD ["/app/scan.sh"]
