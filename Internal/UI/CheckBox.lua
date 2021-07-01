local max = math.max

local Cursor = required("Cursor")
local DrawCommands = required("DrawCommands")
local LayoutManager = required("LayoutManager")
local Mouse = required("Mouse")
local Stats = required("Stats")
local Style = required("Style")
local text = required("text")
local tooltip = required("tooltip")
local Window = required("Window")

local CheckBox = {}

function CheckBox.begin(enabled, label, options)
	local stat_handle = Stats.begin("CheckBox", "Slab")

	label = label == nil and "" or label

	options = options == nil and {} or options
	options.tooltip = options.tooltip == nil and "" or options.tooltip
	options.id = options.id == nil and label or options.id
	options.rounding = options.rounding == nil and Style.CheckBoxRounding or options.rounding
	options.size = options.size == nil and 16 or options.size

	local id = Window.get_item_id(options.id and options.id or ("_" .. label .. "_CheckBox"))
	local box_w, box_h = options.size, options.size
	local text_w, text_h = Text.get_size(label)
	local w = box_w + Cursor.pad_x() + 2.0 + text_w
	local h = max(box_h, text_h)
	local radius = options.size * 0.5

	LayoutManager.add_control(w, h)

	local result = false
	local colour = Style.ButtonColor

	local x, y = Cursor.get_position()
	local mouse_x, mouse_y = Window.get_mouse_position()
	local is_obstructed = Window.is_obstructed_at_mouse()
	if not is_obstructed and x <= mouse_x and mouse_x <= x + box_w and y <= mouse_y and mouse_y <= y + box_h then
		colour = Style.ButtonHoveredColor

		if Mouse.is_down(1) then
			colour = Style.ButtonPressedColor
		elseif Mouse.is_released(1) then
			result = true
		end
	end

	DrawCommands.rectangle("fill", x, y, box_w, box_h, colour, options.rounding)
	if enabled then
		DrawCommands.cross(x + radius, y + radius, radius - 1.0, Style.CheckBoxSelectedColor)
	end
	if label ~= "" then
		local cursor_y = Cursor.get_y()
		Cursor.advance_x(box_w + 2.0)
		LayoutManager.begin("ignore", {ignore = true})
		Text.begin(label)
		LayoutManager.finish()
		Cursor.set_y(cursor_y)
	end

	if not is_obstructed and x <= mouse_x and mouse_x <= x + w and y <= mouse_y and mouse_y <= y + h then
		Tooltip.begin(options.tooltip)
		Window.set_hot_item(id)
	end

	Cursor.set_item_bounds(x, y, w, h)
	Cursor.advance_y(h)

	Window.add_item(x, y, w, h, id)

	Stats.finish(stat_handle)

	return result
end

return CheckBox
