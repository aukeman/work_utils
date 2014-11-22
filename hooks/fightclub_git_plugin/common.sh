#!/bin/bash

# PIVOTAL_PROJECT_ID="985502"
# PIVOTAL_TOKEN="5d089c9f3dc01c734dece727cc65e513";


if [[ -z ${PIVOTAL_PROJECT_ID} ]]; then
	echo "\$PIVOTAL_PROJECT_ID is not defined" >&2
	exit 1
elif [[ -z ${PIVOTAL_TOKEN} ]]; then
	echo "\$PIVOTAL_TOKEN is not defined" >&2
	exit 1
fi

OPTIONAL_NUMBER_MARKER_SED_REGEX='[\[{(]\{0,1\}#\{0,1\}'
OPTIONAL_NUMBER_MARKER_EGREP_REGEX='[\[\{(]{0,1}#{0,1}'

PIVOTAL_CARD_NUMBER_SED_REGEX='[0-9]\{8,\}'
PIVOTAL_CARD_NUMBER_EGREP_REGEX='[0-9]{8,}'

function get_branch_name()
{
	git symbolic-ref HEAD | awk -F/ '{print $NF}'
}

function is_pivotal_card_number_in_string()
{
	echo "${1}" | egrep -q "${OPTIONAL_NUMBER_MARKER_EGREP_REGEX}${PIVOTAL_CARD_NUMBER_EGREP_REGEX}"
}

function does_pivotal_card_number_begin_string()
{
	echo ">>> $1 <<<"

	echo "${1}" | egrep -q "^${OPTIONAL_NUMBER_MARKER_EGREP_REGEX}${PIVOTAL_CARD_NUMBER_EGREP_REGEX}"
}

function get_pivotal_card_number_from_string()
{
	if is_pivotal_card_number_in_string "${1}"; then
		echo "${1}" | sed -e "s/.*\(${PIVOTAL_CARD_NUMBER_SED_REGEX}\).*/\1/"
	else
		echo
	fi
}

function get_pivotal_card_number_from_commit_message_file()
{
	get_pivotal_card_number_begin_string "$(head -1 \"${1}\" 2>/dev/null)"
}

function does_pivotal_card_number_begin_commit_message_file()
{
	echo "))) $(head -1 ${1} 2>/dev/null) ((("

	does_pivotal_card_number_begin_string "$(head -1 \"${1}\" 2>/dev/null)"
}

function is_pivotal_card_number_in_branch()
{
	is_pivotal_card_number_in_string "$(get_branch_name)"
}

function get_pivotal_card_number_from_branch()
{
	get_pivotal_card_number_from_string "$(get_branch_name)"
}

function confirm_pivotal_card_number_exists()
{
	http_response=$(curl -s -I -H "X-TrackerToken: ${PIVOTAL_TOKEN}" "https://www.pivotaltracker.com/services/v5/projects/${PIVOTAL_PROJECT_ID}/stories/${1}" 2>&1)

	if [[ "$?" != "0" ]]; then
		echo "could not connect to pivotal API" >&2
		false

	elif $(echo "${http_response}" | head -1 | grep -iq "200 OK"); then
		true
	
	elif $(echo "${http_response}" | head -1 | grep -iq "404 Not Found"); then	
		echo "pivotal card #${pivotal_card_number} not found!" >&2
		false
	
	else
		echo -e "Unexpected response from pivotal:\n${http_response}" >&2
		false
	fi
}



