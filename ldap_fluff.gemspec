Gem::Specification.new do |s|
  s.name        = 'ldap_fluff'
  s.version     = '0.3.0'
  s.summary     = 'LDAP Querying tools for Active Directory, FreeIPA and Posix-style'
  s.description = 'Simple library for binding & group querying on top of various ldap implementations'
  s.homepage    = 'https://github.com/Katello/ldap_fluff'
  s.files       = Dir['lib/**/*.rb'] + Dir['test/**/*.rb']

  s.require_path = 'lib'
  s.test_files   = Dir['test/**/*.rb']

  s.has_rdoc = true
  s.author   = %w('Jordan OMara' 'Daniel Lobato' 'Petr Chalupa', 'Adam Price' 'Marek Hulan')
  s.email    = %w('jomara@redhat.com' 'elobatocs@gmail.com' 'pchalupa@redhat.com' 'komidore64@gmail.com' 'mhulan@redhat.com')

  s.add_dependency('net-ldap', '>= 0.3.1')
  if RUBY_VERSION < '1.9'
    s.add_dependency('activesupport', '~> 3.2')
  else
    s.add_dependency('activesupport')
  end
  s.add_development_dependency('rake')
  s.add_development_dependency('minitest')
end
