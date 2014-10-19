util.AddNetworkString( "RAM_MapVoteStart" )
util.AddNetworkString( "RAM_MapVoteUpdate" )
util.AddNetworkString( "RAM_MapVoteCancel" )
util.AddNetworkString( "RAM_MapVoteFile" )
util.AddNetworkString( "RTV_Delay" )

MapVote.Continued = false

net.Receive( "RAM_MapVoteUpdate", function( len, ply )
    if MapVote.Allow then
        if IsValid(ply) then
            local update_type = net.ReadUInt( 3 )
            
            if update_type == MapVote.UPDATE_VOTE then
                local map = net.ReadString()
                
                if MapVote.CurrentMaps[map] then
                    MapVote.Votes[ply:SteamID()] = map
                    
                    net.Start( "RAM_MapVoteUpdate" )
                        net.WriteUInt( MapVote.UPDATE_VOTE, 3 )
                        net.WriteEntity( ply )
                        net.WriteString( map )
                    net.Broadcast()
                end
            end
        end
    end
end)

function MapVote.SendDir( player, dir, clientdir )
    if !file.Exists( dir, "GAME" ) then
        print( "Directory '" .. dir .. "' is missing!" )
        return
    end
    local files, dirs = file.Find( dir .. "/*", "GAME" )
    for _, fdir in pairs( dirs ) do
        if fdir != ".svn" then
            MapVote.SendDir( player, dir .. "/" .. fdir, clientdir .. "/" .. fdir )
        end
    end
 
    for k, v in pairs( files ) do
        MapVote.SendFile( player, dir .. "/" .. v, clientdir .. "/" .. v )
    end
end

function MapVote.SendFile( player, path, clientdir )
    local content = file.Read( path, "GAME" )
    net.Start( "RAM_MapVoteFile" )
        net.WriteString( clientdir )
        net.WriteString( content )
    net.Broadcast()
end 

hook.Add( "PlayerInitialSpawn", "MapVotePlayerConnect", function( player )
    MapVote.SendDir( player, "lua/mapvote/html", "mapvote/html" )
end)

if file.Exists( "mapvote/recentmaps.txt", "DATA" ) then
    recentmaps = util.JSONToTable( file.Read( "mapvote/recentmaps.txt", "DATA" ) )
else
    recentmaps = {}
end

if file.Exists( "mapvote/config.txt", "DATA" ) then
    MapVote.Config = util.JSONToTable( file.Read( "mapvote/config.txt", "DATA" ) )
else
    MapVote.Config = {}
end

function CoolDownDoStuff()
    cooldownnum = MapVote.Config.MapsBeforeRevote or 3

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
    cooldown = MapVote.Config.EnableCooldown or true
    prefix = prefix or MapVote.Config.MapPrefixes
    local gamemodes = MapVote.Config.Gamemodes or {}
    local previewFormat = MapVote.Config.MapPreviewURLs or "asset://garrysmod/materials/maps/%s.png"
    
    local maps = file.Find( "maps/*.bsp", "GAME" )
    
    local vote_maps = {}
    
    local amt = 0

    for k, map in RandomPairs( maps ) do
        local mapstr = map:sub( 1, -5 ):lower()
        if not current and game.GetMap():lower() .. ".bsp" == map then continue end
        if cooldown and table.HasValue( recentmaps, map ) then continue end

        for _prefix, _gamemode in pairs( prefix ) do
            if string.find( map, "^" .. _prefix ) then
                vote_maps[map:sub(1, -5)] = _gamemode[math.random(#_gamemode)]
                amt = amt + 1
                break
            end
        end
        
        if limit and amt >= limit then break end
    end
    
    net.Start( "RAM_MapVoteStart" )
        local amt = 0
        for k, v in pairs( gamemodes ) do
            amt = amt + 1
        end
        net.WriteUInt(amt, 32)
        
        for k, v in pairs( gamemodes ) do
            net.WriteString( k )
            net.WriteString( v[1] )
            net.WriteString( v[2] )
        end
        
        amt = 0
        for k, v in pairs( vote_maps ) do
            amt = amt + 1
        end
        net.WriteUInt(amt, 32)
        
        for k, v in pairs( vote_maps ) do
            net.WriteString( k )
            net.WriteString( v )
            net.WriteString( string.format( previewFormat, k ) )
        end
        
        net.WriteUInt( length, 32 )
    net.Broadcast()
    
    MapVote.Allow = true
    MapVote.CurrentMaps = vote_maps
    MapVote.Votes = {}
    
    timer.Create( "RAM_MapVote", length, 1, function()
        MapVote.Allow = false
        local map_results = {}
        
        for k, v in pairs( MapVote.Votes ) do
            if not map_results[v] then
                map_results[v] = 0
            end
            map_results[v] = map_results[v] + 1
        end
        
        CoolDownDoStuff()

        local winner = table.GetWinningKey( map_results )
        
        if not winner then
            for k, v in RandomPairs( MapVote.CurrentMaps ) do
                winner = k
                break
            end
        end
        
        net.Start( "RAM_MapVoteUpdate" )
            net.WriteUInt( MapVote.UPDATE_WIN, 3 )
            
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