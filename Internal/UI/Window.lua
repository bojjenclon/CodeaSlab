local insert = table.insert
local remove = table.remove
local max = math.max
local floor = math.floor

local Cursor = required("Cursor")
local Dock = required("Dock")
local DrawCommands = required("DrawCommands")
local MenuState = required("MenuState")
local Mouse = required("Mouse")
local Region = required("Region")
local Stats = required("Stats")
local Style = required("Style")
local Utility = required("Utility")

local Window = {}

local instances = {}
local stack = {}
local stack_lock_id = nil
local pending_stack = {}
local active_instance = nil
local moving_instance = nil

local SizerType = {
	None = 0,
	N = 1,
	E = 2,
	s = 3,
	w = 4,
	NE = 5,
	SE = 6,
	SW = 7,
	NW = 8
}

local function update_stack_index()
	for i = 1, #stack, 1 do
		stack[i].stack_index = #stack - i + 1
	end
end

local function push_to_top(instance)
	for i, v in ipairs(stack) do
		if instance == v then
			remove(stack, i)
			break
		end
	end

	insert(stack, 1, instance)

	update_stack_index()
end

local function new_instance(id)
	local instance = {}
	instance.id = id
	instance.x = 0.0
	instance.y = 0.0
	instance.w = 200.0
	instance.h = 200.0
	instance.content_w = 0.0
	instance.content_h = 0.0
	instance.title = ""
	instance.is_moving = false
	instance.title_delta_x = 0.0
	instance.title_delta_y = 0.0
	instance.allow_resize = true
	instance.allow_focus = true
	instance.sizer_type = SizerType.None
	instance.sizer_filter = nil
	instance.size_delta_x = 0.0
	instance.size_delta_y = 0.0
	instance.has_resized = false
	instance.delta_content_w = 0.0
	instance.delta_content_h = 0.0
	instance.background_color = Style.WindowBackgroundColor
	instance.border = 4.0
	instance.children = {}
	instance.last_item = nil
	instance.hot_item = nil
	instance.context_hot_item = nil
	instance.items = {}
	instance.layer = "Normal"
	instance.stack_index = 0
	instance.can_obstruct = true
	instance.frame_number = 0
	instance.last_cursor_x = 0
	instance.last_cursor_y = 0
	instance.stat_handle = nil
	instance.is_appearing = false
	instance.is_open = true
	instance.no_saved_settings = false
	return instance
end

local function get_instance(id)
	if id == nil then
		return active_instance
	end

	for k, v in pairs(instances) do
		if v.id == id then
			return v
		end
	end
	local instance = new_instance(id)
	insert(instances, instance)
	return instance
end

local function contains(instance, x, y)
	if instance ~= nil then
		local offset_y = 0.0
		if instance.title ~= "" then
			offset_y = Style.Font:getHeight()
		end
		return instance.x <= x and x <= instance.x + instance.w and instance.y - offset_y <= y and
			y <= instance.y + instance.h
	end
	return false
end

local function update_title_bar(instance, is_obstructed, allow_move)
	if is_obstructed then
		return
	end

	if instance ~= nil and instance.title ~= "" and instance.sizer_type == SizerType.None then
		local w = instance.w
		local h = Style.Font:getHeight()
		local x = instance.x
		local y = instance.y - h
		local is_tethered = Dock.is_tethered(instance.id)

		local mouse_x, mouse_y = Mouse.position()

		if Mouse.is_clicked(1) then
			if x <= mouse_x and mouse_x <= x + w and y <= mouse_y and mouse_y <= y + h then
				if allow_move then
					instance.is_moving = true
				end

				if is_tethered then
					Dock.begin_tear(instance.id, mouse_x, mouse_y)
				end

				if instance.allow_focus then
					push_to_top(instance)
				end
			end
		elseif Mouse.is_released(1) then
			instance.is_moving = false
		end

		if instance.is_moving then
			local delta_x, delta_y = Mouse.get_delta()
			instance.title_delta_x = instance.title_delta_x + delta_x
			instance.title_delta_y = instance.title_delta_y + delta_y
		elseif is_tethered then
			Dock.update_tear(instance.id, mouse_x, mouse_y)

			-- Retrieve the cached options to calculate torn off position. The cached options contain the
			-- desired bounds for this window. The bounds that are a part of the instance are the altered options
			-- modified by the Dock module.
			local options = Dock.get_cached_options(instance.id)
			if not Dock.is_tethered(instance.id) then
				instance.is_moving = true

				if options ~= nil then
					-- Properly place the window at the mouse position offset by the title width/height.
					instance.title_delta_x = mouse_x - options.x - floor(options.w * 0.25)
					instance.title_delta_y = mouse_y - options.y - floor(h * 0.5)
				end
			end
		end
	end
