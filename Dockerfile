FROM progrium/busybox
RUN opkg-install bash coreutils-base64 openssh-client-utils openssh-client
#RUN mkdir -p /etc/ssl && mkdir -p /etc/ssl/certs
#ADD certs /etc/ssl/certs/
ENV SHELL /bin/bash
RUN mkdir setup
ADD . setup
WORKDIR setup
RUN chmod +x setup.sh
CMD "./setup.sh"
