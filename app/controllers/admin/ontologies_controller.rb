class Admin::OntologiesController < AdminController 

  def index
  	@all_fields=Ontology.uniq.pluck(:field) # distinct fields
  	if @all_fields.size > 0
	  @field=params[:field] || @all_fields.first	  	
	  @terms=Ontology.where(:field=>@field).order('value ASC').map {|term| term.value}.join("\n")
  	end
  end

  def create
  	@term=Ontology.new
    @term.field=params[:field]
    @term.value='enter values here'
    @term.save
  	redirect_to admin_ontologies_path(:field=>params[:field])
  end

  def update_terms
  	@field=params[:field]
  	@terms=params[:terms].split("\n")
  	Ontology.where(:field=>@field).destroy_all # remove existing terms for this field
  	# add all terms submitted
  	@terms.each do |term|
     unless term.strip.blank?
       ont_term=Ontology.new
       ont_term.field=@field
       ont_term.value=term.strip
       ont_term.save 
     end
    end
  	flash[:success]=I18n.t('revs.admin.terms_updated',:field=>@field,:num=>@terms.size)
  	redirect_to admin_ontologies_path(:field=>@field)
  end

end