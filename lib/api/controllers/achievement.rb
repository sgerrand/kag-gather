require 'api/controllers/base'
module KAG
  module API
    module Controller
      class Achievement < Base
        @@class_key = 'Achievement'
        @@primary_key = :name

        def get
          if @params[:id]
            self.read(@params[:id])
          elsif @params[:code]
            @@primary_key = :code
            self.read(@params[:code])
          else
            self.list
          end
        end

        def read(id)
          if @@primary_key == :code
            ach = ::Achievement.where('code = ?',@params[:code]).first
          else
            ach = ::Achievement.where(:id => id).first
          end
          if ach
            d = SymbolTable.new(ach.attributes)
            d[:users] = {}
            ach.users.each do |u|
              d[:users][u.name] = {
                  :name => u.name,
                  :score => u.score,
                  :rank => u.rank,
                  :value => u.value
              }
            end
            self.success('',d)
          else
            self.failure('err_nf',clan)
          end
        end

        def list
          limit = @params[:limit] || 25
          start = @params[:start] || 0

          total = ::Achievement.count
          achievements = ::Achievement.order('name ASC').offset(start).limit(limit)
          if achievements
            list = []
            achievements.each do |achievement|
              data = SymbolTable.new(achievement.attributes)
              data[:users] = achievement.users_as_list
              list << data
            end
            self.collection(list,total)
          else
            self.failure('err_nf',c)
          end
        end

      end
    end
  end
end