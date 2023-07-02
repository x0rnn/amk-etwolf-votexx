-- putmedic a player playing a spam-heavy class (soldier or fieldops) and restrict them from playing soldier or fieldops

block_class = {}
soundindex = ""
crestrict = {}
crestrict_id = {}
cflag = false

function et_InitGame(levelTime, randomSeed, restart)
	for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
		crestrict[i] = nil
	end
end

function et_ClientBegin(clientNum)
	block_class[clientNum] = { [1]=false, [2]=3, [3]=3 }
end

function et_ClientDisconnect(clientNum)
	if crestrict[clientNum] == true then
		crestrict[clientNum] = nil
		local index={}
		for k,v in pairs(crestrict_id) do
			index[v]=k
		end
		table.remove(crestrict_id, index[clientNum])
		if next(crestrict) == nil then
			cflag = false
		end
	end
end

function et_RunFrame(levelTime)
	if levelTime % 1000 ~= 0 then return end
	gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
	if gamestate == 0 then
		if cflag == true then
			local x = 1
			for index in pairs(crestrict_id) do
				if block_class[crestrict_id[x]][1] == true then
					if et.gentity_get(crestrict_id[x],"sess.latchPlayerType") == block_class[crestrict_id[x]][2] or et.gentity_get(crestrict_id[x],"sess.latchPlayerType") == block_class[crestrict_id[x]][3] then
						et.gentity_set(crestrict_id[x],"sess.latchPlayerType", 1)
						et.trap_SendServerCommand(crestrict_id[x], "cpm \"^1You are not allowed to play that class.\n\"")
					end
					if et.gentity_get(crestrict_id[x],"sess.PlayerType") == block_class[crestrict_id[x]][2] or et.gentity_get(crestrict_id[x],"sess.PlayerType") == block_class[crestrict_id[x]][3] then
						local health = tonumber(et.gentity_get(crestrict_id[x], "health"))
						if health > 0 then
							et.gentity_set(crestrict_id[x], "ps.powerups", 1, 0)
							et.G_Damage(crestrict_id[x], 80, 1022, 1000, 8, 34)
							et.G_Sound(crestrict_id[x], et.G_SoundIndex("/sound/osp/goat.wav"))
						end
					end
				end
				x = x + 1
			end
		end
	end
end

Vote:new("putmedic <player>")
	:description("Switches a player to Medic from a spam-heavy class (Soldier or FieldOps)")
	:vote(function(player)

		if V.context.callerTeam ~= nil and V.context.callerTeam ~= V.context.targetTeam then
			return false, "You can only putmedic players within the same team."
		end

		local class = et.gentity_get(player, "sess.PlayerType")
		local classname = ""
		if class == 0 then
			classname = "Soldier"
		elseif class == 3 then
			classname = "FieldOps"
		end
		if class == 1 then
			return false, string.format("%s ^7is already a Medic.", et.gentity_get(player, "pers.netname"))
		end
		if classname == "" then
			return false, "You can only putmedic players who play a spam-heavy class (Soldier or FieldOps)."
		end
		
		return string.format("PUTMEDIC %s ^7from %s", et.gentity_get(player, "pers.netname"), classname)
	end)
	:pass(function(player)
		crestrict[player] = true
		table.insert(crestrict_id, player)
		block_class[player][1] = true
		block_class[player][2] = 0 -- 0 = soldier, 1 = medic, 2 = engineer, 3 = fieldops, 4 = covertops
		block_class[player][3] = 3 -- second class to block. Set to same as above if only 1 class is restricted
		cflag = true
	end)
	:team()
	:percent(60)
