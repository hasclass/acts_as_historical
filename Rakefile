  require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "acts_as_historical"
    gem.summary = %Q{ActiveRecord plugin for historical data (stock prices, pageviews, etc).}
    gem.description = %Q{}
    gem.email = "sebastian.burkhard@gmail.com"
    gem.homepage = "http://github.com/hasclass/acts_as_historical"
    gem.authors = ["hasclass"]

    gem.add_dependency "activerecord",  "~> 2.3.5"
    gem.add_dependency "activesupport", "~> 2.3.5"

    gem.add_development_dependency "mysql",    ">= 0"
    gem.add_development_dependency "shoulda",  ">= 0"
    gem.add_development_dependency "mocha",    ">= 0"
    gem.add_development_dependency "redgreen", ">= 0"
    gem.add_development_dependency "date_ext", ">= 0"
    gem.add_development_dependency "jeweler",  ">= 0"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test' << 'rails'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/*_test.rb'
    test.rcov_opts = %w{--rails --exclude osx\/objc,gems\/,spec\/,features\/ --aggregate coverage.data}
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "acts_as_historical #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
