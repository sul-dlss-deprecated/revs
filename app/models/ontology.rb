class Ontology < ActiveRecord::Base
  
  include RankedModel
  ranks :row_order,:column => :position, :with_same => :field

  def self.terms(field,term)
  	self.where(:field=>field).where(['value like ?',"#{term}%"]).order('value ASC').limit(50)
  end

end
