require 'spec_helper'
require 'kag/bot/bot'

##
# Testing for the server functions
#
describe KAG::Config do
  subject do

  end

  it "ensure new works" do
    d = SymbolTable.new({
        :nick => "test",
        :authname => "test1",
        :host => "127.0.0.1",
        :realname => "Tester McGee",
        :gather => {},
        :message => {},
        :count => 1
    })
    r = KAG::Bans::Report.new({},{},d)
    r.should_not eq(nil)
  end

  it "ensure remove works" do
    u = SymbolTable.new({:nick =>"test",:authname =>"test1"})
    r = KAG::Bans::Report.remove({},{},u)
    r.should eq(true)

  end
end