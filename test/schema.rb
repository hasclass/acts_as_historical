ActiveRecord::Schema.define(:version => 0) do  
  create_table :records, :force => true do |t|     
    t.date :snapshot_date  
  end 
  create_table :record_weekdays, :force => true do |t|     
    t.date :snapshot_date  
  end 
end