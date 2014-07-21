Gem::Specification.new do |s|
  s.name        = 'ldap_fluff'
  s.version     = '0.2.5'
  s.summary     = 'LDAP Querying tools for Active Directory, FreeIPA and Posix-style'
  s.description = 'Simple library for binding & group querying on top of various ldap implementations'
  s.homepage    = 'https://github.com/Katello/ldap_fluff'
  s.license     = 'GPLv2'
  s.files       = Dir['lib/**/*.rb'] + Dir['test/**/*.rb']

  s.require_path = 'lib'
  s.test_files   = Dir['test/**/*.rb']

  s.has_rdoc = true
  s.author   = 'Jordan OMara'
  s.email    = 'jomara@redhat.com'

  s.add_dependency('net-ldap', '>= 0.3.1')
  s.add_dependency('activesupport', '~> 3.2')
  s.add_development_dependency('rake')
  s.add_development_dependency('minitest')
end
