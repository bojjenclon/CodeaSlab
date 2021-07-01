local insert = table.insert

local Common = required("Common")
local Stats = required("Stats")
local Utility = required("Utility")

local Keyboard = {}

local key_pressed_fn = nil
local key_released_fn = nil
local events = {}
local keys = {}

local function push_event(t, key, Scancode, IsRepeat)
	insert(
		events,
		{
			t = t,
			key = key,
			Scancode = Scancode,
			IsRepeat = IsRepeat,
			Frame = Stats.get_frame_number()
		}
	)
end

local function on_key_pressed(key, Scancode, IsRepeat)
	push_event(Common.Event.Pressed, key, Scancode, IsRepeat)

	if key_pressed_fn ~= nil then
		key_pressed_fn(key, Scancode, IsRepeat)
	end
end

local function on_key_released(key, Scancode)
	push_event(Common.Event.Released, key, Scancode, false)

	if key_released_fn ~= nil then
		key_released_fn(key, Scancode)
	end
end

local function process_events()
	keys = {}

	-- Soft keyboards found on mobile/tablet devices will push keypressed/keyreleased events when the user
	-- releases from the pressed key. All released events pushed as the same frame as the pressed events will be
	-- pushed to the events table for the next frame to process.
	local NextEvents = {}

	for i, v in ipairs(events) do
		if keys[v.Scancode] == nil then
			keys[v.Scancode] = {}
		end

		local key = keys[v.Scancode]

		if Utility.is_mobile() and v.t == Common.Event.Released and key.Frame == v.Frame then
			v.Frame = v.Frame + 1
			insert(NextEvents, v)
		else
			key.t = v.t
			key.key = v.key
			key.Scancode = v.Scancode
			key.IsRepeat = v.IsRepeat
			key.Frame = v.Frame
		end
	end

	events = NextEvents
end

function Keyboard.initialize(Args)
	key_pressed_fn = love.handlers["keypressed"]
	key_released_fn = love.handlers["keyreleased"]
	love.handlers["keypressed"] = on_key_pressed
	love.handlers["keyreleased"] = on_key_released
end

function Keyboard.update()
	process_events()
end

function Keyboard.is_pressed(key)
	local item = keys[key]

	if item == nil then
		return false
	end

	return item.t == Common.Event.Pressed
end

function Keyboard.is_released(key)
	local item = keys[key]

	if item == nil then
		return false
	end

	return item.t == Common.Event.Released
end

function Keyboard.is_down(key)
	return love.keyboard.isScancodeDown(key)
end

return Keyboard
