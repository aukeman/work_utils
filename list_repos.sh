#!/bin/bash

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

if [[ -t 1 ]]; then
  terminal=true
  cr="\r"
fi  
 
for dir in $(find ~/git -type d -mindepth 1 -maxdepth 1); do
     
  if [[ -e "${dir}/.git" ]]; then


    pushd ${dir} >/dev/null

    if ( ! ${diff} && [[ -z ${branch} ]] ) ||
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
  fi
done

${terminal} && echo -en "${cr} "
