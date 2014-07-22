class Admin::OntologiesController < AdminController 

  def index
  	@all_fields=Ontology.uniq.pluck(:field) # distinct fields
  	if @all_fields.size > 0
	  @field=params[:field] || @all_fields.first	  	
	  @terms=Ontology.where(:field=>@field).order('value ASC').map {|term| term.value}.join("\n")
  	end
  end

  def create
  	@term=Ontology.create(:field=>params[:field],:value=>'enter values here')
  	redirect_to admin_ontologies_path(:field=>params[:field])
  end

  def update_terms
  	@field=params[:field]
  	@terms=params[:terms].split("\n")
  	Ontology.where(:field=>@field).destroy_all # remove existing terms for this field
  	# add all terms submitted
  	@terms.each {|term| Ontology.create(:field=>@field,:value=>term.strip) unless term.strip.blank?}
  	flash[:success]=I18n.t('revs.admin.terms_updated',:field=>@field,:num=>@terms.size)
  	redirect_to admin_ontologies_path(:field=>@field)
  end

end