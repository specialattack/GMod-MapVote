MapVote = {}
MapVote.Config = {}

--Default Config
MapVoteConfigDefault = {
    MapLimit = 10,
    TimeLimit = 30,
    AllowCurrentMap = false,
    EnableCooldown = true,
    MapsBeforeRevote = 3,
    RTVPlayerCount = 3,
    MapPreviewURLs = "asset://garrysmod/materials/maps/%s.png",
    MapPrefixes = {
        ["ttt_"] = { "terrortown" },
        ["ph_"] = { "prop_hunt" },
        ["cs_"] = { "terrortown", "prop_hunt" }
    },
    Gamemodes = {
        ["terrortown"] = { "TTT", "rgba(0, 127, 255, 0.7)" },
        ["prop_hunt"] = { "PH", "rgba(127, 255, 0, 0.7)" },
        ["murder"] = { "MD", "rgba(255, 0, 127, 0.7)" }
    }
}
--Default Config

function table.show(t, name, indent)
    local cart     -- a container
    local autoref  -- for self references

    --[[ counts the number of elements in a table
    local function tablecount(t)
       local n = 0
       for _, _ in pairs(t) do n = n+1 end
       return n
    end
    ]]
    -- (RiciLake) returns true if the table is empty
    local function isemptytable(t) return next(t) == nil end

    local function basicSerialize (o)
        local so = tostring(o)
        if type(o) == "function" then
            local info = debug.getinfo(o, "S")
            -- info.name is nil because o is not a calling level
            if info.what == "C" then
                return string.format("%q", so .. ", C function")
            else
                -- the information is defined through lines
                return string.format("%q", so .. ", defined in (" ..
                        info.linedefined .. "-" .. info.lastlinedefined ..
                        ")" .. info.source)
            end
        elseif type(o) == "number" or type(o) == "boolean" then
            return so
        else
            return string.format("%q", so)
        end
    end

    local function addtocart (value, name, indent, saved, field)
        indent = indent or ""
        saved = saved or {}
        field = field or name

        cart = cart .. indent .. field

        if type(value) ~= "table" then
            cart = cart .. " = " .. basicSerialize(value) .. ";\n"
        else
            if saved[value] then
                cart = cart .. " = {}; -- " .. saved[value]
                        .. " (self reference)\n"
                autoref = autoref ..  name .. " = " .. saved[value] .. ";\n"
            else
                saved[value] = name
                --if tablecount(value) == 0 then
                if isemptytable(value) then
                    cart = cart .. " = {};\n"
                else
                    cart = cart .. " = {\n"
                    for k, v in pairs(value) do
                        k = basicSerialize(k)
                        local fname = string.format("%s[%s]", name, k)
                        field = string.format("[%s]", k)
                        -- three spaces between levels
                        addtocart(v, fname, indent .. "   ", saved, field)
                    end
                    cart = cart .. indent .. "};\n"
                end
            end
        end
    end

    name = name or "__unnamed__"
    if type(t) ~= "table" then
        return name .. " = " .. basicSerialize(t)
    end
    cart, autoref = "", ""
    addtocart(t, name, indent)
    return cart .. autoref
end

local function fixTable( tbl )
    local result = {}

    for key, value in pairs( tbl ) do
        if tonumber( key ) ~= nil then
            if type(value) == "table" then
                result[tonumber( key )] = fixTable( value )
            else
                result[tonumber( key )] = value
            end
        else
            if type(value) == "table" then
                result[key] = fixTable( value )
            else
                result[key] = value
            end
        end
    end

    return result
end

hook.Add( "Initialize", "MapVoteConfigSetup", function()
    if not file.Exists( "mapvote", "DATA" ) then
        file.CreateDir( "mapvote" )
    end
    if not file.Exists( "mapvote/config.txt", "DATA" ) then
        file.Write( "mapvote/config.txt", util.TableToJSON( MapVoteConfigDefault, true ) )
    end

    if SERVER then
        if not file.Exists( "mapvote/scores.txt", "DATA" ) then
            file.Write( "mapvote/scores.txt", util.TableToJSON( MapVote.Scores, true ) )
        else
            MapVote.Scores = fixTable( util.JSONToTable( file.Read( "mapvote/scores.txt", "DATA" ) ) )
        end
    end
end )

MapVote.CurrentMaps = {}
MapVote.Votes = {}
MapVote.Feedback = {}
MapVote.Scores = {}

MapVote.Allow = false

MapVote.UPDATE_VOTE = 1
MapVote.UPDATE_WIN = 3
MapVote.UPDATE_FEEDBACK = 4

if SERVER then
    AddCSLuaFile()
    AddCSLuaFile( "mapvote/cl_mapvote.lua" )

    include( "mapvote/sv_mapvote.lua" )
    include( "mapvote/rtv.lua" )
else
    include( "mapvote/cl_mapvote.lua" )
end
