require File.dirname(__FILE__) + '/test_helper.rb'

class ActsAsHistoricalTest < ActiveSupport::TestCase
  load_schema

  class Record < ActiveRecord::Base
    acts_as_historical
  end

  def test_schema_has_loaded_correctly
    assert Record.all
  end

  def test_to_date
    date = Date.today
    assert_equal Record.create(:snapshot_date => date).to_date, date
  end

  context "Record" do
    should "have default date = snapshot_date" do
      assert_equal 'snapshot_date', Record.historical_date_col
    end
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

    context "newest" do
      should "be friday" do
        assert_equal @r_fri, Record.newest.first
      end
    end

    context "oldest" do
      should "be monday" do
        assert_equal @r_mon, Record.oldest.first
      end
    end

    context "upto" do
      should "return records upto date excluding date" do
        assert Record.upto(@tue).include?(@r_mon)
        assert !Record.upto(@tue).include?(@r_tue)
        assert !Record.upto(@tue).include?(@r_wed)
      end
    end

    context "upto_including" do
      should "return records upto and including given date" do
        records = Record.upto_including(@tue)
        assert  records.include?(@r_mon)
        assert  records.include?(@r_tue)
        assert !records.include?(@r_wed)
      end
    end

    context "from_including" do
      should "return records from including given date" do
        records = Record.from_including(@tue)
        assert !records.include?(@r_mon)
        assert  records.include?(@r_tue)
        assert  records.include?(@r_wed)
      end
    end

    context "from" do
      should "return records from excluding given date" do
        records = Record.from(@tue)
        assert !records.include?(@r_mon)
        assert !records.include?(@r_tue)
        assert  records.include?(@r_wed)
      end
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

    context "between" do
      setup { @records = Record.between(@tue, @wed)}

      should "include only days within range" do
        assert  @records.include?(@r_tue)
        assert  @records.include?(@r_wed)
        assert !@records.include?(@r_mon)
        assert !@records.include?(@r_thu)
        assert !@records.include?(@r_fri)
      end

      should "return record when range start and end are the same" do
        assert Record.between(@mon, @mon).include?(@r_mon)
      end
    end
  end
end
