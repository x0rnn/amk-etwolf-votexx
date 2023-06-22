-- Extend timelimit by 3 minutes in the last 3 minutes of the game

mapstarted = false
paused = false
mapstart_time = 0
paused_time = 0
unpaused_time = 0
stuck_time = 0
intervals = {[1]=0, [2]=0}

function et_RunFrame(levelTime)
	if levelTime % 1000 ~= 0 then return end

	local gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
	if gamestate == 0 then
		if mapstarted == false then
			mapstart_time = et.trap_Milliseconds()
			mapstarted = true
		else
			if paused == true then
				local cs = et.trap_GetConfigstring(11)
				if intervals[1] == 0 then
					intervals[1] = cs
				elseif intervals[1] ~= 0 then
					if intervals[2] == 0 then
						intervals[2] = cs
					elseif intervals[2] ~= 0 then
						intervals[1] = intervals[2]
						intervals[2] = cs
						if intervals[1] == intervals[2] then
							paused = false
							unpaused_time = et.trap_Milliseconds() - 1000
							stuck_time = unpaused_time - paused_time + stuck_time
							intervals[1] = 0
							intervals[2] = 0
						end
					end
				end
			end
		end
	end
end

function et_ConsoleCommand()
	local arg = et.trap_Argv(1)
	if arg == "pause" then
		paused = true
		paused_time = et.trap_Milliseconds()
	end
	if arg == "unpause" then
		paused = false
		unpaused_time = et.trap_Milliseconds()
		stuck_time = unpaused_time - paused_time + stuck_time + 10000
	end
	return(0)
end

Vote:new("extend_time")
	:description("Extends the timelimit 3 minutes in the last 3 minutes of the match")
	:vote(function()
	
		local timelimit = et.trap_Cvar_Get("timelimit") * 1000 * 60
		local timeleft
		timeleft = timelimit - ((et.trap_Milliseconds() - stuck_time) - mapstart_time)
		if timeleft > 180000 then
			return false, "You can only callvote this in the last 3 minutes of the match."
		end

        return string.format("Extend timelimit 3 minutes")
    
    end)
	:pass(function()
		et.trap_Cvar_Set("timelimit", et.trap_Cvar_Get("timelimit") + 3)
	end)
	:percent(60)

