et.MAX_WEAPONS = 50
pistolwar_flag = false
pistolwar = {
	nil,	--// 1
	true,	--WP_LUGER,				// 2
	false,	--WP_MP40,				// 3
	true,	--WP_GRENADE_LAUNCHER,	// 4
	false,	--WP_PANZERFAUST,		// 5
	false,	--WP_FLAMETHROWER,		// 6
	true,	--WP_COLT,				// 7	// equivalent american weapon to german luger
	false,	--WP_THOMPSON,			// 8	// equivalent american weapon to german mp40
	true,	--WP_GRENADE_PINEAPPLE,	// 9
	false,	--WP_STEN,				// 10	// silenced sten sub-machinegun
	true,	--WP_MEDIC_SYRINGE,		// 11	// JPW NERVE -- broken out from CLASS_SPECIAL per Id request
	true, 	--WP_AMMO,				// 12	// JPW NERVE likewise
	false,	--WP_ARTY,				// 13
	true,	--WP_SILENCER,			// 14	// used to be sp5
	true,	--WP_DYNAMITE,			// 15
	nil,	--// 16
	nil,	--// 17
	nil,		--// 18
	true,	--WP_MEDKIT,			// 19
	true,	--WP_BINOCULARS,		// 20
	nil,	--// 21
	nil,	--// 22
	false,	--WP_KAR98,				// 23	// WolfXP weapons
	false,	--WP_CARBINE,			// 24
	false,	--WP_GARAND,			// 25
	true,	--WP_LANDMINE,			// 26
	true,	--WP_SATCHEL,			// 27
	true,	--WP_SATCHEL_DET,		// 28
	nil,	--// 29
	true,	--WP_SMOKE_BOMB,		// 30
	false,	--WP_MOBILE_MG42,		// 31
	false,	--WP_K43,				// 32
	false,	--WP_FG42,				// 33
	nil,	--// 34
	false,	--WP_MORTAR,			// 35
	nil,	--// 36
	false,	--WP_AKIMBO_COLT,		// 37
	false,	--WP_AKIMBO_LUGER,		// 38
	nil,	--// 39					axis riflegrenade
	nil,	--// 40					allies riflegrenade
	true,	--WP_SILENCED_COLT,		// 41
	false,	--WP_GARAND_SCOPE,		// 42
	false,	--WP_K43_SCOPE,			// 43
	false,	--WP_FG42SCOPE,			// 44
	false,	--WP_MORTAR_SET,		// 45
	false,	--WP_MEDIC_ADRENALINE,	// 46
	false,	--WP_AKIMBO_SILENCEDCOLT,// 47
	false	--WP_AKIMBO_SILENCEDLUGER,// 48
}

function et_RunFrame(levelTime)
	if levelTime % 1000 ~= 0 then return end

	if pistolwar_flag == true then
		local gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
		if gamestate == 0 then
			for j=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
				local team = tonumber(et.gentity_get(j, "sess.sessionTeam"))
				if team == 1 or team == 2 then
					local health = tonumber(et.gentity_get(j, "health"))
					if health > 0 then
						for i=1,(et.MAX_WEAPONS-1),1 do
							if not pistolwar[i] then
								et.gentity_set(j,"ps.ammoclip",i,0)
								et.gentity_set(j,"ps.ammo",i,0)
							end
						end
					end
				end
			end
		end
	end
end

function et_ClientSpawn(clientNum,revived)
	if pistolwar_flag == true then
		if revived ~= true then
			for i=1,(et.MAX_WEAPONS-1),1 do
				if not pistolwar[i] then
					et.gentity_set(clientNum,"ps.ammoclip",i,0)
					et.gentity_set(clientNum,"ps.ammo",i,0)
				else
					et.gentity_set(clientNum,"ps.ammo",i,104)
				end
			end
		end
	end
end

Vote:new("pistolwar")
	:description("Pistols only")
	:vote(function()
		if pistolwar_flag == true then
			return false, "Pistolwar mode is already enabled."
		end
		
		local playerCount = 0
		for j=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
			local team = tonumber(et.gentity_get(j, "sess.sessionTeam"))
			if team == 1 or team == 2 then
				playerCount = playerCount + 1
			end
		end
		if playerCount < 22 then
			return false, "This vote requires 22 players or more to cast."
		end

		return string.format("Enable pistols only mode?")
	end)
	:pass(function()
		pistolwar_flag = true
	end)
	:percent(90)

Vote:new("allweapons")
	:description("Enable all weapons")
	:vote(function()
		if pistolwar_flag == false then
			return false, "All weapons are already enabled."
		end

		return string.format("Enable all weapons?")
	end)
	:pass(function()
		pistolwar_flag = false
	end)

