local insert = table.insert
local remove = table.remove
local min = math.min
local max = math.max
local floor = math.floor

local Button = required("button")
local ComboBox = required("ComboBox")
local Cursor = required("Cursor")
local FileSystem = required("FileSystem")
local Image = required("img")
local Input = required("Input")
local Keyboard = required("Keyboard")
local LayoutManager = required("LayoutManager")
local ListBox = required("ListBox")
local Mouse = required("Mouse")
local Region = required("Region")
local Style = required("Style")
local text = required("text")
local Tree = required("Tree")
local Utility = required("Utility")
local Window = required("Window")

local Dialog = {}

local instances = {}
local active_instance = nil
local stack = {}
local instance_stack = {}
local file_dialog_ask_overwrite = false
local filter_w = 0.0

local function validate_save_file(files, extension)
	if extension == nil or extension == "" then
		return
	end

	if files ~= nil and #files == 1 then
		local index = string.find(files[1], ".", 1, true)

		if index ~= nil then
			files[1] = string.sub(files[1], 1, index - 1)
		end

		files[1] = files[1] .. extension
	end
end

local function update_input_text(instance)
	if instance ~= nil then
		if #instance.rtn > 0 then
			instance.text = #instance.rtn > 1 and "<Multiple>" or instance.rtn[1]
		else
			instance.text = ""
		end
	end
end

local function prune_results(items, directory_only)
	local result = {}

	for i, v in ipairs(items) do
		if FileSystem.is_directory(v) then
			if directory_only then
				insert(result, v)
			end
		else
			if not directory_only then
				insert(result, v)
			end
		end
	end

	return result
end

