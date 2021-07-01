local insert = table.insert
local remove = table.remove
local max = math.max
local min = math.min

local Cursor = required("Cursor")
local Window = required("Window")

local LayoutManager = {}

local instances = {}
local stack = {}
local active = nil

local function get_window_bounds()
	local win_x, win_y, win_w, win_h = Window.get_bounds(true)
	local border = Window.get_border()

	win_x = win_x + border
	win_y = win_y + border
	win_w = win_w - border * 2
	win_h = win_h - border * 2

	return win_x, win_y, win_w, win_h
end

local function get_row_size(instance)
	if instance ~= nil then
		local column = instance.columns[instance.column_no]

		if column.rows ~= nil then
			local row = column.rows[column.row_no]

			if row ~= nil then
				return row.w, row.h
			end
		end
	end

	return 0, 0
end

local function get_row_cursor_pos(instance)
	if instance ~= nil then
		local column = instance.columns[instance.column_no]

		if column.rows ~= nil then
			local row = column.rows[column.row_no]

			if row ~= nil then
				return row.cursor_x, row.cursor_y
			end
		end
	end

	return nil, nil
end

local function get_layout_h(instance, include_pad)
	include_pad = include_pad == nil and true or include_pad

	if instance ~= nil then
		local column = instance.columns[instance.column_no]

		if column.rows ~= nil then
			local h = 0

			for i, v in ipairs(column.rows) do
				h = h + v.h

				if include_pad then
					h = h + Cursor.pad_y()
				end
			end

			return h
		end
	end

	return 0
end

local function get_previous_row_bottom(instance)
	if instance ~= nil then
		local column = instance.columns[instance.column_no]

		if column.rows ~= nil and column.row_no > 1 and column.row_no <= #column.rows then
			local y = column.rows[column.row_no - 1].cursor_y
			local h = column.rows[column.row_no - 1].h
			return y + h
		end
	end

	return nil
end

local function get_column_position(instance)
	if instance ~= nil then
		local win_x, win_y, win_w, win_h = get_window_bounds()
		local win_l, win_t = Window.get_position()
		local count = #instance.columns
		local column_w = win_w / count
		local total_w = 0

		for i = 1, instance.column_no - 1, 1 do
			local column = instance.columns[i]
			total_w = total_w + column.w
		end

		local anchor_x, anchor_y = instance.x, instance.y

		if not instance.anchor_x then
			anchor_x = win_x - win_l - Window.get_border()
		end

		if not instance.anchor_y then
			anchor_y = win_y - win_t - Window.get_border()
		end

		return anchor_x + total_w, anchor_y
	end

	return 0, 0
end

local function get_column_size(instance)
	if instance ~= nil then
		local column = instance.columns[instance.column_no]
		local win_x, win_y, win_w, win_h = get_window_bounds()
		local count = #instance.columns
		local column_w = win_w / count
		local w, h = 0, get_layout_h(instance)

		if not Window.is_auto_size() then
			w = column_w
			h = win_h
			column.w = w
		else
			w = max(column.w, column_w)
		end

		return w, h
	end

	return 0, 0
end

