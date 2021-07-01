local ceil = math.ceil
local max = math.max
local min = math.min
local insert = table.insert

local Button = required("button")
local Cursor = required("Cursor")
local DrawCommands = required("DrawCommands")
local Image = required("img")
local Input = required("Input")
local LayoutManager = required("LayoutManager")
local Mouse = required("Mouse")
local Style = required("Style")
local text = required("text")
local Utility = required("Utility")
local Window = required("Window")

local ColorPicker = {}

local saturation_meshes = nil
local saturation_size = 200.0
local saturation_step = 5
local saturation_focused = false

local tint_meshes = nil
local tint_w = 30.0
local tint_h = saturation_size
local tint_focused = false

local alpha_mesh = nil
local alpha_w = tint_w
local alpha_h = tint_h
local alpha_focused = false

local current_color = {1.0, 1.0, 1.0, 1.0}
local color_h = 25.0

local function is_equal(a, b)
	for i, v in ipairs(a) do
		if v ~= b[i] then
			return false
		end
	end

	return true
end

local function input_color(component, value, offset_x)
	local changed = false
	Text.begin(string.format("%s ", component))
	Cursor.same_line()
	Cursor.set_relative_x(offset_x)
	if
		Input.begin(
			"ColorPicker_" .. component,
			{w = 40.0, numbers_only = true, text = tostring(ceil(value * 255)), return_on_text = false}
		)
	 then
		local new_value = tonumber(Input.get_text())
		if new_value ~= nil then
			new_value = max(new_value, 0)
			new_value = min(new_value, 255)
			value = new_value / 255
			changed = true
		end
	end
	return value, changed
end

local function update_saturation_colors()
	if saturation_meshes ~= nil then
		local mesh_index = 1
		local step = saturation_step
		local c_0_0 = {1.0, 1.0, 1.0, 1.0}
		local c_1_0 = {1.0, 1.0, 1.0, 1.0}
		local c_0_1 = {1.0, 1.0, 1.0, 1.0}
		local c_1_1 = {1.0, 1.0, 1.0, 1.0}
		local step_x, step_y = 0, 0
		local hue, sat, val = Utility.rgb_to_hsv(current_color[1], current_color[2], current_color[3])

		for i = 1, step, 1 do
			for j = 1, step, 1 do
				local S0 = step_x / step
				local S1 = (step_x + 1) / step
				local V0 = 1.0 - (step_y / step)
				local V1 = 1.0 - ((step_y + 1) / step)

				c_0_0[1], c_0_0[2], c_0_0[3] = Utility.hsv_to_rgb(hue, S0, V0)
				c_1_0[1], c_1_0[2], c_1_0[3] = Utility.hsv_to_rgb(hue, S1, V0)
				c_0_1[1], c_0_1[2], c_0_1[3] = Utility.hsv_to_rgb(hue, S0, V1)
				c_1_1[1], c_1_1[2], c_1_1[3] = Utility.hsv_to_rgb(hue, S1, V1)

				local msh = saturation_meshes[mesh_index]
				mesh_index = mesh_index + 1

				msh:setVertexAttribute(1, 3, c_0_0[1], c_0_0[2], c_0_0[3], c_0_0[4])
				msh:setVertexAttribute(2, 3, c_1_0[1], c_1_0[2], c_1_0[3], c_1_0[4])
				msh:setVertexAttribute(3, 3, c_1_1[1], c_1_1[2], c_1_1[3], c_1_1[4])
				msh:setVertexAttribute(4, 3, c_0_1[1], c_0_1[2], c_0_1[3], c_0_1[4])

				step_x = step_x + 1
			end

			step_x = 0
			step_y = step_y + 1
		end
	end
end

local function initialize_saturation_meshes()
	if saturation_meshes == nil then
		saturation_meshes = {}
		local step = saturation_step
		local x, y = 0.0, 0.0
		local size = saturation_size / step

		for i = 1, step, 1 do
			for j = 1, step, 1 do
				local verts = {
					{
						x,
						y,
						0.0,
						0.0
					},
					{
						x + size,
						y,
						1.0,
						0.0
					},
					{
						x + size,
						y + size,
						1.0,
						1.0
					},
					{
						x,
						y + size,
						0.0,
						1.0
					}
				}

				local new_mesh = love.graphics.newMesh(verts)
				insert(saturation_meshes, new_mesh)

				x = x + size
			end

			x = 0.0
			y = y + size
		end
	end

	update_saturation_colors()
end

