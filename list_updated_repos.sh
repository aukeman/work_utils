#!/bin/bash

terminal=false
full=false
branch=

spinner=( '|' '/' '-' '\' ) 

while getopts "hfb:" opt; do
  case ${opt} in
    f) full=true;;
    b) branch=${OPTARG};;
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

    if ! git diff --quiet master; then

      echo -en ${cr}
      echo $(basename ${dir})

      if ${full}; then
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

echo -en "\r "
