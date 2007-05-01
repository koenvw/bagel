require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the bagel plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the bagel plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Bagel'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.options << '--main' << 'README'
  rdoc.rdoc_files.include('README', 'LICENSE')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include('app/models/*.rb')
  rdoc.rdoc_files.include('app/controllers/site_controller.rb')
end
