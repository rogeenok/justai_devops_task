#!/bin/bash


# update remote branches refs
git remote update

# get the list with all remotes branches
allremotes=$(git branch -r | grep -v 'HEAD' | grep -w 'origin' | cut -d '/' -f 2)

# check each branch in a cycle
for current in $allremotes
do

	# flag to making docker images update
	flag=0

	echo "current remote branch is : $current"

	# get a list with local branches and check if current remote branch exists among locals
	localbranches=( $(git for-each-ref --format '%(refname:short)' refs/heads/) )
	tag=$(docker images | grep devops-app | tr -s ' ' | cut -d ' ' -f 2 | grep $current)
	if ! [[ " ${localbranches[@]} " =~ " ${current} " ]]; then
		# checkout if not
		git checkout --track origin/$current
		flag=2
		echo "the remote branch $current is new --> checkout"
	else
		git checkout -q $current
		#check updates if yes
		status=$(git status | grep -E "behind" | cut -d ' ' -f 4)
		len=${#status}

		if (( $len > 0 )) ; then
			# pull changes if the local branch is behind
			git pull
			flag=1
			echo "updating existing branch $current"
		else
			echo "branch $current is up-to-date or ahead"
			# check if we have any docker image for unchanched branch
			if (( ${#tag} == 0 )) ; then
				flag=2
			fi
		fi
	fi
	
	if [ "$flag" -gt "0" ]; then
	
		#check the existence of image tagged with current branch
		#tag=$(docker images | grep devops-app | tr -s ' ' | cut -d ' ' -f 2 | grep $current)
		
		oldtag=$tag
		o_version="0.1"
		n_version=$o_version
		
		# update tag version if the prior exists
		if (( ${#tag} != 0 )) ; then
			o_version=$(echo $tag | cut -d 'v' -f 2)
			# update the version for tag calling simple python script
			n_version=$(python vupd.py $o_version)
			tag=$(echo $current | cut -d '=' -f 2)-v$n_version
		else
			# create a new tag (v0.1)
			tag=$(echo $current | cut -d '=' -f 2)-v$n_version
		fi
		
		# save metadata	
		maintainer="maintainer=$(git log -1 --pretty=format:'%an')"
		branch="branch=$current"
		commit="commit=$(git log -1 --pretty=format:'%H')"
		
		# build a docker image
		docker build -t devops-app:$tag . --label "$maintainer" \
			--label "$branch" \
			--label "$commit"
			
		if ! [[ "$flag" -eq "2" ]]; then
		# stop running container
		docker stop dappc-$oldtag && docker rm dappc-$oldtag
		# also remove previous image on update & make new one
		docker rmi devops-app:$oldtag
		fi
		
		# run new one on a random port 			
		docker run -d --name dappc-$tag -p :8080/tcp devops-app:$tag
	fi
	
done