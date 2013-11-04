module VisibilityHelper
  
  ######################
  # we need a custom getter/setter for the visibility field to make it easier to map integers to values
  def visibility
    viz=SolrDocument.visibility_mappings.invert[visibility_value.to_s]
    viz ? viz.to_sym : :visible  # if we don't have any value, its visible
  end

  def visibility=(value)
    self.visibility_value = SolrDocument.visibility_mappings[value.to_sym]
  end  
  ######################

end