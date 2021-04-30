#!/usr/bin/env bash

#-----------------------------------
# Usage Section

#<usage>
#//Usage: gen-keys [ {-d|--debug} ] [ {-h|--help} {-t|--type} ]
#//Description: Generates SSH keys for pairing local and remote hosts
#//Examples: gen-keys; gen-keys --debug; gen-keys -t
#//Options:
#//	-d --debug	Enable debug mode
#//	-h --help	Display this help message
#//	-t --type	Choose type of key to create
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
_default_keytype="ed25519" # (rsa|dsa|ecdsa|ed25519)
_keytype="${_default_keytype}"
_keylength="" # Will equal "-b "${_bit_length}"" if set
_keycomment="" # Will equal "-C "${_comment}" if set

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

	# Get user comment (email address, maybe)
	printf "Enter an optional comment, such as your email address (blank for default): "
	read _comment
	if [[ -n "${_comment}" ]]; then
		_keycomment="-C "${_comment}""
	fi

	# Offer different key types and bit lengths (optional)
	if [[ "${_type_yN:-}" = "y" ]]; then
		__key_options__
	fi

	# Generate the keys
	ssh-keygen ${_keylength:-} -t "${_keytype}" -f "${_keyname}" ${_keycomment:-}

	# Create a known_hosts file for each key
	touch known_hosts_"${_remote_host}"

	# Create/update config file
	touch config

	# Get Label for config file section
	_label=${_remote_host%.*} # Strips off .suffix, if there is one
	_label=${_label^} # Changes first character to uppercase

	cat >> config << EOF
# ${_label}
Host ${_remote_host}
 Hostname ${_remote_host}
 User ${_user_name}
 AddKeysToAgent yes
# UseKeychain yes #(Mac OS only)
 IdentityFile ~/.ssh/${_keyname}
 UserKnownHostsFile ~/.ssh/known_hosts_${_remote_host}
 IdentitiesOnly yes
# End ${_label}

EOF

	# Update ~/.ssh/.keyfile
	printf "%b\n" ~/.ssh/* | grep -Ev 'pub|config|known_hosts' | xargs basename -a > ~/.ssh/.keyfile

	# Add the key to ssh-agent
	eval $(keychain --eval "${_keyname}")

	# TODO Make this an option for retrieving later
	# Append the public key to the remote host
	printf "%b\n" "Copy/paste the key below to "${_remote_host}":"
	printf "%b\n" ""
	cat ~/.ssh/"${_keyname}".pub
	printf "%b\n" ""
	printf "%b\n" "Or use the command below if you can access a shell on "${_remote_host}":"
	printf "%b\n" ""
	printf "%b\n" "cat ~/.ssh/"${_keyname}".pub | ssh "${_user_name}"@"${_remote_host}" 'cat >> ~/.ssh/authorized_keys2'"

	# TODO Make option to delete everything related to _keyname

} #end __main_script__
#</main>

#-----------------------------------
# Local functions

#<functions>
function __bit_length__ {
	# Set $_keylength to bit length, if desired
	_rsa_opts=(1024 2048 4096)
	_ecdsa_opts=(256 384 521)
	if [[ "${_keytype}" =~ (rsa|ecdsa) ]]; then
		printf "Set bit length? (y/N): "
		read _response
		if [[ "${_response}" =~ (y|Y) ]]; then
			if [[ "${_keytype}" = "rsa" ]]; then
				_chooser_array=("${_rsa_opts[@]}")
			else
				_chooser_array=("${_ecdsa_opts[@]}")
			fi
		fi
		_chooser_message="Choose bit length (blank sets default): "
		__chooser__
		_keylength="-b $(printf "%b\n" "${_chooser_array[@]:$_chooser_number-1:1}")"
	fi
}

function __chooser__ {
	# Set $_chooser_array and $_chooser_message before calling this function
	_chooser_count="${#_chooser_array[@]}"
	_chooser_array_keys=(${!_chooser_array[@]})
	function __chooser_list_ {
		printf "%q %q\n" $((_key + 1)) "${_chooser_array[$_key]}"
	}

	if [[ "${_chooser_count}" -gt 1 ]]; then
		for _key in "${_chooser_array_keys[@]}"; do
			__chooser_list_
		done | more
		printf "%b\n" "${_chooser_message}"
		printf "(enter number 1-"${_chooser_count}"): "
		read _chooser_number
		case "${_chooser_number}" in
			''|*[!0-9]*) # not a number
				return
				;;
			*) # not in range
				if [[ "${_chooser_number}" -lt 1 ]] || [[ "${_chooser_number}" -gt "${_chooser_count}" ]]; then
					return
				fi
				;;
		esac
	else
		_chooser_number="0"
	fi
} # end __chooser__

function __key_options__ {
	# Set $_keytype to key type chosen from a numbered list
	_chooser_array=(rsa dsa ecdsa ed25519)
	_chooser_message="Choose key type (default is "${_default_keytype}")"
	__chooser__
	_keytype="$(printf "%b\n" "${_chooser_array[@]:$_chooser_number-1:1}")"

	# Set bit length
	__bit_length__
}

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
elif [[ "${1:-}" =~ (-t|--type) ]]; then
	_type_yN="y"
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
