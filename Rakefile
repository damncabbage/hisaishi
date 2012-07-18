require 'rubygems'
require 'fileutils'
require File.expand_path('environment.rb', File.dirname(__FILE__))

namespace :db do
  desc 'Create the databases and, if they exist, clear the data in them.'
  task :create do
    Song.auto_migrate!
    Vote.auto_migrate!
    Reason.auto_migrate!
    HisaishiQueue.auto_migrate!
    Announcement.auto_migrate!    
  end
  
  desc 'Upgrade db tables to most recent state.'
  task :upgrade do
    Song.auto_upgrade!
    Vote.auto_upgrade!
    Reason.auto_upgrade!
    HisaishiQueue.auto_upgrade!
    Announcement.auto_upgrade!
  end

  desc 'Load the seed data from data/seeds.rb.'
  task :seed do
    seed_file = "./data/seeds.rb"
    load(seed_file) if File.exist?(seed_file)
  end
end

namespace :hisaishi do
  desc 'Generate the installation-specific config file.'
  task :install do
    template = File.expand_path('tasks/templates/environments.rb', File.dirname(__FILE__))
    config   = File.expand_path('config/environments.rb', File.dirname(__FILE__))

    raise "The environments.rb config already exists!" if File.exists?(config)
    cp template, config, :verbose => true
  end

  desc "Set up an example song and seed file."
  task :example do
    base_path      = File.realdirpath(File.dirname(__FILE__))
    music_path    = File.join(base_path, 'public', 'music')
    examples_path = File.join(base_path, 'tasks', 'examples')

    puts "Setting up example music and lyrics."
    mkdir music_path
    cp File.join(examples_path, 'Jeris - Grease Man in a Jam.mp3'), music_path
    cp File.join(examples_path, 'Jeris - Grease Man in a Jam.txt'), music_path

    puts "Setting up seeds.csv"
    cp File.join(examples_path, 'seeds.csv'), File.join(base_path, 'data')

    puts "Done! Next, run 'bundle exec rake db:seed'."
  end
  
  desc 'Calculates song lengths and saves to db.'
  task :songlengths do
    Song.all.each do |s|
      next if s.length > 0
      puts "Working on #{s.title}."
      data = s.get_data!
      if !data.nil? then
        time = data.length.ceil
        s.length = time
        s.save
      end
      puts "Length: #{s.length} secs"
    end
  end
end

namespace :apache do
  desc 'Creates vhost for files directory.'
  task :vhostfiles do
    tpl = '<VirtualHost *:80>
  DocumentRoot {path}
  ServerName hisaishi-files.local
  <Directory {path}>
    Options +Indexes FollowSymLinks MultiViews
    AllowOverride All
    Order allow,deny
    allow from all
  </Directory>
  ErrorLog /var/log/apache2/hisaishi-files-error.log
  CustomLog /var/log/apache2/hisaishi-files-access.log combined
</VirtualHost>'
    vhost = tpl.gsub('{path}', File.join(File.dirname(__FILE__), 'public'))
    
    filename = "hisaishi-files.local.conf"
    f = File.new(filename, "w")
    f.write(vhost)
    f.close
    puts "Wrote #{filename}"
  end
end
