require 'kag/models/model'
require 'kag/models/score/scorer'
require 'open-uri'
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
        if user.authed?
          authname = user.authname
        else
          u = User.find_login_by_host(user.host)
          return false unless u
          authname = u.authname
        end
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

    def login(m)
      m.user.send "Please go to http://stats.gather.kag2d.nl/sso/?t=#{URI::encode(m.user.host)} to link login to your main KAG Account. This will redirect you to a secure, official KAG-sponsored SSO site that keeps your information secure and only on the kag2d.com servers."
    end

    def clear_expired_logins
      User.where('temp_end_at <= ? AND temp = ?',Time.now,true).each do |u|
        u.logout
      end
    end

    def find_login_by_host(host)
      User.where(:host => host,:temp => true).first
    end

    def score(user)
      User.find_by_kag_user(user).do_score
    end

    def rank_top(num,return_string = true)
      users = User.select('GROUP_CONCAT(`kag_user`) AS `kag_user`, `score`').group('score').order('score DESC').limit(num)
      list = []
      idx = 1
      users.each do |u|
        name = u.kag_user.split(',').join(', ')
        if return_string
          list << "##{idx}: #{name} - #{u.score.to_s}"
        else
          list << {:name => name,:score => u.score}
        end
        idx += 1
      end
      return_string ? "TOP 10: #{list.join(' | ')}" : list
    end

    def rescore_all
      User.all.each {|u| u.do_score}
    end
  end

  def name
    self.kag_user.empty? ? self.authname : self.kag_user
  end

  ##
  # See if the user is linked
  #
  # @return [Boolean]
  #
  def linked?
    !self.kag_user.nil? and !self.kag_user.to_s.empty?
  end

  ##
  # Unlink the user from their KAG account
  #
  # @return [Boolean]
  #
  def unlink
    self.kag_user = ''
    self.save
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
    wl_ratio = self.stat('wins').to_s+'/'+self.stat('losses').to_s

    t = []
    self.stats(true).each do |stat|
      t << "#{stat.name} #{stat.value}"
    end

    "#{self.authname} has played in #{self.matches(true).count.to_s} matches, with a W/L ratio of: #{wl_ratio}. Other stats: #{t.join(', ')}"
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
    Ignore.is_ignored?(self.authname)
  end

  def authed?
    !self.authname.to_s.empty?
  end

  def logout
    self.queues.each do |q|
      q.remove(self)
    end

    self.authname = ''
    self.nick = ''
    self.host = ''
    self.save
  end

  def synchronize(user)
    self.nick = user.nick
    self.host = user.host
    self.save
  end

  def do_score
    KAG::Scorer.score(self)
  end

  def rank
    User.where('score > ?',self.score).count + 1
  end
end