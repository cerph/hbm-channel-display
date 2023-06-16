local c = require("component")
local GPU = c.gpu
local console = c.rbmk_console
local term = require("term")
local GUI = require("GUI")
local buffer = require("doubleBuffering")

--------------------------------------------------------------------------------

args = {...}
if (args[1] == 'true') then 
    is_reasim = true
end

if (#args < 1) then
    print("Usage: channel_parameters reasim={true|false}")
    os.exit()
end

--------------------------------------------------------------------------------

GPU.setResolution(126, 63)
GPU.setResolution(120, 60)

--------------------------------------------------------------------------------

left_margin = 1
right_margin = 0
top_margin = 1
bottom_margin = 0

background_color = 0xFFFFFF
bg_color = 0x000000

no_alert = "      "

local workspace = GUI.workspace()
workspace:addChild(GUI.panel(1, 1, workspace.width, workspace.height, background_color))

local container = workspace:addChild(GUI.container(left_margin, top_margin, workspace.width-right_margin, workspace.height-bottom_margin))
container:addChild(GUI.panel(1, 1, container.width, container.height, bg_color))

--------------------------------------------------------------------------------

local function layout_size(layout)
    column_width = 8
    row_height = 4

    for i=1, 15 do
        layout:setColumnWidth(i, GUI.SIZE_POLICY_ABSOLUTE, column_width)
        layout:setRowHeight(i, GUI.SIZE_POLICY_ABSOLUTE, row_height)
    end
end

--------------------------------------------------------------------------------

local function update_screen()
    workspace:draw()
    buffer.drawChanges()
end

local function render_indexes()
    for x=1, 15 do
        for y=1, 15 do
            container:addChild(GUI.label((((x-1)*9)+2)-x, (((y-1)*5)+2)-y, container.width, container.height, 0x1B1B1B, (((y-1)*15)+x)-1))
        end
    end
end

--------------------------------------------------------------------------------
-- STATIC GRID RENDERING

local function blank(lay_x, lay_y, canvas)
    color = 0x1B1B1B
    -- borders
    for z=1, 16 do
        canvas:set(z, 1, true, color)
        canvas:set(z, 16, true, color)
        canvas:set(16, z, true, color)
        canvas:set(1, z, true, color)
    end

    return canvas
end

local function control_rod(lay_x, lay_y, canvas, color)
    -- borders
    for z=1, 16 do
        canvas:set(z, 1, true, color)
        canvas:set(z, 16, true, color)
        canvas:set(16, z, true, color)
        canvas:set(1, z, true, color)
    end

    return canvas
end

local function fuel_rod(lay_x, lay_y, canvas)
    -- color = 0xFF8C00
    color = 0x00FFF0
    -- borders
    for z=1, 16 do
        canvas:set(z, 1, true, color)
        canvas:set(z, 16, true, color)
        canvas:set(16, z, true, color)
        canvas:set(1, z, true, color)
    end

    return canvas
end

local function base_column(lay_x, lay_y, canvas, label, alert, color)
    color = color or 0xFFFFFF
    -- borders
    for z=1, 16 do
        canvas:set(z, 1, true, color)
        canvas:set(z, 16, true, color)
        canvas:set(16, z, true, color)
        canvas:set(1, z, true, color)
    end

    -- static label
    -- text_container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)-1)-lay_y, container.width, container.height, 0xFFFFFF, label))

    return canvas
end

local function boiler(lay_x, lay_y, canvas)
    color = 0xFF602B
    -- borders
    for z=1, 16 do
        canvas:set(z, 1, true, color)
        canvas:set(z, 16, true, color)
        canvas:set(16, z, true, color)
        canvas:set(1, z, true, color)
    end

    return canvas
end

local function outgasser(lay_x, lay_y, canvas)
    color = 0xC688E2
    -- borders
    for z=1, 16 do
        canvas:set(z, 1, true, color)
        canvas:set(z, 16, true, color)
        canvas:set(16, z, true, color)
        canvas:set(1, z, true, color)
    end

    return canvas
end

