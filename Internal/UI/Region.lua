local max = math.max
local min = math.min
local floor = math.floor

local DrawCommands = required("DrawCommands")
local MenuState = required("MenuState")
local Mouse = required("Mouse")
local Style = required("Style")
local Utility = required("Utility")

local Region = {}

local instances = {}
local stack = {}
local active_instance = nil
local scroll_pad = 3.0
local scroll_bar_size = 10.0
local wheel_x = 0.0
local wheel_y = 0.0
local wheel_speed = 3.0
local hot_instance = nil
local wheel_instance = nil
local scroll_instance = nil

local function get_x_scroll_size(instance)
	if instance ~= nil then
		return max(instance.w - (instance.content_w - instance.w), 10.0)
	end
	return 0.0
end

local function get_y_scroll_size(instance)
	if instance ~= nil then
		return max(instance.h - (instance.content_h - instance.h), 10.0)
	end
	return 0.0
end

local function is_scroll_hovered(instance, x, y)
	local has_scroll_x, has_scroll_y = false, false

	if instance ~= nil then
		if instance.has_scroll_x then
			local pos_y = instance.y + instance.h - scroll_pad - scroll_bar_size
			local size_x = get_x_scroll_size(instance)
			local pos_x = instance.scroll_pos_x
			has_scroll_x =
				instance.x + pos_x <= x and x < instance.x + pos_x + size_x and pos_y <= y and y < pos_y + scroll_bar_size
		end

		if instance.has_scroll_y then
			local pos_x = instance.x + instance.w - scroll_pad - scroll_bar_size
			local size_y = get_y_scroll_size(instance)
			local pos_y = instance.scroll_pos_y
			has_scroll_y =
				pos_x <= x and x < pos_x + scroll_bar_size and instance.y + pos_y <= y and y < instance.y + pos_y + size_y
		end
	end
	return has_scroll_x, has_scroll_y
end

local function contains(instance, x, y)
	if instance ~= nil then
		return instance.x <= x and x <= instance.x + instance.w and instance.y <= y and y <= instance.y + instance.h
	end
	return false
end

local function update_scroll_bars(instance, is_obstructed)
	if instance.ignore_scroll then
		return
	end

	instance.has_scroll_x = instance.content_w > instance.w
	instance.has_scroll_y = instance.content_h > instance.h

	local x, y = instance.mouse_x, instance.mouse_y
	instance.hover_scroll_x, instance.hover_scroll_y = is_scroll_hovered(instance, x, y)
	local x_size = instance.w - get_x_scroll_size(instance)
	local y_size = instance.h - get_y_scroll_size(instance)

	if is_obstructed then
		instance.hover_scroll_x = false
		instance.hover_scroll_y = false
	end

	local is_mouse_released = Mouse.is_released(1)
	local is_mouse_clicked = Mouse.is_clicked(1)

	local delta_x, delta_y = Mouse.get_delta()

	if wheel_instance == instance then
		instance.hover_scroll_x = wheel_x ~= 0.0
		instance.hover_scroll_y = wheel_y ~= 0.0
	end

	if not is_obstructed and contains(instance, x, y) or (instance.hover_scroll_x or instance.hover_scroll_y) then
		if wheel_instance == instance then
			if wheel_x ~= 0.0 then
				instance.scroll_pos_x = max(instance.scroll_pos_x + wheel_x, 0.0)
				instance.is_scrolling_x = true
				is_mouse_released = true
				wheel_x = 0.0
			end

			if wheel_y ~= 0.0 then
				instance.scroll_pos_y = max(instance.scroll_pos_y - wheel_y, 0.0)
				instance.is_scrolling_y = true
				is_mouse_released = true
				wheel_y = 0.0
			end

			wheel_instance = nil
			scroll_instance = instance
		end

		if scroll_instance == nil and is_mouse_clicked and (instance.hover_scroll_x or instance.hover_scroll_y) then
			scroll_instance = instance
			scroll_instance.is_scrolling_x = instance.hover_scroll_x
			scroll_instance.is_scrolling_y = instance.hover_scroll_y
		end
	end

	if scroll_instance == instance and is_mouse_released then
		instance.is_scrolling_x = false
		instance.is_scrolling_y = false
		scroll_instance = nil
	end

	if instance.has_scroll_x then
		if instance.has_scroll_y then
			x_size = x_size - scroll_bar_size - scroll_pad
		end
		x_size = max(x_size, 0.0)
		if scroll_instance == instance then
			MenuState.request_close = false

			if instance.is_scrolling_x then
				instance.scroll_pos_x = max(instance.scroll_pos_x + delta_x, 0.0)
			end
		end
		instance.scroll_pos_x = min(instance.scroll_pos_x, x_size)
	end

	if instance.has_scroll_y then
		if instance.has_scroll_x then
			y_size = y_size - scroll_bar_size - scroll_pad
		end
		y_size = max(y_size, 0.0)
		if scroll_instance == instance then
			MenuState.request_close = false

			if instance.is_scrolling_y then
				instance.scroll_pos_y = max(instance.scroll_pos_y + delta_y, 0.0)
			end
		end
		instance.scroll_pos_y = min(instance.scroll_pos_y, y_size)
	end

	local x_ratio, y_ratio = 0.0, 0.0
	if x_size ~= 0.0 then
		x_ratio = max(instance.scroll_pos_x / x_size, 0.0)
	end
	if y_size ~= 0.0 then
		y_ratio = max(instance.scroll_pos_y / y_size, 0.0)
	end

	local t_x = max(instance.content_w - instance.w, 0.0) * -x_ratio
	local t_y = max(instance.content_h - instance.h, 0.0) * -y_ratio
	instance.transform:setTransformation(floor(t_x), floor(t_y))
