# Changelog for KAG Gather Bot

## 2.0
- Add in-game sub requests via !rsub [player-to-sub-out]
- Full ignore/ban support, as well as !report for reporting players
- Link your IRC authname to your KAG account for better stats management via sso.kag2d.com
- Converted data storage to mysql for easier searching of stats overall architectural scalability
- Added WARMUP mode in matches, !ready to start round
- Used multithreading to properly handle RCON connections for multiple matches
- Proper control of servers via RCON, match flow control

## 1.5
* Refresh users on commands to better handle authname checks
* Remove users from queue after being idle 30 minutes (configurable)
* Gather-wide stats via !stats
* Match logging for history

## 1.4
* !stats [nick] for user-specific stats
* User-specific stats (for now only match counts)
* Lots of refactoring to move away from using nick to more proper authname
* Related, bot now requires AUTH to IRC server to use it

## 1.3
* Command-specific help via !help
* Total refactoring to use submodules to make for easier code grokking
* Add !report_count for getting number of times a user has been reported
* Fix issue where server2 was always picked if no matches started
* Fix issue where delay in match start was not resetting queue fast enough
* Add !report [nick] to report abusive/improper players. After X number of reports (default 7), player is ignored in gather
* Add data-storage framework
* Add !unreport, !ignore
* Add basic channel commands
* Add admin-only !hostname [nick] and !authname [nick] methods
* Add !is_admin [nick] to see who is an admin

## 1.2

* Add !kick_from_match [nick]
* Add !add_silent and !rem_silent to add/remove people from queue, without sending channel msg
* Add !restart_map/!next_map methods that will restart/next map for active match
* Add !reload_config method to dynamically reload config.json on the fly
* Add !help for list of commands
* Add !sub support if someone

## 1.1

* Add admin-only !add [nick] and !rem [nick] commands
* Add !clear method to clear the current queue
* Add !restart/!quit method for bot control
* Add unit tests via rspec
* Configurable !end vote threshold for ending a match (defaults to 3)

## 1.0

* Random-class assignments (optional)
* !end, when passed, kicks all remaining players from server if RCON is setup
* Auth-based nick management, so people can't spoof nicks
* Full KAG API support via Kagerator
* RCON support via managed TCP sockets to prevent game lag and memory leaking
* Add all prior-bot existing functionality
