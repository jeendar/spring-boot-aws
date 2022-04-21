#!/bin/bash
# Define tag name
export TZ='GST-2'
datetime=$(date +"%Y%m%d-%H%M%S")
tag=$BRANCH-$datetime

# Define remote git url with access token
replacementString=$GITHUB_ACCESS_TOKEN@github.stratocrest.com
giturl=$(git config --get remote.origin.url)
giturlwithtoken=${giturl/github.stratocrest.com/$replacementString}
git remote add stratocrest $giturlwithtoken

# Calculate change log
lastTag=$(git tag | grep $BRANCH | tail -1)
changeLog=$(git log $BRANCH...$lastTag --oneline)

# Create the tag with the changelog and push to the remote
git tag -a $tag -m "Version deployed from $BRANCH at $datetime" -m "ChangeLog" -m "$changeLog"
git push stratocrest $tag
