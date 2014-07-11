#!/bin/bash

list=false
terminal=false
status=false
diff=false
branch=
remote=origin/master

spinner=( '|' '/' '-' '\' ) 

USAGE="Perform various queries of git repositories under \$GIT_REPO_ROOT.

Usage:
  $(basename ${0}) [-s] [-d | -u | -r <remote branch>] ] [-b <branch name pattern>] | -h

  -s: show status (git status -sb) for the repositories returned by the query

  -d: show repositories with diffs between the current working branch and origin/master
  -u: show repositories with diffs between the current working branch and the branch's upstream remote
  -r: show repositories with diffs between the current working branch and the given remote branch

  -b: show repositories with local or remote branches matching the given pattern
"

while getopts "hdsub:r:" opt; do
  case ${opt} in
    d) diff=true;;
    s) status=true;;
    b) branch=${OPTARG};;
    r) remote=${OPTARG}; diff=true;;
    u) remote='@{u}'; diff=true;;
    h) echo "$USAGE"; exit 0;;
    *) echo "$USAGE" >&2; exit 1;;
  esac
done

# if not looking for a diff or branch, then we're listing repos
if ! ${diff} && [[ -z ${branch} ]]; then
  list=true
fi

# suppress printing the spinner if not outputting to the terminal
if [[ -t 1 ]]; then
  terminal=true
  cr="\r"
fi  

if ${diff}; then
  echo "Listing repos with diffs between working tree and ${remote/@\{u\}/upstream remote}"
  echo
elif [[ -n ${branch} ]]; then
  echo "Listing repos containing a local or remote branch matching \"${branch}\""
  echo
fi

for repo in $(find ${GIT_REPO_ROOT:-~/git/} -name .git -a -type d -mindepth 2 -maxdepth 2); do
     
  dir=$(dirname ${repo})

  pushd ${dir} >/dev/null

  if ( ${list} ) ||
     ( [[ -n ${branch} ]] && git branch --list --all | grep --quiet ${branch} ) ||
     ( [[ -z ${branch} ]] && git branch --list --remote | grep --quiet ${remote} && ! git diff --quiet ${remote}.. ); then

    echo -en ${cr}
    echo $(basename ${dir}) \($(git branch | grep "^\*" | cut -c3-)\)

    if [[ -n ${branch} ]] && 
       (( 1 < $(git branch --list --all | grep ${branch} | wc -l) )); then
      git branch --list | grep ${branch} | tr "*" " "
      echo
    fi 

    if ${status}; then
      git status -sb
      echo 
    fi
    
  fi
  
  if ${terminal}; then
    echo -en "${cr}${spinner[0]}"
    spinner=("${spinner[@]:1}" "${spinner[0]}")
  fi

  popd >/dev/null

done

${terminal} && echo -en "${cr} "
