Vote:new("putaxis <player>")
	:description("Puts a player to the Axis team")
	:vote(function(player)
        if V.context.targetTeam ~= TEAM_AXIS then
            return string.format("PUTAXIS %s", et.gentity_get(player, "pers.netname")) 
        else
       	return false, "Player is already in Axis." 
       end

    end)
	:pass("ref putaxis <player:%d>")
	:percent(80)
