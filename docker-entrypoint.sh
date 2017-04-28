#!/bin/bash

now=`date +"%s"`

function get_revision() {
  bundle show decidim | awk -F'-' '{print $NF}'
}

function get_last_pr_info() {
  cat last_prs.json | \
  jq '.[] | { info: ((.number | tostring) + "-" + .head.label) }' | \
  grep decidim-bot | \
  head -1
}

function get_last_id() {
  echo $(get_last_pr_info) | \
  awk -F'-' '{print $1}' | awk -F'"' '{print $NF}'
}

function get_last_timestamp() {
  echo $(get_last_pr_info) | \
  awk -F'-' '{print substr($NF, 1, length($NF)-1)}'
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

echo "0. Get last pr info"
curl https://api.github.com/repos/$DECIDIM_GITHUB_ORGANIZATION/$DECIDIM_GITHUB_REPO/pulls?access_token=$GITHUB_OAUTH_TOKEN > last_prs.json
last_id=$(get_last_id $last_pr_info)
last_timestamp=$(get_last_timestamp $last_pr_info)

echo "1. Clone repository"
git clone https://$GITHUB_OAUTH_TOKEN@github.com/$GITHUB_ORGANIZATION/$GITHUB_REPO.git && cd $GITHUB_REPO
git remote add decidim https://github.com/$DECIDIM_GITHUB_ORGANIZATION/$DECIDIM_GITHUB_REPO.git && git fetch decidim
git reset --hard decidim/master
if [ "$last_timestamp" == "" ]; then
  branch_name="update-decidim-${DECIDIM_VERSION:-$now}"
  git checkout -b $branch_name
else
  branch_name="update-decidim-$last_timestamp"
  git checkout $branch_name
fi

echo "2. Install gems"
bundle install

echo "3. Create db and load schema"
bundle exec rake db:create db:schema:load

echo "4. Update decidim"
old_revision=$(get_revision)
bundle update decidim decidim-dev
new_revision=$(get_revision)
if [ "$old_revision" == "$new_revision" ]; then
  echo "Nothing to do."
  exit 0
fi

echo "5. Run decidim:upgrade and migrate db"
bundle exec rake decidim:upgrade db:migrate

echo "6. Create/Update PR to update decidim"
git add . && git commit -am "Update decidim" && git push origin $branch_name

if [ "$last_timestamp" == "" ]; then
  curl \
    -i \
    -X POST \
    -d "{
      \"title\": \"Update Decidim\",
      \"base\":\"master\",
      \"head\":\"$GITHUB_ORGANIZATION:$branch_name\",
      \"body\":\"Changes https://github.com/decidim/decidim/compare/$old_revision...$new_revision\"
    }" \
    https://api.github.com/repos/$DECIDIM_GITHUB_ORGANIZATION/$DECIDIM_GITHUB_REPO/pulls?access_token=$GITHUB_OAUTH_TOKEN
else
  curl \
    -i \
    -X POST \
    -d "{
      \"body\":\"Changes https://github.com/decidim/decidim/compare/$old_revision...$new_revision\"
    }" \
    https://api.github.com/repos/$DECIDIM_GITHUB_ORGANIZATION/$DECIDIM_GITHUB_REPO/issues/$last_id/comments?access_token=$GITHUB_OAUTH_TOKEN
fi
