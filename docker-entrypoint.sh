#!/bin/bash

now=`date +"%s"`

function get_decidim_version() {
  bundle show decidim | awk -F'-' '{print $NF}'
}

# Environment checks
[ -z "$GITHUB_ORGANIZATION" ] && echo "You must provide a GITHUB_ORGANIZATION environment variable" && exit 1;
[ -z "$GITHUB_REPO" ] && echo "You must provide a GITHUB_REPO environment variable" && exit 1;
[ -z "$GITHUB_OAUTH_TOKEN" ] && echo "You must provide a GITHUB_OAUTH_TOKEN environment variable" && exit 1;
[ -z "$DECIDIM_GITHUB_ORGANIZATION" ] && echo "You must provide a DECIDIM_GITHUB_ORGANIZATION environment variable" && exit 1;
[ -z "$DECIDIM_GITHUB_REPO" ] && echo "You must provide a DECIDIM_GITHUB_REPO environment variable" && exit 1;

# Git configuration
git config --global user.name $GIT_USERNAME
git config --global user.email $GIT_EMAIL

echo "1. Clone repository"
git clone https://$GITHUB_OAUTH_TOKEN@github.com/$GITHUB_ORGANIZATION/$GITHUB_REPO.git && cd $GITHUB_REPO
git remote add decidim https://github.com/$DECIDIM_GITHUB_ORGANIZATION/$DECIDIM_GITHUB_REPO.git && git fetch decidim
git reset --hard decidim/master

echo "2. Install gems"
bundle install

echo "3. Create db and load schema"
bundle exec rake db:create db:schema:load

echo "4. Update decidim"
old_decidim_version=$(get_decidim_version)
bundle update decidim decidim-dev
decidim_version=$(get_decidim_version)

echo "5. Run decidim:upgrade and migrate db"
bundle exec rake decidim:upgrade db:migrate

echo "6. Create/Update PR to update decidim"
branch_name="update-decidim-$decidim_version"
git checkout -b $branch_name
git add . && git commit -am "Update decidim to v$decidim_version" && git push origin $branch_name
curl \
  -i \
  -X POST \
  -d "{
    \"title\": \"Update Decidim to v$decidim_version\",
    \"base\":\"master\",
    \"head\":\"$GITHUB_ORGANIZATION:$branch_name\",
    \"body\":\"Update decidim from v$old_decidim_version to v$decidim_version. You can check the release notes [here](https://github.com/decidim/decidim/releases/tag/v$decidim_version).\",
    \"maintainer_can_modify\":true
  }" \
  https://api.github.com/repos/$DECIDIM_GITHUB_ORGANIZATION/$DECIDIM_GITHUB_REPO/pulls?access_token=$GITHUB_OAUTH_TOKEN