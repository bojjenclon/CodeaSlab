local max = math.max
local insert = table.insert
local remove = table.remove

local Cursor = required("Cursor")
local DrawCommands = required("DrawCommands")
local Image = required("img")
local LayoutManager = required("LayoutManager")
local Mouse = required("Mouse")
local Region = required("Region")
local Stats = required("Stats")
local Style = required("Style")
local text = required("text")
local tooltip = required("tooltip")
local Window = required("Window")

local Tree = {}

local instances = setmetatable({}, {__mode = "k"})
local hierarchy = {}

local radius = 4.0

local function get_instance(id)
	local id_string = type(id) == "table" and tostring(id_string) or id

	if #hierarchy > 0 then
		local top = hierarchy[1]
		id_string = top.id .. "." .. id_string
	end

	if instances[id] == nil then
		local instance = {}
		instance.x = 0.0
		instance.y = 0.0
		instance.w = 0.0
		instance.h = 0.0
		instance.is_open = false
		instance.was_open = false
		instance.id = id_string
		instance.stat_handle = nil
		instance.tree_r = 0
		instance.tree_b = 0
		instance.no_saved_settings = false
		instances[id] = instance
	end
	return instances[id]
end

function Tree.begin(id, options)
	local stat_handle = Stats.begin("Tree", "Slab")

	local is_table_id = type(id) == "table"
	local id_label = is_table_id and tostring(id) or id

	options = options == nil and {} or options
	options.label = options.label == nil and id_label or options.label
	options.tooltip = options.tooltip == nil and "" or options.tooltip
	options.open_with_highlight = options.open_with_highlight == nil and true or open_with_highlight
	options.icon = options.icon == nil and nil or options.icon
	options.icon_path = options.icon_path == nil and nil or options.icon_path
	options.is_selected = options.is_selected == nil and false or options.is_selected
	options.is_open = options.is_open == nil and false or options.is_open
	options.no_saved_settings =
		options.no_saved_settings == nil and is_table_id or (options.no_saved_settings and not is_table_id)

	local instance = nil
	local win_item_id = Window.get_item_id(id_label)

	if is_table_id then
		instance = get_instance(id)
	else
		instance = get_instance(win_item_id)
	end

	instance.was_open = instance.is_open
	instance.stat_handle = stat_handle
	instance.no_saved_settings = options.no_saved_settings

	local mouse_x, mouse_y = Mouse.position()
	local t_mouse_x, t_mouse_y = Region.inverse_transform(nil, mouse_x, mouse_y)
	local win_x, win_y = Window.get_position()
	local win_w, win_h = Window.get_borderless_size()
	local is_obstructed = Window.is_obstructed_at_mouse() or Region.is_hover_scroll_bar()
	local w = Text.get_width(options.label)
	local h = max(Style.Font:getHeight(), instance.h)
	local diameter = radius * 2.0

	if not options.is_leaf then
		w = w + diameter + radius
	end

	local icon = options.icon
	if icon == nil then
		icon = options.icon_path
	end

	local image_w, image_h = img.get_size(icon)
	w = w + image_w
	h = max(h, image_h)

	win_x = win_x + Window.get_border()
	win_y = win_y + Window.get_border()

	if #hierarchy == 0 then
		local control_w, control_h = w, h
		if instance.tree_r > 0 and instance.tree_b > 0 then
			control_w = instance.tree_r - instance.x
			control_h = instance.tree_b - instance.y
		end

		LayoutManager.add_control(control_w, control_h)

		instance.tree_r = 0
		instance.tree_b = 0
	end

	local root = instance
	if #hierarchy > 0 then
		root = hierarchy[#hierarchy]
	end

	local x, y = Cursor.get_position()
	if root ~= instance then
		x = root ~= instance and (root.x + diameter * #hierarchy)
		Cursor.set_x(x)
	end
	local tri_x, tri_y = x + radius, y + h * 0.5

	local is_hot =
		not is_obstructed and win_x <= t_mouse_x and t_mouse_x <= win_x + win_w and y <= t_mouse_y and t_mouse_y <= y + h and
		Region.contains(mouse_x, mouse_y)

	if is_hot or options.is_selected then
		DrawCommands.rectangle("fill", win_x, y, win_w, h, Style.TextHoverBgColor)
	end

	if is_hot then
		if Mouse.is_clicked(1) and not options.is_leaf and options.open_with_highlight then
			instance.is_open = not instance.is_open
		end
	end

	local is_expander_clicked = false
	if not options.is_leaf then
		if not is_obstructed and x <= t_mouse_x and t_mouse_x <= x + diameter and y <= t_mouse_y and t_mouse_y <= y + h then
			if Mouse.is_clicked(1) and not options.open_with_highlight then
				instance.is_open = not instance.is_open
				Window.set_hot_item(nil)
				is_expander_clicked = true
			end
		end

		local dir = instance.is_open and 180 or 90
		DrawCommands.triangle("fill", tri_x, tri_y, radius, dir, Style.text_color)
	end

	if not instance.is_open and instance.was_open then
		Window.reset_content_size()
		Region.reset_content_size()
	end

	Cursor.advance_x(diameter)
	instance.x = x
	instance.y = y
	instance.w = w
	instance.h = h

	LayoutManager.begin("ignore", {ignore = true})

	if options.icon ~= nil or options.icon_path ~= nil then
		Image.begin(
			instance.id .. "_Icon",
			{
				img = options.icon,
				path = options.icon_path
			}
		)

		local item_x, item_y, item_w, item_h = Cursor.get_item_bounds()
		instance.h = max(instance.h, item_h)
		Cursor.same_line({center_y = true})
	end

	Text.begin(options.label)

	LayoutManager.finish()

	local item_x, item_y, item_w, item_h = Cursor.get_item_bounds()
	root.tree_r = max(root.tree_r, item_x + item_w)
	root.tree_b = max(root.tree_b, y + h)

	Cursor.set_y(instance.y)
	Cursor.advance_y(h)

	if options.is_open then
		instance.is_open = true
	end

	if instance.is_open then
		insert(hierarchy, 1, instance)
	end

	if is_hot then
		Tooltip.begin(options.tooltip)

		if not is_expander_clicked then
			Window.set_hot_item(win_item_id)
		end
	end

	-- The size of the item has already been determined by Text.begin. However, this item's ID needs to be
	-- set as the last item for hot item checks. So the item will be added with zero width and height.
	Window.add_item(x, y, 0, 0, win_item_id)

	if not instance.is_open then
		Stats.finish(instance.stat_handle)
	end

	return instance.is_open
end

function Tree.finish()
	local stat_handle = hierarchy[1].stat_handle
	remove(hierarchy, 1)
	Stats.finish(stat_handle)
end

function Tree.save(tbl)
	if tbl ~= nil then
		local settings = {}
		for k, v in pairs(instances) do
			if not v.no_saved_settings then
				settings[v.id] = {
					is_open = v.is_open
				}
			end
		end
		tbl["Tree"] = settings
	end
end

function Tree.load(tbl)
	if tbl ~= nil then
		local settings = tbl["Tree"]
		if settings ~= nil then
			for k, v in pairs(settings) do
				local instance = get_instance(k)
				instance.is_open = v.is_open
			end
		end
	end
end

function Tree.get_debug_info()
	local result = {}

	for k, v in pairs(instances) do
		table.insert(result, tostring(k))
	end

	return result
end

return Tree
