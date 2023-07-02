disablesmoke = false

function et_ClientSpawn(clientNum,revived)
	if disablesmoke == true then
		if et.gentity_get(clientNum,"sess.latchPlayerType") == 4 then
			et.gentity_set(clientNum,"ps.ammoclip",29,0)
			et.gentity_set(clientNum,"ps.ammo",29,0)
		end
	end
end

Vote:new("disablesmoke")
	:description("Disable covert smoke grenades")
	:vote(function()
		if disablesmoke == true then
			return false, "Covert smoke grenades are already disabled."
		end

		return string.format("Disable covert smoke grenades?")
	end)
	:pass(function()
		disablesmoke = true
	end)

Vote:new("enablesmoke")
	:description("Enable covert smoke grenades")
	:vote(function()
		if disablesmoke == false then
			return false, "Covert smoke grenades are already enabled."
		end

		return string.format("Enable covert smoke grenades?")
	end)
	:pass(function()
		disablesmoke = false
	end)