local function add_control(instance, w, h, t)
	if instance ~= nil then
		local row_w, row_h = get_row_size(instance)
		local win_x, win_y, win_w, win_h = get_window_bounds()
		local cursor_x, cursor_y = Cursor.get_position()
		local x, y = get_row_cursor_pos(instance)
		local layout_h = get_layout_h(instance)
		local prev_row_bottom = get_previous_row_bottom(instance)
		local anchor_x, anchor_y = get_column_position(instance)
		win_w, win_h = get_column_size(instance)
		local column = instance.columns[instance.column_no]

		if row_w == 0 then
			row_w = w
		end

		if row_h == 0 then
			row_h = h
		end

		if x == nil then
			if instance.align_x == "center" then
				x = max(win_w * 0.5 - row_w * 0.5 + anchor_x, anchor_x)
			elseif instance.align_x == "right" then
				local right = win_w - row_w
				if not Window.is_auto_size() then
					right = right + Window.get_border()
				end

				x = max(right, anchor_x)
			else
				x = anchor_x
			end
		end

		if y == nil then
			if prev_row_bottom ~= nil then
				y = prev_row_bottom + Cursor.pad_y()
			else
				local region_h = win_y + win_h - cursor_y
				if instance.align_y == "center" then
					y = max(region_h * 0.5 - layout_h * 0.5 + anchor_y, anchor_y)
				elseif instance.align_y == "Bottom" then
					y = max(win_h - layout_h, anchor_y)
				else
					y = anchor_y
				end
			end
		end

		Cursor.set_x(win_x + x)
		Cursor.set_y(win_y + y)

		if h < row_h then
			if instance.align_row_y == "center" then
				Cursor.set_y(win_y + y + row_h * 0.5 - h * 0.5)
			elseif instance.align_row_y == "Bottom" then
				Cursor.set_y(win_y + y + row_h - h)
			end
		end

		local row_no = column.row_no

		if column.rows ~= nil then
			local row = column.rows[row_no]

			if row ~= nil then
				row.cursor_x = x + w + Cursor.pad_x()
				row.cursor_y = y
			end
		end

		if column.pending_rows[row_no] == nil then
			local row = {
				cursor_x = nil,
				cursor_y = nil,
				w = 0,
				h = 0,
				request_h = 0,
				max_h = 0,
				controls = {}
			}
			insert(column.pending_rows, row)
		end

		local row = column.pending_rows[row_no]

		insert(
			row.controls,
			{
				x = Cursor.get_x(),
				y = Cursor.get_y(),
				w = w,
				h = h,
				altered_size = column.altered_size,
				t = t
			}
		)
		row.w = row.w + w + Cursor.pad_x()
		row.h = max(row.h, h)

		column.row_no = row_no + 1
		column.altered_size = false
		column.w = max(row.w, column.w)
	end
end

local function get_instance(id)
	local key = Window.get_id() .. "." .. id

	if instances[key] == nil then
		local instance = {}
		instance.id = id
		instance.window_id = Window.get_id()
		instance.align_x = "left"
		instance.align_y = "top"
		instance.align_row_y = "top"
		instance.ignore = false
		instance.expand_w = false
		instance.x = 0
		instance.y = 0
		instance.columns = {}
		instance.column_no = 1
		instances[key] = instance
	end

	return instances[key]
end

function LayoutManager.add_control(w, h, t)
	if active ~= nil and not active.ignore then
		add_control(active, w, h)
	end
end

