module KAG
  module Test
    class MatchSetup
      attr_accessor :server,:queue,:match,:players,:listener,:parser

      def start_match(shuffle_teams = true)
        self.server = ::Server.new
        self.server.name = 'test'
        self.server.ip = '127.0.0.1'
        self.server.port = 50301
        self.server.password = '1234'
        unless self.server.save
          raise 'Failed to save server'
        end

        self.queue = ::GatherQueue.first

        player_list = %w(Geti splittingred Ardivaba killatron Verra Cpa3y Kalikst Vidar Ezreli Furai)
        KAG::Config.instance[:match_size] = 10

        self.players = []
        player_list.each do |p|
          u = ::User.new
          u.authname = p
          u.nick = p
          u.kag_user = p
          if u.save
            p = ::GatherQueuePlayer.new
            p.gather_queue_id = self.queue.id
            p.user_id = u.id
            self.players << p
          end
        end

        self.match = ::Match.new({
           :server => self.server
        })
        self.match.setup_teams(self.players,shuffle_teams)
        unless self.match.save
          raise 'Failed to save match'
        end

        self.server.match_in_progress = self.match
        self.server.in_use = self.match.id
        self.server.match_data = SymbolTable.new
        unless self.server.save
          raise 'Failed to save server again'
        end
        self.server.match

        self.listener = KAG::Server::Listener.new(self.server)
        self.parser = KAG::Server::Parser.new(self.listener,self.listener.data)
        self.parser.test = true
        self.parser
      end
    end
  end
end