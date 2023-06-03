bcli() {
    if [ "$1" = "up" ]; then
	export MEMBERS="$(groups | sed 's/ /\n/g' | xargs -I{} getent group {} | sed 's/\([^:]*\):[^:]*:\([^:]*\):.*/\2 \1/g')"
	docker run --rm -d -v $HOME:/host -v "/opt/tech:/opt/cad/conf" --name "bcli-$USER" -h "bcli-$USER" -e USER=$USER -e USER_ID=$(id -u) -e GROUP_ID=$(id -g) -e DISPLAY=$DISPLAY -e MEMBERS="$MEMBERS" -v "/tmp/.X11-unix:/tmp/.X11-unix:rw" public.ecr.aws/l5h5o6z4/broccoli-cli:latest > /dev/null
	#docker run --rm -d -v $HOME:/host -v "${BCLI_TECH:/opt/tech}:/opt/cad/conf" --name "bcli-$USER" -h "bcli-$USER" -e USER=$USER -e USER_ID=$(id -u) -e GROUP_ID=$(id -g) -e DISPLAY=$DISPLAY -v "/tmp/.X11-unix:/tmp/.X11-unix:rw" ${BCLI_IMAGE:-public.ecr.aws/l5h5o6z4/broccoli-cli:latest} > /dev/null
	echo "bcli-$USER started"
    elif [ "$1" = "down" ]; then
	docker stop "bcli-$USER" > /dev/null
	echo "bcli-$USER stopped"
	#legacy, or if server files change faster than a new download
    elif [ "$1" = "mount" ]; then
	if [ -z "$BROCCOLI_USER" ]; then
	    echo "Please set the BROCCOLI_USER environment variable for ssh access."
	else
	    mkdir -p $HOME/tech
 	    sshfs $BROCCOLI_USER@broccolimicro.io:/opt/tech $HOME/tech/
	fi
    elif [ "$1" = "unmount" ]; then
	shift
	if [ "$1" = "-f" ]; then
	    pkill -KILL sshfs
	    fusermount -u $HOME/tech
	else
	    umount $HOME/tech
	fi
	rmdir $HOME/tech
    elif [ "$#" -eq 0 ]; then
	WD="/host"
	if [[ "$PWD" = "$HOME/"* ]]; then
		WD="/host${PWD#$HOME}"
	fi
	docker exec -u $(id -u) -w $WD -it "bcli-$USER" /bin/bash
    else
	if [ "$1" != "--help" ]; then
	    echo "error: unrecognized command '$1'"
	    echo ""
	fi

	echo "usage: bcli <command>"
	echo "If command is empty, then start a terminal logged into the toolset."
	echo "  up      - launch the toolset"
	echo "  down    - shutdown the toolset"
	echo "  mount   - legacy command; mount the technology files from broccolimicro.io"
	echo "  unmount - legacy command; unmount the technology files"
	echo "    -f    - legacy option; force the unmount if the connection has been broken"
    fi 
}
