#!/bin/bash


# update remote branches refs
git remote update

current=$(git branch | grep \* | cut -d ' ' -f2)
echo "current branch is : $current"

status=$(git status | grep -E "behind" | cut -d ' ' -f 4)
len=${#status}

# echo $status $len

if (( $len == 0 )) ; then
	# pull changes
	git pull
	
	#check the existence of image tagged with current branch
	tag=$(docker images | grep devops-app | tr -s ' ' | cut -d ' ' -f 2 | grep $current)
	echo $tag
	
	oldtag=$tag
	o_version="0.1"
	n_version=$o_version
	
	# update tag version if the prior exists
	if (( ${#tag} != 0 )) ; then
		o_version=$(echo $tag | cut -d 'v' -f 2)
		echo $o_version
		# update the version for tag
	else
		# create a new tag (v0.1)
		tag="$(echo $current | cut -d '=' -f 2)-v$n_version"
		echo "new tag $tag is set for branch $current"
	fi
	
	# save metadata	
	maintainer="maintainer=$(git log -1 --pretty=format:'%an')"
	branch="branch=$current"
	commit="commit=$(git log -1 --pretty=format:'%H')"
	
	# build a docker image
	docker build -t devops-app:$tag . --label "$maintainer" \
		--label "$branch" \
		--label "$commit"
	# stop running container
	docker stop dappc-$oldtag && docker rm dappc-$oldtag
	# run new one
	docker run -d --name dappc-$tag -p 80:8080/tcp devops-app:$tag
fi