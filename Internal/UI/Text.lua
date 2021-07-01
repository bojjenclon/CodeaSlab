local floor = math.floor
local insert = table.insert

local Cursor = required("Cursor")
local DrawCommands = required("DrawCommands")
local LayoutManager = required("LayoutManager")
local Mouse = required("Mouse")
local Stats = required("Stats")
local Style = required("Style")
local Window = required("Window")

local Text = {}

function Text.begin(label, options)
	local stat_handle = Stats.begin("Text", "Slab")

	options = options == nil and {} or options
	options.colour = options.colour == nil and Style.text_color or options.colour
	options.pad = options.pad == nil and 0.0 or options.pad
	options.is_selectable = options.is_selectable == nil and false or options.is_selectable
	options.is_selectable_text_only = options.is_selectable_text_only == nil and false or options.is_selectable_text_only
	options.is_selected = options.is_selected == nil and false or options.is_selected
	options.add_item = options.add_item == nil and true or options.add_item
	options.hover_color = options.hover_color == nil and Style.TextHoverBgColor or options.hover_color
	options.url = options.url == nil and nil or options.url

	if options.url ~= nil then
		options.is_selectable_text_only = true
		options.colour = Style.TextURLColor
	end

	local w = Text.get_width(label)
	local h = Style.Font:getHeight()
	local pad_x = options.pad

	LayoutManager.add_control(w + pad_x, h)

	local colour = options.colour
	local result = false
	local win_id = Window.get_item_id(label)
	local x, y = Cursor.get_position()
	local mouse_x, mouse_y = Window.get_mouse_position()

	local is_obstructed = Window.is_obstructed_at_mouse()

	if not is_obstructed and x <= mouse_x and mouse_x <= x + w and y <= mouse_y and mouse_y <= y + h then
		Window.set_hot_item(win_id)
	end

	local win_x, win_y, win_w, win_h = Window.get_bounds()
	local check_x = options.is_selectable_text_only and x or win_x
	local check_w = options.is_selectable_text_only and w or win_w
	local hovered =
		not is_obstructed and check_x <= mouse_x and mouse_x <= check_x + check_w + pad_x and y <= mouse_y and
		mouse_y <= y + h

	if options.is_selectable or options.is_selected then
		if hovered or options.is_selected then
			DrawCommands.rectangle("fill", check_x, y, check_w + pad_x, h, options.hover_color)
		end

		if hovered then
			if options.select_on_hover then
				result = true
			else
				if Mouse.is_clicked(1) then
					result = true
				end
			end
		end
	end

	if hovered and options.url ~= nil then
		Mouse.set_cursor("hand")

		if Mouse.is_clicked(1) then
			love.system.openURL(options.url)
		end
	end

	DrawCommands.print(label, floor(x + pad_x * 0.5), floor(y), colour, Style.Font)

	if options.url ~= nil then
		DrawCommands.line(x + pad_x, y + h, x + w, y + h, 1.0, colour)
	end

	Cursor.set_item_bounds(x, y, w + pad_x, h)
	Cursor.advance_y(h)

	if options.add_item then
		Window.add_item(x, y, w + pad_x, h, win_id)
	end

	Stats.finish(stat_handle)

	return result
end

function Text.begin_formatted(label, options)
	local stat_handle = Stats.begin("textf", "Slab")

	local win_w, win_h = Window.get_borderless_size()

	options = options == nil and {} or options
	options.colour = options.colour == nil and Style.text_color or options.colour
	options.w = options.w == nil and win_w or options.w
	options.align = options.align == nil and "left" or options.align

	if Window.is_auto_size() then
		options.w = WIDTH
	end

	local width, wrapped = Style.Font:getWrap(label, options.w)
	local h = #wrapped * Style.Font:getHeight()

	LayoutManager.add_control(width, h)

	local x, y = Cursor.get_position()

	DrawCommands.printf(label, floor(x), floor(y), width, options.align, options.colour, Style.Font)

	Cursor.set_item_bounds(floor(x), floor(y), width, h)
	Cursor.advance_y(h)

	Window.reset_content_size()
	Window.add_item(floor(x), floor(y), width, h)

	Stats.finish(stat_handle)
end

function Text.begin_object(object, options)
	local stat_handle = Stats.begin("TextObject", "Slab")

	local win_w, win_h = Window.get_borderless_size()

	options = options == nil and {} or options
	options.colour = options.colour == nil and Style.text_color or options.colour

	local w, h = object:getDimensions()

	LayoutManager.add_control(w, h)

	local x, y = Cursor.get_position()

	DrawCommands.Text(object, floor(x), floor(y), options.colour)

	Cursor.set_item_bounds(floor(x), floor(y), w, h)
	Cursor.advance_y(y)

	Window.reset_content_size()
	Window.add_item(floor(x), floor(y), w, h)

	Stats.finish(stat_handle)
end

function Text.get_width(label)
	return Style.Font:getWidth(label)
end

function Text.get_height()
	return Style.Font:getHeight()
end

function Text.get_size(label)
	return Style.Font:getWidth(label), Style.Font:getHeight()
end

function Text.get_size_wrap(label, width)
	local w, lines = Style.Font:getWrap(label, width)
	return w, #lines * Text.get_height()
end

function Text.get_lines(label, width)
	local w, lines = Style.Font:getWrap(label, width)

	local start = 0
	for i, v in ipairs(lines) do
		if #v == 0 then
			lines[i] = "\n"
		else
			local offset = start + #v + 1
			local ch = string.sub(label, offset, offset)

			if ch == "\n" then
				lines[i] = lines[i] .. "\n"
			end
		end

		start = start + #lines[i]
	end

	if string.sub(label, #label, #label) == "\n" then
		insert(lines, "")
	end

	if #lines == 0 then
		insert(lines, "")
	end

	return lines
end

function Text.create_object()
	return love.graphics.newText(Style.Font)
end

return Text
