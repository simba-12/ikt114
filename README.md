## Exercise 01 - Shell Scripting

This script is designed to automate the installation of Docker, update the Message of the Day (MOTD), and modify the Maximum Transmission Unit (MTU) on various Linux distributions. It also includes functionality to add users to the Docker group.

```
./script.sh [options] [usernames...]

``` 

## Options

```
-v, --verbose: Enable verbose mode.
-m, --motd [message]: Set the Message of the Day.
--mtu [number]: Set the MTU value.

```
### Examples
```
Install Docker and add users silently:

./script.sh user1 user2

Install Docker with verbose mode and set MOTD:

./script.sh -v -m "Welcome to the server" user1 user2

Set MTU value to 1400:
./script.sh --mtu 1400 user1 user2

```

## Functions
### Docker Installation  
```
install_docker_ubuntu_verbose: Install Docker on Ubuntu with verbose output.
install_docker_ubuntu_silent: Install Docker on Ubuntu silently.
install_docker_centos_verbose: Install Docker on CentOS with verbose output.
install_docker_centos_silent: Install Docker on CentOS silently.
install_docker_arch_verbose: Install Docker on Arch Linux with verbose output.
install_docker_arch_silent: Install Docker on Arch Linux silently.
```

## User Management
```
add_users_verbose: Add users to the Docker group with verbose output.
add_users_silent: Add users to the Docker group silently.
```

## MTU Update
```
update_mtu_verbose: Update the Maximum Transmission Unit with verbose output.
update_mtu_silent: Update the Maximum Transmission Unit silently.
```

## OS Detection
```
detect_OS: Detect the operating system and run the appropriate Docker installation function.
```

## Argument Parsing
```
check_for_verbose: Check if verbose mode is enabled.
check_for_MOTD: Check if MOTD is provided.
check_for_MTU: Check if MTU is provided.
```