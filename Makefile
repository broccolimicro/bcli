all:
	DOCKER_BUILDKIT=1 docker build . --secret id=user,src=.secret/user --secret id=token,src=.secret/token -t git.broccolimicro.io/broccoli/development-environment:latest
