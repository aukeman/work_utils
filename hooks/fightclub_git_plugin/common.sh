#!/bin/bash

# PIVOTAL_PROJECT_ID="985502"
# PIVOTAL_TOKEN="5d089c9f3dc01c734dece727cc65e513";

if [[ -z ${PIVOTAL_PROJECT_ID} ]]; then
	echo "\$PIVOTAL_PROJECT_ID environment variable is not defined" >&2
	exit 1
elif [[ -z ${PIVOTAL_TOKEN} ]]; then
	echo "\$PIVOTAL_TOKEN environment variable is not defined" >&2
	exit 1
fi

OPTIONAL_NUMBER_MARKER_REGEX='\[?#?'
PIVOTAL_CARD_NUMBER_REGEX='\d{8,}'

function generate_error_message
{
	echo
	echo "Failed to ${1}."
	echo "If you need to bypass the Fight Club git hooks, run this command again and pass the --no-verify option."
}

function get_branch_name()
{
	git symbolic-ref HEAD | awk -F/ '{print $NF}'
}

function is_pivotal_card_number_in_string()
{
	ruby -e 'if not ARGV[0] =~ /#{ARGV[1]}/; then exit 1; end' -- "${1}" "${PIVOTAL_CARD_NUMBER_REGEX}"
}

function does_pivotal_card_number_begin_string()
{
	ruby -e 'if not ARGV[0] =~ /^#{ARGV[1]}/; then exit 1; end' -- "${1}" "${OPTIONAL_NUMBER_MARKER_REGEX}${PIVOTAL_CARD_NUMBER_REGEX}"
}

function get_pivotal_card_number_from_string()
{
	ruby -e 'ARGV[0] =~ /(#{ARGV[1]})/; print $1' -- "${1}" "${PIVOTAL_CARD_NUMBER_REGEX}"
}

function get_pivotal_card_number_from_commit_message_file()
{
	get_pivotal_card_number_from_string "$(head -1 ${1} 2>/dev/null)"
}

function does_pivotal_card_number_begin_commit_message_file()
{
	does_pivotal_card_number_begin_string "$(head -1 ${1} 2>/dev/null)"
}

function is_pivotal_card_number_in_branch()
{
	is_pivotal_card_number_in_string "$(get_branch_name)"
}

function get_pivotal_card_number_from_branch()
{
	get_pivotal_card_number_from_string "$(get_branch_name)"
}

function confirm_pivotal_card_exists()
{
	http_response=$(curl -s -I -H "X-TrackerToken: ${PIVOTAL_TOKEN}" "https://www.pivotaltracker.com/services/v5/projects/${PIVOTAL_PROJECT_ID}/stories/${1}" 2>&1)

	if [[ "$?" != "0" ]]; then
		echo "could not connect to pivotal API" >&2
		false

	elif $(echo "${http_response}" | head -1 | grep -iq "200 OK"); then
		true
	
	elif $(echo "${http_response}" | head -1 | grep -iq "404 Not Found"); then	
		echo "pivotal card #${1} not found!" >&2
		false
	
	else
		echo -e "Unexpected response from pivotal:\n${http_response}" >&2
		false
	fi
}



