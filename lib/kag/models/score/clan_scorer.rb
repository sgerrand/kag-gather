module KAG
  class ClanScorer

    def initialize(clan)
      @clan = clan
      @ratios = SymbolTable.new({
        :win_ratio => 16.0,
        :loss_ratio => 8.0,
        :generic_kill => 6.0,
        :generic_death => 6.0,

        :knight_kill => 12.0,
        :knight_death => 8.0,
        :archer_kill => 5.0,
        :archer_death => 20.0,
        :builder_kill => 18.0,
        :builder_death => 6.0,

        :builder_win => 3.0,
        :builder_loss => 1.5,

        :loss => 2.0,
        :inactive_penalty_multiplier => 25,
        :inactive_penalty_days => 5.00,
        :match_percentage_multiplier => 200,
        :minimum_matches => 10,
        :member_bonus => 2
      })
    end

    ##
    # Calculate score.
    #
    # Subtract class-specific kills/deaths from main kills/deaths total before calculating
    #
    def self.score(clan)
      scorer = self.new(clan)
      scorer.score
    end


    ##
    # Score the user
    #
    def score
      return 0 unless @clan
      score = 0
      stats = @clan.stats_as_hash
      wins = stats['wins'].to_i
      losses = stats['losses'].to_i

      if (wins+losses) >= @ratios[:minimum_matches]

        total_matches = ::Match.where('stats IS NOT NULL AND ended_at IS NOT NULL').count
        player_matches = wins+losses
        percentage_of_matches = (player_matches.to_f / total_matches.to_f)

        win_percentage = wins.to_f / player_matches.to_f
        loss_percentage = (100.00 - (win_percentage*100))/100.00
        if loss_percentage > 0
          win_multiplier = (win_percentage) / (loss_percentage*@ratios[:loss])
        else
          win_multiplier = win_percentage
        end
        puts "#{@clan.name}: (W: #{win_percentage.to_s}) - (L: #{loss_percentage.to_s} * #{@ratios[:loss].to_s}) == #{win_multiplier.to_s}"

        generic_kills = stats['kills'].to_i - stats['archer.kills'].to_i - stats['builder.kills'].to_i - stats['knight.kills'].to_i
        generic_deaths = stats['deaths'].to_i - stats['archer.deaths'].to_i - stats['builder.deaths'].to_i - stats['knight.deaths'].to_i

        if wins > 0 or losses > 0
          win_adder = (wins * @ratios[:win_ratio]) - (losses * @ratios[:loss_ratio]) + (percentage_of_matches * @ratios[:match_percentage_multiplier])
          win_adder2 = win_adder * win_multiplier
          score += win_adder2

          puts "#{@clan.name}:  (#{wins.to_s} * #{@ratios[:win_ratio].to_s}) - (#{losses.to_s} * #{@ratios[:loss_ratio].to_s}) + (#{percentage_of_matches.to_s} * #{@ratios[:match_percentage_multiplier].to_s}) == #{win_adder.to_s} * #{win_multiplier.to_s} == #{win_adder2.to_s}"
        end

        average_members = ActiveRecord::Base.connection.execute('SELECT AVG(`clanCount`) AS `cc` FROM (SELECT COUNT(`clan_id`) AS `clanCount` FROM `users` WHERE `clan_id` != 0 AND `score` > 0 GROUP BY `clan_id`) `c`')
        if average_members
          average_members = average_members.first.first.to_f
          if average_members > 0
            clan_members = @clan.users.where('score > 0').count.to_f
            team_bonus = @ratios[:member_bonus] * (clan_members / average_members)
            puts "Clan/Avg Members: (#{clan_members.to_s} / #{average_members.to_s}) * #{@ratios[:member_bonus]} == #{team_bonus.to_s}"
            score += team_bonus
          end
        end

        b_wins = stats['builder.wins'].to_i
        b_losses = stats['builder.losses'].to_i
        score += (b_wins*@ratios[:builder_win]) # slight bonus to builder wins since builder is less dependent on k/d
        score -= (b_losses*@ratios[:builder_loss]) # slight detract to builder losses since builder is less dependent on k/d

        score += calc_kr_add(@ratios[:generic_kill],@ratios[:generic_death],generic_kills,generic_deaths)
        score += calc_kr_add(@ratios[:knight_kill],@ratios[:knight_death],stats['knight.kills'].to_i,stats['knight.deaths'].to_i)
        score += calc_kr_add(@ratios[:archer_kill],@ratios[:archer_death],stats['archer.kills'].to_i,stats['archer.deaths'].to_i)
        score += calc_kr_add(@ratios[:builder_kill],@ratios[:builder_death],stats['builder.kills'].to_i,stats['builder.deaths'].to_i)

        #clan_count = ::Clan.count
        #score = (score*clan_count.to_f)/((clan_count/7.2)*3.1337)
        #score = score * win_multiplier
      else
        score = 0.00
      end

      score = score <= 0 ? 0 : score
      @clan.score = score
      @clan.save
      score
    end

    def calc_kr_add(kill_multiplier,death_multiplier,kills,deaths)
      add = 0
      if kills > 0 or deaths > 0
        add += kills * (kill_multiplier / 50.0)
        add -= deaths * (death_multiplier / 50.0)
      end
      add
    end
  end
end