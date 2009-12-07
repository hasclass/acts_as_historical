require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the acts_as_historic plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'rails'
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the acts_as_historic plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ActsAsHistoric'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "acts_as_historical"
    gemspec.summary = "One line summary of your gem"
    gemspec.description = "A different and possibly longer explanation of"
    gemspec.email = ""
    gemspec.homepage = "http://github.com/has_class/acts_as_historical"
    gemspec.authors = ["Sebastian Burkhard"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end