function LayoutManager.compute_size(w, h)
	if active ~= nil then
		local x, y = get_column_position(active)
		local win_w, win_h = get_column_size(active)
		local real_w = win_w - x
		local real_h = win_h - y
		local column = active.columns[active.column_no]

		if not active.anchor_x then
			real_w = win_w
		end

		if not active.anchor_y then
			real_h = win_h
		end

		if Window.is_auto_size() then
			local layout_h = get_layout_h(active, false)

			if layout_h > 0 then
				real_h = layout_h
			end
		end

		if active.expand_w then
			if column.rows ~= nil then
				local count = 0
				local reduce_w = 0
				local pad = 0
				local row = column.rows[column.row_no]
				if row ~= nil then
					for i, v in ipairs(row.controls) do
						if v.altered_size then
							count = count + 1
						else
							reduce_w = reduce_w + v.w
						end
					end

					if #row.controls > 1 then
						pad = Cursor.pad_x() * (#row.controls - 1)
					end
				end

				count = max(count, 1)

				w = (real_w - reduce_w - pad) / count
			end
		end

		if active.expand_h then
			if column.rows ~= nil then
				local count = 0
				local reduce_h = 0
				local pad = 0
				local max_row_h = 0
				for i, row in ipairs(column.rows) do
					local is_size_altered = false

					if i == column.row_no then
						max_row_h = row.max_h
						row.request_h = max(row.request_h, h)
					end

					for j, control in ipairs(row.controls) do
						if control.altered_size then
							if not is_size_altered then
								count = count + 1
								is_size_altered = true
							end
						end
					end

					if not is_size_altered then
						reduce_h = reduce_h + row.h
					end
				end

				if #column.rows > 1 then
					pad = Cursor.pad_y() * (#column.rows - 1)
				end

				count = max(count, 1)

				real_h = max(real_h - reduce_h - pad, 0)
				h = max(real_h / count, h)
				h = max(h, max_row_h)
			end
		end

		column.altered_size = active.expand_w or active.expand_h
	end

	return w, h
end

function LayoutManager.begin(id, options)
	assert(id ~= nil or type(id) ~= string, "a valid string id must be given to begin_layout!")

	options = options == nil and {} or options
	options.align_x = options.align_x == nil and "left" or options.align_x
	options.align_y = options.align_y == nil and "top" or options.align_y
	options.align_row_y = options.align_row_y == nil and "top" or options.align_row_y
	options.ignore = options.ignore == nil and false or options.ignore
	options.expand_w = options.expand_w == nil and false or options.expand_w
	options.expand_h = options.expand_h == nil and false or options.expand_h
	options.anchor_x = options.anchor_x == nil and false or options.anchor_x
	options.anchor_y = options.anchor_y == nil and true or options.anchor_y
	options.columns = options.columns == nil and 1 or options.columns

	options.columns = max(options.columns, 1)

	local instance = get_instance(id)
	instance.align_x = options.align_x
	instance.align_y = options.align_y
	instance.align_row_y = options.align_row_y
	instance.ignore = options.ignore
	instance.expand_w = options.expand_w
	instance.expand_h = options.expand_h
	instance.x, instance.y = Cursor.get_relative_position()
	instance.anchor_x = options.anchor_x
	instance.anchor_y = options.anchor_y

	if options.columns ~= #instance.columns then
		instance.columns = {}
		for i = 1, options.columns, 1 do
			local column = {
				rows = nil,
				pending_rows = {},
				row_no = 1,
				w = 0
			}

			insert(instance.columns, column)
		end
	end

	for i, column in ipairs(instance.columns) do
		column.pending_rows = {}
		column.row_no = 1
	end

	insert(stack, 1, instance)
	active = instance
end

function LayoutManager.finish()
	assert(active ~= nil, "LayoutManager.finish was called without a call to LayoutManager.begin!")

	for i, column in ipairs(active.columns) do
		local rows = column.rows
		column.rows = column.pending_rows
		column.pending_rows = nil

		if rows ~= nil and column.rows ~= nil and #rows == #column.rows then
			for i, v in ipairs(rows) do
				column.rows[i].max_h = rows[i].request_h
			end
		end
	end

	remove(stack, 1)
	active = nil

	if #stack > 0 then
		active = stack[1]
	end
end

function LayoutManager.same_line(cursor_options)
	Cursor.same_line(cursor_options)
	if active ~= nil then
		local column = active.columns[active.column_no]
		column.row_no = max(column.row_no - 1, 1)
	end
end

function LayoutManager.new_line()
	if active ~= nil then
		add_control(active, 0, Cursor.get_new_line_size(), "new_line")
	end
	Cursor.new_line()
end

function LayoutManager.set_column(index)
	if active ~= nil then
		index = max(index, 1)
		index = min(index, #active.columns)
		active.column_no = index
	end
end

function LayoutManager.get_active_size()
	if active ~= nil then
		return get_column_size(active)
	end

	return 0, 0
end

function LayoutManager.validate()
	local message = nil

	for i, v in ipairs(stack) do
		if message == nil then
			message = "The following layouts have not had end_layout called:\n"
		end

		message = message .. "'" .. v.id .. "' in window '" .. v.window_id .. "'\n"
	end

	assert(message == nil, message)
end

return LayoutManager
