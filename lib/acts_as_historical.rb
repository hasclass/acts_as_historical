require 'active_support/concern'

module ActsAsHistorical
  extend ActiveSupport::Concern

  module ClassMethods

    # acts_as_historical
    #
    #
    # @option opts [Symbol] :date_column (:snapshot_date) the database column for the date of the record
    # @option opts [Symbol] :scope (nil)
    #
    def acts_as_historical(opts = {})
      configuration = {
        :date_column => "snapshot_date",
        :scope => nil
      }

      configuration.update(opts) if opts.is_a?(Hash)

      send :include, InstanceMethods
      send :extend,  DynamicClassMethods

      self.cattr_accessor :historical_date_col, :historical_scope, :only_weekdays

      self.historical_date_col = configuration[:date_column]
      self.historical_scope    = configuration[:scope]

      order_desc = "#{self.historical_date_col_sql} DESC"
      order_asc = "#{self.historical_date_col_sql} ASC"

      # scopes - sortings
      scope :asc,  :order => order_asc
      scope :desc, :order => order_desc

      scope :oldest,        :limit => 1, :order => order_asc
      scope :newest,        :limit => 1, :order => order_desc
      scope :newest_two,    :limit => 2, :order => order_desc

      # one snapshot per week (every wednesday)
      scope :weekly, :conditions =>
        "DAYOFWEEK(#{self.historical_date_col_sql}) = 2"

      %w[sundays mondays tuesdays wednesdays thursdays fridays saturdays].each_with_index do |name, day_of_week|
        scope name, :conditions =>
          "DAYOFWEEK(#{self.historical_date_col_sql}) = #{day_of_week+1}"
      end

      scope :within_month, lambda {{
          :conditions => ["#{self.historical_date_col_sql} > ?", Date.today - 30]
      }}

      scope :within_year, lambda {{
          :conditions => ["#{self.historical_date_col_sql} > ?", Date.today - 364]
      }}

      scope :same_scope, lambda {|record|
        if self.historical_scope.nil?
          {}
        else
          {:conditions => {self.historical_scope => record[self.historical_scope]} }
        end
      }

      scope :on_date, lambda {|date| {
          :conditions => { :snapshot_date => date.to_date },
          :limit => 1
      }}

      # between(older_date, newer_date)
      #
      scope :between, lambda {|*args|
        from, to = args
        range = (from.to_date..to.to_date)
        { :conditions => {self.historical_date_col => range } }
      }

      # nearest(date, 1)
      # nearest(date, (date_from..date_to))
      #
      scope :nearest, lambda {|*args|
        date, tolerance = args
        range = self.tolerance_to_range(date, tolerance)
        {
          :conditions => {self.historical_date_col => range},
          :order => ["ABS(DATEDIFF(#{self.historical_date_col_sql}, '#{date.to_date.to_s(:db)}')) ASC"]
        }
      }

      # Does not include date
      #
      scope :upto, lambda {|date|
        raise "passed parameter does not respond_to? to_date" unless date.respond_to?(:to_date)
        { :conditions => ["#{self.historical_date_col_sql} < ?", date.to_date] }
      }

      # Includes date
      #
      scope :upto_including, lambda {|date|
        raise "passed parameter does not respond_to? to_date" unless date.respond_to?(:to_date)
        { :conditions => ["#{self.historical_date_col_sql} <= ?", date.to_date] }
      }

      scope :from, lambda {|date|
        raise "passed parameter does not respond_to? to_date" unless date.respond_to?(:to_date)
        { :conditions => ["#{self.historical_date_col_sql} > ?", date.to_date] }
      }

      scope :from_including, lambda {|date|
        raise "passed parameter does not respond_to? to_date" unless date.respond_to?(:to_date)
        { :conditions => ["#{self.historical_date_col_sql} >= ?", date.to_date] }
      }

      scope :opt, lambda {|attributes_for_select| {:select => [:snapshot_date, attributes_for_select].flatten.uniq.join(', ') } }

      # validations
      validate :valid_date?, :on => :save
      nil
    end
  end

  module DynamicClassMethods
    def historical_date_col_sql
      "`#{self.table_name}`.`#{self.historical_date_col}`"
    end

    def tolerance_to_range(date,range)
      if range.is_a?(Numeric)
        range = (date - range)..(date + range)
      elsif range.respond_to?(:to_date_range)
        range = range.to_date_range
      elsif range.is_a?(Range)
        range
      end
    end
  end

  module InstanceMethods
    def valid_date?
      if self.to_date.nil?
        errors.add_to_base('date missing')
        return false
      end
      if self.to_date >= Date.tomorrow
        errors.add_to_base('date is in future')
        return false
      end
      true
    end

    def previous; find_record_at(snapshot_date - 1);   end
    def next;     find_record_at(snapshot_date + 1);   end

    # override with your date implementation. eg. Weekday
    #
    #def snapshot_date
    #  self[self.class.historical_date_col]
    #end

    def to_date
      snapshot_date and snapshot_date.to_date
    end

    private

    def find_record_at(date)
      self.class.on_date(date).same_scope(self).find(:first)
    end
  end
end

ActiveRecord::Base.send :include, ActsAsHistorical
