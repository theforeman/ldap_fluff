Gem::Specification.new do |s|
  s.name        = 'ldap_fluff'
  s.version     = '0.4.3'
  s.summary     = 'LDAP querying tools for Active Directory, FreeIPA and POSIX-style'
  s.description = 'Simple library for binding & group querying on top of various LDAP implementations'
  s.homepage    = 'https://github.com/theforeman/ldap_fluff'
  s.license     = 'GPLv2'
  s.files       = Dir['lib/**/*.rb'] + Dir['test/**/*.rb'] + ['README.rdoc', 'LICENSE']
  s.extra_rdoc_files = ['README.rdoc', 'LICENSE']

  s.require_path = 'lib'
  s.test_files   = Dir['test/**/*.rb']

  s.has_rdoc = true
  s.author   = ['Jordan O\'Mara', 'Daniel Lobato', 'Petr Chalupa', 'Adam Price', 'Marek Hulan', 'Dominic Cleal']
  s.email    = %w(jomara@redhat.com elobatocs@gmail.com pchalupa@redhat.com komidore64@gmail.com mhulan@redhat.com dominic@cleal.org)

  s.required_ruby_version = ">= 1.9.3"

  s.add_dependency('net-ldap', '>= 0.3.1')
  s.add_dependency('activesupport')
  s.add_development_dependency('rake')
  s.add_development_dependency('minitest')
  s.add_development_dependency('rubocop')
end
