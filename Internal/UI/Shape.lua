local insert = table.insert
local abs = math.abs
local max = math.max
local min = math.min
local huge = math.huge

local Cursor = required("Cursor")
local DrawCommands = required("DrawCommands")
local LayoutManager = required("LayoutManager")
local Stats = required("Stats")
local Window = required("Window")

local Shape = {}

local curve = nil
local curve_x, curve_y = 0, 0

function Shape.rectangle(options)
	local stat_handle = Stats.begin("rectangle", "Slab")

	options = options == nil and {} or options
	options.mode = options.mode == nil and "fill" or options.mode
	options.w = options.w == nil and 32 or options.w
	options.h = options.h == nil and 32 or options.h
	options.colour = options.colour == nil and nil or options.colour
	options.rounding = options.rounding == nil and 2.0 or options.rounding
	options.outline = options.outline == nil and false or options.outline
	options.outline_color = options.outline_color == nil and {0.0, 0.0, 0.0, 1.0} or options.outline_color
	options.segments = options.segments == nil and 10 or options.segments

	local w = options.w
	local h = options.h
	LayoutManager.add_control(w, h)

	local x, y = Cursor.get_position()

	if options.outline then
		DrawCommands.rectangle("line", x, y, w, h, options.outline_color, options.rounding, options.segments)
	end

	DrawCommands.rectangle(options.mode, x, y, w, h, options.colour, options.rounding, options.segments)

	Window.add_item(x, y, w, h)
	Cursor.set_item_bounds(x, y, w, h)
	Cursor.advance_y(h)

	Stats.finish(stat_handle)
end

function Shape.circle(options)
	local stat_handle = Stats.begin("circle", "Slab")

	options = options == nil and {} or options
	options.mode = options.mode == nil and "fill" or options.mode
	options.radius = options.radius == nil and 12.0 or options.radius
	options.colour = options.colour == nil and nil or options.colour
	options.segments = options.segments == nil and nil or options.segments

	local diameter = options.radius * 2.0

	LayoutManager.add_control(diameter, diameter)

	local x, y = Cursor.get_position()
	local center_x = x + options.radius
	local center_y = y + options.radius

	DrawCommands.circle(options.mode, center_x, center_y, options.radius, options.colour, options.segments)
	Window.add_item(x, y, diameter, diameter)
	Cursor.set_item_bounds(x, y, diameter, diameter)
	Cursor.advance_y(diameter)

	Stats.finish(stat_handle)
end

function Shape.triangle(options)
	local stat_handle = Stats.begin("triangle", "Slab")

	options = options == nil and {} or options
	options.mode = options.mode == nil and "fill" or options.mode
	options.radius = options.radius == nil and 12 or options.radius
	options.rotation = options.rotation == nil and 0 or options.rotation
	options.colour = options.colour == nil and nil or options.colour

	local diameter = options.radius * 2.0

	LayoutManager.add_control(diameter, diameter)

	local x, y = Cursor.get_position()
	local center_x = x + options.radius
	local center_y = y + options.radius

	DrawCommands.triangle(options.mode, center_x, center_y, options.radius, options.rotation, options.colour)
	Window.add_item(x, y, diameter, diameter)
	Cursor.set_item_bounds(x, y, diameter, diameter)
	Cursor.advance_y(diameter)

	Stats.finish(stat_handle)
end

function Shape.line(x_2, y_2, options)
	local stat_handle = Stats.begin("line", "Slab")

	options = options == nil and {} or options
	options.width = options.width == nil and 1.0 or options.width
	options.colour = options.colour == nil and nil or options.colour

	local x, y = Cursor.get_position()
	local w, h = abs(x_2 - x), abs(y_2 - y)
	h = max(h, options.width)

	DrawCommands.line(x, y, x_2, y_2, options.width, options.colour)
	Window.add_item(x, y, w, h)
	Cursor.set_item_bounds(x, y, w, h)
	Cursor.advance_y(h)

	Stats.finish(stat_handle)
end

function Shape.curve(points, options)
	local stat_handle = Stats.begin("curve", "Slab")

	options = options == nil and {} or options
	options.colour = options.colour == nil and nil or options.colour
	options.depth = options.depth == nil and nil or options.depth

	curve = love.math.newBezierCurve(points)

	local min_x, min_y = huge, huge
	local max_x, max_y = 0, 0
	for i = 1, curve:getControlPointCount(), 1 do
		local p_x, p_y = curve:getControlPoint(i)
		min_x = min(min_x, p_x)
		min_y = min(min_y, p_y)

		max_x = max(max_x, p_x)
		max_y = max(max_y, p_y)
	end

	local w = abs(max_x - min_x)
	local h = abs(max_y - min_y)

	LayoutManager.add_control(w, h)

	curve_x, curve_y = Cursor.get_position()
	curve:translate(curve_x, curve_y)

	DrawCommands.curve(curve:render(options.depth), options.colour)
	Window.add_item(min_x, min_y, w, h)
	Cursor.set_item_bounds(min_x, min_y, w, h)
	Cursor.advance_y(h)

	Stats.finish(stat_handle)
end

function Shape.get_curve_control_point_count()
	if curve ~= nil then
		return curve:getControlPointCount()
	end

	return 0
end

function Shape.get_curve_control_point(index, options)
	options = options == nil and {} or options
	options.local_space = options.local_space == nil and true or options.local_space

	local x, y = 0, 0
	if curve ~= nil then
		if options.local_space then
			curve:translate(-curve_x, -curve_y)
		end

		x, y = curve:getControlPoint(index)

		if options.local_space then
			curve:translate(curve_x, curve_y)
		end
	end

	return x, y
end

function Shape.evaluate_curve(time, options)
	options = options == nil and {} or options
	options.local_space = options.local_space == nil and true or options.local_space

	local x, y = 0, 0
	if curve ~= nil then
		if options.local_space then
			curve:translate(-curve_x, -curve_y)
		end

		x, y = curve:evaluate(time)

		if options.local_space then
			curve:translate(curve_x, curve_y)
		end
	end

	return x, y
end

function Shape.polygon(points, options)
	local stat_handle = Stats.begin("polygon", "Slab")

	options = options == nil and {} or options
	options.colour = options.colour == nil and nil or options.colour
	options.mode = options.mode == nil and "fill" or options.mode

	local min_x, min_y = huge, huge
	local max_x, max_y = 0, 0
	local verts = {}

	for i = 1, #points, 2 do
		min_x = min(min_x, points[i])
		min_y = min(min_y, points[i + 1])

		max_x = max(max_x, points[i])
		max_y = max(max_y, points[i + 1])
	end

	local w = abs(max_x - min_x)
	local h = abs(max_y - min_y)

	LayoutManager.add_control(w, h)

	min_x, min_y = huge, huge
	max_x, max_y = 0, 0
	local x, y = Cursor.get_position()
	for i = 1, #points, 2 do
		insert(verts, points[i] + x)
		insert(verts, points[i + 1] + y)

		min_x = min(min_x, verts[i])
		min_y = min(min_y, verts[i + 1])

		max_x = max(max_x, verts[i])
		max_y = max(max_y, verts[i + 1])
	end

	DrawCommands.polygon(options.mode, verts, options.colour)
	Window.add_item(min_x, min_y, w, h)
	Cursor.set_item_bounds(min_x, min_y, w, h)
	Cursor.advance_y(h)

	Stats.finish(stat_handle)
end

return Shape
