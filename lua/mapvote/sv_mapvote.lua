util.AddNetworkString( "RAM_MapVoteStart" )
util.AddNetworkString( "RAM_MapVoteUpdate" )
util.AddNetworkString( "RAM_MapVoteCancel" )
util.AddNetworkString( "RAM_MapVoteFile" )
util.AddNetworkString( "RTV_Delay" )

MapVote.Continued = false

net.Receive( "RAM_MapVoteUpdate", function( _, ply )
    if MapVote.Allow then
        if IsValid(ply) then
            local update_type = net.ReadUInt( 8 )

            if update_type == MapVote.UPDATE_VOTE then
                local map = net.ReadString()

                if MapVote.CurrentMaps[map] then
                    MapVote.Votes[ply:SteamID()] = map

                    net.Start( "RAM_MapVoteUpdate" )
                        net.WriteUInt( MapVote.UPDATE_VOTE, 8 )
                        net.WriteEntity( ply )
                        net.WriteString( map )
                    net.Broadcast()
                end
            elseif update_type == MapVote.UPDATE_FEEDBACK then
                local score = net.ReadUInt( 8 )
                MapVote.Feedback[ply:SteamID()] = score
                print( ply:GetName() .. " gave this map a score of " .. score )
            end
        end
    end
end )

function MapVote.SendDir( player, dir, clientdir )
    if not file.Exists( dir, "GAME" ) then
        print( "Directory '" .. dir .. "' is missing!" )
        return
    end
    local files, dirs = file.Find( dir .. "/*", "GAME" )
    for _, fdir in pairs( dirs ) do
        if fdir ~= ".svn" then
            MapVote.SendDir( player, dir .. "/" .. fdir, clientdir .. "/" .. fdir )
        end
    end
 
    for _, v in pairs( files ) do
        MapVote.SendFile( player, dir .. "/" .. v, clientdir .. "/" .. v )
    end
end

function MapVote.SendFile( player, path, clientdir )
    local content = file.Read( path, "GAME" )
    net.Start( "RAM_MapVoteFile" )
        net.WriteString( clientdir )
        net.WriteString( content )
    net.Send( player )
end 

hook.Add( "PlayerInitialSpawn", "MapVotePlayerConnect", function( player )
    MapVote.SendDir( player, "lua/mapvote/html", "mapvote/html" )
end)

local recentmaps = {}

if file.Exists( "mapvote/recentmaps.txt", "DATA" ) then
    recentmaps = util.JSONToTable( file.Read( "mapvote/recentmaps.txt", "DATA" ) )
end

if file.Exists( "mapvote/config.txt", "DATA" ) then
    MapVote.Config = util.JSONToTable( file.Read( "mapvote/config.txt", "DATA" ) )
else
    MapVote.Config = {}
end

function MapVote.GetMapScore( mapname, gamemode )
    for _, mapinfo in pairs( MapVote.Scores ) do
        if mapinfo["name"] == mapname and mapinfo["gamemode"] == gamemode then
            return mapinfo["score"]
        end
    end
    return -1
end

