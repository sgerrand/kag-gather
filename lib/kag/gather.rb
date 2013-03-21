require 'cinch'
require 'kag/bot'
require 'kag/config'
require 'kag/server'
require 'kag/match'

module KAG
  class Gather
    include Cinch::Plugin

    def config
      KAG::Config.instance
    end

    attr_accessor :queue,:servers

    def initialize(*args)
      super
      @queue = {}
      @matches = {}
      _load_servers
    end

    def _load_servers
      @servers = {}
      KAG::Config.instance[:servers].each do |k,s|
        s[:key] = k
        @servers[k] = KAG::Server.new(s)
      end
    end

    #listen_to :channel, method: :channel_listen
    #def channel_listen(m)
    #end

    listen_to :leaving, method: :on_leaving
    def on_leaving(m,nick)
      match = get_match_in(nick)
      if match
        match.remove_player(nick)
      elsif @queue.key?(nick)
        remove_user_from_queue(nick)
      end
    end

    listen_to :nick, method: :on_nick
    def on_nick(m)
      match = get_match_in(m.user.last_nick)
      if match
        match.rename_player(m.user.last_nick,m.user.nick)
      elsif @queue.key?(m.user.last_nick)
        @queue[m.user.nick] = @queue[m.user.last_nick]
        @queue.delete(m.user.last_nick)
      end
    end

    match "add", method: :evt_add
    def evt_add(m)
      add_user_to_queue(m,m.user.nick)
    end

    match "rem", method: :evt_rem
    def evt_rem(m)
      match = get_match_in(m.user.nick)
      if match
        match.remove_player(m.user.nick)
        send_channels_msg "#{nick} has left the match at #{match.server[:key]}! Find a sub!"
      elsif @queue.key?(user)
        remove_user_from_queue(m.user.nick)
      end
    end

    match "list", method: :evt_list
    def evt_list(m)
      users = []
      @queue.each do |n,u|
        users << n
      end
      m.user.send "Queue (#{KAG::Match.type_as_string}) [#{@queue.length}] #{users.join(", ")}"
    end

    match "status", method: :evt_status
    def evt_status(m)
      reply m,"Matches in progress: #{@matches.length.to_s}"
    end

    match "end", method: :evt_end
    def evt_end(m)
      match = get_match_in(m.user.nick)
      if match
        match.add_end_vote
        if match.voted_to_end?
          match.cease
          @matches.delete(match.server[:key])
          send_channels_msg("Match at #{match.server[:key]} finished!")
        else
          reply m,"End vote started, #{match.get_needed_end_votes_left} more votes to end match at #{match.server[:key]}"
        end
      else
        reply m,"You're not in a match, silly! Stop trying to hack me."
      end
    end

    def add_user_to_queue(m,nick)
      unless @queue.key?(nick) or get_match_in(nick)
        @queue[nick] = SymbolTable.new({
            :user => User(nick),
            :channel => m.channel,
            :message => m.message,
            :joined_at => Time.now
        })
        send_channels_msg "Added #{nick} to queue (#{KAG::Match.type_as_string}) [#{@queue.length}]"
        check_for_new_match
      end
    end

    def remove_user_from_queue(nick)
      if @queue.key?(nick)
        @queue.delete(nick)
        send_channels_msg "Removed #{nick} from queue (#{KAG::Match.type_as_string}) [#{@queue.length}]"
      end
    end

    def get_match_in(nick)
      m = false
      @matches.each do |k,match|
        if match.has_player?(nick)
          m = match
        end
      end
      m
    end

    def check_for_new_match
      if @queue.length >= KAG::Config.instance[:match_size]
        players = []
        @queue.each do |n,i|
          players << n
        end

        server = get_unused_server
        unless server
          send_channels_msg "Could not find any available servers!"
          debug "FAILED TO FIND UNUSED SERVER"
          return false
        end

        match = KAG::Match.new(SymbolTable.new({
          :server => server,
          :players => players
        }))
        match.start
        messages = match.notify_teams_of_match_start
        messages.each do |nick,msg|
          User(nick.to_s).send(msg) unless nick.to_s.include?("player")
          sleep(2)
        end
        send_channels_msg(match.text_for_match_start,false)

        @queue = {}
        @matches[server[:key]] = match
      end
    end

    def send_channels_msg(msg,colorize = true)
      KAG::Config.instance[:channels].each do |c|
        msg = Format(:grey,msg) if colorize
        Channel(c).send(msg)
      end
    end

    def reply(m,msg,colorize = true)
      msg = Format(:grey,msg) if colorize
      m.reply msg
    end

    def get_unused_server
      server = false
      @servers.each do |k,s|
        server = s unless s.in_use?
      end
      server
    end

    match "help", method: :evt_help
    def evt_help(m)
      msg = "Commands: !add, !rem, !list, !status, !help, !end"
      msg = msg + ", !rem [nick], !add [nick], !clear, !restart, !quit" if is_admin(m.user)
      User(m.user.nick).send(msg)
    end

    # admin methods

    def debug(msg)
      if KAG::Config.instance[:debug]
        puts msg
      end
    end

    def is_admin(user)
      user.refresh
      o = (KAG::Config.instance[:owners] or [])
      o.include?(user.authname)
    end

    match "clear", method: :evt_clear
    def evt_clear(m)
      if is_admin(m.user)
        send_channels_msg "Match queue cleared."
        @queue = {}
      end
    end

    match /rem (.+)/, method: :evt_rem_admin
    def evt_rem_admin(m, arg)
      if is_admin(m.user)
        arg = arg.split(" ")
        arg.each do |nick|
          remove_user_from_queue(nick)
        end
      end
    end

    match /add (.+)/, method: :evt_add_admin
    def evt_add_admin(m, arg)
      if is_admin(m.user)
        arg = arg.split(" ")
        arg.each do |nick|
          if m.channel.has_user?(nick)
            add_user_to_queue(m,nick)
          else
            reply m,"User #{nick} is not in this channel!"
          end
        end
      end
    end

    match /is_admin (.+)/, method: :evt_am_i_admin
    def evt_am_i_admin(m,nick)
      u = User(nick)
      if is_admin(u)
        reply m,"Yes, #{nick} is an admin!"
      else
        reply m,"No, #{nick} is not an admin."
      end
    end


    match "quit", method: :evt_quit
    def evt_quit(m)
      if is_admin(m.user)
        m.bot.quit("Shutting down...")
      end
    end

    match "restart", method: :evt_restart
    def evt_restart(m)
      if is_admin(m.user)
        cmd = (KAG::Config.instance[:restart_method] or "nohup sh gather.sh &")
        puts cmd
        pid = spawn cmd
        debug "Restarting bot, new process ID is #{pid.to_s} ..."
        exit
      end
    end

    match "restart_map", method: :evt_restart_map
    def evt_restart_map(m)
      if is_admin(m.user)
        match = get_match_in(m.user.nick)
        if match and match.server
          match.server.restart_map
        end
      end
    end

    match /restart_map (.+)/, method: :evt_restart_map_specify
    def evt_restart_map_specify(m,arg)
      if is_admin(m.user)
        if @servers[key]
          @servers[key].restart_map
        else
          m.reply "No server found with key #{arg}"
        end
      end
    end

    match "next_map", method: :evt_next_map
    def evt_next_map(m)
      if is_admin(m.user)
        match = get_match_in(m.user.nick)
        if match and match.server
          match.server.next_map
        end
      end
    end

    match /next_map (.+)/, method: :evt_next_map_specify
    def evt_next_map_specify(m,arg)
      if is_admin(m.user)
        if @servers[key]
          @servers[key].next_map
        else
          m.reply "No server found with key #{arg}"
        end
      end
    end

    match /kick_from_match (.+)/, method: :evt_kick_from_match
    def evt_kick_from_match(m,nick)
      if is_admin(m.user)
        match = get_match_in(nick)
        if match
          match.remove_player(nick)
          m.reply "#{nick} has been kicked from the match"
        else
          m.reply "#{nick} is not in a match!"
        end
      end
    end

    match "reload_config", method: :evt_reload_config
    def evt_reload_config(m)
      if is_admin(m.user)
        KAG::Config.instance.reload
        m.reply "Configuration reloaded."
      end
    end
  end
end