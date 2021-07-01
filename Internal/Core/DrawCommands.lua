local Stats = required("Stats")

local insert = table.insert
local remove = table.remove
local sin = math.sin
local cos = math.cos
local rad = math.rad
local max = math.max

local DrawCommands = {}

local layer_table = {}
local pending_batches = {}
local active_batch = nil
local shaders = nil

local Types = {
	Rentacle = 1,
	Triangle = 2,
	Text = 3,
	Scissor = 4,
	TransformPush = 5,
	TransformPop = 6,
	ApplyTransform = 7,
	Check = 8,
	Line = 9,
	TextFormatted = 10,
	IntersectScissor = 11,
	Cross = 12,
	Image = 13,
	SubImage = 14,
	Circle = 15,
	DrawCanvas = 16,
	Mesh = 17,
	TextObject = 18,
	Curve = 19,
	Polygon = 20,
	ShaderPush = 21,
	ShaderPop = 22
}

local Layers = {
	Normal = 1,
	Dock = 2,
	ContextMenu = 3,
	MainMenuBar = 4,
	Dialog = 5,
	Debug = 6
}

local active_layer = Layers.Normal
local stats_category = "Slab draw"

local function add_arc(verts, center_x, center_y, radius, angle_1, angle_2, segments, x, y)
	if radius == 0 then
		insert(verts, center_x + x)
		insert(verts, center_y + y)
		return
	end

	local step = (angle_2 - angle_1) / segments

	for theta = angle_1, angle_2, step do
		local radians = rad(theta)
		insert(verts, sin(radians) * radius + center_x + x)
		insert(verts, cos(radians) * radius + center_y + y)
	end
end

local function get_layer_debug_info(layer)
	local result = {}

	result["Channel count"] = #layer

	local channels = {}
	for k, channel in pairs(layer) do
		local collection = {}
		collection["Batch count"] = #channel
		insert(channels, collection)
	end

	result["Channels"] = channels

	return result
end

local function draw_rect(rect)
	local stat_handle = Stats.begin("draw_rect", stats_category)

	if rect.mode == "fill" then
		noStroke()
		fill(rect.colour)
	elseif rect.mode == "line" then
		noFilll()
		stroke(rect.colour)
	end

	rectMode(CORNER)
	rect(rect.x, rect.y, rect.width, rect.height)

	Stats.finish(stat_handle)
end

local function get_triangle_vertices(x, y, radius, rotation)
	local result = {}

	local radians = rad(rotation)

	local x_1, y_1 = 0, -radius
	local x_2, y_2 = -radius, radius
	local x_3, y_3 = radius, radius

	local px_1 = x_1 * cos(radians) - y_1 * sin(radians)
	local py_1 = y_1 * cos(radians) + x_1 * sin(radians)

	local px_2 = x_2 * cos(radians) - y_2 * sin(radians)
	local py_2 = y_2 * cos(radians) + x_2 * sin(radians)

	local px_3 = x_3 * cos(radians) - y_3 * sin(radians)
	local py_3 = y_3 * cos(radians) + x_3 * sin(radians)

	result = {
		vec2(x + px_1, y + py_1),
		vec2(x + px_2, y + py_2),
		vec2(x + px_3, y + py_3)
	}

	return result
end

local function draw_triangle(triangle)
	local stat_handle = Stats.begin("draw_triangle", stats_category)

	local vertices = get_triangle_vertices(triangle.x, triangle.y, triangle.radius, triangle.rotation)
	if triangle.mode == "fill" then
		local tri_mesh = mesh()
		tri_mesh.vertices = vertices
		tri_mesh:setColor(triangle.colour)
	elseif triangle.mode == "line" then
		stroke(triangle.colour)

		for i = 2, #vertices do
			local v_1 = vertices[i - 1]
			local v_2 = vertices[i]

			line(v_1.x, v_1.y, v_2.x, v_2.y)
		end
	end

	Stats.finish(stat_handle)
end

local function draw_check(check)
	local stat_handle = Stats.begin("draw_check", stats_category)

	local vertices = {
		vec2(check.x - check.radius * 0.5, check.y),
		vec2(check.x, check.y + check.radius),
		vec2(check.x + check.radius, check.y - check.radius)
	}

	stroke(check.colour)
	for i = 2, #vertices do
		local v_1 = vertices[i - 1]
		local v_2 = vertices[i]

		line(v_1.x, v_1.y, v_2.x, v_2.y)
	end

	Stats.finish(stat_handle)
