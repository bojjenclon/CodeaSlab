local Utility = {}

local abs = math.abs
local remove = table.remove

function Utility.make_color(colour)
	local copy = {0.0, 0.0, 0.0, 1.0}
	if colour ~= nil then
		copy[1] = colour[1]
		copy[2] = colour[2]
		copy[3] = colour[3]
		copy[4] = colour[4]
	end
	return copy
end

function Utility.hsv_to_rgb(h, s, v)
	if s == 0.0 then
		return v, v, v
	end

	h = math.fmod(h, 1.0) / (60.0 / 360.0)
	local i = math.floor(h)
	local f = h - i
	local p = v * (1.0 - s)
	local q = v * (1.0 - s * f)
	local t = v * (1.0 - s * (1.0 - f))

	local r, g, b = 0, 0, 0

	if i == 0 then
		r, g, b = v, t, p
	elseif i == 1 then
		r, g, b = q, v, p
	elseif i == 2 then
		r, g, b = p, v, t
	elseif i == 3 then
		r, g, b = p, q, v
	elseif i == 4 then
		r, g, b = t, p, v
	else
		r, g, b = v, p, q
	end

	return r, g, b
end

function Utility.rgb_to_hsv(r, g, b)
	local k = 0.0

	if g < b then
		local t = g
		g = b
		b = t
		k = -1.0
	end

	if r < g then
		local t = r
		r = g
		g = t
		k = -2.0 / 6.0 - k
	end

	local chroma = r - (g < b and g or b)
	local h = abs(k + (g - b) / (6.0 * chroma + 1e-20))
	local s = chroma / (r + 1e-20)
	local v = r

	return h, s, v
end

function Utility.has_value(tbl, value)
	for i, v in ipairs(tbl) do
		if v == value then
			return true
		end
	end

	return false
end

function Utility.remove(tbl, value)
	for i, v in ipairs(tbl) do
		if v == value then
			remove(tbl, i)
			break
		end
	end
end

function Utility.copy_values(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return
	end

	for k, v in pairs(a, b) do
		local other = b[k]

		if other ~= nil then
			a[k] = Utility.copy(other)
		end
	end
end

function Utility.copy(original)
	local copy = nil

	if type(original) == "table" then
		copy = {}

		for k, v in next, original, nil do
			copy[Utility.copy(k)] = Utility.copy(v)
		end
	else
		copy = original
	end

	return copy
end

function Utility.contains(tbl, value)
	if tbl == nil then
		return false
	end

	for i, v in ipairs(tbl) do
		if value == v then
			return true
		end
	end

	return false
end

function Utility.table_count(tbl)
	local result = 0

	if tbl ~= nil then
		for k, v in pairs(tbl) do
			result = result + 1
		end
	end

	return result
end

function Utility.is_windows()
	return false
end

function Utility.is_osx()
	return false
end

function Utility.is_mobile()
	return true
end

function Utility.clamp(value, min_val, max_val)
	return value < min_val and min_val or (value > max_val and max_val or value)
end

return Utility