end

local function is_sizer_enabled(instance, sizer)
	if instance ~= nil then
		if #instance.sizer_filter > 0 then
			for i, v in ipairs(instance.sizer_filter) do
				if v == sizer then
					return true
				end
			end
			return false
		end
		return true
	end
	return false
end

local function update_size(instance, is_obstructed)
	if instance ~= nil and instance.allow_resize then
		if Region.is_hover_scroll_bar(instance.id) then
			return
		end

		if instance.sizer_type == SizerType.None and is_obstructed then
			return
		end

		if moving_instance ~= nil then
			return
		end

		local x = instance.x
		local y = instance.y
		local w = instance.w
		local h = instance.h

		if instance.title ~= "" then
			local offset = Style.Font:getHeight()
			y = y - offset
			h = h + offset
		end

		local mouse_x, mouse_y = Mouse.position()
		local new_sizer_type = SizerType.None
		local scroll_pad = Region.get_scroll_pad()

		if x <= mouse_x and mouse_x <= x + w and y <= mouse_y and mouse_y <= y + h then
			if
				x <= mouse_x and mouse_x <= x + scroll_pad and y <= mouse_y and mouse_y <= y + scroll_pad and
					is_sizer_enabled(instance, "NW")
			 then
				Mouse.set_cursor("sizenwse")
				new_sizer_type = SizerType.NW
			elseif
				x + w - scroll_pad <= mouse_x and mouse_x <= x + w and y <= mouse_y and mouse_y <= y + scroll_pad and
					is_sizer_enabled(instance, "NE")
			 then
				Mouse.set_cursor("sizenesw")
				new_sizer_type = SizerType.NE
			elseif
				x + w - scroll_pad <= mouse_x and mouse_x <= x + w and y + h - scroll_pad <= mouse_y and mouse_y <= y + h and
					is_sizer_enabled(instance, "SE")
			 then
				Mouse.set_cursor("sizenwse")
				new_sizer_type = SizerType.SE
			elseif
				x <= mouse_x and mouse_x <= x + scroll_pad and y + h - scroll_pad <= mouse_y and mouse_y <= y + h and
					is_sizer_enabled(instance, "s_w")
			 then
				Mouse.set_cursor("sizenesw")
				new_sizer_type = SizerType.SW
			elseif x <= mouse_x and mouse_x <= x + scroll_pad and is_sizer_enabled(instance, "w") then
				Mouse.set_cursor("sizewe")
				new_sizer_type = SizerType.w
			elseif x + w - scroll_pad <= mouse_x and mouse_x <= x + w and is_sizer_enabled(instance, "E") then
				Mouse.set_cursor("sizewe")
				new_sizer_type = SizerType.E
			elseif y <= mouse_y and mouse_y <= y + scroll_pad and is_sizer_enabled(instance, "N") then
				Mouse.set_cursor("sizens")
				new_sizer_type = SizerType.N
			elseif y + h - scroll_pad <= mouse_y and mouse_y <= y + h and is_sizer_enabled(instance, "s") then
				Mouse.set_cursor("sizens")
				new_sizer_type = SizerType.s
			end
		end

		if Mouse.is_clicked(1) then
			instance.sizer_type = new_sizer_type
		elseif Mouse.is_released(1) then
			instance.sizer_type = SizerType.None
		end

		if instance.sizer_type ~= SizerType.None then
			local delta_x, delta_y = Mouse.get_delta()

			if instance.w <= instance.border then
				if
					(instance.sizer_type == SizerType.w or instance.sizer_type == SizerType.NW or instance.sizer_type == SizerType.SW) and
						delta_x > 0.0
				 then
					delta_x = 0.0
				end

				if
					(instance.sizer_type == SizerType.E or instance.sizer_type == SizerType.NE or instance.sizer_type == SizerType.SE) and
						delta_x < 0.0
				 then
					delta_x = 0.0
				end
			end

			if instance.h <= instance.border then
				if
					(instance.sizer_type == SizerType.N or instance.sizer_type == SizerType.NW or instance.sizer_type == SizerType.NE) and
						delta_y > 0.0
				 then
					delta_y = 0.0
				end

				if
					(instance.sizer_type == SizerType.s or instance.sizer_type == SizerType.SE or instance.sizer_type == SizerType.SW) and
						delta_y < 0.0
				 then
					delta_y = 0.0
				end
			end

			if delta_x ~= 0.0 or delta_y ~= 0.0 then
				instance.has_resized = true
				instance.delta_content_w = 0.0
				instance.delta_content_h = 0.0
			end

			if instance.sizer_type == SizerType.N then
				Mouse.set_cursor("sizens")
				instance.title_delta_y = instance.title_delta_y + delta_y
				instance.size_delta_y = instance.size_delta_y - delta_y
			elseif instance.sizer_type == SizerType.E then
				Mouse.set_cursor("sizewe")
				instance.size_delta_x = instance.size_delta_x + delta_x
			elseif instance.sizer_type == SizerType.s then
				Mouse.set_cursor("sizens")
				instance.size_delta_y = instance.size_delta_y + delta_y
			elseif instance.sizer_type == SizerType.w then
				Mouse.set_cursor("sizewe")
				instance.title_delta_x = instance.title_delta_x + delta_x
				instance.size_delta_x = instance.size_delta_x - delta_x
			elseif instance.sizer_type == SizerType.NW then
				Mouse.set_cursor("sizenwse")
				instance.title_delta_x = instance.title_delta_x + delta_x
				instance.size_delta_x = instance.size_delta_x - delta_x
				instance.title_delta_y = instance.title_delta_y + delta_y
				instance.size_delta_y = instance.size_delta_y - delta_y
			elseif instance.sizer_type == SizerType.NE then
				Mouse.set_cursor("sizenesw")
				instance.size_delta_x = instance.size_delta_x + delta_x
				instance.title_delta_y = instance.title_delta_y + delta_y
				instance.size_delta_y = instance.size_delta_y - delta_y
			elseif instance.sizer_type == SizerType.SE then
				Mouse.set_cursor("sizenwse")
				instance.size_delta_x = instance.size_delta_x + delta_x
				instance.size_delta_y = instance.size_delta_y + delta_y
			elseif instance.sizer_type == SizerType.SW then
				Mouse.set_cursor("sizenesw")
				instance.title_delta_x = instance.title_delta_x + delta_x
				instance.size_delta_x = instance.size_delta_x - delta_x
				instance.size_delta_y = instance.size_delta_y + delta_y
			end
		end
	end
