#!/bin/bash

# Only override if nothing has been set already
[[ "$ADMIN_PIN" ]]         || export ADMIN_PIN=1234
[[ "$DEFAULTS_TO_QUEUE" ]] || export DEFAULTS_TO_QUEUE=1

# Change to wherever this script it located.
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Fire it up.
bundle exec ruby hisaishi.rb
