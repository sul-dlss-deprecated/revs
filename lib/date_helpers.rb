module DateHelpers
    
  def show_as_date(datetime)
    datetime.nil? ? "" : date_object(datetime).strftime('%B %e, %Y')  
  end

  def show_as_datetime(datetime)
    datetime.nil? ? "" : date_object(datetime).strftime('%B %e, %Y')  
  end

  def date_object(input)
    if input.class == String
      begin
        return Date.parse(input)
      rescue
        return nil
      end
    end
    return input
  end
  
  # tell us if the string passed is a valid year
  def is_valid_year?(date_string)
    date_string.scan(/\D/).empty? and (1800..Date.today.year).include?(date_string.to_i)
  end

  # tell us if the string passed is in is a full date of the format M/D/YYYY, and returns the date object if it is valid
  def get_full_date(date_string)
    begin
      return Date.strptime date_string.gsub('-','/').delete(' '), '%m/%d/%Y'
    rescue
      false
    end
  end
  
end