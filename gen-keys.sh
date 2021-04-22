#!/usr/bin/env bash

#-----------------------------------
# Usage Section

#<usage>
#//Usage: gen-keys [ {-d|--debug} ] [ {-h|--help} ]
#//Description: Generates SSH keys for pairing local and remote hosts
#//Examples: gen-keys; gen-keys --debug
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
#  keychain
#</depends>

#-----------------------------------
# TODO Section

#<todo>
# TODO

# DONE

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

	# Get the name of the remote host
	printf "Enter the name of the remote host (blank quits): "
	read _remote_host
	if [[ -z "${_remote_host}" ]]; then
		exit 2
	else
		_keyname="${_remote_host}"_key
	fi

	# Get user name
	printf "Enter username on "${_remote_host}" (enter \"git\" on github or gitlab): "
	read _user_name

	# Generate the keys
	ssh-keygen -t ed25519 -f "${_keyname}"

	# Create a known_hosts file for each key
	touch known_hosts_"${_remote_host}"

	# Create/update config file
	touch config

	# Get Label
	printf "Enter a Label for this config entry (Host without .com): "
	read _label

	cat >> config << EOF
# ${_label}
Host ${_remote_host}
 Hostname ${_remote_host}
 User ${_user_name}
 AddKeysToAgent yes
 UseKeychain yes
 IdentityFile ~/.ssh/${_keyname}
 UserKnownHostsFile ~/.ssh/known_hosts_${_remote_host}
 IdentitiesOnly yes

EOF

	# TODO This section will be fixed in Task: Handle public key transfer #6
	# Append the public key to the remote host
	#if [[ -z "${_user_name}" ]]; then
		#exit 2
	#fi
	#cat ~/.ssh/"${_keyname}".pub | ssh "${_user_name}"@"${_remote_host}" 'cat >> ~/.ssh/authorized_keys2'

	# Add the key to ssh-agent
	eval $(keychain --eval "${_keyname}")

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
