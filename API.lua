if SLAB_PATH == nil then
	SLAB_PATH = (...):match("(.-)[^%.]+$")
end

SLAB_FILE_PATH = debug.getinfo(1, "s").source:match("^@(.+)/")
SLAB_FILE_PATH = SLAB_FILE_PATH == nil and "" or SLAB_FILE_PATH

local Button = required("button")
local CheckBox = required("CheckBox")
local ColorPicker = required("ColorPicker")
local ComboBox = required("ComboBox")
local Config = required("Config")
local Cursor = required("Cursor")
local Dialog = required("Dialog")
local Dock = required("Dock")
local DrawCommands = required("DrawCommands")
local Image = required("img")
local Input = required("Input")
local Keyboard = required("Keyboard")
local LayoutManager = required("LayoutManager")
local ListBox = required("ListBox")
local Messages = required("Messages")
local Mouse = required("Mouse")
local Menu = required("Menu")
local MenuState = required("MenuState")
local MenuBar = required("MenuBar")
local Region = required("Region")
local separator = required("separator")
local Shape = required("Shape")
local Stats = required("Stats")
local Style = required("Style")
local text = required("text")
local Tree = required("Tree")
local Utility = required("Utility")
local Window = required("Window")

--[[
	Slab

	Slab is an immediate mode GUI toolkit for the Love 2D framework. This library is designed to
	allow users to easily add this library to their existing Love 2D projects and quickly create
	tools to enable them to iterate on their ideas quickly. The user should be able to utilize this
	library with minimal integration steps and is completely written in Lua and utilizes
	the Love 2D API. No compiled binaries are required and the user will have access to the source
	so that they may make adjustments that meet the needs of their own projects and tools. Refer
	to main.lua and SlabTest.lua for example usage of this library.

	Supported Version: 11.3.0

	API:
		initialize
		get_version
		get_love_version
		update
		draw
		set_ini_state_path
		get_ini_state_path
		set_verbose
		get_messages

		Style:
			get_style
			push_font
			pop_font

		Window:
			begin_window
			end_window
			get_window_position
			get_window_size
			get_window_content_size
			get_window_active_size
			is_window_appearing

		Menu:
			begin_main_menu_bar
			end_main_menu_bar
			begin_menu_bar
			end_menu_bar
			begin_menu
			end_menu
			begin_context_menu_item
			begin_context_menu_window
			end_context_menu
			menu_item
			menu_item_checked

		separator
		button
		radio_button
		text
		text_selectable
		textf
		get_text_size
		get_text_width
		get_text_height
		checkBox
		input
		input_number_drag
		input_number_slider
		get_input_text
		get_input_number
		get_input_cursor_pos
		is_input_focused
		is_any_input_focused
		set_input_focus
		set_input_cursor_pos
		set_input_cursor_pos_line
		begin_tree
		end_tree
		begin_combo_box
		end_combo_box
		imgage

		Cursor:
			same_line
			new_line
			set_cursor_pos
			get_cursor_pos
			indent
			unindent

		Properties

		ListBox:
			begin_list_box
			end_list_box
			begin_list_box_item
			is_list_box_item_clicked
			end_list_box_item

		Dialog:
			open_dialog
			begin_dialog
			end_dialog
			close_dialog
			message_box
			file_dialog

		Mouse:
			is_mouse_down
			is_mouse_clicked
			is_mouse_released
			is_mouse_double_clicked
			is_mouse_dragging
			get_mouse_position
			get_mouse_position_window
			get_mouse_delta

		control:
			is_control_hovered
			is_control_clicked
			get_control_size
			is_void_hovered
			is_void_clicked

		Keyboard:
			is_key_down
			is_key_pressed
			is_key_released

		Shape:
			rectangle
			circle
			triangle
			line
			curve
			get_curve_control_point_count
			get_curve_control_point
			evaluate_curve
			evaluate_curve_mouse
			polygon

		Stats:
			begin_stat
			end_stat
			enable_stats
			is_stats_enabled
			flush_stats

		Layout:
			begin_layout
			end_layout
			set_layout_column
			get_layout_size

		Scroll:
			set_scroll_speed
			get_scroll_speed

		Shader:
			push_shader
			pop_shader

		Dock:
			enable_docks
			disable_docks
			set_dock_options
--]]
local Slab = {}

-- Slab version numbers.
local Version_Major = 0
local Version_Minor = 7
local Version_Revision = 2

local frame_stat_handle = nil

-- The path to save the UI state to a file. This will default to the base source directory.
local ini_state_path = love.filesystem.getSourceBaseDirectory() .. "/Slab.ini"
local quit_fn = nil
local verbose = false
local initialized = false
local did_update = false
local did_draw = false

local function load_state()
	if ini_state_path ~= nil then
		local result, err = Config.load_file(ini_state_path)
		if result ~= nil then
			Dock.load(result)
			Tree.load(result)
			Window.load(result)
		elseif verbose then
			print("Failed to load INI file '" .. ini_state_path .. "': " .. err)
		end
	end
end

local function save_state()
	if ini_state_path ~= nil then
		local tbl = {}
		Dock.save(tbl)
		Tree.save(tbl)
		Window.save(tbl)
		Config.save(ini_state_path, tbl)
	end
end

local function text_input(ch)
	Input.text(ch)

	if love.textinput ~= nil then
		love.textinput(ch)
	end
end

local function wheel_moved(x, y)
	Window.wheel_moved(x, y)

	if love.wheelmoved ~= nil then
		love.wheelmoved(x, y)
	end
end

local function on_quit()
	save_state()

	if quit_fn ~= nil then
		quit_fn()
	end
end

--[[
	initialize

	Initializes Slab and hooks into the required events. This function should be called in love.load.

	args: [tbl] The List of parameters passed in by the user on the command-line. This should be passed in from
		love.load function. Below is a List of arguments available to modify Slab:
		NoMessages: [String] Disables the messaging system that warns developers of any changes in the API.
		NoDocks: [String] Disables all docks.

	rtn: None.
--]]
function Slab.initialize(args)
	if initialized then
		return
	end

	Style.API.initialize()
	love.handlers["textinput"] = text_input
	love.handlers["wheelmoved"] = wheel_moved

	-- In Love 11.3, overriding love.handlers['quit'] doesn't seem to affect the callback during shutdown.
	-- Storing and overriding love.quit manually will properly call Slab's callback. This function will call
	-- the stored function once Slab is finished with its process.
	quit_fn = love.quit
	love.quit = on_quit

	args = args or {}
	if type(args) == "table" then
		for i, v in ipairs(args) do
			if string.lower(v) == "nomessages" then
				Messages.set_enabled(false)
			elseif string.lower(v) == "nodocks" then
				Slab.disable_docks({"Left", "Right", "Bottom"})
			end
		end
	end

	Keyboard.initialize(args)
	Mouse.initialize(args)

	load_state()

	initialized = true
end

--[[
	get_version

	Retrieves the current version of Slab being used as a string.

	rtn: [String] String of the current Slab version.
--]]
function Slab.get_version()
	return string.format("%d.%d.%d", Version_Major, Version_Minor, Version_Revision)
end

--[[
	get_love_version

	Retrieves the current version of Love being used as a string.

	rtn: [String] String of the current Love version.
--]]
function Slab.get_love_version()
	local Major, Minor, Revision, Codename = love.getVersion()
	return string.format("%d.%d.%d - %s", Major, Minor, Revision, Codename)
end

--[[
	update

	Updates the input state and states of various widgets. This function must be called every frame.
	This should be called before any Slab calls are made to ensure proper responses to Input are made.

	dt: [Number] The delta time for the frame. This should be passed in from love.update.

	rtn: None.
--]]
function Slab.update(dt)
	if did_update then
		return
	end

	Stats.reset()
	frame_stat_handle = Stats.begin("Frame", "Slab")
	local stat_handle = Stats.begin("update", "Slab")

	Mouse.update()
	Keyboard.update()
	Input.update(dt)
	DrawCommands.reset()
	Window.reset()
	LayoutManager.validate()

	if MenuState.is_opened then
		MenuState.was_opened = MenuState.is_opened
		if Mouse.is_clicked(1) then
			MenuState.request_close = true
		end
	end

	Stats.finish(stat_handle)

	did_update = true
	did_draw = false
end

