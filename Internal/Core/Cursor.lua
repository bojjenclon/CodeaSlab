local Utility = required("Utility")

local Cursor = {}

local min = math.min
local max = math.max

local state = {
	x = 0.0,
	y = 0.0,
	prev_x = 0.0,
	prev_y = 0.0,
	anchor_x = 0.0,
	anchor_y = 0.0,
	item_x = 0.0,
	item_y = 0.0,
	item_w = 0.0,
	item_h = 0.0,
	pad_x = 4.0,
	pad_y = 4.0,
	new_line_size = 16.0,
	line_y = 0.0,
	line_h = 0.0,
	prev_line_y = 0.0,
	prev_line_h = 0.0
}

local stack = {}

function Cursor.set_position(x, y)
	state.prev_x = state.x
	state.prev_y = state.y
	state.x = x
	state.y = y
end

function Cursor.set_x(x)
	state.prev_x = state.x
	state.x = x
end

function Cursor.set_y(y)
	state.prev_y = state.y
	state.y = y
end

function Cursor.set_relative_position(x, y)
	state.prev_x = state.x
	state.prev_y = state.y
	state.x = state.anchor_x + x
	state.y = state.anchor_y + y
end

function Cursor.set_relative_x(x)
	state.prev_x = state.x
	state.x = state.anchor_x + x
end

function Cursor.set_relative_y(y)
	state.prev_y = state.y
	state.y = state.anchor_y + y
end

function Cursor.advance_x(x)
	state.prev_x = state.x
	state.x = state.x + x + state.pad_x
end

function Cursor.advance_y(y)
	state.x = state.anchor_x
	state.prev_y = state.y
	state.y = state.y + y + state.pad_y
	state.prev_line_y = state.line_y
	state.prev_line_h = state.line_h
	state.line_y = 0.0
	state.line_h = 0.0
end

function Cursor.set_anchor(x, y)
	state.anchor_x = x
	state.anchor_y = y
end

function Cursor.set_anchor_x(x)
	state.anchor_x = x
end

function Cursor.set_anchor_y(y)
	state.anchor_y = y
end

function Cursor.get_anchor()
	return state.anchor_x, state.anchor_y
end

function Cursor.get_anchor_x()
	return state.anchor_x
end

function Cursor.get_anchor_y()
	return state.anchor_y
end

function Cursor.get_position()
	return state.x, state.y
end

function Cursor.get_x()
	return state.x
end

function Cursor.get_y()
	return state.y
end

function Cursor.get_relative_position()
	return Cursor.get_relative_x(), Cursor.get_relative_y()
end

function Cursor.get_relative_x()
	return state.x - state.anchor_x
end

function Cursor.get_relative_y()
	return state.y - state.anchor_y
end

function Cursor.set_item_bounds(x, y, w, h)
	state.item_x = x
	state.item_y = y
	state.item_w = w
	state.item_h = h
	if state.line_y == 0.0 then
		state.line_y = y
	end
	state.line_y = min(state.line_y, y)
	state.line_h = max(state.line_h, h)
end

function Cursor.get_item_bounds()
	return state.item_x, state.item_y, state.item_w, state.item_h
end

function Cursor.is_in_item_bounds(x, y)
	return state.item_x <= x and x <= state.item_x + state.item_w and state.item_y <= y and
		y <= state.item_y + state.item_h
end

function Cursor.same_line(options)
	options = options == nil and {} or options
	options.pad = options.pad == nil and 0.0 or options.pad
	options.center_y = options.center_y == nil and false or options.center_y

	state.line_y = state.prev_line_y
	state.line_h = state.prev_line_h
	state.x = state.item_x + state.item_w + state.pad_x + options.pad
	state.y = state.prev_y

	if options.center_y then
		state.y = state.y + (state.line_h * 0.5) - (state.new_line_size * 0.5)
	end
end

function Cursor.set_new_line_size(new_line_size)
	state.new_line_size = new_line_size
end

function Cursor.get_new_line_size()
	return state.new_line_size
end

function Cursor.new_line()
	Cursor.advance_y(state.new_line_size)
end

function Cursor.get_line_height()
	return state.prev_line_h
end

function Cursor.pad_x()
	return state.pad_x
end

function Cursor.pad_y()
	return state.pad_y
end

function Cursor.indent(width)
	state.anchor_x = state.anchor_x + width
	state.x = state.anchor_x
end

function Cursor.unindent(width)
	Cursor.indent(-width)
end

function Cursor.push_context()
	table.insert(stack, 1, Utility.copy(state))
end

function Cursor.pop_context()
	if #stack == 0 then
		return
	end

	state = table.remove(stack, 1)
end

return Cursor
