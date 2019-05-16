#!/bin/bash

# Helper script to setup a new Linux (probably mostly Ubuntu specific stuff in here) machine
# Sets various settings
#
# Options:
# -d: Downloads packages and installs various applications


# Probably the worst way of checking for options :)
if [ $# -gt 0 ]; then
    case $1 in
        "-d")
            if [ $(id -u) -eq 0 ]; then # Is ran as root
                echo "Downloading.."

                # Download packages
                apt update && apt upgrade

                apt install gnome-tweaks # Extra settings for gnome
                echo -e "\n\n\tDownloading 'gnome-tweaks'"

                apt install dconf-editor # A lot of different settings
                echo -e "\n\n\tDownloading 'dconf-editor'"

                apt install python3-dev python3-pip python3-setuptools
                echo -e "\n\n\tDownloading python tools"

                pip3 install thefuck
                echo -e "\n\n\tDownloading 'fuck' from https://github.com/nvbn/thefuck"
            else
                echo "Error: -d needs root permissions, run with sudo"
            fi
    esac
fi

# Read the bashrc file
bashrc=$(cat ~/.bashrc)

# PROMPT_DIRTRIM not already added
if [[ $bashrc != *"PROMPT_DIRTRIM"* ]]; then
    echo -e "PROMPT_DIRTRIM=3\n" >> ~/.bashrc # Sets the terminal prompt to max 3 directories
fi


dconfInstalled=false
# If dconf-editor is not installed, ask if the user wants to install it
if [ $(dpkg-query -W -f='${Status}' dconf-editor 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "dconf-editor is not installed, do you want to install it? (y/n)"
    read -r answer

    case $answer in
        "y")
            if [ $(id -u) -eq 0 ]; then # is root, install dconf-editor
                apt install dconf-editor
                dconfInstalled=true
            else
                echo "Error: Need root permissions to install dconf-editor, run with sudo"
            fi
            ;;
        *)
            ;;
    esac
else
    dconfInstalled=true
fi

# If dconf-editor is installed change various settings
if [ $dconfInstalled ]; then
    # Import terminal profiles from the profiles/ directory
    # Exporting profiles can be done with:
    # dconf dump /org/gnome/terminal/legacy/profiles:/:<profileid>/ > <profileid>

    for profile in $(find profiles/ -type f); do
        name=$(basename $profile) # The name of the actual file (not the entire path)
        dconf load /org/gnome/terminal/legacy/profiles:/:$name/ < $profile
    done

    # Cycles through windows if mutliple of the same are open
    # IE. if multiple chrome windows are open, cycle through them when clicked on the taskbar
    # Other values can be found in dconf-editor and by following org.gnome.shell...
    gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'cycle-windows'
    gsettings set org.gnome.desktop.interface clock-show-seconds true # Show seconds in clock on top
    gsettings set org.gnome.desktop.interface clock-show-weekday true # Show what day it is in clock on top (mo, tu etc.)
fi


# Add /opt/lampp to path (through bashrc) if it's not there
# This allows the usage of "xampp start" from anywhere
# TODO: Need to do something with sudoers, since xampp needs sudo and sudo cant be called from everywhere
if [[ $PATH != *":/opt/lampp"* ]] || [[ $bashrc != *":/opt/lampp"* ]]; then
    echo -e "export PATH=$PATH:/opt/lampp\n" >> ~/.bashrc
fi


echo "Restart your terminal for changes to appear" # Source ~/.bashrc doesn't seem to work in a script