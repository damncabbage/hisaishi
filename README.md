= Hisaishi

It's for showing Karaoke on the web.

(Accepts [Soramimi Karaoke](http://soramimi.nl/) song timestamp formats.)


== Installation

```bash
git clone git://github.com/smashcon/hisaishi.git  # Warning: read-only.
cd hisaishi

bundle install
alias be="bundle exec"
be rake hisaishi:install # Sets up config/environments.rb
be rake db:create

# Optional:
be rake hisaishi:example # Sets up an example seed and song.
be rake db:seed          # Seeds the example from data/seeds.csv

# Kick it off in development mode
be ruby hisaishi.rb
```

Now go and open http://localhost:4567/ in your browser and sample the *PHAT BEATS*.


== Caveats

Hisaishi is pretty heavily coupled with Basecamp's authentication API; this is a hacky internal project and haven't yet had time to split out the authentication into a Warden strategy yet.

Ignoring the `set :basecamp_domain` directive in the config files, however, disables the login entirely; in that case, the username is assumed to 'guest'.
