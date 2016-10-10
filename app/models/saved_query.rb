class SavedQuery < ActiveRecord::Base

  belongs_to :user
  include RankedModel
  ranks :row_order,:column => :position
  extend FriendlyId
  friendly_id :title, :use=> [:slugged, :finders]

  VISIBILITY_TYPES=%w{public curator}

  scope :public_lists, -> {where(:visibility=>'public',:active=>true)}
  scope :all_lists, -> {where(:active=>true)}

  validates :title, :query, :presence=>true
  validates :user_id, :numericality => { :only_integer => true }
  validate :check_visibility

  def check_visibility
    errors.add(:visibility, :must_be_selected) unless VISIBILITY_TYPES.include? visibility.to_s
  end

  def url
    "/?#{query}"
  end

end
