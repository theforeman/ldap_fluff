#!/usr/bin/env bash

set -e # fail on error

echo ""
echo "MINITEST"
bundle exec rake

echo ""
echo "RUBOCOP"
# disable rubocop for now
bundle exec rubocop $(git ls-files | grep ".*\.rb$") Gemfile Rakefile ldap_fluff.gemspec || true
