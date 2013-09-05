#!/bin/bash
# The script clones all repositories of an GitHub user.
# Author: Handrus Stephan Nogueira
# Date: 08-05-2013
 
# the github personal token so you can retrieve your repositories 
GITHUB_PERSONAL_TOKEN="YOUR TOKEN HERE"
 
# the git clone cmd used for cloning each repository
# the parameter recursive is used to clone submodules, too.
GIT_CLONE_CMD="git clone --quiet --recursive "
# For backup use the CMD bellow
#GIT_CLONE_CMD="git clone --quiet --recursive --mirror "
 
# fetch repository list via github api
REPOS=`curl -H "Authorization: token ${GITHUB_PERSONAL_TOKEN}" https://api.github.com/user/repos -q`

# Repo ssh_url
REPOLIST=`echo ${REPOS} | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep '"ssh_url":' | sed 's/:/ /1' | awk -F" " '{ print $2 }' | uniq | sed -e 's/^"//'  -e 's/"$//'`

#Repository Full-name Eg.: user/repo
REPOSFNAME=`echo ${REPOS} | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep '"full_name":' | sed 's/:/ /1' | awk -F" " '{ print $2 }'| uniq | sed -e 's/^"//'  -e 's/"$//'` 

#Repo name
REPOSNAME=`echo ${REPOS} | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep '"name":' | sed 's/:/ /1' | awk -F" " '{ print $2 }'| uniq | sed -e 's/^"//'  -e 's/"$//'` 

#transform delimited string into array
REPOSFNAMEA=($REPOSFNAME)
REPOLISTA=($REPOLIST)
REPOSNAMEA=($REPOSNAME)

for (( i=0;i<${#REPOSNAMEA[*]};i++));
do
  if [ -d "${REPOSNAMEA[${i}]}" ]; then
    echo "A folder ${REPOSNAMEA[${i}]} already exists"
  else
     echo "== Cloning ${REPOLISTA[${i}]} to ${REPOSNAMEA[${i}]} =="
     ${GIT_CLONE_CMD}${REPOLISTA[${i}]} ./${REPOSNAMEA[${i}]}
  fi
  if [ ! -d "${REPOSNAMEA[${i}]}/.git" ]; then
    echo "Folder ${REPOSNAMEA[${i}]} is a not a git repository"
  else
    #fetch repository fork data
    cd ${REPOSNAMEA[${i}]}
    # Get the current repo URL
    url=$(git config --get remote.origin.url)

    part=${url#*github.com*/}

    # ZOMG parse JSON using the github api get the parent git_url.
    # would suggest to use curl -s .. | jq -r '.parent.git_url'  
    upstream=$(curl -s https://api.github.com/repos/${REPOSFNAMEA[${i}]} | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep '"git_url":' | sed 's/:/ /1' | awk -F" " '{ print $2 }' | uniq | tail -1 | sed -e 's/^"//'  -e 's/"$//')

    echo "== Adding upstream ${upstream} to ${REPOSNAMEA[${i}]}  =="
    git remote add upstream ${upstream}
    git fetch upstream --quiet
    cd ..

  fi 
done 
