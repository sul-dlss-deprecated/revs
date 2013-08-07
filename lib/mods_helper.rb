# TODO this is exactly the same code as in pre-assembly, and is used here so we can write correct mods when the user makes changes
require 'countries'

module ModsHelper
        
  # a hash of LC Subject Heading terms and their IDs for linking for "Automobiles" http://id.loc.gov/authorities/subjects/sh85010201.html
  # this is cached and loaded from disk and deserialized back into a hash for performance reasons, then stored as a module
  # level constant so it can be reused throughout the pre-assembly run as a constant
  #  This cached set of terms can be re-generated with "ruby devel/revs_lc_automobile_terms.rb"
  AUTOMOBILE_LC_TERMS= File.open(REVS_LC_TERMS_FILENAME,'rb'){|io| Marshal.load(io)}
  
  # check the incoming format and fix some common issues
  def revs_check_formats(format)
    case format.strip
      when "black-and-white negative"
        "black-and-white negatives"
      when "color negative"
        "color negatives"
      when "slides/color transparency"
        "color transparencies"
      when "color negatives/slides"
        "color negatives"
      when "black-and-white negative strips"
        "black-and-white negatives"
      when "color transparency"
        "color transparencies"
      when "slide"
        "slides"
      else
        format.strip
    end
  end
  
  # lookup the marque sent to see if it matches any known LC terms, trying a few varieties; returns a hash of the term and its ID if match is found, else returns false
  def revs_lookup_marque(marque)
    result=false
    variants1=[marque,marque.capitalize,marque.singularize,marque.pluralize,marque.capitalize.singularize,marque.capitalize.pluralize]
    variants2=[]
    variants1.each do |name| 
      variants2 << "#{name} automobile" 
      variants2 << "#{name} automobiles"
    end
    (variants1+variants2).each do |variant|
      lookup_term=AUTOMOBILE_LC_TERMS[variant]
      if lookup_term
        result={'url'=>lookup_term,'value'=>variant}
        break
      end
    end
    return result
  end # revs_lookup_marque
  
  # check if the string passed is a country name or code -- if so, return the country name, if not a recognized country, return false
  def revs_get_country(name)
    name='US' if name=='USA' # special case; USA is not recognized by the country gem, but US is
    country=Country.find_country_by_name(name.strip) # find it by name
    code=Country.new(name.strip) # find it by code
    if country.nil? && code.data.nil? 
      return false
    else
      return (code.data.nil? ? country.name : code.name)
    end
  end # revs_get_country
  
  # parse a string like this: "San Mateo (Calif.)" to try and figure out if there is any state in there; if found, return the city and state as an array, if none found, return false
  def revs_get_city_state(name)
    state_match=name.match(/[(]\S+[)]/)
    if state_match.nil?
      return false
    else
      first_match=state_match[0]
      state=first_match.gsub(/[()]/,'').strip # remove parens and strip
      city=name.gsub(first_match,'').strip # remove state name from input string and strip
      return [city,state]
    end
  end # revs_get_city_state
  
  # given an abbreviated state name (e.g. "Calif." or "CA") return the full state name (e.g. "California")
  def revs_get_state_name(name)
    test_name=name.gsub('.','').strip.downcase
    us=Country.new('US')
    us.states.each do |key,value|
      if value['name'].downcase.start_with?(test_name) || key.downcase == test_name
        return value['name']
        break
      end
    end
    return name
  end # revs_get_state_name

end # Revs Module  