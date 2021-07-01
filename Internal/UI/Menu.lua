local insert = table.insert
local remove = table.remove
local max = math.max

local Cursor = required("Cursor")
local DrawCommands = required("DrawCommands")
local MenuState = required("MenuState")
local Mouse = required("Mouse")
local Style = required("Style")
local text = required("text")
local Window = required("Window")

local Menu = {}

local instances = {}

local pad = 8.0
local left_pad = 25.0
local right_pad = 70.0
local check_size = 5.0
local opened_context_menu = nil

local function is_item_hovered()
	local item_x, item_y, item_w, item_h = Cursor.get_item_bounds()
	local mouse_x, mouse_y = Window.get_mouse_position()
	return not Window.is_obstructed_at_mouse() and item_x < mouse_x and mouse_x < item_x + Window.get_width() and
		item_y < mouse_y and
		mouse_y < item_y + item_h
end

local function alter_options(options)
	options = options == nil and {} or options
	options.enabled = options.enabled == nil and true or options.enabled
	options.is_selectable = options.enabled
	options.select_on_hover = options.enabled

	if options.enabled then
		options.colour = Style.text_color
	else
		options.colour = Style.TextDisabledColor
	end

	return options
end

local function constrain_position(x, y, w, h)
	local result_x, result_y = x, y

	local right = x + w
	local bottom = y + h
	local offset_x = right >= WIDTH
	local offset_y = bottom >= HEIGHT

	if offset_x then
		result_x = x - (right - WIDTH)
	end

	if offset_y then
		result_y = y - h
	end

	local win_x, win_y, win_w, win_h = Window.get_bounds()
	if offset_x then
		result_x = win_x - w
	end

	result_x = max(result_x, 0.0)
	result_y = max(result_y, 0.0)

	return result_x, result_y
end

local function begin_window(id, x, y)
	local instance = instances[id]
	if instance ~= nil then
		x, y = constrain_position(x, y, instance.w, instance.h)
	end

	Cursor.push_context()
	Window.begin(
		id,
		{
			x = x,
			y = y,
			w = 0.0,
			h = 0.0,
			allow_resize = false,
			allow_focus = false,
			border = 0.0,
			auto_size_window = true,
			layer = "ContextMenu",
			bg_color = Style.MenuColor,
			rounding = {0, 0, 2, 2},
			no_saved_settings = true
		}
	)
end

function Menu.begin_menu(label, options)
	local result = false
	local x, y = Cursor.get_position()
	local is_menu_bar = Window.is_menu_bar()
	local id = Window.get_id() .. "." .. label
	local win = Window.top()

	options = alter_options(options)
	options.is_selected = options.enabled and win.selected == id

	if is_menu_bar then
		options.is_selectable_text_only = options.enabled
		options.pad = pad * 2
	else
		Cursor.set_x(x + left_pad)
	end

	local menu_x = 0.0
	local menu_y = 0.0

	-- 'result' may be false if 'enabled' is false. The hovered state is still required
	-- so that will be handled differently.
	result = Text.begin(label, options)
	local item_x, item_y, item_w, item_h = Cursor.get_item_bounds()
	if is_menu_bar then
		Cursor.same_line()

		-- Menubar items don't extend to the width of the window since these items are layed out horizontally. Only
		-- need to perform hover check on item bounds.
		local hovered = Cursor.is_in_item_bounds(Window.get_mouse_position())
		if hovered then
			if Mouse.is_clicked(1) then
				if result then
					MenuState.was_opened = MenuState.is_opened
					MenuState.is_opened = not MenuState.is_opened

					if MenuState.is_opened then
						MenuState.request_close = false
					end
				elseif MenuState.was_opened then
					MenuState.request_close = false
				end
			end
		end

		if MenuState.is_opened and opened_context_menu == nil then
			if result then
				win.selected = id
			end
		else
			win.selected = nil
		end

		menu_x = x
		menu_y = y + Window.get_height()
	else
		local win_x, win_y, win_w, win_h = Window.get_bounds()
		local h = Style.Font:getHeight()
		local tri_x = win_x + win_w - h * 0.75
		local tri_y = y + h * 0.5
		local radius = h * 0.35
		DrawCommands.triangle("fill", tri_x, tri_y, radius, 90, Style.text_color)

		menu_x = x + win_w
		menu_y = y

		if result then
			win.selected = id
		end

		Window.add_item(item_x, item_y, item_w + right_pad, item_h)

		-- Prevent closing the menu window if this item is clicked.
		if is_item_hovered() and Mouse.is_clicked(1) then
			MenuState.request_close = false
		end
	end

	result = win.selected == id

	if result then
		begin_window(id, menu_x, menu_y)
	end

	return result
