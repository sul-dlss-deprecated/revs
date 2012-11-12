require 'rspec/core/rake_task'
desc "Run continuous integration suite"
task :ci do
  # We will need to have add jettywrapper and a test
  # index if we want to start doing integration testing.
  Rake::Task["rspec"].invoke
end

RSpec::Core::RakeTask.new(:rspec) do |spec|
  spec.rspec_opts = ["-c", "-f progress", "-r ./spec/spec_helper.rb"]
end