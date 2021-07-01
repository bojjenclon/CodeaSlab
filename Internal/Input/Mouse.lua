local insert = table.insert

local Common = required("Common")

local Mouse = {}

local state = {
	x = 0.0,
	y = 0.0,
	delta_x = 0.0,
	delta_y = 0.0,
	async_delta_x = 0.0,
	async_delta_y = 0.0,
	buttons = {}
}

local cursors = nil
local current_cursor = "arrow"
local pending_cursor = ""
local moused_moved_fn = nil
local moused_pressed_fn = nil
local moused_released_fn = nil
local events = {}

local function on_mouse_moved(x, y, d_x, d_y, is_touch)
	state.x = x
	state.y = y
	state.async_delta_x = state.async_delta_x + d_x
	state.async_delta_y = state.async_delta_y + d_y
end

local function push_event(t, x, y, button, is_touch, presses)
	insert(
		events,
		{
			t = t,
			x = x,
			y = y,
			button = button,
			is_touch = is_touch,
			presses = presses
		}
	)
end

local function on_mouse_pressed(x, y, button, is_touch, presses)
	push_event(Common.Event.Pressed, x, y, button, is_touch, presses)

	if moused_pressed_fn ~= nil then
		moused_pressed_fn(x, y, button, is_touch, presses)
	end
end

local function on_mouse_released(x, y, button, is_touch, presses)
	push_event(Common.Event.Released, x, y, button, is_touch, presses)

	if moused_released_fn ~= nil then
		moused_released_fn(x, y, button, is_touch, presses)
	end
end

local function process_events()
	state.buttons = {}

	for i, v in ipairs(events) do
		if state.buttons[v.button] == nil then
			state.buttons[v.button] = {}
		end

		local Button = state.buttons[v.button]
		Button.t = v.t
		Button.is_touch = v.is_touch
		Button.presses = v.presses
	end

	events = {}
end

function Mouse.initialize(Args)
	moused_moved_fn = love.handlers["mousemoved"]
	moused_pressed_fn = love.handlers["mousepressed"]
	moused_released_fn = love.handlers["mousereleased"]
	love.handlers["mousemoved"] = on_mouse_moved
	love.handlers["mousepressed"] = on_mouse_pressed
	love.handlers["mousereleased"] = on_mouse_released
end

function Mouse.update()
	process_events()

	state.delta_x = state.async_delta_x
	state.delta_y = state.async_delta_y
	state.async_delta_x = 0
	state.async_delta_y = 0

	if cursors == nil then
		cursors = {}
		cursors.Arrow = love.mouse.getSystemCursor("arrow")
		cursors.SizeWE = love.mouse.getSystemCursor("sizewe")
		cursors.SizeNS = love.mouse.getSystemCursor("sizens")
		cursors.SizeNESW = love.mouse.getSystemCursor("sizenesw")
		cursors.SizeNWSE = love.mouse.getSystemCursor("sizenwse")
		cursors.IBeam = love.mouse.getSystemCursor("ibeam")
		cursors.Hand = love.mouse.getSystemCursor("hand")
	end

	Mouse.set_cursor("arrow")
end

function Mouse.is_down(button)
	return love.mouse.isDown(button)
end

function Mouse.is_clicked(button)
	local item = state.buttons[button]

	if item == nil or item.presses == 0 then
		return false
	end

	return item.t == Common.Event.Pressed
end

function Mouse.is_double_clicked(button)
	local item = state.buttons[button]

	if item == nil or item.presses < 2 then
		return false
	end

	return item.t == Common.Event.Pressed and item.presses % 2 == 0
end

function Mouse.is_released(button)
	local item = state.buttons[button]

	if item == nil then
		return false
	end

	return item.t == Common.Event.Released
end

function Mouse.position()
	return state.x, state.y
end

function Mouse.has_delta()
	return state.delta_x ~= 0.0 or state.delta_y ~= 0.0
end

function Mouse.get_delta()
	return state.delta_x, state.delta_y
end

function Mouse.is_dragging(button)
	return Mouse.is_down(button) and Mouse.has_delta()
end

function Mouse.set_cursor(t)
	if cursors == nil then
		return
	end

	pending_cursor = t
end

function Mouse.update_cursor()
	if pending_cursor ~= "" and pending_cursor ~= current_cursor then
		current_cursor = pending_cursor
		pending_cursor = ""

		local t = current_cursor
		if t == "arrow" then
			love.mouse.setCursor(cursors.Arrow)
		elseif t == "sizewe" then
			love.mouse.setCursor(cursors.SizeWE)
		elseif t == "sizens" then
			love.mouse.setCursor(cursors.SizeNS)
		elseif t == "sizenesw" then
			love.mouse.setCursor(cursors.SizeNESW)
		elseif t == "sizenwse" then
			love.mouse.setCursor(cursors.SizeNWSE)
		elseif t == "ibeam" then
			love.mouse.setCursor(cursors.IBeam)
		elseif t == "hand" then
			love.mouse.setCursor(cursors.Hand)
		end
	end
end

return Mouse
