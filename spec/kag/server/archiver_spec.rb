require 'support/loader'

##
# Testing for the server functions
#
describe KAG::Server::Archiver do

  subject do
    ms = KAG::Test::MatchSetup.new
    ms.start_match(false)
  end

  it 'test archive' do
    subject.parse('[00:00:00] <[=] Vidar> !ready Knight').should eq(:ready)
    subject.live = true
    subject.parse('[00:00:00] [=] Vidar gibbed [CODE] Geti into pieces')
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.parse('[00:00:00] Red Team wins the game!').should eq(:match_win)
    subject.live = true
    subject.parse('[00:00:00] [=] Vidar gibbed [CODE] Geti into pieces').should eq(:gibbed)
    subject.live = true
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.live = true
    subject.parse('[00:00:00] Red Team wins the game!').should eq(:match_win)
    subject.archive

    u = ::User.fetch('Geti')
    u.stat(:deaths).should eq(4)
    u.stat('deaths.gibbed').should eq(2)
    u.stat('deaths.slew').should eq(2)

    u = ::User.fetch('Vidar')
    u.stat(:kills).should eq(4)
    u.stat('kills.gibbed').should eq(2)
    u.stat('kills.slew').should eq(2)

    c = ::Clan.fetch('[=]')
    c.stat(:kills).should eq(4)
    c.stat('kills.gibbed').should eq(2)
    c.stat('kills.slew').should eq(2)
  end

  it 'test killstreak/deathstreak' do
    subject.parse('[00:00:00] <[=] Vidar> !ready Knight').should eq(:ready)
    subject.live = true
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.parse('[00:00:00] [CODE] Geti slew [=] Vidar with his sword').should eq(:slew)
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.parse('[00:00:00] [=] Vidar slew [CODE] Geti with his sword').should eq(:slew)
    subject.parse('[00:00:00] [CODE] Geti slew [=] Vidar with his sword').should eq(:slew)

    subject.live = true
    subject.parse('[00:00:00] Red Team wins the game!').should eq(:match_win)
    subject.archive

    u = ::User.fetch('Vidar')
    u.stat(:killstreaks).should eq(2)
    u.stat(:killstreak_10).should eq(1)
    u.stat(:ended_others_deathstreak).should eq(1)

    u = ::User.fetch('Geti')
    u.stat(:deathstreaks).should eq(1)
    u.stat(:ended_others_killstreak).should eq(2)
  end

  it 'test in-game stat, first_to_ready' do
    subject.parse('[00:00:00] <[=] Vidar> !ready Knight').should eq(:ready)
    subject.parse('[00:00:00] <[=] Vidar> !ready Knight').should eq(:ready)
    subject.archive
    u = ::User.fetch('Vidar')
    u.stat(:first_to_ready).should eq(1)
  end


end