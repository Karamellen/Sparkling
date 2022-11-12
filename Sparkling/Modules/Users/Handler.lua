Users = {}
Users.Funcs = {}
Users.Players = {}
Users.Utility = {}

local LoadDelay = 60

local default = {
    ['hp'] = 100,
    ['ban'] = 0,
    ['cash'] = 69,
    ['groups'] = {},
    ['inventory'] = {},
    ['survival'] = {},
    ['identity'] = {
        ['first'] = 'Change',
        ['last'] = "Your name"
    }
}

-- local resp = SQL:query('SELECT * FROM users WHERE id = ?', {tostring(src)})

Users.Funcs.Get = function(source)
    local steam = Users.Utility.GetSteam(source)
    if steam == '' then
        return Error("Cannot find user")
    end

    return PlayerObject(
        steam
    )
end

Users.Funcs.Create = function(_, _, def)
    local source=source
    local steam = Users.Utility.GetSteam(source)

    def.defer()

    if steam == '' then
        return def.done(
            "Whoops, seems that you doesn't have steam open."
        )
    end

    Wait(0)

    def.update(
        "Checking your steam / data"
    )

    local resp = SQL:query('SELECT * FROM users WHERE id = ?', {steam}, function(data)
        Debug("A user joined "..steam)

        if table.unpack(data) ~= nil then
            def.update("You are already registered, loading in")
            Debug("User already registered")

        else
            Debug("Creating user "..steam)

            def.update("Creating your user...")

            SQL:query('INSERT INTO users (id) VALUES (?)', {steam})
        end
        Users.Funcs.Load(source, steam, data, def)
    end)
end

Users.Funcs.Load = function(source, steam, db, def)
    if Users.Players[steam] then
        return Error("An error occurred, player with steam "..steam.." is already loaded?")
    end

    local data = {
        ['connecting'] = true
    }
    if table.unpack(db) ~= nil then
        db = table.unpack(db)['data']
        for k,v in pairs(default) do
            Debug("K: "..tostring(k).." V: "..tostring(v).." DB[K]: "..tostring(db[k]))
            if db[k] == nil then
                data[k] = v
            else
                data[k] = db[k]
            end
        end
    else
        data = default
    end

    if data['ban'] ~= 0 then
        return def.done(
            "Whoops, you are banned - for the reason: "..data['ban']
        )
    end

    print(json.encode(data))

    Users.Players[steam] = data

    def.done()

    Wait(LoadDelay*1000)
    if Users.Players[steam] then
        if Users.Players[steam]['connecting'] then
            DropPlayer(source, 'A error occurred, please rejoin')
        end
    end
end

Users.Funcs.Spawned = function()
    local source = source
    local steam = Users.Utility.GetSteam(source)
    if Users.Players[steam] == nil then
        return
    end

    if Users.Players[steam]['connecting'] == false then
        return DropPlayer(source, "Whoops, there was a bug, or you are trying to exploit the system, if - stop.")
    end

    Users.Players[steam]['connecting'] = false
    Debug("Spawned")
    -- load all data
    local bob = Users.Funcs.Get(source)
    print(bob.ID)
end

Users.Funcs.Remove = function()
    local source = source
    local steam = Users.Utility.GetSteam(source)
    
    if Users.Players[steam] == nil then
        return Warn("A user left the server, but was not registered? Please check this out.")
    end

    local data = Users.Players[steam]
    data['connecting'] = nil
    data['id'] = nil

    Debug("Saved: "..json.encode(data))

    SQL:query(
        'UPDATE users SET data = ? WHERE id = ?', 
        {
            json.encode(data),
            steam
        }
    )
    Users.Players[steam] = nil
end

AddEventHandler('playerDropped', Users.Funcs.Remove)
AddEventHandler("playerConnecting", Users.Funcs.Create)
RegisterNetEvent("Sparkling:Spawned", Users.Funcs.Spawned)

Sparkling.Users = Users.Funcs