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

hook.Add( "Initialize", "MapVoteConfigSetup", function()
    if not file.Exists( "mapvote", "DATA" ) then
        file.CreateDir( "mapvote" )
    end
    if not file.Exists( "mapvote/config.txt", "DATA" ) then
        file.Write( "mapvote/config.txt", util.TableToJSON( MapVoteConfigDefault, true ) )
    end
end )

MapVote.CurrentMaps = {}
MapVote.Votes = {}

MapVote.Allow = false

MapVote.UPDATE_VOTE = 1
MapVote.UPDATE_WIN = 3

if SERVER then
    AddCSLuaFile()
    AddCSLuaFile( "mapvote/cl_mapvote.lua" )

    include( "mapvote/sv_mapvote.lua" )
    include( "mapvote/rtv.lua" )
else
    include( "mapvote/cl_mapvote.lua" )
end
