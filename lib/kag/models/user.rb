require 'kag/models/model'
##
# Abstraction of a User record
#
class User < KAG::Model
  has_many :players
  has_many :matches, :through => :players
  has_many :gather_queue_players
  has_many :queues, :through => :gather_queue_players
  has_many :user_stats

  class << self
    ##
    # Create a new User record from a Cinch::User
    #
    # @param [Cinch::User] user
    # @return [Boolean|User]
    #
    def create(user)
      u = User.new
      u.authname = user.authname
      u.nick = user.nick
      u.host = user.host
      u.created_at = Time.now
      if u.save
        u
      else
        false
      end
    end

    ##
    # Fetch the User object for a authname or user
    #
    # @param [String|Symbol|Cinch::User]
    # @return [User|Boolean]
    #
    def fetch(user)
      return user if user.class == User
      if user.class == String
        authname = user
      else
        return false unless user.authed?
        authname = user.authname
      end

      u = User.find_by_authname(authname)
      if !u and user.class == String
        u = User.find_by_kag_user(authname)
      end
      unless u
        u = User.new({
          :authname => user.class == String ? user : user.authname,
          :nick => user.class == String ? user : user.nick,
          :kag_user => "",
          :host => user.class == String ? '' : user.host,
          :created_at => Time.now,
        })
        u.save
      end
      u
    end
  end

  ##
  # See if the user is linked
  #
  # @return [Boolean]
  #
  def linked?
    u.kag_user != '' and !u.kag_user.nil?
  end

  ##
  # Unlink the user from their KAG account
  #
  # @return [Boolean]
  #
  def unlink
    u.kag_user = ""
    u.save
  end

  ##
  # Get the stats for the user
  #
  # @param [Boolean] bust_cache
  # @return [Array]
  #
  def stats(bust_cache = true)
    self.user_stats(bust_cache)
  end

  ##
  # Get the stats text for the user
  #
  # @return [String]
  #
  def stats_text
    kd_ratio = self.stat("kills").to_s+'/'+self.stat("deaths").to_s
    "#{self.authname} has played in #{self.matches(true).count.to_s} matches, with a K/D ratio of: #{kd_ratio}"
  end

  ##
  # Get a stat value for a user
  #
  # @param [String|Symbol] k
  # @param [Boolean] return_value
  # @return [Integer|Float|UserStat]
  #
  def stat(k,return_value = true)
    s = self.stats.where(:name => k.to_s).first
    if return_value
      if s
        s.value
      else
        0
      end
    else
      s
    end
  end

  ##
  # Set the stat for the user for a key
  #
  # @param [String|Symbol] k
  # @param [Integer|Float|String] v
  # @return [Boolean]
  #
  def set_stat(k,v)
    s = self.stat(k,false)
    unless s
      s = UserStat.new({
        :user => self,
        :name => k.to_s,
        :value => 0,
      })
    end
    s.value = v
    s.save
  end

  ##
  # Delete the stat record for a key
  #
  # @param [String|Symbol] k
  # @return [Boolean]
  #
  def delete_stat(k)
    s = self.stat(k,false)
    if s
      s.destroy
    end
  end

  ##
  # Increase a stat value
  #
  # @param [String|Symbol] key
  # @param [Integer] increment
  # @return [Boolean]
  #
  def inc_stat(k,increment = 1)
    s = self.stat(k,false)
    unless s
      s = UserStat.new({
        :user => self,
        :name => k.to_s,
        :value => 0,
      })
    end
    s.value = s.value.to_i+increment.to_i
    s.save
  end

  ##
  # Decrease a stat value
  #
  # @param [String|Symbol] key
  # @param [Integer] decrement
  # @return [Boolean]
  #
  def dec_stat(k,decrement = 1)
    s = self.stat(k,false)
    unless s
      s = UserStat.new({
        :user => self,
        :name => k.to_s,
        :value => 0,
      })
    end
    s.value = s.value.to_i-decrement.to_i
    s.save
  end

  ##
  # Ignore this user
  #
  # @param [Integer] hours
  # @param [String] reason
  # @param [User|String|Cinch::User] creator
  # @return [Boolean]
  #
  def ignore(hours,reason = '',creator = nil)
    Ignore.them(self.authname,hours,reason,creator)
  end

  ##
  # See if this user is ignored
  #
  # @return [Boolean]
  #
  def ignored?
    Ignore.is?(self.authname)
  end
end