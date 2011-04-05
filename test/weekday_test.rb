require 'date_ext'
require File.dirname(__FILE__) + '/test_helper.rb'

class ActsAsHistoricalWeekdayTest < ActiveSupport::TestCase
  load_schema

  class Record < ActiveRecord::Base
    acts_as_historical
    def snapshot_date
      date = super
      date and date.to_weekday
    end
  end

  context 'named_scopes with 5 weekdays' do
    setup {
      Record.delete_all
      @fri = Weekday.new(2009,11,27)
      @mon = Weekday.new(2009,11,30)
      @tue = Weekday.new(2009,12,1)
      @wed = Weekday.new(2009,12,2)
      @thu = Weekday.new(2009,12,3)

      @r_fri = Record.create! :snapshot_date => @fri
      @r_mon = Record.create! :snapshot_date => @mon
      @r_tue = Record.create! :snapshot_date => @tue
      @r_wed = Record.create! :snapshot_date => @wed
      @r_thu = Record.create! :snapshot_date => @thu
    }

    context "snapshot_date" do
      should "return weekday" do
        assert_equal @mon, Record.find(@r_mon).snapshot_date
      end
    end

    context "snapshots over weekend" do
      should "return friday as previous of monday" do
        assert_equal @r_fri, @r_mon.previous
      end

      should "return monday as next of friday" do
        assert_equal @r_mon, @r_fri.next
      end

      should "include friday, monday, tuesday for nearest(monday, 1)" do
        results = Record.nearest(@mon,1)
        assert_equal 3, results.length
        assert results.include?(@r_mon)
        assert results.include?(@r_tue)
        assert results.include?(@r_fri)
      end
    end

    context "tolerance over week" do
      should "work" do
        Record.tolerance_to_range(@mon, 1).include?(@fri)
      end
    end
  end
end
