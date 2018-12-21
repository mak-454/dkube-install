#!/usr/bin/env sh
echo "cloning dkube-installer ...."
git clone https://github.com/mak-454/dkube-install /tmp/dkube-install && cd /tmp/dkube-install && git checkout alpha3.1

pkg="all"
if [ "$2" = "rdma=yes" ]
then
       git clone https://github.com/kubeflow/mpi-operator.git /tmp/mpi-operator
       if [ $? != 0 ]
       then
               echo "Git cloning failed for mpi-operator"
               exit 1
       fi
	pkg="all+rdma"
fi
sleep 1
if [ -d "installer" ]; then
	cd installer/
	echo "Installing python dependancies ...."
	pip3 install -r requirements.txt
	sleep 1
	if [ $1 = "install" ]; then
	    ./dkubectl deploy --pkg $pkg --client_id ${CLIENT_ID} --client_secret ${CLIENT_SECRET}
	else
	    ./dkubectl delete --pkg $pkg
	fi
else
	echo "Installer directory not found"
	exit 1
fi

