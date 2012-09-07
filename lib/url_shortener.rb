class UrlShortener
  
  def self.get_next_words
    #To deterine which words to combine next, look at the descrcipor and noun from the last url input.
    descriptor = Url.last.descriptor
    noun       = Url.last.noun
    short      = Url.last.short

    #Initialize two arrays for all descriptor and noun words for state that will be determined in get_state_options
    #states are combinatinos of descriptor and noun lenghts and are defined in application.rb
    descriptor_options, noun_options = get_state_options(descriptor, noun)

    #get index numbers for last descriptor & noun in their options array
    descriptor_index = descriptor_options.index("#{descriptor}")
    noun_index       = noun_options.index("#{noun}")

    #If the descriptor or the noun is not in the descriptor/noun array for current state, then you're at the start of this state and return the first descriptor/noun pair
    return descriptor_options[0], noun_options[0], form_short(descriptor_options[0], noun_options[0]) if noun_index.nil? || descriptor_index.nil?


    #Now loop through which ever array (descriptors or nouns) that has more words to make sure every possible combination is used.
    #This changes per state, sometimes the number of nouns is higher than descriptors, sometimes more descriptors than nouns
    #The current style is, if there are more descriptors

    #If the size of the descriptor options array is greater than the noun's
    if descriptor_options.size > noun_options.size
      #And you've reached the last noun, for instance 'zip' in a three letter noun state
      if noun_index == noun_options.size-1
        #move to the next descriptor in the descriptor options list
        descriptor = descriptor_options[descriptor_index+1]
        #and return to the beginning of the noun list
        noun_options[0]
      else
        #otherwise go to next noun
        noun = noun_options[noun_index +1]
      end
    else #If the size of the nouns options array is greater than the descriptor's
      #If the last descriptor in the descriptor options is reached, 
      if descriptor_index == descriptor_options.size-1
        #move to the next noun in the noun options list
        noun = noun_options[noun_index+1]
        #and return to the beginning of the descriptor list
        descriptor = descriptor_options[0]
      else #otherwise go to the next descriptor
        descriptor = descriptor_options[descriptor_index +1]
      end
    end
    #now you have the right descriptor and noun for creating a short url
    short = form_short(descriptor, noun)
    return descriptor, noun, short
  end
  
  def self.form_short descriptor, noun
    #Get the part of speech for the descriptor in order to determine order of words
    descriptor_pos = Word.find_by_word(descriptor).pos
    #pluralize the noun if the lead number is greater than 1
    noun = noun.pluralize unless Rails.cache.read('lead_number') == 1
    short = POS_HASH[descriptor_pos] == 0 ? "#{Rails.cache.read('lead_number')}-#{descriptor}-#{noun}" : "#{Rails.cache.read('lead_number')}-#{noun}-#{descriptor}" 
  end
  
  #Determins the current state and then fetches an array of descriptors and an array of nouns that match the state 
  def self.get_state_options(descriptor, noun)
    #First assign the last state to state variable based on words from last url in db
    state = "#{descriptor.length}-#{noun.length}"
    descriptor_options, noun_options = Rails.cache.fetch("#{state}", :expires_in =>1.week){return_words_array(descriptor.length, noun.length)}   
    #if the descriptor and noun from last url stored are the last elements in the options list, then it's time to change states.
    if descriptor_options.last == descriptor && noun_options.last == noun
      state = get_next_state("#{descriptor.length}-#{noun.length}")
      #Fetch new word options list for new state unless they're already cached
      descriptor_length, noun_length    = state.split("-")
      descriptor_options, noun_options  = Rails.cache.fetch("#{state}", :expires_in =>1.week){return_words_array(descriptor_length, noun_length)}
    end
    Rails.cache.write('state', state)
    return descriptor_options, noun_options
  end
  
  #Called by state options after the correct state is determined 
  def self.return_words_array(descriptor_length, noun_length)
    descriptors = Array.new
    nouns       = Array.new

    #Third person is only good for singular nouns, while lead number increments, use Infinitive instead
    Word.where("span = #{descriptor_length} and pos != 'n' and pos != 'i'").order(:word).each.map{|w| descriptors << w.word } if Rails.cache.read('lead_number') == 1
    Word.where("span = #{descriptor_length} and pos != 'n' and pos != 't'").order(:word).each.map{|w| descriptors << w.word } if Rails.cache.read('lead_number').to_i  > 1
    Word.where("span = #{noun_length} and pos = 'n'").order(:word).each.map{|w| nouns << w.word }
    return descriptors, nouns
  end
  #Called by get_state_options when it determines that a state has expired
  def self.get_next_state state
    #If the current state is the last state, then return to first state and tick lead number up, otherwise return next state
    return next_state = STATES.last == state ? return_first_state_and_increment_lead_number : STATES[STATES.index(state)+1]
  end

  #Called after the last state is reached. The lead number is incremented and the first state starts again
  def self.return_first_state_and_increment_lead_number
    Rails.cache.clear #Clear cache when incrementing lead number so that infinitive is used instead of third person tense
    last_lead_number = Url.last.short.match(/^\d+/).to_s.to_i + 1
    Rails.cache.write("lead_number", last_lead_number)
    STATES[0]
  end

  #Short urls are generated based partly on the last url in the urls table. If this is the first url,
  #then select the first descirptor and first noun of the first state.
  def self.get_first_words_ever
    descriptor, noun  = Word.first(:conditions => ["span = 3 and pos != 'n'"]).word, Word.first(:conditions => ["span = 3 and pos = 'n'"]).word
    Rails.cache.write('lead_number', 1)
    short = form_short(descriptor, noun)
    return descriptor, noun, short
  end
  
  #Changes instances where a user may have typed a 0 instead of the letter O or vice-versa
  def self.clean_short_url short_url
    sections = short_url.split(/-/)
    sections[0].gsub!(/(o)/i,"0")
    short_url =  "#{sections[0]}-#{sections[1..2].join('-').gsub('0','o')}"
  end
end