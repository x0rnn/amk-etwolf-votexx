# Vote++

This is a Lua module for Enemy Territory - Wolfenstein server introducing extended voting functionality and providing an easy way to define new commands.

## Usage

1. Put `vote++.lua` in `etpro` folder.
2. Create an empty `vote++.config.lua` file (that's where the configuration goes).
3. Append `vote++.lua` to `lua_modules` cvar.

## Configuration

All the configuration belongs to `vote++.config.lua`.

Apart from defining commands, you can define any ET callback (like `et_RunFrame`) and use any API (`et.*` and stdlib).

### Defining vote commands

~~~lua
Vote:new("nohw")
    :description("Disable heavy weapons")
    :pass("exec nohw.cfg")
~~~

This command can be executed as: `callvote nohw`, `ref nohw` (in server console or as an authenticated referee).

- `Vote:new(string)`: command name, can be defined as:
    - `string`
    - `string <arg1> <arg2>`

The module automatically validates number of passed arguments and prints a help message when not enough of them is given.  There's a special reserved argument `<player>`, which always resolves to a slot number. Caller can use part of name instead. When using string as argument to callback functions (see below), you can use: `<player:%d>` or `<player:%s>`, which resolves to a slot number or player name, respectively.

All arguments defined in the `Vote:new()` constructor will be passed to callback functions (`vote`, `pass`, `fail`).

- `:description(string)`: help text of the command.

- `:vote(string | function)`: this can be either a string or function called immediately after `callvote` command. It's supposed to validate the arguments and return a vote string.

~~~lua
Vote:new("remove <player>")
    :vote("PUTSPEC <player:%s>") -- PUTSPEC ETPlayer
~~~

~~~lua
Vote:new("kill <player>")
    :vote(function(player)

        if math.random() < 0.5 then
            return false, "No, you're out of luck." -- you can optionally return error message
        end

        return string.format("KILL %s", et.gentity_get(player, "pers.netname"))
    
    end)
~~~

- `:pass(string | function)`: this will be called if the vote passes
  
- `:fail(string | function)`: this will be called if the vote fails

- `:percent(number)`: sets the percentage at which the vote passes, default: `vote_percent`

- `:team()`: makes the vote team only - this only works if the `<player>` argument is specified in the constructor

- `:attacker()`: makes the vote only available for attacking team

- `:defender()`: makes the vote only available for defending team

### Disabling vote commands

You can disable any or all the vote commands, including the built-in ones.

~~~lua
V.disable("*") -- disables all commands
V.disable("warmupdamage")
V.enable("kick")
~~~

### ETAdmin integration

ETAdmin can, under certain conditions, automatically cancel or pass votes. It does so by executing `cancelvote` or `passvote` to server console. ETPro doesn't propagate this command to Lua modules, so you need to change it to `cancelvote++` and `passvote++`. Native functionality is preserved.