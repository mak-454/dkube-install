FROM ubuntu:16.04

RUN apt update
RUN apt install git vim virtualenv wget uuid-runtime python3-pip -y
RUN apt-get update && apt-get install -y apt-transport-https curl
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >/etc/apt/sources.list.d/kubernetes.list
RUN apt-get update
RUN apt-get install -y kubelet=1.12.2-00 kubeadm=1.12.2-00 kubectl=1.12.2-00
RUN mkdir -p $HOME/.kube/
#RUN cd $HOME && git clone https://github.com/mak-454/dkube-install && source dkube-installation/bin/activate && cd dkube-install/installer/ && pip3 install -r requirements.txt
#RUN source dkube-installation/bin/activate
#RUN cd dkube-install/installer/
#RUN pip3 install -r requirements.txt