--------------------------------------------------------------------------------
-- DYNAMIC TEXT RENDERING

local function text_base_column(lay_x, lay_y, alert, label)
    -- static label
    text_container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)-1)-lay_y, container.width, container.height, 0xFFFFFF, label))

    -- alert
    if (alert ~= no_alert) then
        text_container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)+0)-lay_y, container.width, container.height, 0xFF0000, alert))
    end
end

local function text_control_rod(lay_x, lay_y, alert, insert)
    -- rod insertion %
    text_container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)-1)-lay_y, container.width, container.height, 0xFFFFFF, string.format("IN %.0f", 100-(insert*100))))

    -- alert
    if (alert ~= no_alert) then
        text_container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)+0)-lay_y, container.width, container.height, 0xFF0000, alert))
    end
end

local function text_fuel_rod(lay_x, lay_y, alert, skin_temp, xenon)
    -- core skin temp
    text_container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)-1)-lay_y, container.width, container.height, 0xFFFFFF, string.format("C %.0f", skin_temp)))
    -- xenon amnt
    text_container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)-0)-lay_y, container.width, container.height, 0xFFFFFF, string.format("X %.0f", xenon).."%"))

    -- alert
    if (alert ~= no_alert) then
        text_container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)+0)-lay_y, container.width, container.height, 0xFF0000, alert))
    end
end

local function text_boiler(lay_x, lay_y, alert, water, steam)
    water = 100*(water/200000)
    steam = 100*(steam/20000000)

    text_container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)-1)-lay_y, container.width, container.height, 0xFFFFFF, string.format("W %.0f", water).."%"))
    text_container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)-0)-lay_y, container.width, container.height, 0xFFFFFF, string.format("S %.0f", steam).."%"))

    -- alert
    if (alert ~= no_alert) then
        text_container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)+0)-lay_y, container.width, container.height, 0xFF0000, alert))
    end
end

local function text_outgasser(lay_x, lay_y, alert, flux_progress)
    flux_progress = 100*(flux_progress / flux_required)

    text_container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)-1)-lay_y, container.width, container.height, 0xFFFFFF, string.format("P %.0f", flux_progress).."%"))

    -- alert
    if (alert ~= no_alert) then
        text_container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)+0)-lay_y, container.width, container.height, 0xFF0000, alert))
    end
end


--------------------------------------------------------------------------------


local color_lookup = {
    [0] = 0xFF0000,  -- RED
    [1] = 0xFFFF00,  -- YELLOW
    [2] = 0x00FF00,  -- GREEN
    [3] = 0x0000FF,  -- BLUE
    [4] = 0xFF00FF,  -- PURPLE
}

local occupied_indexes = {}

local grid_layout = container:addChild(GUI.layout(1, 1, container.width, container.height, 15, 15))
layout_size(grid_layout)
render_indexes()

-- POPULATE INDEX TABLE AND RENDER STATIC GRID
for y=1, 15 do
    for x=1, 15 do
        braille = GUI.brailleCanvas(1, 1, 8, 4)

        column = blank(x, y, braille)
        column_index = x-(15*y)+224
        column_data = console.getColumnData(x-1, y-1)

        if (column_data["type"] ~= nil) then
            occupied_indexes[column_index] = {_x = x-1, _y = y-1}

            container:addChild(GUI.label((8*x)-7, (-4*y)+61, container.width, container.height, 0xFFFFFF, column_index))

            column_type = column_data["type"]
            color = color_lookup[tonumber(column_data["color"])]

            if (column_type == "CONTROL") then
                column = control_rod(x, y, braille, color)
            elseif (column_type == "FUEL_SIM") then
                column = fuel_rod(x, y, braille)
            elseif (column_type == "FUEL") then
                column = fuel_rod(x, y, braille)
            elseif (column_type == "REFLECTOR") then
                column = base_column(x, y, braille, "REF")
            elseif (column_type == "ABSORBER") then
                column = base_column(x, y, braille, "ABS")
            elseif (column_type == "BLANK") then
                column = base_column(x, y, braille, "")
            elseif (column_type == "STORAGE") then
                column = base_column(x, y, braille, "STORE")
            elseif (column_type == "BOILER") then
                column = boiler(x, y, braille)
            elseif (column_type == "OUTGASSER") then
                column = outgasser(x, y, braille)
            else
                column = base_column(x, y, braille, "")
            end
        end

        pos = grid_layout:setPosition(x, 16-y, grid_layout:addChild(column))
    end
