# Revs Digital Library

This is a Blacklight application for the Revs Digital Library at Stanford University.

## Getting Started

1. Checkout the code:

        cd [ROOT FOLDER LOCATION OF WHERE YOU WANT THE CODE TO GO]
        git clone https://github.com/sul-dlss/revs.git
        cd revs

  The master branch is what is deployed in production.

  The develop branch is what is actively under development.  

1. [Optional] If you want to use rvmrc to manage gemsets, copy the .rvmrc example files:

        cp .rvmrc.example .rvmrc
        cd .. && cd revs

1. Install dependencies via bundler for both the main and deploy directories.  If you are outside the Stanford network
and are trying to run the code, see the special section below before continuing with the bundle install:

        bundle install

1. Get jetty setup

        rake jetty:clean

1. Copy the .yml example files and the jetty config files:

        rake revs:config

1. Create and migrate the databases:

        rake db:create:all
        rake db:migrate

1. Seed the databases:

        rake db:seed

  This will give you collection highlights for the home page and MUST BE/IS SAFE to run in all environments for the site to work.

1. Load the fixture data:

        rake db:fixtures:load
        rake revs:update_item_title

  This will give you a few test users to work with and should only be used in development.
  See the test/fixtures/users.yml files for usernames/passwords.  

1. Start the development solr (you should first stop any other jetty processes if you have
   multiple jetty-related projects):

        rake jetty:start

1. To index the records into an environment's core, ensure jetty is running (it may take a few extra seconds after the jetty:start command is issued), then:

        rake revs:index_fixtures

1. Start Rails:

        rails s

1. Go to <http://localhost:3000>

## Non-Stanford Users

The code has not been tested outside of Stanford University and while it should work, there may be some internal dependencies.
We believe that making the small modifications listed below will enable the Revs Digital Library code to work outside of Stanford:

1. Open the Gemfile at the root of the project and comment out the following line (in the  ":deployment" group).

  gem 'dlss-capistrano'

1. Prior to step 5 - creating and migrating the databases - you will need to remove all migrations involving edit-store from revs/db/migrate/ otherwise rake db:migrate will error and list the migration that fails. You can do this by hand or in revs/db/migrate/ run ls *edit-store* to see the files that match that filter and delete them with rm -i *edit-store*.

1. The rest should work - let us know if you find any other errors :)

## Default Users

The default users in the fixtures are:

* admin1
* curator1
* user1

The password for each default user is "password"


## Terms Dialog Box

Configuration for the terms dialog box is in the application_controller.rb.

The `show_terms_dialog?` method defines when and if the terms dialog needs to be shown
(it should return true or false based on whatever logic you want).

The `accept_terms` method defines what happens when the user accepts the terms dialog.
It can set a cookie with a specific expiration if you don't
want the user to see the terms dialog box again for a specific period of time (which could be very long if you essentially don't want it to display again).


## Deployment

### Tagging

Before deploying to production, tag the release with a version.  We use date-based tags, typically month-year (eg. september-2013) for monthly releases.

  git checkout master
  git tag september-2013
  git push --tags


### Deploying

Typically before deploying, you will merge the latest code from develop to master, then bump the version in a new commit on master, create a tag, push, and then deploy:

    git checkout master
    git merge develop
    # bump VERSION file
    git ci -m 'bump version'
    git push

    git tag TAG_NAME # standard is month-yearincrement, eg. June-2014a
    git push --tags

    bundle exec cap production deploy   # for production  (revslib.stanford.edu)
    bundle exec cap staging deploy      # for staging     (revs-stage.stanford.edu)
    bundle exec cap development deploy  # for development (revs-dev.stanford.edu)

You must specify a branch or tag to deploy.  You can deploy the latest by specifying "master".

## Testing

You can run the test suite locally by running:

    rake local_ci

Your local development jetty must be started for this to work.  If your local jetty is stopped, start it with:

    rake jetty:start

## Git Development Strategy


### Branches

The *master* branch is what is running in production and staging.
The *develop* branch is what is running (typically) in development.
In the examples below, the *working* branch is your local feature branch,
from which you later merge your updated work into either *master* or *develop*.

### Typical day to day development workflow

1. Getting up to date

        git checkout develop
        git pull  

2. Working (*working* is your local feature branch)

        git checkout working
        * do stuff *
        git add
        git commit -m 'my changes'

3. Getting *develop* up to date

        git checkout develop
        git pull

  Look for new updates. If you have updates, continue with Step 4, otherwise continue with Step 5.

4. If there are changes

        git checkout working
        git rebase develop
        git checkout develop

5. Merge and push

        git merge working
        git push

6. Head back to step 2 to continue working

  You can skip step 4 if the `git pull` in step 3 doesn't bring down any updates so you know *working* is already up-to-date.
  Step 4 is where you could have merge conflicts. But now you resolve them on *working* so when you then merge back to *develop* (after fixing the conflicts),
  the git history is linear and doesn't show any merge commits.  
