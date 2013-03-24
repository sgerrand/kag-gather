require 'symboltable'
require 'kag/data'
require 'kag/config'

module KAG
  class Report < SymbolTable

    def initialize(gather,m,user)
      hash = {
        :nick => user.nick,
        :authname => user.authname,
        :host => user.host,
        :realname => user.realname,
        :gather => gather,
        :message => m,
        :count => 1
      }
      super(hash)
      _ensure_data
      if reported?
        if can_report?
          if past_threshold?
            ignore
          else
            up_report_count
          end
        else
          self.gather.reply self.message,"You have already reported #{self[:nick]}. You can only report a user once."
        end
      else
        report
      end
    end

    def can_report?
      r = _report
      if r and r[:reporters]
        !r[:reporters].include?(self.message.user.authname)
      else
        true
      end
    end

    def _ensure_data
      data[:reported] = {} unless data[:reported]
      data[:ignored] = {} unless data[:ignored]
    end

    def reported?
      data[:reported].key?(self[:host].to_sym)
    end

    def report
      puts self.message.inspect
      c = self.dup
      c.delete(:gather)
      c.delete(:message)
      c[:reporters] = [self.message.user.authname]
      data[:reported][self[:host].to_sym] = c
      data.save

      self.gather.reply self.message,"User #{self[:nick]} reported." if self.gather.class == KAG::Gather
    end

    def ignore
      c = self.clone
      c.delete(:gather)
      c.delete(:message)
      data[:ignored][self[:host].to_sym] = c
      data.save
      self.gather.reply self.message,"User #{self[:nick]} ignored." if self.gather.class == KAG::Gather
    end

    def past_threshold?
      _report[:count].to_i > KAG::Config.instance[:report_threshold].to_i
    end

    def up_report_count
      _report[:count] = _report[:count].to_i + 1
      _report[:reporters] = [] unless _report[:reporters]
      _report[:reporters] << self.message.user.authname
      data.save

      self.gather.reply message,"User #{self[:nick]} reported. #{self[:nick]} has now been reported #{data[:reported][self[:host].to_sym][:count]} times." if self.gather.class == KAG::Gather
    end

    def self.ignore(gather,message,user)
      KAG::Config.data[:ignored] = {} unless KAG::Config.data[:ignored]
      if KAG::Config.data[:ignored] and !KAG::Config.data[:ignored].key?(user.host.to_sym)
        c = SymbolTable.new({
          :nick => user.nick,
          :authname => user.authname,
          :host => user.host,
          :realname => user.realname,
          :gather => gather,
          :message => message,
          :reporters => [message.user.authname]
        })
        KAG::Config.data[:ignored][user.host.to_sym] = c
        KAG::Config.data.save

        gather.reply message,"User #{user.nick} added to ignore list." if gather.class == KAG::Gather
        true
      else
        gather.reply message,"User #{user.nick} already in ignore list!" if gather.class == KAG::Gather
        false
      end
    end

    def self.remove(gather,message,user)
      if KAG::Config.data[:reported] and KAG::Config.data[:reported].key?(user.host.to_sym)
        KAG::Config.data[:reported].delete(user.host.to_sym)
        KAG::Config.data.save

        gather.reply message,"User #{user.nick} removed from report list." if gather.class == KAG::Gather
        true
      else
        gather.reply message,"User #{user.nick} not in report list!" if gather.class == KAG::Gather
        false
      end
    end

    def self.unignore(gather,message,user)
      if KAG::Config.data[:ignored] and KAG::Config.data[:ignored].key?(user.host.to_sym)
        KAG::Config.data[:ignored].delete(user.host.to_sym)
        KAG::Config.data.save

        gather.reply message,"User #{user.nick} removed from ignore list." if gather.class == KAG::Gather
        true
      else
        gather.reply message,"User #{user.nick} not in ignore list!" if gather.class == KAG::Gather
        false
      end
    end

    protected

    def data
      KAG::Config.data
    end

    def _report
      data[:reported][self[:host].to_sym]
    end
  end
end