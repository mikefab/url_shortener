require 'spec_helper'

describe Url do    
  describe "generate records on a clean database" do
    before(:each) do
      Rails.cache.clear
    end
    it "should gerate a new record that contains a preceding '1' and a singular noun" do
     u = Url.find_or_create_by_name("http://www.1.com")
     u.short.should match(/^1/)
     u.short.should match(/-#{u.noun}(-|\b)/)
    end
 
    it "should gerate a second record also with a preceding '1' and a singular noun" do
      u = Url.find_or_create_by_name("http://www.1.com")
      u = Url.find_or_create_by_name("http://www.2.org")
      u = Url.find_or_create_by_name("http://www.3.com")
      u.short.should match(/^1/)
      u.short.should match(/-#{u.noun}(-|\b)/)
    end
  end
   
   #This tests that states change correctly, ie. from 3-3 to 3-4 to 4-3 to 4-4 to 5-3 to 3-5 to 4-5 to 5-4 to 5-5
   describe "rotating through states" do 
     1.upto(STATES.size-1) do |t|
       #Get descriptor and noun sizes for state
       descriptor_size, noun_size = STATES_hash[STATES[t-1]]
       post_descriptor_size, post_noun_size = STATES_hash[STATES[t]]
       it "should change states from #{STATES[t-1]} to #{STATES[t]} after exhuasting  #{STATES[t-1]} combinations" do
         #Get previous state's last descriptor and noun so you can add one record before the change to next state
         descriptor, noun = return_words_by_size(descriptor_size, noun_size)
         ActiveRecord::Migration.suppress_messages do 
           ActiveRecord::Migration.execute("insert into urls (name, descriptor, noun, short)values('http://www.0.com', '#{descriptor}', '#{noun}', '1-#{noun}-#{descriptor}');")
           1.upto(3) do |t|
             u = Url.find_or_create_by_name("http://www.#{t}.com")
             u.descriptor.size.should == post_descriptor_size
             u.noun.size.should       == post_noun_size
           end
         end
       end
     end
   end
   
  it "should generate a new record that contains a preceding '2' and a pluralized noun after simulating end of last state" do
    #get sizes for last state
    descriptor_size, noun_size = STATES_hash[STATES[STATES.size-1]]
    #Get last descriptor and noun for last state
    descriptor, noun = return_words_by_size(descriptor_size, noun_size)
    #insert a record that will allow the next automatically generated record to have an incremented lead number
    ActiveRecord::Migration.execute("insert into urls (name, descriptor, noun, short)values('http://www.0.com', '#{descriptor}', '#{noun}', '1-#{noun}-#{descriptor}');")
    u = Url.find_or_create_by_name("http://www.1.com")
    u = Url.find_or_create_by_name("http://www.2.com")
    u.short.should match(/^2/)

  end

  ##This test takes a while to run
  # it "should, starting from a clean database, exhaust all possible combinations of the first state before changing states" do
  #    Rails.cache.clear
  #    descriptor_size, noun_size = STATES_hash[STATES[0]]
  #    total_descriptors_for_state = Word.where("span = #{descriptor_size} and pos != 'n' and pos != 'i'").size
  #    total_nouns_for_state = Word.where("span = #{noun_size} and pos = 'n'").size
  #    total_combinations_for_first_state = total_descriptors_for_state * total_nouns_for_state
  # 
  #    counter = 0 
  #    (total_combinations_for_first_state+20).times do |t|
  #      u = Url.find_or_create_by_name("http://www.#{t}.com")
  #      counter += 1 if u.descriptor.size == descriptor_size and u.noun.size == noun_size
  #    end
  #    print "#{counter} -- #{total_combinations_for_first_state}"
  #    counter.should == total_combinations_for_first_state
  #  end

   def return_words_by_size descriptor_size, noun_size
     descriptor, noun = Word.where("span = #{descriptor_size} and pos != 'n' and pos != 'i'").order(:word).last.word, Word.where("span = #{noun_size} and pos = 'n'").order(:word).last.word
   end

end
