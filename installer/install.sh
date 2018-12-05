#!/usr/bin/env sh
echo "cloning dkube-installer ...."
git clone https://github.com/mak-454/dkube-install /tmp/dkube-install && cd /tmp/dkube-install && git checkout alpha3_rdma
git clone https://github.com/kubeflow/mpi-operator.git /tmp/mpi-operator
sleep 1
if [ -d "installer" ]; then
	cd installer/
	echo "Installing python dependancies ...."
	pip3 install -r requirements.txt
	sleep 1
	if [ $1 = "install" ]; then
	    ./dkubectl deploy --pkg $2 --client_id ${CLIENT_ID} --client_secret ${CLIENT_SECRET}
	    kubectl apply -f /opt/dkube/dfabproxy.yaml
	else
	    kubectl delete -f /opt/dkube/dfabproxy.yaml
	    ./dkubectl delete --pkg $2
	fi
else
	echo "Installer directory not found"
	exit 1
fi