local function open_directory(dir)
	if active_instance ~= nil and active_instance.directory ~= nil then
		active_instance.parsed = false
		if string.sub(dir, #dir, #dir) == FileSystem.separator() then
			dir = string.sub(dir, 1, #dir - 1)
		end
		active_instance.directory = FileSystem.sanitize(dir)
	end
end

local function file_dialog_item(id, label, is_directory, index)
	ListBox.begin_item(id, {selected = Utility.has_value(active_instance.selected, index)})

	if is_directory then
		Image.begin("FileDialog_Folder", {path = SLAB_FILE_PATH .. "/Internal/Resources/Textures/Folder.png"})
		Cursor.same_line({center_y = true})
	end

	Text.begin(label)

	if ListBox.is_item_clicked(1) then
		local set = true
		if active_instance.allow_multi_select then
			if Keyboard.is_down("lctrl") or Keyboard.is_down("rctrl") then
				set = false
				if Utility.has_value(active_instance.selected, index) then
					Utility.remove(active_instance.selected, index)
					Utility.remove(active_instance.rtn, active_instance.directory .. "/" .. label)
				else
					insert(active_instance.selected, index)
					insert(active_instance.rtn, active_instance.directory .. "/" .. label)
				end
			elseif Keyboard.is_down("lshift") or Keyboard.is_down("rshift") then
				if #active_instance.selected > 0 then
					set = false
					local anchor = active_instance.selected[#active_instance.selected]
					local min_val = min(anchor, index)
					local max_val = max(anchor, index)

					active_instance.selected = {}
					active_instance.rtn = {}
					for i = min_val, max_val, 1 do
						insert(active_instance.selected, i)
						if i > #active_instance.directories then
							i = i - #active_instance.directories
							insert(active_instance.rtn, active_instance.directory .. "/" .. active_instance.files[i])
						else
							insert(active_instance.rtn, active_instance.directory .. "/" .. active_instance.directories[i])
						end
					end
				end
			end
		end

		if set then
			active_instance.selected = {index}
			active_instance.rtn = {active_instance.directory .. "/" .. label}
		end

		update_input_text(active_instance)
	end

	local result = false

	if ListBox.is_item_clicked(1, true) then
		if is_directory then
			open_directory(active_instance.directory .. "/" .. label)
		else
			result = true
		end
	end

	ListBox.end_item()

	return result
end

local function add_directory_item(path)
	local separator = FileSystem.separator()
	local item = {}
	item.path = path
	item.name = FileSystem.get_base_name(path)
	item.name = item.name == "" and separator or item.name
	-- remove the starting slash for Unix style directories.
	if string.sub(item.name, 1, 1) == separator and item.name ~= separator then
		item.name = string.sub(item.name, 2)
	end
	item.children = nil
	return item
end

local function file_dialog_explorer(instance, root)
	if instance == nil then
		return
	end

	if root ~= nil then
		local should_open = Window.is_appearing() and string.find(instance.directory, root.path, 1, true) ~= nil

		local options = {
			label = root.name,
			open_with_highlight = false,
			is_selected = active_instance.directory == root.path,
			is_open = should_open
		}
		local is_open = Tree.begin(root.path, options)

		if Mouse.is_clicked(1) and Window.IsItemHot() then
			open_directory(root.path)
		end

		if is_open then
			if root.children == nil then
				root.children = {}

				local separator = FileSystem.separator()
				local directories = FileSystem.get_directory_items(root.path .. separator, {files = false})
				for i, v in ipairs(directories) do
					local path = root.path
					if string.sub(path, #path) ~= separator and path ~= separator then
						path = path .. separator
					end
					if string.sub(v, 1, 1) == separator then
						v = string.sub(v, 2)
					end
					local item = add_directory_item(path .. FileSystem.get_base_name(v))
					insert(root.children, item)
				end
			end

			for i, v in ipairs(root.children) do
				file_dialog_explorer(instance, v)
			end

			Tree.finish()
		end
	end
end

local function get_filter(instance, index)
	local filter = "*.*"
	local desc = "All files"
	if instance ~= nil and #instance.filters > 0 then
		if index == nil then
			index = instance.selected_filter
		end

		local item = instance.filters[index]
		if item ~= nil then
			if type(item) == "table" then
				if #item == 1 then
					filter = item[1]
					desc = ""
				elseif #item == 2 then
					filter = item[1]
					desc = item[2]
				end
			else
				filter = tostring(item)
				desc = ""
			end
		end
	end

	return filter, desc
end

local function get_extension(instance)
	local filter, desc = get_filter(instance)
	local result = ""

	if filter ~= "*.*" then
		local index = string.find(filter, ".", 1, true)

		if index ~= nil then
			result = string.sub(filter, index)
		end
	end

	return result
end

local function is_instance_open(id)
	local instance = instances[id]
	if instance ~= nil then
		return instance.is_open
	end
	return false
end

local function get_instance(id)
	if instances[id] == nil then
		local instance = {}
		instance.id = id
		instance.is_open = false
		instance.opening = false
		instance.w = 0.0
		instance.h = 0.0
		instances[id] = instance
	end
	return instances[id]
end

function Dialog.begin(id, options)
	local instance = get_instance(id)
	if not instance.is_open then
		return false
	end

	options = options == nil and {} or options
	options.x = floor(WIDTH * 0.5 - instance.w * 0.5)
	options.y = floor(HEIGHT * 0.5 - instance.h * 0.5)
	options.layer = "Dialog"
	options.allow_focus = false
	options.allow_move = false
	options.auto_size_window = options.auto_size_window == nil and true or options.auto_size_window
	options.no_saved_settings = true

	Window.begin(instance.id, options)

	if instance.opening then
		Input.set_focused(nil)
		instance.opening = false
	end

	active_instance = instance
	insert(instance_stack, 1, active_instance)

	return true
end

function Dialog.finish()
	active_instance.w, active_instance.h = Window.get_size()
	Window.finish()

	active_instance = nil
	remove(instance_stack, 1)

	if #instance_stack > 0 then
		active_instance = instance_stack[1]
	end
end

function Dialog.open(id)
	local instance = get_instance(id)
	if not instance.is_open then
		instance.opening = true
		instance.is_open = true
		insert(stack, 1, instance)
		Window.set_stack_lock(instance.id)
		Window.push_to_top(instance.id)
	end
end

function Dialog.close()
	if active_instance ~= nil and active_instance.is_open then
		active_instance.is_open = false
		remove(stack, 1)
		Window.set_stack_lock(nil)

		if #stack > 0 then
			instance = stack[1]
			Window.set_stack_lock(instance.id)
			Window.push_to_top(instance.id)
		end
	end
end

function Dialog.is_open()
	return #stack > 0
end

function Dialog.message_box(title, message, options)
	local result = ""
	Dialog.open("message_box")
	if Dialog.begin("message_box", {title = title, border = 12}) then
		options = options == nil and {} or options
		options.buttons = options.buttons == nil and {"OK"} or options.buttons

		LayoutManager.begin("MessageBox_Message_Layout", {align_x = "center", align_y = "center"})
		LayoutManager.new_line()
		local text_w = min(Text.get_width(message), WIDTH * 0.80)
		Text.begin_formatted(message, {align = "center", w = text_w})
		LayoutManager.finish()

		Cursor.new_line()
		Cursor.new_line()

		LayoutManager.begin("MessageBox_Buttons_Layout", {align_x = "right", align_y = "Bottom"})
		for i, v in ipairs(options.buttons) do
			if Button.begin(v) then
				result = v
			end
			Cursor.same_line()
			LayoutManager.same_line()
		end
		LayoutManager.finish()

		if result ~= "" then
			Dialog.close()
		end

		Dialog.finish()
	end

	return result
end

function Dialog.file_dialog(options)
	options = options == nil and {} or options
	options.allow_multi_select = options.allow_multi_select == nil and true or options.allow_multi_select
	options.directory = options.directory == nil and nil or options.directory
	options.t = options.t == nil and "openfile" or options.t
	options.title = options.title == nil and nil or options.title
	options.filters = options.filters == nil and {{"*.*", "All files"}} or options.filters
	options.include_parent = options.include_parent == nil and true or options.include_parent

	if options.title == nil then
		options.title = "open File"

		if options.t == "savefile" then
			options.allow_multi_select = false
			options.title = "save File"
		elseif options.t == "opendirectory" then
			options.title = "open directory"
		end
	end

	local result = {button = "", files = {}}
	local was_open = is_instance_open("file_dialog")

	Dialog.open("file_dialog")
	local w = WIDTH * 0.65
	local h = HEIGHT * 0.65
	if
		Dialog.begin(
			"file_dialog",
			{
				title = options.title,
				auto_size_window = false,
				w = w,
				h = h,
				auto_size_content = false,
				allow_resize = false
			}
		)
	 then
		active_instance.allow_multi_select = options.allow_multi_select

		if not was_open then
			active_instance.text = ""
			if active_instance.directory == nil then
				active_instance.directory = love.filesystem.getSourceBaseDirectory()
			end

			if options.directory ~= nil and FileSystem.is_directory(options.directory) then
				active_instance.directory = options.directory
			end

			active_instance.filters = options.filters
			active_instance.selected_filter = 1
		end

		local clear = false
		if not active_instance.parsed then
			local filter = get_filter(active_instance)
			active_instance.root = add_directory_item(FileSystem.GetRootDirectory(active_instance.directory))
			active_instance.selected = {}
			active_instance.directories = FileSystem.get_directory_items(active_instance.directory .. "/", {files = false})
			active_instance.files =
				FileSystem.get_directory_items(active_instance.directory .. "/", {directories = false, filter = filter})
			active_instance.rtn = {active_instance.directory .. "/"}
			active_instance.text = ""
			active_instance.parsed = true

			update_input_text(active_instance)

			for i, v in ipairs(active_instance.directories) do
				active_instance.directories[i] = FileSystem.get_base_name(v)
			end

			for i, v in ipairs(active_instance.files) do
				active_instance.files[i] = FileSystem.get_base_name(v)
			end

			clear = true
		end

		local win_w, win_h = Window.get_size()
		local button_w, button_h = Button.get_size("OK")
		local explorer_w = 150.0
		local list_h = win_h - Text.get_height() - button_h * 3.0 - Cursor.pad_y() * 2.0
		local prev_anchor_x = Cursor.get_anchor_x()

		Text.begin(active_instance.directory)

		local cursor_x, cursor_y = Cursor.get_position()
		local mouse_x, mouse_y = Window.get_mouse_position()
		Region.begin(
			"FileDialog_DirectoryExplorer",
			{
				x = cursor_x,
				y = cursor_y,
				w = explorer_w,
				h = list_h,
				auto_size_content = true,
				no_background = true,
				intersect = true,
				mouse_x = mouse_x,
				mouse_y = mouse_y,
				is_obstructed = Window.is_obstructed_at_mouse(),
				rounding = Style.WindowRounding
			}
		)

		Cursor.advance_x(0.0)
		Cursor.set_anchor_x(Cursor.get_x())

		file_dialog_explorer(active_instance, active_instance.root)

		Region.finish()
		Region.apply_scissor()
		Cursor.advance_x(explorer_w + 4.0)
		Cursor.set_y(cursor_y)

		LayoutManager.begin("FileDialog_ListBox_Expand", {anchor_x = true, expand_w = true})
		ListBox.begin("FileDialog_ListBox", {h = list_h, clear = clear})

		local index = 1
		local item_selected = false
		if options.include_parent then
			if file_dialog_item("Item_Parent", "..", true, index) then
				item_selected = true
			end

			index = index + 1
		end

		for i, v in ipairs(active_instance.directories) do
			file_dialog_item("Item_" .. index, v, true, index)
			index = index + 1
		end
		if options.t ~= "opendirectory" then
			for i, v in ipairs(active_instance.files) do
				if file_dialog_item("Item_" .. index, v, false, index) then
					item_selected = true
				end
				index = index + 1
			end
		end
		ListBox.finish()
		LayoutManager.finish()

		local list_box_x, list_box_y, list_box_w, list_box_h = Cursor.get_item_bounds()
		local input_w = list_box_x + list_box_w - prev_anchor_x - filter_w - Cursor.pad_x()

		Cursor.set_anchor_x(prev_anchor_x)
		Cursor.set_x(prev_anchor_x)

		local read_only = options.t ~= "savefile"
		if Input.begin("FileDialog_Input", {w = input_w, read_only = read_only, text = active_instance.text, align = "left"}) then
			active_instance.text = Input.get_text()
			active_instance.rtn[1] = active_instance.text
		end

		Cursor.same_line()

		local filter, desc = get_filter(active_instance)
		if ComboBox.begin("FileDialog_Filter", {selected = filter .. " " .. desc}) then
			for i, v in ipairs(active_instance.filters) do
				filter, desc = get_filter(active_instance, i)
				if Text.begin(filter .. " " .. desc, {is_selectable = true}) then
					active_instance.selected_filter = i
					active_instance.parsed = false
				end
			end

			ComboBox.finish()
		end

		local filter_cbx, filter_cby, filter_cbw, filter_cbh = Cursor.get_item_bounds()
		filter_w = filter_cbw

		LayoutManager.begin("FileDialog_Buttons_Layout", {align_x = "right", align_y = "Bottom"})
		if Button.begin("OK") or item_selected then
			local opening_directory = false
			if #active_instance.rtn == 1 and options.t ~= "opendirectory" then
				local path = active_instance.rtn[1]
				if FileSystem.is_directory(path) then
					opening_directory = true
					open_directory(path)
				elseif options.t == "savefile" then
					if FileSystem.exists(path) then
						file_dialog_ask_overwrite = true
						opening_directory = true
					end
				end
			end

			if not opening_directory then
				result.button = "OK"
				result.files = prune_results(active_instance.rtn, options.t == "opendirectory")

				if options.t == "savefile" then
					validate_save_file(result.files, get_extension(active_instance))
				end
			end
		end

		Cursor.same_line()
		LayoutManager.same_line()

		if Button.begin("Cancel") then
			result.button = "Cancel"
		end
		LayoutManager.finish()

		if file_dialog_ask_overwrite then
			local file_name = #active_instance.rtn > 0 and active_instance.rtn[1] or ""
			local ask_overwrite =
				Dialog.message_box(
				"Overwriting",
				"Are you sure you would like to overwrite file " .. file_name,
				{buttons = {"Cancel", "No", "Yes"}}
			)

			if ask_overwrite ~= "" then
				if ask_overwrite == "No" then
					result.button = "Cancel"
					result.files = {}
				elseif ask_overwrite == "Yes" then
					result.button = "OK"
					result.files = prune_results(active_instance.rtn, options.t == "opendirectory")
				end

				file_dialog_ask_overwrite = false
			end
		end

		if result.button ~= "" then
			active_instance.parsed = false
			Dialog.close()
		end

		Dialog.finish()
	end
	return result
end

return Dialog