--[[
	draw

	This function will execute all buffered draw calls from the various Slab calls made prior. This
	function should be called from love.draw and should be called at the very to ensure Slab is rendered
	above the user's workspace.

	rtn: None.
--]]
function Slab.draw()
	if did_draw then
		return
	end

	local stat_handle = Stats.begin("draw", "Slab")

	Window.validate()

	local moving_instance = Window.get_moving_instance()
	if moving_instance ~= nil then
		Dock.draw_overlay()
		Dock.set_pending_window(moving_instance)
	else
		Dock.Commit()
	end

	if MenuState.request_close then
		Menu.close()
		MenuBar.clear()
	end

	Mouse.update_cursor()

	if Mouse.is_released(1) then
		Button.clear_clicked()
	end

	love.graphics.push()
	love.graphics.origin()
	DrawCommands.execute()
	love.graphics.pop()

	Stats.finish(stat_handle)
	Stats.finish(frame_stat_handle)

	did_draw = true
	did_update = false
end

--[[
	set_ini_state_path

	Sets the INI path to save the UI state. If nil, Slab will not save the state to disk.

	rtn: None.
--]]
function Slab.set_ini_state_path(path)
	ini_state_path = path
end

--[[
	get_ini_state_path

	Gets the INI path to save the UI state. This value can be nil.

	rtn: [String] The path on disk the UI state will be saved to.
--]]
function Slab.get_ini_state_path()
	return ini_state_path
end

--[[
	set_verbose

	Enable/Disables internal Slab logging. Could be useful for diagnosing problems that occur inside of Slab.

	IsVerbose: [Boolean] Flag to enable/disable verbose logging.

	rtn: None.
--]]
function Slab.set_verbose(IsVerbose)
	verbose = (IsVerbose == nil or type(IsVerbose) ~= "boolean") and false or IsVerbose
end

--[[
	get_messages

	Retrieves a List of existing messages that has been captured by Slab.

	rtn: [tbl] List of messages that have been broadcasted from Slab.
--]]
function Slab.get_messages()
	return Messages.get()
end

--[[
	get_style

	Retrieve the style table associated with the current instance of Slab. This will allow the user to add custom styling
	to their controls.

	rtn: [tbl] The style table.
--]]
function Slab.get_style()
	return Style
end

--[[
	push_font

	Pushes a Love font object onto the font stack. All text rendering will use this font until pop_font is called.

	font: [object] The Love font object to use.

	rtn: None.
--]]
function Slab.push_font(font)
	Style.API.push_font(font)
end

--[[
	pop_font

	Pops the last font from the stack.

	rtn: None.
--]]
function Slab.pop_font()
	Style.API.pop_font()
end

--[[
	begin_window

	This function begins the process of drawing widgets to a window. This function must be followed up with
	an end_window call to ensure proper behavior of drawing windows.

	id: [String] a unique string identifying this window in the project.
	options: [tbl] List of options that control how this window will behave.
		x: [Number] The x position to start rendering the window at.
		y: [Number] The y position to start rendering the window at.
		w: [Number] The starting width of the window.
		h: [Number] The starting height of the window.
		content_w: [Number] The starting width of the content contained within this window.
		content_h: [Number] The starting height of the content contained within this window.
		bg_color: [tbl] The background color value for this window. Will use the default style WindowBackgroundColor if this is empty.
		title: [String] The title to display for this window. If emtpy, no title bar will be rendered and the window will not be movable.
		allow_move: [Boolean] controls whether the window is movable within the title bar area. The default value is true.
		allow_resize: [Boolean] controls whether the window is resizable. The default value is true. auto_size_window must be false for this to work.
		allow_focus: [Boolean] controls whether the window can be focused. The default value is true.
		border: [Number] The value which controls how much empty space should be left between all sides of the window from the content.
			The default value is 4.0
		no_outline: [Boolean] controls whether an outline should not be rendered. The default value is false.
		is_menu_bar: [Boolean] controls whether if this window is a menu bar or not. This flag should be ignored and is used by the menu bar
			system. The default value is false.
		auto_size_window: [Boolean] Automatically updates the window size to match the content size. The default value is true.
		auto_size_window_w: [Boolean] Automatically update the window width to match the content size. This value is taken from auto_size_window by default.
		auto_size_window_h: [Boolean] Automatically update the window height to match the content size. This value is taken from auto_size_window by default.
		auto_size_content: [Boolean] The content size of the window is automatically updated with each new widget. The default value is true.
		layer: [String] The layer to which to draw this window. This is used internally and should be ignored by the user.
		reset_position: [Boolean] Determines if the window should reset any delta changes to its position.
		reset_size: [Boolean] Determines if the window should reset any delta changes to its size.
		reset_content: [Boolean] Determines if the window should reset any delta changes to its content size.
		ResetLayout: [Boolean] Will reset the position, size, and content. Short hand for the above 3 flags.
		sizer_filter: [tbl] Specifies what sizers are enabled for the window. If nothing is specified, all sizers are available. The values can
			be: NW, NE, s_w, SE, N, s, E, w
		can_obstruct: [Boolean] Sets whether this window is considered for obstruction of other windows and their controls. The default value is true.
		rounding: [Number] Amount of rounding to apply to the corners of the window.
		is_open: [Boolean] Determines if the window is open. If this value exists within the options, a close button will appear in
			the corner of the window and is updated when this button is pressed to reflect the new open state of this window.
		no_saved_settings: [Boolean] Flag to disable saving this window's settings to the state INI file.

	rtn: [Boolean] The open state of this window. Useful for simplifying API calls by storing the result in a flag instead of a table.
		end_window must still be called regardless of the result for this value.
--]]
function Slab.begin_window(id, options)
	return Window.begin(id, options)
end

--[[
	end_window

	This function must be called after a begin_window and associated widget calls. If the user fails to call this, an assertion will be thrown
	to alert the user.

	rtn: None.
--]]
function Slab.end_window()
	Window.finish()
end

--[[
	get_window_position

	Retrieves the active window's position.

	rtn: [Number], [Number] The x and y position of the active window.
--]]
function Slab.get_window_position()
	return Window.get_position()
end

--[[
	get_window_size

	Retrieves the active window's size.

	rtn: [Number], [Number] The width and height of the active window.
--]]
function Slab.get_window_size()
	return Window.get_size()
end

--[[
	get_window_content_size

	Retrieves the active window's content size.

	rtn: [Number], [Number] The width and height of the active window content.
--]]
function Slab.get_window_content_size()
	return Window.get_content_size()
end

--[[
	get_window_active_size

	Retrieves the active window's active size minus the borders.

	rtn: [Number], [Number] The width and height of the window's active bounds.
--]]
function Slab.get_window_active_size()
	return Window.get_borderless_size()
end

--[[
	is_window_appearing

	Is the current window appearing this frame. This will return true if begin_window has
	not been called for a window over 2 or more frames.

	rtn: [Boolean] True if the window is appearing this frame. False otherwise.
--]]
function Slab.is_window_appearing()
	return Window.is_appearing()
end

--[[
	begin_main_menu_bar

	This function begins the process for setting up the main menu bar. This should be called outside of any begin_window/end_window calls.
	The user should only call end_main_menu_bar if this function returns true. Use begin_menu/end_menu calls to add menu items on the main menu bar.

	Example:
		if Slab.begin_main_menu_bar() then
			if Slab.begin_menu("File") then
				if Slab.menu_item("Quit") then
					love.event.quit()
				end

				Slab.end_menu()
			end

			Slab.end_main_menu_bar()
		end

	rtn: [Boolean] Returns true if the main menu bar process has started.
--]]
function Slab.begin_main_menu_bar()
	Cursor.set_position(0.0, 0.0)
	return Slab.begin_menu_bar(true)
end

--[[
	end_main_menu_bar

	This function should be called if begin_main_menu_bar returns true.

	rtn: None.
--]]
function Slab.end_main_menu_bar()
	Slab.end_menu_bar()
end

--[[
	begin_menu_bar

	This function begins the process of rendering a menu bar for a window. This should only be called within a begin_window/end_window context.

	is_main_menu_bar: [Boolean] Is this menu bar for the main viewport. Used internally. Should be ignored for all other calls.

	rtn: [Boolean] Returns true if the menu bar process has started.
--]]
function Slab.begin_menu_bar(is_main_menu_bar)
	return MenuBar.begin(is_main_menu_bar)
end

--[[
	end_menu_bar

	This function should be called if begin_menu_bar returns true.

	rtn: None.
--]]
function Slab.end_menu_bar()
	MenuBar.finish()
end

