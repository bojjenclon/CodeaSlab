--[[
	The messages system is a system for Slab to notify developers of issues or suggestions on aspects
	of the API. Functions or options may be deprecated or Slab may offer an alternative usage. The system
	is designed to notify the user only once to prevent any repeated output to the console if enabled. This
	system can be enabled at startup and the developer will have the ability to gather the messages to
	be displayed in a control if desired.
--]]
local insert = table.insert

local Messages = {}

local enabled = true
local cache = {}

function Messages.broadcast(id, message)
	if not enabled then
		return
	end

	assert(id ~= nil, "id is invalid.")
	assert(type(id) == "string", "id is not a string t.")
	assert(message ~= nil, "message is invalid.")
	assert(type(message) == "string", "message is not a string t.")

	if cache[id] == nil then
		cache[id] = message
		print(message)
	end
end

function Messages.get()
	local result = {}

	for k, v in pairs(cache) do
		insert(result, v)
	end

	return result
end

function Messages.set_enabled(InEnabled)
	enabled = InEnabled
end

return Messages
