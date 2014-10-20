surface.CreateFont( "RAM_VoteFont", {
    font = "Trebuchet MS",
    size = 19,
    weight = 700,
    antialias = true,
    shadow = true
})

surface.CreateFont( "RAM_VoteFontGamemode", {
    font = "Trebuchet MS",
    size = 19,
    antialias = true,
    shadow = true,
    outline = true
})

surface.CreateFont( "RAM_VoteFontCountdown", {
    font = "Tahoma",
    size = 32,
    weight = 700,
    antialias = true,
    shadow = true
})

surface.CreateFont( "RAM_VoteSysButton", 
{    font = "Marlett",
    size = 13,
    weight = 0,
    symbol = true,
})

MapVote.EndTime = 0
MapVote.Panel = false
MapVote.Players = {}

net.Receive( "RAM_MapVoteStart", function()
    MapVote.CurrentMaps = {}
    MapVote.CurrentGamemodes = {}
    MapVote.Allow = true
    MapVote.Votes = {}
    
    local amt = net.ReadUInt(32)
    
    for i = 1, amt do
        local name = net.ReadString()
        local shorthand = net.ReadString()
        local color = net.ReadString()
        
        MapVote.CurrentGamemodes[name] = { shorthand, color }
    end
    
    amt = net.ReadUInt(32)
    
    for i = 1, amt do
        local map = net.ReadString()
        local gamemode = net.ReadString()
        local previewURL = net.ReadString()
        
        MapVote.CurrentMaps[map] = { gamemode, previewURL }
    end
    
    MapVote.EndTime = CurTime() + net.ReadUInt(32)
    
    if IsValid( MapVote.Panel ) then
        MapVote.Panel:Remove()
    end
    
    MapVote.Panel = vgui.Create( "RAM_VoteScreen" )
    MapVote.Panel:SetGamemodes( MapVote.CurrentGamemodes )
    MapVote.Panel:SetMaps( MapVote.CurrentMaps )
end)

