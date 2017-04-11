[![Build Status](https://travis-ci.org/sul-dlss/revs.svg?branch=master)](https://travis-ci.org/sul-dlss/revs)

# Revs Digital Library

This is a Blacklight Application for the Revs Digital Library at Stanford University.

## Getting Started

1. Checkout the code:

        cd [ROOT FOLDER LOCATION OF WHERE YOU WANT THE CODE TO GO]
        git clone https://github.com/sul-dlss/revs.git
        cd revs

  The master branch is what is deployed in production.

  To make changes to the code, create a feature branch off of master, commit to the new feature branch, and then submit a pull request to master.

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

1. Start jetty, create and migrate the databases (note you should first stop any other jetty processes that are running if you have
   multiple jetty-related projects):

        rake jetty:start
        rake db:create:all
        rake db:migrate

1. Seed the databases - this will give you collection highlights for the home page and MUST BE/IS SAFE to run in all environments for the site to work:

        rake db:seed

1. Load the fixture data - this will give you a few test users to work with and should only be used in development.
  See the test/fixtures/users.yml files for usernames/passwords.

        rake db:fixtures:load
        rake revs:update_item_title

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

1. The rest should work - let us know if you find any other errors

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

Before deploying to production, update the VERSION file, and then tag the release with a version.  We use date based tags, typically month-year (eg. september-2013) for monthly releases.

Bump VERSION file by editing it in master
  git co master
  git ci -m 'bump version to VERSION-NUMBER-HERE'
  git push

  git tag VERSION-NUMBER-HERE
  git push --tags


### Deploying

    bundle exec cap prod deploy     # for production  (revslib.stanford.edu)
    bundle exec cap stage deploy    # for staging     (revs-stage.stanford.edu, only visible when VPNed)
    bundle exec cap dev deploy      # for development (revs-dev.stanford.edu, only visible when VPNed)

You must specify a branch to deploy.  You can deploy the latest by specifying "master".  You should never be deploying anything except master to prod.

## Testing

You can run the test suite locally by running:

    rake local_ci

Your local development jetty must be started for this to work.  If your local jetty is stopped, start it with:

    rake jetty:start

## Git Development Strategy

### Branches

The *master* branch is what is running in production (and usually in staging as well).
We use feature/task based branches with pull requests that are merged to master for day to day work.

## Maintaining the fields in the solr document

If you need to add or remove a field that is in the solr document (i.e. associated with an object), there are many
codebases that need to be edited because of the nature of the metadata editing that is somewhat unique to the Revs
Digital Library.  For example, if you wanted to add a new field, you need to:

1. Be sure the MODs template gets updated to the new field is stored appropriately during accessioning.  The MODs templates are in /config/templates.
2. Ensure the new field has a column in the metadata spreadsheet supplied by Revs. The name of the column in the spreadsheet should match what is in the MODs template you edited in step 1.
3. Update the Revs template in editstore-updater to be sure metadata edits coming from the site make it to the MODs correctly.  In the editstore-updater code  (https://github.com/sul-dlss/editstore-updater), this is in the app/models/template/revs.rb file in the "field_definitions" method.  Configure with the name of the solr field and the location in the MODs template.  After deploying editstore-updater, be sure to visit the UI (https://revslib.stanford.edu/editstore/projects/2) and confirm you see the fields in the list.
4. Update the revs-indexing-service code (https://github.com/sul-dlss/revs-indexer-service) to be sure the MODs is correctly indexed into solr.  You'll need to update the lib/revs_mapper.rb class (in the convert_to_solr_doc method).
5. Update the revs-utils gem, which has shared configuration around available fields.
 -- add the new fields in the lib/revs-utils.rb file in the "revs_field_mapping" method.  Configuration specifies the accessor name along with the solr field name.
 -- update config/manifest_headers.yml to add the new columns that will appear in spreadsheets
 -- bump and release the gem
6. Update the revs digital library website code (this codebase) to show the new field and make it editable (if necessary), and add it as a facet (if necessary).
 -- add facets in the catalog controller if necessary
 -- update the "bulk_update_fields" method in ApplicationHelper if this new field is available for bulk updating by curators
 -- update the app/views/catalog/_show_default_collection_member.html.erb view to add the new field to the appropriate part of the interface
 -- in the SolrDocument model, update the "has_XXX?" methods which are used to indicate when certain parts of the webpage interface have metadata
 -- you may need to update the locale files with new strings for labels in the step above
 -- bundle update to use the latest revs-utils gem you released above
 -- update mods template in /config/templates (described in step 1 above) and copy to the places where accessioning occurs (eg. /dor/staging/Revs)
7. Possibly adjust the solr schema and config and deploy to production if you need to make a copy field of a text field for searchability.  If you do this, you'll need to edit the config/schema.xml and config/solrconfig.xml documents in this codebase and then have them deployed into the solr cloud.
8. Release a new pre-assembly with the new version of revs-utils you released above.  This will allow the scripts that confirm spreadsheets before accessioning to be aware of the new column(s).
