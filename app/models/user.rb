require "digest/md5"
  
class User < ActiveRecord::Base
  unloadable

  attr_accessor :password
  attr_accessible :email, :password, :given_name, :family_name, :privilege_id, :title
  
  validates_uniqueness_of :email
  validates_presence_of :email, :family_name, :given_name

  before_destroy :dont_destroy_admin
  belongs_to :privilege
    
  def before_create
    if self.password.nil?
      errors.add("Must supply a password")
    else
      self.hashed_password = User.hash_password(self.password)      
    end
  end
  
  def after_create
    self.password = nil
  end
  
  def before_update
    unless self.password.nil?
      self.hashed_password = User.hash_password(self.password)
    end
  end
    
  def after_update
    self.password = nil
  end
  
  def self.login(email, password)
    hashed_password = hash_password(password || "")
    find(:first,
         :conditions => ["email = ? and hashed_password = ?", email, hashed_password])
  end
  
  def try_to_login()
    User.login(self.email, self.password)
  end
  
  def full_name
    unless self.title.nil?
      self.given_name + " " + self.family_name + ", " + self.title
    else
      self.given_name + " " + self.family_name
    end
  end
  
  def hl7_name
    unless self.title.nil?
      "#{self.given_name}^#{self.family_name}^#{self.title}"
    else
      "#{self.given_name}^#{self.family_name}"
    end
  end
  
  def dont_destroy_admin
    raise "Can't destroy mkohli@iupui.edu" if self.email == 'mkohli@iupui.edu'
  end
  
  private
  def self.hash_password(password)
    Digest::MD5.hexdigest(password)
  end
    
end

class Provider < User
  unloadable
  has_many :encounters
  has_many :quality_checks
end

class Client < User
  unloadable
  has_many :encounters
end
