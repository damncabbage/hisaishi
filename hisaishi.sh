#!/bin/bash

# Only override if nothing has been set already
[[ "$ADMIN_PIN" ]]         || export ADMIN_PIN=1234
[[ "$DEFAULTS_TO_QUEUE" ]] || export DEFAULTS_TO_QUEUE=1

bundle exec ruby hisaishi.rb