end

function Window.top()
	return active_instance
end

function Window.is_obstructed(x, y, skip_scroll_check)
	if Region.is_scrolling() then
		return true
	end

	-- If there are no windows, then nothing can obstruct.
	if #stack == 0 then
		return false
	end

	if active_instance ~= nil then
		if not active_instance.is_open then
			return true
		end

		if active_instance.is_moving then
			return false
		end

		if active_instance.is_appearing then
			return true
		end

		-- Gather all potential windows that can obstruct the given position.
		local list = {}
		for i, v in ipairs(stack) do
			-- stack locks prevents other windows to be considered.
			if v.id == stack_lock_id then
				insert(list, v)
				break
			end

			if contains(v, x, y) and v.can_obstruct then
				insert(list, v)
			end
		end

		-- Certain layers are rendered on top of 'Normal' windows. Consider these windows first.
		local top = nil
		for i, v in ipairs(list) do
			if v.layer ~= "Normal" then
				top = v
				break
			end
		end

		-- If all windows are considered the normal layer, then just grab the window at the top of the stack.
		if top == nil then
			top = list[1]
		end

		if top ~= nil then
			if active_instance == top then
				if not skip_scroll_check and Region.is_hover_scroll_bar(active_instance.id) then
					return true
				end

				return false
			elseif top.is_open then
				return true
			end
		end
	end

	return false
