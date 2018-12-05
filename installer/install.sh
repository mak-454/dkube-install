#!/usr/bin/env sh
echo "cloning dkube-installer ...."
#git clone https://github.com/mak-454/dkube-install /tmp/dkube-install && cd /tmp/dkube-install && git checkout alpha3
git clone https://github.com/kubeflow/mpi-operator.git /tmp/mpi-operator
sleep 1
if [ -d "installer" ]; then
	cd installer/
	echo "Installing python dependancies ...."
	pip3 install -r requirements.txt
	sleep 1
	if [ $1 = "install" ]; then
		if [ $2 = "all+rdma" ]; then
	    	./dkubectl deploy --pkg all+rdma --client_id ${CLIENT_ID} --client_secret ${CLIENT_SECRET}
		else
			./dkubectl deploy --pkg all --client_id ${CLIENT_ID} --client_secret ${CLIENT_SECRET}
		fi
	    kubectl apply -f /opt/dkube/dfabproxy.yaml
	else
	    kubectl delete -f /opt/dkube/dfabproxy.yaml
		if [ $2 = "all+rdma" ]; then
		    ./dkubectl delete --pkg all+rdma
		else
			./dkubectl delete --pkg all
		fi
	fi
else
	echo "Installer directory not found"
	exit 1
fi

