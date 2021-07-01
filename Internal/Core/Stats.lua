local Stats = {}

local insert = table.insert
local max = math.max

local data = {}
local pending = {}
local enabled = false
local queue_enabled = false
local queue_disabled = false
local id = 1
local queue_flush = false
local frame_number = 0

local function get_category(category)
	assert(category ~= nil, "Nil category given to Stats system.")
	assert(category ~= "", "Empty category given to Stats system.")
	assert(type(category) == "string", "category given is not of t string. t given is '" .. type(category) .. "'.")

	if data[category] == nil then
		data[category] = {}
	end

	return data[category]
end

local function reset_category(category)
	local instance = data[category]

	if instance ~= nil then
		for k, v in pairs(instance) do
			v.last_time = v.time
			v.last_call_count = v.call_count
			v.max_time = max(v.max_time, v.time)
			v.time = 0.0
			v.call_count = 0
		end
	end
end

local function get_item(name, category)
	assert(name ~= nil, "Nil name given to Stats system.")
	assert(name ~= "", "Empty name given to Stats system.")

	local cat = get_category(category)

	if cat[name] == nil then
		local instance = {}
		instance.time = 0.0
		instance.max_time = 0.0
		instance.call_count = 0
		instance.last_time = 0.0
		instance.last_call_count = 0.0
		cat[name] = instance
	end

	return cat[name]
end

function Stats.begin(name, category)
	if not enabled then
		return
	end

	local handle = id
	id = id + 1

	local instance = {start_time = ElapsedTime, name = name, category = category}
	pending[handle] = instance

	return handle
end

function Stats.finish(handle)
	if not enabled then
		return
	end

	assert(handle ~= nil, "Nil handle given to Stats.finish.")

	local instance = pending[handle]
	assert(instance ~= nil, "Invalid handle given to Stats.finish.")
	pending[handle] = nil

	local elapsed = ElapsedTime - instance.start_time

	local item = get_item(instance.name, instance.category)
	item.call_count = item.call_count + 1
	item.time = item.time + elapsed
end

function Stats.get_time(name, category)
	if not enabled then
		return 0.0
	end

	local item = get_item(name, category)

	return item.time > 0.0 and item.time or item.last_time
end

function Stats.get_max_time(name, category)
	if not enabled then
		return 0.0
	end

	local item = get_item(name, category)

	return item.max_time
end

function Stats.get_call_count(name, category)
	if not enabled then
		return 0
	end

	local item = get_item(name, category)

	return item.call_count > 0 and item.call_count or item.last_call_count
end

function Stats.reset()
	frame_number = frame_number + 1

	if queue_enabled then
		enabled = true
		queue_enabled = false
	end

	if queue_disabled then
		enabled = false
		queue_disabled = false
	end

	if queue_flush then
		data = {}
		pending = {}
		id = 1
		queue_flush = false
	end

	if not enabled then
		return
	end

	local message = nil
	for k, v in pairs(pending) do
		if message == nil then
			message = "Stats.finish were not called for the given stats: \n"
		end

		message = message .. "\t" .. tostring(v.name) .. " in " .. tostring(v.category) .. "\n"
	end

	assert(message == nil, message)

	for k, v in pairs(data) do
		reset_category(k)
	end
end

function Stats.set_enabled(is_enabled)
	queue_enabled = is_enabled

	if not queue_enabled then
		queue_disabled = true
	end
end

function Stats.is_enabled()
	return enabled
end

function Stats.get_categories()
	local result = {}

	for k, v in pairs(data) do
		insert(result, k)
	end

	return result
end

function Stats.get_items(category)
	local result = {}

	local instance = get_category(category)

	for k, v in pairs(instance) do
		insert(result, k)
	end

	return result
end

function Stats.flush()
	queue_flush = true
end

function Stats.get_frame_number()
	return frame_number
end

return Stats
