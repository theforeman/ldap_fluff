require 'rake/clean'
require 'rake/testtask'
require 'rdoc/task'
begin
  require 'rubygems'
  require 'rubygems/package_task'
rescue Exception
  nil
end

# Determine the current version of the software

CLOBBER.include('pkg')

SRC_RB = FileList['lib/**/*.rb']

# The default task is run if rake is given no explicit arguments.

desc "Default Task"
task :default => :test_all

# Test Tasks ---------------------------------------------------------

Rake::TestTask.new("test_units") do |t|
  t.test_files = FileList['test/*_test.rb']
  t.verbose = false
end

# ====================================================================
# Create a task that will package the Rake software into distributable
# gem files.

PKG_FILES = FileList[
  'etc/**/*.yml',
  'lib/**/*.rb', 
  'test/**/*.rb',
  'scripts/**/*.rb'
]

if ! defined?(Gem)
  puts "Package Target requires RubyGEMs"
else
  spec = Gem::Specification.new do |s|
    
    #### Basic information.

    s.name = 'ldap_fluff'
    s.version = `rpm -q --qf "%{version}" --specfile rubygem-ldap_fluff.spec`
    s.summary = "LDAP Querying tools for Active Directory, FreeIPA and Posix-style"
    s.description = %{\
Simple library for binding & group querying on top of various ldap implementations
}
    s.homepage = "http://www.redhat.com"
    s.files = PKG_FILES.to_a
    s.require_path = 'lib'
    
    s.test_files = PKG_FILES.select { |fn| fn =~ /^test\/test/ }
    
    s.has_rdoc = true
    s.author = "Jordan OMara"
    s.email = "jomara@redhat.com"

    # deps
    s.gem.add_dependency('net-ldap')
    # testing deps
    s.gem_add_development_dependency('minitest')
    s.gem_add_development_dependency('factory_girl')
  end

  namespace 'ldap_fluff' do 
    Gem::PackageTask.new(spec) do |t|
      t.need_tar = true 
    end 
  end

  task :package => ['ldap_fluff:package']
end