local function CoolDownDoStuff()
    local amt = 0
    local totalScore = 0
    for _, score in pairs( MapVote.Feedback ) do
        amt = amt + 1
        totalScore = totalScore + score
    end
    local map = game.GetMap():lower()
    local gamemode = gmod.GetGamemode()
    local score = MapVote.GetMapScore( map, gamemode["FolderName"] )
    if (score <= 0 and amt >= 1) or amt > 5 then
        local newScore
        if score <= 0 then
            newScore = totalScore / amt
        else
            newScore = score * 0.3 + (totalScore / amt) * 0.7
        end
        if not MapVote.Scores[ map ] then
            MapVote.Scores[ #MapVote.Scores + 1 ] = { ["name"] = map, ["score"] = newScore, ["gamemode"] = gamemode["FolderName"] }
        else
            for _, mapinfo in pairs( MapVote.Scores ) do
                if mapinfo["name"] == map and mapinfo["gamemode"] == gamemode then
                    mapinfo["score"] = newScore
                end
            end
        end

        file.Write( "mapvote/scores.txt", util.TableToJSON( MapVote.Scores, true ) )
    end

    local cooldownnum = MapVote.Config.MapsBeforeRevote or 3

    if table.getn( recentmaps ) == cooldownnum then 
        table.remove( recentmaps )
    end

    local curmap = game.GetMap():lower() .. ".bsp"

    if not table.HasValue( recentmaps, curmap ) then
        table.insert( recentmaps, 1, curmap )
    end

    file.Write( "mapvote/recentmaps.txt", util.TableToJSON( recentmaps ) )
end

function MapVote.Start( length, current, limit, prefix )
    current = current or MapVote.Config.AllowCurrentMap or false
    length = length or MapVote.Config.TimeLimit or 30
    limit = limit or MapVote.Config.MapLimit or 10
    local cooldown = MapVote.Config.EnableCooldown or true
    prefix = prefix or MapVote.Config.MapPrefixes
    local gamemodes = MapVote.Config.Gamemodes or {}
    local previewFormat = MapVote.Config.MapPreviewURLs or "asset://garrysmod/materials/maps/%s.png"
    
    local maps = file.Find( "maps/*.bsp", "GAME" )
    
    local vote_maps = {}
    
    local amt = 0

    for _, map in RandomPairs( maps ) do
        if not (current and game.GetMap():lower() .. ".bsp" == map) and not (cooldown and table.HasValue( recentmaps, map )) then
            for _prefix, _gamemode in pairs( prefix ) do
                if string.find( map, "^" .. _prefix ) then
                    vote_maps[map:sub(1, -5)] = _gamemode[math.random(#_gamemode)]
                    amt = amt + 1
                    break
                end
            end

            if limit and amt >= limit then break end
        end
    end

    net.Start( "RAM_MapVoteStart" )
        local amt = 0
        for _, _ in pairs( gamemodes ) do
            amt = amt + 1
        end
        net.WriteUInt( amt, 32 )
        
        for k, v in pairs( gamemodes ) do
            net.WriteString( k )
            net.WriteString( v[1] )
            net.WriteString( v[2] )
        end

        amt = 0
        for _, _ in pairs( vote_maps ) do
            amt = amt + 1
        end
        net.WriteUInt( amt, 32 )
        
        for map, gamemode in pairs( vote_maps ) do
            net.WriteString( map )
            net.WriteString( gamemode )
            net.WriteString( string.format( previewFormat, map ) )
            net.WriteUInt( MapVote.GetMapScore( map, gamemode ), 32 )
        end
        
        net.WriteUInt( length, 32 )
    net.Broadcast()
    
    MapVote.Allow = true
    MapVote.CurrentMaps = vote_maps
    MapVote.Votes = {}
    
    timer.Create( "RAM_MapVote", length, 1, function()
        MapVote.Allow = false
        local map_results = {}
        
        for _, v in pairs( MapVote.Votes ) do
            if not map_results[v] then
                map_results[v] = 0
            end
            map_results[v] = map_results[v] + 1
        end
        
        CoolDownDoStuff()

        local winner = table.GetWinningKey( map_results )
        
        if not winner then
            for k, _ in RandomPairs( MapVote.CurrentMaps ) do
                winner = k
                break
            end
        end
        
        net.Start( "RAM_MapVoteUpdate" )
            net.WriteUInt( MapVote.UPDATE_WIN, 8 )
            
            net.WriteString( winner )
        net.Broadcast()
        
        local map = MapVote.CurrentMaps[winner]

        timer.Simple( 4, function()
            hook.Run( "MapVoteChange", winner )
            RunConsoleCommand( "gamemode", map )
            RunConsoleCommand( "changelevel", winner )
        end)
    end)
end

hook.Add( "Shutdown", "RemoveRecentMaps", function()
    if file.Exists( "mapvote/recentmaps.txt", "DATA" ) then
        file.Delete( "mapvote/recentmaps.txt" )
    end
end)

function MapVote.Cancel()
    if MapVote.Allow then
        MapVote.Allow = false

        net.Start( "RAM_MapVoteCancel" )
        net.Broadcast()

        timer.Destroy( "RAM_MapVote" )
    end
end

hook.Add( "Initialize", "InitPostEntity", function()
    function GAMEMODE:StartGamemodeVote()
        MapVote.Start( nil, nil, nil, nil )
    end
end)
