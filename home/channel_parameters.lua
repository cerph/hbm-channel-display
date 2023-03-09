local c = require("component")
local GPU = c.gpu
local console = c.rbmk_console
local term = require("term")
local GUI = require("GUI")
local buffer = require("doubleBuffering")

--------------------------------------------------------------------------------

GPU.setResolution(120, 60)

--------------------------------------------------------------------------------

left_margin = 1
right_margin = 0
top_margin = 1
bottom_margin = 0

background_color = 0xFFFFFF
bg_color = 0x000000

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
        for y=15, 1, -1 do
            container:addChild(GUI.label((((x-1)*9)+2)-x, (((y-1)*5)+2)-y, container.width, container.height, 0x1B1B1B, ((x-1)*15)+(15-y)))
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
    container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)+3)-lay_y, container.width, container.height, 0xFFFFFF, label))

    return canvas
end

--------------------------------------------------------------------------------
-- DYNAMIC TEXT RENDERING

local function text_control_rod(lay_x, lay_y, alert, insert)
    -- rod insertion %
    text_container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)+3)-lay_y, container.width, container.height, 0xFFFFFF, string.format("IN %.0f", 100-(insert*100))))

    -- alert
    if not(alert == nil) then
        text_container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)+4)-lay_y, container.width, container.height, 0xFF0000, alert))
    end
end

local function text_fuel_rod(lay_x, lay_y, alert, skin_temp)
    -- core skin temp
    text_container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)+3)-lay_y, container.width, container.height, 0xFFFFFF, string.format("C %.0f", skin_temp)))

    -- alert
    if (alert) then
        text_container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)+4)-lay_y, container.width, container.height, 0xFF0000, alert))
    end
end

local function text_base_column(lay_x, lay_y, alert)
    -- alert
    if (alert) then
        text_container:addChild(GUI.label((((lay_x-1)*9)+3)-lay_x, (((lay_y-1)*5)+4)-lay_y, container.width, container.height, 0xFF0000, alert))
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
for x=1, 15 do
    for y=15, 1, -1 do
        braille = GUI.brailleCanvas(1, 1, 8, 4)

        column = blank(x, y, braille)
        
        column_data = console.getColumnData(tostring(((x-1)*15)+(15-y)))
        
        if column_data then
            occupied_indexes[((x-1)*15)+(15-y)] = {x = x, y = y}

            container:addChild(GUI.label((((x-1)*9)+2)-x, (((y-1)*5)+2)-y, container.width, container.height, 0xFFFFFF, ((x-1)*15)+(15-y)))

            column_type = column_data[1]
            color = color_lookup[tonumber(column_data[7])]

            if (column_type == "CONTROL") then
                column = control_rod(x, y, braille, color)
            elseif (column_type == "FUEL_SIM") then
                column = fuel_rod(x, y, braille)
            elseif (column_type == "REFLECTOR") then
                column = base_column(x, y, braille, "REF")
            elseif (column_type == "ABSORBER") then
                column = base_column(x, y, braille, "ABS")
            elseif (column_type == "BLANK") then
                column = base_column(x, y, braille, "")
            elseif (column_type == "STORAGE") then
                column = base_column(x, y, braille, "STORE")
            end
        end

        pos = grid_layout:setPosition(x, y, grid_layout:addChild(column))
    end
end

-- MAIN (TEXT) RENDER LOOP
while true do
    text_container = workspace:addChild(GUI.container(left_margin, top_margin, workspace.width-right_margin, workspace.height-bottom_margin))

    for k, v in pairs(occupied_indexes) do
        column_data = console.getColumnData(tostring(k))

        column_type   = column_data[1]
        hull_temp     = tonumber(column_data[2])
        water         = tonumber(column_data[3])
        steam         = tonumber(column_data[4])
        moderated     = column_data[5]
        level         = tonumber(column_data[6])
        color         = tonumber(column_data[7])
        enrichment    = tonumber(column_data[8])
        xenon         = tonumber(column_data[9])
        skin_temp     = tonumber(column_data[10])
        core_temp     = tonumber(column_data[11])
        max_skin_temp = tonumber(column_data[12])

        alert = "      "

        if (hull_temp > 1200) then
            alert = "TEMP"
        elseif (water < 14000) then
            alert = "COOLEN"
        end

        if (column_type == "CONTROL") then
            text_control_rod(v.x, v.y, alert, level)
        elseif (column_type == "FUEL_SIM") then
            if ((skin_temp > max_skin_temp-300) and (max_skin_temp ~= 0)) then
                alert = "[TEMP]"
            elseif (xenon > 10) then
                alert = "POISON"
            elseif ((((1 - enrichment) * 100000)) / 1000 > 75) then
                alert = "DEPLET"
            end
            text_fuel_rod(v.x, v.y, alert, skin_temp)
        elseif (column_type == "REFLECTOR") then
            text_base_column(v.x, v.y, alert)
        elseif (column_type == "ABSORBER") then
            text_base_column(v.x, v.y, alert)
        elseif (column_type == "BLANK") then
            text_base_column(v.x, v.y, alert)
        elseif (column_type == "STORAGE") then
            text_base_column(v.x, v.y, alert)
        end

    end

    update_screen()
    text_container:remove()
end

