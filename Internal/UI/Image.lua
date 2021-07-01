local Cursor = required("Cursor")
local DrawCommands = required("DrawCommands")
local LayoutManager = required("LayoutManager")
local Mouse = required("Mouse")
local Stats = required("Stats")
local Style = required("Style")
local tooltip = required("tooltip")
local Window = required("Window")

local Image = {}

local instances = {}
local image_cache = {}

local function get_image(path)
	if image_cache[path] == nil then
		image_cache[path] = love.graphics.newImage(path)
		local wrap_h, wrap_v = image_cache[path]:getWrap()
	end
	return image_cache[path]
end

local function get_instance(id)
	local key = Window.get_id() .. "." .. id
	if instances[key] == nil then
		local instance = {}
		instance.id = id
		instance.img = nil
		instances[key] = instance
	end
	return instances[key]
end

function Image.begin(id, options)
	local stat_handle = Stats.begin("img", "Slab")

	options = options == nil and {} or options
	options.tooltip = options.tooltip == nil and "" or options.tooltip
	options.rotation = options.rotation == nil and 0 or options.rotation
	options.scale = options.scale == nil and 1 or options.scale
	options.scale_x = options.scale_x == nil and options.scale or options.scale_x
	options.scale_y = options.scale_y == nil and options.scale or options.scale_y
	options.colour = options.colour == nil and {1.0, 1.0, 1.0, 1.0} or options.colour
	options.sub_x = options.sub_x == nil and 0.0 or options.sub_x
	options.sub_y = options.sub_y == nil and 0.0 or options.sub_y
	options.sub_w = options.sub_w == nil and 0.0 or options.sub_w
	options.sub_h = options.sub_h == nil and 0.0 or options.sub_h
	options.wrap_h = options.wrap_h == nil and "clamp" or options.wrap_h
	options.wrap_v = options.wrap_v == nil and "clamp" or options.wrap_v

	local instance = get_instance(id)
	local win_item_id = Window.get_item_id(id)

	if instance.img == nil then
		if options.img == nil then
			assert(options.path ~= nil, "path to an image is required if no image is set!")
			instance.img = get_image(options.path)
		else
			instance.img = options.img
		end
	end

	instance.img:setWrap(options.wrap_h, options.wrap_v)

	local w = instance.img:getWidth() * options.scale_x
	local h = instance.img:getHeight() * options.scale_y

	local use_sub_image = false
	if options.sub_w > 0.0 and options.sub_h > 0.0 then
		w = options.sub_w * options.scale_x
		h = options.sub_h * options.scale_y
		use_sub_image = true
	end

	LayoutManager.add_control(w, h)

	local x, y = Cursor.get_position()
	local mouse_x, mouse_y = Window.get_mouse_position()

	if not Window.is_obstructed_at_mouse() and x <= mouse_x and mouse_x <= x + w and y <= mouse_y and mouse_y <= y + h then
		Tooltip.begin(options.tooltip)
		Window.set_hot_item(win_item_id)
	end

	if use_sub_image then
		DrawCommands.SubImage(
			x,
			y,
			instance.img,
			options.sub_x,
			options.sub_y,
			options.sub_w,
			options.sub_h,
			options.rotation,
			options.scale_x,
			options.scale_y,
			options.colour
		)
	else
		DrawCommands.image(x, y, instance.img, options.rotation, options.scale_x, options.scale_y, options.colour)
	end

	Cursor.set_item_bounds(x, y, w, h)
	Cursor.advance_y(h)

	Window.add_item(x, y, w, h, win_item_id)

	Stats.finish(stat_handle)
end

function Image.get_size(img)
	if img ~= nil then
		local data = img
		if type(img) == "string" then
			data = get_image(img)
		end

		if data ~= nil then
			return data:getWidth(), data:getHeight()
		end
	end

	return 0, 0
end

return Image
