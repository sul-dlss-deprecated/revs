class Gallery < ActiveRecord::Base

  belongs_to :user
  extend FriendlyId
  friendly_id :title, :use => [:slugged, :finders]

  scope :public_galleries, -> {where(:visibility=>'public',:gallery_type=>'user')}

  include RankedModel
  ranks :row_order,:column => :position, :scope=>:public_galleries

  GALLERY_TYPES=%w{favorites user}
  VISIBILITY_TYPES=%w{public private curator}

  attr_readonly :saved_items_count

  has_many :all_saved_items, :class_name=>'SavedItem', :dependent=>:destroy

  validate :check_gallery_type
  validate :check_visibility

  validates :title, :presence=>true
  validates :user_id, :numericality => { :only_integer => true }
  validate :only_one_favorites_list_per_user

  def self.featured
    self.public_galleries.where(:featured=>true).where('saved_items_count > 0').rank(:row_order)
  end

  def self.curated
    self.public_galleries.joins(:user).where('saved_items_count > 0').where("users.role in ('curator','admin')").rank(:row_order)
  end

  def self.regular_users
    self.public_galleries.joins(:user).where('saved_items_count > 0').where("users.role = 'user'").rank(:row_order)
  end

  def public
    visibility.to_sym == :public
  end

  def image(params={})
    user=params[:user] || nil
    size=params[:size] || :default
    item=saved_items(user).limit(1)
    item.size == 0 ? (size == :large ? 'default-thumbnail_thumb.jpg' : 'default-thumbnail_square.jpg') : item.first.solr_document.images(size).first
  end

  # custom has_many association, so we can add visibility filtering -- get the galleries items, pass in a second user (like the logged in user) to decide if hidden items should be returned as well
  def saved_items(user=nil)
    User.visibility_filter(SavedItem.where(:gallery_id=>id),'saved_items',user).rank(:row_order)
  end

  def only_one_favorites_list_per_user
    errors.add(:gallery_type, :cannot_be_more_than_one_favorites_list_per_user) if gallery_type.to_s == 'favorites' && self.class.where(:user_id=>self.user_id,:gallery_type=>:favorites).size != 0
  end

  def check_gallery_type
    errors.add(:gallery_type, :not_valid) unless GALLERY_TYPES.include? gallery_type.to_s
  end

  def check_visibility
    errors.add(:visibility, :must_be_selected) unless VISIBILITY_TYPES.include? visibility.to_s
  end

end
