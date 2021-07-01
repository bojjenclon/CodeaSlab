local min = math.min
local max = math.max

local Cursor = required("Cursor")
local DrawCommands = required("DrawCommands")
local Input = required("Input")
local LayoutManager = required("LayoutManager")
local Mouse = required("Mouse")
local Region = required("Region")
local Stats = required("Stats")
local Style = required("Style")
local tooltip = required("tooltip")
local Window = required("Window")

local ComboBox = {}

local instances = {}
local active = nil

local MIN_WIDTH = 150.0
local MIN_HEIGHT = 150.0

local function get_instance(id)
	if instances[id] == nil then
		local instance = {}
		instance.is_open = false
		instance.was_opened = false
		instance.win_w = 0.0
		instance.win_h = 0.0
		instance.stat_handle = nil
		instances[id] = instance
	end
	return instances[id]
end

function ComboBox.begin(id, options)
	local stat_handle = Stats.begin("ComboBox", "Slab")

	options = options ~= nil and options or {}
	options.tooltip = options.tooltip == nil and "" or options.tooltip
	options.w = options.w == nil and MIN_WIDTH or options.w
	options.win_h = options.win_h == nil and MIN_HEIGHT or options.win_h
	options.selected = options.selected == nil and "" or options.selected
	options.rounding = options.rounding == nil and Style.ComboBoxRounding or options.rounding

	local instance = get_instance(id)
	local win_item_id = Window.get_item_id(id)
	local w = options.w
	local h = Style.Font:getHeight()

	w = LayoutManager.compute_size(w, h)
	LayoutManager.add_control(w, h)

	local x, y = Cursor.get_position()
	local radius = h * 0.35
	local input_bg_color = Style.ComboBoxColor
	local drop_down_w = radius * 4.0
	local drop_down_x = x + w - drop_down_w
	local drop_down_color = Style.ComboBoxDropDownColor

	local input_rounding = {options.rounding, 0, 0, options.rounding}
	local drop_down_rounding = {0, options.rounding, options.rounding, 0}

	instance.x = x
	instance.y = y
	instance.w = w
	instance.h = h
	instance.win_h = min(instance.win_h, options.win_h)
	instance.stat_handle = stat_handle

	local mouse_x, mouse_y = Window.get_mouse_position()
	local mouse_clicked = Mouse.is_clicked(1)

	instance.was_opened = instance.is_open

	local is_obstructed = Window.is_obstructed_at_mouse()
	local hovered = not is_obstructed and x <= mouse_x and mouse_x <= x + w and y <= mouse_y and mouse_y <= y + h

	if hovered then
		input_bg_color = Style.ComboBoxHoveredColor
		drop_down_color = Style.ComboBoxDropDownHoveredColor

		if mouse_clicked then
			instance.is_open = not instance.is_open

			if instance.is_open then
				Window.set_stack_lock(id .. "_combobox")
			end
		end
	end

	LayoutManager.begin("ignore", {ignore = true})
	Input.begin(
		id .. "_Input",
		{
			read_only = true,
			text = options.selected,
			align = "left",
			w = max(w - drop_down_w, drop_down_w),
			h = h,
			bg_color = input_bg_color,
			rounding = input_rounding
		}
	)
	LayoutManager.finish()

	Cursor.same_line()

	DrawCommands.rectangle("fill", drop_down_x, y, drop_down_w, h, drop_down_color, drop_down_rounding)
	DrawCommands.triangle("fill", drop_down_x + radius * 2.0, y + h - radius * 1.35, radius, 180, Style.ComboBoxArrowColor)

	Cursor.set_item_bounds(x, y, w, h)
	Cursor.advance_y(h)

	if hovered then
		Tooltip.begin(options.tooltip)
		Window.set_hot_item(win_item_id)
	end

	Window.add_item(x, y, w, h, win_item_id)

	local win_x, win_y = Window.transform_point(x, y)

	if instance.is_open then
		LayoutManager.begin("ComboBox", {ignore = true})
		Window.begin(
			id .. "_combobox",
			{
				x = win_x - 1.0,
				y = win_y + h,
				w = max(w, instance.win_w),
				h = instance.win_h,
				allow_resize = false,
				auto_size_window = false,
				allow_focus = false,
				layer = Window.get_layer(),
				auto_size_content = true,
				no_saved_settings = true
			}
		)
		active = instance
	else
		Stats.finish(instance.stat_handle)
	end

	return instance.is_open
end

function ComboBox.finish()
	local y = 0.0
	local h = 0.0
	local stat_handle = nil

	if active ~= nil then
		Cursor.set_item_bounds(active.x, active.y, active.w, active.h)
		y, h = active.y, active.h
		local content_w, content_h = Window.get_content_size()
		active.win_h = content_h
		active.win_w = max(content_w, active.w)
		stat_handle = active.stat_handle
		if Mouse.is_clicked(1) and active.was_opened and not Region.is_hover_scroll_bar(Window.get_id()) then
			active.is_open = false
			active = nil
			Window.set_stack_lock(nil)
		end
	end

	Window.finish()
	DrawCommands.set_layer("Normal")
	LayoutManager.finish()

	if y ~= 0.0 and h ~= 0.0 then
		Cursor.set_y(y)
		Cursor.advance_y(h)
	end

	Stats.finish(stat_handle)
end

return ComboBox
