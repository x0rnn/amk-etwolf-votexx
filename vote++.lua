local MOD_NAME = "vote++"

local SINGLE_CONFIG_NAME = "vote++.config.lua"
local CONFIG_DIR = "vote++"

-- constants
local FORMAT_CP               = 'cp "%s"'
local FORMAT_CPM              = 'cpm "%s"'
local FORMAT_PRINT            = 'print "%s"'
local FORMAT_CS               = 'cs %i "%s"\n'
local MSG_VOTE_DISABLED       = "Sorry, [lof]^3%s^7 [lon]voting has been disabled\n"
local MSG_ADDITIONAL_VOTE     = "\nAdditional ^3callvote^7 commands are:\n^3----------------------------\n"
local MSG_SIDE_TEAM           = "Sorry, ^3%s ^7voting is only possible for %s team.\n"
local MSG_INVALID_SLOT_NUMBER = "Invalid slot number.\n"
local TEAM_AXIS               = 1
local TEAM_ALLIES             = 2
local TEAM_SPECTATOR          = 3
local ENT_SESSION_TEAM        = "sess.sessionTeam"
local ENT_PERS_NETNAME        = "pers.netname"
local SIDE_ATTACKER           = 0
local SIDE_DEFENDER           = 1
local VOTE_SCOPE_GLOBAL
local VOTE_SCOPE_TEAM         = 1
local CMD_CALLVOTE            = "callvote"
local HELP_VOTES_ROW          = 3
local HELP_VOTES_COLUMN_SIZE  = 29

-- local scope
local this = {

	-- ET callbacks
	callbacks = {},

	-- These callbacks can intercept
	intercepts = {
		et_IPCReceive     = true,
		et_ClientConnect  = true,
		et_ClientCommand  = true,
		et_ConsoleCommand = true,
		et_UpgradeSkill   = true,
		et_Obituary       = true,
	},

	-- Custom vote handlers
	commands = {},

	-- Enabled votes
	enabled = {},

	-- Running vote context
	context = {
		vote       = nil,
		target     = nil,
		targetTeam = nil,
		argument   = nil,
	},

	-- Futures
	futures = {},

	-- Default percentage to restore
	percentage = nil,

}

--
-- Vote definition API.
--

local Vote   = {}
local VoteMT = {__index = Vote}
this.Vote = Vote

--- Instantiates a vote definition.
-- @param command string
function Vote:new(command)

	local s, e = string.find(command, "^[a-zA-Z0-9_]+")

	if s == e then
		error(string.format("%s: Vote:new() command has an invalid format", MOD_NAME))
	end

	local id = string.lower(string.sub(command, s, e))

	if id == "n" then
		error(string.format("%s: Vote:new() reserved command name", MOD_NAME))
	end

	local arguments = {}

	for a in string.gmatch(command, "<([^>]+)>") do
		table.insert(arguments, a)
	end

	if #arguments > 1 then
		error(string.format("%s: Vote:new(%s) can define no more than 1 argument", MOD_NAME, id))
	end

	local m = setmetatable({
		id         = id,
		command    = command,
		arguments  = arguments,
		vCallbacks = {}
	}, VoteMT)

	this.enable(id)
	this.commands[id] = m

	return m

end

--- Sets vote description.
-- @param description string
function Vote:description(description)
	this.assertType("description", description, "string")
	self.vDescription = description
	return self
end

--- Makes the vote team specific.
function Vote:team()
	self.vScope = VOTE_SCOPE_TEAM
	return self
end

--- Makes the vote attacker specific.
function Vote:attacker()
	self.vSide = SIDE_ATTACKER
	return self
end

--- Makes the vote defender specific.
function Vote:defender()
	self.vSide = SIDE_DEFENDER
	return self
end

--- Sets a required percentage to pass.
function Vote:percent(percent)
	this.assertType("percent", percent, "number")
	self.vPercent = percent
	return self
end

--- Attaches a vote callback.
-- @param callback function or string
function Vote:vote(callback)
	this.assertCallback("vote", callback)
	self.vCallbacks.vote = callback
	return self
end

--- Attaches a pass callback.
-- @param callback function or string
function Vote:pass(callback)
	this.assertCallback("pass", callback)
	self.vCallbacks.pass = callback
	return self
end

--- Attaches a fail callback.
-- @param callback function or string
function Vote:fail(callback)
	this.assertCallback("pass", callback)
	self.vCallbacks.fail = callback
	return self
end

--
-- Internal functions.
--

--- Enables a command.
function this.enable(command)
	this.enabled[command] = true
