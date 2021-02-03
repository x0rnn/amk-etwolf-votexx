local KICK_DURATION = 10 -- minutes
local KICK_MESSAGE  = "Vote kicked."

-- Kicks the player using PunkBuster.
Vote:new("kick <player>")
	:description("Attempts to kick player from server")
	:vote("KICK <player:%s>")
	:pass(function(player)
		et.trap_SendConsoleCommand(et.EXEC_APPEND, string.format("pb_sv_kick %d %d \"%s\"\n", player + 1, KICK_DURATION, KICK_MESSAGE))
	end)
	:team()