surface.CreateFont("RAM_VoteFont", {
    font = "Trebuchet MS",
    size = 19,
    weight = 700,
    antialias = true,
    shadow = true
})

surface.CreateFont("RAM_VoteFontGamemode", {
    font = "Trebuchet MS",
    size = 19,
    antialias = true,
    shadow = true,
    outline = true
})

surface.CreateFont("RAM_VoteFontCountdown", {
    font = "Tahoma",
    size = 32,
    weight = 700,
    antialias = true,
    shadow = true
})

surface.CreateFont("RAM_VoteSysButton", 
{    font = "Marlett",
    size = 13,
    weight = 0,
    symbol = true,
})

MapVote.EndTime = 0
MapVote.Panel = false

net.Receive("RAM_MapVoteStart", function()
    MapVote.CurrentMaps = {}
    MapVote.Allow = true
    MapVote.Votes = {}
    
    local amt = net.ReadUInt(32)
    
    for i = 1, amt do
        local map = net.ReadString()
        local gamemode = net.ReadString()
        
        MapVote.CurrentMaps[#MapVote.CurrentMaps + 1] = { map, gamemode }
    end
    
    MapVote.EndTime = CurTime() + net.ReadUInt(32)
    
    if(IsValid(MapVote.Panel)) then
        MapVote.Panel:Remove()
    end
    
    MapVote.Panel = vgui.Create("RAM_VoteScreen")
    MapVote.Panel:SetMaps(MapVote.CurrentMaps)
end)

net.Receive("RAM_MapVoteUpdate", function()
    local update_type = net.ReadUInt(3)
    
    if(update_type == MapVote.UPDATE_VOTE) then
        local ply = net.ReadEntity()
        
        if(IsValid(ply)) then
            local map_id = net.ReadUInt(32)
            MapVote.Votes[ply:SteamID()] = map_id
        
            if(IsValid(MapVote.Panel)) then
                MapVote.Panel:AddVoter(ply)
            end
        end
    elseif(update_type == MapVote.UPDATE_WIN) then      
        if(IsValid(MapVote.Panel)) then
            MapVote.Panel:Flash(net.ReadUInt(32))
        end
    end
end)

net.Receive("RAM_MapVoteCancel", function()
    if IsValid(MapVote.Panel) then
        MapVote.Panel:Remove()
    end
end)

net.Receive("RTV_Delay", function()
    chat.AddText(Color( 102,255,51 ), "[RTV]", Color( 255,255,255 ), " The vote has been rocked, map vote will begin on round end")
end)

local PANEL = {}

function PANEL:Init()
    self:ParentToHUD()
    
    self.Canvas = vgui.Create("Panel", self)
    self.Canvas:MakePopup()
    self.Canvas:SetKeyboardInputEnabled(false)
    --[[ Use to test spacing
    self.Canvas.Paint = function(s, w, h)
        local col = Color(255, 255, 255, 10)
        
        draw.RoundedBox(4, 0, 0, w, h, col)
    end
    --]]
    
    self.countDown = vgui.Create("DLabel", self.Canvas)
    self.countDown:SetTextColor(color_white)
    self.countDown:SetFont("RAM_VoteFontCountdown")
    self.countDown:SetText("Initializing...")
    self.countDown:SetPos(0, 14)
    self.countDown:SizeToContents()
    self.countDown:CenterHorizontal()
    
    self.mapList = vgui.Create("DPanelList", self.Canvas)
    self.mapList:SetDrawBackground(true)
    self.mapList:SetSpacing(4)
    self.mapList:SetPadding(4)
    self.mapList:EnableHorizontal(true)
    self.mapList:EnableVerticalScrollbar()
    
    self.closeButton = vgui.Create("DButton", self.Canvas)
    self.closeButton:SetText("")

    self.closeButton.Paint = function(panel, w, h)
        derma.SkinHook("Paint", "WindowCloseButton", panel, w, h)
    end

    self.closeButton.DoClick = function()
        print("HI")
        self:SetVisible(false)
    end

    --[[ Why are these even here?
    self.maximButton = vgui.Create("DButton", self.Canvas)
    self.maximButton:SetText("")
    self.maximButton:SetDisabled(true)

    self.maximButton.Paint = function(panel, w, h)
        derma.SkinHook("Paint", "WindowMaximizeButton", panel, w, h)
    end

    self.minimButton = vgui.Create("DButton", self.Canvas)
    self.minimButton:SetText("")
    self.minimButton:SetDisabled(true)

    self.minimButton.Paint = function(panel, w, h)
        derma.SkinHook("Paint", "WindowMinimizeButton", panel, w, h)
    end
    --]]

    self.Voters = {}
end

function PANEL:PerformLayout()
    local cx, cy = chat.GetChatBoxPos()
    
    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())
        
    local extra = math.Clamp(300, 0, ScrW() - 624)
    self.Canvas:StretchToParent(0, 0, 0, 0)
    self.Canvas:SetWide(624 + extra)
    self.Canvas:SetTall(cy - 20)
    self.Canvas:SetPos(0, 20)
    self.Canvas:CenterHorizontal()
    self.Canvas:SetZPos(0)
    
    self.mapList:StretchToParent(0, 90, 0, 0)

    local buttonPos = 624 + extra - 30

    self.closeButton:SetPos(buttonPos, -4)
    self.closeButton:SetSize(31, 31)
    self.closeButton:SetVisible(true)

    --[[
    self.maximButton:SetPos(buttonPos - 31 * 1, 4)
    self.maximButton:SetSize(31, 31)
    self.maximButton:SetVisible(true)

    self.minimButton:SetPos(buttonPos - 31 * 2, 4)
    self.minimButton:SetSize(31, 31)
    self.minimButton:SetVisible(true)
    --]]
