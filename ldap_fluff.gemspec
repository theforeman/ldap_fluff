Gem::Specification.new do |s|
  s.name        = 'ldap_fluff'
  s.version     = '0.6.0'
  s.summary     = 'LDAP querying tools for Active Directory, FreeIPA and POSIX-style'
  s.description = 'Simple library for binding & group querying on top of various LDAP implementations'
  s.homepage    = 'https://github.com/theforeman/ldap_fluff'
  s.license     = 'GPL-2.0-only'
  s.files       = Dir['lib/**/*.rb'] + Dir['test/**/*.rb'] + ['README.rdoc', 'LICENSE']
  s.extra_rdoc_files = ['README.rdoc', 'LICENSE']

  s.require_path = 'lib'
  s.test_files   = Dir['test/**/*.rb']

  s.author   = ['Jordan O\'Mara', 'Daniel Lobato', 'Petr Chalupa',
                'Adam Price', 'Marek Hulan', 'Dominic Cleal']
  s.email    = %w[jomara@redhat.com elobatocs@gmail.com pchalupa@redhat.com
                  komidore64@gmail.com mhulan@redhat.com dominic@cleal.org]

  s.required_ruby_version = '>= 2.4.0'

  s.add_dependency('activesupport', '>= 5', '< 7')
  s.add_dependency('net-ldap', '>= 0.11', '< 1')
  s.add_development_dependency('minitest', '~> 5.0')
  s.add_development_dependency('rake', '~> 13.1')
end