end

function Window.is_obstructed_at_mouse()
	local x, y = Mouse.position()
	return Window.is_obstructed(x, y)
end

function Window.reset()
	pending_stack = {}
	active_instance = get_instance("Global")
	active_instance.w = WIDTH
	active_instance.h = HEIGHT
	active_instance.border = 0.0
	active_instance.no_saved_settings = true
	insert(pending_stack, 1, active_instance)
end

function Window.begin(id, options)
	local stat_handle = Stats.begin("Window", "Slab")

	options = options == nil and {} or options
	options.x = options.x == nil and 50.0 or options.x
	options.y = options.y == nil and 50.0 or options.y
	options.w = options.w == nil and 200.0 or options.w
	options.h = options.h == nil and 200.0 or options.h
	options.content_w = options.content_w == nil and 0.0 or options.content_w
	options.content_h = options.content_h == nil and 0.0 or options.content_h
	options.bg_color = options.bg_color == nil and Style.WindowBackgroundColor or options.bg_color
	options.title = options.title == nil and "" or options.title
	options.allow_move = options.allow_move == nil and true or options.allow_move
	options.allow_resize = options.allow_resize == nil and true or options.allow_resize
	options.allow_focus = options.allow_focus == nil and true or options.allow_focus
	options.border = options.border == nil and 4.0 or options.border
	options.no_outline = options.no_outline == nil and false or options.no_outline
	options.is_menu_bar = options.is_menu_bar == nil and false or options.is_menu_bar
	options.auto_size_window = options.auto_size_window == nil and true or options.auto_size_window
	options.auto_size_window_w =
		options.auto_size_window_w == nil and options.auto_size_window or options.auto_size_window_w
	options.auto_size_window_h =
		options.auto_size_window_h == nil and options.auto_size_window or options.auto_size_window_h
	options.auto_size_content = options.auto_size_content == nil and true or options.auto_size_content
	options.layer = options.layer == nil and "Normal" or options.layer
	options.reset_position = options.reset_position == nil and false or options.reset_position
	options.reset_size = options.reset_size == nil and options.auto_size_window or options.reset_size
	options.reset_content = options.reset_content == nil and options.auto_size_content or options.reset_content
	options.ResetLayout = options.ResetLayout == nil and false or options.ResetLayout
	options.sizer_filter = options.sizer_filter == nil and {} or options.sizer_filter
	options.can_obstruct = options.can_obstruct == nil and true or options.can_obstruct
	options.rounding = options.rounding == nil and Style.WindowRounding or options.rounding
	options.no_saved_settings = options.no_saved_settings == nil and false or options.no_saved_settings

	Dock.alter_options(id, options)

	local title_rounding = {options.rounding, options.rounding, 0, 0}
	local body_rounding = {0, 0, options.rounding, options.rounding}

	if type(options.rounding) == "table" then
		title_rounding = options.rounding
		body_rounding = options.rounding
	elseif options.title == "" then
		body_rounding = options.rounding
	end

	local instance = get_instance(id)
	insert(pending_stack, 1, instance)

	if active_instance ~= nil then
		active_instance.children[id] = instance
	end

	active_instance = instance
	if options.auto_size_window_w then
		options.w = 0.0
	end

	if options.auto_size_window_h then
		options.h = 0.0
	end

	if options.reset_position or options.ResetLayout then
		active_instance.title_delta_x = 0.0
		active_instance.title_delta_y = 0.0
	end

	if active_instance.auto_size_window ~= options.auto_size_window and options.auto_size_window then
		options.reset_size = true
	end

	if active_instance.border ~= options.border then
		options.reset_size = true
	end

	active_instance.x = active_instance.title_delta_x + options.x
	active_instance.y = active_instance.title_delta_y + options.y
	active_instance.w = max(active_instance.size_delta_x + options.w + options.border, options.border)
	active_instance.h = max(active_instance.size_delta_y + options.h + options.border, options.border)
	active_instance.content_w = options.content_w
	active_instance.content_h = options.content_h
	active_instance.background_color = options.bg_color
	active_instance.title = options.title
	active_instance.allow_resize = options.allow_resize and not options.auto_size_window
	active_instance.allow_focus = options.allow_focus
	active_instance.border = options.border
	active_instance.is_menu_bar = options.is_menu_bar
	active_instance.auto_size_window = options.auto_size_window
	active_instance.auto_size_window_w = options.auto_size_window_w
	active_instance.auto_size_window_h = options.auto_size_window_h
	active_instance.auto_size_content = options.auto_size_content
	active_instance.layer = options.layer
	active_instance.hot_item = nil
	active_instance.sizer_filter = options.sizer_filter
	active_instance.has_resized = false
	active_instance.can_obstruct = options.can_obstruct
	active_instance.stat_handle = stat_handle
	active_instance.no_saved_settings = options.no_saved_settings

	local show_close = false
	if options.is_open ~= nil and type(options.is_open) == "boolean" then
		active_instance.is_open = options.is_open
		show_close = true
	end

	if active_instance.is_open then
		local current_frame_number = Stats.get_frame_number()
		active_instance.is_appearing = current_frame_number - active_instance.frame_number > 1
		active_instance.frame_number = current_frame_number

		if active_instance.stack_index == 0 then
			insert(stack, 1, active_instance)
			update_stack_index()
		end
	end

	if active_instance.auto_size_content then
		active_instance.content_w = max(options.content_w, active_instance.delta_content_w)
		active_instance.content_h = max(options.content_h, active_instance.delta_content_h)
	end

	local offset_y = 0.0
	if active_instance.title ~= "" then
		offset_y = Style.Font:getHeight()
		active_instance.y = active_instance.y + offset_y

		if options.auto_size_window then
			local title_w = Style.Font:getWidth(active_instance.title) + active_instance.border * 2.0
			active_instance.w = max(active_instance.w, title_w)
		end
	end

	local mouse_x, mouse_y = Mouse.position()
	local is_obstructed = Window.is_obstructed(mouse_x, mouse_y, true)
	if
		(active_instance.allow_focus and Mouse.is_clicked(1) and not is_obstructed and
			contains(active_instance, mouse_x, mouse_y)) or
			active_instance.is_appearing
	 then
		push_to_top(active_instance)
	end

	instance.last_cursor_x, instance.last_cursor_y = Cursor.get_position()
	Cursor.set_position(active_instance.x + active_instance.border, active_instance.y + active_instance.border)
	Cursor.set_anchor(active_instance.x + active_instance.border, active_instance.y + active_instance.border)

	update_size(active_instance, is_obstructed)
	update_title_bar(active_instance, is_obstructed, options.allow_move)

	DrawCommands.set_layer(active_instance.layer)

	DrawCommands.begin({channel = active_instance.stack_index})
	if active_instance.title ~= "" then
		local TitleX =
			floor(active_instance.x + (active_instance.w * 0.5) - (Style.Font:getWidth(active_instance.title) * 0.5))
		local title_color = active_instance.background_color
		if active_instance == stack[1] then
			title_color = Style.WindowTitleFocusedColor
		end
		DrawCommands.rectangle(
			"fill",
			active_instance.x,
			active_instance.y - offset_y,
			active_instance.w,
			offset_y,
			title_color,
			title_rounding
		)
		DrawCommands.rectangle(
			"line",
			active_instance.x,
			active_instance.y - offset_y,
			active_instance.w,
			offset_y,
			nil,
			title_rounding
		)
		DrawCommands.line(active_instance.x, active_instance.y, active_instance.x + active_instance.w, active_instance.y, 1.0)

		Region.begin(
			active_instance.id .. "_Title",
			{
				x = active_instance.x,
				y = active_instance.y - offset_y,
				w = active_instance.w,
				h = offset_y,
				no_background = true,
				no_outline = true,
				ignore_scroll = true,
				mouse_x = mouse_x,
				mouse_y = mouse_y,
				is_obstructed = is_obstructed
			}
		)
		DrawCommands.print(active_instance.title, TitleX, floor(active_instance.y - offset_y), Style.text_color, Style.Font)

		if show_close then
			local close_bg_radius = offset_y * 0.4
			local close_size = close_bg_radius * 0.5
			local close_x = active_instance.x + active_instance.w - active_instance.border - close_bg_radius
			local close_y = active_instance.y - offset_y * 0.5
			local is_close_hovered =
				close_x - close_bg_radius <= mouse_x and mouse_x <= close_x + close_bg_radius and
				close_y - offset_y * 0.5 <= mouse_y and
				mouse_y <= close_y + close_bg_radius and
				not is_obstructed

			if is_close_hovered then
				DrawCommands.circle("fill", close_x, close_y, close_bg_radius, Style.WindowCloseBgColor)

				if Mouse.is_clicked(1) then
					active_instance.is_open = false
					active_instance.is_moving = false
					options.is_open = false
				end
			end

			DrawCommands.cross(close_x, close_y, close_size, Style.WindowCloseColor)
		end

		Region.finish()
	end

	local region_w = active_instance.w
	local region_h = active_instance.h

	if active_instance.x + active_instance.w > WIDTH then
		region_w = WIDTH - active_instance.x
	end
	if active_instance.y + active_instance.h > HEIGHT then
		region_h = HEIGHT - active_instance.y
	end

	Region.begin(
		active_instance.id,
		{
			x = active_instance.x,
			y = active_instance.y,
			w = region_w,
			h = region_h,
			content_w = active_instance.content_w + active_instance.border,
			content_h = active_instance.content_h + active_instance.border,
			bg_color = active_instance.background_color,
			is_obstructed = is_obstructed,
			mouse_x = mouse_x,
			mouse_y = mouse_y,
			reset_content = active_instance.has_resized,
			rounding = body_rounding,
			no_outline = options.no_outline
		}
	)

	if options.reset_size then
		active_instance.size_delta_x = 0.0
		active_instance.size_delta_y = 0.0
	end

	if options.reset_content or options.ResetLayout then
		active_instance.delta_content_w = 0.0
		active_instance.delta_content_h = 0.0
	end

	return active_instance.is_open
