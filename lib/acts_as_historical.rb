
module ActsAsHistorical

  def self.included(base)
    base.extend(ClassMethods)
  end

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
        :
        :scope => nil
      }
      configuration.update(opts) if opts.is_a?(Hash)

      send :include, InstanceMethods
      send :extend, DynamicClassMethods
      
      self.cattr_accessor :historical_date_col, :historical_scope, :only_weekdays
      self.historical_date_col = 'snapshot_date' #configuration[:date_column]
      self.historical_scope    = configuration[:scope]
      
      order_desc = "#{self.historical_date_col_sql} DESC"
      order_asc = "#{self.historical_date_col_sql} ASC"
      
      # named_scopes - sortings
      named_scope :asc,  :order => order_asc
      named_scope :desc, :order => order_desc

      named_scope :oldest,        :limit => 1, :order => order_asc
      named_scope :newest,        :limit => 1, :order => order_desc
      named_scope :newest_two,    :limit => 2, :order => order_desc
    
      # one snapshot per week (every wednesday)      
      named_scope :weekly,
                  :conditions => "DAYOFWEEK(#{self.historical_date_col_sql}) = 2"

      %w[sundays mondays tuesdays wednesdays thursdays fridays saturdays].each_with_index do |name, day_of_week|
        named_scope name,
                    :conditions => "DAYOFWEEK(#{self.historical_date_col_sql}) = #{day_of_week+1}"
      end

      named_scope :within_month, lambda {{
          :conditions => ["#{self.historical_date_col_sql} > ?", Date.today - 30]
      }}

      named_scope :within_year, lambda {{
          :conditions => ["#{self.historical_date_col_sql} > ?", Date.today - 364]
      }}

      named_scope :same_scope, lambda {|record| 
        if self.historical_scope.nil?
          {}
        else
          {:conditions => {self.historical_scope => record[self.historical_scope]} }
        end
      }

      named_scope :on_date, lambda {|date| {
          :conditions => { :snapshot_date => date.to_date },
          :limit => 1
      }}

      named_scope :between, lambda {|*args|
        from, to = args
        range = from.to_date..to.to_date
        { :conditions => {self.historical_date_col => range } }
      }

      # nearest(date, 1)
      # nearest(date, (date_from..date_to))
      #
      named_scope :nearest, lambda {|*args| 
        date, tolerance = args
        range = self.tolerance_to_range(date.to_date, tolerance)
        {
          :conditions => {self.historical_date_col => range},
          :order => ["ABS(DATEDIFF(#{self.historical_date_col_sql}, '#{date.to_date.to_s(:db)}')) ASC"]
        }
      }

      # Does not include date
      # 
      named_scope :upto, lambda {|date| 
        raise "passed parameter does not respond_to? to_date" if date.respond_to?(:to_date)
        { :conditions => ["#{self.historical_date_col_sql} < ?", date.to_date] }
      }

      # Includes date
      #
      named_scope :upto_including, lambda {|date| 
        raise "passed parameter does not respond_to? to_date" if date.respond_to?(:to_date)
        { :conditions => ["#{self.historical_date_col_sql} <= ?", date.to_date] }
      }

      named_scope :from, lambda {|date| 
        raise "passed parameter does not respond_to? to_date" if date.respond_to?(:to_date)
        { :conditions => ["#{self.historical_date_col_sql} > ?", date.to_date] }
      }

      named_scope :from_including, lambda {|date| 
        raise "passed parameter does not respond_to? to_date" if date.respond_to?(:to_date)
        { :conditions => ["#{self.historical_date_col_sql} >= ?", date.to_date] }
      }

      named_scope :opt, lambda {|attributes_for_select| {:select => [:snapshot_date, attributes_for_select].flatten.uniq.join(', ') } }

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
    
    def previous; find_record_at(prev_day);   end
    def next;     find_record_at(next_day);   end

    def to_date
      self.send(self.class.historical_date_col)
    end

    private
    def find_record_at(date)
      self.class.at_date(date).same_scope(self).find(:first)
    end

    def next_day; self.class.step_date(to_date,  1); end
    def prev_day; self.class.step_date(to_date, -1); end  
  end

  module AllDays
    module ClassMethods
      def step_date(date, step_size)
        date + step_size
      end
    end
  end
end

ActiveRecord::Base.send :include, ActsAsHistorical