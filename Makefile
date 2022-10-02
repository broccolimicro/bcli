all:
	DOCKER_BUILDKIT=1 docker build --shm-size=4gb --secret id=user,src=.secret/user --secret id=token,src=.secret/token -t git.broccolimicro.io/broccoli/development-environment:latest .

local:	
	DOCKER_BUILDKIT=1 docker build --shm-size=4gb --secret id=user,src=.secret/user --secret id=token,src=.secret/token -t git.broccolimicro.io/broccoli/development-environment:latest --add-host=git.broccolimicro.io:10.0.0.65 .
