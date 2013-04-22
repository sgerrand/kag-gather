require 'cinch'
require 'kag/common'
require 'commands/help'

module KAG
  module Help
    class Plugin
      include Cinch::Plugin
      include Cinch::Commands
      include KAG::Common
      hook :pre,method: :auth
      hook :post, method: :close_db_connection

      command :help,{},
        summary: 'Get general help on KAG Gather'
      def help(m)
        if m.user.authed?
          m.user.send(_h('general_help',{
            :nick => m.user.nick
          }))
        else
          m.user.send(_h('general_not_authed',{
            :nick => m.user.nick
          }))
        end
      end

      command :help_auth,{},
        summary: 'Get help on using the AUTH system to permanently login.'
      def help_auth(m)
        m.user.send(_h('help_auth',{
          :nick => m.user.nick
        }))
      end

      command :reload_lexicon,{},
        summary: 'Reload the lexicon.',
        admin: true
      def reload_lexicon(m)
        KAG::Help::Book.instance.reload
        m.user.send 'Reloaded lexicon.'
      end
    end
  end
end