net.Receive( "RAM_MapVoteUpdate", function()
    local update_type = net.ReadUInt( 3 )
    
    if update_type == MapVote.UPDATE_VOTE then
        local ply = net.ReadEntity()
        
        if IsValid( ply ) then
            local map = net.ReadString() -- 
            if not MapVote.Players[ply:SteamID()] then
                local addr = "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=FA00819718A65791DEA67E7DCFEC1B74&steamids=" .. ply:SteamID64() .. "?format=xml"
                local count = 0
                local HTTPRequest = {
                    url = addr,
                    method = "get",
                    success = function( code, body, headers )
                        if code == 0 or #body == 0 then
                            print( "Failed getting player info! Length: " .. #body .. "; Code: " .. code )
                            MapVote.Players[ply:SteamID()] = ply:SteamID64()
                            MapVote.Panel:AddVoterInfo( ply, MapVote.Players[ply:SteamID()] )
                        else
                            MapVote.Players[ply:SteamID()] = body
                            MapVote.Panel:AddVoterInfo( ply, MapVote.Players[ply:SteamID()] )
                        end
                    end,
                    failed = function( reason )
                        print( "Failed getting player info! Reason: " .. reason )
                        MapVote.Players[ply:SteamID()] = ply:SteamID64()
                        MapVote.Panel:AddVoterInfo( ply, MapVote.Players[ply:SteamID()] )
                    end
                }
                HTTP( HTTPRequest )
            end
            MapVote.Votes[ply:SteamID()] = map
            
            if IsValid( MapVote.Panel ) then
                MapVote.Panel:AddVoter( ply, map )
            end
        end
    elseif update_type == MapVote.UPDATE_WIN then      
        if IsValid( MapVote.Panel ) then
            MapVote.Panel:Flash( net.ReadString() )
        end
    end
end)

net.Receive( "RAM_MapVoteCancel", function()
    if IsValid( MapVote.Panel ) then
        MapVote.Panel:Remove()
    end
end)

net.Receive( "RTV_Delay", function()
    chat.AddText( Color( 102,255,51 ), "[RTV]", Color( 255,255,255 ), " The vote has been rocked, map vote will begin on round end" )
end)

net.Receive( "RAM_MapVoteFile", function()
    local path = net.ReadString()
    local content = net.ReadString()
    path = string.StripExtension( path ) .. ".txt"
    file.CreateDir( string.GetPathFromFilename( path ) )
    file.Write( path, content )
end)

local PANEL = {}

function PANEL:Init()
    --self:ParentToHUD()
    self:Dock( FILL )
    self:SetZPos( 2000 )
    
    self.HTML = vgui.Create( "DHTML", self )
    
    self.HTML:Dock( FILL )
    self.HTML:OpenURL( "asset://garrysmod/data/mapvote/html/mapvote.txt" )
    self.HTML:SetMouseInputEnabled( true )
    self.HTML:SetKeyboardInputEnabled( false )
    self.HTML:SetAllowLua( true )
    self.HTML:AddFunction( "MapVoteLua", "Vote", function( map )
        if map then
            net.Start( "RAM_MapVoteUpdate" )
                net.WriteUInt( MapVote.UPDATE_VOTE, 3 )
                net.WriteString( map )
            net.SendToServer()
        end
    end)
    self.HTML:RequestFocus()
    
    self:MakePopup()
    self:SetKeyboardInputEnabled( false )
    
    --[[
    self.closeButton = vgui.Create("DButton", self.Canvas)
    self.closeButton:SetText("")

    self.closeButton.Paint = function(panel, w, h)
        derma.SkinHook("Paint", "WindowCloseButton", panel, w, h)
    end

    self.closeButton.DoClick = function()
        print("HI")
        self:SetVisible(false)
    end
    --]]

    self.Voters = {}
end

function PANEL:AddVoterInfo( ply, info )
    local data = util.JSONToTable( info )
    --print( string.format( "MapVote.AddVoterAvatar( %q, %q )", ply:GetName(), data["response"]["players"][1]["avatar"] ) )
    self.HTML:Call( string.format( "MapVote.AddVoterAvatar( %q, %q )", ply:GetName(), data["response"]["players"][1]["avatar"] ) )
end

function PANEL:AddVoter( ply, map )
    --print( string.format( "MapVote.AddVoter( %q, %q )", ply:GetName(), map ) )
    self.HTML:Call( string.format( "MapVote.AddVoter( %q, %q )", ply:GetName(), map ) )
    if MapVote.Players[ply:SteamID()] then
        self:AddVoterInfo( ply, MapVote.Players[ply:SteamID()] )
    end
end

function PANEL:Think()
    --[[
    for k, v in pairs(self.mapList:GetItems()) do
        v.PrevVotes = v.NumVotes or 0
        v.NumVotes = 0
    end
    
    local extra = math.Clamp(300, 0, ScrW() - 624)
    local width = (extra + 600) / 5 - 4
    
    for k, v in pairs(self.Voters) do
        if(not IsValid(v.Player)) then
            v:Remove()
        else
            if(not MapVote.Votes[v.Player:SteamID()]) then
                v:Remove()
            else
                local bar = self:GetMapButton(MapVote.Votes[v.Player:SteamID()])
                local currentVotes = bar.NumVotes
                
                if(MapVote.HasExtraVotePower(v.Player)) then
                    bar.NumVotes = bar.NumVotes + 2
                else
                    bar.NumVotes = bar.NumVotes + 1
                end
                
                if(IsValid(bar)) then
                    local CurrentPos = Vector(v.x, v.y, 0)
                    local NewPos = nil
                    local NewSize = nil
                    --if (bar.PrevVotes * 37 > width) then
                        local size = math.Clamp(32, 0, width / math.Clamp(bar.PrevVotes, 5, math.huge) - 5)
                        --NewPos = Vector(bar.x + (21 * currentVotes) % (bar.PrevVotes * 21) + 2, bar.y + bar:GetTall() - 39 + math.floor(currentVotes / (bar.PrevVotes * 21)) * 21, 0)
                        NewPos = Vector(bar.x + (size + 5) * currentVotes + 3, bar.y + bar:GetTall() - 39, 0)
                        NewSize = Vector(size + 4, size + 4, 0)
                    --else
                    --    NewPos = Vector(bar.x + 37 * currentVotes + 2, bar.y + bar:GetTall() - 39, 0)
                    --    NewSize = Vector(36, 36, 0)
                    --end
                    --local NewPos = Vector((bar.x + bar:GetWide()) - 21 * currentVotes - 1, bar.y + (bar:GetTall() * 0.5 - 10), 0)
                    
                    if(not v.CurPos or v.CurPos ~= NewPos) then
                        v:MoveTo(NewPos.x, NewPos.y, 0.3)
                        v.CurPos = NewPos
                    end
                    if(not v.CurSize or v.CurSize ~= NewSize) then
                        v:SizeTo(NewSize.x, NewSize.y, 0.3)
                        v.CurSize = NewSize
                    end
                end
            end
        end
        
    end
    --]]
    local timeLeft = math.Round(math.Clamp(MapVote.EndTime - CurTime(), 0, math.huge))
    
    self.HTML:Call( string.format( "MapVote.UpdateTimer( %q )", tostring(timeLeft or 0).." seconds" ) )
end

function PANEL:Paint()
end

function PANEL:SetGamemodes( gamemodes )
    for k, v in RandomPairs( gamemodes ) do
        self.HTML:Call( string.format( "MapVote.AddGamemode( %q, %q, %q )", k, v[1], v[2] ) )
    end
end

function PANEL:SetMaps( maps )
    for k, v in RandomPairs( maps ) do
        self.HTML:Call( string.format( "MapVote.AddMap( %q, %q, %q )", k, v[1], v[2] ) )
    end
end

function PANEL:Flash( map )
    self:SetVisible( true )
    
    local callon = string.format( "MapVote.BlinkMap( %q, true )", map )
    local calloff = string.format( "MapVote.BlinkMap( %q, false )", map )

    timer.Simple( 0.0, function() self.HTML:Call( callon ) surface.PlaySound( "hl1/fvox/blip.wav" ) end )
    timer.Simple( 0.2, function() self.HTML:Call( calloff ) end )
    timer.Simple( 0.4, function() self.HTML:Call( callon ) surface.PlaySound( "hl1/fvox/blip.wav" ) end )
    timer.Simple( 0.6, function() self.HTML:Call( calloff ) end )
    timer.Simple( 0.8, function() self.HTML:Call( callon ) surface.PlaySound( "hl1/fvox/blip.wav" ) end )
    timer.Simple( 1.0, function() self.HTML:Call( calloff ) end )
end

derma.DefineControl("RAM_VoteScreen", "", PANEL, "DPanel")
