#!/bin/bash

# Exercise 01 - Shell scripting - Marius Bordal & Teklit Haileab

# Global Variables:
verbose_flag=false
MOTD=""
MTU="1500"

# Verbose mode functionality:
# This wil set "verbose_flag" to either true or false depending on wether or not "-v" or "--verbose" was given as argument
# usage: ./script.sh -v OR ./script.sh --verbose
check_for_verbose() {
    for var in "$@"
    do
        if [ "$var" = "-v" ] || [ "$var" = "--verbose" ]; then
            verbose_flag=true
        fi
    done
}

# Update MOTD functionality:
# This will set the MOTD variable to be the argument right after "--m" or "--motd" argument when running the script
# usage: ./script.sh -m "Message of the day" OR ./script.sh --motd "Message of the day" (quotation marks are optional)
check_for_MOTD() {
    for (( i=1; i<=$#; i++ ))
    do  # Get the next argument after "-m" or "--motd"
        if [ "${!i}" = "-m" ] || [ "${!i}" = "--motd" ]; then
            j=$((i+1))
            MOTD="${!j}" 
        fi
    done
}

# Update MTU functionality:
# This will set the mtu variable to whichever argument comes right after "--mtu"
# usage: ./script.sh --mtu [number] OR --MTU [number]
check_for_MTU() {
    for (( i=1; i<=$#; i++ )) # loop through arguments:
    do
        if [ "${!i}" = "--mtu" ] || [ "${!i}" = "--MTU" ]; then # if mtu arguments is given            
            j=$((i+1))      # Get the next argument after "--mtu" or "--MTU"
            MTU="${!j}"     # make the MTU variable equal the argument directly afet "--mtu"

            # make the mtu revert back to 1500 if that is given as argument,
            # this if statement will not run unless the mtu argument is given,
            # so that it won't revert back unless 1500 is actually given:
            if  [ "${!j}" = "1500" ]; then
                sudo ip link set dev docker0 mtu "$MTU" >/dev/null 2>&1
                if [ "$verbose_flag" = "true" ]; then
                    echo "updated MTU to $MTU"
                fi
            fi
        fi
    done
}


# Shared functions:

# verbose functions, with comments:

# Function to add users with verbose mode on:
add_users_verbose () {
    # check for existance of docker group, create it if it doesn't exist
    if [ ! "$(getent group docker)" ]; then
        sudo groupadd docker
    fi

    # loop thorugh arguments given
    for arg in "$@"; do

        # if the argument is for verbose, mtu or motd functionality, ignore them, also ignore all numbers
        if [[ ! "$arg" =~ ^[0-9]+$ && "$arg" != "-v" && "$arg" != "--verbose" && "$arg" != "-m" && "$arg" != "--motd" && "$arg" != "--mtu" && "$arg" != "--MTU" && "$arg" != "$MOTD" ]]; then

            # check if user already exists
            if id -u "$arg" >/dev/null 2>&1; then
                echo "$arg exists as a user"
            else
                # add argument as user
                sudo useradd -m -G docker "$arg"

                # set password for user, default: "passord"
                password=$(openssl passwd -1 "passord")
                sudo usermod -p "$password" "$arg"

                # print to console
                echo "$arg added as user"
                echo "$arg added to docker group"
            fi
        fi
    done
}

# Function to update MTU with verbose mode on:
update_mtu_verbose () {
    
    echo "updating MTU to $MTU"

    #Temporarily stop docker and update mtu
    sudo systemctl stop docker
    sudo ip link set dev docker0 mtu "$MTU"

    # restart all services
    sudo systemctl restart docker docker.service containerd containerd.service 
}

# Function to update MOTD with verbose mode on:
update_motd_verbose () {
    echo "updating message of the day"
    sudo rm -rf /etc/motd                           # delete if folder exists
    sudo mkdir /etc/motd                            # create folder    
    sudo touch /etc/motd/01.txt                     # create txt file within folder
    sudo chmod a+rw /etc/motd/01.txt                # change permissions of txt file
    sudo sh -c "echo '$MOTD' > /etc/motd/01.txt"    # print message of the day and save to file
    echo "meesage of the day:"
    echo "$MOTD"
}


# silent functions, no comments on these, they are the exact same as the verbose functions, only difference is that they don't print anything to conosle

add_users_silent () {
    if [ ! "$(getent group docker)" ]; then
        sudo groupadd docker >/dev/null 2>&1
    fi

    for arg in "$@"; do
        if [[ ! "$arg" =~ ^[0-9]+$ && "$arg" != "-v" && "$arg" != "--verbose" && "$arg" != "-m" && "$arg" != "--motd" && "$arg" != "--mtu" && "$arg" != "--MTU" && "$arg" != "$MOTD" ]]; then
            
            if id -u "$arg" >/dev/null 2>&1; then
                echo "$arg already exists as a user" >/dev/null 2>&1
            else
                sudo useradd -m -G docker "$arg" >/dev/null 2>&1
                password=$(openssl passwd -1 "passord") >/dev/null 2>&1
                sudo usermod -p "$password" "$arg" >/dev/null 2>&1
            fi
        fi
    done
}

update_mtu_silent () {
    sudo systemctl stop docker >/dev/null 2>&1
    sudo ip link set dev docker0 mtu "$MTU" >/dev/null 2>&1
    sudo systemctl restart docker docker.service containerd containerd.service >/dev/null 2>&1
}

update_motd_silent () {
    sudo rm -rf /etc/motd >/dev/null 2>&1         
    sudo mkdir /etc/motd >/dev/null 2>&1         
    sudo touch /etc/motd/01.txt >/dev/null 2>&1      
    sudo chmod a+rw /etc/motd/01.txt >/dev/null 2>&1 
    sudo sh -c "echo '$MOTD' > /etc/motd/01.txt" >/dev/null 2>&1  
}


# Functions specific for Ubuntu (only the verbose funtions contain comments, the silent functions are the same, but silent):
install_docker_ubuntu_verbose () {
    # update OS before anything
    echo "updating ubuntu"
    sudo apt update
    sudo apt upgrade -y

    # remove old versions
    echo "removing old versions of docker"
    sudo apt-get remove -y docker docker.io containerd runc
	sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common lsb-release
	
    # set up keyring if it is not already set up
    echo "setting up keyring for docker"
    if [ -e "/etc/apt/keyrings" ]; then	
        echo "keyring already exists"
    else
	    sudo mkdir -p /etc/apt/keyrings
	    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	    echo \
  		    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  		    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    fi    
    
    sudo chmod a+r /etc/apt/keyrings/docker.gpg # give read/write permissions to the keyring to avoid issues

	# install docker and enable it on startup
    echo "installing docker"
	sudo apt-get update
	sudo apt-get install -y docker docker-ce docker-ce-cli containerd.io docker-compose-plugin
	sudo systemctl enable docker
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
}

install_docker_ubuntu_silent () {
    sudo apt update >/dev/null 2>&1
    sudo apt upgrade -y >/dev/null 2>&1
    sudo apt-get remove -y docker docker.io containerd runc >/dev/null 2>&1
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common lsb-release >/dev/null 2>&1
    if [ -e "/etc/apt/keyrings" ]; then
        sudo rm -rf -p /etc/apt/keyrings >/dev/null 2>&1
    else
	    sudo mkdir -p /etc/apt/keyrings >/dev/null 2>&1
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg >/dev/null 2>&1
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null 2>&1
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - >/dev/null 2>&1
    fi
    
    
    sudo chmod a+r /etc/apt/keyrings/docker.gpg >/dev/null 2>&1
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install -y docker docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null 2>&1
    sudo usermod -aG docker "$(whoami)" >/dev/null 2>&1  
    sudo systemctl enable docker >/dev/null 2>&1
    sudo systemctl enable docker.service >/dev/null 2>&1
    sudo systemctl enable containerd.service >/dev/null 2>&1
}


# Functions specific for CentOS (only the verbose funtions contain comments, the silent functions are the same, but silent)::
install_docker_centos_verbose () {
    # CentOS 8 has reached its EOL, therefore we must cange the repo URL:
    echo "changing repository URL"
	sudo sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
	sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

	# update the system packages
    echo "updating centOS"
	sudo dnf update -y

	# install the required dependencies
    echo "installing required dependencies"
	sudo dnf install -y dnf-utils device-mapper-persistent-data lvm2

	# add the Docker repository
    echo "adding the Docker repository"
	sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
	# install Docker
    echo "installing Docker"
	sudo dnf install -y docker-ce docker-ce-cli containerd.io
	
    # start and enable Docker
	sudo systemctl start docker
    sudo systemctl enable docker
}

install_docker_centos_silent () {
	sudo sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* >/dev/null 2>&1
	sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* >/dev/null 2>&1
	sudo dnf update -y >/dev/null 2>&1
	sudo dnf install -y dnf-utils device-mapper-persistent-data lvm2 >/dev/null 2>&1
	sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo >/dev/null 2>&1
	sudo dnf install -y docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
	sudo systemctl start docker >/dev/null 2>&1
    sudo systemctl enable docker >/dev/null 2>&1
}


# Functions specific for Arch Linux (only the verbose funtions contain comments, the silent functions are the same, but silent)::
install_docker_arch_verbose() {
    # updating OS
    echo "updating Arch Linux"
    sudo pacman -Syu --noconfirm

    #install docker
    echo "installing docker"
	sudo pacman -S docker --noconfirm
    sudo systemctl enable docker
    sudo systemctl start docker
}

install_docker_arch_silent () {
    sudo pacman -Syu --noconfirm > /dev/null 2>&1
	sudo pacman -S docker --noconfirm > /dev/null 2>&1
    sudo systemctl enable docker > /dev/null 2>&1
    sudo systemctl start docker > /dev/null 2>&1
}


# Function to detect OS, and to decide which "install_docker" function to run:
detect_OS () {
    # read "os-release" file
    file="/etc/os-release"
    while read -r line; do
        
        # If "Ubuntu" is fouund in file, download docker for ubuntu
        if echo "$line" | grep -q "Ubuntu"; then
            echo "package manager = APT"

            # check if verbose mode is activated
            if [ "$verbose_flag" = "true" ]; then
                install_docker_ubuntu_verbose
                break
            elif [ "$verbose_flag" = "false" ]; then
                echo "installing docker silently"
                install_docker_ubuntu_silent
                break
            fi

        # If "CentOS" is fouund in file, download docker for CentOS
        elif echo "$line" | grep -q "CentOS"; then
            echo "package manager = DNF"

            if [ "$verbose_flag" = "true" ]; then
                install_docker_centos_verbose
                break
            elif [ "$verbose_flag" = "false" ]; then
                echo "installing docker silently"
                install_docker_centos_silent
                break
            fi

        # If "Arch Linux" is fouund in file, download docker for Arch Linux
        elif echo "$line" | grep -q "Arch Linux"; then
            echo "package manager = pacman"

            if [ "$verbose_flag" = "true" ]; then
                install_docker_arch_verbose
                break
            elif [ "$verbose_flag" = "false" ]; then
                echo "installing docker silently" 
                install_docker_arch_silent
                break
            fi
        fi
    done < "$file"
}

# check if verbose-mode, MOTD and/or MTU were given as arguments:
check_for_verbose "$@"
check_for_MOTD "$@"
check_for_MTU "$@"

# Detect OS, this function will run the correct "install_docker" function based on which OS is detected
detect_OS  

# run add user command, silently or verbosely, depending on the verbose flag
if [ "$verbose_flag" = "true" ]; then
    add_users_verbose "$@"
else
    add_users_silent "$@"
fi

# Update MOTD if argument was given, silently or verbosely, depending on the verbose flag
if [ "$MOTD" != "" ]; then
    if [ "$verbose_flag" = "true" ]; then
        update_motd_verbose
    else
        update_motd_silent
    fi
fi

# Update MTU if argument was given, silently or verbosely, depending on the verbose flag
if [ "$MTU" != "1500" ]; then
    if [ "$verbose_flag" = "true" ]; then
        update_mtu_verbose
    else
        update_mtu_silent
    fi
fi

# script done.
exit 0
