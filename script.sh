#!/bin/bash

# checking the difference in branches (currently just master)
git fetch
difff=$(git diff @{upstream})
len=${#difff}

if (( $len >= 0 )) ; then
	# making a docker image
	docker build -t devops-app . --label "maintainer=$(git log -1 --pretty=format:'%an')" \
		--label "branch=$(git branch | grep \* | cut -d ' ' -f2)" \
		--label "commit=$(git log -1 --pretty=format:'%H')"
	# stop running container
	docker stop dapp-container && docker rm dapp-container
	# run new one
	docker run -d --name dapp-container -p 80:8080/tcp devops-app
fi