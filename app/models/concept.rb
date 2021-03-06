class Concept < ActiveRecord::Base
  has_many :answers
  has_many :observations
  
  validates_uniqueness_of :name
  
  def before_save
    self.name = self.name.upcase
  end
  
  def html_name
    self.name.downcase.gsub(" ", "_")
  end

end