end

local heart_mat = Material("icon16/heart.png")
local star_mat = Material("icon16/star.png")
local shield_mat = Material("icon16/shield.png")

function PANEL:AddVoter(voter)
    for k, v in pairs(self.Voters) do
        if(v.Player and v.Player == voter) then
            return false
        end
    end
    
    
    local icon_container = vgui.Create("Panel", self.mapList:GetCanvas())
    local icon = vgui.Create("AvatarImage", icon_container)
    icon:SetSize(16, 16)
    icon:SetZPos(1000)
    icon:SetTooltip(voter:Name())
    icon_container.Player = voter
    icon_container:SetTooltip(voter:Name())
    icon:SetPlayer(voter, 16)

    if MapVote.HasExtraVotePower(voter) then
        icon_container:SetSize(40, 20)
        icon:SetPos(21, 2)
        icon_container.img = star_mat
    else
        icon_container:SetSize(20, 20)
        icon:SetPos(2, 2)
    end
    
    icon_container.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(255, 0, 0, 80))
        
        if(icon_container.img) then
            surface.SetMaterial(icon_container.img)
            surface.SetDrawColor(Color(255, 255, 255))
            surface.DrawTexturedRect(2, 2, w / 2 - 2, h - 4)
        end
    end
    
    do
        local OrigSetSize = icon_container.SetSize
        icon_container.SetSize = function(s, w, h)
            if MapVote.HasExtraVotePower(voter) then
                icon:SetPos(h + 2, 2)
                icon:SetSize(h - 4, h - 4)
                OrigSetSize(s, h * 2, h)
            else
                icon:SetPos(2, 2)
                icon:SetSize(h - 4, h - 4)
                OrigSetSize(s, h, h)
            end
        end
    end
    
    table.insert(self.Voters, icon_container)
end

function PANEL:Think()
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
    
    local timeLeft = math.Round(math.Clamp(MapVote.EndTime - CurTime(), 0, math.huge))
    
    self.countDown:SetText(tostring(timeLeft or 0).." seconds")
    self.countDown:SizeToContents()
    self.countDown:CenterHorizontal()
