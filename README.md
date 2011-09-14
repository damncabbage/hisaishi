Hisaishi
========

Hisaishi is for showing karaoke on the web.

Hisaishi plays back an mp3 file and shows lyrics which have been timestamped to match. It accepts lyrics in the format created and used by [Soramimi Karaoke](http://soramimi.nl/) (so if you have a bunch of Soramimi lyrics, you're good to go).

Hisaishi is designed for deployment to [Heroku](http://heroku.com/) but you could run it locally if that's more your bag. It is designed for groovy browsers like Google Chrome and Safari but it should work in Firefox.


Installation
------------

```bash
git clone git://github.com/smashcon/hisaishi.git  # Warning: read-only.
cd hisaishi

bundle install
alias be="bundle exec"
be rake hisaishi:install  # Sets up config/environments.rb
be rake db:create

# Optional:
be rake hisaishi:example # Sets up an example seed and song.
be rake db:seed          # Seeds the example from data/seeds.csv

# Kick it off in development mode
be ruby hisaishi.rb
```

Now go and open http://localhost:4567/ in your browser and sample the *PHAT BEATS*.


Caveats
-------

Hisaishi was developed for internal use. We wanted to open source it so that people could see what we were up to but there are elements of it that are still pretty tightly tied to our needs at the moment. (This is why there's voting and why we have it coupled with Basecamp's authentication API.)

We haven't had time to split out the authentication into a Warden strategy yet. Ignoring the `set :basecamp_domain` directive in the config files, however, disables the login entirely. In that case, the username is assumed to 'guest'.

Licence
-------

Hisaishi is copyright 2011 Geoffrey Roberts, Robert Howard and Michael Camilleri. It is distributed under an [MIT Licence](http://en.wikipedia.org/wiki/MIT_License).