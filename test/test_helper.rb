require 'rubygems'
require 'active_record'
require 'active_record/fixtures'
require 'active_support'
require 'active_support/test_case'
require 'test/unit'
require 'shoulda'
require 'redgreen'

ENV['RAILS_ENV'] = 'test'

ActiveRecord::Base.logger = Logger.new(StringIO.new) # Shush.

def load_schema
  config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))

  db_adapter = ENV['DB']

  # no db passed, try one of these fine config-free DBs before bombing.
  db_adapter ||= 'mysql'

  if db_adapter.nil?
    raise "No DB Adapter selected. Pass the DB= option to pick one, or install Sqlite or Sqlite3."
  end

  ActiveRecord::Base.establish_connection(config[db_adapter])
  #Fixtures.create_fixtures(File.dirname(__FILE__), ActiveRecord::Base.connection.tables)


  load(File.dirname(__FILE__) + "/schema.rb")
  require File.dirname(__FILE__) + '/../rails/init.rb'
end

class Date
  def to_date(); self; end
end
