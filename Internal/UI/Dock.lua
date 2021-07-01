local DrawCommands = required("DrawCommands")
local MenuState = required("MenuState")
local Mouse = required("Mouse")
local Style = required("Style")
local Utility = required("Utility")

local Dock = {}

local instances = {}
local pending = nil
local pending_window = nil

local function is_valid(id)
	if id == nil then
		return false
	end

	if type(id) ~= "string" then
		return false
	end

	return id == "Left" or id == "Bottom" or id == "Right"
end

local function get_instance(id)
	if instances[id] == nil then
		local instance = {}
		instance.id = id
		instance.window = nil
		instance.reset = false
		instance.tear_x = 0
		instance.tear_y = 0
		instance.is_tearing = false
		instance.torn = false
		instance.cached_options = nil
		instance.enabled = true
		instance.no_saved_settings = false
		instances[id] = instance
	end
	return instances[id]
end

local function get_overlay_bounds(t)
	local x, y, w, h = 0, 0, 0, 0
	local view_w, view_h = WIDTH, HEIGHT
	local offset = 75

	if t == "Left" then
		w = 100
		h = 150
		x = offset
		y = view_h * 0.5 - h * 0.5
	elseif t == "Right" then
		w = 100
		h = 150
		x = view_w - offset - w
		y = view_h * 0.5 - h * 0.5
	elseif t == "Bottom" then
		w = view_w * 0.55
		h = 100
		x = view_w * 0.5 - w * 0.5
		y = view_h - offset - h
	end

	return x, y, w, h
end

local function draw_overlay(t)
	local instance = get_instance(t)
	if instance ~= nil and instance.window ~= nil then
		return
	end

	if not instance.enabled then
		return
	end

	local x, y, w, h = get_overlay_bounds(t)
	local colour = {0.29, 0.59, 0.83, 0.65}
	local title_h = 14
	local spacing = 6

	local mouse_x, mouse_y = Mouse.position()
	if x <= mouse_x and mouse_x <= x + w and y <= mouse_y and mouse_y <= y + h then
		colour = {0.50, 0.75, 0.96, 0.65}
		pending = t
	end

	DrawCommands.rectangle("fill", x, y, w, title_h, colour)
	DrawCommands.rectangle("line", x, y, w, title_h, {0, 0, 0, 1})

	y = y + title_h + spacing
	h = h - title_h - spacing
	DrawCommands.rectangle("fill", x, y, w, h, colour)
	DrawCommands.rectangle("line", x, y, w, h, {0, 0, 0, 1})
end

function Dock.draw_overlay()
	pending = nil

	DrawCommands.set_layer("Dock")
	DrawCommands.begin()

	draw_overlay("Left")
	draw_overlay("Right")
	draw_overlay("Bottom")

	DrawCommands.finish()

	if Mouse.is_released(1) then
		for id, instance in pairs(instances) do
			instance.is_tearing = false
		end
	end
end

function Dock.Commit()
	if pending ~= nil and pending_window ~= nil and Mouse.is_released(1) then
		local instance = get_instance(pending)

		if pending_window ~= nil then
			instance.window = pending_window.id
			pending_window = nil
			instance.reset = true
		end

		pending = nil
	end
end

function Dock.GetDock(win_id)
	for k, v in pairs(instances) do
		if v.window == win_id then
			return k
		end
	end

	return nil
end

function Dock.get_bounds(t)
	local x, y, w, h = 0, 0, 0, 0
	local view_w, view_h = WIDTH, HEIGHT
	local main_menu_bar_h = MenuState.main_menu_bar_h
	local title_h = Style.Font:getHeight()

	if t == "Left" then
		y = main_menu_bar_h
		w = 150
		h = view_h - y - title_h
	elseif t == "Right" then
		x = view_w - 150
		y = main_menu_bar_h
		w = 150
		h = view_h - y - title_h
	elseif t == "Bottom" then
		y = view_h - 150
		w = view_w
		h = 150
	end

	return x, y, w, h
end

function Dock.alter_options(win_id, options)
	options = options == nil and {} or options

	for id, instance in pairs(instances) do
		if instance.window == win_id then
			if instance.torn or not instance.enabled then
				instance.window = nil
				Utility.copy_values(options, instance.cached_options)
				instance.cached_options = nil
				instance.torn = false
				options.reset_size = true
			else
				if instance.reset then
					instance.cached_options = {
						x = options.x,
						y = options.y,
						w = options.w,
						h = options.h,
						allow_move = options.allow_move,
						layer = options.layer,
						sizer_filter = Utility.copy(options.sizer_filter),
						auto_size_window = options.auto_size_window,
						auto_size_window_w = options.auto_size_window_w,
						auto_size_window_h = options.auto_size_window_h,
						allow_resize = options.allow_resize
					}
				end

				options.allow_move = false
				options.layer = "Dock"
				if id == "Left" then
					options.sizer_filter = {"E"}
				elseif id == "Right" then
					options.sizer_filter = {"w"}
				elseif id == "Bottom" then
					options.sizer_filter = {"N"}
				end

				local x, y, w, h = Dock.get_bounds(id)
				options.x = x
				options.y = y
				options.w = w
				options.h = h
				options.auto_size_window = false
				options.auto_size_window_w = false
				options.auto_size_window_h = false
				options.allow_resize = true
				options.reset_position = instance.reset
				options.reset_size = instance.reset
				instance.reset = false
			end

			break
		end
	end
end

function Dock.set_pending_window(instance)
	pending_window = instance
end

function Dock.get_pending_window()
	return pending_window
end

function Dock.is_tethered(win_id)
	for id, instance in pairs(instances) do
		if instance.window == win_id then
			return not instance.torn
		end
	end

	return false
end

function Dock.begin_tear(win_id, x, y)
	for id, instance in pairs(instances) do
		if instance.window == win_id then
			instance.tear_x = x
			instance.tear_y = y
			instance.is_tearing = true
		end
	end
end

function Dock.update_tear(win_id, x, y)
	for id, instance in pairs(instances) do
		if instance.window == win_id and instance.is_tearing then
			local threshold = 25.0
			local distance_x = instance.tear_x - x
			local distance_y = instance.tear_y - y
			local distance_sq = distance_x * distance_x + distance_y * distance_y

			if distance_sq >= threshold * threshold then
				instance.is_tearing = false
				instance.torn = true
			end
		end
	end
end

function Dock.get_cached_options(win_id)
	for id, instance in pairs(instances) do
		if instance.window == win_id then
			return instance.cached_options
		end
	end

	return nil
end

function Dock.toggle(list, enabled)
	list = list == nil and {} or list
	enabled = enabled == nil and true or enabled

	if type(list) == "string" then
		list = {list}
	end

	for i, v in ipairs(list) do
		if is_valid(v) then
			local instance = get_instance(v)
			instance.enabled = enabled
		end
	end
end

function Dock.set_options(t, options)
	options = options == nil and {} or options
	options.no_saved_settings = options.no_saved_settings == nil and false or options.no_saved_settings

	if is_valid(t) then
		local instance = get_instance(t)
		instance.no_saved_settings = options.no_saved_settings
	end
end

function Dock.save(tbl)
	if tbl ~= nil then
		local settings = {}
		for k, v in pairs(instances) do
			if not v.no_saved_settings then
				settings[k] = tostring(v.window)
			end
		end
		tbl["Dock"] = settings
	end
end

function Dock.load(tbl)
	if tbl ~= nil then
		local settings = tbl["Dock"]
		if settings ~= nil then
			for k, v in pairs(settings) do
				local instance = get_instance(k)
				instance.window = v
			end
		end
	end
end

return Dock
