task :exhaust => [:environment] do #This is for conjugations.rb related to clause_extractor gem
  print "xxxxx\n"
  states = [[3,3], [4,3], [3,4], [5,3],  [3,5], [4,4], [5,4], [5,5]]
  hash = {}
  one = Hash.new

  Word.where("span = 4 and pos = 'n'").all.each do |w|
    one[w.word] = Array.new
  end
  Word.where("span = 4 and pos = 'n'").all.each do |w|
    Word.where("span = 4 and pos != 'n'").all.each do |d|
      one[w.word] << d.word
    end
  end
  one.each do |k,v| 
 #   print "#{k} #{v.size}\n"
  end
#  print "#{one.size}\n"
end