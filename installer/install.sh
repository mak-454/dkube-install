echo "cloning dkube-installer ...."
git clone https://github.com/mak-454/dkube-install && cd dkube-install && git checkout installer_test
sleep 1
if [ -d "installer" ]; then
	cd installer/
	echo "Installing python dependancies ...."
	pip3 install -r requirements.txt
	sleep 1
	./dkubectl deploy --pkg all --client_id ${CLIENT_ID} --client_secret ${CLIENT_SECRET}
else
	echo "Installer directory not found"
	exit 1
fi

