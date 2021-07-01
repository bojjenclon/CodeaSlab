--[[

MIT License

Copyright (c) 2019-2020 Mitchell Davis <coding.jackalope@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR a PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]]
local Slab = required("Slab")
local DrawCommands = required("DrawCommands")
local Input = required("Input")
local Mouse = required("Mouse")
local Region = required("Region")
local Stats = required("Stats")
local Style = required("Style")
local tooltip = required("tooltip")
local Tree = required("Tree")
local Window = required("Window")

local SlabDebug = {}
local SlabDebug_About = "SlabDebug_About"
local SlabDebug_Mouse = {title = "Mouse", is_open = false}
local SlabDebug_Windows = {title = "Windows", is_open = false}
local SlabDebug_Regions = {title = "Regions", is_open = false}
local SlabDebug_Tooltip = {title = "tooltip", is_open = false}
local SlabDebug_DrawCommands = {title = "DrawCommands", is_open = false}
local SlabDebug_Performance = {title = "Performance", is_open = false}
local SlabDebug_StyleEditor = {
	title = "Style Editor",
	is_open = false,
	auto_size_window = false,
	allow_resize = true,
	w = 700.0,
	h = 500.0
}
local SlabDebug_Input = {title = "Input", is_open = false}
local SlabDebug_MultiLine = {title = "Multi-line Input", is_open = false}
local SlabDebug_MultiLine_FileDialog = false
local SlabDebug_MultiLine_FileName = ""
local SlabDebug_MultiLine_Contents = ""
local SlabDebug_Tree = {title = "Tree", is_open = false, auto_size_window = false, allow_resize = true}

local SlabDebug_Windows_Categories = {"Inspector", "stack"}
local SlabDebug_Windows_Category = "Inspector"
local SlabDebug_Regions_Selected = ""

local Selected_Window = ""

local Style_EditingColor = nil
local Style_ColorStore = nil
local Style_FileDialog = nil

local function Window_Inspector()
	local Ids = Window.get_instance_ids()
	if Slab.begin_combo_box("SlabDebug_Windows_Inspector", {selected = Selected_Window}) then
		for i, v in ipairs(Ids) do
			if Slab.text_selectable(v) then
				Selected_Window = v
			end
		end

		Slab.end_combo_box()
	end

	local info = Window.get_instance_info(Selected_Window)
	for i, v in ipairs(info) do
		Slab.text(v)
	end
end

