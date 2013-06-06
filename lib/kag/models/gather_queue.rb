require 'kag/models/model'

class GatherQueue < KAG::Model
  has_many :gather_queue_players
  has_many :users, :through => :gather_queue_players

  def players(bust_cache = false)
    self.gather_queue_players(bust_cache)
  end

  def is_full?
    self.players(true).length >= KAG::Config.instance[:match_size]
  end

  def reset
    GatherQueuePlayer.destroy_all(['gather_queue_id = ?',self.id])
  end

  def player(user)
    self.players(true).joins(:user).where(:users => {:kag_user => user.kag_user}).first
  end

  def has_player?(user)
    !self.player(user).nil?
  end

  def add(user,silent = false,preference = false)
    if self.has_player?(user)
      "#{user.name} is already in the queue!"
    else
      if Player.is_playing?(user)
        "#{user.name} is already in a match!"
      else
        player = GatherQueuePlayer.where(:user_id => user.id).first
        if player # already in queue
          "#{user.name} is already in the queue!"
        else
          gp = GatherQueuePlayer.new({
            :gather_queue_id => self.id,
            :user_id => user.id,
            :created_at => Time.now
          })

          if preference
            preference = preference.to_s.upcase
            unless %w(EU US AUS).include?(preference)
              preference = nil
            end
          end
          gp.server_preference = preference if preference
          added = gp.save
          if added
            preference_vote = preference ? " with vote for #{preference}" : ''
            KAG.gather.send_channels_msg "Added #{user.name} to queue#{preference_vote} (#{::Match.type_as_string}) [#{self.length}]" unless silent
            user.inc_stat(:adds)
            KAG::Stats::Main.add_stat(:adds)
            check_for_new_match
            true
          else
            'Failed to add to queue!'
          end
        end
      end
    end
  end

  def check_for_new_match
    if self.is_full?
      unless self.start_match
        KAG.gather.send_channels_msg 'Could not find any available servers!'
        puts 'FAILED TO FIND UNUSED SERVER'
      end
    end
  end

  def remove(user,silent = false)
    removed = false
    user = SymbolTable.new({:kag_user => user}) if user.class == String
    queue_player = self.player(user)
    if queue_player
      queue_player.destroy
      KAG.gather.send_channels_msg "Removed #{user.name} from queue (#{::Match.type_as_string}) [#{self.length}]" unless silent
      removed = true
    else
      puts "User #{user.name} is not in the queue!"
    end
    removed
  end

  def list
    m = []
    self.users(true).each do |user|
      m << user.name
    end
    m.join(', ')
  end

  def list_text
    "Queue (#{::Match.type_as_string}) [#{self.players.length}] #{self.list}"
  end

  def idle_list
    return false unless KAG.gather and KAG.gather.bot
    list = []
    self.users(true).each do |user|
      irc_user = KAG.gather.bot.user_list.find_ensured(user.nick)
      if irc_user and !irc_user.unknown
        irc_user.refresh
        list << "#{user.nick}: #{irc_user.idle.to_i / 60}m"
      end
    end
    list.join(', ')
  end

  def length
    self.players(true).length
  end

  ##
  # Start the match from the queue and reset it
  #
  def start_match
    server = ::Server.find_unused(self)
    unless server
      return false
    end
    players = self.players(true)

    # reset queue first to prevent 11-player load
    self.reset

    match = ::Match.new({
       :server => server,
    })
    match.setup_teams(players)
    match.notify_players_of_match_start
    match.start
    true
  end
end