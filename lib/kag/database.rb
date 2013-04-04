require 'kag/config'
require 'active_record'
require 'symboltable'
require 'logger'

ActiveRecord::Base.logger = Logger.new('debug.log')
config = KAG::Config.instance['database']
#ActiveRecord::Base.configurations = config
db = config[:development]
ActiveRecord::Base.establish_connection(
  :adapter => db[:adapter].to_sym,
  :host => db[:host].to_s,
  :database => db[:database].to_s,
  :username => db[:username].to_s,
  :password => db[:password].to_s,
  :pool => db[:pool].to_i,
  :timeout => db[:timeout].to_i

)
#ActiveRecord::Base.table_name_prefix = config[:development][:table_name_prefix]