--[[
	begin_menu

	Adds a menu item that when the user hovers over, opens up an additional context menu. When used within a menu bar, begin_menu calls
	will be added to the bar. Within a context menu, the menu item will be added within the context menu with an additional arrow to notify
	the user more options are available. If this function returns true, the user must call end_menu.

	label: [String] The label to display for this menu.
	options: [tbl] List of options that control how this menu behaves.
		enabled: [Boolean] Determines if this menu is enabled. This value is true by default. disabled items are displayed but
			cannot be interacted with.

	rtn: [Boolean] Returns true if the menu item is being hovered.
--]]
function Slab.begin_menu(label, options)
	return Menu.begin_menu(label, options)
end

--[[
	end_menu

	Finishes up a begin_menu. This function must be called if begin_menu returns true.

	rtn: None.
--]]
function Slab.end_menu()
	Menu.end_menu()
end

--[[
	begin_context_menu_item

	Opens up a context menu based on if the user right clicks on the last item. This function should be placed immediately after an item
	call to open up a context menu for that specific item. If this function returns true, end_context_menu must be called.

	Example:
		if Slab.button("button!") then
			-- Perform logic here when button is clicked
		end

		-- This will only return true if the previous button is hot and the user right-clicks.
		if Slab.begin_context_menu_item() then
			Slab.menu_item("button item 1")
			Slab.menu_item("button item 2")

			Slab.end_context_menu()
		end

	button: [Number] The mouse button to use for opening up this context menu.

	rtn: [Boolean] Returns true if the user right clicks on the previous item call. end_context_menu must be called in order for
		this to function properly.
--]]
function Slab.begin_context_menu_item(button)
	return Menu.begin_context_menu({is_item = true, button = button})
end

--[[
	begin_context_menu_window

	Opens up a context menu based on if the user right clicks anywhere within the window. It is recommended to place this function at the end
	of a window's widget calls so that Slab can catch any begin_context_menu_item calls before this call. If this function returns true,
	end_context_menu must be called.

	button: [Number] The mouse button to use for opening up this context menu.

	rtn: [Boolean] Returns true if the user right clicks anywhere within the window. end_context_menu must be called in order for this
		to function properly.
--]]
function Slab.begin_context_menu_window(button)
	return Menu.begin_context_menu({is_window = true, button = button})
end

--[[
	end_context_menu

	Finishes up any begin_context_menu_item/begin_context_menu_window if they return true.

	rtn: None.
--]]
function Slab.end_context_menu()
	Menu.end_context_menu()
end

--[[
	menu_item

	Adds a menu item to a given context menu.

	label: [String] The label to display to the user.
	options: [tbl] List of options that control how this menu behaves.
		enabled: [Boolean] Determines if this menu is enabled. This value is true by default. disabled items are displayed but
			cannot be interacted with.

	rtn: [Boolean] Returns true if the user clicks on this menu item.
--]]
function Slab.menu_item(label, options)
	return Menu.menu_item(label, options)
end

--[[
	menu_item_checked

	Adds a menu item to a given context menu. If IsChecked is true, then a check mark will be rendered next to the
	label.

	Example:
		local Checked = false
		if Slab.menu_item_checked("Menu item", Checked)
			Checked = not Checked
		end

	label: [String] The label to display to the user.
	IsChecked: [Boolean] Determines if a check mark should be rendered next to the label.
	options: [tbl] List of options that control how this menu behaves.
		enabled: [Boolean] Determines if this menu is enabled. This value is true by default. disabled items are displayed but
			cannot be interacted with.

	rtn: [Boolean] Returns true if the user clicks on this menu item.
--]]
function Slab.menu_item_checked(label, IsChecked, options)
	return Menu.menu_item_checked(label, IsChecked, options)
end

--[[
	separator

	This functions renders a separator line in the window.

	Option: [tbl] List of options for how this separator will be drawn.
		include_borders: [Boolean] Whether to extend the separator to include the window borders. This is false by default.
		h: [Number] The height of the separator. This doesn't change the line thickness, rather, specifies the cursor advancement
			in the y direction.
		thickness: [Number] The thickness of the line rendered. The default value is 1.0.

	rtn: None.
--]]
function Slab.separator(options)
	separator.begin(options)
end

--[[
	button

	Adds a button to the active window.

	label: [String] The label to display on the Button.
	options: [tbl] List of options for how this button will behave.
		tooltip: [String] The tooltip to display when the user hovers over this Button.
		rounding: [Number] Amount of rounding to apply to the corners of the Button.
		invisible: [Boolean] Don't render the button, but keep the behavior.
		w: [Number] Override the width of the Button.
		h: [Number] Override the height of the Button.
		disabled: [Boolean] If true, the button is not interactable by the user.

	rtn: [Boolean] Returns true if the user clicks on this Button.
--]]
function Slab.button(label, options)
	return Button.begin(label, options)
end

--[[
	radio_button

	Adds a radio button entry to the active window. The grouping of radio buttons is determined by the user. An index can
	be applied to the given radio button and a selected_index can be passed in to determine if this specific radio button
	is the selected one.

	label: [String] The label to display next to the Button.
	options: [tbl] List of options for how this radio button will behave.
		index: [Number] The index of this radio Button. Will be 0 by default and not selectable. Assign an index to group the Button.
		selected_index: [Number] The index of the radio button that is selected. If this equals the index field, then this radio button
			will be rendered as selected.
		tooltip: [String] The tooltip to display when the user hovers over the button or label.

	rtn: [Boolean] Returns true if the user clicks on this Button.
--]]
function Slab.radio_button(label, options)
	return Button.begin_radio(label, options)
end

--[[
	text

	Adds text to the active window.

	label: [String] The string to be displayed in the window.
	options: [tbl] List of options for how this text is displayed.
		colour: [tbl] The color to render the text.
		pad: [Number] How far to pad the text from the left side of the current cursor position.
		is_selectable: [Boolean] Whether this text is selectable using the text's y position and the window x and width as the
			hot zone.
		is_selectable_text_only: [Boolean] Only available if is_selectable is true. Will use the text width instead of the
			window width to determine the hot zone.
		is_selected: [Boolean] Forces the hover background to be rendered.
		select_on_hover: [Boolean] Returns true if the user is hovering over the hot zone of this text.
		hover_color: [tbl] The color to render the background if the is_selected option is true.
		url: [String] a url address to open when this text control is clicked.

	rtn: [Boolean] Returns true if select_on_hover option is set to true. False otherwise.
--]]
function Slab.text(label, options)
	return Text.begin(label, options)
end

--[[
	text_selectable

	This function is a shortcut for SlabText with the is_selectable option set to true.

	label: [String] The string to be displayed in the window.
	options: [tbl] List of options for how this text is displayed.
		See Slab.text for all options.

	rtn: [Boolean] Returns true if user clicks on this text. False otherwise.
--]]
function Slab.text_selectable(label, options)
	options = options == nil and {} or options
	options.is_selectable = true
	return Slab.text(label, options)
end

--[[
	textf

	Adds formatted text to the active window. This text will wrap to fit within the contents of
	either the window or a user specified width.

	label: [String] The text to be rendered.
	options: [tbl] List of options for how this text is displayed.
		colour: [tbl] The color to render the text.
		w: [Number] The width to restrict the text to. If this option is not specified, then the window
			width is used.
		align: [String] The alignment to use for this text. For more information, refer to the love documentation
			at https://love2d.org/wiki/AlignMode. Below are the available options:
			center: align text center.
			left: align text left.
			right: align text right.
			justify: align text both left and right.

	rtn: None.
--]]
function Slab.textf(label, options)
	Text.begin_formatted(label, options)
end

--[[
	get_text_size

	Retrieves the width and height of the given text. The result is based on the current font.

	label: [String] The string to retrieve the size for.

	rtn: [Number], [Number] The width and height of the given text.
--]]
function Slab.get_text_size(label)
	return Text.get_size(label)
end

--[[
	get_text_width

	Retrieves the width of the given text. The result is based on the current font.

	label: [String] The string to retrieve the width for.

	rtn: [Number] The width of the given text.
--]]
function Slab.get_text_width(label)
	local w, h = Slab.get_text_size(label)
	return w
end

--[[
	get_text_height

	Retrieves the height of the current font.

	rtn: [Number] The height of the current font.
--]]
function Slab.get_text_height()
	return Text.get_height()
end

