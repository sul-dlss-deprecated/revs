class SavedItem < WithSolrDocument
  
  belongs_to :gallery
  belongs_to :item, :foreign_key=>:druid, :primary_key=>:druid
 
  include RankedModel
  ranks :row_order,:column => :position, :with_same => :gallery_id
  
  after_save :update_gallery_last_updated

  attr_accessible :druid, :gallery_id, :description
  validates :gallery_id, :numericality => { :only_integer => true }
  validates :druid, :is_druid=>true
  validate :only_one_saved_item_per_druid_per_gallery
    
  ##### class level methods
  def self.save_favorite(params={})
    user_id=params[:user_id]
    druid=params[:druid]
    description=params[:description]
    gallery=User.find(user_id).favorites_list
    return self.create(:druid=>druid,:gallery_id=>gallery.id,:description=>description)
  end

  def self.save_to_gallery(params={})
    druid=params[:druid]
    description=params[:description]
    gallery_id=params[:gallery_id]
    user_id=params[:user_id]

    if user_id && user_id != Gallery.find(gallery_id).user_id# if we are supplied with a user_id, confirm the gallery we are saving to is owned by the user
      saved_item=self.new
      saved_item.errors.add(:gallery_id)
    else
      saved_item=self.create(:druid=>druid,:gallery_id=>gallery_id,:description=>description)
    end

    saved_item

  end
    
  def self.remove_favorite(params={})
    user_id=params[:user_id]
    druid=params[:druid]
    gallery=User.find(user_id).favorites_list
    return self.where(:druid=>druid,:gallery_id=>gallery.id).limit(1).first.destroy
  end
  ######

  # when you create/update a saved item, lets touch the gallery so we can keep track of when it was last updated
  def update_gallery_last_updated
    gallery.touch
  end

  # some helper methods to connect us to the user this saved_item belongs to (which we need to go through the gallery to get to)
  def user
    gallery.user
  end
  
  def user_id
    user.id
  end
  
  def image
    self.solr_document.images.first
  end

  def title
    self.solr_document.title
  end
  
  def only_one_saved_item_per_druid_per_gallery
    scoped=self.class.where(:druid=>self.druid,:gallery_id=>self.gallery_id)
    scoped=scoped.where('id != ?',self.id) if self.id
    errors.add(:druid, :cannot_be_more_than_one_saved_item_per_druid_per_gallery) if scoped.size != 0
  end
  
end
