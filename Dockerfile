FROM debian:10
RUN apt-get update && apt-get install -y init openssh-client openssh-server openssh-sftp-server curl bash-completion && curl -L -o /usr/local/bin/k3s https://github.com/rancher/k3s/releases/download/v1.19.2%2Bk3s1/k3s && \
    chmod +x /usr/local/bin/k3s && \
    curl -sfL https://get.k3s.io > /root/install-k3s.sh && chmod +x /root/install-k3s.sh
COPY files/* /root/