--[[
	CheckBox

	Renders a check box with a label. The check box when enabled will render an 'x'.

	enabled: [Boolean] Will render an 'x' within the box if true. Will be an empty box otherwise.
	label: [String] The label to display after the check box.
	options: [tbl] List of options for how this check box will behave.
		tooltip: [String] text to be displayed if the user hovers over the check box.
		id: [String] An optional id that can be supplied by the user. By default, the id will be the label.
		rounding: [Number] Amount of rounding to apply to the corners of the check box.
		size: [Number] The uniform size of the box. The default value is 16.

	rtn: [Boolean] Returns true if the user clicks within the check box.
--]]
function Slab.checkBox(enabled, label, options)
	return CheckBox.begin(enabled, label, options)
end

--[[
	Input

	This function will render an input box for a user to input text in. This widget behaves like input boxes
	found in other applications. This function will only return true if it has focus and user has either input
	text or pressed the return key.

	Example:
		local text = "Hello World"
		if Slab.input('Example', {text = text}) then
			text = Slab.GetInputText()
		end

	id: [String] a string that uniquely identifies this Input within the context of the window.
	options: [tbl] List of options for how this Input will behave.
		tooltip: [String] text to be displayed if the user hovers over the Input box.
		return_on_text: [Boolean] Will cause this function to return true whenever the user has input
			a new character into the Input box. This is true by default.
		text: [String] The text to be supplied to the input box. It is recommended to use this option
			when return_on_text is true.
		text_color: [tbl] The color to use for the text. The default color is the color used for text, but there is also
			a default multiline text color defined in the Style.
		bg_color: [tbl] The background color for the input box.
		select_color: [tbl] The color used when the user is selecting text within the input box.
		select_on_focus: [Boolean] When this input box is focused by the user, the text contents within the input
			will be selected. This is true by default.
		numbers_only: [Boolean] When true, only numeric characters and the '.' character are allowed to be input into
			the input box. If no text is input, the input box will display '0'.
		w: [Number] The width of the input box. By default, will be 150.0
		h: [Number] The height of the input box. By default, will be the height of the current font.
		read_only: [Boolean] Whether this input field can be editable or not.
		align: [String] Aligns the text within the input box. options are:
			left: Aligns the text to the left. This will be set when this Input is focused.
			center: Aligns the text in the center. This is the default for when the text is not focused.
		rounding: [Number] Amount of rounding to apply to the corners of the input box.
		min_number: [Number] The minimum value that can be entered into this input box. Only valid when numbers_only is true.
		max_number: [Number] The maximum value that can be entered into this input box. Only valid when numbers_only is true.
		multi_line: [Boolean] Determines whether this input control should support multiple lines. If this is true, then the
			select_on_focus flag will be false. The given text will also be sanitized to remove controls characters such as
			'\r'. Also, the text will be left aligned.
		multi_line_w: [Number] The width for which the lines of text should be wrapped at.
		highlight: [tbl] a List of key-values that define what words to highlight what color. Strings should be used for
			the word to highlight and the value should be a table defining the color.
		step: [Number] The step amount for numeric controls when the user click and drags. The default value is 1.0.
		no_drag: [Boolean] Determines whether this numberic control allows the user to click and drag to alter the value.
		use_slider: [Boolean] If enabled, displays a slider inside the input control. This will only be drawn if the numbers_only
			option is set to true. The position of the slider inside the control determines the value based on the min_number
			and max_number option.

	rtn: [Boolean] Returns true if the user has pressed the return key while focused on this input box. If return_on_text
		is set to true, then this function will return true whenever the user has input any character into the input box.
--]]
function Slab.input(id, options)
	return Input.begin(id, options)
end

--[[
	InputNumberDrag

	This is a wrapper function for calling the Input function which sets the proper options to set up the input box for
	displaying and editing numbers. The user will be able to click and drag the control to alter the value. Double-clicking
	inside this control will allow for manually editing the value.

	id: [String] a string that uniquely identifies this Input within the context of the window.
	value: [Number] The value to display in the control.
	min_val: [Number] The minimum value that can be set for this number control. If nil, then this value will be set to -math.huge.
	max_val: [Number] The maximum value that can be set for this number control. If nil, then this value will be set to math.huge.
	step: [Number] The amount to increase value when mouse delta reaches threshold.
	options: [tbl] List of options for how this input control is displayed. See Slab.input for all options.

	rtn: [Boolean] Returns true whenever this valued is modified.
--]]
function Slab.input_number_drag(id, value, min_val, max_val, step, options)
	options = options == nil and {} or options
	options.text = tostring(value)
	options.min_number = min_val
	options.max_number = max_val
	options.step = step
	options.numbers_only = true
	options.use_slider = false
	options.no_drag = false
	return Slab.input(id, options)
end

--[[
	InputNumberSlider

	This is a wrapper function for calling the Input function which sets the proper options to set up the input box for
	displaying and editing numbers. This will also force the control to display a slider, which determines what the value
	stored is based on the min_val and max_val options. Double-clicking inside this control will allow for manually editing
	the value.

	id: [String] a string that uniquely identifies this Input within the context of the window.
	value: [Number] The value to display in the control.
	min_val: [Number] The minimum value that can be set for this number control. If nil, then this value will be set to -math.huge.
	max_val: [Number] The maximum value that can be set for this number control. If nil, then this value will be set to math.huge.
	options: [tbl] List of options for how this input control is displayed. See Slab.input for all options.
		precision: [Number] An integer in the range [0..5]. This will set the size of the fractional component.

	rtn: [Boolean] Returns true whenever this valued is modified.
--]]
function Slab.input_number_slider(id, value, min_val, max_val, options)
	options = options == nil and {} or options
	options.text = tostring(value)
	options.min_number = min_val
	options.max_number = max_val
	options.numbers_only = true
	options.use_slider = true
	return Slab.input(id, options)
end

--[[
	GetInputText

	Retrieves the text entered into the focused input box. Refer to the documentation for Slab.input for an example on how to
	use this function.

	rtn: [String] Returns the text entered into the focused input box.
--]]
function Slab.GetInputText()
	return Input.get_text()
end

--[[
	GetInputNumber

	Retrieves the text entered into the focused input box and attempts to conver the text into a number. Will always return a valid
	number.

	rtn: [Number] Returns the text entered into the focused input box as a number.
--]]
function Slab.get_input_number()
	local result = tonumber(Input.get_text())
	if result == nil then
		result = 0
	end
	return result
end

--[[
	GetInputCursorPos

	Retrieves the position of the input cursor for the focused input control. There are three values that are returned. The first one
	is the absolute position of the cursor with regards to the text for the control. The second is the column position of the cursor
	on the current line. The final value is the line number. The column will match the absolute position if the input control is not
	multi line.

	rtn: [Number], [Number], [Number] The absolute position of the cursor, the column position of the cursor on the current line,
		and the line number of the cursor. These values will all be zero if no input control is focused.
--]]
function Slab.get_input_cursor_pos()
	return Input.get_cursor_pos()
end

--[[
	IsInputFocused

	Returns whether the input control with the given id is focused or not.

	id: [String] The id of the input control to check.

	rtn: [Boolean] True if the input control with the given id is focused. False otherwise.
--]]
function Slab.is_input_focused(id)
	return Input.is_focused(id)
end

--[[
	IsAnyInputFocused

	Returns whether any input control is focused or not.

	rtn: [Boolean] True if there is an input control focused. False otherwise.
--]]
function Slab.is_any_input_focused()
	return Input.is_any_focused()
end

--[[
	SetInputFocus

	Sets the focus of the input control to the control with the given id. The focus is set at the beginning
	of the next frame to avoid any input events from the current frame.

	id: [String] The id of the input control to focus.
--]]
function Slab.set_input_focus(id)
	Input.set_focused(id)
end

--[[
	SetInputCursorPos

	Sets the absolute text position in bytes of the focused input control. This value is applied on the next frame.
	This function can be combined with the SetInputFocus function to modify the cursor positioning of the desired
	input control. Note that the input control supports UTF8 characters so if the desired position is not a valid
	character, the position will be altered to find the next closest valid character.

	pos: [Number] The absolute position in bytes of the text of the focused input control.
--]]
function Slab.set_input_cursor_pos(pos)
	Input.set_cursor_pos(pos)
end

--[[
	SetInputCursorPosLine

	Sets the column and line number of the focused input control. These values are applied on the next frame. This
	function behaves the same as SetInputCursorPos, but allows for setting the cursor by column and line.

	column: [Number] The text position in bytes of the current line.
	line: [Number] The line number to set.
--]]
function Slab.set_input_cursor_pos_line(column, line)
	Input.set_cursor_pos_line(column, line)
