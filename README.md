# Broccoli Development Environment

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

When you are done, you can shut down the development environment.
```
bcli down
```