end

local function draw_scroll_bars(instance)
	if not instance.has_scroll_x and not instance.has_scroll_y then
		return
	end

	if hot_instance ~= instance and scroll_instance ~= instance and not Utility.is_mobile() then
		local dt = love.timer.getDelta()
		instance.scroll_alpha_x = max(instance.scroll_alpha_x - dt, 0.0)
		instance.scroll_alpha_y = max(instance.scroll_alpha_y - dt, 0.0)
	else
		instance.scroll_alpha_x = 1.0
		instance.scroll_alpha_y = 1.0
	end

	if instance.has_scroll_x then
		local x_size = get_x_scroll_size(instance)
		local colour = Utility.make_color(Style.ScrollBarColor)
		if instance.hover_scroll_x or instance.is_scrolling_x then
			colour = Utility.make_color(Style.ScrollBarHoveredColor)
		end
		colour[4] = instance.scroll_alpha_x
		local x_pos = instance.scroll_pos_x
		DrawCommands.rectangle(
			"fill",
			instance.x + x_pos,
			instance.y + instance.h - scroll_pad - scroll_bar_size,
			x_size,
			scroll_bar_size,
			colour,
			Style.ScrollBarRounding
		)
	end

	if instance.has_scroll_y then
		local y_size = get_y_scroll_size(instance)
		local colour = Utility.make_color(Style.ScrollBarColor)
		if instance.hover_scroll_y or instance.is_scrolling_y then
			colour = Utility.make_color(Style.ScrollBarHoveredColor)
		end
		colour[4] = instance.scroll_alpha_y
		local y_pos = instance.scroll_pos_y
		DrawCommands.rectangle(
			"fill",
			instance.x + instance.w - scroll_pad - scroll_bar_size,
			instance.y + y_pos,
			scroll_bar_size,
			y_size,
			colour,
			Style.ScrollBarRounding
		)
	end
end

local function get_instance(id)
	if id == nil then
		return active_instance
	end

	if instances[id] == nil then
		local instance = {}
		instance.id = id
		instance.x = 0.0
		instance.y = 0.0
		instance.w = 0.0
		instance.h = 0.0
		instance.s_x = 0.0
		instance.s_y = 0.0
		instance.content_w = 0.0
		instance.content_h = 0.0
		instance.has_scroll_x = false
		instance.has_scroll_y = false
		instance.hover_scroll_x = false
		instance.hover_scroll_y = false
		instance.is_scrolling_x = false
		instance.is_scrolling_y = false
		instance.scroll_pos_x = 0.0
		instance.scroll_pos_y = 0.0
		instance.scroll_alpha_x = 0.0
		instance.scroll_alpha_y = 0.0
		instance.intersect = false
		instance.auto_size_content = false
		instance.transform = love.math.newTransform()
		instance.transform:reset()
		instances[id] = instance
	end
	return instances[id]
end

