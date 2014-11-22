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

function get_git_user_name
{
	git config user.name
}

function get_repo_name()
{
	basename $(git rev-parse --show-toplevel)
}

function get_branch_name()
{
	git symbolic-ref HEAD | awk -F/ '{print $NF}'
}

function get_commit_hash()
{
	git log -1 --format="%H"
}

function get_commit_short_hash()
{
	git log -1 --format="%h"
}

function get_commit_title()
{
	git log -1 --format="%s" HEAD
}

function get_changed_files()
{
	git diff --name-status HEAD~1
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

function get_pivotal_card_number_from_log()
{
	git log -10 --format="%s" | 
	(while read title; do
		if does_pivotal_card_number_begin_string "${title}"; then
			get_pivotal_card_number_from_string "${title}"
			break
		fi
	done)
}

function build_source_commit_json
{
	ruby -e 'require "json"; puts Hash[[ ["source_commit", Hash[[ ["commit_id", ARGV[0]], ["message", ARGV[1]], ["author", ARGV[2]] ]] ] ]].to_json' -- "${1}" "${2}" "${3}"
}

function build_story_comment_json
{
	ruby -e 'require "json"; puts Hash[[ ["text", ARGV[0]] ]].to_json' -- "${1}"
}

function confirm_pivotal_card_exists()
{
	http_code=$(curl -s -I -H "X-TrackerToken: ${PIVOTAL_TOKEN}" -o dev/null -w "%{http_code}" "https://www.pivotaltracker.com/services/v5/projects/${PIVOTAL_PROJECT_ID}/stories/${1}" 2>&1)

	result=false
	
	if [[ "$?" != "0" ]]; then
		echo "could not connect to pivotal API" >&2
	else
		case "${http_code}" in
			"200") result=true;;
			"404") echo "pivotal card #${1} not found!" >&2;;
			*)     echo "Unexpected http code from Pivotal: ${http_code}" >&2;;
		esac
	fi

	${result}
}

function update_pivotal_card_with_commit
{
	commit_hash=$(get_commit_hash)
	user_name=$(get_git_user_name)
	message="$(get_commit_title)

**Repo:** $(get_repo_name)
**Branch:** $(get_branch_name)
**Hash:** $(get_commit_short_hash)

$(get_changed_files | sed -e 's/^\([A-Z]\)\(.*\)/**\1**\2/')"

	source_commit_json=$(build_source_commit_json "${hash}" "${message}" "${user_name}")
	
	http_code=$(curl -s -X POST -H "X-TrackerToken: $PIVOTAL_TOKEN" -H "Content-Type: application/json" -d "${source_commit_json}" -o /dev/null -w "%{http_code}" "https://www.pivotaltracker.com/services/v5/source_commits")
	
	if [[ "${http_code}" != "200" ]]; then
		echo "Could not update Pivotal Card" >&2
	fi
}

function update_pivotal_card_with_push
{
	message="Push to ${2}
	
**Repo:** $(get_repo_name)
**Branch:** $(get_branch_name)
**Hash:** $(get_commit_short_hash)"

	comment_json=$(build_story_comment_json "${message}")
	
	http_code=$(curl -s -X POST -H "X-TrackerToken: $PIVOTAL_TOKEN" -H "Content-Type: application/json" -d "${comment_json}" -o /dev/null -w "%{http_code}" "https://www.pivotaltracker.com/services/v5/projects/${PIVOTAL_PROJECT_ID}/stories/${1}/comments")
	
	if [[ "${http_code}" != "200" ]]; then
		echo "Could not update Pivotal Card" >&2
	fi
}

function update_pivotal_card_with_merge
{
	echo "pivotal card number: ${1}"

	message="Merge
	
**Repo:** $(get_repo_name)
**Branch:** $(get_branch_name)
**Hash:** $(get_commit_short_hash)"

	comment_json=$(build_story_comment_json "${message}")

	http_code=$(curl -s -X POST -H "X-TrackerToken: $PIVOTAL_TOKEN" -H "Content-Type: application/json" -d "${comment_json}" -o /dev/null -w "%{http_code}" "https://www.pivotaltracker.com/services/v5/projects/${PIVOTAL_PROJECT_ID}/stories/${1}/comments")
	
	if [[ "${http_code}" != "200" ]]; then
		echo "Could not update Pivotal Card" >&2
	fi
	
}

