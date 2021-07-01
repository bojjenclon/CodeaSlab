local floor = math.floor
local max = math.max

local Cursor = required("Cursor")
local DrawCommands = required("DrawCommands")
local LayoutManager = required("LayoutManager")
local Mouse = required("Mouse")
local Stats = required("Stats")
local Style = required("Style")
local text = required("text")
local tooltip = required("tooltip")
local Utility = required("Utility")
local Window = required("Window")

local Button = {}

local pad = 10.0
local min_width = 75.0
local radius = 8.0
local clicked_id = nil

function Button.begin(label, options)
	local stat_handle = Stats.begin("button", "Slab")

	options = options == nil and {} or options
	options.tooltip = options.tooltip == nil and "" or options.tooltip
	options.rounding = options.rounding == nil and Style.button_rounding or options.rounding
	options.invisible = options.invisible == nil and false or options.invisible
	options.w = options.w == nil and nil or options.w
	options.h = options.h == nil and nil or options.h
	options.disabled = options.disabled == nil and false or options.disabled

	local id = Window.get_item_id(label)
	local w, h = Button.get_size(label)
	local label_w = Style.Font:getWidth(label)
	local FontHeight = Style.Font:getHeight()
	local text_color = options.disabled and Style.ButtonDisabledTextColor or nil

	if options.w ~= nil then
		w = options.w
	end

	if options.h ~= nil then
		h = options.h
	end

	w, h = LayoutManager.compute_size(w, h)
	LayoutManager.add_control(w, h)

	local x, y = Cursor.get_position()

	local result = false
	local colour = Style.ButtonColor

	local mouse_x, mouse_y = Window.get_mouse_position()
	if not Window.is_obstructed_at_mouse() and x <= mouse_x and mouse_x <= x + w and y <= mouse_y and mouse_y <= y + h then
		Tooltip.begin(options.tooltip)
		Window.set_hot_item(id)

		if not options.disabled then
			if not Utility.is_mobile() then
				colour = Style.ButtonHoveredColor
			end

			if clicked_id == id then
				colour = Style.ButtonPressedColor
			end

			if Mouse.is_clicked(1) then
				clicked_id = id
			end

			if Mouse.is_released(1) and clicked_id == id then
				result = true
				clicked_id = nil
			end
		end
	end

	local label_x = x + (w * 0.5) - (label_w * 0.5)

	if not options.invisible then
		DrawCommands.rectangle("fill", x, y, w, h, colour, options.rounding)
		local x, y = Cursor.get_position()
		Cursor.set_x(floor(label_x))
		Cursor.set_y(floor(y + (h * 0.5) - (FontHeight * 0.5)))
		LayoutManager.begin("ignore", {ignore = true})
		Text.begin(label, {colour = text_color})
		LayoutManager.finish()
		Cursor.set_position(x, y)
	end

	Cursor.set_item_bounds(x, y, w, h)
	Cursor.advance_y(h)

	Window.add_item(x, y, w, h, id)

	Stats.finish(stat_handle)

	return result
end

function Button.begin_radio(label, options)
	local stat_handle = Stats.begin("radio_button", "Slab")

	label = label == nil and "" or label

	options = options == nil and {} or options
	options.index = options.index == nil and 0 or options.index
	options.selected_index = options.selected_index == nil and 0 or options.selected_index
	options.tooltip = options.tooltip == nil and "" or options.tooltip

	local result = false
	local id = Window.get_item_id(label)
	local w, h = radius * 2.0, radius * 2.0
	local is_obstructed = Window.is_obstructed_at_mouse()
	local colour = Style.ButtonColor
	local mouse_x, mouse_y = Window.get_mouse_position()

	if label ~= "" then
		local text_w, text_h = Text.get_size(label)
		w = w + Cursor.pad_x() + text_w
		h = max(h, text_h)
	end

	LayoutManager.add_control(w, h)

	local x, y = Cursor.get_position()
	local center_x, center_y = x + radius, y + radius
	local d_x = mouse_x - center_x
	local d_y = mouse_y - center_y
	local hovered_button = not is_obstructed and (d_x * d_x) + (d_y * d_y) <= radius * radius
	if hovered_button then
		colour = Style.ButtonHoveredColor

		if clicked_id == id then
			colour = Style.ButtonPressedColor
		end

		if Mouse.is_clicked(1) then
			clicked_id = id
		end

		if Mouse.is_released(1) and clicked_id == id then
			result = true
			clicked_id = nil
		end
	end

	DrawCommands.circle("fill", center_x, center_y, radius, colour)

	if options.index > 0 and options.index == options.selected_index then
		DrawCommands.circle("fill", center_x, center_y, radius * 0.7, Style.RadioButtonSelectedColor)
	end

	if label ~= "" then
		local cursor_y = Cursor.get_y()
		Cursor.advance_x(radius * 2.0)
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

	Window.add_item(x, y, w, h)

	Stats.finish(stat_handle)

	return result
end

function Button.get_size(label)
	local w = Style.Font:getWidth(label)
	local h = Style.Font:getHeight()
	return max(w, min_width) + pad * 2.0, h + pad * 0.5
end

function Button.clear_clicked()
	clicked_id = nil
end

return button
