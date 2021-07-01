local abs = math.abs
local insert = table.insert
local min = math.min
local max = math.max
local floor = math.floor
local huge = math.huge
local gsub = string.gsub
local sub = string.sub
local match = string.match
local len = string.len
local byte = string.byte
local find = string.find

local Cursor = required("Cursor")
local DrawCommands = required("DrawCommands")
local Keyboard = required("Keyboard")
local LayoutManager = required("LayoutManager")
local Mouse = required("Mouse")
local Region = required("Region")
local Stats = required("Stats")
local Style = required("Style")
local text = required("text")
local tooltip = required("tooltip")
local UTF8 = require("utf8")
local Utility = required("Utility")
local Window = required("Window")

local Input = {}

local instances = {}
local focused = nil
local last_focused = nil
local text_cursor_pos = 0
local text_cursor_pos_line = 0
local text_cursor_pos_line_max = 0
local text_cursor_pos_line_number = 1
local text_cursor_anchor = -1
local text_cursor_alpha = 0.0
local fade_in = true
local drag_select = false
local focus_to_next = false
local last_text = ""
local pad = Region.get_scroll_pad() + Region.get_scroll_bar_size()
local pending_focus = nil
local pending_cursor_pos = -1
local pending_cursor_column = -1
local pending_cursor_line = -1
local is_sliding = false
local drag_delta = 0

local MIN_WIDTH = 150.0

local function sanitize_text(data)
	local result = false

	if data ~= nil then
		local count = 0
		data, count = gsub(data, "\r", "")
		result = count > 0
	end

	return data, result
end

local function get_display_character(data, pos)
	local result = ""

	if data ~= nil and pos > 0 and pos < len(data) then
		local offset = UTF8.offset(data, -1, pos + 1)
		result = sub(data, offset, pos)

		if result == nil then
			result = "nil"
		end
	end

	if result == "\n" then
		result = "\\n"
	end

	return result
end

local function get_character(data, index, forward)
	local result = ""
	if forward then
		local sub = sub(data, index + 1)
		result = match(sub, "[%z\1-\127\194-\244%s\n][\128-\191]*")
	else
		local sub = sub(data, 1, index)
		result = match(sub, "[%z\1-\127\194-\244%s\n][\128-\191]*$")
	end
	return result
end

