Gem::Specification.new do |s|
  s.name        = 'ldap_fluff'
  s.version     = '0.6.0'
  s.summary     = 'LDAP querying tools for Active Directory, FreeIPA and POSIX-style'
  s.description = 'Simple library for binding & group querying on top of various LDAP implementations'
  s.homepage    = 'https://github.com/theforeman/ldap_fluff'
  s.license     = 'GPLv2'
  s.files       = Dir['lib/**/*.rb'] + Dir['test/**/*.rb'] + ['README.rdoc', 'LICENSE']
  s.extra_rdoc_files = ['README.rdoc', 'LICENSE']

  s.require_path = 'lib'
  s.test_files   = Dir['test/**/*.rb']

  s.author   = ['Jordan O\'Mara', 'Daniel Lobato', 'Petr Chalupa',
                'Adam Price', 'Marek Hulan', 'Dominic Cleal']
  s.email    = %w[jomara@redhat.com elobatocs@gmail.com pchalupa@redhat.com
                  komidore64@gmail.com mhulan@redhat.com dominic@cleal.org]

  s.required_ruby_version = '>= 2.4.0'

  s.add_dependency('activesupport')
  s.add_dependency('net-ldap', '>= 0.11')
  s.add_development_dependency('minitest')
  s.add_development_dependency('rake')
end