local function InitializeTintMeshes()
	if tint_meshes == nil then
		tint_meshes = {}
		local step = 6
		local x, y = 0.0, 0.0
		local c_0 = {1.0, 1.0, 1.0, 1.0}
		local c_1 = {1.0, 1.0, 1.0, 1.0}
		local i = 0
		local colors = {
			{1.0, 0.0, 0.0, 1.0},
			{1.0, 1.0, 0.0, 1.0},
			{0.0, 1.0, 0.0, 1.0},
			{0.0, 1.0, 1.0, 1.0},
			{0.0, 0.0, 1.0, 1.0},
			{1.0, 0.0, 1.0, 1.0},
			{1.0, 0.0, 0.0, 1.0}
		}

		for index = 1, step, 1 do
			c_0 = colors[index]
			c_1 = colors[index + 1]
			local verts = {
				{
					x,
					y,
					0.0,
					0.0,
					c_0[1],
					c_0[2],
					c_0[3],
					c_0[4]
				},
				{
					tint_w,
					y,
					1.0,
					0.0,
					c_0[1],
					c_0[2],
					c_0[3],
					c_0[4]
				},
				{
					tint_w,
					y + tint_h / step,
					1.0,
					1.0,
					c_1[1],
					c_1[2],
					c_1[3],
					c_1[4]
				},
				{
					x,
					y + tint_h / step,
					0.0,
					1.0,
					c_1[1],
					c_1[2],
					c_1[3],
					c_1[4]
				}
			}

			local new_mesh = love.graphics.newMesh(verts)
			insert(tint_meshes, new_mesh)

			y = y + tint_h / step
		end
	end
end

local function initialize_alpha_mesh()
	if alpha_mesh == nil then
		local verts = {
			{
				0.0,
				0.0,
				0.0,
				0.0,
				1.0,
				1.0,
				1.0,
				1.0
			},
			{
				alpha_w,
				0.0,
				1.0,
				0.0,
				1.0,
				1.0,
				1.0,
				1.0
			},
			{
				alpha_w,
				alpha_h,
				1.0,
				1.0,
				0.0,
				0.0,
				0.0,
				1.0
			},
			{
				0.0,
				alpha_h,
				0.0,
				1.0,
				0.0,
				0.0,
				0.0,
				1.0
			}
		}

		alpha_mesh = love.graphics.newMesh(verts)
	end
end