end

--[[
	BeginTree

	This function will render a tree item with an optional label. The tree can be expanded or collapsed based on whether
	the user clicked on the tree item. This function can also be nested to create a hierarchy of tree items. This function
	will return false when collapsed and true when expanded. If this function returns true, Slab.end_tree must be called in
	order for this tree item to behave properly. The hot zone of this tree item will be the height of the label and the width
	of the window by default.

	id: [String/tbl] a string or table uniquely identifying this tree item within the context of the window. If the given id
		is a table, then the internal Tree entry for this table will be removed once the table has been garbage collected.
	options: [tbl] List of options for how this tree item will behave.
		label: [String] The text to be rendered for this tree item.
		tooltip: [String] The text to be rendered when the user hovers over this tree item.
		is_leaf: [Boolean] If this is true, this tree item will not be expandable/collapsable.
		open_with_highlight: [Boolean] If this is true, the tree will be expanded/collapsed when the user hovers over the hot
			zone of this tree item. If this is false, the user must click the expand/collapse icon to interact with this tree
			item.
		icon: [object] a user supplied image. This must be a valid Love image or the call will assert.
		icon_path: [String] If the icon option is nil, then a path can be specified. Slab will load and
			manage the image resource.
		is_selected: [Boolean] If true, will render a highlight rectangle around the tree item.
		is_open: [Boolean] Will force the tree item to be expanded.
		no_saved_settings: [Boolean] Flag to disable saving this tree's settings to the state INI file.

	rtn: [Boolean] Returns true if this tree item is expanded. Slab.end_tree must be called if this returns true.
--]]
function Slab.begin_tree(id, options)
	return Tree.begin(id, options)
end

--[[
	EndTree

	Finishes up any BeginTree calls if those functions return true.

	rtn: None.
--]]
function Slab.end_tree()
	Tree.finish()
end

--[[
	begin_combo_box

	This function renders a non-editable input field with a drop down arrow. When the user clicks this option, a window is
	created and the user can supply their own Slab.text_selectable calls to add possible items to select from. This function
	will return true if the combo box is opened. Slab.end_combo_box must be called if this function returns true.

	Example:
		local options = {"Apple", "Banana", "Orange", "Pear", "Lemon"}
		local Options_Selected = ""
		if Slab.begin_combo_box('Fruits', {selected = Options_Selected}) then
			for k, v in pairs(options) do
				if Slab.text_selectable(v) then
					Options_Selected = v
				end
			end

			Slab.end_combo_box()
		end

	id: [String] a string that uniquely identifies this combo box within the context of the active window.
	options: [tbl] List of options that control how this combo box behaves.
		tooltip: [String] text that is rendered when the user hovers over this combo box.
		selected: [String] text that is displayed in the non-editable input box for this combo box.
		w: [Number] The width of the combo box. The default value is 150.0.
		rounding: [Number] Amount of rounding to apply to the corners of the combo box.

	rtn: [Boolean] This function will return true if the combo box is open.
--]]
function Slab.begin_combo_box(id, options)
	return ComboBox.begin(id, options)
end

--[[
	end_combo_box

	Finishes up any begin_combo_box calls if those functions return true.

	rtn: None.
--]]
function Slab.end_combo_box()
	ComboBox.finish()
end

--[[
	img

	Draws an image at the current cursor position. The id uniquely identifies this
	image to manage behaviors with this image. An image can be supplied through the
	options or a path can be specified which Slab will manage the loading and storing of
	the image reference.

	id: [String] a string uniquely identifying this image within the context of the current window.
	options: [tbl] List of options controlling how the image should be drawn.
		img: [object] a user supplied image. This must be a valid Love image or the call will assert.
		path: [String] If the img option is nil, then a path must be specified. Slab will load and
			manage the image resource.
		rotation: [Number] The rotation value to apply when this image is drawn.
		scale: [Number] The scale value to apply to both the x and y axis.
		scale_x: [Number] The scale value to apply to the x axis.
		scale_y: [Number] The scale value to apply to the y axis.
		colour: [tbl] The color to use when rendering this image.
		sub_x: [Number] The x-coordinate used inside the given image.
		sub_y: [Number] The y-coordinate used inside the given image.
		sub_w: [Number] The width used inside the given image.
		sub_h: [Number] The height used insided the given image.
		WrapX: [String] The horizontal wrapping mode for this image. The available options are 'clamp', 'repeat', 
			'mirroredrepeat', and 'clampzero'. For more information refer to the Love2D documentation on wrap modes at
			https://love2d.org/wiki/WrapMode.
		WrapY: [String] The vertical wrapping mode for this image. The available options are 'clamp', 'repeat', 
			'mirroredrepeat', and 'clampzero'. For more information refer to the Love2D documentation on wrap modes at
			https://love2d.org/wiki/WrapMode.

	rtn: None.
--]]
function Slab.image(id, options)
	Image.begin(id, options)
end

--[[
	same_line

	This forces the cursor to move back up to the same line as the previous widget. By default, all Slab widgets will
	advance the cursor to the next line based on the height of the current line. By using this call with other widget
	calls, the user will be able to set up multiple widgets on the same line to control how a window may look.

	options: [tbl] List of options that controls how the cursor should handle the same line.
		pad: [Number] Extra padding to apply in the x direction.
		center_y: [Boolean] controls whether the cursor should be centered in the y direction on the line. By default
			the line will use the new_line_size, which is the height of the current font to center the cursor.

	rtn: None.
--]]
function Slab.same_line(options)
	LayoutManager.same_line(options)
end

--[[
	new_line

	This forces the cursor to advance to the next line based on the height of the current font.

	rtn: None.
--]]
function Slab.new_line()
	LayoutManager.new_line()
end

--[[
	set_cursor_pos

	Sets the cursor position. The default behavior is to set the cursor position relative to
	the current window. The absolute position can be set if the 'Absolute' option is set.

	controls will only be drawn within a window. If the cursor is set outside of the current
	window context, the control will not be displayed.

	x: [Number] The x coordinate to place the cursor. If nil, then the x coordinate is not modified.
	y: [Number] The y coordinate to place the cursor. If nil, then the y coordinate is not modified.
	options: [tbl] List of options that control how the cursor position should be set.
		Absolute: [Boolean] If true, will place the cursor using absolute coordinates.

	rtn: None.
--]]
function Slab.set_cursor_pos(x, y, options)
	options = options == nil and {} or options
	options.Absolute = options.Absolute == nil and false or options.Absolute

	if options.Absolute then
		x = x == nil and Cursor.get_x() or x
		y = y == nil and Cursor.get_y() or y
		Cursor.set_position(x, y)
	else
		x = x == nil and Cursor.get_x() - Cursor.get_anchor_x() or x
		y = y == nil and Cursor.get_y() - Cursor.get_anchor_y() or y
		Cursor.set_relative_position(x, y)
	end
end

--[[
	get_cursor_pos

	Gets the cursor position. The default behavior is to get the cursor position relative to
	the current window. The absolute position can be retrieved if the 'Absolute' option is set.

	options: [tbl] List of options that control how the cursor position should be retrieved.
		Absolute: [Boolean] If true, will return the cursor position in absolute coordinates.

	rtn: [Number], [Number] The x and y coordinates of the cursor.
--]]
function Slab.get_cursor_pos(options)
	options = options == nil and {} or options
	options.Absolute = options.Absolute == nil and false or options.Absolute

	local x, y = Cursor.get_position()

	if not options.Absolute then
		x = x - Cursor.get_anchor_x()
		y = y - Cursor.get_anchor_y()
	end

	return x, y
end

--[[
	indent

	Advances the anchored x position of the cursor. All subsequent lines will begin at the new cursor position. This function
	has no effect when columns are present.

	width: [Number] How far in pixels to advance the cursor. If nil, then the default value identified by the 'indent'
		property in the current style is used.

	rtn: None.
--]]
function Slab.indent(width)
	width = width == nil and Style.indent or width
	Cursor.indent(width)
end

--[[
	unindent

	Retreats the anchored x position of the cursor. All subsequent lines will begin at the new cursor position. This function
	has no effect when columns are present.

	width: [Number] How far in pixels to retreat the cursor. If nil, then the default value identified by the 'indent'
		property in the current style is used.

	rtn: None.
--]]
function Slab.unindent(width)
	width = width == nil and Style.indent or width
	Cursor.unindent(width)