end

local function draw_text(txt)
	local stat_handle = Stats.begin("draw_text", stats_category)

	font(txt.font)
	color(txt.colour)
	text(txt.text, txt.x, txt.y)

	Stats.finish(stat_handle)
end

local function draw_text_formatted(txt)
	local stat_handle = Stats.begin("draw_text_formatted", stats_category)

	font(txt.font)
	color(txt.colour)
	textWrapWidth(txt.w)
	textAlign(txt.align)
	text(string.format(txt.text), txt.x, txt.y)

	Stats.finish(stat_handle)
end

local function draw_text_object(text)
	local stat_handle = Stats.begin("draw_text_object", stats_category)

	spriteMode(CORNER)
	color(255)
	sprite(txt.text, txt.x, txt.y)

	Stats.finish(stat_handle)
end

local function draw_line(line)
	local stat_handle = Stats.begin("draw_line", stats_category)

	stroke(line.colour)
	local line_w = strokeWidth()
	strokeWidth(line.width)
	line(line.x_1, line.y_1, line.x_2, line.y_2)
	strokeWidth(line_w)

	Stats.finish(stat_handle)
end

local function draw_cross(cross)
	local stat_handle = Stats.begin("draw_cross", stats_category)

	local x, y = cross.x, cross.y
	local r = cross.radius
	color(cross.colour)
	line(x - r, y - r, x + r, y + r)
	line(x - r, y + r, x + r, y - r)

	Stats.finish(stat_handle)
end

local function draw_image(img)
	local stat_handle = Stats.begin("draw_image", stats_category)

	pushMatrix()

	spriteMode(CORNER)
	color(img.colour)
	rotate(img.rotation)
	scale(img.scale_x, img.scale_y)
	sprite(img.image, img.x, img.y)

	popMatrix()

	Stats.finish(stat_handle)
end

local function draw_sub_image(img)
	local stat_handle = Stats.begin("draw_sub_image", stats_category)

	pushMatrix()

	spriteMode(CORNER)
	color(img.colour)
	-- TODO: Transform
	local quad = img.quad
	local spr = img.image
	sprite(spr:copy(quad.x, quad.y, quad.w, quad.h), img.x, img.y)

	popMatrix()

	Stats.finish(stat_handle)
end

local function draw_circle(circle)
	local stat_handle = Stats.begin("draw_circle", stats_category)

	if circle.mode == "fill" then
		noStroke()
		fill(circle.colour)
	elseif circle.mode == "line" then
		noFill()
		stroke(circle.colour)
	end

	ellipseMode(CORNER)
	ellipse(circle.x, circle.y, circle.radius, circle.radius)

	Stats.finish(stat_handle)
end

local function draw_curve(curve)
	local stat_handle = Stats.begin("draw_curve", stats_category)

	stroke(curve.colour)

	local vertices = curve.points

	for i = 2, #vertices do
		local v_1 = vertices[i - 1]
		local v_2 = vertices[i]

		line(v_1.x, v_1.y, v_2.x, v_2.y)
	end

	Stats.finish(stat_handle)
end

local function draw_polygon(polygon)
	local stat_handle = Stats.begin("draw_polygon", stats_category)

	local vertices = curve.points
	if polygon.mode == "fill" then
		local poly_mesh = mesh()
		poly_mesh.vertices = triangulate(vertices)
		poly_mesh:setColor(polygon.colour)
	elseif polygon.mode == "line" then
		stroke(curve.colour)

		for i = 2, #vertices do
			local v_1 = vertices[i - 1]
			local v_2 = vertices[i]

			line(v_1.x, v_1.y, v_2.x, v_2.y)
		end
	end

	Stats.finish(stat_handle)
end

local function draw_canvas(canvas)
	local stat_handle = Stats.begin("draw_canvas", stats_category)

	-- TODO

	Stats.finish(stat_handle)
end

local function draw_mesh(msh)
	local stat_handle = Stats.begin("draw_mesh", stats_category)

	-- TODO

	Stats.finish(stat_handle)
end