function Region.begin(id, options)
	options = options == nil and {} or options
	options.x = options.x == nil and 0.0 or options.x
	options.y = options.y == nil and 0.0 or options.y
	options.w = options.w == nil and 0.0 or options.w
	options.h = options.h == nil and 0.0 or options.h
	options.s_x = options.s_x == nil and options.x or options.s_x
	options.s_y = options.s_y == nil and options.y or options.s_y
	options.content_w = options.content_w == nil and 0.0 or options.content_w
	options.content_h = options.content_h == nil and 0.0 or options.content_h
	options.auto_size_content = options.auto_size_content == nil and false or options.auto_size_content
	options.bg_color = options.bg_color == nil and Style.WindowBackgroundColor or options.bg_color
	options.no_outline = options.no_outline == nil and false or options.no_outline
	options.no_background = options.no_background == nil and false or options.no_background
	options.is_obstructed = options.is_obstructed == nil and false or options.is_obstructed
	options.intersect = options.intersect == nil and false or options.intersect
	options.ignore_scroll = options.ignore_scroll == nil and false or options.ignore_scroll
	options.mouse_x = options.mouse_x == nil and 0.0 or options.mouse_x
	options.mouse_y = options.mouse_y == nil and 0.0 or options.mouse_y
	options.reset_content = options.reset_content == nil and false or options.reset_content
	options.rounding = options.rounding == nil and 0.0 or options.rounding

	local instance = get_instance(id)
	instance.x = options.x
	instance.y = options.y
	instance.w = options.w
	instance.h = options.h
	instance.s_x = options.s_x
	instance.s_y = options.s_y
	instance.intersect = options.intersect
	instance.ignore_scroll = options.ignore_scroll
	instance.mouse_x = options.mouse_x
	instance.mouse_y = options.mouse_y
	instance.auto_size_content = options.auto_size_content

	if options.reset_content then
		instance.content_w = 0.0
		instance.content_h = 0.0
	end

	if not options.auto_size_content then
		instance.content_w = options.content_w
		instance.content_h = options.content_h
	end

	active_instance = instance
	table.insert(stack, 1, active_instance)

	update_scroll_bars(instance, options.is_obstructed)

	if options.auto_size_content then
		instance.content_h = 0.0
		instance.content_w = 0.0
	end

	if hot_instance == instance and (not contains(instance, instance.mouse_x, instance.mouse_y) or options.is_obstructed) then
		hot_instance = nil
	end

	if not options.is_obstructed then
		if contains(instance, instance.mouse_x, instance.mouse_y) or (instance.hover_scroll_x or instance.hover_scroll_y) then
			if scroll_instance == nil then
				hot_instance = instance
			else
				hot_instance = scroll_instance
			end
		end
	end

	if not options.no_background then
		DrawCommands.rectangle("fill", instance.x, instance.y, instance.w, instance.h, options.bg_color, options.rounding)
	end
	if not options.no_outline then
		DrawCommands.rectangle("line", instance.x, instance.y, instance.w, instance.h, nil, options.rounding)
	end
	DrawCommands.transform_push()
	DrawCommands.apply_transform(instance.transform)
	Region.apply_scissor()
end

function Region.finish()
	DrawCommands.transform_pop()
	draw_scroll_bars(active_instance)

	if
		hot_instance == active_instance and wheel_instance == nil and (wheel_x ~= 0.0 or wheel_y ~= 0.0) and
			not active_instance.ignore_scroll
	 then
		wheel_instance = active_instance
	end

	if active_instance.intersect then
		DrawCommands.intersect_scissor()
	else
		DrawCommands.scissor()
	end

	active_instance = nil
	table.remove(stack, 1)

	if #stack > 0 then
		active_instance = stack[1]
	end
end

function Region.is_hover_scroll_bar(id)
	local instance = get_instance(id)
	if instance ~= nil then
		return instance.hover_scroll_x or instance.hover_scroll_y
	end
	return false
end

function Region.translate(id, x, y)
	local instance = get_instance(id)
	if instance ~= nil then
		instance.transform:translate(x, y)
		local t_x, t_y = instance.transform:inverseTransformPoint(0, 0)

		if not instance.ignore_scroll then
			if x ~= 0.0 and instance.has_scroll_x then
				local x_size = instance.w - get_x_scroll_size(instance)
				local content_w = instance.content_w - instance.w

				if instance.has_scroll_y then
					x_size = x_size - scroll_pad - scroll_bar_size
				end

				x_size = max(x_size, 0.0)

				instance.scroll_pos_x = (t_x / content_w) * x_size
				instance.scroll_pos_x = max(instance.scroll_pos_x, 0.0)
				instance.scroll_pos_x = min(instance.scroll_pos_x, x_size)
			end

			if y ~= 0.0 and instance.has_scroll_y then
				local y_size = instance.h - get_y_scroll_size(instance)

				if instance.has_scroll_x then
					y_size = y_size - scroll_pad - scroll_bar_size
				end

				y_size = max(y_size, 0.0)

				local content_h = instance.content_h - instance.h

				instance.scroll_pos_y = (t_y / content_h) * y_size
				instance.scroll_pos_y = max(instance.scroll_pos_y, 0.0)
				instance.scroll_pos_y = min(instance.scroll_pos_y, y_size)
			end
		end
	end
end

function Region.transform(id, x, y)
	local instance = get_instance(id)
	if instance ~= nil then
		return instance.transform:transformPoint(x, y)
	end
	return x, y
