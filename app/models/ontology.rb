class Ontology < ActiveRecord::Base
  
  attr_accessible :field, :value

  include RankedModel
  ranks :row_order,:column => :position, :with_same => :field

  def self.terms(field,term)
  	self.where(:field=>field).where(['value like ?',"#{term}%"]).order('position ASC,value ASC').limit(10)
  end

end