function ColorPicker.begin(options)
	options = options == nil and {} or options
	options.colour = options.colour == nil and {1.0, 1.0, 1.0, 1.0} or options.colour
	options.refresh = options.refresh == nil and false or options.refresh
	options.x = options.x == nil and nil or options.x
	options.y = options.y == nil and nil or options.y

	if saturation_meshes == nil then
		initialize_saturation_meshes()
	end

	if tint_meshes == nil then
		InitializeTintMeshes()
	end

	if alpha_mesh == nil then
		initialize_alpha_mesh()
	end

	Window.begin("ColorPicker", {title = "colour Picker", x = options.x, y = options.y})

	if Window.is_appearing() or options.refresh then
		current_color[1] = options.colour[1]
		current_color[2] = options.colour[2]
		current_color[3] = options.colour[3]
		current_color[4] = options.colour[4]
		update_saturation_colors()
	end

	local x, y = Cursor.get_position()
	local mouse_x, mouse_y = Window.get_mouse_position()
	local h, s, v = Utility.rgb_to_hsv(current_color[1], current_color[2], current_color[3])
	local update_color = false
	local mouse_clicked = Mouse.is_clicked(1) and not Window.is_obstructed_at_mouse()

	if saturation_meshes ~= nil then
		for i, v in ipairs(saturation_meshes) do
			DrawCommands.mesh(v, x, y)
		end

		Window.add_item(x, y, saturation_size, saturation_size)

		local update_saturation = false
		if x <= mouse_x and mouse_x < x + saturation_size and y <= mouse_y and mouse_y < y + saturation_size then
			if mouse_clicked then
				saturation_focused = true
				update_saturation = true
			end
		end

		if saturation_focused and Mouse.is_dragging(1) then
			update_saturation = true
		end

		if update_saturation then
			local canvas_x = max(mouse_x - x, 0)
			canvas_x = min(canvas_x, saturation_size)

			local canvas_y = max(mouse_y - y, 0)
			canvas_y = min(canvas_y, saturation_size)

			s = canvas_x / saturation_size
			v = 1 - (canvas_y / saturation_size)

			update_color = true
		end

		local saturation_x = s * saturation_size
		local saturation_y = (1.0 - v) * saturation_size
		DrawCommands.circle("line", x + saturation_x, y + saturation_y, 4.0, {1.0, 1.0, 1.0, 1.0})

		x = x + saturation_size + Cursor.pad_x()
	end

	if tint_meshes ~= nil then
		for i, v in ipairs(tint_meshes) do
			DrawCommands.mesh(v, x, y)
		end

		Window.add_item(x, y, tint_w, tint_h)

		local update_tint = false
		if x <= mouse_x and mouse_x < x + tint_w and y <= mouse_y and mouse_y < y + tint_h then
			if mouse_clicked then
				tint_focused = true
				update_tint = true
			end
		end

		if tint_focused and Mouse.is_dragging(1) then
			update_tint = true
		end

		if update_tint then
			local canvas_y = max(mouse_y - y, 0)
			canvas_y = min(canvas_y, tint_h)

			h = canvas_y / tint_h

			update_color = true
		end

		local tint_y = h * tint_h
		DrawCommands.line(x, y + tint_y, x + tint_w, y + tint_y, 2.0, {1.0, 1.0, 1.0, 1.0})

		x = x + tint_w + Cursor.pad_x()
		DrawCommands.mesh(alpha_mesh, x, y)
		Window.add_item(x, y, alpha_w, alpha_h)

		local update_alpha = false
		if x <= mouse_x and mouse_x < x + alpha_w and y <= mouse_y and mouse_y < y + alpha_h then
			if mouse_clicked then
				alpha_focused = true
				update_alpha = true
			end
		end

		if alpha_focused and Mouse.is_dragging(1) then
			update_alpha = true
		end

		if update_alpha then
			local canvas_y = max(mouse_y - y, 0)
			canvas_y = min(canvas_y, alpha_h)

			current_color[4] = 1.0 - canvas_y / alpha_h

			update_color = true
		end

		local a = 1.0 - current_color[4]
		local alpha_y = a * alpha_h
		DrawCommands.line(x, y + alpha_y, x + alpha_w, y + alpha_y, 2.0, {a, a, a, 1.0})

		y = y + alpha_h + Cursor.pad_y()
	end

	if update_color then
		current_color[1], current_color[2], current_color[3] = Utility.hsv_to_rgb(h, s, v)
		update_saturation_colors()
	end

	local offset_x = Text.get_width("##")
	Cursor.advance_y(saturation_size)
	x, y = Cursor.get_position()
	local r = current_color[1]
	local g = current_color[2]
	local b = current_color[3]
	local a = current_color[4]

	current_color[1], r = input_color("r", r, offset_x)
	current_color[2], g = input_color("g", g, offset_x)
	current_color[3], b = input_color("b", b, offset_x)
	current_color[4], a = input_color("a", a, offset_x)

	if r or g or b or a then
		update_saturation_colors()
	end

	local input_x, input_y = Cursor.get_position()
	Cursor.same_line()
	x = Cursor.get_x()
	Cursor.set_y(y)

	local win_x, win_y, win_w, win_h = Window.get_bounds()
	win_w, win_h = Window.get_borderless_size()

	offset_x = Text.get_width("####")
	local color_x = x + offset_x

	local color_w = (win_x + win_w) - color_x
	Cursor.set_position(color_x, y)
	Image.begin(
		"ColorPicker_CurrentAlpha",
		{
			path = SLAB_FILE_PATH .. "/Internal/Resources/Textures/Transparency.png",
			sub_w = color_w,
			sub_h = color_h,
			wrap_h = "repeat",
			wrap_v = "repeat"
		}
	)
	DrawCommands.rectangle("fill", color_x, y, color_w, color_h, current_color, Style.button_rounding)

	local label_w, LabelH = Text.get_size("New")
	Cursor.set_position(color_x - label_w - Cursor.pad_x(), y + (color_h * 0.5) - (LabelH * 0.5))
	Text.begin("New")

	y = y + color_h + Cursor.pad_y()

	Cursor.set_position(color_x, y)
	Image.begin(
		"ColorPicker_CurrentAlpha",
		{
			path = SLAB_FILE_PATH .. "/Internal/Resources/Textures/Transparency.png",
			sub_w = color_w,
			sub_h = color_h,
			wrap_h = "repeat",
			wrap_v = "repeat"
		}
	)
	DrawCommands.rectangle("fill", color_x, y, color_w, color_h, options.colour, Style.button_rounding)

	local label_w, LabelH = Text.get_size("Old")
	Cursor.set_position(color_x - label_w - Cursor.pad_x(), y + (color_h * 0.5) - (LabelH * 0.5))
	Text.begin("Old")

	if Mouse.is_released(1) then
		saturation_focused = false
		tint_focused = false
		alpha_focused = false
	end

	Cursor.set_position(input_x, input_y)
	Cursor.new_line()

	LayoutManager.begin("ColorPicker_Buttons_Layout", {align_x = "right"})
	local result = {button = "", colour = Utility.make_color(current_color)}
	if Button.begin("OK") then
		result.button = "OK"
	end

	LayoutManager.same_line()

	if Button.begin("Cancel") then
		result.button = "Cancel"
		result.colour = Utility.make_color(options.colour)
	end
	LayoutManager.finish()

	Window.finish()

	return result
end

return ColorPicker