end

--[[
	Properties

	Iterates through the table's key-value pairs and adds them to the active window. This currently only does
	a shallow loop and will not iterate through nested tables.

	TODO: Iterate through nested tables.

	tbl: [tbl] The List of properties to build widgets for.
	options: [tbl] List of options that can applied to a specific property. The key should match an entry in the
		'tbl' argument and will apply any additional options to the property control.
	Fallback: [tbl] List of options that can be applied to any property if an entry was not found in the 'options'
		argument.

	rtn: None.
--]]
function Slab.Properties(tbl, options, Fallback)
	options = options or {}
	Fallback = Fallback or {}

	if tbl ~= nil then
		for k, v in pairs(tbl) do
			local t = type(v)
			local ItemOptions = options[k] or Fallback
			if t == "boolean" then
				if Slab.checkBox(v, k, ItemOptions) then
					tbl[k] = not tbl[k]
				end
			elseif t == "number" then
				Slab.text(k .. ": ")
				Slab.same_line()
				ItemOptions.text = v
				ItemOptions.numbers_only = true
				ItemOptions.return_on_text = false
				ItemOptions.use_slider = ItemOptions.min_number and ItemOptions.max_number
				if Slab.input(k, ItemOptions) then
					tbl[k] = Slab.get_input_number()
				end
			elseif t == "string" then
				Slab.text(k .. ": ")
				Slab.same_line()
				ItemOptions.text = v
				ItemOptions.numbers_only = false
				ItemOptions.return_on_text = false
				if Slab.input(k, ItemOptions) then
					tbl[k] = Slab.GetInputText()
				end
			end
		end
	end
end

--[[
	begin_list_box

	Begins the process of creating a list box. If this function is called, end_list_box must be called after all
	items have been added.

	id: [String] a string uniquely identifying this list box within the context of the current window.
	options: [tbl] List of options controlling the behavior of the list box.
		w: [Number] The width of the list box. If nil, a default value of 150 is used.
		h: [Number] The height of the list box. If nil, a default value of 150 is used.
		clear: [Boolean] Clears out the items in the list. It is recommended to only call this if the list items
			has changed and should not be set to true on every frame.
		rounding: [Number] Amount of rounding to apply to the corners of the list box.
		stretch_w: [Boolean] Stretch the list box to fill the remaining width of the window.
		stretch_h: [Boolean] Stretch the list box to fill the remaining height of the window.

	rtn: None.
--]]
function Slab.begin_list_box(id, options)
	ListBox.begin(id, options)
end

--[[
	end_list_box

	Ends the list box container. Will close off the region and properly adjust the cursor.

	rtn: None.
--]]
function Slab.end_list_box()
	ListBox.finish()
end

--[[
	begin_list_box_item

	Adds an item to the current list box with the given id. The user can then draw controls however they see
	fit to display a single item. This allows the user to draw list items such as a texture with a name or just
	a text to represent the item. If this is called, end_list_box_item must be called to complete the item.

	id: [String] a string uniquely identifying this item within the context of the current list box.
	options: [tbl] List of options that control the behavior of the active list item.
		selected: [Boolean] If true, will draw the item with a selection background.

	rtn: None.
--]]
function Slab.begin_list_box_item(id, options)
	ListBox.begin_item(id, options)
end

--[[
	is_list_box_item_clicked

	Checks to see if a hot list item is clicked. This should only be called within a BeginListBoxLitem/end_list_box_item
	block.

	button: [Number] The button to check for the click of the item.
	IsDoubleClick: [Boolean] check for double-click instead of single click.

	rtn: [Boolean] Returns true if the active item is hovered with mouse and the requested mouse button is clicked.
--]]
function Slab.is_list_box_item_clicked(button, IsDoubleClick)
	return ListBox.is_item_clicked(button, IsDoubleClick)
end

--[[
	end_list_box_item

	Ends the current item and commits the bounds of the item to the list.

	rtn: None.
--]]
function Slab.end_list_box_item()
	ListBox.end_item()
end

--[[
	open_dialog

	Opens the dialog box with the given id. If the dialog box was opened, then it is pushed onto the stack.
	Calls to the begin_dialog with this same id will return true if opened.

	id: [String] a string uniquely identifying this dialog box.

	rtn: None.
--]]
function Slab.open_dialog(id)
	Dialog.open(id)
end

--[[
	begin_dialog

	Begins the dialog window with the given id if it is open. If this function returns true, then end_dialog must be called.
	Dialog boxes are windows which are centered in the center of the viewport. The dialog box cannot be moved and will
	capture all input from all other windows.

	id: [String] a string uniquely identifying this dialog box.
	options: [tbl] List of options that control how this dialog box behaves. These are the same parameters found
		for begin_window, with some caveats. Certain options are overridden by the Dialog system. They are:
			x, y, layer, allow_focus, allow_move, and auto_size_window.

	rtn: [Boolean] Returns true if the dialog with the given id is open.
--]]
function Slab.begin_dialog(id, options)
	return Dialog.begin(id, options)
end

--[[
	end_dialog

	Ends the dialog window if a call to begin_dialog returns true.

	rtn: None.
--]]
function Slab.end_dialog()
	Dialog.finish()
end

--[[
	close_dialog

	Closes the currently active dialog box.

	rtn: None.
--]]
function Slab.close_dialog()
	Dialog.close()
end

--[[
	message_box

	Opens a message box to be displayed to the user with a title and a message. buttons can be specified through the options
	table which when clicked, the string of the button is returned. This function should be called every frame when a message
	box wants to be displayed.

	title: [String] The title to display for the message box.
	message: [String] The message to be displayed. The text is aligned in the center. Multi-line strings are supported.
	options: [tbl] List of options to control the behavior of the message box.
		buttons: [tbl] List of buttons to display with the message box. The order of the buttons are displayed from right to left.

	rtn: [String] The name of the button that was clicked. If none was clicked, an emtpy string is returned.
--]]
function Slab.message_box(title, message, options)
	return Dialog.message_box(title, message, options)
end

--[[
	file_dialog

	Opens up a dialog box that displays a file explorer for opening or saving files or directories. This function does not create any file
	handles, it just returns the List of files selected by the user.

	options: [tbl] List of options that control the behavior of the file dialog.
		allow_multi_select: [Boolean] Allows the user to select multiple items in the file dialog.
		directory: [String] The starting directory when the file dialog is open. If none is specified, the dialog
			will start at love.filesystem.getSourceBaseDirectory and the dialog will remember the last
			directory navigated to by the user between calls to this function.
		t: [String] The t of file dialog to use. The options are:
			openfile: This is the default method. The user will have access to both directories and files. However,
				only file selections are returned.
			opendirectory: This t is used to filter the file dialog for directories only. No files will appear
				in the list.
			savefile: This t is used to select a name of a file to save. The user will be prompted if they wish to overwrite
				an existing file.
		filters: [tbl] a List of filters the user can select from when browsing files. The table can contain tables or strings.
			tbl: If a table is used for a filter, it should contain two elements. The first element is the filter while the second
				element is the description of the filter e.g. {"*.lua", "Lua files"}
			String: If a raw string is used, then it should just be the filter. It is recommended to use the table option since a
				description can be given for each filter.
		include_parent: [Boolean] This option will include the parent '..' directory item in the file/dialog list. This option is
			true by default.

	rtn: [tbl] Returns items for how the user interacted with this file dialog.
		button: [String] The button the user clicked. Will either be OK or Cancel.
		files: [tbl] An array of selected file items the user selected when OK is pressed. Will be empty otherwise.
--]]
function Slab.file_dialog(options)
	return Dialog.file_dialog(options)
end

--[[
	ColorPicker

	Displays a window to allow the user to pick a hue and saturation value of a color. This should be called every frame and the result
	should be handled to stop displaying the color picker and store the resulting color.

	options: [tbl] List of options that control the behavior of the color picker.
		colour: [tbl] The color to modify. This should be in the format of 0-1 for each color component (RGBA).

	rtn: [tbl] Returns the button and color the user has selected.
		button: [String] The button the user clicked. Will either be OK or Cancel.
		colour: [tbl] The new color the user has chosen. This will always be returned.
--]]
function Slab.ColorPicker(options)
	return ColorPicker.begin(options)
end

--[[
	is_mouse_down

	Determines if a given mouse button is down.

	button: [Number] The button to check for. The valid numbers are: 1 - Left, 2 - Right, 3 - Middle.

	rtn: [Boolean] True if the given button is down. False otherwise.
--]]
function Slab.is_mouse_down(button)
	return Mouse.is_down(button and button or 1)
