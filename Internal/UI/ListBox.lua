local Cursor = required("Cursor")
local DrawCommands = required("DrawCommands")
local LayoutManager = required("LayoutManager")
local Mouse = required("Mouse")
local Region = required("Region")
local Stats = required("Stats")
local Style = required("Style")
local text = required("text")
local Window = required("Window")

local ListBox = {}

local instances = {}
local active_instance = nil

local function get_item_instance(instance, id)
	if instance ~= nil then
		if instance.items[id] == nil then
			local item = {}
			item.id = id
			item.x = 0.0
			item.y = 0.0
			item.w = 0.0
			item.h = 0.0
			instance.items[id] = item
		end
		return instance.items[id]
	end
	return nil
end

local function get_instance(id)
	if instances[id] == nil then
		local instance = {}
		instance.id = id
		instance.x = 0.0
		instance.y = 0.0
		instance.w = 0.0
		instance.h = 0.0
		instance.items = {}
		instance.active_item = nil
		instance.hot_item = nil
		instance.selected = false
		instance.stat_handle = nil
		instances[id] = instance
	end
	return instances[id]
end

function ListBox.begin(id, options)
	local stat_handle = Stats.begin("ListBox", "Slab")

	options = options == nil and {} or options
	options.w = options.w == nil and 150.0 or options.w
	options.h = options.h == nil and 150.0 or options.h
	options.clear = options.clear == nil and false or options.clear
	options.rounding = options.rounding == nil and Style.WindowRounding or options.rounding
	options.stretch_w = options.stretch_w or false
	options.stretch_h = options.stretch_h or false

	local instance = get_instance(Window.get_item_id(id))
	local w = options.w
	local h = options.h

	if options.clear then
		instance.items = {}
	end

	w, h = LayoutManager.compute_size(w, h)
	LayoutManager.add_control(w, h)

	local remaining_w, remaining_h = Window.get_remaining_size()
	if options.stretch_w then
		w = remaining_w
	end

	if options.stretch_h then
		h = remaining_h
	end

	local x, y = Cursor.get_position()
	instance.x = x
	instance.y = y
	instance.w = w
	instance.h = h
	instance.stat_handle = stat_handle
	active_instance = instance

	Cursor.set_item_bounds(x, y, w, h)
	Cursor.advance_y(0.0)

	Window.add_item(x, y, w, h, instance.id)

	local is_obstructed = Window.is_obstructed_at_mouse()

	local t_x, t_y = Window.transform_point(x, y)
	local mouse_x, mouse_y = Window.get_mouse_position()
	Region.begin(
		instance.id,
		{
			x = x,
			y = y,
			w = w,
			h = h,
			s_x = t_x,
			s_y = t_y,
			auto_size_content = true,
			no_background = true,
			intersect = true,
			mouse_x = mouse_x,
			mouse_y = mouse_y,
			reset_content = Window.has_resized(),
			is_obstructed = is_obstructed,
			rounding = options.rounding
		}
	)

	instance.hot_item = nil
	local in_region = Region.contains(mouse_x, mouse_y)
	mouse_x, mouse_y = Region.inverse_transform(instance.id, mouse_x, mouse_y)
	for k, v in pairs(instance.items) do
		if
			not is_obstructed and not Region.is_hover_scroll_bar(instance.id) and v.x <= mouse_x and mouse_x <= v.x + instance.w and
				v.y <= mouse_y and
				mouse_y <= v.y + v.h and
				in_region
		 then
			instance.hot_item = v
		end

		if instance.hot_item == v or v.selected then
			DrawCommands.rectangle("fill", v.x, v.y, instance.w, v.h, Style.TextHoverBgColor)
		end
	end

	LayoutManager.begin("ignore", {ignore = true})
end

function ListBox.begin_item(id, options)
	options = options == nil and {} or options
	options.selected = options.selected == nil and false or options.selected

	assert(active_instance ~= nil, "Trying to call begin_list_box_item outside of begin_list_box.")
	assert(
		active_instance.active_item == nil,
		"begin_list_box_item was called for item '" ..
			(active_instance.active_item ~= nil and active_instance.active_item.id or "nil") ..
				"' without a call to end_list_box_item."
	)
	local item = get_item_instance(active_instance, id)
	item.x = active_instance.x
	item.y = Cursor.get_y()
	Cursor.set_x(item.x)
	Cursor.advance_x(0.0)
	active_instance.active_item = item
	active_instance.active_item.selected = options.selected
end

function ListBox.is_item_clicked(button, IsDoubleClick)
	assert(active_instance ~= nil, "Trying to call is_item_clicked outside of begin_list_box.")
	assert(active_instance.active_item ~= nil, "is_item_clicked was called outside of begin_list_box_item.")
	if active_instance.hot_item == active_instance.active_item then
		button = button == nil and 1 or button
		if IsDoubleClick then
			return Mouse.is_double_clicked(button)
		else
			return Mouse.is_clicked(button)
		end
	end
	return false
end

function ListBox.end_item()
	assert(active_instance ~= nil, "Trying to call begin_list_box_item outside of begin_list_box.")
	assert(active_instance.active_item ~= nil, "Trying to call end_list_box_item without calling begin_list_box_item.")
	local item_x, item_y, item_w, item_h = Cursor.get_item_bounds()
	active_instance.active_item.w = item_w
	active_instance.active_item.h = Cursor.get_line_height()
	Cursor.set_y(active_instance.active_item.y + active_instance.active_item.h)
	Cursor.advance_y(0.0)
	active_instance.active_item = nil
end

function ListBox.finish()
	assert(active_instance ~= nil, "end_list_box was called without calling begin_list_box.")
	Region.finish()
	Region.apply_scissor()

	Cursor.set_item_bounds(active_instance.x, active_instance.y, active_instance.w, active_instance.h)
	Cursor.set_position(active_instance.x, active_instance.y)
	Cursor.advance_y(active_instance.h)

	LayoutManager.finish()

	Stats.finish(active_instance.stat_handle)

	active_instance = nil
end

return ListBox
