bcli() {
	if [ "$1" = "up" ]; then
		docker run -d -v $HOME:/host --rm --name "bcli-develop" -h "bcli-develop" -e USER=$USER -e USER_ID=$(id -u) -e GROUP_ID=$(id -g) -e DISPLAY=$DISPLAY -v "/tmp/.X11-unix:/tmp/.X11-unix:rw" git.broccolimicro.io/broccoli/development-environment:latest > /dev/null
		echo "bcli-develop started"
	elif [ "$1" = "down" ]; then
		docker stop bcli-develop > /dev/null
		echo "bcli-develop stopped"
	elif [ "$1" = "mount" ]; then
		mkdir -p $HOME/tech
		sshfs $BROCCOLI_USER@broccolimicro.io:/opt/tech $HOME/tech/
	elif [ "$1" = "unmount" ]; then
		umount $HOME/tech
		rmdir $HOME/tech
	else 
		docker exec -u $(id -u):$(id -g) -it bcli-develop /bin/bash
	fi 
}
