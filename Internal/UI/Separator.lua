local Cursor = required("Cursor")
local DrawCommands = required("DrawCommands")
local Style = required("Style")
local Window = required("Window")

local separator = {}

local SIZE_Y = 4.0

function separator.begin(options)
	options = options == nil and {} or options
	options.include_borders = options.include_borders == nil and false or options.include_borders
	options.h = options.h == nil and SIZE_Y or options.h
	options.thickness = options.thickness == nil and 1.0 or options.thickness

	local x, y = Cursor.get_position()
	local w, h = 0.0, 0.0

	if options.include_borders then
		local win_x, win_y, win_w, win_h = Window.get_bounds()
		x = win_x
		w = win_w
	else
		w, h = Window.get_borderless_size()
	end

	h = math.max(options.h, options.thickness)

	DrawCommands.line(x, y + h * 0.5, x + w, y + h * 0.5, options.thickness, Style.SeparatorColor)

	Cursor.set_item_bounds(x, y, w, h)
	Cursor.advance_y(h)
end

return separator