end

function Region.inverse_transform(id, x, y)
	local instance = get_instance(id)
	if instance ~= nil then
		return instance.transform:inverseTransformPoint(x, y)
	end
	return x, y
end

function Region.reset_transform(id)
	local instance = get_instance(id)
	if instance ~= nil then
		instance.transform:reset()
		instance.scroll_pos_x = 0.0
		instance.scroll_pos_y = 0.0
	end
end

function Region.is_active(id)
	if active_instance ~= nil then
		return active_instance.id == id
	end
	return false
end

function Region.add_item(x, y, w, h)
	if active_instance ~= nil and active_instance.auto_size_content then
		local new_w = x + w - active_instance.x
		local new_h = y + h - active_instance.y
		active_instance.content_w = max(active_instance.content_w, new_w)
		active_instance.content_h = max(active_instance.content_h, new_h)
	end
end

function Region.apply_scissor()
	if active_instance ~= nil then
		if active_instance.intersect then
			DrawCommands.intersect_scissor(active_instance.s_x, active_instance.s_y, active_instance.w, active_instance.h)
		else
			DrawCommands.scissor(active_instance.s_x, active_instance.s_y, active_instance.w, active_instance.h)
		end
	end
end

function Region.get_bounds()
	if active_instance ~= nil then
		return active_instance.x, active_instance.y, active_instance.w, active_instance.h
	end
	return 0.0, 0.0, 0.0, 0.0
end

function Region.get_content_size()
	if active_instance ~= nil then
		return active_instance.content_w, active_instance.content_h
	end
	return 0.0, 0.0
end

function Region.contains(x, y)
	if active_instance ~= nil then
		return active_instance.x <= x and x <= active_instance.x + active_instance.w and active_instance.y <= y and
			y <= active_instance.y + active_instance.h
	end
	return false
end

function Region.reset_content_size(id)
	local instance = get_instance(id)
	if instance ~= nil then
		instance.content_w = 0.0
		instance.content_h = 0.0
	end
end

function Region.get_scroll_pad()
	return scroll_pad
end

function Region.get_scroll_bar_size()
	return scroll_bar_size
end

function Region.wheel_moved(x, y)
	wheel_x = x * wheel_speed
	wheel_y = y * wheel_speed
end

function Region.get_wheel_delta()
	return wheel_x, wheel_y
end

function Region.is_scrolling(id)
	if id ~= nil then
		local instance = get_instance(id)
		return scroll_instance == instance or wheel_instance == instance
	end

	return scroll_instance ~= nil or wheel_instance ~= nil
end

function Region.get_hot_instance_id()
	if hot_instance ~= nil then
		return hot_instance.id
	end

	return ""
end

function Region.clear_hot_instance(id)
	if hot_instance ~= nil then
		if id ~= nil then
			if hot_instance.id == id then
				hot_instance = nil
			end
		else
			hot_instance = nil
		end
	end
end

function Region.get_instance_ids()
	local result = {}

	for k, v in pairs(instances) do
		table.insert(result, k)
	end

	return result
end

function Region.get_debug_info(id)
	local result = {}
	local instance = nil

	for k, v in pairs(instances) do
		if k == id then
			instance = v
			break
		end
	end

	table.insert(result, "scroll_instance: " .. (scroll_instance ~= nil and scroll_instance.id or "nil"))
	table.insert(result, "wheel_instance: " .. (wheel_instance ~= nil and wheel_instance.id or "nil"))
	table.insert(result, "wheel_x: " .. wheel_x)
	table.insert(result, "wheel_y: " .. wheel_y)
	table.insert(result, "Wheel speed: " .. wheel_speed)

	if instance ~= nil then
		table.insert(result, "id: " .. instance.id)
		table.insert(result, "w: " .. instance.w)
		table.insert(result, "h: " .. instance.h)
		table.insert(result, "content_w: " .. instance.content_w)
		table.insert(result, "content_h: " .. instance.content_h)
		table.insert(result, "scroll_pos_x: " .. instance.scroll_pos_x)
		table.insert(result, "scroll_pos_y: " .. instance.scroll_pos_y)

		local t_x, t_y = instance.transform:transformPoint(0, 0)
		table.insert(result, "t_x: " .. t_x)
		table.insert(result, "t_y: " .. t_y)
		table.insert(result, "max_val t_x: " .. instance.content_w - instance.w)
		table.insert(result, "max_val t_y: " .. instance.content_h - instance.h)
	end

	return result
end

function Region.set_wheel_speed(speed)
	wheel_speed = speed == nil and 3.0 or speed
end

function Region.get_wheel_speed()
	return wheel_speed
end

return Region
