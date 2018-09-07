import subprocess as sp
import re
import sys
import time
import os
import argparse

def pretty_green(msg):
    print("\033[1;32m%s\033[0m"%msg)

def pretty_red(msg):
    print("\033[1;31m%s\033[0m"%msg)

def pretty_blue(msg):
    print("\033[1;34m%s\033[0m"%msg)

def my_help():
	pretty_red("python3 %s [--docker_username <docker_username>] [--docker_password <docker-password>]"%sys.argv[0])
	sys.exit(1)

def delete_image(name):
    if not sp.call("sudo docker images | grep %s &> /dev/null"%name,shell=True, executable='/bin/bash'):
        pretty_blue("Deleting %s image..."%name)
        if sp.call("sudo docker images | grep %s | awk '{print $3}' | sudo xargs docker rmi"%name,shell=True, executable='/bin/bash'):
            pretty_red("Failed to delete %s image"%name)

def delete_old_imagees():
	delete_image("dkube/tensorflow-serving-cpu")
	time.sleep(1)
	delete_image("dkube/tensorflow-serving-gpu")
	time.sleep(1)
	delete_image("dkube/tensorflow-cpu")
	time.sleep(1)
	delete_image("dkube/tf-inference-server")
	time.sleep(1)
	delete_image("dkube/tensorflow-notebook-cpu")
	time.sleep(1)
	delete_image("dkube/tensorflow-gpu")
	time.sleep(1)
	delete_image("dkube/tensorboard")

def install_image(name, version):
	pretty_blue("Installing %s image..."%name)
	if not sp.call("sudo docker pull ocdr/%s:%s"%(name, version),shell=True, executable='/bin/bash'):
		time.sleep(1)
		sp.call("sudo docker tag ocdr/%s:%s dkube/%s:%s"%(name, version, name, version),shell=True, executable='/bin/bash')
	else:
		pretty_red("Failed to install %s image"%name)

def install_new_images():
	install_image("tensorflow-serving-cpu", "v1")
	install_image("tensorflow-serving-gpu", "v1")
	install_image("tensorflow-cpu", "v1")
	install_image("tf-inference-server", "v1")
	install_image("tensorflow-notebook-cpu", "v1")
	install_image("tensorflow-gpu", "v1")
	install_image("tensorboard", "v1")

def docker_login(username, passwd):
	if not sp.call("sudo docker login -u %s -p %s"%(username, passwd),shell=True, executable='/bin/bash'):
		pretty_green("Docker login success... !!!")
	else:
		pretty_red("Docker login failed with: %s"%username)

def docker_logout():
	if not sp.call("sudo docker logout",shell=True, executable='/bin/bash'):
		pretty_green("Docker logout successful... !!!")
	else:
		pretty_red("Docker logout failed")

def run():
	parser = argparse.ArgumentParser(description="setup public images")
	parser.add_argument("--docker_username", help="Username for docker hub")
	parser.add_argument("--docker_password", help="Password for docker hub")
	if len(sys.argv)==1:
		parser.print_help(sys.stderr)
		sys.exit(1)
	args = parser.parse_args()

	if ((args.docker_username) and (args.docker_password)):
			DOCKER_USER = args.docker_username
			DOCKER_PASSWORD = args.docker_password
	else:   
			my_help()

	try:
		delete_old_imagees()
		docker_login(DOCKER_USER, DOCKER_PASSWORD)
		install_new_images()
		docker_logout()
	except:
		print("")

run()
