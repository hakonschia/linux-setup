#!/bin/bash

# Helper script to setup a new Linux (probably mostly Ubuntu specific stuff in here) machine
# Sets various settings
#
# Options:
# -d: Downloads packages and installs various applications

uid=$(id -u) # The user ID of the user running the program (used to check for sudo)

# Probably the worst way of checking for options :)
if [ $# -gt 0 ]; then
    case $1 in
        "-d")
            if [ "$uid" -eq 0 ]; then # Is ran as root
                echo "Downloading.."

                # Download packages
                apt update && apt upgrade

                apt install gnome-tweaks # Extra settings for gnome
                echo -e "\\n\\n\\tDownloading 'gnome-tweaks'"

                apt install dconf-editor # A lot of different settings
                echo -e "\\n\\n\\tDownloading 'dconf-editor'"

                apt install python3-dev python3-pip python3-setuptools
                echo -e "\\n\\n\\tDownloading python tools"

                pip3 install thefuck
                echo -e "\\n\\n\\tDownloading 'fuck' from https://github.com/nvbn/thefuck"
            else
                echo "Error: -d needs root permissions, run with sudo"
            fi
    esac
fi

# Read the bashrc file
bashrc=$(cat ~/.bashrc)

# PROMPT_DIRTRIM not already added
if [[ $bashrc != *"PROMPT_DIRTRIM"* ]]; then
    echo -e "PROMPT_DIRTRIM=3\\n" >> ~/.bashrc # Sets the terminal prompt to max 3 directories
fi


dconfInstalled=false
# If dconf-editor is not installed, ask if the user wants to install it
if [ "$(dpkg-query -W -f='${Status}' dconf-editor 2>/dev/null | grep -c "ok installed")" -eq 0 ]; then
    echo "dconf-editor is not installed, do you want to install it? (y/n)"
    read -r answer

    case $answer in
        "y")
            if [ "$uid" -eq 0 ]; then # is root, install dconf-editor
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
if [ "$dconfInstalled" ]; then
    # Import terminal profiles from the profiles/ directory
    # Exporting profiles can be done with:
    # dconf dump /org/gnome/terminal/legacy/profiles:/:<profileid>/ > <profileid>

    profileList=$(gsettings get org.gnome.Terminal.ProfilesList list)

    # Remove the last bracket "['23vfewf-2f32f']" becomes "['23vfewf-2f32f'"
    profileList=${profileList:0:-1}

    for profile in $(find profiles/ -type f); do
        # TODO: Checking against duplicates
        # Will now add duplicate entries to the list, so it will say you have multiple of the same profile

        name=$(basename "$profile") # The name of the actual file, ie. the profile ID (not the entire path)
        dconf load /org/gnome/terminal/legacy/profiles:/:"$name"/ < "$profile"


        profileList="$profileList, '$name'" # Add the profile to the list

        # Need to add the profile name to org.gnome.terminal.legacy.profiles.list
    done

    profileList="$profileList]" # Readd the bracket

    gsettings set org.gnome.Terminal.ProfilesList list "$profileList"


    # Cycles through windows if mutliple of the same are open
    # IE. if multiple chrome windows are open, cycle through them when clicked on the taskbar
    # Other values can be found in dconf-editor and by following org.gnome.shell...
    gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'cycle-windows'
    
    gsettings set org.gnome.desktop.interface clock-show-date true # Show the date (sep. 3 etc.)
    gsettings set org.gnome.desktop.interface clock-show-seconds true # Show seconds in clock on top
    gsettings set org.gnome.desktop.interface clock-show-weekday true # Show what day it is in clock on top (mo, tu etc.)
fi


# Add /opt/lampp to path (through bashrc) if it's not there
# This allows the usage of "xampp start" from anywhere
if [[ "$PATH" != *":/opt/lampp"* ]] || [[ $bashrc != *":/opt/lampp"* ]]; then
    echo -e "export PATH=$PATH:/opt/lampp\  \n" >> ~/.bashrc
fi

# To use sudo <command> the exectuable needs to be in a path in secure_path in /etc/sudoers
if [[ "$uid" -eq 0 ]]; then # Is root
    sudoers=$(cat /etc/sudoers | grep secure_path)

    if [[ $sudoers != *":/opt/lampp"* ]]; then
        # Remove the double quote at the end, add :/opt/lampp and a new double qoute
        sudoersNew="${sudoers:0:-1}:/opt/lampp\""

        # Edit the line matching what was in the secure_path line, and change it to the new one
        # sed -i s/<pattern>/<replacement>/a <file>
        # -i = inline edit
        # s = substitution
        # pattern is the regex to match
        # replacement is what should it be replaced by

        # Use the old as the pattern to match against, and the new to replace it
        sed -i "s|$sudoers|$sudoersNew|g" "/etc/sudoers"
    fi           
else
    echo "Run with sudo to add xampp to sudoers"
fi


# Installs some gnome tools and echos where to go to install multi monitors add-on
if [[ "$uid" -eq 0 ]]; then
    apt install gnome-tweak-tool
    apt install chrome-gnome-shell

    echo "Go to https://chrome.google.com/webstore/detail/gnome-shell-integration/gphhapmejobijbbhgpjhcjognlahblep"
    echo "Go to https://extensions.gnome.org/extension/921/multi-monitors-add-on/"
fi


# Instead of boring sudo !! when forgetting sudo, have some manners and ask nicely instead
# '"'"' = end the first string, add a new string with double quotes with a single quote in it
# concatinate that again with a new string
# It turns out as: alias please='sudo $(history -p !!)'
if [[ "$bashrc" != *"alias please"* ]]; then
    # -e to print \n as newline
    echo -e '\nalias please='"'"'sudo $(history -p !!)'"'"'' >> ~/.bashrc
fi
# Add alias for both please and pls
if [[ "$bashrc" != *"alias pls"* ]]; then
    echo -e '\nalias pls='"'"'sudo $(history -p !!)'"'"'' >> ~/.bashrc
fi


echo "Restart your terminal for changes to appear" # source ~/.bashrc doesn't seem to work in a script :(