end

function Window.finish()
	if active_instance ~= nil then
		local handle = active_instance.stat_handle
		Region.finish()
		DrawCommands.finish(not active_instance.is_open)
		remove(pending_stack, 1)

		Cursor.set_position(active_instance.last_cursor_x, active_instance.last_cursor_y)
		active_instance = nil
		if #pending_stack > 0 then
			active_instance = pending_stack[1]
			Cursor.set_anchor(active_instance.x + active_instance.border, active_instance.y + active_instance.border)
			DrawCommands.set_layer(active_instance.layer)
			Region.apply_scissor()
		end

		Stats.finish(handle)
	end
end

function Window.get_mouse_position()
	local x, y = Mouse.position()
	if active_instance ~= nil then
		x, y = Region.inverse_transform(active_instance.id, x, y)
	end
	return x, y
end

function Window.get_width()
	if active_instance ~= nil then
		return active_instance.w
	end
	return 0.0
end

function Window.get_height()
	if active_instance ~= nil then
		return active_instance.h
	end
	return 0.0
end

function Window.get_border()
	if active_instance ~= nil then
		return active_instance.border
	end
	return 0.0
end

function Window.get_bounds(ignore_title_bar)
	if active_instance ~= nil then
		ignore_title_bar = ignore_title_bar == nil and false or ignore_title_bar
		local offset_y = (active_instance.title ~= "" and not ignore_title_bar) and Style.Font:getHeight() or 0.0
		return active_instance.x, active_instance.y - offset_y, active_instance.w, active_instance.h + offset_y
	end
	return 0.0, 0.0, 0.0, 0.0