end

--- Disables a command.
function this.disable(command)
	this.enabled[command] = false
end

--- Loads configuration.
function this.configure()

	local basePath = et.trap_Cvar_Get("fs_homepath") .. "/" .. et.trap_Cvar_Get("fs_game")

	this.include(basePath .. "/" .. SINGLE_CONFIG_NAME)

	for _, file in pairs(et.trap_FS_GetFileList(CONFIG_DIR, "lua")) do
		this.include(basePath .. "/" .. CONFIG_DIR .. "/" .. file)
	end

end

--- Includes a file, propagating the relevant scope and registering all nested callbacks.
function this.include(filename)

	local scope = {
		V    = this,
		Vote = Vote,
	}

	for variable, value in pairs(_G) do

		if variable ~= "this" and string.sub(variable, 1, 3) ~= "et_" then
			scope[variable] = value
		end

	end

	local script, err = loadfile(filename, 'bt', scope)

	if err ~= nil then

		local fd, len = et.trap_FS_FOpenFile(filename, et.FS_READ)

		-- The file exists, so it doesn't compile.
		if len >= 0 then
			et.trap_FS_FCloseFile(fd)
			error(err)
		end

		return

	end

	script()

	for name, callback in pairs(scope) do

		if string.sub(name, 1, 3) == "et_" and name ~= "et_VoteCall" and name ~= "et_VoteEnd" then

			if this.callbacks[name] == nil then
				this.callbacks[name] = {callback}
			else
				table.insert(this.callbacks[name], callback)
			end

		end

	end

	for name, _ in pairs(this.callbacks) do

		if _G[name] == nil then
			_G[name] = this.createGenericCallbackHandler(name)
		end

	end

end

--- Checks that an option field is a valid callback.
function this.assertCallback(name, callback)

	if type(callback) ~= "function" and type(callback) ~= "string" then
		error(string.format('%s: Vote:%s() expects function or string, %s given', MOD_NAME, name, type(callback)))
	end

end

--- Checks that an option field has an expected type.
function this.assertType(name, value, expected)

	if type(value) ~= expected then
		error(string.format('%s: Vote:%s() expects %s, %s given', MOD_NAME, name, expected, type(value)))
	end

end

--- Calls all the registered callbacks and returns a truthy value when intercepted.
function this.executeETCallbacks(callback, ...)

	local arg = {...}

	if this.callbacks[callback] == nil then
		return
	end

	for _, f in pairs(this.callbacks[callback]) do

		local status, res = pcall(function()
			return f(table.unpack(arg))
		end)

		if not status then
			et.G_Print(string.format("%s: %s\n", MOD_NAME, res))
		elseif res and this.intercepts[callback] == true then
			return res
		end

	end

end

--- Creates callback handler for the functions we ourselves don't implement.
function this.createGenericCallbackHandler(name)

	return function(...)

		local arg = {...}
		local intercepted = this.executeETCallbacks(name, table.unpack(arg))

		if intercepted ~= nil then
			return intercepted
		end

	end

end

--- Executes vote callback (pass, fail and vote).
function this.executeVoteCallback(name, execute)

	if type(this.context.vote.vCallbacks[name]) == "function" then

		local status, result, message = pcall(function()
			return this.context.vote.vCallbacks[name](table.unpack(this.context.arguments))
		end)

		if not status then
			error(result)
		end

		return result, message

	elseif type(this.context.vote.vCallbacks[name]) == "string" then

		local s       = string.format("%s", this.context.vote.vCallbacks[name])
		local netname = et.Q_CleanStr(et.gentity_get(this.context.target, ENT_PERS_NETNAME))

		if this.context.target ~= nil then
			s = this.replace(s, "<player:%s>", netname)
			s = this.replace(s, "<player:%d>", tostring(this.context.target))
			s = this.replace(s, "<player:%i>", tostring(this.context.target))
		end

		if execute then
			et.trap_SendConsoleCommand(et.EXEC_NOW, string.format("%s\n", s))
			return nil
		end

		return s

	end

	return nil

end

--- Replaces a substring.
function this.replace(s, find, replacement)

	local a, b = string.find(s, find, 1, true)

	if a ~= b then
		s = string.sub(s, 1, a - 1) .. replacement .. string.sub(s, b + 1)
	end

	return s

end

