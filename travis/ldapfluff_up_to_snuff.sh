#!/usr/bin/env bash

echo ""
echo "MINITEST"
bundle exec rake

echo ""
echo "RUBOCOP"
bundle exec rubocop $(git ls-files | grep ".*\.rb$") Gemfile Rakefile ldap_fluff.gemspec