end

function Window.get_position()
	if active_instance ~= nil then
		local x, y = active_instance.x, active_instance.y
		if active_instance.title ~= "" then
			y = y - Style.Font:getHeight()
		end
		return x, y
	end
	return 0.0, 0.0
end

function Window.get_size()
	if active_instance ~= nil then
		return active_instance.w, active_instance.h
	end
	return 0.0, 0.0
end

function Window.get_content_size()
	if active_instance ~= nil then
		return active_instance.content_w, active_instance.content_h
	end
	return 0.0, 0.0
end

--[[
	This function is used to help other controls retrieve the available real estate needed to expand their
	bounds without expanding the bounds of the window by removing borders.
--]]
function Window.get_borderless_size()
	local w, h = 0.0, 0.0

	if active_instance ~= nil then
		w = max(active_instance.w, active_instance.content_w)
		h = max(active_instance.h, active_instance.content_h)

		w = max(0.0, w - active_instance.border * 2.0)
		h = max(0.0, h - active_instance.border * 2.0)
	end

	return w, h
end

function Window.get_remaining_size()
	local w, h = Window.get_borderless_size()

	if active_instance ~= nil then
		w = w - (Cursor.get_x() - active_instance.x - active_instance.border)
		h = h - (Cursor.get_y() - active_instance.y - active_instance.border)
	end

	return w, h
