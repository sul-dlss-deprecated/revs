require "spec_helper"

describe "Routing Collections" do
  it "should route /collections properly to the configured field and values for indetifying collections" do
    expect(:get => "/collections").to route_to(:controller => "catalog",
                                               :action => "index",
                                               :f => {CatalogController.blacklight_config.collection_identifying_field => [CatalogController.blacklight_config.collection_identifying_value]}
                                              )
  end
end