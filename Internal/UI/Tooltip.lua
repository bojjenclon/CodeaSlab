local insert = table.insert
local format = string.format
local min = math.min

local Cursor = required("Cursor")
local DrawCommands = required("DrawCommands")
local LayoutManager = required("LayoutManager")
local Mouse = required("Mouse")
local Style = required("Style")
local text = required("text")
local Window = required("Window")
local Utility = required("Utility")

local Tooltip = {}

local last_display_time = 0.0
local accum_display_time = 0.0
local tooltip_time = 0.75
local tooltip_expire_time = 0.025
local alpha = 0.0
local offset_y = 0.0
local reset_size = false

function Tooltip.begin(tip)
	if tip == nil or tip == "" then
		return
	end

	local elapsed = ElapsedTime - last_display_time
	if elapsed > tooltip_expire_time then
		accum_display_time = 0.0
		alpha = 0.0
		reset_size = true
	end

	local delta_time = love.timer.getDelta()
	accum_display_time = accum_display_time + delta_time
	last_display_time = ElapsedTime

	if accum_display_time > tooltip_time then
		local x, y = Mouse.position()
		alpha = min(alpha + delta_time * 4.0, 1.0)
		local bg_color = Utility.make_color(Style.WindowBackgroundColor)
		local text_color = Utility.make_color(Style.text_color)
		bg_color[4] = alpha
		text_color[4] = alpha

		local cursor_x, cursor_y = Cursor.get_position()

		LayoutManager.begin("ignore", {ignore = true})
		Window.begin(
			"Tooltip",
			{
				x = x,
				y = y - offset_y,
				w = 0,
				h = 0,
				auto_size_window = true,
				auto_size_content = false,
				allow_resize = false,
				allow_focus = false,
				layer = "ContextMenu",
				reset_window_size = reset_size,
				can_obstruct = false,
				no_saved_settings = true
			}
		)
		Text.begin_formatted(tip, {colour = text_color})
		offset_y = Window.get_height()
		Window.finish()
		LayoutManager.finish()
		Cursor.set_position(cursor_x, cursor_y)
		reset_size = false
	end
end

function Tooltip.get_debug_info()
	local info = {}

	local elapsed = ElapsedTime - last_display_time
	insert(info, format("time: %.2f", accum_display_time))
	insert(info, format("Is Visible: %s", tostring(accum_display_time > tooltip_time and elapsed <= tooltip_expire_time)))
	insert(info, format("time to Display: %.2f", tooltip_time))
	insert(info, format("Expire time: %f", tooltip_expire_time))

	return info
end

return Tooltip
