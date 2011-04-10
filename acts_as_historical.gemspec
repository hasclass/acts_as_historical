# encoding: utf-8

Gem::Specification.new do |s|
  s.required_rubygems_version = '>= 1.3.6'

  # The following four lines are automatically updated by the "gemspec" rake
  # task. It it completely safe to edit them, but using the rake task is
  # easier, and any values you enter will be overwritten when the "gemspec"
  # task is run.
  s.name              = 'acts_as_historical'
  s.version           = '0.2.0'
  s.date              = '2011-04-05'
  s.rubyforge_project = 'acts_as_historical'

  # You may safely edit the section below.

  s.platform     = Gem::Platform::RUBY
  s.authors      = ['hasclass']
  s.email        = ['sebastian.burkhard@gmail.com']
  s.homepage     = 'http://github.com/hasclass/acts_as_historical'
  s.summary      = 'ActiveRecord plugin for historical data (stock prices, ' \
                   'pageviews, etc).'

  s.rdoc_options     = ['--charset=UTF-8']
  s.extra_rdoc_files = %w[LICENSE README.rdoc]

  s.require_path = 'lib'

  s.add_dependency 'activerecord',  '>= 3.0.5'
  s.add_dependency 'activesupport', '>= 3.0.5'

  s.add_development_dependency 'test-unit', '>= 2.0'
  s.add_development_dependency 'mysql',     '>= 0'
  s.add_development_dependency 'shoulda',   '>= 0'
  s.add_development_dependency 'date_ext',  '>= 0'

  # The manifest is created by the "gemspec" rake task. Do not edit it
  # directly; your changes will be wiped out when you next run the task.

  # = MANIFEST =
  s.files = %w[
    Gemfile
    LICENSE
    README.rdoc
    Rakefile
    acts_as_historical.gemspec
    lib/acts_as_historical.rb
    lib/acts_as_historical/version.rb
    rails/init.rb
  ]
  # = MANIFEST =

  s.test_files = s.files.select { |path| path =~ /^test\/.*\.rb/ }
end
