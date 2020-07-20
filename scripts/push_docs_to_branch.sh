#!/bin/bash

set -Eeuo pipefail

TODAY=`date "+%Y%m%d"`
# we build new versions only for majors
PATTERN_FOR_NEW_VERSION="^refs/tags/[0-9]+\\.0\\.0$"
MASTER_REF=refs/heads/master

[[ ! $GITHUB_REF =~ $PATTERN_FOR_NEW_VERSION ]] \
&& [[ $GITHUB_REF != $MASTER_REF ]] \
&& echo "Not on master or major version, skipping." \
&& exit 0

NEW_VERSION=
if [ "$GITHUB_REF" != $MASTER_REF ]
then
    NEW_VERSION=${GITHUB_REF/refs\/tags\//}
fi

# clone the $DOCS_BRANCH in a temp directory
git clone --depth=1 --branch=$DOCS_BRANCH git@github.com:$GITHUB_REPOSITORY.git $TMP_DOCS_FOLDER

echo "Updating the docs..."
# FIXME: remove the next 2 lines when we do the move
mv docs olddocs
mv newdocs docs
cp -R `ls -A | grep -v "^\.git$"` $TMP_DOCS_FOLDER/
# FIXME: remove the next 3 lines when we do the move
rm -rf $TMP_DOCS_FOLDER/olddocs
mv docs newdocs
mv olddocs docs


cd $TMP_DOCS_FOLDER

if [ ! -z "$NEW_VERSION" ]
then
    echo "Generating docs for new version $NEW_VERSION..."
    cd docs
    yarn run new-version $NEW_VERSION
    cd ..
fi

if [ -z "$(git status --porcelain)" ]
then
    echo "Nothing changed in docs, done 👍"
else
    echo "Pushing changes to git..."
    git add .
    git commit -am "AUTO docusaurus $TODAY"
    git fetch --unshallow
    git push origin $DOCS_BRANCH

    echo "Done 👌"
fi
