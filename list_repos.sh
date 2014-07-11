#!/bin/bash

list=false
terminal=false
status=false
diff=false
branch=
remote=origin/master




spinner=( '|' '/' '-' '\' ) 

while getopts "hdsub:r:" opt; do
  case ${opt} in
    d) diff=true;;
    s) status=true;;
    b) branch=${OPTARG};;
    r) remote=${OPTARG};;
    u) remote='@{u}';;
    h) echo "TODO"; exit 0;;
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
  echo "Listing repos containing a branch matching \"${branch}\""
  echo
fi

for repo in $(find ${GIT_REPO_ROOT:-~/git/} -name .git -a -type d -mindepth 2 -maxdepth 2); do
     
  dir=$(dirname ${repo})

  pushd ${dir} >/dev/null

  if ( ${list} ) ||
     ( [[ -n ${branch} ]] && git branch --list | grep --quiet ${branch} ) ||
     ( [[ -z ${branch} ]] && git branch --list --remote | grep --quiet ${remote} && ! git diff --quiet ${remote}.. ); then

    echo -en ${cr}
    echo $(basename ${dir}) \($(git branch | grep "^\*" | cut -c3-)\)

    if [[ -n ${branch} ]] && 
       (( 1 < $(git branch --list | grep ${branch} | wc -l) )); then
      git branch --list | grep ${branch}
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
