-- Puts player to spectator.
Vote:new("remove <player>")
    :description("Removes player from team")
    :vote(function(player)

        if V.context.callerTeam ~= nil and V.context.callerTeam ~= V.context.targetTeam then
            return false, "You can only remove players within the same team."
        end

        return string.format("REMOVE %s", et.gentity_get(player, "pers.netname"))

    end)
    :pass("ref remove <player:%d>")
    :team()