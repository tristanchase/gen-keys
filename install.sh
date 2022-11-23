#!/bin/bash
set -e
#
# install.sh
#
# Tristan M. Chase 2022-11-23
#
# Installs gen-keys.sh and any related scripts and system software needed to run it.

# Variables

## Preserve starting directory.
start_dir="$(pwd)"

## Dependencies

### System
sys_deps="ssh-keygen keychain"

### gen-keys-specific
script_deps="gen-keys"

## Destination
dir=$HOME/bin

# Process

## Install missing $sys_deps
echo "Installing system software needed for gen-keys to run..."
echo ""
sleep 2
sudo apt install $sys_deps
sleep 2
echo "Done installing system software."
echo ""

## Download raw $script_deps from GitHub to $dir
echo "Downloading script files from GitHub..."
echo ""
sleep 2

### Create destination directory and change to it
mkdir -p $dir
cd $dir

### Get the files.
for file in $script_deps; do
	wget https://raw.githubusercontent.com/tristanchase/$file/main/$file.sh
	mv $file.sh $file # Rename the $file (drop the .sh)
	chmod 755 $file   # Make the $file executable
done

### Finish up.
sleep 2
echo "Installation complete. You may now use gen-keys by typing it on the command line."
echo ""

## Check to see if $dir is in $PATH

### If not, add it and modify .(bas|zs|oh-my-zs)hrc to include it.

## Return to starting directory.
cd $start_dir

exit 0
