# To change this template, choose Tools | Templates
# and open the template in the editor.

module ActsAsHistorical

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def acts_as_historical(options = {})
      configuration = { 
        :date_column => "snapshot_date",
        :days => :all_days,
        :scope => nil
      }
      configuration.update(options) if options.is_a?(Hash)

      send :include, InstanceMethods
      send :extend, DynamicClassMethods
      
      case configuration[:days].to_sym
      when :all_days
        send :extend, AllDays::ClassMethods
      when :weekdays
        send :extend, WeekDays::ClassMethods
      end
      self.cattr_accessor :historical_date_col, :historical_scope, :only_weekdays
      self.historical_date_col = configuration[:date_column]
      self.historical_scope    = configuration[:scope]
      
      order_desc = "#{self.historical_date_col_sql} DESC"
      order_asc = "#{self.historical_date_col_sql} ASC"
      
      default_scope :order => order_desc
      
      # named_scopes - sortings
      named_scope :asc,  :order => order_asc
      named_scope :desc, :order => order_desc

      named_scope :oldest,        :limit => 1, :order => order_asc
      named_scope :newest,        :limit => 1
      named_scope :newest_two,    :limit => 2
    
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

      named_scope :at_date, lambda {|date| {
          :conditions => { :snapshot_date => date },
          :limit => 1
      }}

      named_scope :between, lambda {|*args|
        from, to = args
        range = from.to_date..to.to_date
        {
          :conditions => {self.historical_date_col => range }
      }}
      
      
      # nearest(date, 1)
      # nearest(date, (date_from..date_to))
      #
      named_scope :nearest, lambda {|*args| 
        date = args.first.to_date
        range = self.tolerance_to_range(date, args[1])
        
        {
          :conditions => {self.historical_date_col => range},
          :order => ["ABS(DATEDIFF(#{self.historical_date_col_sql}, '#{date.to_s(:db)}')) ASC"]
      }}

      # TODO
      named_scope :until
      named_scope :from
      
      named_scope :opt, lambda {|attributes_for_select| {:select => [:snapshot_date, attributes_for_select].flatten.uniq.join(', ') } }

      # validations
      validate :valid_date?, :on => :save
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
      if self.class.only_weekdays and snapshot_date and snapshot_date.cwday >= 6
        errors.add_to_base('snapshot_date is not a weekday')
        return false
      end
      if self.snapshot_date >= Date.tomorrow
        errors.add_to_base('snapshot_date is in future')
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
  
  module WeekDays
    module ClassMethods
      def step_date(date, step_size)
        date = date + step_size
        while date.cwday > 5
          date = step_size < 0 ? date - 1 : date + 1
        end
        date
      end
    end
  end

end

ActiveRecord::Base.send :include, ActsAsHistorical