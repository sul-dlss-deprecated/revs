class Gallery < ActiveRecord::Base
  
  belongs_to :user
  extend FriendlyId
  friendly_id :title, :use => [:slugged]

  include RankedModel
  ranks :row_order,:column => :position

  has_many :saved_items, :order=>"position ASC", :dependent => :destroy

  GALLERY_TYPES=%w{favorites user}

  attr_accessible :user_id,:public,:title,:description,:gallery_type,:views
  
  validate :check_gallery_type
  validates :title, :presence=>true
  validates :user_id, :numericality => { :only_integer => true }
  validate :only_one_favorites_list_per_user
  
  def image
    item=saved_items.limit(1)
    item.size == 0 ? nil : item.first.solr_document.images.first
  end

  def only_one_favorites_list_per_user
    errors.add(:gallery_type, :cannot_be_more_than_one_favorites_list_per_user) if gallery_type.to_s == 'favorites' && self.class.where(:user_id=>self.user_id,:gallery_type=>:favorites).size != 0
  end
  
  def check_gallery_type
    errors.add(:gallery_type, :not_valid) unless GALLERY_TYPES.include? gallery_type.to_s
  end
  
end