local function Window_Stack()
	local stack = Window.get_stack_debug()
	Slab.text("stack: " .. #stack)
	for i, v in ipairs(stack) do
		Slab.text(v)
	end
end

local function DrawCommands_Item(root, label)
	if type(root) == "table" then
		if Slab.begin_tree(label) then
			for k, v in pairs(root) do
				DrawCommands_Item(v, k)
			end

			Slab.end_tree()
		end
	else
		Slab.begin_tree(label .. " " .. tostring(root), {is_leaf = true})
	end
end

local DrawPerformance_Category = nil
local DrawPerformance_WinX = 50.0
local DrawPerformance_WinY = 50.0
local DrawPerformance_ResetPosition = false
local DrawPerformance_Init = false
local DrawPerformance_W = 200.0

local function DrawPerformance()
	if not DrawPerformance_Init then
		Slab.enable_stats(true)
		DrawPerformance_Init = true
	end

	SlabDebug_Performance.x = DrawPerformance_WinX
	SlabDebug_Performance.y = DrawPerformance_WinY
	SlabDebug_Performance.reset_position = DrawPerformance_ResetPosition

	Slab.begin_window("SlabDebug_Performance", SlabDebug_Performance)
	DrawPerformance_ResetPosition = false

	local Categories = Stats.get_categories()

	if DrawPerformance_Category == nil then
		DrawPerformance_Category = Categories[1]
	end

	if Slab.begin_combo_box("DrawPerformance_Categories", {selected = DrawPerformance_Category, w = DrawPerformance_W}) then
		for i, v in ipairs(Categories) do
			if Slab.text_selectable(v) then
				DrawPerformance_Category = v
			end
		end

		Slab.end_combo_box()
	end

	if Slab.checkBox(Slab.is_stats_enabled(), "enabled") then
		Slab.enable_stats(not Slab.is_stats_enabled())
	end

	Slab.same_line()

	if Slab.button("flush") then
		Slab.flush_stats()
	end

	Slab.separator()

	if DrawPerformance_Category ~= nil then
		local items = Stats.get_items(DrawPerformance_Category)

		local pad = 50.0
		local MaxW = 0.0
		for i, v in ipairs(items) do
			MaxW = math.max(MaxW, Slab.get_text_width(v))
		end

		local cursor_x, cursor_y = Slab.get_cursor_pos()
		Slab.set_cursor_pos(MaxW * 0.5 - Slab.get_text_width("Stat") * 0.5)
		Slab.text("Stat")

		local TimeX = MaxW + pad
		local TimeW = Slab.get_text_width("time")
		local TimeItemW = Slab.get_text_width(string.format("%.4f", 0.0))
		Slab.set_cursor_pos(TimeX, cursor_y)
		Slab.text("time")

		local MaxTimeX = TimeX + TimeW + pad
		local MaxTimeW = Slab.get_text_width("max_val time")
		Slab.set_cursor_pos(MaxTimeX, cursor_y)
		Slab.text("max_val time")

		local CallCountX = MaxTimeX + MaxTimeW + pad
		local CallCountW = Slab.get_text_width("Call count")
		Slab.set_cursor_pos(CallCountX, cursor_y)
		Slab.text("Call count")

		DrawPerformance_W = CallCountX + CallCountW

		Slab.separator()

		for i, v in ipairs(items) do
			local time = Stats.get_time(v, DrawPerformance_Category)
			local max_time = Stats.get_max_time(v, DrawPerformance_Category)
			local call_count = Stats.get_call_count(v, DrawPerformance_Category)

			cursor_x, cursor_y = Slab.get_cursor_pos()
			Slab.set_cursor_pos(MaxW * 0.5 - Slab.get_text_width(v) * 0.5)
			Slab.text(v)

			Slab.set_cursor_pos(TimeX + TimeW * 0.5 - TimeItemW * 0.5, cursor_y)
			Slab.text(string.format("%.4f", time))

			Slab.set_cursor_pos(MaxTimeX + MaxTimeW * 0.5 - TimeItemW * 0.5, cursor_y)
			Slab.text(string.format("%.4f", max_time))

			Slab.set_cursor_pos(CallCountX + CallCountW * 0.5 - Slab.get_text_width(call_count) * 0.5, cursor_y)
			Slab.text(call_count)
		end
	end

	Slab.end_window()
end

local function EditColor(colour)
	Style_EditingColor = colour
	Style_ColorStore = {colour[1], colour[2], colour[3], colour[4]}
end

local function RestoreEditColor()
	Style_EditingColor[1] = Style_ColorStore[1]
	Style_EditingColor[2] = Style_ColorStore[2]
	Style_EditingColor[3] = Style_ColorStore[3]
	Style_EditingColor[4] = Style_ColorStore[4]
end

local function DrawStyleEditor()
	Slab.begin_window("SlabDebug_StyleEditor", SlabDebug_StyleEditor)
	local x, y = Slab.get_window_position()
	local w, h = Slab.get_window_size()

	local Style = Slab.get_style()
	local Names = Style.API.GetStyleNames()
	local CurrentStyle = Style.API.GetCurrentStyleName()
	Slab.begin_layout("SlabDebug_StyleEditor_Styles_Layout", {expand_w = true})
	if Slab.begin_combo_box("SlabDebug_StyleEditor_Styles", {selected = CurrentStyle}) then
		for i, v in ipairs(Names) do
			if Slab.text_selectable(v) then
				Style.API.SetStyle(v)
			end
		end

		Slab.end_combo_box()
	end

	if Slab.button("New") then
		Style_FileDialog = "new"
	end

	Slab.same_line()

	if Slab.button("load") then
		Style_FileDialog = "load"
	end

	Slab.same_line()

	local SaveDisabled = Style.API.IsDefaultStyle(CurrentStyle)
	if Slab.button("save", {disabled = SaveDisabled}) then
		Style.API.SaveCurrentStyle()
	end
	Slab.end_layout()

	Slab.separator()

	local refresh = false
	Slab.begin_layout("SlabDebug_StyleEditor_Content_Layout", {columns = 2, expand_w = true})
	for k, v in pairs(Style) do
		if type(v) == "table" and k ~= "font" and k ~= "API" then
			Slab.set_layout_column(1)
			Slab.text(k)
			Slab.set_layout_column(2)
			local w, h = Slab.get_layout_size()
			h = Slab.get_text_height()
			Slab.rectangle({w = w, h = h, colour = v, outline = true})
			if Slab.is_control_clicked() then
				if Style_EditingColor ~= nil then
					RestoreEditColor()
					refresh = true
				end

				EditColor(v)
			end
		end
	end

	for k, v in pairs(Style) do
		if type(v) == "number" and k ~= "FontSize" then
			Slab.set_layout_column(1)
			Slab.text(k)
			Slab.set_layout_column(2)
			if Slab.input("SlabDebug_Style_" .. k, {text = tostring(v), return_on_text = false, numbers_only = true}) then
				Style[k] = Slab.get_input_number()
			end
		end
	end
	Slab.end_layout()
	Slab.end_window()

	if Style_EditingColor ~= nil then
		local result = Slab.ColorPicker({colour = Style_ColorStore, x = x + w, y = y})
		Style_EditingColor[1] = result.colour[1]
		Style_EditingColor[2] = result.colour[2]
		Style_EditingColor[3] = result.colour[3]
		Style_EditingColor[4] = result.colour[4]

		if result.button ~= "" then
			if result.button == "OK" then
				Style.API.StoreCurrentStyle()
			end

			if result.button == "Cancel" then
				RestoreEditColor()
			end

			Style_EditingColor = nil
		end
	end

	if Style_FileDialog ~= nil then
		local t = Style_FileDialog == "new" and "savefile" or Style_FileDialog == "load" and "openfile" or nil

		if t ~= nil then
			local path = love.filesystem.getRealDirectory(SLAB_FILE_PATH) .. "/" .. SLAB_FILE_PATH .. "Internal/Resources/Styles"
			local result =
				Slab.file_dialog({allow_multi_select = false, directory = path, t = t, filters = {{"*.style", "Styles"}}})

			if result.button ~= "" then
				if result.button == "OK" then
					if Style_FileDialog == "new" then
						Style.API.CopyCurrentStyle(result.files[1])
					else
						Style.API.LoadStyle(result.files[1], true)
					end
				end

				Style_FileDialog = nil
			end
		else
			Style_FileDialog = nil
		end
	end
end

function SlabDebug.About()
	if Slab.begin_dialog(SlabDebug_About, {title = "About"}) then
		Slab.text("Slab Version: " .. Slab.get_version())
		Slab.text("Love Version: " .. Slab.get_love_version())
		Slab.new_line()
		Slab.begin_layout(SlabDebug_About .. ".Buttons_Layout", {align_x = "center"})
		if Slab.button("OK") then
			Slab.close_dialog()
		end
		Slab.end_layout()
		Slab.end_dialog()
	end
end

function SlabDebug.OpenAbout()
	Slab.open_dialog(SlabDebug_About)
end

function SlabDebug.Mouse()
	Slab.begin_window("SlabDebug_Mouse", SlabDebug_Mouse)
	local x, y = Mouse.position()
	Slab.text("x: " .. x)
	Slab.text("y: " .. y)

	local delta_x, delta_y = Mouse.get_delta()
	Slab.text("delta x: " .. delta_x)
	Slab.text("delta y: " .. delta_y)

	for i = 1, 3, 1 do
		Slab.text("button " .. i .. ": " .. (Mouse.is_down(i) and "Pressed" or "Released"))
	end

	Slab.text("Hot Region: " .. Region.get_hot_instance_id())
	Slab.end_window()
end

function SlabDebug.Windows()
	Slab.begin_window("SlabDebug_Windows", SlabDebug_Windows)

	if Slab.begin_combo_box("SlabDebug_Windows_Categories", {selected = SlabDebug_Windows_Category}) then
		for i, v in ipairs(SlabDebug_Windows_Categories) do
			if Slab.text_selectable(v) then
				SlabDebug_Windows_Category = v
			end
		end

		Slab.end_combo_box()
	end

	if SlabDebug_Windows_Category == "Inspector" then
		Window_Inspector()
	elseif SlabDebug_Windows_Category == "stack" then
		Window_Stack()
	end

	Slab.end_window()
end

function SlabDebug.Regions()
	Slab.begin_window("SlabDebug_Regions", SlabDebug_Regions)

	local Ids = Region.get_instance_ids()
	if Slab.begin_combo_box("SlabDebug_Regions_Ids", {selected = SlabDebug_Regions_Selected}) then
		for i, v in ipairs(Ids) do
			if Slab.text_selectable(v) then
				SlabDebug_Regions_Selected = v
			end
		end
		Slab.end_combo_box()
	end

	local info = Region.get_debug_info(SlabDebug_Regions_Selected)
	for i, v in ipairs(info) do
		Slab.text(v)
	end

	Slab.end_window()
end

function SlabDebug.tooltip()
	Slab.begin_window("SlabDebug_Tooltip", SlabDebug_Tooltip)

	local info = Tooltip.get_debug_info()
	for i, v in ipairs(info) do
		Slab.text(v)
	end

	Slab.end_window()
end

function SlabDebug.DrawCommands()
	Slab.begin_window("SlabDebug_DrawCommands", SlabDebug_DrawCommands)

	local info = DrawCommands.get_debug_info()
	for k, v in pairs(info) do
		DrawCommands_Item(v, k)
	end

	Slab.end_window()
end

function SlabDebug.Performance()
	DrawPerformance()
end

function SlabDebug.Performance_SetPosition(x, y)
	DrawPerformance_WinX = x ~= nil and x or 50.0
	DrawPerformance_WinY = y ~= nil and y or 50.0
	DrawPerformance_ResetPosition = true
end

function SlabDebug.StyleEditor()
	DrawStyleEditor()
end

function SlabDebug.Input()
	Slab.begin_window("SlabDebug_Input", SlabDebug_Input)

	local info = Input.get_debug_info()
	Slab.text("focused: " .. info["focused"])
	Slab.text("width: " .. info["width"])
	Slab.text("height: " .. info["height"])
	Slab.text("Cursor x: " .. info["cursor_x"])
	Slab.text("Cursor y: " .. info["cursor_y"])
	Slab.text("Cursor position: " .. info["cursor_pos"])
	Slab.text("Character: " .. info["Character"])
	Slab.text("line position: " .. info["LineCursorPos"])
	Slab.text("line position max_val: " .. info["LineCursorPosMax"])
	Slab.text("line Number: " .. info["line_number"])
	Slab.text("line length: " .. info["LineLength"])

	local lines = info["Lines"]
	if lines ~= nil then
		Slab.text("lines: " .. #lines)
	end

	Slab.end_window()
end

local SlabDebug_MultiLine_Highlight = {
	["function"] = {1, 0, 0, 1},
	["end"] = {1, 0, 0, 1},
	["if"] = {1, 0, 0, 1},
	["then"] = {1, 0, 0, 1},
	["local"] = {1, 0, 0, 1},
	["for"] = {1, 0, 0, 1},
	["do"] = {1, 0, 0, 1},
	["not"] = {1, 0, 0, 1},
	["while"] = {1, 0, 0, 1},
	["repeat"] = {1, 0, 0, 1},
	["until"] = {1, 0, 0, 1},
	["break"] = {1, 0, 0, 1},
	["else"] = {1, 0, 0, 1},
	["elseif"] = {1, 0, 0, 1},
	["in"] = {1, 0, 0, 1},
	["and"] = {1, 0, 0, 1},
	["or"] = {1, 0, 0, 1},
	["true"] = {1, 0, 0, 1},
	["false"] = {1, 0, 0, 1},
	["nil"] = {1, 0, 0, 1},
	["return"] = {1, 0, 0, 1}
}

local SlabDebug_MultiLine_ShouldHighlight = true

function SlabDebug.multi_line()
	Slab.begin_window("SlabDebug_MultiLine", SlabDebug_MultiLine)

	if Slab.button("load") then
		SlabDebug_MultiLine_FileDialog = true
	end

	Slab.same_line()

	if Slab.button("save", {disabled = SlabDebug_MultiLine_FileName == ""}) then
		local handle, err = io.open(SlabDebug_MultiLine_FileName, "w")

		if handle ~= nil then
			handle:write(SlabDebug_MultiLine_Contents)
			handle:close()
		end
	end

	local item_w, item_h = Slab.get_control_size()

	Slab.same_line()
	if Slab.checkBox(SlabDebug_MultiLine_ShouldHighlight, "Use Lua highlight", {size = item_h}) then
		SlabDebug_MultiLine_ShouldHighlight = not SlabDebug_MultiLine_ShouldHighlight
	end

	Slab.separator()

	Slab.text("File: " .. SlabDebug_MultiLine_FileName)

	if
		Slab.input(
			"SlabDebug_MultiLine",
			{
				multi_line = true,
				text = SlabDebug_MultiLine_Contents,
				w = 500.0,
				h = 500.0,
				highlight = SlabDebug_MultiLine_ShouldHighlight and SlabDebug_MultiLine_Highlight or nil
			}
		)
	 then
		SlabDebug_MultiLine_Contents = Slab.GetInputText()
	end

	Slab.end_window()

	if SlabDebug_MultiLine_FileDialog then
		local result = Slab.file_dialog({allow_multi_select = false, t = "openfile"})

		if result.button ~= "" then
			SlabDebug_MultiLine_FileDialog = false

			if result.button == "OK" then
				SlabDebug_MultiLine_FileName = result.files[1]
				local handle, err = io.open(SlabDebug_MultiLine_FileName, "r")

				if handle ~= nil then
					SlabDebug_MultiLine_Contents = handle:read("*a")
					handle:close()
				end
			end
		end
	end
end

function SlabDebug.Tree()
	if not SlabDebug_Tree.is_open then
		return
	end

	local info = Tree.get_debug_info()

	Slab.begin_window("Tree", SlabDebug_Tree)
	Slab.text("instances: " .. #info)

	Slab.begin_layout("Tree_List_Layout", {expand_w = true, expand_h = true})
	Slab.begin_list_box("Tree_List")
	for i, v in ipairs(info) do
		Slab.begin_list_box_item("Item_" .. i)
		Slab.text(v)
		Slab.end_list_box_item()
	end
	Slab.end_list_box()
	Slab.end_layout()

	Slab.end_window()
end

local function MenuItemWindow(options)
	if Slab.menu_item_checked(options.title, options.is_open) then
		options.is_open = not options.is_open
	end
end

function SlabDebug.Menu()
	if Slab.begin_menu("Debug") then
		if Slab.menu_item("About") then
			SlabDebug.OpenAbout()
		end

		MenuItemWindow(SlabDebug_Mouse)
		MenuItemWindow(SlabDebug_Windows)
		MenuItemWindow(SlabDebug_Regions)
		MenuItemWindow(SlabDebug_Tooltip)
		MenuItemWindow(SlabDebug_DrawCommands)
		MenuItemWindow(SlabDebug_Performance)
		MenuItemWindow(SlabDebug_StyleEditor)
		MenuItemWindow(SlabDebug_Input)
		MenuItemWindow(SlabDebug_MultiLine)
		MenuItemWindow(SlabDebug_Tree)

		Stats.set_enabled(SlabDebug_Performance.is_open)

		Slab.end_menu()
	end
end

function SlabDebug.begin()
	SlabDebug.About()
	SlabDebug.Mouse()
	SlabDebug.Windows()
	SlabDebug.Regions()
	SlabDebug.tooltip()
	SlabDebug.DrawCommands()
	SlabDebug.Performance()
	SlabDebug.StyleEditor()
	SlabDebug.Input()
	SlabDebug.multi_line()
	SlabDebug.Tree()
end

return SlabDebug
