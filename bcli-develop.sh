bcli() {
	if [ "$1" = "up" ]; then
		docker run -d -v $HOME:/host --rm --name "bcli-develop" -h "bcli-develop" -e USER=$USER -e USER_ID=$(id -u) -e GROUP_ID=$(id -g) git.broccolimicro.io/broccoli/development-environment:latest > /dev/null
		echo "bcli-develop started"
	elif [ "$1" = "down" ]; then
		docker stop bcli-develop > /dev/null
		echo "bcli-develop stopped"
	else 
		docker exec -u $(id -u):$(id -g) -it bcli-develop /bin/bash
	fi 
}
