# Decidim Updater

The following docker image runs a simple shell script to clone an existing fork from a Decidim application repository and update the `decidim` and `decidim-dev` gems.
Finally, it creates a PR against the original repository.

## Usage

```bash
docker run -e GITHUB_USER=xxx
           -e GITHUB_PASSWORD=xxx
           -e GITHUB_ORGANIZATION=xxx
           -e GITHUB_REPO=xxx
           -e DECIDIM_GITHUB_ORGANIZATION=xxx
           -e DECIDIM_GITHUB_REPO=xxx
           codegram/decidim-updater
```

## Configuration

The docker image uses the following environment variables:

- **`GITHUB_USER`**: The github user to clone the repository.
- **`GITHUB_PASSWORD`**: The password used to authenticate the user in Github.
- **`GITHUB_ORGANIZATION`**: The github organization who has created a fork from a decidim application.
- **`GITHUB_REPOSITORY`**: The github repository which is a fork from a decidim application.
- **`DECIDIM_GITHUB_ORGANIZATION`**: The github organization who was created a decidim application.
- **`DECIDIM_GITHUB_REPO`**: The github repository which corresponds to a decidim application.
- **`DATABASE_HOST`**: __(defaults to `db`)__ The database host.
- **`DATABASE_USERNAME`**: __(defaults to `postgres`)__ The database user.
- **`DATABASE_PASSWORD`**: __(defaults to `''`)__ The database password.
- **`DATABASE_NAME`**: __(defaults to `''`)__ The database name.
- **`DECIDIM_VERSION`**: __(defaults to a unix timestamp)__ Identify the update branch.
- **`GIT_USERNAME`**: __(defaults to `decidim-updater-bot`)__ Username used to create the commit.
- **`GIT_EMAIL`**: __(defaults to `decidim-updater-bot@foo.bar`)__ Email used to create the commit.