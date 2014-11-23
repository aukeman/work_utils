#!/bin/bash

projects_dir=$1
pivotal_token=$2

if [[ -z ${projects_dir} || -z ${pivotal_token} ]]; then
	echo "Usage: $(basename "$0") <git projects dir> <pivotal token>" >&2
	exit 1
fi
	
if which setx >/dev/null; then
	setx FIGHTCLUB_GIT_PLUGIN_HOME "${PWD}"
	setx PIVOTAL_PROJECT_ID "985502"
	setx PIVOTAL_TOKEN "${2}"
else
	echo "Set the following environment variables:"
	echo "  FIGHTCLUB_GIT_PLUGIN_HOME = ${PWD}"
	echo "  PIVOTAL_PROJECT_ID        = 985502"
	echo "  PIVOTAL_TOKEN             = ${2}"
fi

find "${projects_dir}" -name ".git" -type d -maxdepth 2 | while read dir; do
	cp ./prepare-commit-msg ./commit-msg ./post-commit ./post-merge ./pre-push "${dir}/hooks"
done