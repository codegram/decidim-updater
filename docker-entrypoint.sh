#!/bin/bash

now=`date +"%s"`

function get_revision() {
  bundle show decidim | awk -F'-' '{print $NF}'
}

# Environment checks
[ -z "$GITHUB_ORGANIZATION" ] && echo "You must provide a GITHUB_ORGANIZATION environment variable" && exit 1;
[ -z "$GITHUB_REPO" ] && echo "You must provide a GITHUB_REPO environment variable" && exit 1;
[ -z "$GITHUB_OAUTH_TOKEN" ] && echo "You must provide a GITHUB_OAUTH_TOKEN environment variable" && exit 1;
[ -z "$DECIDIM_GITHUB_ORGANIZATION" ] && echo "You must provide a DECIDIM_GITHUB_ORGANIZATION environment variable" && exit 1;
[ -z "$DECIDIM_GITHUB_REPO" ] && echo "You must provide a DECIDIM_GITHUB_REPO environment variable" && exit 1;

echo "1. Clone repository"
git clone https://$GITHUB_OAUTH_TOKEN@github.com/$GITHUB_ORGANIZATION/$GITHUB_REPO.git && cd $GITHUB_REPO
git remote add decidim https://github.com/$DECIDIM_GITHUB_ORGANIZATION/$DECIDIM_GITHUB_REPO.git && git fetch decidim
git reset --hard decidim/master

echo "2. Install gems"
bundle install

echo "3. Create db and load schema"
bundle exec rake db:create db:schema:load

echo "4. Update decidim"
old_revision=$(get_revision)
bundle update decidim decidim-dev
new_revision=$(get_revision)

echo "5. Run decidim:upgrade and migrate db"
bundle exec rake decidim:upgrade db:migrate

echo "6. Create git branch and PR for upgrade decidim"
git config --global user.email $GIT_EMAIL
git config --global user.name $GIT_USERNAME
git checkout -b update-decidim-${DECIDIM_VERSION:-$now}
git add . && git commit -am "Update decidim" && git push origin update-decidim-${DECIDIM_VERSION:-$now}
curl \
  -i \
  -X POST \
  -d "{
    \"title\": \"Update Decidim\",
    \"base\":\"master\",
    \"head\":\"$GITHUB_ORGANIZATION:update-decidim-${DECIDIM_VERSION:-$now}\",
    \"body\":\"Changes https://github.com/decidim/decidim/compare/$old_revision...$new_revision\"
  }" \
  https://api.github.com/repos/$DECIDIM_GITHUB_ORGANIZATION/$DECIDIM_GITHUB_REPO/pulls?access_token=$GITHUB_OAUTH_TOKEN
