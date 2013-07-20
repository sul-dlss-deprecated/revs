# Revs Digital Library

This is a Blacklight Application for the Revs Digital Library at Stanford University.

## Getting Started

1. Checkout the code:

        cd [ROOT FOLDER LOCATION OF WHERE YOU WANT THE CODE TO GO]
        git clone https://github.com/sul-dlss/revs.git
        cd revs

  The master branch is what is deployed in production.

  The develop branch is what is actively under development.  

1. [Optional] If you want to use rvmrc to manage gemsets, copy the .rvmrc example files:

        cp .rvmrc.example .rvmrc
        cp deploy/.rvmrc.example deploy/.rvmrc

1. Install dependencies via bundler for both the main and deploy directories:

        bundle install
        cd deploy
        bundle install
        cd ..

1. Copy the .yml example files:

        cd revs
        rake revs:config

1. Create and migrate the databases:

        rake db:create:all
        rake db:migrate

1. Seed the databases:

        rake db:seed

  This will give you collection highlights for the home page and MUST BE/IS SAFE to run in all environments for the site to work.

1. Load the fixture data:

        rake db:fixtures:load

  This will give you a few test users to work with and should only be used in development.
  See the test/fixtures/users.yml files for usernames/passwords.  

1. Start the development solr (you should first stop any other jetty processes if you have
   multiple jetty-related projects):

        rake jetty:start

1. To index the records into an environment's core, ensure jetty is running, then:

        rake revs:index_fixtures

1. Start Rails:

        rails s

1. Go to <http://localhost:3000>

## Terms Dialog Box

Configuration for the terms dialog box is in the application_controller.rb.

The `show_terms_dialog?` method defines when and if the terms dialog needs to be shown
(it should return true or false based on whatever logic you want).

The `accept_terms` method defines what happens when the user accepts the terms dialog.
It can set a cookie with a specific expiration if you don't
want the user to see the terms dialog box again for a specific period of time (which could be very long if you essentially don't want it to display again).

## Deployment

    cd deploy
    cap production deploy   # for production
    cap staging deploy      # for staging
    cap development deploy  # for development

You must specify a branch or tag to deploy.  You can deploy the latest by specifying "master"

## Testing

You can run the test suite locally by running:

    rake local_ci

Your local development jetty must be started for this to work.  If your local jetty is stopped, start it with:

    rake jetty:start

## Git Development Strategy

### Branches

Master branch is what is running in production and staging
Develop branch is what is running (typically) on development
Working branch (local) is your local working branch

### Day to day working

Getting up to date
1. git checkout develop
2. git pull  

Working
3. git checkout working
4. now make updates and commit them on 'working'

Getting Develop Up to date
5. git checkout develop
6. git pull

If there are changes
7. git checkout working
8. git rebase develop
9. git checkout develop

10. git merge working
11. git push

12. Head back to step 3 to continue working

You can skip steps 7,8, and 9 if 'git pull develop' doesn't bring down any updates so you know 'working' is already up to date. 
Step 8 is where you could have merge conflicts. But now you resolve them on 'working' so when you then merge back to 'develop' (after fixing the conflicts), 
the git history is linear and doesn't show any merge commits.  
