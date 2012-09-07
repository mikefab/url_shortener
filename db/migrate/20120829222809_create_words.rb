class CreateWords < ActiveRecord::Migration
  def change
    create_table :words do |t|
     t.string :word
     t.string :pos
     t.integer :span
    end
    #open a file of English words with parts of speech.
    words = Hash.new
    file = File.new('public/words.txt', "r")
    ActiveRecord::Migration.suppress_messages do
      while (line = file.gets)
        (word, pos, rank, definition) = line.split(/\t/)        #pos is part of speech
        word.downcase!
        if pos.match(/(n|adj)/)  #only want adjectives and nouns
          kind = pos.match(/n/) ? 'n' : 'd' #d is for descriptor (adjectives and verbs cannot overlap)
          #unless words["#{kind}-#{word}"] 
          unless words[word] 
            Word.create!(:word=>word, :pos => pos, :span => word.size) if word.match(/^[a-z]*$/)
            words[word] = 1
          end
        end
      end
    end

    file = File.new('public/verbs.txt', "r")
    ActiveRecord::Migration.suppress_messages do
      while (line = file.gets)
        (infinitive, word, pos) = line.split(/\t/)        #pos is part of speech
        if pos.match(/(gerund|participle|third|infinitive)/)  
          pos = pos[0]        #use first letter of part of speech
          unless words[word]  #d is for descriptor
            Word.create!(:word=>word, :pos => pos, :span => word.size) 
            words[word] = 1
          end
        end
      end
    end
  end
end