local function draw_elements(elements)
	local stat_handle = Stats.begin("draw_elements", stats_category)

	for k, v in pairs(elements) do
		if v.t == Types.Rectangle then
			draw_rect(v)
		elseif v.t == Types.Triangle then
			draw_triangle(v)
		elseif v.t == Types.Text then
			draw_text(v)
		elseif v.t == Types.Scissor then
			clip(v.x, v.y, v.w, v.h)
		elseif v.t == Types.TransformPush then
			pushMatrix()
		elseif v.t == Types.TransformPop then
			popMatrix()
		elseif v.t == Types.ApplyTransform then
			applyMatrix(v.transform)
		elseif v.t == Types.Check then
			draw_check(v)
		elseif v.t == Types.Line then
			draw_line(v)
		elseif v.t == Types.TextFormatted then
			draw_text_formatted(v)
		elseif v.t == Types.IntersectScissor then
			-- TODO: Fix?
			clip(v.x, v.y, v.w, v.h)
		elseif v.t == Types.Cross then
			draw_cross(v)
		elseif v.t == Types.Image then
			draw_image(v)
		elseif v.t == Types.SubImage then
			draw_sub_image(v)
		elseif v.t == Types.Circle then
			draw_circle(v)
		elseif v.t == Types.DrawCanvas then
			draw_canvas(v)
		elseif v.t == Types.Mesh then
			draw_mesh(v)
		elseif v.t == Types.TextObject then
			draw_text_object(v)
		elseif v.t == Types.Curve then
			draw_curve(v)
		elseif v.t == Types.Polygon then
			draw_polygon(v)
		elseif v.t == Types.ShaderPush then
			insert(shaders, 1, v.shader)
			shader(v.shader)
		elseif v.t == Types.ShaderPop then
			remove(shaders, 1)
			shader(shaders[1])
		end
	end

	Stats.finish(stat_handle)
end

local function assert_active_batch()
	assert(active_batch ~= nil, "DrawCommands.begin was not called before commands were issued!")
end

local function DrawLayer(layer, name)
	if layer.channels == nil then
		return
	end

	local stat_handle = Stats.begin("draw layer " .. name, stats_category)

	local keys = {}
	for k, channel in pairs(layer.channels) do
		insert(keys, k)
	end

	table.sort(keys)

	for index, c in ipairs(keys) do
		local channel = layer.channels[c]
		if channel ~= nil then
			for i, v in ipairs(channel) do
				draw_elements(v.elements)
			end
		end
	end

	Stats.finish(stat_handle)
end

function DrawCommands.reset()
	layer_table = {}
	layer_table[Layers.Normal] = {}
	layer_table[Layers.Dock] = {}
	layer_table[Layers.ContextMenu] = {}
	layer_table[Layers.MainMenuBar] = {}
	layer_table[Layers.Dialog] = {}
	layer_table[Layers.Debug] = {}
	active_layer = Layers.Normal
	pending_batches = {}
	active_batch = nil
	shaders = {}
end

function DrawCommands.begin(options)
	options = options == nil and {} or options
	options.channel = options.channel == nil and 1 or options.channel

	if layer_table[active_layer].channels == nil then
		layer_table[active_layer].channels = {}
	end

	if layer_table[active_layer].channels[options.channel] == nil then
		layer_table[active_layer].channels[options.channel] = {}
	end

	local channel = layer_table[active_layer].channels[options.channel]

	active_batch = {}
	active_batch.elements = {}
	insert(channel, active_batch)
	insert(pending_batches, 1, active_batch)
end

function DrawCommands.finish(clear_elements)
	clear_elements = clear_elements == nil and false or clear_elements

	if active_batch ~= nil then
		if clear_elements then
			active_batch.elements = {}
		end

		love.graphics.setScissor()
		remove(pending_batches, 1)

		active_batch = nil
		if #pending_batches > 0 then
			active_batch = pending_batches[1]
		end
	end
end

function DrawCommands.set_layer(layer)
	if layer == "Normal" then
		active_layer = Layers.Normal
	elseif layer == "Dock" then
		active_layer = Layers.Dock
	elseif layer == "ContextMenu" then
		active_layer = Layers.ContextMenu
	elseif layer == "MainMenuBar" then
		active_layer = Layers.MainMenuBar
	elseif layer == "Dialog" then
		active_layer = Layers.Dialog
	elseif layer == "Debug" then
		active_layer = Layers.Debug
	end
end

