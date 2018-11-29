FROM ubuntu:16.04

RUN apt update
RUN apt install git vim virtualenv wget uuid-runtime python3-pip -y
RUN apt-get update && apt-get install -y apt-transport-https curl
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >/etc/apt/sources.list.d/kubernetes.list
RUN apt-get update
RUN apt-get install -y kubelet=1.12.2-00 kubeadm=1.12.2-00 kubectl=1.12.2-00
ADD install.sh /usr/local/bin/install.sh
RUN chmod +x /usr/local/bin/install.sh
ADD dfabproxy.yaml /opt/dkube/dfabproxy.yaml
#ENTRYPOINT /usr/local/bin/install.sh
