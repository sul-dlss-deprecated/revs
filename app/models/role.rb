class Role < ActiveRecord::Base

  attr_accessible :id,:name
  
  has_many :users

  def self.admin
    @admin ||= Role.find_by_name('Admin')
  end

  def self.curator
    @curator ||= Role.find_by_name('Curator')
  end

  def self.user
    @user ||= Role.find_by_name('User')
  end

end

