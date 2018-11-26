echo "cloning dkube-installer ...."
git clone https://github.com/mak-454/dkube-install && cd dkube-install && git checkout installer_test

echo "Cloning and checkout Done ............."
sleep 1
if [ -d "installer" ]; then
	echo "Inside installer............"
	ls
	cd installer/
	pip3 install -r requirements.txt
	sleep 1
	./dkubectl deploy --pkg all --client_id ${CLIENT_ID} --client_secret ${CLIENT_SECRET}
else
	echo "Installer direcotry not found"
	exit 1
fi