function DrawCommands.rectangle(mode, x, y, width, height, colour, radius, segments)
	assert_active_batch()
	if type(radius) == "table" then
		segments = segments == nil and 10 or segments

		local verts = {}
		local t_l = radius[1]
		local t_r = radius[2]
		local b_r = radius[3]
		local b_l = radius[4]

		t_l = t_l == nil and 0 or t_l
		t_r = t_r == nil and 0 or t_r
		b_r = b_r == nil and 0 or b_r
		b_l = b_l == nil and 0 or b_l

		add_arc(verts, width - b_r, height - b_r, b_r, 0, 90, segments, x, y)
		add_arc(verts, width - t_r, t_r, t_r, 90, 180, segments, x, y)
		add_arc(verts, t_l, t_l, t_l, 180, 270, segments, x, y)
		add_arc(verts, b_l, height - b_l, b_l, 270, 360, segments, x, y)

		DrawCommands.polygon(mode, verts, colour)
	else
		local item = {}
		item.t = Types.Rectangle
		item.mode = mode
		item.x = x
		item.y = y
		item.width = width
		item.height = height
		item.colour = colour and colour or {0.0, 0.0, 0.0, 1.0}
		item.radius = radius and radius or 0.0
		insert(active_batch.elements, item)
	end
end

function DrawCommands.triangle(mode, x, y, radius, rotation, colour)
	assert_active_batch()
	local item = {}
	item.t = Types.Triangle
	item.mode = mode
	item.x = x
	item.y = y
	item.radius = radius
	item.rotation = rotation
	item.colour = colour and colour or {0.0, 0.0, 0.0, 1.0}
	insert(active_batch.elements, item)
end

function DrawCommands.print(text, x, y, colour, font)
	assert_active_batch()
	local item = {}
	item.t = Types.Text
	item.text = text
	item.x = x
	item.y = y
	item.colour = colour and colour or {1.0, 1.0, 1.0, 1.0}
	item.font = font
	insert(active_batch.elements, item)
end

function DrawCommands.printf(text, x, y, w, align, colour, font)
	assert_active_batch()
	local item = {}
	item.t = Types.TextFormatted
	item.text = text
	item.x = x
	item.y = y
	item.w = w
	item.align = align and align or "left"
	item.colour = colour and colour or {1.0, 1.0, 1.0, 1.0}
	item.font = font
	insert(active_batch.elements, item)
end

function DrawCommands.scissor(x, y, w, h)
	assert_active_batch()
	if w ~= nil then
		w = max(w, 0.0)
	end
	if h ~= nil then
		h = max(h, 0.0)
	end
	local item = {}
	item.t = Types.Scissor
	item.x = x
	item.y = y
	item.w = w
	item.h = h
	insert(active_batch.elements, item)
end

function DrawCommands.intersect_scissor(x, y, w, h)
	assert_active_batch()
	if w ~= nil then
		w = max(w, 0.0)
	end
	if h ~= nil then
		h = max(h, 0.0)
	end
	local item = {}
	item.t = Types.IntersectScissor
	item.x = x and x or 0.0
	item.y = y and y or 0.0
	item.w = w and w or 0.0
	item.h = h and h or 0.0
	insert(active_batch.elements, item)
end

function DrawCommands.transform_push()
	assert_active_batch()
	local item = {}
	item.t = Types.TransformPush
	insert(active_batch.elements, item)
end

function DrawCommands.transform_pop()
	assert_active_batch()
	local item = {}
	item.t = Types.TransformPop
	insert(active_batch.elements, item)
end

function DrawCommands.apply_transform(transform)
	assert_active_batch()
	local item = {}
	item.t = Types.ApplyTransform
	item.transform = transform
	insert(active_batch.elements, item)
end

function DrawCommands.check(x, y, radius, colour)
	assert_active_batch()
	local item = {}
	item.t = Types.Check
	item.x = x
	item.y = y
	item.radius = radius
	item.colour = colour and colour or {0.0, 0.0, 0.0, 1.0}
	insert(active_batch.elements, item)
end

function DrawCommands.line(x_1, y_1, x_2, y_2, width, colour)
	assert_active_batch()
	local item = {}
	item.t = Types.Line
	item.x_1 = x_1
	item.y_1 = y_1
	item.x_2 = x_2
	item.y_2 = y_2
	item.width = width
	item.colour = colour and colour or {0.0, 0.0, 0.0, 1.0}
	insert(active_batch.elements, item)
end

function DrawCommands.cross(x, y, radius, colour)
	assert_active_batch()
	local item = {}
	item.t = Types.Cross
	item.x = x
	item.y = y
	item.radius = radius
	item.colour = colour and colour or {0.0, 0.0, 0.0, 1.0}
	insert(active_batch.elements, item)