end

--[[
	is_mouse_clicked

	Determines if a given mouse button changes state from up to down this frame.

	button: [Number] The button to check for. The valid numbers are: 1 - Left, 2 - Right, 3 - Middle.

	rtn: [Boolean] True if the given button changes state from up to down. False otherwise.
--]]
function Slab.is_mouse_clicked(button)
	return Mouse.is_clicked(button and button or 1)
end

--[[
	is_mouse_released

	Determines if a given mouse button changes state from down to up this frame.

	button: [Number] The button to check for. The valid numbers are: 1 - Left, 2 - Right, 3 - Middle.

	rtn: [Boolean] True if the given button changes state from down to up. False otherwise.
--]]
function Slab.is_mouse_released(button)
	return Mouse.is_released(button and button or 1)
end

--[[
	is_mouse_double_clicked

	Determines if a given mouse button has been clicked twice within a given time frame.

	button: [Number] The button to check for. The valid numbers are: 1 - Left, 2 - Right, 3 - Middle.

	rtn: [Boolean] True if the given button was double clicked. False otherwise.
--]]
function Slab.is_mouse_double_clicked(button)
	return Mouse.is_double_clicked(button and button or 1)
end

--[[
	is_mouse_dragging

	Determines if a given mouse button is down and there has been movement.

	button: [Number] The button to check for. The valid numbers are: 1 - Left, 2 - Right, 3 - Middle.

	rtn: [Boolean] True if the button is held down and is moving. False otherwise.
--]]
function Slab.is_mouse_dragging(button)
	return Mouse.is_dragging(button and button or 1)
end

--[[
	get_mouse_position

	Retrieves the current mouse position in the viewport.

	rtn: [Number], [Number] The x and y coordinates of the mouse position.
--]]
function Slab.get_mouse_position()
	return Mouse.position()
end

--[[
	get_mouse_position_window

	Retrieves the current mouse position within the current window. This position will include any transformations 
	added to the window such as scrolling.

	rtn: [Number], [Number] The x and y coordinates of the mouse position within the window.
--]]
function Slab.get_mouse_position_window()
	return Window.get_mouse_position()
end

--[[
	get_mouse_delta

	Retrieves the change in mouse coordinates from the last frame.

	rtn: [Number], [Number] The x and y coordinates of the delta from the last frame.
--]]
function Slab.get_mouse_delta()
	return Mouse.get_delta()
end

--[[
	is_control_hovered

	Checks to see if the last control added to the window is hovered by the mouse.

	rtn: [Boolean] True if the last control is hovered, false otherwise.
--]]
function Slab.is_control_hovered()
	-- Prevent hovered checks on mobile if user is not dragging a touch.
	if Utility.is_mobile() and not Slab.is_mouse_down() then
		return false
	end

	local result = Window.IsItemHot()

	if not result and not Window.is_obstructed_at_mouse() then
		local x, y = Slab.get_mouse_position_window()
		result = Cursor.is_in_item_bounds(x, y)
	end

	return result
end

--[[
	is_control_clicked

	Checks to see if the previous control is hovered and clicked.

	button: [Number] The button to check for. The valid numbers are: 1 - Left, 2 - Right, 3 - Middle.

	rtn: [Boolean] True if the previous control is hovered and clicked. False otherwise.
--]]
function Slab.is_control_clicked(button)
	return Slab.is_control_hovered() and Slab.is_mouse_clicked(button)
end

--[[
	get_control_size

	Retrieves the last declared control's size.

	rtn: [Number], [Number] The width and height of the last control declared.
--]]
function Slab.get_control_size()
	local x, y, w, h = Cursor.get_item_bounds()
	return w, h
end

--[[
	is_void_hovered

	Checks to see if any non-Slab area of the viewport is hovered.

	rtn: [Boolean] True if any non-Slab area of the viewport is hovered. False otherwise.
--]]
function Slab.is_void_hovered()
	-- Prevent hovered checks on mobile if user is not dragging a touch.
	if Utility.is_mobile() and not Slab.is_mouse_down() then
		return false
	end

	return Region.get_hot_instance_id() == "" and not Region.is_scrolling()
end

--[[
	is_void_clicked

	Checks to see if any non-Slab area of the viewport is clicked.

	button: [Number] The button to check for. The valid numbers are: 1 - Left, 2 - Right, 3 - Middle.

	rtn: [Boolean] True if any non-Slab area of the viewport is clicked. False otherwise.
--]]
function Slab.is_void_clicked(button)
	return Slab.is_mouse_clicked(button) and Slab.is_void_hovered()
end

--[[
	is_key_down

	Checks to see if a specific key is held down. The key should be one of the love defined Scancode which the list can
	be found at https://love2d.org/wiki/Scancode.

	key: [String] a love defined key scancode.

	rtn: [Boolean] True if the key is held down. False otherwise.
--]]
function Slab.is_key_down(key)
	return Keyboard.is_down(key)
end

--[[
	is_key_pressed

	Checks to see if a specific key state went from up to down this frame. The key should be one of the love defined Scancode which the list can
	be found at https://love2d.org/wiki/Scancode.

	key: [String] a love defined scancode.

	rtn: [Boolean] True if the key state went from up to down this frame. False otherwise.
--]]
function Slab.is_key_pressed(key)
	return Keyboard.is_pressed(key)
end

--[[
	is_key_pressed

	Checks to see if a specific key state went from down to up this frame. The key should be one of the love defined Scancode which the list can
	be found at https://love2d.org/wiki/Scancode.

	key: [String] a love defined scancode.

	rtn: [Boolean] True if the key state went from down to up this frame. False otherwise.
--]]
function Slab.is_key_released(key)
	return Keyboard.is_released(key)
end

--[[
	rectangle

	Draws a rectangle at the current cursor position for the active window.

	options: [tbl] List of options that control how this rectangle is displayed.
		mode: [String] Whether this rectangle should be filled or outlined. The default value is 'fill'.
		w: [Number] The width of the rectangle.
		h: [Number] The height of the rectangle.
		colour: [tbl] The color to use for this rectangle.
		rounding: [Number] or [tbl]
			[Number] Amount of rounding to apply to all corners.
			[tbl] Define the rounding for each corner. The order goes top left, top right, bottom right, and bottom left.
		outline: [Boolean] If the mode option is 'fill', this option will allow an outline to be drawn.
		outline_color: [tbl] The color to use for the outline if requested.
		segments: [Number] Number of points to add for each corner if rounding is requested.

	rtn: None.
--]]
function Slab.rectangle(options)
	Shape.rectangle(options)
end

--[[
	circle

	Draws a circle at the current cursor position plus the radius for the active window.

	options: [tbl] List of options that control how this circle is displayed.
		mode: [String] Whether this circle should be filled or outlined. The default value is 'fill'.
		radius: [Number] The size of the circle.
		colour: [tbl] The color to use for the circle.
		segments: [Number] The number of segments used for drawing the circle.

	rtn: None.
--]]
function Slab.circle(options)
	Shape.circle(options)
end

--[[
	triangle

	Draws a triangle at the current cursor position plus the radius for the active window.

	Option: [tbl] List of options that control how this triangle is displayed.
		mode: [String] Whether this triangle should be filled or outlined. The default value is 'fill'.
		radius: [Number] The distance from the center of the triangle.
		rotation: [Number] The rotation of the triangle in degrees.
		colour: [tbl] The color to use for the triangle.

	rtn: None.
--]]
function Slab.triangle(options)
	Shape.triangle(options)
end

--[[
	line

	Draws a line starting at the current cursor position and going to the defined points in this function.

	x_2: [Number] The x coordinate for the destination.
	y_2: [Number] The y coordinate for the destination.
	Option: [tbl] List of options that control how this line is displayed.
		width: [Number] How thick the line should be.
		colour: [tbl] The color to use for the line.

	rtn: None.
--]]
function Slab.line(x_2, y_2, options)
	Shape.line(x_2, y_2, options)
end

--[[
	curve

	Draws a bezier curve with the given points as control points. The points should be defined in local space. Slab will translate the curve to the
	current cursor position. There should two or more points defined for a proper curve.

	points: [tbl] List of points to define the control points of the curve.
	options: [tbl] List of options that control how this curve is displayed.
		colour: [tbl] The color to use for this curve.
		depth: [Number] The number of recursive subdivision steps to use when rendering the curve. If nil, the default LÖVE 2D value is used which is 5.

	rtn: None.
--]]
function Slab.curve(points, options)
	Shape.curve(points, options)
