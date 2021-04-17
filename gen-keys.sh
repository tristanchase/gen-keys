#!/usr/bin/env bash

#-----------------------------------
# Usage Section

#<usage>
#//Usage: gen-keys [ {-d|--debug} ] [ {-h|--help} ]
#//Description: Generates SSH keys for use on local and remote hosts
#//Examples: gen-keys foo; gen-keys --debug bar
#//Options:
#//	-d --debug	Enable debug mode
#//	-h --help	Display this help message
#</usage>

#<created>
# Created: 2021-04-16T22:58:21-04:00
# Tristan M. Chase <tristan.m.chase@gmail.com>
#</created>

#<depends>
# Depends on:
#  ssh-keygen
#</depends>

#-----------------------------------
# TODO Section

#<todo>
# TODO

# DONE
# + Insert script
# + Clean up stray ;'s
# + Modify command substitution to "$(this_style)"
# + Rename function_name() to function __function_name__ /\w+\(\)
# + Rename $variables to "${_variables}" /\$\w+/s+1 @v vEl,{n
# + Check that _variable="variable definition" (make sure it's in quotes)
# + Update usage, description, and options section
# + Update dependencies section

#</todo>

#-----------------------------------
# License Section

#<license>
# Put license here
#</license>

#-----------------------------------
# Runtime Section

#<main>
# Initialize variables
#_temp="file.$$"

# List of temp files to clean up on exit (put last)
#_tempfiles=("${_temp}")

# Put main script here
function __main_script__ {

	# Work in the right place
	cd ~/.ssh

	# Get the name of the remote machine
	printf "Enter the name of the remote machine (blank quits): "
	read _remote_machine
	if [[ -z "${_remote_machine}" ]]; then
		exit 2
	fi

	# Generate the keys
	ssh-keygen -t ed25519 -f "${_remote_machine}"

	# Append the public key to the remote machine
	printf "Enter your username on "${_remote_machine}" (blank quits): "
	read _user_name
	if [[ -z "${_user_name}" ]]; then
		exit 2
	fi
	cat ~/.ssh/"${_remote_machine}".pub | ssh "${_user_name}"@"${_remote_machine}" 'cat >> ~/.ssh/authorized_keys2'

	# Add the key to ssh-agent
	eval $(keychain --eval "${_remote_machine}")

} #end __main_script__
#</main>

#-----------------------------------
# Local functions

#<functions>
function __local_cleanup__ {
	:
}
#</functions>

#-----------------------------------
# Source helper functions
for _helper_file in functions colors git-prompt; do
	if [[ ! -e ${HOME}/."${_helper_file}".sh ]]; then
		printf "%b\n" "Downloading missing script file "${_helper_file}".sh..."
		sleep 1
		wget -nv -P ${HOME} https://raw.githubusercontent.com/tristanchase/dotfiles/master/"${_helper_file}".sh
		mv ${HOME}/"${_helper_file}".sh ${HOME}/."${_helper_file}".sh
	fi
done

source ${HOME}/.functions.sh

#-----------------------------------
# Get some basic options
# TODO Make this more robust
#<options>
if [[ "${1:-}" =~ (-d|--debug) ]]; then
	__debugger__
elif [[ "${1:-}" =~ (-h|--help) ]]; then
	__usage__
fi
#</options>

#-----------------------------------
# Bash settings
# Same as set -euE -o pipefail
#<settings>
set -o errexit
set -o nounset
set -o errtrace
set -o pipefail
IFS=$'\n\t'
#</settings>

#-----------------------------------
# Main Script Wrapper
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
	trap __traperr__ ERR
	trap __ctrl_c__ INT
	trap __cleanup__ EXIT

	__main_script__


fi

exit 0
