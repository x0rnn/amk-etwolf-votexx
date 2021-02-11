Vote:new("putallies <player>")
	:description("Puts a player to the Allied team")
	:vote(function(player)
        if V.context.targetTeam ~= TEAM_ALLIES then
            return string.format("PUTALLIES %s", et.gentity_get(player, "pers.netname")) 
        else
       	return false, "Player is already in Allies." 
       end

    end)
	:pass("ref putallies <player:%d>")
	:percent(80)
