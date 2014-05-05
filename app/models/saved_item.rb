class SavedItem < WithSolrDocument
  
  belongs_to :gallery
  belongs_to :item, :foreign_key=>:druid, :primary_key=>:druid
 
  include RankedModel
  ranks :row_order,:column => :position, :with_same => :gallery_id
  
  attr_accessible :druid, :gallery_id, :description
  validates :gallery_id, :numericality => { :only_integer => true }
  validates :druid, :is_druid=>true
  validate :only_one_saved_item_per_druid_per_gallery, :on => :create
    
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

  def self.save_favorite(params={})
    user_id=params[:user_id]
    druid=params[:druid]
    description=params[:description]
    gallery=Gallery.get_favorites_list(user_id) # creates the default favorites list if it does not exist
    return self.create(:druid=>druid,:gallery_id=>gallery.id,:description=>description)
  end

  def self.save_to_gallery(params={})
    druid=params[:druid]
    description=params[:description]
    gallery_id=params[:gallery_id]
    return self.create(:druid=>druid,:gallery_id=>gallery_id,:description=>description)
  end
    
  def self.remove_favorite(params={})
    user_id=params[:user_id]
    druid=params[:druid]
    gallery=Gallery.get_favorites_list(user_id) 
    self.where(:druid=>druid,:gallery_id=>gallery.id).limit(1).first.destroy if gallery
  end
  
  def self.get_favorites(user_id)
    Gallery.get_favorites_list(user_id).saved_items
  end
  
  def only_one_saved_item_per_druid_per_gallery
    errors.add(:druid, :cannot_be_more_than_one_saved_item_per_druid_per_gallery) if self.class.where(:druid=>self.druid,:gallery_id=>self.gallery_id).size != 0
  end
  
  def self.find_by_id(id)
    return self.where(:id=>id).first
  end
  
end
