class SavedQuery < ActiveRecord::Base
  
  belongs_to :user
  include RankedModel
  ranks :row_order,:column => :position
  extend FriendlyId
  friendly_id :title, :use=> [:slugged, :finders]
  
  validates :title, :query, :presence=>true
  validates :user_id, :numericality => { :only_integer => true }

  def url
    "/?#{query}"
  end
  
end
