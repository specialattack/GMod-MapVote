local function printf( s, ... )
    print( s:format(...) )
end

math.randomseed( os.time() )

local maps = {
    { ["name"] = "cs_assault.bsp",                   ["score"] = 3, ["gamemode"] = "prophunt" },
    { ["name"] = "cs_office.bsp",                    ["score"] = 2, ["gamemode"] = "prophunt" },
    { ["name"] = "de_aztec.bsp",                     ["score"] = 5, ["gamemode"] = "prophunt" },
    { ["name"] = "de_cbble.bsp",                     ["score"] = 4, ["gamemode"] = "prophunt" },
    { ["name"] = "de_dust2.bsp",                     ["score"] = 1, ["gamemode"] = "prophunt" },
    { ["name"] = "de_train.bsp",                     ["score"] = 3, ["gamemode"] = "prophunt" },
    { ["name"] = "mb_melonbomber.bsp",               ["score"] = 4, ["gamemode"] = "melonbomber" },
    { ["name"] = "cs_assault.bsp",                   ["score"] = 2, ["gamemode"] = "terrortown" },
    { ["name"] = "cs_office.bsp",                    ["score"] = 4, ["gamemode"] = "terrortown" },
    { ["name"] = "de_aztec.bsp",                     ["score"] = 1, ["gamemode"] = "terrortown" },
    { ["name"] = "de_cbble.bsp",                     ["score"] = 4, ["gamemode"] = "terrortown" },
    { ["name"] = "de_dust2.bsp",                     ["score"] = 2, ["gamemode"] = "terrortown" },
    { ["name"] = "de_train.bsp",                     ["score"] = 3, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_airbus_b3.bsp",                ["score"] = 5, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_bank_b3.bsp",                  ["score"] = 3, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_bb_teenroom_b2.bsp",           ["score"] = 2, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_biocube.bsp",                  ["score"] = 1, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_bunker.bsp",                   ["score"] = 4, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_camel_v1.bsp",                 ["score"] = 5, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_cloverfield_b4.bsp",           ["score"] = 3, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_cluedo_b5_improved1.bsp",      ["score"] = 1, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_community_pool_revamped.bsp",  ["score"] = 1, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_concentration_b2.bsp",         ["score"] = 5, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_construction_v3.bsp",          ["score"] = 1, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_crummycradle_b1fix.bsp",       ["score"] = 5, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_desperados.bsp",               ["score"] = 4, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_elevatorandstairs.bsp",        ["score"] = 4, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_fg_sexy_render_v6a.bsp",       ["score"] = 4, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_fiskarna_v2.bsp",              ["score"] = 5, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_horizon_v1.bsp",               ["score"] = 5, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_intergalactic.bsp",            ["score"] = 2, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_island_2013.bsp",              ["score"] = 1, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_ldt_ghosttown.bsp",            ["score"] = 5, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_lordcharles_mansion_v6.bsp",   ["score"] = 4, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_mc_mineshaft.bsp",             ["score"] = 4, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_minecraft_b5.bsp",             ["score"] = 1, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_minecraft_mythic_b8.bsp",      ["score"] = 1, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_nightmare_church_b3.bsp",      ["score"] = 3, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_production.bsp",               ["score"] = 2, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_ravenville_a2.bsp",            ["score"] = 5, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_rooftops_a2_f1.bsp",           ["score"] = 1, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_scarisland_b1.bsp",            ["score"] = 4, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_skytower_b1-1.bsp",            ["score"] = 5, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_slumcity_b2.bsp",              ["score"] = 1, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_train_.bsp",                   ["score"] = 1, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_trouble_tower_v1.bsp",         ["score"] = 1, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_underside_a1.bsp",             ["score"] = 4, ["gamemode"] = "terrortown" },
    { ["name"] = "ttt_vessel.bsp",                   ["score"] = 2, ["gamemode"] = "terrortown" },
    { ["name"] = "xmas_nipperhouse.bsp",             ["score"] = 5, ["gamemode"] = "terrortown" },
}

printf( " %-33s   %-7s   %-12s", "Map name:", "Score:", "Gamemode:" )
print( "-----------------------------------------------------------" )

for _,map in pairs(maps) do
    printf( " %-33s | %-7d | %-12s", map["name"], map["score"], map["gamemode"] )
end

local function selectRandom( tbl )
   return tbl[ math.random( #tbl ) ]
end

local function selectMaps( maps, amount )
    local results = {}
    local total = 0

    for _,map in pairs(maps) do
        total = total + map["score"]
    end

    total = math.max( total, 1 )
    for _ = 1,amount do
        local i = total
        local row, bad
        while i > 0 or bad do
            row = selectRandom( maps )
            bad = false
            if row["score"] <= 0 then
                i = i - 9
            else
                i = i - row["score"] * row["score"]
            end

            if i <= 0 then
                for _,map in pairs(results) do
                    if map["name"] == row["name"] and map["gamemode"] == row["gamemode"] then
                        bad = true
                        break
                    end
                end
            end
        end

        results[ #results + 1 ] = row
    end

    return results
end

print( "" )
print( "Selected maps:" )
printf( " %-33s   %-7s   %-12s", "Map name:", "Score:", "Gamemode:" )
print( "-----------------------------------------------------------" )

local values = { "", "", "", "", "" }
for _ = 1,10 do
    local chosen = selectMaps( maps, 10 )
    for _, map in pairs(chosen) do
        --printf( " %-33s | %-7d | %-12s", map["name"], map["score"], map["gamemode"] )
        values[ map["score"] ] = (values[ map["score"] ] or "") .. "="
    end
end

for key,value in pairs(values) do
    printf( "%d: %s", key, value )
end
