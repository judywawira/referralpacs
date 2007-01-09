class Encounter < ActiveRecord::Base
  validates_presence_of :date, :indication, :findings, :impression
  belongs_to :patient
  belongs_to :encounter_type
  has_many :images, :exclusively_dependent => true
end
