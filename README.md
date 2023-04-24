# Broccoli Development Environment

Pull the docker image for the broccoli command line interface.
```
docker pull git.broccolimicro.io/broccoli/broccoli-cli:latest
```

Setup the broccoli command line interface with the following command.
```
source bcli-develop.sh
```

Set up your ssh connection to the technology node server, it is preferrable to set up an ssh key.
```
export BROCCOLI_USER="nbingham"
bcli mount
```

Download the developement environment and boot it up in docker
```
bcli up
```

Open up a shell inside the development environment. Here you will have access to all of the necessary tools.
```
bcli
```

Your home directory will be mounted at
```
/host
```

Many of the installed tools may be found at
```
/opt
```

Finally, vim is fully set up for both golang and act
```
vim file.act
```

When you are done, you can shut down the development environment and disconnect the technology server.
```
bcli down
bcli unmount
```