end


-- MAIN (TEXT) RENDER LOOP
while true do
    text_container = workspace:addChild(GUI.container(left_margin, top_margin, workspace.width-right_margin, workspace.height-bottom_margin))

    for k, v in pairs(occupied_indexes) do
        column_data = console.getColumnData(v._x, v._y)
        -- print(v._x)
        -- print(v._y)


        column_type   = column_data["type"]
        hull_temp     = tonumber(column_data["hullTemp"])
        water         = tonumber(column_data["realSimWater"])
        steam         = tonumber(column_data["realSimSteam"])
        moderated     = column_data["moderated"]
        level         = tonumber(column_data["level"])
        color         = tonumber(column_data["color"])
        enrichment    = tonumber(column_data["enrichment"])
        xenon         = tonumber(column_data["xenon"])
        skin_temp     = tonumber(column_data["coreSkinTemp"])
        core_temp     = tonumber(column_data["coreTemp"])
        max_skin_temp = tonumber(column_data["coreMaxTemp"])
		--
		flux_slow     = tonumber(column_data["fluxSlow"])
		flux_fast     = tonumber(column_data["fluxFast"])
		boiler_water  = tonumber(column_data["water"])
		boiler_steam  = tonumber(column_data["steam"])
		flux_progress = tonumber(column_data["fluxProgress"])
		flux_required = tonumber(column_data["requiredFlux"])
		

        alert = no_alert

        if (hull_temp > 1200) then
            alert = "TEMP"
        end

        if (is_reasim) then
            if (water < 14000) then
                alert = "COOLEN"
            end
        end

        -- listen, the coords made sense on the old interface, im too lazy to make it make sense here
        v.y = 16-v._y
        v.x = v._x+1

        if (column_type == "CONTROL") then
            text_control_rod(v.x, v.y, alert, level)
        elseif (column_type == "FUEL_SIM") then
            if ((skin_temp > max_skin_temp-300) and (max_skin_temp ~= 0)) then
                alert = "[TEMP]"
            elseif (xenon > 15) then
                alert = "POISON"
            elseif ((((1 - enrichment) * 100000)) / 1000 > 75) then
                alert = "DEPLET"
            end
            text_fuel_rod(v.x, v.y, alert, skin_temp, xenon)
        elseif (column_type == "FUEL") then
            if ((skin_temp > max_skin_temp-300) and (max_skin_temp ~= 0)) then
                alert = "[TEMP]"
            elseif (xenon > 15) then
                alert = "POISON"
            elseif ((((1 - enrichment) * 100000)) / 1000 > 75) then
                alert = "DEPLET"
            end
            text_fuel_rod(v.x, v.y, alert, skin_temp, xenon)
        elseif (column_type == "REFLECTOR") then
            text_base_column(v.x, v.y, alert, "REF")
        elseif (column_type == "ABSORBER") then
            text_base_column(v.x, v.y, alert, "ABS")
        elseif (column_type == "BLANK") then
            text_base_column(v.x, v.y, alert, "")
        elseif (column_type == "STORAGE") then
            text_base_column(v.x, v.y, alert, "STORE")
        elseif (column_type == "MODERATOR") then
            text_base_column(v.x, v.y, alert, "MOD")
        elseif (column_type == "BOILER") then
            text_boiler(v.x, v.y, alert, boiler_water, boiler_steam)
        elseif (column_type == "OUTGASSER") then
            text_outgasser(v.x, v.y, alert, flux_progress, flux_required)
        else 
            text_base_column(v.x, v.y, alert, "")
        end

    ::continue::
    end

    os.sleep(0.001)
    update_screen()
    text_container:remove()
end

