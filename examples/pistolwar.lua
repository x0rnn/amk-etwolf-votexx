et.MAX_WEAPONS = 55
pistolwar_flag = false
pistolwar = {
	nil,	--WP_KNIFE,                  ///< 1
	true,	--WP_LUGER,                  ///< 2
	false,	--WP_MP40,                   ///< 3
	true,	--WP_GRENADE_LAUNCHER,       ///< 4	axis grenade
	false,	--WP_PANZERFAUST,            ///< 5
	false,	--WP_FLAMETHROWER,           ///< 6
	true,	--WP_COLT,                   ///< 7	equivalent american weapon to german luger
	false,	--WP_THOMPSON,               ///< 8	equivalent american weapon to german mp40
	true,	--WP_GRENADE_PINEAPPLE,      ///< 9	allied grenade
	false,	--WP_STEN,                   ///< 10	silenced sten sub-machinegun
	true,	--WP_MEDIC_SYRINGE,          ///< 11	broken out from CLASS_SPECIAL per Id request
	true,	--WP_AMMO,                   ///< 12	likewise
	false,	--WP_ARTY,                   ///< 13
	true,	--WP_SILENCER,               ///< 14	silenced luger (used to be sp5)
	true,	--WP_DYNAMITE,               ///< 15
	nil,	--WP_SMOKETRAIL,             ///< 16
	nil,	--WP_MAPMORTAR,              ///< 17
	nil,	--VERYBIGEXPLOSION,          ///< 18	explosion effect for airplanes
	true,	--WP_MEDKIT,                 ///< 19
	true,	--WP_BINOCULARS,             ///< 20
	nil,	--WP_PLIERS,                 ///< 21
	nil,	--WP_SMOKE_MARKER,           ///< 22	changed name to cause less confusion
	false,	--WP_KAR98,                  ///< 23	axis rifle
	false,	--WP_CARBINE,                ///< 24	allied rifle
	false,	--WP_GARAND,                 ///< 25
	true,	--WP_LANDMINE,               ///< 26
	true,	--WP_SATCHEL,                ///< 27
	true,	--WP_SATCHEL_DET,            ///< 28
	nil,	--WP_SMOKE_BOMB,             ///< 29
	false,	--WP_MOBILE_MG42,            ///< 30
	false,	--WP_K43,                    ///< 31
	false,	--WP_FG42,                   ///< 32
	false,	--WP_DUMMY_MG42,             ///< 33 for storing heat on mounted mg42s...
	false,	--WP_MORTAR,                 ///< 34
	false,	--WP_AKIMBO_COLT,            ///< 35
	false,	--WP_AKIMBO_LUGER,           ///< 36
	false,	--WP_GPG40,                  ///< 37	axis riflegrenade
	false,	--WP_M7,                     ///< 38	allies riflegrenade
	true,	--WP_SILENCED_COLT,          ///< 39
	false,	--WP_GARAND_SCOPE,           ///< 40
	false,	--WP_K43_SCOPE,              ///< 41
	false,	--WP_FG42_SCOPE,             ///< 42
	false,	--WP_MORTAR_SET,             ///< 43
	false,	--WP_MEDIC_ADRENALINE,       ///< 44
	false,	--WP_AKIMBO_SILENCEDCOLT,    ///< 45
	false,	--WP_AKIMBO_SILENCEDLUGER,   ///< 46
	false,	--WP_MOBILE_MG42_SET,        ///< 47
	false,	--WP_KNIFE_KABAR,            ///< 48	allied knife
	false,	--WP_MOBILE_BROWNING,        ///< 49	allied machinegun
	false,	--WP_MOBILE_BROWNING_SET,    ///< 50
	false,	--WP_MORTAR2,                ///< 51	allied mortar
	false,	--WP_MORTAR2_SET,            ///< 52
	false,	--WP_BAZOOKA,                ///< 53	allied panzerfaust
	false,	--WP_MP34,                   ///< 54	axis sten alternative
	false	--WP_AIRSTRIKE,              ///< 55
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