end

function Menu.menu_item(label, options)
	options = alter_options(options)

	Cursor.set_x(Cursor.get_x() + left_pad)
	local result = Text.begin(label, options)
	local item_x, item_y, item_w, item_h = Cursor.get_item_bounds()
	Window.add_item(item_x, item_y, item_w + right_pad, item_h)

	if result then
		local win = Window.top()
		win.selected = nil

		result = Mouse.is_clicked(1)
		if result and MenuState.was_opened then
			MenuState.request_close = true
		end
	else
		if is_item_hovered() and Mouse.is_clicked(1) then
			MenuState.request_close = false
		end
	end

	return result
end

function Menu.menu_item_checked(label, IsChecked, options)
	options = alter_options(options)
	local x, y = Cursor.get_position()
	local result = Menu.menu_item(label, options)

	if IsChecked then
		local h = Style.Font:getHeight()
		DrawCommands.check(x + left_pad * 0.5, y + h * 0.5, check_size, options.colour)
	end

	return result
end

function Menu.separator()
	local ctx = Context.top()
	if ctx.t == "Menu" then
		local item = get_item("Sep_" .. ctx.data.separator_id)
		item.is_separator = true
		ctx.data.separator_id = ctx.data.separator_id + 1
	end
end

function Menu.end_menu()
	local id = Window.get_id()
	if instances[id] == nil then
		instances[id] = {}
	end
	instances[id].w = Window.get_width()
	instances[id].h = Window.get_height()

	Window.finish()
	Cursor.pop_context()
end

function Menu.pad()
	return pad
end

function Menu.begin_context_menu(options)
	options = options == nil and {} or options
	options.is_item = options.is_item == nil and false or options.is_item
	options.is_window = options.is_window == nil and false or options.is_window
	options.button = options.button == nil and 2 or options.button

	local BaseId = nil
	local id = nil
	if options.is_window then
		BaseId = Window.get_id()
	elseif options.is_item then
		BaseId = Window.get_context_hot_item()
		if BaseId == nil then
			BaseId = Window.get_hot_item()
		end
	end

	if options.is_item and Window.get_last_item() ~= BaseId then
		return false
	end

	if BaseId ~= nil then
		id = BaseId .. ".ContextMenu"
	end

	if id == nil then
		return false
	end

	if MenuState.is_opened and opened_context_menu ~= nil then
		if opened_context_menu.id == id then
			begin_window(opened_context_menu.id, opened_context_menu.x, opened_context_menu.y)
			return true
		end
		return false
	end

	local is_opening = false
	if not Window.is_obstructed_at_mouse() and Window.is_mouse_hovered() and Mouse.is_clicked(options.button) then
		local is_valid_window = options.is_window and Window.get_hot_item() == nil
		local is_valid_item = options.is_item

		if is_valid_window or is_valid_item then
			MenuState.is_opened = true
			is_opening = true
		end
	end

	if is_opening then
		local x, y = Mouse.position()
		x, y = constrain_position(x, y, 0.0, 0.0)
		opened_context_menu = {id = id, x = x, y = y, win = Window.top()}
		Window.set_context_hot_item(options.is_item and BaseId or nil)
	end

	return false
end

function Menu.end_context_menu()
	Menu.end_menu()
end

function Menu.close()
	MenuState.was_opened = MenuState.is_opened
	MenuState.is_opened = false
	MenuState.request_close = false

	if opened_context_menu ~= nil then
		opened_context_menu.win.context_hot_item = nil
		opened_context_menu = nil
	end
end

return Menu
