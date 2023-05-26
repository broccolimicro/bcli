all:
	DOCKER_BUILDKIT=1 docker build --shm-size=4gb --secret id=user,src=.secret/user --secret id=token,src=.secret/token -t git.broccolimicro.io/broccoli/broccoli-cli:latest -t public.ecr.aws/l5h5o6z4/broccoli-cli:latest .