end

function Window.is_menu_bar()
	if active_instance ~= nil then
		return active_instance.is_menu_bar
	end
	return false
end

function Window.get_id()
	if active_instance ~= nil then
		return active_instance.id
	end
	return ""
end

function Window.add_item(x, y, w, h, id)
	if active_instance ~= nil then
		active_instance.last_item = id
		if Region.is_active(active_instance.id) then
			if active_instance.auto_size_window_w then
				active_instance.size_delta_x = max(active_instance.size_delta_x, x + w - active_instance.x)
			end

			if active_instance.auto_size_window_h then
				active_instance.size_delta_y = max(active_instance.size_delta_y, y + h - active_instance.y)
			end

			if active_instance.auto_size_content then
				active_instance.delta_content_w = max(active_instance.delta_content_w, x + w - active_instance.x)
				active_instance.delta_content_h = max(active_instance.delta_content_h, y + h - active_instance.y)
			end
		else
			Region.add_item(x, y, w, h)
		end
	end
end

function Window.wheel_moved(x, y)
	Region.wheel_moved(x, y)
end

function Window.transform_point(x, y)
	if active_instance ~= nil then
		return Region.transform(active_instance.id, x, y)
	end
	return 0.0, 0.0
end

function Window.reset_content_size()
	if active_instance ~= nil then
		active_instance.delta_content_w = 0.0
		active_instance.delta_content_h = 0.0
	end
end

function Window.set_hot_item(hot_item)
	if active_instance ~= nil then
		active_instance.hot_item = hot_item
	end
end

function Window.set_context_hot_item(hot_item)
	if active_instance ~= nil then
		active_instance.context_hot_item = hot_item
	end
end

function Window.get_hot_item()
	if active_instance ~= nil then
		return active_instance.hot_item
	end
	return nil
end

function Window.IsItemHot()
	if active_instance ~= nil and active_instance.last_item ~= nil then
		return active_instance.hot_item == active_instance.last_item
	end
	return false
end

function Window.get_context_hot_item()
	if active_instance ~= nil then
		return active_instance.context_hot_item
	end
	return nil
end

function Window.is_mouse_hovered()
	if active_instance ~= nil then
		local x, y = Mouse.position()
		return contains(active_instance, x, y)
	end
	return false
end

function Window.get_item_id(id)
	if active_instance ~= nil then
		if active_instance.items[id] == nil then
			active_instance.items[id] = active_instance.id .. "." .. id
		end
		return active_instance.items[id]
	end
	return nil
