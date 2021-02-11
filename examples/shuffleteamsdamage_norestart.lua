Vote:new("shuffleteamsdamage_norestart")
	:description("Randomly place players on each team, based on damage, without a map restart")
	:vote(function()
		return string.format("Shuffle teams by damage, without a map restart")
	end)
	:pass(function()
		local axisdmg = 0
		local alliesdmg = 0
		local damages = {}
	
		for j=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
			local team = tonumber(et.gentity_get(j, "sess.sessionTeam"))
			if team == 1 or team == 2 then
				if team == 1 then
					local dmg = tonumber(et.gentity_get(j, "sess.damage_given"))
					table.insert(damages, {j, dmg, 1})
					axisdmg = axisdmg + dmg
				elseif team == 2 then
					local dmg = tonumber(et.gentity_get(j, "sess.damage_given"))
					table.insert(damages, {j, dmg, 2})
					alliesdmg = alliesdmg + dmg
				end
			end
		end

		table.sort(damages, function(a, b) return a[2] > b[2] end)

		local weaker_team = {}
		local stronger_team = {}
		local wti = 1
		local sti = 1
	
		for k, v, t in ipairs(damages) do
			if k >= 1 and math.mod(k - 1, 2) == 0 then 
				weaker_team[wti] = {v, t}
				wti = wti + 1
			else
				stronger_team[sti] = {v, t}
				sti = sti + 1
			end
		end
	
		if axisdmg >= alliesdmg then -- weaker_team == allies
			for k,v in ipairs(weaker_team) do
				if v[1][3] == 1 then
					et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref putalliesf " .. v[1][1] .. "\n")
				else
					et.G_Damage(v[1][1], 80, 1022, 1000, 8, 34)
				end
			end
			for k,v in ipairs(stronger_team) do
				if v[1][3] == 2 then
					et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref putaxisf " .. v[1][1] .. "\n")
				else
					et.G_Damage(v[1][1], 80, 1022, 1000, 8, 34)
				end
			end
		elseif alliesdmg > axisdmg then -- weaker_team == axis
			for k,v in ipairs(weaker_team) do
				if v[1][3] == 2 then
					et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref putaxisf " .. v[1][1] .. "\n")
				else
					et.G_Damage(v[1][1], 80, 1022, 1000, 8, 34)
				end
			end
			for k,v in ipairs(stronger_team) do
				if v[1][3] == 1 then
					et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref putalliesf " .. v[1][1] .. "\n")
				else
					et.G_Damage(v[1][1], 80, 1022, 1000, 8, 34)
				end
			end
		end
	end)