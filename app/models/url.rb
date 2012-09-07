class Url < ActiveRecord::Base
  validates_presence_of :name, :on => :create, :message => "can't be blank"
  validates_format_of :name, :with => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix, :on => :create, :message => "must be an authentic url"
  before_create :prepare_record
  
  def prepare_record
    self.descriptor, self.noun, self.short = Url.last.nil? ? UrlShortener.get_first_words_ever : UrlShortener.get_next_words
  end
    

end
