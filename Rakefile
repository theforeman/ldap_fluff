require 'rubygems'
require 'rake/testtask'

# The default task is run if rake is given no explicit arguments.
desc 'Default Task'
task :default => :test

# Test Tasks ---------------------------------------------------------

Rake::TestTask.new('test') do |t|
  t.libs       = %w[lib test]
  t.test_files = FileList['test/**/*.rb']
  t.verbose    = true
end
