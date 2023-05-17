# Broccoli Development Environment

First time use:

Download the Skywater 130nm PDK and Configuration Files: 

https://broccoli-hosting.s3.us-east-2.amazonaws.com/sky130.tar.gz

Extract to your home directory: 
```
mkdir ~/tech; tar -xzvf sky130.tar.gz -C ~/tech
```

First and subsequent use:

Pull the docker image for the broccoli command line interface.
```
docker pull public.ecr.aws/l5h5o6z4/broccoli-cli:latest
```

Setup the broccoli command line interface with the following command.
```
source bcli-develop.sh
```

Download the developement environment and boot it up in docker
```
bcli up
```

Open up a shell inside the development environment. Here you will have access to all of the necessary tools.
```
bcli
```

If graphical tools (such as magic and gaw) fail to launch, you may need to install ```xhost``` on your local machine, and grant docker permission to access your X server.
```
xhost +local:docker
```

Your home directory will be mounted at
```
/host
```

Many of the installed tools may be found at
```
/opt
```

Finally, vim is fully set up for both golang and act.
```
vim file.act
```

When you are done, you can shut down the development environment.
```
bcli down
```

