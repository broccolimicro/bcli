# Broccoli Development Environment

The following tools are available:
go       - architectural and behavioral simulation
haystack - formal synthesis of self-timed circuits
act      - circuit design and digital simulation
prspice  - configure digital/analog circuit co-simulation
Xyce     - analog circuit simulation
gaw      - analog waveform viewer
magic    - circuit layout

Semiconductor PDKs are in /opt/cad/conf
Packages may be installed with 'sudo apt install <package>'
Other usages of sudo are disabled

## Setup

Download the Skywater 130nm PDK and configuration files, and extract them to your home directory: 
```
wget https://broccoli-hosting.s3.us-east-2.amazonaws.com/sky130.tar.gz
mkdir ~/tech; tar -xzvf sky130.tar.gz -C ~/tech
```
Pull the docker image for the broccoli command line interface, and configure it.
```
docker pull public.ecr.aws/l5h5o6z4/broccoli-cli:latest
git clone https://git.broccolimicro.io/Broccoli/broccoli-cli.git
source broccoli-cli/bcli-develop.sh
export BCLI_TECH="$HOME/tech"
```

## Runtime

Boot up the development environment in docker
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
Finally, vim is fully set up for both golang and act.
```
vim file.act
```
When you are done, you can shut down the development environment.
```
bcli down
```

## Troubleshooting

If graphical tools (such as magic and gaw) fail to launch, you may need to install ```xhost``` on your local machine, and grant docker permission to access your X server.
```
xhost +local:docker
```