end

function Window.get_last_item()
	if active_instance ~= nil then
		return active_instance.last_item
	end
	return nil
end

function Window.validate()
	if #pending_stack > 1 then
		assert(false, "end_window was not called for: " .. pending_stack[1].id)
	end

	moving_instance = nil
	local should_update = false
	for i = #stack, 1, -1 do
		if stack[i].is_moving then
			moving_instance = stack[i]
		end

		if stack[i].frame_number ~= Stats.get_frame_number() then
			stack[i].stack_index = 0
			Region.clear_hot_instance(stack[i].id)
			Region.clear_hot_instance(stack[i].id .. "_Title")
			remove(stack, i)
			should_update = true
		end
	end

	if should_update then
		update_stack_index()
	end
end

function Window.has_resized()
	if active_instance ~= nil then
		return active_instance.has_resized
	end
	return false
end

function Window.set_stack_lock(id)
	stack_lock_id = id
end

function Window.push_to_top(id)
	local instance = get_instance(id)

	if instance ~= nil then
		push_to_top(instance)
	end
end

function Window.is_appearing()
	if active_instance ~= nil then
		return active_instance.is_appearing
	end

	return false
end

function Window.get_layer()
	if active_instance ~= nil then
		return active_instance.layer
	end
	return "Normal"
end

function Window.get_instance_ids()
	local result = {}

	for i, v in ipairs(instances) do
		insert(result, v.id)
	end

	return result
end

function Window.get_instance_info(id)
	local result = {}

	local instance = nil
	for i, v in ipairs(instances) do
		if v.id == id then
			instance = v
			break
		end
	end

	insert(result, "moving_instance: " .. (moving_instance ~= nil and moving_instance.id or "nil"))

	if instance ~= nil then
		insert(result, "title: " .. instance.title)
		insert(result, "x: " .. instance.x)
		insert(result, "y: " .. instance.y)
		insert(result, "w: " .. instance.w)
		insert(result, "h: " .. instance.h)
		insert(result, "content_w: " .. instance.content_w)
		insert(result, "content_h: " .. instance.content_h)
		insert(result, "size_delta_x: " .. instance.size_delta_x)
		insert(result, "size_delta_y: " .. instance.size_delta_y)
		insert(result, "delta_content_w: " .. instance.delta_content_w)
		insert(result, "delta_content_h: " .. instance.delta_content_h)
		insert(result, "border: " .. instance.border)
		insert(result, "layer: " .. instance.layer)
		insert(result, "stack index: " .. instance.stack_index)
		insert(result, "auto_size_window: " .. tostring(instance.auto_size_window))
		insert(result, "auto_size_content: " .. tostring(instance.auto_size_content))
	end

	return result
end

function Window.get_stack_debug()
	local result = {}

	for i, v in ipairs(stack) do
		result[i] = tostring(v.stack_index) .. ": " .. v.id

		if v.id == stack_lock_id then
			result[i] = result[i] .. " (Locked)"
		end
	end

	return result
end

function Window.is_auto_size()
	if active_instance ~= nil then
		return active_instance.auto_size_window_w or active_instance.auto_size_window_h
	end

	return false
end

function Window.save(tbl)
	if tbl ~= nil then
		local settings = {}
		for i, v in ipairs(instances) do
			if not v.no_saved_settings then
				settings[v.id] = {
					x = v.title_delta_x,
					y = v.title_delta_y,
					w = v.size_delta_x,
					h = v.size_delta_y
				}
			end
		end
		tbl["Window"] = settings
	end
end

function Window.load(tbl)
	if tbl ~= nil then
		local settings = tbl["Window"]
		if settings ~= nil then
			for k, v in pairs(settings) do
				local instance = get_instance(k)
				instance.title_delta_x = v.x
				instance.title_delta_y = v.y
				instance.size_delta_x = v.w
				instance.size_delta_y = v.h
			end
		end
	end
end

function Window.get_moving_instance()
	return moving_instance
end

return Window
