require 'rubygems'

require 'test/unit'
require 'active_record'
require 'active_record/fixtures'
require 'active_support'
require 'active_support/test_case'
require 'shoulda'

ENV['RAILS_ENV'] = 'test'

ActiveRecord::Base.logger = Logger.new(StringIO.new) # Shush.

def load_schema
  config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))

  # Allow user to customise the database used; defaults to mysql.
  db_adapter = ENV['DB'] ||= 'mysql'

  ActiveRecord::Base.establish_connection(config[db_adapter])

  load(File.dirname(__FILE__) + "/schema.rb")
  require File.dirname(__FILE__) + '/../rails/init.rb'
end

class Date
  def to_date(); self; end
end
