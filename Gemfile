# vim:ft=ruby

source 'https://rubygems.org'

if RUBY_VERSION.start_with? '1.9'
  gem 'net-ldap', '< 0.13'
end

unless RUBY_VERSION >= '2.2'
  gem 'activesupport', '< 5'
end

gemspec

gem 'rubocop', :group => :test if RUBY_VERSION >= '2.0'