end

--[[
	get_curve_control_point_count

	Returns the number of control points defined with the last call to curve.

	rtn: [Number] The number of control points defined for the previous curve.
--]]
function Slab.get_curve_control_point_count()
	return Shape.get_curve_control_point_count()
end

--[[
	get_curve_control_point

	Returns the point for the given control point index. This point by default will be in local space defined by the points given in the curve function.
	The translated position can be requested by setting the local_space option to false.

	index: [Number] The index of the control point to retrieve.
	options: [tbl] a List of options that control what is returned by this function.
		local_space: [Boolean] Returns either the translated or untranslated control point. This is true by default.

	rtn: [Number], [Number] The translated x, y coordinates of the given control point.
--]]
function Slab.get_curve_control_point(index, options)
	return Shape.get_curve_control_point(index, options)
end

--[[
	evaluate_curve

	Returns the point at the given time. The time value should be between 0 and 1 inclusive. The point returned will be in local space. For the translated
	position, set the local_space option to false.

	time: [Number] The time on the curve between 0 and 1.
	options: [tbl] a List of options that control what is returned by this function.
		local_space: [Boolean] Returnes either the translated or untranslated control point. This is true by default.

	rtn: [Number], [Number] The x and y coordinates at the given time on the curve.
--]]
function Slab.evaluate_curve(time, options)
	return Shape.evaluate_curve(time, options)
end

--[[
	evaluate_curve_mouse

	Returns the point on the curve at the given x-coordinate of the mouse relative to the end points of the curve.

	options: [tbl] a List of options that control what is returned by this function.
		Refer to the documentation for evaluate_curve for the List of options.

	rtn: [Number], [Number] The x and y coordinates at the given x mouse position on the curve.
--]]
function Slab.evaluate_curve_mouse(options)
	local x_1, y_1 = Slab.get_curve_control_point(1, {local_space = false})
	local x_2, y_2 = Slab.get_curve_control_point(Slab.get_curve_control_point_count(), {local_space = false})
	local Left = math.min(x_1, x_2)
	local w = math.abs(x_2 - x_1)
	local x, y = Slab.get_mouse_position_window()
	local offset = math.max(x - Left, 0.0)
	offset = math.min(offset, w)

	return Slab.evaluate_curve(offset / w, options)
end

--[[
	polygon

	Renders a polygon with the given points. The points should be defined in local space. Slab will translate the position to the current cursor position.

	points: [tbl] List of points that define this polygon.
	options: [tbl] List of options that control how this polygon is drawn.
		colour: [tbl] The color to render this polygon.
		mode: [String] Whether to use 'fill' or 'line' to draw this polygon. The default is 'fill'.

	rtn: None.
--]]
function Slab.polygon(points, options)
	Shape.polygon(points, options)
end

--[[
	begin_stat

	Starts the timer for the specific stat in the given category.

	name: [String] The name of the stat to capture.
	category: [String] The category this stat belongs to.

	rtn: [Number] The handle identifying this stat capture.
--]]
function Slab.begin_stat(name, category)
	return Stats.begin(name, category)
end

--[[
	end_stat

	Ends the timer for the stat assigned to the given handle.

	handle: [Number] The handle identifying a begin_stat call.

	rtn: None.
--]]
function Slab.end_stat(handle)
	Stats.finish(handle)
end

--[[
	enable_stats

	Sets the enabled state of the stats system. The system is disabled by default.

	Enable: [Boolean] The new state of the states system.

	rtn: None.
--]]
function Slab.enable_stats(Enable)
	Stats.set_enabled(Enable)
end

--[[
	is_stats_enabled

	Query whether the stats system is enabled or disabled.

	rtn: [Boolean] Returns whether the stats system is enabled or disabled.
--]]
function Slab.is_stats_enabled()
	return Stats.is_enabled()
end

--[[
	flush_stats

	Resets the stats system to an empty state.

	rtn: None.
--]]
function Slab.flush_stats()
	Stats.flush()
end

--[[
	begin_layout

	Enables the layout manager and positions the controls between this call and end_layout based on the given options. The anchor
	position for the layout is determined by the current cursor position on the y axis. The horizontal position is not anchored.
	Layouts are stacked, so there can be layouts within parent layouts.

	id: [String] The id of this layout.
	options: [tbl] List of options that control how this layout behaves.
		align_x: [String] Defines how the controls should be positioned horizontally in the window. The available options are 
			'left', 'center', or 'right'. The default option is 'left'.
		align_y: [String] Defines how the controls should be positioned vertically in the window. The available options are
			'top', 'center', or 'Bottom'. The default option is 'top'. The top is determined by the current cursor position.
		align_row_y: [String] Defines how the controls should be positioned vertically within a row. The available options are
			'top', 'center', or 'Bottom'. The default option is 'top'.
		ignore: [Boolean] Should this layout ignore positioning of controls. This is useful if certain controls need custom
			positioning within a layout.
		expand_w: [Boolean] If true, will expand all controls' width within the row to the size of the window.
		expand_h: [Boolean] If true, will expand all controls' height within the row and the size of the window.
		anchor_x: [Boolean] Anchors the layout management at the current x cursor position. The size is calculated using this position.
			The default value for this is false.
		anchor_y: [Boolean] Anchors the layout management at the current y cursor position. The size is calculated using this position.
			The default value for this is true.
		columns: [Number] The number of columns to use for this layout. The default value is 1.

	rtn: None.
--]]
function Slab.begin_layout(id, options)
	LayoutManager.begin(id, options)
end

--[[
	end_layout

	Ends the currently active layout. Each begin_layout call must have a matching end_layout. Failure to do so will result in
	an assertion.

	rtn: None.
--]]
function Slab.end_layout()
	LayoutManager.finish()
end

--[[
	set_layout_column

	Sets the current active column.

	index: [Number] The index of the column to be active.

	rtn: None.
--]]
function Slab.set_layout_column(index)
	LayoutManager.set_column(index)
end

--[[
	get_layout_size

	Retrieves the size of the active layout. If there are columns, then the size of the column is returned.

	rtn: [Number], [Number] The width and height of the active layout. 0 is returned if no layout is active.
--]]
function Slab.get_layout_size()
	return LayoutManager.get_active_size()
end

--[[
	set_scroll_speed

	Sets the speed of scrolling when using the mouse wheel.

	rtn: None.
--]]
function Slab.set_scroll_speed(speed)
	Region.set_wheel_speed(speed)
end

--[[
	get_scroll_speed

	Retrieves the speed of scrolling for the mouse wheel.

	rtn: [Number] The current wheel scroll speed.
--]]
function Slab.get_scroll_speed()
	return Region.get_wheel_speed()
end

--[[
	push_shader

	Pushes a shader effect to be applied to any following controls before a call to pop_shader. Any shader effect that is still active
	will be cleared at the end of Slab's draw call.

	Shader: [object] The shader object created with the love.graphics.newShader function. This object should be managed by the caller.

	rtn: None.
--]]
function Slab.push_shader(Shader)
	DrawCommands.push_shader(Shader)
end

--[[
	pop_shader

	Pops the currently active shader effect. Will enable the next active shader on the stack. If none exists, no shader is applied.

	rtn: None.
--]]
function Slab.pop_shader()
	DrawCommands.pop_shader()
end

--[[
	enable_docks

	Enables the docking functionality for a particular side of the viewport.

	list: [String/tbl] a single item or List of items to enable for docking. The valid options are 'Left', 'Right', or 'Bottom'.

	rtn: None.
--]]
function Slab.enable_docks(list)
	Dock.toggle(list, true)
end

--[[
	disable_docks

	Disables the docking functionality for a particular side of the viewport.

	list: [String/tbl] a single item or List of items to disable for docking. The valid options are 'Left', 'Right', or 'Bottom'.

	rtn: None.
--]]
function Slab.disable_docks(list)
	Dock.toggle(list, false)
end

--[[
	set_dock_options

	set options for a dock t.

	t: [String] The t of dock to set options for. This can be 'Left', 'Right', or 'Bottom'.
	options: [tbl] List of options that control how a dock behaves.
		no_saved_settings: [Boolean] Flag to disable saving a dock's settings to the state INI file.
--]]
function Slab.set_dock_options(t, options)
	Dock.set_options(t, options)
end

return Slab
