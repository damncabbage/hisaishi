require 'rubygems'
require File.join(File.dirname(__FILE__), 'environment')

namespace :db do
  desc 'Create the databases and, if they exist, clear the data in them.'
  task :create do
    Song.auto_migrate!
    Vote.auto_migrate!
  end

  desc 'Load the seed data from data/seeds.rb.'
  task :seed  do
    seed_file = "./data/seeds.rb"
    load(seed_file) if File.exist?(seed_file)
  end
end