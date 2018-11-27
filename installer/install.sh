#!/usr/bin/env sh
echo "cloning dkube-installer ...."
git clone https://github.com/mak-454/dkube-install && cd dkube-install && git checkout alpha3
sleep 1
if [ -d "installer" ]; then
	cd installer/
	echo "Installing python dependancies ...."
	pip3 install -r requirements.txt
	sleep 1
	if [ $1 = "install" ]; then
	    ./dkubectl deploy --pkg all --client_id ${CLIENT_ID} --client_secret ${CLIENT_SECRET}
	else
	    ./dkubectl delete --pkg all
	fi
else
	echo "Installer directory not found"
	exit 1
fi