end

function PANEL:SetMaps(maps)
    self.mapList:Clear()
    
    for k, v in RandomPairs(maps) do
        local button = vgui.Create("DButton", self.mapList)
        button.ID = k
        button:SetText("")
        
        button.DoClick = function()
            net.Start("RAM_MapVoteUpdate")
                net.WriteUInt(MapVote.UPDATE_VOTE, 3)
                net.WriteUInt(button.ID, 32)
            net.SendToServer()
        end
        
        local extra = math.Clamp(300, 0, ScrW() - 624)
        local width = (extra + 600) / 5
        local height = width + 60
        local mapName = v[1]
        local gamemode = v[2]
        
        do
            local Paint = button.Paint
            button.Paint = function(s, w, h)
                local col = Color(255, 255, 255, 10)
                
                if(button.bgColor) then
                    col = button.bgColor
                end
                
                draw.RoundedBox(4, 0, 0, w, h, col)
                draw.DrawText(mapName, "RAM_VoteFont", width / 2, width - 6, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
                --draw.DrawText(gamemode, "RAM_VoteFontGamemode", width / 2, width - 18, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
                --draw.SimpleTextOutlined( string Text, string font, number x, number y, table color, number xAlign, number yAlign, number outlinewidth, table outlinecolor )
                draw.SimpleTextOutlined( gamemode, "RAM_VoteFont", width / 2, width + 16, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 255) )
                Paint(s, w, h)
            end
        end
        
        button:SetTextColor(color_white)
        button:SetContentAlignment(4)
        --button:SetTextInset(8, 0)
        button:SetFont("RAM_VoteFont")
        
        button:SetDrawBackground(false)
        button:SetTall(height)
        button:SetWide(width)
        button.NumVotes = 0
        
        --local icon = vgui.Create("DImage", button)
        --icon:SetSize(width - 8, width - 8)
        --icon:SetPos(4, 4)
        --icon:SetImage("maps/" .. v, "vgui/avatar_default")
        
        local html = vgui.Create( "HTML", button)
        html:SetSize(width - 8, width - 8)
        html:SetPos(4,4)
        local hCode = "<style type='text/css'> body {overflow:hidden; }</style><body><img src=http://mrblue.specialattack.net/gmod/maps/" .. mapName .. ".png width=100% height=100%></body>"
        html:SetHTML(hCode)
        
        self.mapList:AddItem(button)
    end
end

function PANEL:GetMapButton(id)
    for k, v in pairs(self.mapList:GetItems()) do
        if(v.ID == id) then return v end
    end
    
    return false
end

function PANEL:Paint()
    --Derma_DrawBackgroundBlur(self)
    
    local CenterY = ScrH() / 2
    local CenterX = ScrW() / 2
    
    surface.SetDrawColor(0, 0, 0, 200)
    surface.DrawRect(0, 0, ScrW(), ScrH())
end

function PANEL:Flash(id)
    self:SetVisible(true)

    local bar = self:GetMapButton(id)
    
    if(IsValid(bar)) then
        timer.Simple( 0.0, function() bar.bgColor = Color( 0, 255, 255 ) surface.PlaySound( "hl1/fvox/blip.wav" ) end )
        timer.Simple( 0.2, function() bar.bgColor = nil end )
        timer.Simple( 0.4, function() bar.bgColor = Color( 0, 255, 255 ) surface.PlaySound( "hl1/fvox/blip.wav" ) end )
        timer.Simple( 0.6, function() bar.bgColor = nil end )
        timer.Simple( 0.8, function() bar.bgColor = Color( 0, 255, 255 ) surface.PlaySound( "hl1/fvox/blip.wav" ) end )
        timer.Simple( 1.0, function() bar.bgColor = Color( 100, 100, 100 ) end )
    end
end

derma.DefineControl("RAM_VoteScreen", "", PANEL, "DPanel")
