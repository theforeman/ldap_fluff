# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'ldap_fluff'
  s.version     = '0.5.1'
  s.summary     = 'LDAP querying tools for Active Directory, FreeIPA and POSIX-style'
  s.description = 'Simple library for binding & group querying on top of various LDAP implementations'
  s.homepage    = 'https://github.com/theforeman/ldap_fluff'
  s.license     = 'GPLv2'

  s.extra_rdoc_files = %w[README.rdoc LICENSE]
  s.files            = s.extra_rdoc_files + Dir['lib/**/*.rb']

  s.require_paths = ['lib']
  s.test_files    = Dir['test/**/*.rb']

  s.authors = ['Jordan O\'Mara', 'Daniel Lobato', 'Petr Chalupa', 'Adam Price', 'Marek Hulan', 'Dominic Cleal']
  s.email   = %w[jomara@redhat.com elobatocs@gmail.com pchalupa@redhat.com komidore64@gmail.com mhulan@redhat.com
                 dominic@cleal.org]

  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency 'net-ldap', '~> 0.12'

  s.add_development_dependency 'bundler', '>= 1.14'
  s.add_development_dependency 'rake', '>= 10.0'

  s.add_development_dependency 'minitest', '~> 5.0'
  s.add_development_dependency 'rubocop'
end