end

function DrawCommands.image(x, y, img, rotation, scale_x, scale_y, colour)
	assert_active_batch()
	local item = {}
	item.t = Types.Image
	item.x = x
	item.y = y
	item.img = img
	item.rotation = rotation
	item.scale_x = scale_x
	item.scale_y = scale_y
	item.colour = colour and colour or {1.0, 1.0, 1.0, 1.0}
	insert(active_batch.elements, item)
end

function DrawCommands.SubImage(x, y, img, s_x, s_y, s_w, s_h, rotation, scale_x, scale_y, colour)
	assert_active_batch()
	local item = {}
	item.t = Types.SubImage
	item.transform = love.math.newTransform(x, y, rotation, scale_x, scale_y)
	item.img = img
	item.quad = love.graphics.newQuad(s_x, s_y, s_w, s_h, img:getWidth(), img:getHeight())
	item.colour = colour and colour or {1.0, 1.0, 1.0, 1.0}
	insert(active_batch.elements, item)
end

function DrawCommands.circle(mode, x, y, radius, colour, segments)
	assert_active_batch()
	local item = {}
	item.t = Types.Circle
	item.mode = mode
	item.x = x
	item.y = y
	item.radius = radius
	item.colour = colour and colour or {0.0, 0.0, 0.0, 1.0}
	item.segments = segments and segments or 24
	insert(active_batch.elements, item)
end

function DrawCommands.draw_canvas(canvas, x, y)
	assert_active_batch()
	local item = {}
	item.t = Types.DrawCanvas
	item.canvas = canvas
	item.x = x
	item.y = y
	insert(active_batch.elements, item)
end

function DrawCommands.mesh(msh, x, y)
	assert_active_batch()
	local item = {}
	item.t = Types.Mesh
	item.msh = msh
	item.x = x
	item.y = y
	insert(active_batch.elements, item)
end

function DrawCommands.text(text, x, y)
	assert_active_batch()
	local item = {}
	item.t = Types.TextObject
	item.text = text
	item.x = x
	item.y = y
	item.colour = {0, 0, 0, 1}
	insert(active_batch.elements, item)
end

function DrawCommands.curve(points, colour)
	assert_active_batch()
	local item = {}
	item.t = Types.Curve
	item.points = points
	item.colour = colour ~= nil and colour or {0, 0, 0, 1}
	insert(active_batch.elements, item)
end

function DrawCommands.polygon(mode, points, colour)
	assert_active_batch()
	local item = {}
	item.t = Types.Polygon
	item.mode = mode
	item.points = points
	item.colour = colour ~= nil and colour or {0, 0, 0, 1}
	insert(active_batch.elements, item)
end

function DrawCommands.push_shader(shader)
	assert_active_batch()
	local item = {
		t = Types.ShaderPush,
		shader = shader
	}
	insert(active_batch.elements, item)
end

function DrawCommands.pop_shader()
	assert_active_batch()
	local item = {
		t = Types.ShaderPop
	}
	insert(active_batch.elements, item)
end

function DrawCommands.execute()
	local stat_handle = Stats.begin("execute", stats_category)

	DrawLayer(layer_table[Layers.Normal], "Normal")
	DrawLayer(layer_table[Layers.Dock], "Dock")
	DrawLayer(layer_table[Layers.ContextMenu], "ContextMenu")
	DrawLayer(layer_table[Layers.MainMenuBar], "MainMenuBar")
	DrawLayer(layer_table[Layers.Dialog], "Dialog")
	DrawLayer(layer_table[Layers.Debug], "Debug")

	shader()

	Stats.finish(stat_handle)
end

function DrawCommands.get_debug_info()
	local result = {}

	result["Normal"] = get_layer_debug_info(layer_table[Layers.Normal])
	result["Dock"] = get_layer_debug_info(layer_table[Layers.Dock])
	result["ContextMenu"] = get_layer_debug_info(layer_table[Layers.ContextMenu])
	result["MainMenuBar"] = get_layer_debug_info(layer_table[Layers.MainMenuBar])
	result["Dialog"] = get_layer_debug_info(layer_table[Layers.Dialog])
	result["Debug"] = get_layer_debug_info(layer_table[Layers.Debug])

	return result
end

return DrawCommands