local function update_multi_line_position(instance)
	if instance ~= nil then
		if instance.lines ~= nil then
			local count = 0
			local start = 0
			local found = false
			for i, v in ipairs(instance.lines) do
				local length = len(v)
				count = count + length
				if text_cursor_pos < count then
					text_cursor_pos_line = text_cursor_pos - start
					text_cursor_pos_line_number = i
					found = true
					break
				end
				start = start + length
			end

			if not found then
				text_cursor_pos_line = len(instance.lines[#instance.lines])
				text_cursor_pos_line_number = #instance.lines
			end
		else
			text_cursor_pos_line = text_cursor_pos
			text_cursor_pos_line_number = 1
		end
		text_cursor_pos_line_max = text_cursor_pos_line
	end
end

local function validate_text_cursor_pos(instance)
	if instance ~= nil then
		local old_pos = text_cursor_pos
		local bite = byte(sub(instance.text, text_cursor_pos, text_cursor_pos))
		-- This is a continuation byte. check next byte to see if it is an ASCII character or
		-- the beginning of a UTF8 character.
		if bite ~= nil and bite > 127 then
			local next_bite = byte(sub(instance.text, text_cursor_pos + 1, text_cursor_pos + 1))
			if next_bite ~= nil and next_bite > 127 and next_bite < 191 then
				while bite > 127 and bite < 191 do
					text_cursor_pos = text_cursor_pos - 1
					bite = byte(sub(instance.text, text_cursor_pos, text_cursor_pos))
				end

				if text_cursor_pos < old_pos or bite >= 191 then
					text_cursor_pos = text_cursor_pos - 1
					update_multi_line_position(instance)
				end
			end
		end
	end
end

local function move_to_home(instance)
	if instance ~= nil then
		if instance.lines ~= nil and text_cursor_pos_line_number > 1 then
			text_cursor_pos_line = 0
			local count = 0
			local start = 0
			for i, v in ipairs(instance.lines) do
				count = count + len(v)
				if i == text_cursor_pos_line_number then
					text_cursor_pos = start
					break
				end
				start = start + len(v)
			end
		else
			text_cursor_pos = 0
		end
		update_multi_line_position(instance)
	end
end

local function move_to_end(instance)
	if instance ~= nil then
		if instance.lines ~= nil then
			local count = 0
			for i, v in ipairs(instance.lines) do
				count = count + len(v)
				if i == text_cursor_pos_line_number then
					text_cursor_pos = count - 1

					if i == #instance.lines then
						text_cursor_pos = count
					end
					break
				end
			end
		else
			text_cursor_pos = #instance.text
		end
		update_multi_line_position(instance)
	end
end

local function validate_number(instance)
	local result = false

	if instance ~= nil and instance.numbers_only and instance.text ~= "" then
		if sub(instance.text, #instance.text, #instance.text) == "." then
			return
		end

		local value = tonumber(instance.text)
		if value == nil then
			value = 0.0
		end

		local old_value = value

		if instance.min_number ~= nil then
			value = max(value, instance.min_number)
		end
		if instance.max_number ~= nil then
			value = min(value, instance.max_number)
		end

		result = old_value ~= value

		instance.text = tostring(value)
	end

	return result
end

local function get_alignment_offset(instance)
	local offset = 6.0
	if instance ~= nil then
		if instance.align == "center" then
			local text_w = Text.get_width(instance.text)
			offset = (instance.w * 0.5) - (text_w * 0.5)
		end
	end
	return offset
end

local function get_selection(instance)
	if instance ~= nil and text_cursor_anchor >= 0 and text_cursor_anchor ~= text_cursor_pos then
		local min_val = min(text_cursor_anchor, text_cursor_pos) + 1
		local max_val = max(text_cursor_anchor, text_cursor_pos)

		return sub(instance.text, min_val, max_val)
	end
	return ""
end

local function move_cursor_vertical(instance, move_down)
	if instance ~= nil and instance.lines ~= nil then
		local old_line_number = text_cursor_pos_line_number
		if move_down then
			text_cursor_pos_line_number = min(text_cursor_pos_line_number + 1, #instance.lines)
		else
			text_cursor_pos_line_number = max(1, text_cursor_pos_line_number - 1)
		end
		local line = instance.lines[text_cursor_pos_line_number]
		if old_line_number == text_cursor_pos_line_number then
			text_cursor_pos_line = move_down and len(line) or 0
		else
			if text_cursor_pos_line_number == #instance.lines and text_cursor_pos_line >= len(line) then
				text_cursor_pos_line = len(line)
			else
				text_cursor_pos_line = min(len(line), text_cursor_pos_line_max + 1)
				local ch = get_character(line, text_cursor_pos_line)
				if ch ~= nil then
					text_cursor_pos_line = text_cursor_pos_line - len(ch)
				end
			end
		end
		local start = 0
		for i, v in ipairs(instance.lines) do
			if i == text_cursor_pos_line_number then
				text_cursor_pos = start + text_cursor_pos_line
				break
			end
			start = start + len(v)
		end
	end
end

local function is_valid_digit(instance, ch)
	if instance ~= nil then
		if instance.numbers_only then
			if match(ch, "%d") ~= nil then
				return true
			end

			if ch == "-" then
				if text_cursor_anchor == 0 or text_cursor_pos == 0 or #instance.text == 0 then
					return true
				end
			end

			if ch == "." then
				local selected = get_selection(instance)
				if selected ~= nil and find(selected, ".", 1, true) ~= nil then
					return true
				end

				if find(instance.text, ".", 1, true) == nil then
					return true
				end
			end
		else
			return true
		end
	end
	return false
end

local function is_command_key_down()
	local l_key, r_key = "lctrl", "rctrl"
	if Utility.is_osx() then
		l_key, r_key = "lgui", "rgui"
	end
	return Keyboard.is_down(l_key) or Keyboard.is_down(r_key)
end

local function is_home_pressed()
	local result = false
	if Utility.is_osx() then
		result = is_command_key_down() and Keyboard.is_pressed("left")
	else
		result = Keyboard.is_pressed("home")
	end
	return result
end

local function is_end_pressed()
	local result = false
	if Utility.is_osx() then
		result = is_command_key_down() and Keyboard.is_pressed("right")
	else
		result = Keyboard.is_pressed("end")
	end
	return result
end

local function is_next_space_down()
	local result = false
	if Utility.is_osx() then
		result = Keyboard.is_down("lalt") or Keyboard.is_down("ralt")
	else
		result = Keyboard.is_down("lctrl") or Keyboard.is_down("rctrl")
	end
	return result
end

local function get_cursor_x_offset(instance)
	local result = get_alignment_offset(instance)
	if instance ~= nil then
		if text_cursor_pos > 0 then
			local sub = sub(instance.text, 1, text_cursor_pos)
			result = Text.get_width(sub) + get_alignment_offset(instance)
		end
	end
	return result
end

local function get_cursor_pos(instance)
	local x, y = get_alignment_offset(instance), 0.0

	if instance ~= nil then
		local data = instance.text
		if instance.lines ~= nil then
			data = instance.lines[text_cursor_pos_line_number]
			y = Text.get_height() * (text_cursor_pos_line_number - 1)
		end
		local cursor_pos = min(text_cursor_pos_line, len(data))
		if cursor_pos > 0 then
			local sub = sub(data, 0, cursor_pos)
			x = x + Text.get_width(sub)
		end
	end

	return x, y
end

local function select_word(instance)
	if instance ~= nil then
		local filter = "%s"
		if get_character(instance.text, text_cursor_pos) == " " then
			if get_character(instance.text, text_cursor_pos + 1) == " " then
				filter = "%s"
			else
				text_cursor_pos = text_cursor_pos + 1
			end
		end
		text_cursor_anchor = 0
		local i = 0
		while i ~= nil and i + 1 < text_cursor_pos do
			i = find(instance.text, filter, i + 1)
			if i ~= nil and i < text_cursor_pos then
				text_cursor_anchor = i
			else
				break
			end
		end
		i = find(instance.text, filter, text_cursor_pos + 1)
		if i ~= nil then
			text_cursor_pos = i - 1
		else
			text_cursor_pos = #instance.text
		end
		update_multi_line_position(instance)
	end
end

local function get_next_cursor_pos(instance, left)
	local result = 0
	if instance ~= nil then
		local next_space = is_next_space_down()

		if next_space then
			if left then
				result = 0
				local i = 0
				while i ~= nil and i + 1 < text_cursor_pos do
					i = find(instance.text, "%s", i + 1)
					if i ~= nil and i < text_cursor_pos then
						result = i
					else
						break
					end
				end
			else
				local i = find(instance.text, "%s", text_cursor_pos + 1)
				if i ~= nil then
					result = i
				else
					result = #instance.text
				end
			end
		else
			if left then
				local ch = get_character(instance.text, text_cursor_pos)
				if ch ~= nil then
					result = text_cursor_pos - len(ch)
				end
			else
				local ch = get_character(instance.text, text_cursor_pos, true)
				if ch ~= nil then
					result = text_cursor_pos + len(ch)
				else
					result = text_cursor_pos
				end
			end
		end
		result = max(0, result)
		result = min(result, len(instance.text))
	end
	return result
end

local function get_cursor_pos_line(instance, line, x)
	local result = 0
	if instance ~= nil and line ~= "" then
		if Text.get_width(line) < x then
			result = len(line)
			if find(line, "\n") ~= nil then
				result = len(line) - 1
			end
		else
			x = x - get_alignment_offset(instance)
			local pos_x = x
			local index = 0
			local sub = ""
			while index <= len(line) do
				local ch = get_character(line, index, true)
				if ch == nil then
					break
				end
				index = index + len(ch)
				sub = sub .. ch
				local pos_x = Text.get_width(sub)
				if pos_x > x then
					local char_x = pos_x - x
					local char_w = Text.get_width(ch)
					if char_x < char_w * 0.65 then
						result = result + len(ch)
					end
					break
				end
				result = index
			end
		end
	end
	return result
end

local function get_text_cursor_pos(instance, x, y)
	local result = 0
	if instance ~= nil then
		local line = instance.text
		local start = 0

		if instance.lines ~= nil and #instance.lines > 0 then
			local h = Text.get_height()
			local line_number = 1
			local found = false
			for i, v in ipairs(instance.lines) do
				if y <= h then
					line = v
					found = true
					break
				end
				h = h + Text.get_height()
				start = start + #v
			end

			if not found then
				line = instance.lines[#instance.lines]
			end
		end

		result = min(start + get_cursor_pos_line(instance, line, x), #instance.text)
	end
	return result
end

local function move_cursor_page(instance, page_down)
	if instance ~= nil then
		local page_h = instance.h - Text.get_height()
		local page_y = page_down and page_h or 0.0
		local x, y = get_cursor_pos(instance)
		local t_x, t_y = Region.inverse_transform(instance.id, 0.0, page_y)
		local next_y = 0.0
		if page_down then
			next_y = t_y + page_h
		else
			next_y = max(t_y - page_h, 0.0)
		end

		text_cursor_pos = get_text_cursor_pos(instance, 0.0, next_y)
		update_multi_line_position(instance)
	end
end

local function update_transform(instance)
	if instance ~= nil then
		local x, y = get_cursor_pos(instance)

		local t_x, t_y = Region.inverse_transform(instance.id, 0.0, 0.0)
		local w = t_x + instance.w - Region.get_scroll_pad() - Region.get_scroll_bar_size()
		local h = t_y + instance.h

		if instance.h > Text.get_height() then
			h = h - Region.get_scroll_pad() - Region.get_scroll_bar_size()
		end

		local new_x = 0.0
		if text_cursor_pos_line == 0 then
			new_x = t_x
		elseif x > w then
			new_x = -(x - w)
		elseif x < t_x then
			new_x = t_x - x
		end

		local new_y = 0.0
		if text_cursor_pos_line_number == 1 then
			new_y = t_y
		elseif y > h then
			new_y = -(y - h)
		elseif y < t_y then
			new_y = t_y - y
		end

		Region.translate(instance.id, new_x, new_y)
	end
end

local function delete_selection(instance)
	if instance ~= nil and instance.text ~= "" and not instance.read_only then
		local start = 0
		local min_val = 0
		local max_val = 0

		if text_cursor_anchor ~= -1 then
			min_val = min(text_cursor_anchor, text_cursor_pos)
			max_val = max(text_cursor_anchor, text_cursor_pos) + 1
		else
			if text_cursor_pos == 0 then
				return false
			end

			local new_text_cursor_pos = text_cursor_pos
			local ch = get_character(instance.text, text_cursor_pos)
			if ch ~= nil then
				min_val = text_cursor_pos - len(ch)
				new_text_cursor_pos = min_val
			end

			ch = get_character(instance.text, text_cursor_pos, true)
			if ch ~= nil then
				max_val = text_cursor_pos + 1
			else
				max_val = len(instance.text) + 1
			end

			text_cursor_pos = new_text_cursor_pos
		end

		local left = sub(instance.text, 1, min_val)
		local right = sub(instance.text, max_val)
		instance.text = left .. right

		text_cursor_pos = len(left)

		if text_cursor_anchor ~= -1 then
			text_cursor_pos = min(text_cursor_anchor, text_cursor_pos)
		end
		text_cursor_pos = max(0, text_cursor_pos)
		text_cursor_pos = min(text_cursor_pos, len(instance.text))

		text_cursor_anchor = -1
		update_multi_line_position(instance)
	end
	return true
end

local function draw_selection(instance, x, y, w, h, colour)
	if instance ~= nil and text_cursor_anchor >= 0 and text_cursor_anchor ~= text_cursor_pos then
		local min_val = min(text_cursor_anchor, text_cursor_pos)
		local max_val = max(text_cursor_anchor, text_cursor_pos)
		h = Text.get_height()

		if instance.lines ~= nil then
			local count = 0
			local start = 0
			local offset_min = 0
			local offset_max = 0
			local offset_y = 0
			for i, v in ipairs(instance.lines) do
				count = count + len(v)
				if min_val < count then
					if min_val > start then
						offset_min = max(min_val - start, 1)
					else
						offset_min = 0
					end

					if max_val < count then
						offset_max = max(max_val - start, 1)
					else
						offset_max = len(v)
					end

					local sub_min = sub(v, 1, offset_min)
					local sub_max = sub(v, 1, offset_max)
					local min_x = Text.get_width(sub_min) - 1.0 + get_alignment_offset(instance)
					local max_x = Text.get_width(sub_max) + 1.0 + get_alignment_offset(instance)

					DrawCommands.rectangle("fill", x + min_x, y + offset_y, max_x - min_x, h, colour)
				end

				if max_val <= count then
					break
				end
				start = start + len(v)
				offset_y = offset_y + h
			end
		else
			local sub_min = sub(instance.text, 1, min_val)
			local sub_max = sub(instance.text, 1, max_val)
			local min_x = Text.get_width(sub_min) - 1.0 + get_alignment_offset(instance)
			local max_x = Text.get_width(sub_max) + 1.0 + get_alignment_offset(instance)

			DrawCommands.rectangle("fill", x + min_x, y, max_x - min_x, h, colour)
		end
	end
end

local function draw_cursor(instance, x, y, w, h)
	if instance ~= nil then
		local c_x, c_y = get_cursor_pos(instance)
		local c_x = x + c_x
		local c_y = y + c_y
		h = Text.get_height()

		DrawCommands.line(c_x, c_y, c_x, c_y + h, 1.0, {0.0, 0.0, 0.0, text_cursor_alpha})
	end
end

local function is_highlight_terminator(ch)
	if ch ~= nil then
		return match(ch, "%w") == nil
	end

	return true
end

local function update_text_object(instance, width, align, highlight, base_color)
	if instance ~= nil and instance.text_object ~= nil then
		local colored_text = {}

		if highlight == nil then
			colored_text = {base_color, instance.text}
		else
			--print(string.format("update_text_object time: %f", (ElapsedTime - start_time)))
			--local start_time = ElapsedTime

			local t_x, t_y = Region.inverse_transform(instance.id, 0, 0)
			local text_h = Text.get_height()
			local top = t_y - text_h * 2
			local bottom = t_y + instance.h + text_h * 2
			local h = #instance.lines * text_h
			local top_line_no = max(floor((top / h) * #instance.lines), 1)
			local bottom_line_no = min(floor((bottom / h) * #instance.lines), #instance.lines)

			local index = 1
			local end_index = 1
			for i = 1, bottom_line_no, 1 do
				local count = len(instance.lines[i])
				if i < top_line_no then
					index = index + count
				end

				end_index = end_index + count
			end

			if index > 1 then
				insert(colored_text, base_color)
				insert(colored_text, sub(instance.text, 1, index - 1))
			end

			while index < end_index do
				local match_index = nil
				local key = nil
				for k, v in pairs(highlight) do
					local found = nil
					local anchor = index
					repeat
						found = find(instance.text, k, anchor, true)

						if found ~= nil then
							local found_end = found + len(k)
							local prev = sub(instance.text, found - 1, found - 1)
							local next = sub(instance.text, found_end, found_end)

							if found == 1 then
								prev = nil
							end

							if found_end > len(instance.text) then
								next = nil
							end

							if not (is_highlight_terminator(prev) and is_highlight_terminator(next)) then
								anchor = found + 1
								found = nil
							end
						else
							break
						end
					until found ~= nil

					if found ~= nil then
						if match_index == nil then
							match_index = found
							key = k
						elseif found < match_index then
							match_index = found
							key = k
						end
					end
				end

				if key ~= nil then
					insert(colored_text, base_color)
					insert(colored_text, sub(instance.text, index, match_index - 1))

					insert(colored_text, highlight[key])
					insert(colored_text, key)

					index = match_index + len(key)
				else
					insert(colored_text, base_color)
					insert(colored_text, sub(instance.text, index, end_index))
					index = end_index
					break
				end
			end

			if index < len(instance.text) then
				insert(colored_text, base_color)
				insert(colored_text, sub(instance.text, index))
			end
		end

		if #colored_text == 0 then
			colored_text = {base_color, instance.text}
		end

		instance.text_object:setf(colored_text, width, align)
	end
end

local function update_slider(instance, precision)
	if instance ~= nil then
		local mouse_x, mouse_y = Mouse.position()
		local min_x = Cursor.get_position()
		local max_x = min_x + instance.w
		local ratio = Utility.clamp((mouse_x - min_x) / (max_x - min_x), 0.0, 1.0)
		local min_val = instance.min_number == nil and -huge or instance.min_number
		local max_val = instance.max_number == nil and huge or instance.max_number
		local value = (max_val - min_val) * ratio + min_val
		if precision > 0 then
			instance.text = string.format("%." .. precision .. "f", value)
		else
			instance.text = string.format("%d", value)
		end
		validate_number(instance)
	end
end

local function update_drag(instance, step)
	if instance ~= nil then
		local delta_x, delta_y = Mouse.get_delta()
		if delta_x ~= 0.0 then
			-- The drag threshold will be calculated dynamically. This is achieved by taking the active monitor
			-- width and dividing by the allowable range. The DPI scale is taken into account as well. The
			-- threshold is clamped at 10 to prevent large requirements for drag effect.
			local dpi_scale = love.window.getDPIScale()
			local width, height, Flags = love.window.getMode()
			local desktop_width, desktop_height = love.window.getDesktopDimensions(Flags.display)
			local min_val = instance.min_number or -huge
			local max_val = instance.max_number or huge
			local diff = (max_val - min_val) / step
			local drag_threshold = 1.0

			if diff > 0 then
				drag_threshold = floor(desktop_width / diff) / dpi_scale
				drag_threshold = Utility.clamp(drag_threshold, 1, 10)
			end

			drag_delta = drag_delta + delta_x
			if abs(drag_delta) > drag_threshold then
				drag_delta = 0
				local value = tonumber(instance.text)
				if value ~= nil then
					value = value + step * (delta_x < 0 and -1 or 1)
					instance.text = tostring(value)
					validate_number(instance)
				end
			end
		end
	end
end

local function draw_slider(instance)
	if instance ~= nil and instance.numbers_only then
		local value = tonumber(instance.text)
		if value ~= nil then
			local min_val = instance.min_number == nil and -huge or instance.min_number
			local max_val = instance.max_number == nil and huge or instance.max_number
			local ratio = (value - min_val) / (max_val - min_val)
			local SliderSize = 6.0
			local min_x, min_y = Cursor.get_position()
			local max_x, max_y = min_x + instance.w - SliderSize, min_y + instance.h
			local x = (max_x - min_x) * ratio + min_x
			DrawCommands.rectangle("fill", x, min_y + 1.0, SliderSize, instance.h - 2.0, Style.InputSliderColor)
		end
	end
end

local function get_instance(id)
	for i, v in ipairs(instances) do
		if v.id == id then
			return v
		end
	end
	local instance = {}
	instance.id = id
	instance.text = ""
	instance.text_changed = false
	instance.numbers_only = true
	instance.read_only = false
	instance.align = "left"
	instance.min_number = nil
	instance.max_number = nil
	instance.lines = nil
	instance.text_object = nil
	instance.highlight = nil
	instance.should_update_text_object = false
	insert(instances, instance)
	return instance
end

function Input.begin(id, options)
	assert(id ~= nil, "Please pass a valid id into Slab.input.")

	local stat_handle = Stats.begin("Input", "Slab")

	options = options == nil and {} or options
	options.tooltip = options.tooltip == nil and "" or options.tooltip
	options.return_on_text = options.return_on_text == nil and true or options.return_on_text
	options.text = options.text == nil and "" or tostring(options.text)
	options.text_color = options.text_color == nil and nil or options.text_color
	options.bg_color = options.bg_color == nil and Style.input_bg_color or options.bg_color
	options.select_color = options.select_color == nil and Style.InputSelectColor or options.select_color
	options.select_on_focus = options.select_on_focus == nil and true or options.select_on_focus
	options.w = options.w == nil and nil or options.w
	options.h = options.h == nil and nil or options.h
	options.read_only = options.read_only == nil and false or options.read_only
	options.align = options.align == nil and nil or options.align
	options.rounding = options.rounding == nil and Style.InputBgRounding or options.rounding
	options.min_number = options.min_number == nil and nil or options.min_number
	options.max_number = options.max_number == nil and nil or options.max_number
	options.multi_line = options.multi_line == nil and false or options.multi_line
	options.multi_line_w = options.multi_line_w == nil and huge or options.multi_line_w
	options.highlight = options.highlight == nil and nil or options.highlight
	options.step = options.step == nil and 1.0 or options.step
	options.no_drag = options.no_drag == nil and false or options.no_drag
	options.use_slider = options.use_slider == nil and false or options.use_slider
	options.precision = options.precision == nil and 3 or math.floor(Utility.clamp(options.precision, 0, 5))

	if type(options.min_number) ~= "number" then
		options.min_number = nil
	end

	if type(options.max_number) ~= "number" then
		options.max_number = nil
	end

	if options.multi_line then
		options.text_color = Style.MultilineTextColor
	end

	local instance = get_instance(Window.get_id() .. "." .. id)
	instance.numbers_only = options.numbers_only
	instance.read_only = options.read_only
	instance.align = options.align
	instance.min_number = options.min_number
	instance.max_number = options.max_number
	instance.multi_line = options.multi_line

	if instance.multi_line_w ~= options.multi_line_w then
		instance.lines = nil
	end

	instance.multi_line_w = options.multi_line_w
	local win_item_id = Window.get_item_id(id)

	if instance.align == nil then
		instance.align = (instance == focused and not is_sliding) and "left" or "center"

		if instance.read_only then
			instance.align = "center"
		end

		if options.multi_line then
			instance.align = "left"
		end
	end

	if focused ~= instance then
		if options.multi_line and #options.text ~= #instance.text then
			instance.lines = nil
		end

		instance.text = options.text == nil and instance.text or options.text
	end

	if instance.min_number ~= nil and instance.max_number ~= nil then
		assert(
			instance.min_number <= instance.max_number,
			"Invalid min_number and max_number passed to Input control '" ..
				instance.id .. "'. min_number: " .. instance.min_number .. " max_number: " .. instance.max_number
		)
	end

	local h = options.h == nil and Text.get_height() or options.h
	local w = options.w == nil and MIN_WIDTH or options.w
	local content_w, content_h = 0.0, 0.0
	local result = false

	w, h = LayoutManager.compute_size(w, h)
	LayoutManager.add_control(w, h)

	instance.w = w
	instance.h = h

	local x, y = Cursor.get_position()

	if options.multi_line then
		options.select_on_focus = false
		local was_sanitized = false
		options.text, was_sanitized = sanitize_text(options.text)
		if was_sanitized then
			result = true
			last_text = options.text
		end

		content_w, content_h = Text.get_size_wrap(instance.text, options.multi_line_w)
	end

	local should_update_text_object = instance.should_update_text_object
	instance.should_update_text_object = false

	if instance.lines == nil and instance.text ~= "" then
		if options.multi_line then
			if instance.text_object == nil then
				instance.text_object = love.graphics.newText(Style.Font)
			end
			instance.lines = Text.get_lines(instance.text, options.multi_line_w)
			content_h = #instance.lines * Text.get_height()
			should_update_text_object = true
		end
	end

	if options.highlight ~= nil then
		if instance.highlight == nil or Utility.table_count(options.highlight) ~= Utility.table_count(instance.highlight) then
			instance.highlight = Utility.copy(options.highlight)
			should_update_text_object = true
		else
			for k, v in pairs(options.highlight) do
				local highlight_color = instance.highlight[k]
				if highlight_color ~= nil then
					if
						v[1] ~= highlight_color[1] or v[2] ~= highlight_color[2] or v[3] ~= highlight_color[3] or
							v[4] ~= highlight_color[4]
					 then
						should_update_text_object = true
						break
					end
				else
					instance.highlight = Utility.copy(options.highlight)
					should_update_text_object = true
					break
				end
			end
		end
	else
		if instance.highlight ~= nil then
			instance.highlight = nil
			should_update_text_object = true
		end
	end

	if should_update_text_object then
		update_text_object(instance, options.multi_line_w, instance.align, options.highlight, options.text_color)
	end

	local is_obstructed = Window.is_obstructed_at_mouse()
	local mouse_x, mouse_y = Window.get_mouse_position()
	local hovered = not is_obstructed and x <= mouse_x and mouse_x <= x + w and y <= mouse_y and mouse_y <= y + h
	local hovered_scroll_bar = Region.is_hover_scroll_bar(instance.id) or Region.is_scrolling()

	if hovered and not hovered_scroll_bar then
		Mouse.set_cursor("ibeam")
		Tooltip.begin(options.tooltip)
		Window.set_hot_item(win_item_id)
	end

	local check_focus = Mouse.is_clicked(1) and not hovered_scroll_bar
	local numbers_only_entry = Mouse.is_double_clicked(1) and instance.numbers_only

	local focused_this_frame = false
	local clear_focus = false
	if check_focus then
		if hovered then
			focused_this_frame = focused ~= instance
			focused = instance
		elseif instance == focused then
			clear_focus = true
			focused = nil
		end
	end

	if focus_to_next and last_focused == nil then
		focused_this_frame = true
		focused = instance
		check_focus = true
		focus_to_next = false
		text_cursor_anchor = -1
		text_cursor_pos = 0
		text_cursor_pos_line = 0
		text_cursor_pos_line_number = 1
	end

	if last_focused == instance then
		last_focused = nil
	end

	local is_editing = instance == focused and not is_sliding

	if instance == focused then
		local back = false
		local ignore_back = false
		local should_delete = false
		local should_update_transform = false
		local previous_text_cursor_pos = text_cursor_pos

		if is_command_key_down() then
			if Keyboard.is_pressed("x") or Keyboard.is_pressed("c") then
				local selected = get_selection(instance)
				if selected ~= "" then
					love.system.setClipboardText(selected)
					should_delete = Keyboard.is_pressed("x")
				end
			end

			if Keyboard.is_pressed("v") then
				local text = love.system.getClipboardText()
				Input.text(text)
				text_cursor_pos = min(text_cursor_pos + #text - 1, #instance.text)
			end
		end

		if Keyboard.is_pressed("tab") then
			if options.multi_line then
				Input.text("\t")
			else
				last_focused = instance
				focus_to_next = true
			end
		end

		if Keyboard.is_pressed("backspace") then
			should_delete = true
			ignore_back = text_cursor_anchor ~= -1
		end

		if Keyboard.is_pressed("delete") then
			if text_cursor_anchor == -1 then
				local ch = get_character(instance.text, text_cursor_pos, true)
				if ch ~= nil then
					text_cursor_pos = text_cursor_pos + len(ch)
					should_delete = true
				end
			else
				ignore_back = true
				should_delete = true
			end
		end

		if should_delete then
			if delete_selection(instance) then
				instance.text_changed = true
			end
		end

		local clear_anchor = false
		local is_shift_down = Keyboard.is_down("lshift") or Keyboard.is_down("rshift")

		if Keyboard.is_pressed("lshift") or Keyboard.is_pressed("rshift") then
			if text_cursor_anchor == -1 then
				text_cursor_anchor = text_cursor_pos
			end
		end

		local home_pressed, end_pressed = false, false

		if is_home_pressed() then
			move_to_home(instance)
			should_update_transform = true
			home_pressed = true
		end

		if is_end_pressed() then
			move_to_end(instance)
			should_update_transform = true
			end_pressed = true
		end

		if not home_pressed and (Keyboard.is_pressed("left") or back) then
			text_cursor_pos = get_next_cursor_pos(instance, true)
			should_update_transform = true
			update_multi_line_position(instance)
		end
		if not end_pressed and Keyboard.is_pressed("right") then
			text_cursor_pos = get_next_cursor_pos(instance, false)
			should_update_transform = true
			update_multi_line_position(instance)
		end

		if Keyboard.is_pressed("up") then
			move_cursor_vertical(instance, false)
			should_update_transform = true
		end
		if Keyboard.is_pressed("down") then
			move_cursor_vertical(instance, true)
			should_update_transform = true
		end

		if Keyboard.is_pressed("pageup") then
			move_cursor_page(instance, false)
			should_update_transform = true
		end
		if Keyboard.is_pressed("pagedown") then
			move_cursor_page(instance, true)
			should_update_transform = true
		end

		if check_focus or drag_select then
			if focused_this_frame then
				if options.numbers_only and not numbers_only_entry and not options.no_drag then
					is_sliding = true
					drag_delta = 0
				elseif options.select_on_focus and instance.text ~= "" then
					text_cursor_anchor = 0
					text_cursor_pos = #instance.text
				end

				-- Display the soft keyboard on mobile devices when an input control receives focus.
				if Utility.is_mobile() and not options.read_only then
					-- Always display for non numeric controls. If this control is a numeric input, check to make
					-- sure the user requested to add text for this numeric control.
					if not options.numbers_only or numbers_only_entry or options.no_drag then
						love.keyboard.setTextInput(true)
					end
				end
			else
				local mouse_input_x, mouse_input_y = mouse_x - x, mouse_y - y
				local c_x, c_y = Region.inverse_transform(instance.id, mouse_input_x, mouse_input_y)
				text_cursor_pos = get_text_cursor_pos(instance, c_x, c_y)
				if Mouse.is_clicked(1) then
					text_cursor_anchor = text_cursor_pos
					drag_select = true
				end
				should_update_transform = true
				is_shift_down = true
			end
			update_multi_line_position(instance)
		end

		if is_sliding then
			local current = tonumber(instance.text)

			if options.use_slider then
				update_slider(instance, options.precision)
			else
				update_drag(instance, options.step)
			end

			instance.text_changed = current ~= tonumber(instance.text)
		end

		if Mouse.is_released(1) then
			drag_select = false
			if text_cursor_anchor == text_cursor_pos then
				text_cursor_anchor = -1
			end

			if is_sliding then
				is_sliding = false
				focused = nil
				result = true
				last_text = instance.text
			end
		end

		if Mouse.is_double_clicked(1) then
			local mouse_input_x, mouse_input_y = mouse_x - x, mouse_y - y
			local c_x, c_y = Region.inverse_transform(instance.id, mouse_input_x, mouse_input_y)
			text_cursor_pos = get_text_cursor_pos(instance, c_x, c_y)
			select_word(instance)
			drag_select = false
		end

		if Keyboard.is_pressed("return") then
			result = true
			if options.multi_line then
				Input.text("\n")
			else
				clear_focus = true
			end
		end

		if instance.text_changed or back then
			if options.return_on_text then
				result = true
			end

			if options.multi_line then
				instance.lines = Text.get_lines(instance.text, options.multi_line_w)
				update_text_object(instance, options.multi_line_w, instance.align, options.highlight, options.text_color)
			end

			update_multi_line_position(instance)

			instance.text_changed = false
			previous_text_cursor_pos = -1
		end

		if should_update_transform then
			clear_anchor = not is_shift_down
			update_transform(instance)
		end

		if clear_anchor then
			text_cursor_anchor = -1
		end
	else
		local was_validated = validate_number(instance)
		if was_validated then
			result = true
			last_text = instance.text
		end
	end

	if Region.is_scrolling(instance.id) then
		local delta_x, delta_y = Mouse.get_delta()
		local wheel_x, wheel_y = Region.get_wheel_delta()

		if delta_y ~= 0.0 or wheel_y ~= 0.0 then
			instance.should_update_text_object = true
		end
	end

	if (instance == focused and not instance.read_only) or options.multi_line then
		options.bg_color = Style.InputEditBgColor
	end

	local t_x, t_y = Window.transform_point(x, y)
	Region.begin(
		instance.id,
		{
			x = x,
			y = y,
			w = w,
			h = h,
			content_w = content_w + pad,
			content_h = content_h + pad,
			bg_color = options.bg_color,
			s_x = t_x,
			s_y = t_y,
			mouse_x = mouse_x,
			mouse_y = mouse_y,
			intersect = true,
			ignore_scroll = not options.multi_line,
			rounding = options.rounding,
			is_obstructed = is_obstructed,
			auto_size_content = false
		}
	)
	if instance == focused then
		if not is_sliding then
			draw_selection(instance, x, y, w, h, options.select_color)
			draw_cursor(instance, x, y, w, h)
		end
	end

	if options.use_slider then
		if not is_editing then
			draw_slider(instance)
		end
	end

	if instance.text ~= "" then
		Cursor.set_position(x + get_alignment_offset(instance), y)

		LayoutManager.begin("ignore", {ignore = true})
		if instance.text_object ~= nil then
			Text.begin_object(instance.text_object)
		else
			Text.begin(instance.text, {add_item = false, colour = options.text_color})
		end
		LayoutManager.finish()
	end
	Region.finish()
	Region.apply_scissor()

	Cursor.set_item_bounds(x, y, w, h)
	Cursor.set_position(x, y)
	Cursor.advance_x(w)
	Cursor.advance_y(h)

	Window.add_item(x, y, w, h, win_item_id)

	if clear_focus then
		validate_number(instance)
		last_text = instance.text
		focused = nil

		if not options.multi_line then
			Region.reset_transform(instance.id)
		end

		-- close the soft keyboard on mobile platforms when an input control loses focus.
		if Utility.is_mobile() then
			love.keyboard.setTextInput(false)
		end
	end

	Stats.finish(stat_handle)

	return result
end

function Input.text(ch)
	if focused ~= nil and not focused.read_only then
		if not is_valid_digit(focused, ch) then
			return
		end

		if text_cursor_anchor ~= -1 then
			delete_selection(focused)
		end

		if text_cursor_pos == 0 then
			focused.text = ch .. focused.text
		else
			local Temp = focused.text
			local left = sub(Temp, 0, text_cursor_pos)
			local right = sub(Temp, text_cursor_pos + 1)
			focused.text = left .. ch .. right
		end

		text_cursor_pos = min(text_cursor_pos + len(ch), len(focused.text))
		text_cursor_anchor = -1
		update_transform(focused)
		focused.text_changed = true
	end
end

function Input.update(dt)
	local delta = dt * 2.0
	if fade_in then
		text_cursor_alpha = min(text_cursor_alpha + delta, 1.0)
		fade_in = text_cursor_alpha < 1.0
	else
		text_cursor_alpha = max(text_cursor_alpha - delta, 0.0)
		fade_in = text_cursor_alpha == 0.0
	end

	if pending_focus ~= nil then
		last_focused = focused
		focused = pending_focus
		pending_focus = nil
	end

	if focused ~= nil then
		if pending_cursor_pos >= 0 then
			text_cursor_pos = min(pending_cursor_pos, #focused.text)
			validate_text_cursor_pos(focused)
			update_multi_line_position(focused)
			pending_cursor_pos = -1
		end

		local multi_line_changed = false

		if pending_cursor_column >= 0 then
			if focused.lines ~= nil then
				text_cursor_pos_line = pending_cursor_column
				multi_line_changed = true
			end

			pending_cursor_column = -1
		end

		if pending_cursor_line > 0 then
			if focused.lines ~= nil then
				text_cursor_pos_line_number = min(pending_cursor_line, #focused.lines)
				multi_line_changed = true
			end

			pending_cursor_line = 0
		end

		if multi_line_changed then
			local line = focused.lines[text_cursor_pos_line_number]
			text_cursor_pos_line = min(text_cursor_pos_line, len(line))
			local start = 0
			for i, v in ipairs(focused.lines) do
				if i == text_cursor_pos_line_number then
					text_cursor_pos = start + text_cursor_pos_line
					break
				end
				start = start + len(v)
			end
			validate_text_cursor_pos(focused)
		end
	else
		pending_cursor_pos = -1
		pending_cursor_column = -1
		pending_cursor_line = 0
	end
end

function Input.get_text()
	if focused ~= nil then
		if focused.numbers_only and (focused.text == "" or focused.text == ".") then
			return "0"
		end
		return focused.text
	end
	return last_text
end

function Input.get_cursor_pos()
	if focused ~= nil then
		return text_cursor_pos, text_cursor_pos_line, text_cursor_pos_line_number
	end

	return 0, 0, 0
end

function Input.is_any_focused()
	return focused ~= nil
end

function Input.is_focused(id)
	local instance = get_instance(Window.get_id() .. "." .. id)
	return instance == focused
end

function Input.set_focused(id)
	if id == nil then
		focused = nil
		pending_focus = nil
		return
	end

	local instance = get_instance(Window.get_id() .. "." .. id)
	pending_focus = instance
end

function Input.set_cursor_pos(pos)
	pending_cursor_pos = max(pos, 0)
end

function Input.set_cursor_pos_line(column, line)
	if column ~= nil then
		pending_cursor_column = max(column, 0)
	end

	if line ~= nil then
		pending_cursor_line = max(line, 1)
	end
end

function Input.get_debug_info()
	local info = {}
	local x, y = get_cursor_pos(focused)

	if focused ~= nil then
		Region.inverse_transform(focused.id, x, y)
	end

	info["focused"] = focused ~= nil and focused.id or "nil"
	info["width"] = focused ~= nil and focused.w or 0
	info["height"] = focused ~= nil and focused.h or 0
	info["cursor_x"] = x
	info["cursor_y"] = y
	info["cursor_pos"] = text_cursor_pos
	info["Character"] = focused ~= nil and get_display_character(focused.text, text_cursor_pos) or ""
	info["LineCursorPos"] = text_cursor_pos_line
	info["LineCursorPosMax"] = text_cursor_pos_line_max
	info["line_number"] = text_cursor_pos_line_number
	info["LineLength"] = (focused ~= nil and focused.lines ~= nil) and len(focused.lines[text_cursor_pos_line_number]) or 0
	info["Lines"] = focused ~= nil and focused.lines or nil

	return info
end

return Input
