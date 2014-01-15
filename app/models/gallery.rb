class Gallery < ActiveRecord::Base
  
  belongs_to :user
  has_many :saved_items, :dependent => :destroy
  
  GALLERY_TYPES=%w{favorites user}

  attr_accessible :user_id,:public,:title,:description,:gallery_type
  
  validate :check_gallery_type
  validates :user_id, :numericality => { :only_integer => true }
  validate :only_one_favorites_list_per_user
  
  # returns the default favorites gallery for the given user ID (and create it does not exist) - returns the gallery
  def self.get_favorites_list(user_id)
    gallery=self.where(:user_id=>user_id,:gallery_type=>:favorites).limit(1)
    if gallery.size == 1
      return gallery.first
    else
      return self.create(:user_id=>user_id,:gallery_type=>:favorites)
    end
  end
  
  def only_one_favorites_list_per_user
    errors.add(:gallery_type, :cannot_be_more_than_one_favorites_list_per_user) if self.class.where(:user_id=>self.user_id,:gallery_type=>:favorites).size != 0
  end
  
  def check_gallery_type
    errors.add(:gallery_type, :not_valid) unless GALLERY_TYPES.include? gallery_type.to_s
  end
  
end