--- Prints usage.
function this.usage(clientNum, command)

	local name = "?"

	if command ~= nil then
		name = command.command
	end

	local usage = string.format("\nUsage: ^3\\%s %s^7", et.trap_Argv(0), name)

	if command and command.vDescription ~= nil then
		usage = string.format("%s\n  %s", usage, command.vDescription)
	end

	et.trap_SendServerCommand(clientNum, string.format(FORMAT_PRINT, usage .. "\n"))

end

--
-- ET.
--

--- Module registration.
function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname(MOD_NAME .. " " .. et.FindSelf())
	this.configure()
	this.executeETCallbacks(levelTime, randomSeed, restart)
end

--- Called on vote call.
function et_VoteCall(clientNum, vote, arg)

	this.context.vote = nil
	vote = string.lower(vote)

	if this.enabled[vote] == false then
		et.trap_SendServerCommand(clientNum, string.format(FORMAT_CPM, string.format(MSG_VOTE_DISABLED, vote)))
		return
	end

	if this.commands[vote] == nil then
		return
	end

	local clientTeam = et.gentity_get(clientNum, ENT_SESSION_TEAM)

	if this.commands[vote].vSide ~= nil and this.commands[vote].vSide ~= clientTeam then

		local side

		if command.vSide == SIDE_ATTACKER then
			side = "attacking"
		else
			side = "defending"
		end

		et.trap_SendServerCommand(clientNum, string.format(FORMAT_PRINT, string.format(MSG_SIDE_TEAM, vote, side)))
		return false

	end

	this.context.arguments  = {}
	this.context.target     = nil

	for _, a in pairs(this.commands[vote].arguments) do

		if arg == nil or arg == "?" then
			this.usage(clientNum, this.commands[vote])
			return false
		end

		local value = arg

		if a == "player" then

			value = et.ClientNumberFromString(value)

			if value == nil then
				et.trap_SendServerCommand(clientNum, string.format(FORMAT_PRINT, MSG_INVALID_SLOT_NUMBER))
				return false
			end

			-- First <player> is our target.
			if this.context.target == nil and value ~= nil then
				this.context.target     = value
				this.context.targetTeam = clientTeam
			end

		end

		table.insert(this.context.arguments, value)

	end

	this.context.vote = this.commands[vote]

	local voteString, errorMessage = this.executeVoteCallback("vote", false)

	if voteString == false then

		if type(errorMessage) == "string" then
			et.trap_SendServerCommand(clientNum, string.format(FORMAT_PRINT, errorMessage .. "\n"))
		end

		return false

	elseif voteString == nil then
		voteString = et.ConcatArgs(1)
	end

	if this.commands[vote].vPercent ~= nil then
		this.percentage = et.trap_Cvar_Get("vote_percent")
		et.trap_Cvar_Set("vote_percent", tostring(this.commands[vote].vPercent))
	end

	if this.commands[vote].vScope == VOTE_SCOPE_TEAM then

		if this.context.target ~= nil then
			return voteString, this.context.target
		else
			return voteString, clientNum
		end

	else
		return voteString
	end

end

--- Called when vote passes or fails.
function et_VoteEnd(passed)

	if this.context.vote == nil then
		return
	end

	if this.percentage ~= nil then
		et.trap_Cvar_Set("vote_percent", this.percentage)
		this.percentage = nil
	end

	if passed then
		this.executeVoteCallback("pass", true)
	else
		this.executeVoteCallback("fail", true)
	end

end

--- /callvote help
function et_ClientCommand(clientNum, command)

	local res = this.executeETCallbacks("et_ClientCommand", clientNum, command)

	if res then
		return res
	end

	command = string.lower(command)

	if command ~= CMD_CALLVOTE or et.trap_Argc() ~= 1 then
		return 0
	end

	table.insert(this.futures, function()

		et.trap_SendServerCommand(clientNum, string.format(FORMAT_PRINT, MSG_ADDITIONAL_VOTE))

		local i = 0
		local r = "^5"

		for _, vote in pairs(this.commands) do

			i = i + 1
			r = r .. vote.id .. string.rep(" ", HELP_VOTES_COLUMN_SIZE - string.len(vote.id))

			if i == HELP_VOTES_ROW then
				et.trap_SendServerCommand(clientNum, string.format(FORMAT_PRINT, r .. "\n"))
				i = 0
				r = "^5"
			end

		end

		if i > 0 then
			et.trap_SendServerCommand(clientNum, string.format(FORMAT_PRINT, r .. "\n"))
		end

	end)

end

--- Executes futures.
function et_RunFrame(levelTime)

	this.executeETCallbacks("et_RunFrame", levelTime)

	local futures = this.futures
	this.futures = {}

	for _, future in pairs(futures) do
		future()
	end

end