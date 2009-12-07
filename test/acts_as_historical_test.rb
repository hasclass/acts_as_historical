require File.dirname(__FILE__) + '/test_helper.rb'

class ActsAsHistoricalTest < ActiveSupport::TestCase
  load_schema 
  
  class Record < ActiveRecord::Base
    acts_as_historical
  end

  class RecordWeekday < ActiveRecord::Base
    acts_as_historical :days => :weekdays
  end
  
  def test_schema_has_loaded_correctly 
    assert Record.all
  end 
  
  def test_to_date
    date = Date.today
    assert_equal Record.create(:snapshot_date => date).to_date, date
  end

  context 'named_scopes with 5 weekdays' do
    setup {
      Record.delete_all
      @mon = Date.new(2009,11,30)
      @tue = Date.new(2009,12,1)
      @wed = Date.new(2009,12,2)
      @thu = Date.new(2009,12,3)
      @fri = Date.new(2009,12,4)
    
      @r_mon = Record.create! :snapshot_date => @mon
      @r_tue = Record.create! :snapshot_date => @tue    
      @r_wed = Record.create! :snapshot_date => @wed
      @r_thu = Record.create! :snapshot_date => @thu
      @r_fri = Record.create! :snapshot_date => @fri      
    }
    
    should "create 5 records" do
      assert_equal 5, Record.count
    end
    
    context "nearest" do
      should "always return monday no matter what tolerance range" do
        assert_equal @r_mon, Record.nearest(@mon-1, 1).first
        assert_equal @r_mon, Record.nearest(@mon, 0).first
        assert_equal @r_mon, Record.nearest(@mon, 1).first
        assert_equal @r_mon, Record.nearest(@mon, 2).first
      end

      should "return nothing when no records within range" do
        Record.stubs(:only_weekdays).returns(false)
        assert Record.nearest(@mon - 1, 0).empty?
        assert Record.nearest(@fri + 1, 0).empty?
      end
    end
  
    context "within" do
      setup { @records = Record.between(@tue, @wed)}
      
      should "include only days within range" do
        assert  @records.include?(@r_tue)
        assert  @records.include?(@r_wed)
        assert !@records.include?(@r_mon)
        assert !@records.include?(@r_thu)
        assert !@records.include?(@r_fri)
      end
      
      should "return record when range start and end are the same" do
        assert  Record.between(@mon, @mon).include?(@r_mon)
      end
    end
  end

  context ":days => :weekdays" do
    context "day present" do
      setup {
        RecordWeekday.delete_all
        @old = RecordWeekday.create! :snapshot_date => Date.new(2009,12,4)
        @new = RecordWeekday.create! :snapshot_date => Date.new(2009,12,7)
      }
      context "#previous" do
        should "return record of previous weekday" do
          assert_equal @old, @new.previous
        end
      end
      context "#next" do
        should "return record of next weekday" do
          assert_equal @new, @old.next
        end
      end
    end
  
    context "day missing" do
      setup {
        RecordWeekday.delete_all
        @record = RecordWeekday.create! :snapshot_date => Date.new(2009,12,3)
      }
      context "#previous" do
        should "return nil if record on previous weekday" do
          assert_equal nil, @record.previous
        end
      end
    
      context "#next" do
        should "return nil if record on next weekday" do
          assert_equal nil, @record.next
        end
      end
    end
  end
  
  context ":days => :all_days" do
    context "day present" do
      setup {
        Record.delete_all
        @old = Record.create! :snapshot_date => Date.new(2009,12,3)
        @new = Record.create! :snapshot_date => Date.new(2009,12,4)
      }
      context "#previous" do
        should "return record of previous day" do
          assert_equal @old, @new.previous
        end
      end
      context "#next" do
        should "return record of next day" do
          assert_equal @new, @old.next
        end
      end
    end
  
    context "day missing" do
      setup {
        Record.delete_all
        @record = Record.create! :snapshot_date => Date.new(2009,12,3)
      }
      context "#previous" do
        should "return nil if record on previous day" do
          assert_equal nil, @record.previous
        end
      end
    
      context "#next" do
        should "return nil if record on next day" do
          assert_equal nil, @record.next
        end
      end
    end
  end



end
