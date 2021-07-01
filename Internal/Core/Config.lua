local FileSystem = required("FileSystem")

local Config = {}
local DecodeValueFn = nil
local Section = nil

local function IsBasicType(value)
	if value ~= nil then
		local t = type(value)

		return t == "number" or t == "boolean" or t == "string"
	end

	return false
end

local function IsArray(tbl)
	if tbl ~= nil and type(tbl) == "table" then
		local N = 0
		for k, v in pairs(tbl) do
			if type(k) ~= "number" then
				return false
			end

			if not IsBasicType(v) then
				return false
			end

			N = N + 1
		end

		return #tbl == N
	end

	return false
end

local function EncodeValue(value)
	local result = ""

	if value ~= nil then
		local t = type(value)
		if t == "boolean" then
			result = value == true and "true" or "false"
		elseif t == "number" or t == "string" then
			result = tostring(value)
		end
	end

	return result
end

local function EncodePair(key, value)
	local result = tostring(key) .. " = "

	if value ~= nil then
		if type(value) == "table" then
			if IsArray(value) then
				result = result .. "(" .. table.concat(value, ",") .. ")\n"
			else
				result = result .. "{"
				local First = true
				for k, v in pairs(value) do
					if not First then
						result = result .. ","
					end
					result = result .. k .. "=" .. EncodeValue(v)
					First = false
				end
				result = result .. "}\n"
			end
		elseif IsBasicType(value) then
			result = result .. tostring(value) .. "\n"
		end
	end

	return result
end

local function EncodeSection(Section, Values)
	local result = "[" .. Section .. "]\n"

	for k, v in pairs(Values) do
		result = result .. EncodePair(k, v)
	end

	return result .. "\n"
end

local function DecodeBoolean(value)
	local Lower = string.lower(value)

	if Lower == "true" then
		return true
	elseif Lower == "false" then
		return false
	end

	return nil
end

local function DecodeArray(value)
	local result = nil

	if string.sub(value, 1, 1) == "(" then
		result = {}
		local index = 1
		local Buffer = ""

		while index <= #value do
			local ch = string.sub(value, index, index)

			if ch == "," or ch == ")" then
				local item = DecodeValueFn(Buffer)
				if item ~= nil then
					table.insert(result, item)
				end
				Buffer = ""
			elseif ch ~= "(" and ch ~= " " then
				Buffer = Buffer .. ch
			end

			index = index + 1
		end
	end

	return result
end

local function DecodeTable(value)
	local result = nil

	if string.sub(value, 1, 1) == "{" then
		result = {}
		for k, v in string.gmatch(value, "(%w+)=(%-?%w+)") do
			result[k] = DecodeValueFn(v)
		end
	end

	return result
end

local function DecodeValue(value)
	if value ~= nil and value ~= "" then
		local Number = tonumber(value)
		if Number ~= nil then
			return Number
		end

		local Boolean = DecodeBoolean(value)
		if Boolean ~= nil then
			return Boolean
		end

		if value == "nil" then
			return nil
		end

		local Array = DecodeArray(value)
		if Array ~= nil then
			return Array
		end

		local tbl = DecodeTable(value)
		if tbl ~= nil then
			return tbl
		end

		return value
	end

	return nil
end

DecodeValueFn = DecodeValue

local function DecodeLine(line, result)
	if string.sub(line, 1, 1) == ";" then
		return
	end

	if string.sub(line, 1, 1) == "[" and string.sub(line, #line, #line) == "]" then
		local key = string.sub(line, 2, #line - 1)
		result[key] = {}
		Section = result[key]
	end

	local index = string.find(line, "=", 1, true)

	if index ~= nil then
		local key = string.sub(line, 1, index - 1)
		key = string.gsub(key, " ", "")

		local value = string.sub(line, index + 1)
		value = string.gsub(value, " ", "")

		if string.sub(value, #value, #value) == "," then
			value = string.sub(value, 1, #value - 1)
		end

		if Section ~= nil then
			Section[key] = DecodeValue(value)
		else
			result[key] = DecodeValue(value)
		end
	end
end

function Config.Encode(tbl)
	local result = ""

	if type(tbl) == "table" and not IsArray(tbl) then
		local Sections = {}
		for k, v in pairs(tbl) do
			if type(v) == "table" and not IsArray(v) then
				Sections[k] = v
			else
				result = result .. EncodePair(k, v)
			end
		end

		if string.len(result) > 0 then
			result = result .. "\n"
		end

		for k, v in pairs(Sections) do
			result = result .. EncodeSection(k, v)
		end
	end

	return result
end

function Config.Decode(Stream)
	local result = nil
	local err = ""

	if Stream ~= nil then
		if type(Stream) == "string" then
			result = {}

			local start = 1
			local finish = string.find(Stream, "\n", start, true)
			local line = ""

			while finish ~= nil do
				line = string.sub(Stream, start, finish - 1)

				DecodeLine(line, result)

				start = finish + 1
				finish = string.find(Stream, "\n", start, true)
			end

			line = string.sub(Stream, start)

			DecodeLine(line, result)
		else
			err = "Invalid t given for Stream. t given is " .. type(Stream) .. "."
		end
	else
		err = "Invalid stream given to Config.Decode!"
	end

	return result, err
end

function Config.load_file(path, UseLoveFS)
	local result = nil
	local Contents, err = nil, nil
	if UseLoveFS then
		Contents, err = love.filesystem.read("string", path)
	else
		Contents, err = FileSystem.ReadContents(path)
	end
	if Contents ~= nil then
		result, err = Config.Decode(Contents)
	end

	return result, err
end

function Config.save(path, tbl)
	local result = false
	local err = ""
	if tbl ~= nil then
		local Contents = Config.Encode(tbl)
		result, err = FileSystem.SaveContents(path, Contents)
	else
		err = "Invalid table given to Config.save!"
	end

	return result, err
end

return Config
