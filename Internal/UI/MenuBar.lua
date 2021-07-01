local Cursor = required("Cursor")
local DrawCommands = required("DrawCommands")
local Menu = required("Menu")
local MenuState = required("MenuState")
local Style = required("Style")
local Window = required("Window")

local MenuBar = {}

local instances = {}

local function get_instance()
	local win = Window.top()
	if instances[win] == nil then
		local instance = {}
		instance.selected = nil
		instance.id = win.id .. "_MenuBar"
		instances[win] = instance
	end
	return instances[win]
end

function MenuBar.begin(is_main_menu_bar)
	local x, y = Cursor.get_position()
	local win_x, win_y, win_w, win_h = Window.get_bounds()
	local instance = get_instance()

	if not MenuState.is_opened then
		instance.selected = nil
	end

	if is_main_menu_bar then
		MenuState.main_menu_bar_h = Style.Font:getHeight()
	end

	Window.begin(
		instance.id,
		{
			x = x,
			y = y,
			w = win_w,
			h = Style.Font:getHeight(),
			allow_resize = false,
			allow_focus = false,
			border = 0.0,
			bg_color = Style.MenuColor,
			no_outline = true,
			is_menu_bar = true,
			auto_size_window = false,
			auto_size_content = false,
			layer = is_main_menu_bar and "MainMenuBar" or nil,
			rounding = 0.0,
			no_saved_settings = true
		}
	)

	Cursor.advance_x(4.0)

	return true
end

function MenuBar.finish()
	Window.finish()
end

function MenuBar.clear()
	for i, v in ipairs(instances) do
		v.selected = nil
	end
end

return MenuBar
