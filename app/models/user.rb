class User < ActiveRecord::Base
  include Blacklight::User
  
  def to_s; "";  end
end