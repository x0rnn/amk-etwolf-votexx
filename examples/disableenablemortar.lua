disablemortar = false

function et_ClientSpawn(clientNum,revived)
	if disablemortar == true then
		if et.gentity_get(clientNum,"sess.latchPlayerType") == 0 then
			if et.gentity_get(clientNum,"sess.latchPlayerWeapon") == 35 then
				et.gentity_set(clientNum,"sess.latchPlayerType", 1)
				et.gentity_set(clientNum, "ps.powerups", 1, 0)
				et.G_Damage(clientNum, 80, 1022, 1000, 8, 34)
			end
		end
	end
end

Vote:new("disablemortar")
	:description("Disable mortar")
	:vote(function()
		if tonumber(et.trap_Cvar_Get("team_maxMortars")) > 0 and disablemortar == true then
			disablemortar = false
		end
		if disablemortar == true then
			return false, "Mortar is already disabled."
		end
		local gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
		if gamestate ~= 0 then
			return false, "You can only vote this during the game."
		end
		
		local playerCount = 0
		for j=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
			local team = tonumber(et.gentity_get(j, "sess.sessionTeam"))
			if team == 1 or team == 2 then
				playerCount = playerCount + 1
			end
		end
		if playerCount < 20 then
			return false, "This vote requires 20 players or more to cast."
		end

		return string.format("Disable mortar?")
	end)
	:pass(function()
		disablemortar = true
		et.trap_Cvar_Set("team_maxMortars", 0)
	end)
	:percent(70)

Vote:new("enablemortar")
	:description("Enable mortar")
	:vote(function()
		if tonumber(et.trap_Cvar_Get("team_maxMortars")) == 0 and disablemortar == false then
			disablemortar = true
		end
		if disablemortar == false then
			return false, "Mortar is already enabled."
		end

		return string.format("Enable mortar?")
	end)
	:pass(function()
		disablemortar = false
		local playerCount = 0
		for j=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
			if et.gentity_get(j, "inuse") then
				playerCount = playerCount + 1
			end
		end
		if playerCount >= 16 then
			et.trap_Cvar_Set("team_maxMortars", 1)
		end
	end)
