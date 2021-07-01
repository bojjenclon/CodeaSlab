--[[

MIT License

Copyright (c) 2019-2020 Mitchell Davis <coding.jackalope@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR a PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]]
local Slab = required("Slab")
local SlabDebug = required("SlabDebug")

local SlabTest = {}

local function DrawOverview()
	Slab.textf(
		"Slab is an immediate mode GUI toolkit for the LÖVE 2D framework. This library " ..
			"is designed to allow users to easily add this library to their existing LÖVE 2D projects and " ..
				"quickly create tools to enable them to iterate on their ideas quickly. The user should be able " ..
					"to utilize this library with minimal integration steps and is completely written in Lua and utilizes " ..
						"the LÖVE 2D API. No compiled binaries are required and the user will have access to the source so " ..
							"that they may make adjustments that meet the needs of their own projects and tools. Refer to main.lua " ..
								"and SlabTest.lua for example usage of this library.\n\n" ..
									"This window will demonstrate the usage of the Slab library and give an overview of all the supported controls " ..
										"and features."
	)

	Slab.new_line()

	Slab.text("The current version of Slab is: ")
	Slab.same_line()
	Slab.text(Slab.get_version(), {colour = {0, 1, 0, 1}})

	Slab.text("The current version of LÖVE is: ")
	Slab.same_line()
	Slab.text(Slab.get_love_version(), {colour = {0, 1, 0, 1}})

	Slab.text("The current OS is: ")
	Slab.same_line()
	Slab.text(love.system.getOS(), {colour = {0, 1, 0, 1}})
end

local DrawButtons_NumClicked = 0
local DrawButtons_NumClicked_Invisible = 0
local DrawButtons_Enabled = false
local DrawButtons_Hovered = false

local function DrawButtons()
	Slab.textf(
		"buttons are simple controls which respond to a user's left mouse click. buttons will simply return true when they are clicked."
	)

	Slab.new_line()

	if Slab.button("button") then
		DrawButtons_NumClicked = DrawButtons_NumClicked + 1
	end

	Slab.same_line()
	Slab.text("You have clicked this button " .. DrawButtons_NumClicked .. " time(s).")

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"buttons can be tested for mouse hover with the call to Slab.is_control_hovered right after declaring the Button."
	)
	Slab.button(DrawButtons_Hovered and "hovered" or "Not hovered", {w = 100})
	DrawButtons_Hovered = Slab.is_control_hovered()

	Slab.new_line()
	Slab.separator()

	Slab.textf("buttons can have a custom width and height.")
	Slab.button("Square", {w = 75, h = 75})

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"buttons can also be invisible so that the designer can implement a custom button but still rely on the " ..
			"button behavior. Below is a an invisible button and a custom rectangle drawn at the same location."
	)
	local x, y = Slab.get_cursor_pos()
	Slab.rectangle({mode = "line", w = 50.0, h = 50.0, colour = {1, 1, 1, 1}})
	Slab.set_cursor_pos(x, y)

	if Slab.button("", {invisible = true, w = 50.0, h = 50.0}) then
		DrawButtons_NumClicked_Invisible = DrawButtons_NumClicked_Invisible + 1
	end

	Slab.same_line({center_y = true})
	Slab.text("invisible button has been clicked " .. DrawButtons_NumClicked_Invisible .. " time(s).")

	Slab.new_line()
	Slab.separator()

	Slab.textf("buttons can also be disabled. Click the button below to toggle the status of the neighboring Button.")

	if Slab.button("toggle") then
		DrawButtons_Enabled = not DrawButtons_Enabled
	end

	Slab.same_line()
	Slab.button(DrawButtons_Enabled and "enabled" or "disabled", {disabled = not DrawButtons_Enabled})
end

local DrawText_Width = 450.0
local DrawText_Alignment = {"left", "center", "right", "justify"}
local DrawText_Alignment_Selected = "left"
local DrawText_NumClicked = 0
local DrawText_NumClicked_TextOnly = 0

local function DrawText()
	Slab.textf("text controls displays text on the current window. Slab currently offers three ways to control the text.")

	Slab.new_line()
	Slab.separator()

	Slab.text("The most basic text control is Slab.text.")
	Slab.text("The color of the text can be controlled with the 'colour' option.", {colour = {0, 1, 0, 1}})

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"text can be formatted using the Slab.textf API. Formatted text will wrap the text based on the 'w' option. " ..
			"If the 'w' option is not specified, the window's width will be used as the width. Formatted text also has an " ..
				"alignment option."
	)

	Slab.new_line()
	Slab.text("width")
	Slab.same_line()
	if Slab.input("DrawText_Width", {text = tostring(DrawText_Width), numbers_only = true, return_on_text = false}) then
		DrawText_Width = Slab.get_input_number()
	end

	Slab.same_line()
	Slab.text("Alignment")
	Slab.same_line()
	if Slab.begin_combo_box("DrawText_Alignment", {selected = DrawText_Alignment_Selected}) then
		for i, v in ipairs(DrawText_Alignment) do
			if Slab.text_selectable(v) then
				DrawText_Alignment_Selected = v
			end
		end

		Slab.end_combo_box()
	end

	Slab.textf(
		"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore " ..
			"et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut " ..
				"aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum " ..
					"dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui " ..
						"officia deserunt mollit anim id est laborum.",
		{w = DrawText_Width, align = DrawText_Alignment_Selected}
	)

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"text can also be interacted with using the Slab.text_selectable function. a background will be " ..
			"rendered when the mouse is hovered over the text and the function will return true when clicked on. " ..
				"The selectable area expands to the width of the window by default. This can be changed to just the text " ..
					"with the 'is_selectable_text_only' option."
	)

	Slab.new_line()
	if Slab.text_selectable("This text has been clicked " .. DrawText_NumClicked .. " time(s).") then
		DrawText_NumClicked = DrawText_NumClicked + 1
	end

	Slab.new_line()
	if
		Slab.text_selectable(
			"This text has been clicked " .. DrawText_NumClicked_TextOnly .. " time(s).",
			{is_selectable_text_only = true}
		)
	 then
		DrawText_NumClicked_TextOnly = DrawText_NumClicked_TextOnly + 1
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"text controls can be configured to contain url links. When this control is clicked, Slab will open the given url " ..
			"with the user's default web browser."
	)

	Slab.text("Love 2D", {url = "http://love2d.org"})
end

local DrawCheckBox_Checked = false
local DrawCheckBox_Checked_NoLabel = false

local function DrawCheckBox()
	Slab.textf(
		"check boxes are controls that will display an empty box with an optional label. The function will " ..
			"return true if the user has clicked on the box. The code is then responsible for updating the checked " ..
				"flag to be passed back into the function."
	)

	Slab.new_line()
	if Slab.checkBox(DrawCheckBox_Checked, "check Box") then
		DrawCheckBox_Checked = not DrawCheckBox_Checked
	end

	Slab.new_line()
	Slab.text("a check box with no label.")
	if Slab.checkBox(DrawCheckBox_Checked_NoLabel) then
		DrawCheckBox_Checked_NoLabel = not DrawCheckBox_Checked_NoLabel
	end
end

local DrawRadioButton_Selected = 1

local function DrawRadioButton()
	Slab.textf("Radio buttons offer the user to select one option from a List of options.")

	Slab.new_line()
	for i = 1, 5, 1 do
		if Slab.radio_button("Option " .. i, {index = i, selected_index = DrawRadioButton_Selected}) then
			DrawRadioButton_Selected = i
		end
	end
end

local DrawMenus_Window_Selected = "Right click and select an option."
local DrawMenus_Control_Selected = "Right click and select an option from a control."
local DrawMenus_CheckBox = false
local DrawMenus_ComboBox = {"Apple", "Banana", "Pear", "Orange", "Lemon"}
local DrawMenus_ComboBox_Selected = "Apple"

local function DrawContextMenuItem(label, button)
	if Slab.begin_context_menu_item(button) then
		for i = 1, 5, 1 do
			local MenuLabel = label .. " Option " .. i
			if Slab.menu_item(MenuLabel) then
				DrawMenus_Control_Selected = MenuLabel
			end
		end

		Slab.end_context_menu()
	end
end

local function DrawMenus()
	Slab.textf(
		"Menus are windows that allow users to make a selection from a List of items. items can be disabled to prevent " ..
			"any interaction but will still be displayed. Below are descriptions of the various menus and how they can be utilized."
	)

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"The main menu bar is rendered at the top of the window with menu items being added " ..
			"from left to right. When a menu item is clicked, a context menu is opened below the " ..
				"selected item. Creating the main menu bar can open anywhere in the code after the " ..
					"Slab.update call. These functions should not be called within a begin_window/end_window " .. "call."
	)

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Context menus are menus which are rendered above all other controls to allow the user to make a selection " ..
			"out of a List of items. These can be opened up through the menu bar, or through a right-click " ..
				"action from the user on a given window or control. Menus and menu items make up the context menu " ..
					"and menus can be nested to allow a tree options to be displayed."
	)

	Slab.new_line()

	Slab.textf(
		"controls can have their own context menus. Right-click on each control to open up the menu " ..
			"and select an option."
	)

	Slab.new_line()
	Slab.text(DrawMenus_Control_Selected)
	Slab.new_line()

	Slab.button("button")
	DrawContextMenuItem("button")

	Slab.text("text")
	DrawContextMenuItem("text")

	if Slab.checkBox(DrawMenus_CheckBox, "check Box") then
		DrawMenus_CheckBox = not DrawMenus_CheckBox
	end
	DrawContextMenuItem("check Box")

	Slab.input("DrawMenus_Input")
	DrawContextMenuItem("Input")

	if Slab.begin_combo_box("DrawMenus_ComboBox", {selected = DrawMenus_ComboBox_Selected}) then
		for i, v in ipairs(DrawMenus_ComboBox) do
			if Slab.text_selectable(v) then
				DrawMenus_Window_Selected = v
			end
		end

		Slab.end_combo_box()
	end
	DrawContextMenuItem("Combo Box")

	Slab.new_line()
	Slab.textf(
		"Context menu items are usually opened with the right mouse Button. This can be changed for context menus to be a differen " ..
			"mouse Button. The button below will open a context menu using the left mouse Button."
	)

	Slab.new_line()
	Slab.button("Left Mouse")
	DrawContextMenuItem("Left Mouse button", 1)

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Right-clicking anywhere within this window will open up a context menu. Note that begin_context_menu_window " ..
			"must come after all begin_context_menu_item calls."
	)

	Slab.new_line()

	Slab.textf(DrawMenus_Window_Selected)

	if Slab.begin_context_menu_window() then
		if Slab.begin_menu("Window Menu 1") then
			for i = 1, 5, 1 do
				local enabled = i % 2 ~= 0
				if Slab.menu_item("sub Window Option " .. i, {enabled = enabled}) then
					DrawMenus_Window_Selected = "sub Window Option " .. i
				end
			end

			Slab.end_menu()
		end

		for i = 1, 5, 1 do
			if Slab.menu_item("Window Option " .. i) then
				DrawMenus_Window_Selected = "Window Option " .. i .. " selected."
			end
		end

		Slab.end_context_menu()
	end
end

local DrawComboBox_Options = {
	"England",
	"France",
	"Germany",
	"USA",
	"Canada",
	"Mexico",
	"Japan",
	"South Korea",
	"China",
	"Russia",
	"India"
}
local DrawComboBox_Selected = "USA"
local DrawComboBox_Selected_Width = "USA"

local function DrawComboBox()
	Slab.textf(
		"a combo box allows the user to select a single item from a list and display the selected item " ..
			"in the combo box. The list is only visible when the user is interacting with the control."
	)

	Slab.new_line()

	if Slab.begin_combo_box("DrawComboBox_One", {selected = DrawComboBox_Selected}) then
		for i, v in ipairs(DrawComboBox_Options) do
			if Slab.text_selectable(v) then
				DrawComboBox_Selected = v
			end
		end

		Slab.end_combo_box()
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf("a combo box's width can be modified with the 'w' option.")

	Slab.new_line()

	local w, h = Slab.get_window_active_size()
	if Slab.begin_combo_box("DrawComboBox_Two", {selected = DrawComboBox_Selected_Width, w = w}) then
		for i, v in ipairs(DrawComboBox_Options) do
			if Slab.text_selectable(v) then
				DrawComboBox_Selected_Width = v
			end
		end

		Slab.end_combo_box()
	end
end

local DrawInput_Basic = "Hello World"
local DrawInput_Basic_Return = "Hello World"
local DrawInput_Basic_Numbers = 0
local DrawInput_Basic_Numbers_Clamped = 0.5
local DrawInput_Basic_Numbers_Clamped_Min = 0.0
local DrawInput_Basic_Numbers_Clamped_Max = 1.0
local DrawInput_Basic_Numbers_Clamped_Step = 0.01
local DrawInput_Basic_Numbers_NoDrag = 50
local DrawInput_Basic_Numbers_Slider = 50
local DrawInput_Basic_Numbers_Slider_Min = 0
local DrawInput_Basic_Numbers_Slider_Max = 100
local DrawInput_MultiLine = [[
function Foo()
	print("Bar")
end

The quick brown fox jumped over the lazy dog.]]
local DrawInput_MultiLine_Width = math.huge
local DrawInput_CursorPos = 0
local DrawInput_CursorColumn = 0
local DrawInput_CursorLine = 0
local DrawInput_Highlight_Text = [[
function Hello()
	print("World")
end]]
local DrawInput_Highlight_Table = {
	["function"] = {1, 0, 0, 1},
	["end"] = {0, 0, 1, 1}
}
local DrawInput_Highlight_Table_Modify = nil

local function DrawInput()
	Slab.textf(
		"The input control allows the user to enter in text into an input box. This control is similar " ..
			"to input boxes found in other applications. These controls are set up to handle UTF8 characters."
	)

	Slab.new_line()

	Slab.textf(
		"The first example is very simple. An Input control is declared and the resulting text is captured if " ..
			"the function returns true. By default, the function will return true on any text that is entered."
	)

	if Slab.input("DrawInput_Basic", {text = DrawInput_Basic}) then
		DrawInput_Basic = Slab.GetInputText()
	end

	Slab.new_line()

	Slab.textf(
		"The return behavior can be modified so that the function will only return true if the Enter/rtn " ..
			"key is pressed. If the control loses focus without the Enter/rtn key pressed, then the text will " ..
				"revert back to what it was before."
	)

	if Slab.input("DrawInput_Basic_Return", {text = DrawInput_Basic_Return, return_on_text = false}) then
		DrawInput_Basic_Return = Slab.GetInputText()
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Input controls can be configured to only take numeric values. Input controls that are configured this way " ..
			"will allow the user to click and drag the control to alter the value by default. The user must double-click the " ..
				"control to manually enter a valid number."
	)

	if Slab.input("DrawInput_Basic_Numbers", {text = tostring(DrawInput_Basic_Numbers), numbers_only = true}) then
		DrawInput_Basic_Numbers = Slab.get_input_number()
	end

	Slab.new_line()

	Slab.textf(
		"These numeric controls can also have min and/or max values set. Below is an example where the " ..
			"numeric input control is clamped from 0.0 to 1.0. The drag step is also modified to be smaller for more precision."
	)

	Slab.text("min_val")
	Slab.same_line()
	local DrawInput_Basic_Numbers_Clamped_Min_Options = {
		text = tostring(DrawInput_Basic_Numbers_Clamped_Min),
		max_number = DrawInput_Basic_Numbers_Clamped_Max,
		step = DrawInput_Basic_Numbers_Clamped_Step,
		numbers_only = true,
		w = 50
	}
	if Slab.input("DrawInput_Basic_Numbers_Clamped_Min", DrawInput_Basic_Numbers_Clamped_Min_Options) then
		DrawInput_Basic_Numbers_Clamped_Min = Slab.get_input_number()
	end

	Slab.same_line()
	Slab.text("max_val")
	Slab.same_line()
	local DrawInput_Basic_Numbers_Clamped_Max_Options = {
		text = tostring(DrawInput_Basic_Numbers_Clamped_Max),
		min_number = DrawInput_Basic_Numbers_Clamped_Min,
		step = DrawInput_Basic_Numbers_Clamped_Step,
		numbers_only = true,
		w = 50
	}
	if Slab.input("DrawInput_Basic_Numbers_Clamped_Max", DrawInput_Basic_Numbers_Clamped_Max_Options) then
		DrawInput_Basic_Numbers_Clamped_Max = Slab.get_input_number()
	end

	Slab.same_line()
	Slab.text("step")
	Slab.same_line()
	local DrawInput_Basic_Numbers_Clamped_Step_Options = {
		text = tostring(DrawInput_Basic_Numbers_Clamped_Step),
		min_number = 0,
		step = 0.01,
		numbers_only = true,
		w = 50
	}
	if Slab.input("DrawInput_Basic_Numbers_Clamped_Step", DrawInput_Basic_Numbers_Clamped_Step_Options) then
		DrawInput_Basic_Numbers_Clamped_Step = Slab.get_input_number()
	end

	local DrawInput_Basic_Numbers_Clamped_Options = {
		text = tostring(DrawInput_Basic_Numbers_Clamped),
		numbers_only = true,
		min_number = DrawInput_Basic_Numbers_Clamped_Min,
		max_number = DrawInput_Basic_Numbers_Clamped_Max,
		step = DrawInput_Basic_Numbers_Clamped_Step
	}
	if Slab.input("DrawInput_Basic_Numbers_Clamped", DrawInput_Basic_Numbers_Clamped_Options) then
		DrawInput_Basic_Numbers_Clamped = Slab.get_input_number()
	end

	Slab.new_line()

	Slab.textf(
		"The click and drag functionality of numeric controls can also be disabled. This will make the input control behave like a " ..
			"standard text input control."
	)

	if
		Slab.input(
			"DrawInput_Basic_Numbers_NoDrag",
			{text = tostring(DrawInput_Basic_Numbers_NoDrag), numbers_only = true, no_drag = true}
		)
	 then
		DrawInput_Basic_Numbers_NoDrag = Slab.get_input_number()
	end

	Slab.new_line()

	Slab.textf(
		"a slider can also be used for these numeric input controls. When configured this way, the value is altered based on where the " ..
			"user clicks and drags inside the control."
	)

	Slab.text("min_val")
	Slab.same_line()
	if
		Slab.input_number_drag(
			"DrawInput_Basic_Numbers_Slider_Min",
			DrawInput_Basic_Numbers_Slider_Min,
			nil,
			DrawInput_Basic_Numbers_Slider_Max,
			{w = 50}
		)
	 then
		DrawInput_Basic_Numbers_Slider_Min = Slab.get_input_number()
	end

	Slab.same_line()
	Slab.text("max_val")
	Slab.same_line()
	if
		Slab.input_number_drag(
			"DrawInput_Basic_Numbers_Slider_Max",
			DrawInput_Basic_Numbers_Slider_Max,
			DrawInput_Basic_Numbers_Slider_Min,
			nil,
			{w = 50}
		)
	 then
		DrawInput_Basic_Numbers_Slider_Max = Slab.get_input_number()
	end

	if
		Slab.input_number_slider(
			"DrawInput_Basic_Numbers_Slider",
			DrawInput_Basic_Numbers_Slider,
			DrawInput_Basic_Numbers_Slider_Min,
			DrawInput_Basic_Numbers_Slider_Max
		)
	 then
		DrawInput_Basic_Numbers_Slider = Slab.get_input_number()
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Input controls also allow for multi-line editing using the multi_line option. The default text wrapping " ..
			"option is set to math.huge, but this can be modified with the multi_line_w option. The example below demonstrates " ..
				"how to set up a multi-line input control and shows how the size of the control can be modified."
	)

	Slab.new_line()
	Slab.text("multi_line_w")
	Slab.same_line()
	if
		Slab.input(
			"DrawInput_MultiLine_Width",
			{text = tostring(DrawInput_MultiLine_Width), numbers_only = true, return_on_text = false}
		)
	 then
		DrawInput_MultiLine_Width = Slab.get_input_number()
	end

	Slab.same_line()
	Slab.text("Cursor pos")
	Slab.same_line()
	if
		Slab.input(
			"DrawInput_CursorPos",
			{text = tostring(DrawInput_CursorPos), numbers_only = true, return_on_text = false, min_number = 0, w = 75}
		)
	 then
		DrawInput_CursorPos = Slab.get_input_number()
		Slab.set_input_focus("DrawInput_MultiLine")
		Slab.set_input_cursor_pos(DrawInput_CursorPos)
	end

	Slab.same_line()
	Slab.text("column")
	Slab.same_line()
	if
		Slab.input(
			"DrawInput_CursorColumn",
			{text = tostring(DrawInput_CursorColumn), numbers_only = true, return_on_text = false, min_number = 0, w = 75}
		)
	 then
		DrawInput_CursorColumn = Slab.get_input_number()
		Slab.set_input_focus("DrawInput_MultiLine")
		Slab.set_input_cursor_pos_line(DrawInput_CursorColumn, DrawInput_CursorLine)
	end

	Slab.same_line()
	Slab.text("line")
	Slab.same_line()
	if
		Slab.input(
			"DrawInput_CursorLine",
			{text = tostring(DrawInput_CursorLine), numbers_only = true, return_on_text = false, min_number = 0, w = 75}
		)
	 then
		DrawInput_CursorLine = Slab.get_input_number()
		Slab.set_input_focus("DrawInput_MultiLine")
		Slab.set_input_cursor_pos_line(DrawInput_CursorColumn, DrawInput_CursorLine)
	end

	local w, h = Slab.get_window_active_size()

	if
		Slab.input(
			"DrawInput_MultiLine",
			{text = DrawInput_MultiLine, multi_line = true, multi_line_w = DrawInput_MultiLine_Width, w = w, h = 150.0}
		)
	 then
		DrawInput_MultiLine = Slab.GetInputText()
	end

	if Slab.is_input_focused("DrawInput_MultiLine") then
		DrawInput_CursorPos, DrawInput_CursorColumn, DrawInput_CursorLine = Slab.get_input_cursor_pos()
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"The input control also offers a way to highlight certain words with a custom color. Below is a List of keywords and the color used to define the word."
	)

	Slab.new_line()

	local text_w, text_h = Slab.get_text_size("")

	for k, v in pairs(DrawInput_Highlight_Table) do
		if Slab.input("DrawInput_Highlight_Table_" .. k, {text = k, return_on_text = false}) then
			DrawInput_Highlight_Table[k] = nil
			k = Slab.GetInputText()
			DrawInput_Highlight_Table[k] = v
		end

		Slab.same_line({pad = 20.0})
		Slab.rectangle({w = 50, h = text_h, colour = v})

		if Slab.is_control_clicked() then
			DrawInput_Highlight_Table_Modify = k
		end

		Slab.same_line({pad = 20.0})

		if Slab.button("Delete", {h = text_h}) then
			DrawInput_Highlight_Table[k] = nil
		end
	end

	if Slab.button("Add") then
		DrawInput_Highlight_Table["new"] = {1, 0, 0, 1}
	end

	if DrawInput_Highlight_Table_Modify ~= nil then
		local result = Slab.ColorPicker({colour = DrawInput_Highlight_Table[DrawInput_Highlight_Table_Modify]})

		if result.button ~= "" then
			if result.button == "OK" then
				DrawInput_Highlight_Table[DrawInput_Highlight_Table_Modify] = result.colour
			end

			DrawInput_Highlight_Table_Modify = nil
		end
	end

	Slab.new_line()

	if
		Slab.input(
			"DrawInput_Highlight",
			{text = DrawInput_Highlight_Text, multi_line = true, highlight = DrawInput_Highlight_Table, w = w, h = 150.0}
		)
	 then
		DrawInput_Highlight_Text = Slab.GetInputText()
	end
end

local DrawImage_Path = SLAB_FILE_PATH .. "/Internal/Resources/Textures/power.png"
local DrawImage_Path_Icons = SLAB_FILE_PATH .. "/Internal/Resources/Textures/gameicons.png"
local DrawImage_Color = {1, 0, 0, 1}
local DrawImage_Color_Edit = false
local DrawImage_Scale = 1.0
local DrawImage_Scale_X = 1.0
local DrawImage_Scale_Y = 1.0
local DrawImage_Power = false
local DrawImage_Power_Hovered = false
local DrawImage_Power_On = {0, 1, 0, 1}
local DrawImage_Power_Off = {1, 0, 0, 1}
local DrawImage_Icon_X = 0
local DrawImage_Icon_Y = 0
local DrawImage_Icon_Move = false

local function DrawImage()
	Slab.textf(
		"Images can be drawn within windows and react to user interaction. a path to an image can be specified through the options of " ..
			"the img function. If this is done, Slab will manage the image resource and will use the path as a key to the resource."
	)

	Slab.image("DrawImage_Basic", {path = DrawImage_Path})

	Slab.new_line()
	Slab.separator()

	Slab.textf("An image's color can be modified with the 'colour' option.")

	if Slab.button("Change colour") then
		DrawImage_Color_Edit = true
	end

	if DrawImage_Color_Edit then
		local result = Slab.ColorPicker({colour = DrawImage_Color})

		if result.button ~= "" then
			DrawImage_Color_Edit = false

			if result.button == "OK" then
				DrawImage_Color = result.colour
			end
		end
	end

	Slab.image("DrawImage_Color", {path = DrawImage_Path, colour = DrawImage_Color})

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"There is an option to modify the scale of an image. The scale can both be affected " .. "on the x or y axis."
	)

	Slab.text("scale")
	Slab.same_line()
	if
		Slab.input("DrawImage_Scale", {text = tostring(DrawImage_Scale), numbers_only = true, return_on_text = false, w = 75})
	 then
		DrawImage_Scale = Slab.get_input_number()
		DrawImage_Scale_X = DrawImage_Scale
		DrawImage_Scale_Y = DrawImage_Scale
	end

	Slab.same_line({pad = 6.0})
	Slab.text("scale x")
	Slab.same_line()
	if
		Slab.input(
			"DrawImage_Scale_X",
			{text = tostring(DrawImage_Scale_X), numbers_only = true, return_on_text = false, w = 75}
		)
	 then
		DrawImage_Scale_X = Slab.get_input_number()
	end

	Slab.same_line({pad = 6.0})
	Slab.text("scale y")
	Slab.same_line()
	if
		Slab.input(
			"DrawImage_Scale_Y",
			{text = tostring(DrawImage_Scale_Y), numbers_only = true, return_on_text = false, w = 75}
		)
	 then
		DrawImage_Scale_Y = Slab.get_input_number()
	end

	Slab.image("DrawImage_Scale", {path = DrawImage_Path, scale_x = DrawImage_Scale_X, scale_y = DrawImage_Scale_Y})

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Images can also have interactions through the control API. The left image will change when the mouse is hovered " ..
			"while the right image will change on click."
	)

	Slab.image(
		"DrawImage_Hover",
		{path = DrawImage_Path, colour = DrawImage_Power_Hovered and DrawImage_Power_On or DrawImage_Power_Off}
	)
	DrawImage_Power_Hovered = Slab.is_control_hovered()

	Slab.same_line({pad = 12.0})
	Slab.image(
		"DrawImage_Click",
		{path = DrawImage_Path, colour = DrawImage_Power and DrawImage_Power_On or DrawImage_Power_Off}
	)
	if Slab.is_control_clicked() then
		DrawImage_Power = not DrawImage_Power
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"a sub region can be defined to draw a section of an image. Move the rectangle around and observe the image on the right."
	)

	local x, y = Slab.get_cursor_pos()
	local AbsX, AbsY = Slab.get_cursor_pos({Absolute = true})
	Slab.image("DrawImage_Icons", {path = DrawImage_Path_Icons})
	if Slab.is_control_clicked() then
		local mouse_x, mouse_y = Slab.get_mouse_position_window()
		local Left = AbsX + DrawImage_Icon_X
		local Right = Left + 50.0
		local top = AbsY + DrawImage_Icon_Y
		local bottom = top + 50.0
		if Left <= mouse_x and mouse_x <= Right and top <= mouse_y and mouse_y <= bottom then
			DrawImage_Icon_Move = true
		end
	end

	if Slab.is_mouse_released() then
		DrawImage_Icon_Move = false
	end

	local w, h = Slab.get_control_size()

	if DrawImage_Icon_Move then
		local delta_x, delta_y = Slab.get_mouse_delta()
		DrawImage_Icon_X = math.max(DrawImage_Icon_X + delta_x, 0.0)
		DrawImage_Icon_X = math.min(DrawImage_Icon_X, w - 50.0)

		DrawImage_Icon_Y = math.max(DrawImage_Icon_Y + delta_y, 0.0)
		DrawImage_Icon_Y = math.min(DrawImage_Icon_Y, h - 50.0)
	end

	Slab.set_cursor_pos(x + DrawImage_Icon_X, y + DrawImage_Icon_Y)
	Slab.rectangle({mode = "line", colour = {0, 0, 0, 1}, w = 50.0, h = 50.0})

	Slab.set_cursor_pos(x + w + 12.0, y)
	Slab.image(
		"DrawImage_Icons_Region",
		{
			path = DrawImage_Path_Icons,
			sub_x = DrawImage_Icon_X,
			sub_y = DrawImage_Icon_Y,
			sub_w = 50.0,
			sub_h = 50.0
		}
	)
end

local DrawCursor_NewLines = 1
local DrawCursor_SameLinePad = 4.0
local DrawCursor_X = nil
local DrawCursor_Y = nil
local DrawCursor_Indent = 14

local function draw_cursor()
	Slab.textf(
		"Slab offers a way to manage the drawing of controls through the cursor. Whenever a control is used, the cursor is " ..
			"automatically advanced based on the size of the control. By default, cursors are advanced vertically downward based " ..
				"on the control's height. However, functions are provided to move the cursor back up to the previous line or create " ..
					"an empty line to advance the cursor downward."
	)

	for i = 1, DrawCursor_NewLines, 1 do
		Slab.new_line()
	end

	Slab.textf(
		"There is a new line between this text and the above description. Modify the number of new lines using the " ..
			"input box below."
	)
	if
		Slab.input(
			"DrawCursor_NewLines",
			{text = tostring(DrawCursor_NewLines), numbers_only = true, return_on_text = false, min_number = 0}
		)
	 then
		DrawCursor_NewLines = Slab.get_input_number()
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Using the same_line function, controls can be layed out on a single line with additional padding. Below are two buttons on " ..
			"the same line with some padding. Use the input field below to modify the padding."
	)
	Slab.button("One")
	Slab.same_line({pad = DrawCursor_SameLinePad})
	Slab.button("Two")
	if
		Slab.input(
			"DrawCursor_SameLinePad",
			{text = tostring(DrawCursor_SameLinePad), numbers_only = true, return_on_text = false}
		)
	 then
		DrawCursor_SameLinePad = Slab.get_input_number()
	end

	Slab.new_line()

	Slab.textf(
		"The same_line function can also vertically center the next item based on the previous control. This is useful for labeling " ..
			"items that are much bigger than the text such as images."
	)
	Slab.image("DrawCursor_Image", {path = DrawImage_Path})
	Slab.same_line({center_y = true})
	Slab.text("This text is centered with respect to the previous image.")

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Slab offers functions to retrieve and set the cursor position. The get_cursor_pos function will return the cursor position " ..
			"relative to the current window. An option can be passed to retrieve the absolute position of the cursor with respect " ..
				"to the viewport."
	)

	local x, y = Slab.get_cursor_pos()
	Slab.text("Cursor x: " .. x)
	Slab.same_line()
	Slab.text("Cursor y: " .. y)

	local AbsX, AbsY = Slab.get_cursor_pos({Absolute = true})
	Slab.text("Absolute x: " .. AbsX)
	Slab.same_line()
	Slab.text("Absolute y: " .. AbsY)

	if DrawCursor_X == nil then
		DrawCursor_X, DrawCursor_Y = Slab.get_cursor_pos()
	end

	if Slab.input("DrawCursor_X", {text = tostring(DrawCursor_X), numbers_only = true, return_on_text = false}) then
		DrawCursor_X = Slab.get_input_number()
	end

	Slab.same_line()

	if Slab.input("DrawCursor_Y", {text = tostring(DrawCursor_Y), numbers_only = true, return_on_text = false}) then
		DrawCursor_Y = Slab.get_input_number()
	end

	Slab.set_cursor_pos(DrawCursor_X, DrawCursor_Y + 30.0)
	Slab.text("Use the input fields to move this text.")

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"There are also API functions to indent or unindent the anchored x position of the cursor. The function takes in a " ..
			"number which represents how far to advance/retreat in pixels from the current anchored position. If no number is " ..
				"given, then the default value is used which is defined by the indent property located in the Style table. Below " ..
					"are examples of how the indent/unindent functions can be used and while the example mainly uses text controls, these " ..
						"functions can be applied to any controls."
	)

	Slab.new_line()

	Slab.text("line 1")
	Slab.text("line 2")
	Slab.indent()
	Slab.text("Indented line 1")
	Slab.text("Indented line 2")
	Slab.indent()
	Slab.text("Indented line 3")
	Slab.unindent()
	Slab.text("Unindented line 1")
	Slab.text("Unindented line 2")
	Slab.unindent()
	Slab.text("Unindented line 3")

	Slab.new_line()
	Slab.indent(DrawCursor_Indent)
	Slab.text("indent:")
	Slab.same_line()
	if Slab.input("DrawCursor_Indent", {text = tostring(DrawCursor_Indent), numbers_only = true, return_on_text = false}) then
		DrawCursor_Indent = Slab.get_input_number()
	end
end

local DrawListBox_Basic_Selected = 1
local DrawListBox_Basic_Count = 10
local DrawListBox_Advanced_Selected = 1

local function DrawListBox()
	Slab.textf(
		"a list box is a scrollable region that contains a List of elements that a user can interact with. The API is flexible " ..
			"so that each element in the list can be rendered in any way desired. Below are a few examples on different ways a list " ..
				"box can be used."
	)

	Slab.new_line()

	local clear = false

	Slab.text("count")
	Slab.same_line()
	if
		Slab.input(
			"DrawListBox_Basic_Count",
			{text = tostring(DrawListBox_Basic_Count), numbers_only = true, min_number = 0, return_on_text = false}
		)
	 then
		DrawListBox_Basic_Count = Slab.get_input_number()
		clear = true
	end

	Slab.new_line()

	Slab.begin_list_box("DrawListBox_Basic", {clear = clear})
	for i = 1, DrawListBox_Basic_Count, 1 do
		Slab.begin_list_box_item("DrawListBox_Basic_Item_" .. i, {selected = i == DrawListBox_Basic_Selected})
		Slab.text("list Box item " .. i)
		if Slab.is_list_box_item_clicked() then
			DrawListBox_Basic_Selected = i
		end
		Slab.end_list_box_item()
	end
	Slab.end_list_box()

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Each list box can contain more than just text. Below is an example of list items with a triangle and a label."
	)

	Slab.new_line()

	Slab.begin_list_box("DrawListBox_Advanced")
	local rotation = 0
	for i = 1, 4, 1 do
		Slab.begin_list_box_item("DrawListBox_Advanced_Item_" .. i, {selected = i == DrawListBox_Advanced_Selected})
		Slab.triangle({radius = 24.0, rotation = rotation})
		Slab.same_line({center_y = true})
		Slab.text("triangle " .. i)
		if Slab.is_list_box_item_clicked() then
			DrawListBox_Advanced_Selected = i
		end
		Slab.end_list_box_item()
		rotation = rotation + 90
	end
	Slab.end_list_box()
end

local DrawTree_Icon_Path = SLAB_FILE_PATH .. "/Internal/Resources/Textures/Folder.png"
local DrawTree_Opened_Selected = 1
local DrawTree_Tables = nil

local function DrawTree()
	Slab.textf("Trees allow data to be viewed in a hierarchy. Trees can also contain leaf nodes which have no children.")

	Slab.new_line()

	if Slab.begin_tree("DrawTree_Root", {label = "root"}) then
		if Slab.begin_tree("DrawTree_Child_1", {label = "Child 1"}) then
			Slab.begin_tree("DrawTree_Child_1_Leaf_1", {label = "Leaf 1", is_leaf = true})
			Slab.end_tree()
		end

		Slab.begin_tree("DrawTree_Leaf_1", {label = "Leaf 2", is_leaf = true})

		if Slab.begin_tree("DrawTree_Child_2", {label = "Child 2"}) then
			Slab.begin_tree("DrawTree_Child_2_Leaf_3", {label = "Leaf 3", is_leaf = true})
			Slab.end_tree()
		end

		Slab.end_tree()
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"The hot zone of a tree item starts at the expander and extends to the width of the window's content. " ..
			"This can be configured to only allow the tree item to be opened/closed with the expander."
	)

	Slab.new_line()

	if Slab.begin_tree("DrawTree_Root_NoHighlight", {label = "root", open_with_highlight = false}) then
		Slab.begin_tree("DrawTree_Leaf", {label = "Leaf", is_leaf = true})

		if Slab.begin_context_menu_item() then
			Slab.menu_item("Leaf Option 1")
			Slab.menu_item("Leaf Option 2")

			Slab.end_context_menu()
		end

		Slab.end_tree()
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Tree items can have an icon associated with them. a loaded img object or path to an image can be " .. "specified."
	)

	Slab.new_line()

	if Slab.begin_tree("DrawTree_Root_Icon", {label = "Folder", icon_path = DrawTree_Icon_Path}) then
		Slab.begin_tree("DrawTree_Item_1", {label = "item 1", is_leaf = true})
		Slab.begin_tree("DrawTree_Item_2", {label = "item 2", is_leaf = true})

		if Slab.begin_tree("DrawTree_Child_1", {label = "Folder", icon_path = DrawTree_Icon_Path}) then
			Slab.begin_tree("DrawTree_Item_3", {label = "item 3", is_leaf = true})
			Slab.begin_tree("DrawTree_Item_4", {label = "item 4", is_leaf = true})

			Slab.end_tree()
		end

		Slab.end_tree()
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"a tree item can be specified to be forced open with the is_open option as shown in the example below. The example " ..
			"also shows how tree items can have the selection rectangle permanently rendered."
	)

	Slab.new_line()

	if Slab.begin_tree("DrawTree_Root_Opened", {label = "root", is_open = true}) then
		for i = 1, 5, 1 do
			Slab.begin_tree(
				"DrawTree_Item_" .. i,
				{label = "item " .. i, is_leaf = true, is_selected = i == DrawTree_Opened_Selected}
			)

			if Slab.is_control_clicked() then
				DrawTree_Opened_Selected = i
			end
		end

		Slab.end_tree()
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Tree Ids can also be specified as a table. This allows the user to use a transient table to identify a particular tree " ..
			"element. The tree system has been updated so that any Ids that are used as tables will have the key be removed when the " ..
				"referenced table is garbage collected. This gives the user the ability to create thousands of tree elements and have " ..
					"the tree system keep the number of persistent elements to a minimum. The default label used for these elements will be " ..
						"the memory location of the table, so it is highly recommended to set the 'label' option for the table. These table " ..
							"elements will also be forced to disable saving settings to disk as the referenced key is a table and is transient. " ..
								"As of version 0.7, this feature is only available for tree controls."
	)
	Slab.new_line()
	Slab.textf(
		"The example below shows 5 tables that have been instanced and have an associated tree element. The right-click context " ..
			"menu for the root allows for additions to this list. The right-click context menu for each item contains the option " ..
				"to remove the individual element from the list and have that table garbage collected. This removal will also remove the " ..
					"associated tree element."
	)

	Slab.new_line()

	if DrawTree_Tables == nil then
		DrawTree_Tables = {}
		for i = 1, 5, 1 do
			table.insert(DrawTree_Tables, {})
		end
	end

	local RemoveIndex = -1
	if Slab.begin_tree("root", {is_open = true}) then
		if Slab.begin_context_menu_item() then
			if Slab.menu_item("Add") then
				table.insert(DrawTree_Tables, {})
			end

			Slab.end_context_menu()
		end

		for i, v in ipairs(DrawTree_Tables) do
			Slab.begin_tree(v, {is_leaf = true})

			if Slab.begin_context_menu_item() then
				if Slab.menu_item("remove") then
					RemoveIndex = i
				end

				Slab.end_context_menu()
			end
		end

		Slab.end_tree()
	end

	if RemoveIndex > 0 then
		table.remove(DrawTree_Tables, RemoveIndex)
	end
end

local DrawDialog_MessageBox = false
local DrawDialog_MessageBox_Title = "message Box"
local DrawDialog_MessageBox_Message = "This is a message."
local DrawDialog_FileDialog = ""
local DrawDialog_FileDialog_Result = ""

local function DrawDialog()
	Slab.textf(
		"Dialog boxes are windows that rendered on top of everything else. These windows will consume input from all other windows " ..
			"and controls. These are useful for forcing users to interact with a window of importance, such as message boxes and " ..
				"file dialogs."
	)

	Slab.new_line()

	Slab.textf("By clicking the button below, an example of a simple dialog box will be rendered.")
	if Slab.button("open Basic Dialog") then
		Slab.open_dialog("DrawDialog_Basic")
	end

	if Slab.begin_dialog("DrawDialog_Basic", {title = "Basic Dialog"}) then
		Slab.text("This is a basic dialog box.")

		if Slab.button("close") then
			Slab.close_dialog()
		end

		Slab.end_dialog()
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Slab offers support for common dialog boxes such as message boxes. To display a message box, Slab.message_box must be called every " ..
			"frame. The buttons to be drawn must be passed in through the buttons option. Once the user has made a selection, the button that was " ..
				"clicked is returned and the program can handle the response accordingly."
	)

	Slab.new_line()

	Slab.text("title")
	Slab.same_line()
	if Slab.input("DrawDialog_MessageBox_Title", {text = DrawDialog_MessageBox_Title}) then
		DrawDialog_MessageBox_Title = Slab.GetInputText()
	end

	Slab.new_line()

	Slab.text("message")
	if Slab.input("DrawDialog_MessageBox_Message", {text = DrawDialog_MessageBox_Message, multi_line = true, h = 75}) then
		DrawDialog_MessageBox_Message = Slab.GetInputText()
	end

	Slab.new_line()

	if Slab.button("Show message Box") then
		DrawDialog_MessageBox = true
	end

	if DrawDialog_MessageBox then
		local result = Slab.message_box(DrawDialog_MessageBox_Title, DrawDialog_MessageBox_Message, {buttons = {"OK"}})

		if result ~= "" then
			DrawDialog_MessageBox = false
		end
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Slab offers a file dialog box so that user can select to open or save a file. This behaves similar to file dialogs found on " ..
			"various operating systems. files can be filtered and a starting directory can be set. There are options for the user to select " ..
				"a single item or multiple items. As with the message box, the file_dialog option must be called every frame and the user response " ..
					"must be handled by the program."
	)

	Slab.new_line()

	if Slab.button("open File") then
		DrawDialog_FileDialog = "openfile"
	end

	Slab.same_line()

	if Slab.button("open directory") then
		DrawDialog_FileDialog = "opendirectory"
	end

	Slab.same_line()

	if Slab.button("save File") then
		DrawDialog_FileDialog = "savefile"
	end

	if DrawDialog_FileDialog ~= "" then
		local result = Slab.file_dialog({allow_multi_select = false, t = DrawDialog_FileDialog})

		if result.button ~= "" then
			DrawDialog_FileDialog = ""

			if result.button == "OK" then
				DrawDialog_FileDialog_Result = result.files[1]
			end
		end
	end

	Slab.textf("selected file: " .. DrawDialog_FileDialog_Result)
end

local DrawInteraction_MouseClicked_Left = 0
local DrawInteraction_MouseClicked_Right = 0
local DrawInteraction_MouseClicked_Middle = 0
local DrawInteraction_MouseReleased_Left = 0
local DrawInteraction_MouseReleased_Right = 0
local DrawInteraction_MouseReleased_Middle = 0
local DrawInteraction_MouseDoubleClicked_Left = 0
local DrawInteraction_MouseDoubleClicked_Right = 0
local DrawInteraction_MouseDoubleClicked_Middle = 0
local DrawInteraction_MouseVoidClicked_Left = 0
local DrawInteraction_KeyPressed_A = 0
local DrawInteraction_KeyPressed_S = 0
local DrawInteraction_KeyPressed_D = 0
local DrawInteraction_KeyPressed_F = 0
local DrawInteraction_KeyReleased_A = 0
local DrawInteraction_KeyReleased_S = 0
local DrawInteraction_KeyReleased_D = 0
local DrawInteraction_KeyReleased_F = 0

local function DrawInteraction()
	Slab.textf(
		"Slab offers functions to query the user's input on a given frame. There are also functions to query for input on the most " ..
			"recently declared control. This can allow the implementation to use custom logic for controls to create custom behaviors."
	)

	Slab.new_line()

	Slab.textf(
		"Below are functions that query the state of the mouse. The is_mouse_down checks to see if a specific button is down on that " ..
			"frame. The is_mouse_clicked will check to see if the state of a button went from up to down on that frame and the is_mouse_released " ..
				"function checks to see if a button went from down to up on that frame."
	)

	local Left = Slab.is_mouse_down(1)
	local Right = Slab.is_mouse_down(2)
	local Middle = Slab.is_mouse_down(3)

	Slab.new_line()

	Slab.text("Left")
	Slab.same_line()
	Slab.text(Left and "Down" or "Up")

	Slab.text("Right")
	Slab.same_line()
	Slab.text(Right and "Down" or "Up")

	Slab.text("Middle")
	Slab.same_line()
	Slab.text(Middle and "Down" or "Up")

	Slab.new_line()

	if Slab.is_mouse_clicked(1) then
		DrawInteraction_MouseClicked_Left = DrawInteraction_MouseClicked_Left + 1
	end
	if Slab.is_mouse_clicked(2) then
		DrawInteraction_MouseClicked_Right = DrawInteraction_MouseClicked_Right + 1
	end
	if Slab.is_mouse_clicked(3) then
		DrawInteraction_MouseClicked_Middle = DrawInteraction_MouseClicked_Middle + 1
	end

	if Slab.is_mouse_released(1) then
		DrawInteraction_MouseReleased_Left = DrawInteraction_MouseReleased_Left + 1
	end
	if Slab.is_mouse_released(2) then
		DrawInteraction_MouseReleased_Right = DrawInteraction_MouseReleased_Right + 1
	end
	if Slab.is_mouse_released(3) then
		DrawInteraction_MouseReleased_Middle = DrawInteraction_MouseReleased_Middle + 1
	end

	Slab.text("Left Clicked: " .. DrawInteraction_MouseClicked_Left)
	Slab.same_line()
	Slab.text("Released: " .. DrawInteraction_MouseReleased_Left)

	Slab.text("Right Clicked: " .. DrawInteraction_MouseClicked_Right)
	Slab.same_line()
	Slab.text("Released: " .. DrawInteraction_MouseReleased_Right)

	Slab.text("Middle Clicked: " .. DrawInteraction_MouseClicked_Middle)
	Slab.same_line()
	Slab.text("Released: " .. DrawInteraction_MouseReleased_Middle)

	Slab.new_line()

	Slab.textf("Slab offers functions to detect if the mouse was double-clicked or if a mouse button is being dragged.")

	Slab.new_line()

	if Slab.is_mouse_double_clicked(1) then
		DrawInteraction_MouseDoubleClicked_Left = DrawInteraction_MouseDoubleClicked_Left + 1
	end
	if Slab.is_mouse_double_clicked(2) then
		DrawInteraction_MouseDoubleClicked_Right = DrawInteraction_MouseDoubleClicked_Right + 1
	end
	if Slab.is_mouse_double_clicked(3) then
		DrawInteraction_MouseDoubleClicked_Middle = DrawInteraction_MouseDoubleClicked_Middle + 1
	end

	Slab.text("Left Double Clicked: " .. DrawInteraction_MouseDoubleClicked_Left)
	Slab.text("Right Double Clicked: " .. DrawInteraction_MouseDoubleClicked_Right)
	Slab.text("Middle Double Clicked: " .. DrawInteraction_MouseDoubleClicked_Middle)

	Slab.new_line()

	local LeftDrag = Slab.is_mouse_dragging(1)
	local RightDrag = Slab.is_mouse_dragging(2)
	local MiddleDrag = Slab.is_mouse_dragging(3)

	Slab.text("Left Drag: " .. tostring(LeftDrag))
	Slab.text("Right Drag: " .. tostring(RightDrag))
	Slab.text("Middle Drag: " .. tostring(MiddleDrag))

	Slab.new_line()

	Slab.textf(
		"The mouse position relative to the viewport and relative to the current window can also be queried. Slab also offers retrieving " ..
			"the mouse delta."
	)

	Slab.new_line()

	local x, y = Slab.get_mouse_position()
	local win_x, win_y = Slab.get_mouse_position_window()
	local delta_x, delta_y = Slab.get_mouse_delta()

	Slab.text("x: " .. x .. " y: " .. y)
	Slab.text("Window x: " .. win_x .. " Window y: " .. win_y)
	Slab.text("delta x: " .. delta_x .. " delta y: " .. delta_y)

	Slab.textf(
		"Slab also offers functions to test if the user is interacting with the non-UI layer. The is_void_hovered and is_void_clicked " ..
			"behave the same way as is_control_hovered and is_control_clicked except will only return true when it is in a non-UI area."
	)

	Slab.new_line()

	if Slab.is_void_clicked(1) then
		DrawInteraction_MouseVoidClicked_Left = DrawInteraction_MouseVoidClicked_Left + 1
	end

	local is_void_hovered = Slab.is_void_hovered()

	Slab.text("Left Void Clicked: " .. DrawInteraction_MouseVoidClicked_Left)
	Slab.text("Is Void hovered: " .. tostring(is_void_hovered))

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Slab offers functions to check for the state of a specific keyboard key. The key code to use are the ones defined by LÖVE " ..
			"which can be found on the wiki. Below we will check for the key states of the a, s, D, f keys."
	)

	Slab.new_line()

	local IsDown_A = Slab.is_key_down("a")
	local IsDown_S = Slab.is_key_down("s")
	local IsDown_D = Slab.is_key_down("d")
	local IsDown_F = Slab.is_key_down("f")

	if Slab.is_key_pressed("a") then
		DrawInteraction_KeyPressed_A = DrawInteraction_KeyPressed_A + 1
	end
	if Slab.is_key_pressed("s") then
		DrawInteraction_KeyPressed_S = DrawInteraction_KeyPressed_S + 1
	end
	if Slab.is_key_pressed("d") then
		DrawInteraction_KeyPressed_D = DrawInteraction_KeyPressed_D + 1
	end
	if Slab.is_key_pressed("f") then
		DrawInteraction_KeyPressed_F = DrawInteraction_KeyPressed_F + 1
	end

	if Slab.is_key_released("a") then
		DrawInteraction_KeyReleased_A = DrawInteraction_KeyReleased_A + 1
	end
	if Slab.is_key_released("s") then
		DrawInteraction_KeyReleased_S = DrawInteraction_KeyReleased_S + 1
	end
	if Slab.is_key_released("d") then
		DrawInteraction_KeyReleased_D = DrawInteraction_KeyReleased_D + 1
	end
	if Slab.is_key_released("f") then
		DrawInteraction_KeyReleased_F = DrawInteraction_KeyReleased_F + 1
	end

	Slab.text("a Down: " .. tostring(IsDown_A))
	Slab.text("s Down: " .. tostring(IsDown_S))
	Slab.text("D Down: " .. tostring(IsDown_D))
	Slab.text("f Down: " .. tostring(IsDown_F))

	Slab.new_line()

	Slab.text("a Pressed: " .. DrawInteraction_KeyPressed_A)
	Slab.text("s Pressed: " .. DrawInteraction_KeyPressed_S)
	Slab.text("D Pressed: " .. DrawInteraction_KeyPressed_D)
	Slab.text("f Pressed: " .. DrawInteraction_KeyPressed_F)

	Slab.new_line()

	Slab.text("a Released: " .. DrawInteraction_KeyReleased_A)
	Slab.text("s Released: " .. DrawInteraction_KeyReleased_S)
	Slab.text("D Released: " .. DrawInteraction_KeyReleased_D)
	Slab.text("f Released: " .. DrawInteraction_KeyReleased_F)
end

local DrawShapes_Rectangle_Color = {1, 0, 0, 1}
local DrawShapes_Rectangle_ChangeColor = false
local DrawShapes_Rectangle_Rounding = {0, 0, 2.0, 2.0}
local DrawShapes_Circle_Radius = 32.0
local DrawShapes_Circle_Segments = 24
local DrawShapes_Circle_Mode = "fill"
local DrawShapes_Triangle_Radius = 32.0
local DrawShapes_Triangle_Rotation = 0
local DrawShapes_Triangle_Mode = "fill"
local DrawShapes_Modes = {"fill", "line"}
local DrawShapes_Line_Width = 1.0
local DrawShapes_Curve = {0, 0, 150, 150, 300, 0}
local DrawShapes_ControlPoint_Size = 7.5
local DrawShapes_ControlPoint_Index = 0
local DrawShapes_Polygon = {10, 10, 150, 25, 175, 75, 50, 125}
local DrawShapes_Polygon_Mode = "fill"

local function DrawShapes_Rectangle_Rounding_Input(Corner, index)
	Slab.text(Corner)
	Slab.same_line()
	if
		Slab.input(
			"DrawShapes_Rectangle_Rounding_" .. Corner,
			{text = tostring(DrawShapes_Rectangle_Rounding[index]), numbers_only = true, min_number = 0, return_on_text = false}
		)
	 then
		DrawShapes_Rectangle_Rounding[index] = Slab.get_input_number()
	end
end

local function DrawShapes()
	Slab.textf(
		"Slab offers functions to draw basic shapes to the window. These shapes can complement the controls provided by Slab."
	)

	Slab.new_line()

	Slab.textf("Below is an invisible button combined with a rectangle. Click on the rectangle to change the color.")

	local x, y = Slab.get_cursor_pos()
	Slab.rectangle({w = 150, h = 25, colour = DrawShapes_Rectangle_Color})
	Slab.set_cursor_pos(x, y)
	if Slab.button("", {w = 150, h = 25, invisible = true}) then
		DrawShapes_Rectangle_ChangeColor = true
	end

	if DrawShapes_Rectangle_ChangeColor then
		local result = Slab.ColorPicker({colour = DrawShapes_Rectangle_Color})

		if result.button ~= "" then
			DrawShapes_Rectangle_ChangeColor = false

			if result.button == "OK" then
				DrawShapes_Rectangle_Color = result.colour
			end
		end
	end

	Slab.new_line()

	Slab.textf(
		"rectangle corner rounding can be defined in multiple ways. The rounding option can take a single number, which will apply rounding to all corners. The option " ..
			"can also accept a table, with each index affecting a single corner. The order this happens in is top left, top right, bottom right, and bottom left."
	)

	Slab.new_line()

	DrawShapes_Rectangle_Rounding_Input("t_l", 1)
	Slab.same_line()
	DrawShapes_Rectangle_Rounding_Input("t_r", 2)
	Slab.same_line()
	DrawShapes_Rectangle_Rounding_Input("b_r", 3)
	Slab.same_line()
	DrawShapes_Rectangle_Rounding_Input("b_l", 4)

	Slab.new_line()

	Slab.rectangle({w = 150.0, h = 75.0, rounding = DrawShapes_Rectangle_Rounding, outline = true, colour = {0, 1, 0, 1}})

	Slab.new_line()
	Slab.separator()

	Slab.textf("Circles are drawn by defining a radius. Along with the color the number of segments can be set as well.")

	Slab.new_line()

	Slab.text("radius")
	Slab.same_line()
	if
		Slab.input(
			"DrawShapes_Circle_Radius",
			{text = tostring(DrawShapes_Circle_Radius), numbers_only = true, min_number = 0, return_on_text = false}
		)
	 then
		DrawShapes_Circle_Radius = Slab.get_input_number()
	end

	Slab.same_line()
	Slab.text("segments")
	Slab.same_line()
	if
		Slab.input(
			"DrawShapes_Circle_Segments",
			{text = tostring(DrawShapes_Circle_Segments), numbers_only = true, min_number = 0, return_on_text = false}
		)
	 then
		DrawShapes_Circle_Segments = Slab.get_input_number()
	end

	Slab.same_line()
	Slab.text("mode")
	Slab.same_line()
	if Slab.begin_combo_box("DrawShapes_Circle_Mode", {selected = DrawShapes_Circle_Mode}) then
		for i, v in ipairs(DrawShapes_Modes) do
			if Slab.text_selectable(v) then
				DrawShapes_Circle_Mode = v
			end
		end

		Slab.end_combo_box()
	end

	Slab.circle(
		{
			radius = DrawShapes_Circle_Radius,
			segments = DrawShapes_Circle_Segments,
			colour = {1, 1, 1, 1},
			mode = DrawShapes_Circle_Mode
		}
	)

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Triangles are drawn by defining a radius, which is the length from the center of the triangle to the 3 points. a rotation in degrees " ..
			"can be specified to rotate the triangle."
	)

	Slab.new_line()

	Slab.text("radius")
	Slab.same_line()
	if
		Slab.input(
			"DrawShapes_Triangle_Radius",
			{text = tostring(DrawShapes_Triangle_Radius), numbers_only = true, min_number = 0, return_on_text = false}
		)
	 then
		DrawShapes_Triangle_Radius = Slab.get_input_number()
	end

	Slab.same_line()
	Slab.text("rotation")
	Slab.same_line()
	if
		Slab.input(
			"DrawShapes_Triangle_Rotation",
			{text = tostring(DrawShapes_Triangle_Rotation), numbers_only = true, min_number = 0, return_on_text = false}
		)
	 then
		DrawShapes_Triangle_Rotation = Slab.get_input_number()
	end

	Slab.same_line()
	Slab.text("mode")
	Slab.same_line()
	if Slab.begin_combo_box("DrawShapes_Triangle_Mode", {selected = DrawShapes_Triangle_Mode}) then
		for i, v in ipairs(DrawShapes_Modes) do
			if Slab.text_selectable(v) then
				DrawShapes_Triangle_Mode = v
			end
		end

		Slab.end_combo_box()
	end

	Slab.triangle(
		{
			radius = DrawShapes_Triangle_Radius,
			rotation = DrawShapes_Triangle_Rotation,
			colour = {0, 1, 0, 1},
			mode = DrawShapes_Triangle_Mode
		}
	)

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"lines are defined by two points. The function only takes in a single point which defines the end point while the start point is defined by the current " ..
			"cursor position. Both the line width and color can be defined."
	)

	Slab.new_line()

	Slab.text("width")
	Slab.same_line()
	if
		Slab.input(
			"DrawShapes_Line_Width",
			{text = tostring(DrawShapes_Line_Width), numbers_only = true, return_on_text = false, min_number = 1.0}
		)
	 then
		DrawShapes_Line_Width = Slab.get_input_number()
	end

	Slab.new_line()

	x, y = Slab.get_cursor_pos({Absolute = true})
	local win_w, win_h = Slab.get_window_active_size()
	Slab.line(x + win_w * 0.5, y, {width = DrawShapes_Line_Width, colour = {1, 1, 0, 1}})

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Bezier curves can be defined through a set of points and added to a Slab window. The points given must be in local space. Slab will translate the " ..
			"curve to the current cursor position. Along with the ability to draw the curve, Slab offers functions to query information about the curve, such as " ..
				"the number of control points defined, the position of a control point, and the ability to evaluate the position of a curve given a time value. " ..
					"There is also a function to evaluate the curve with the current x mouse position."
	)

	Slab.new_line()

	Slab.curve(DrawShapes_Curve)
	x, y = Slab.get_cursor_pos({Absolute = true})

	Slab.same_line({center_y = true, pad = 16})
	local EvalX, EvalY = Slab.evaluate_curve_mouse()
	Slab.text(string.format("x: %.2f y: %.2f", EvalX, EvalY))

	EvalX, EvalY = Slab.evaluate_curve_mouse({local_space = false})
	Slab.set_cursor_pos(EvalX, EvalY, {Absolute = true})
	Slab.circle({colour = {1, 1, 1, 1}, radius = DrawShapes_ControlPoint_Size * 0.5})

	local HalfSize = DrawShapes_ControlPoint_Size * 0.5
	for i = 1, Slab.get_curve_control_point_count(), 1 do
		local p_x, p_y = Slab.get_curve_control_point(i, {local_space = false})

		Slab.set_cursor_pos(p_x - HalfSize, p_y - HalfSize, {Absolute = true})
		Slab.rectangle({w = DrawShapes_ControlPoint_Size, h = DrawShapes_ControlPoint_Size, colour = {1, 1, 1, 1}})

		if Slab.is_control_clicked() then
			DrawShapes_ControlPoint_Index = i
		end
	end

	if DrawShapes_ControlPoint_Index > 0 and Slab.is_mouse_dragging() then
		local delta_x, delta_y = Slab.get_mouse_delta()
		local P2 = DrawShapes_ControlPoint_Index * 2
		local P1 = P2 - 1

		DrawShapes_Curve[P1] = DrawShapes_Curve[P1] + delta_x
		DrawShapes_Curve[P2] = DrawShapes_Curve[P2] + delta_y
	end

	if Slab.is_mouse_released() then
		DrawShapes_ControlPoint_Index = 0
	end

	Slab.set_cursor_pos(x, y, {Absolute = true})

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Polygons can be drawn by passing in a List of points into the polygon function. The points, like the curve, should be defined in local space. Slab will " ..
			"then translate the points to the current cursor position."
	)

	Slab.new_line()

	Slab.text("mode")
	Slab.same_line()
	if Slab.begin_combo_box("DrawShapes_Polygon_Mode", {selected = DrawShapes_Polygon_Mode}) then
		for i, v in ipairs(DrawShapes_Modes) do
			if Slab.text_selectable(v) then
				DrawShapes_Polygon_Mode = v
			end
		end

		Slab.end_combo_box()
	end

	Slab.polygon(DrawShapes_Polygon, {colour = {0, 0, 1, 1}, mode = DrawShapes_Polygon_Mode})
end

local DrawWindow_X = 900
local DrawWindow_Y = 100
local DrawWindow_W = 200
local DrawWindow_H = 200
local DrawWindow_Title = "Example"
local DrawWindow_ResetLayout = false
local DrawWindow_ResetSize = false
local DrawWindow_AutoSizeWindow = true
local DrawWindow_AllowResize = true
local DrawWindow_AllowMove = true
local DrawWindow_AllowFocus = true
local DrawWindow_Border = 4.0
local DrawWindow_BgColor = nil
local DrawWindow_BgColor_ChangeColor = false
local DrawWindow_NoOutline = false
local DrawWindow_SizerFilter = {}
local DrawWindow_SizerFiltersOptions = {
	N = true,
	s = true,
	E = true,
	w = true,
	NW = true,
	NE = true,
	s_w = true,
	SE = true
}

local function DrawWindow_SizerCheckBox(key)
	if Slab.checkBox(DrawWindow_SizerFiltersOptions[key], key) then
		DrawWindow_SizerFiltersOptions[key] = not DrawWindow_SizerFiltersOptions[key]
	end
end

local function DrawWindow()
	Slab.textf(
		"Windows are the basis for which all controls are rendered on and for all user interactions to occur. This area will contain information on the " ..
			"various options that a window can take and what their expected behaviors will be. The window rendered to the right of this window will be affected " ..
				"by the changes to the various parameters."
	)

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"The title of the window can be customized. If no title exists, then the title bar is not rendered and the window can not be moved. There is also an " ..
			"option, allow_move, to disable movement even with the title bar."
	)

	Slab.new_line()

	Slab.text("title")
	Slab.same_line()
	if Slab.input("DrawWindow_Title", {text = DrawWindow_Title, return_on_text = false}) then
		DrawWindow_Title = Slab.GetInputText()
	end

	Slab.same_line()
	if Slab.checkBox(DrawWindow_AllowMove, "Allow Move") then
		DrawWindow_AllowMove = not DrawWindow_AllowMove
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"The default position of the window can be set with the x and y options. The window can be moved from this position but the parameter values stay the same " ..
			"as the window keeps track of any delta changes from the starting position. The window can be reset to the default position as described later on below."
	)

	Slab.new_line()

	Slab.text("x")
	Slab.same_line()
	if Slab.input("DrawWindow_X", {text = tostring(DrawWindow_X), numbers_only = true, return_on_text = false}) then
		DrawWindow_X = Slab.get_input_number()
		DrawWindow_ResetLayout = true
	end

	Slab.same_line()
	Slab.text("y")
	Slab.same_line()
	if Slab.input("DrawWindow_Y", {text = tostring(DrawWindow_Y), numbers_only = true, return_on_text = false}) then
		DrawWindow_Y = Slab.get_input_number()
		DrawWindow_ResetLayout = true
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"The size of the window can be specified. However, windows by default are set to auto size with the auto_size_window option, which resizes the window only when " ..
			"controls are added to the window. If this option is disabled, then the w and h parameters will be applied to the window.\n" ..
				"Similar to the window position, the window's size delta changes are stored by the window. The window's size can be reset to the default with the reset_size " ..
					"option."
	)

	Slab.new_line()

	Slab.text("w")
	Slab.same_line()
	if
		Slab.input(
			"DrawWindow_W",
			{text = tostring(DrawWindow_W), numbers_only = true, return_on_text = false, min_number = 0}
		)
	 then
		DrawWindow_W = Slab.get_input_number()
		DrawWindow_ResetSize = true
	end

	Slab.same_line()
	Slab.text("h")
	Slab.same_line()
	if
		Slab.input(
			"DrawWindow_H",
			{text = tostring(DrawWindow_H), numbers_only = true, return_on_text = false, min_number = 0}
		)
	 then
		DrawWindow_H = Slab.get_input_number()
		DrawWindow_ResetSize = true
	end

	if Slab.checkBox(DrawWindow_AutoSizeWindow, "Auto size Window") then
		DrawWindow_AutoSizeWindow = not DrawWindow_AutoSizeWindow
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Windows can be resized onluy if the auto_size_window option is set false. By default, all sides and corners of a window can be resized, but this can be " ..
			"modified by specifying which directions are allowed to be resized. There is also an option to completely disable resizing with the allow_resize option. " ..
				"Below is a List of options that are available."
	)

	Slab.new_line()

	if Slab.checkBox(DrawWindow_AllowResize, "Allow Resize") then
		DrawWindow_AllowResize = not DrawWindow_AllowResize
	end

	DrawWindow_SizerCheckBox("N")
	DrawWindow_SizerCheckBox("s")
	DrawWindow_SizerCheckBox("E")
	DrawWindow_SizerCheckBox("w")
	DrawWindow_SizerCheckBox("NW")
	DrawWindow_SizerCheckBox("NE")
	DrawWindow_SizerCheckBox("s_w")
	DrawWindow_SizerCheckBox("SE")

	local FalseCount = 0
	DrawWindow_SizerFilter = {}
	for k, v in pairs(DrawWindow_SizerFiltersOptions) do
		if v then
			table.insert(DrawWindow_SizerFilter, k)
		else
			FalseCount = FalseCount + 1
		end
	end

	if FalseCount == 0 then
		DrawWindow_SizerFilter = {}
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Windows gain focus when the user clicks within the region of the window. When the window gains focus, it is brought to the top of the window stack. " ..
			"Through the allow_focus option, a window may have this behavior turned off."
	)

	Slab.new_line()

	if Slab.checkBox(DrawWindow_AllowFocus, "Allow Focus") then
		DrawWindow_AllowFocus = not DrawWindow_AllowFocus
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"Windows have a border defined which is how much space there is between the edges of the window and the contents of the window."
	)

	Slab.new_line()

	Slab.text("border")
	Slab.same_line()
	if
		Slab.input(
			"DrawWindow_Border",
			{text = tostring(DrawWindow_Border), numbers_only = true, return_on_text = false, min_number = 0}
		)
	 then
		DrawWindow_Border = Slab.get_input_number()
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"The reset_size and ResetLayout options for windows will reset any delta changes to a window's position or size. It is recommended to only pass " ..
			"in true for these options on a single frame if resetting the position or size is desired."
	)

	Slab.new_line()

	if Slab.button("reset Layout") then
		DrawWindow_ResetLayout = true
	end

	Slab.same_line()

	if Slab.button("reset size") then
		DrawWindow_ResetSize = true
	end

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"The background color of the window can be modified. Along with modifying the color, the outline of the window can be set to drawn or hidden." ..
			"Hiding the outline and setting the background to be transparent will make only the controls be rendered within the window."
	)

	if DrawWindow_BgColor == nil then
		DrawWindow_BgColor = Slab.get_style().WindowBackgroundColor
	end

	if Slab.button("Change Backgound colour") then
		DrawWindow_BgColor_ChangeColor = true
	end

	if Slab.checkBox(DrawWindow_NoOutline, "No outline") then
		DrawWindow_NoOutline = not DrawWindow_NoOutline
	end

	if DrawWindow_BgColor_ChangeColor then
		local result = Slab.ColorPicker({colour = DrawWindow_BgColor})

		if result.button ~= "" then
			DrawWindow_BgColor_ChangeColor = false

			if result.button == "OK" then
				DrawWindow_BgColor = result.colour
			end
		end
	end

	Slab.begin_window(
		"DrawWindow_Example",
		{
			title = DrawWindow_Title,
			x = DrawWindow_X,
			y = DrawWindow_Y,
			w = DrawWindow_W,
			h = DrawWindow_H,
			ResetLayout = DrawWindow_ResetLayout,
			reset_size = DrawWindow_ResetSize,
			auto_size_window = DrawWindow_AutoSizeWindow,
			sizer_filter = DrawWindow_SizerFilter,
			allow_resize = DrawWindow_AllowResize,
			allow_move = DrawWindow_AllowMove,
			allow_focus = DrawWindow_AllowFocus,
			border = DrawWindow_Border,
			bg_color = DrawWindow_BgColor,
			no_outline = DrawWindow_NoOutline
		}
	)
	Slab.text("Hello World")
	Slab.end_window()

	DrawWindow_ResetLayout = false
	DrawWindow_ResetSize = false
end

local DrawTooltip_CheckBox = false
local DrawTooltip_Radio = 1
local DrawTooltip_ComboBox_Items = {"button", "check Box", "Combo Box", "img", "Input", "text", "Tree"}
local DrawTooltip_ComboBox_Selected = "button"
local DrawTooltip_Image = SLAB_FILE_PATH .. "/Internal/Resources/Textures/power.png"
local DrawTooltip_Input = "This is an input box."

local function DrawTooltip()
	Slab.textf(
		"Slab offers tooltips to be rendered when the user has hovered over the control for a period of time. Not all controls are currently supported, " ..
			"and this window will show examples for tooltips on the supported controls."
	)

	Slab.new_line()

	Slab.button("button", {tooltip = "This is a Button."})

	Slab.new_line()

	if Slab.checkBox(DrawTooltip_CheckBox, "check Box", {tooltip = "This is a check box."}) then
		DrawTooltip_CheckBox = not DrawTooltip_CheckBox
	end

	Slab.new_line()

	for i = 1, 3, 1 do
		if
			Slab.radio_button(
				"Radio " .. i,
				{selected_index = DrawTooltip_Radio, index = i, tooltip = "This is radio button " .. i}
			)
		 then
			DrawTooltip_Radio = i
		end
	end

	Slab.new_line()

	if
		Slab.begin_combo_box(
			"DrawTooltip_ComboBox",
			{selected = DrawTooltip_ComboBox_Selected, tooltip = "This is a combo box."}
		)
	 then
		for i, v in ipairs(DrawTooltip_ComboBox_Items) do
			if Slab.text_selectable(v) then
				DrawTooltip_ComboBox_Selected = v
			end
		end

		Slab.end_combo_box()
	end

	Slab.new_line()

	Slab.image("DrawTooltip_Image", {path = DrawTooltip_Image, tooltip = "This is an image."})

	Slab.new_line()

	if Slab.input("DrawTooltip_Input", {text = DrawTooltip_Input, tooltip = DrawTooltip_Input}) then
		DrawTooltip_Input = Slab.GetInputText()
	end

	Slab.new_line()

	if Slab.begin_tree("DrawTooltip_Tree_Root", {label = "root", tooltip = "This is the root tree item."}) then
		Slab.begin_tree("DrawTooltip_Tree_Child", {label = "Child", tooltip = "This is the child tree item.", is_leaf = true})
		Slab.end_tree()
	end

	Slab.new_line()

	Slab.button("multi_line tooltip", {tooltip = "This is a multi-line Tooltip.\nThis is the second line."})
end

local DrawStats_SetPosition = false
local DrawStats_EncodeIterations = 20
local DrawStats_EncodeLength = 500

local function DrawStats()
	Slab.textf(
		"The Slab API offers functions that track the performance of desired sections of code. With these functions coupled together with the debug " ..
			"performance window, end-users will be able to see bottlenecks located within their code base quickly. To display the performance window, " ..
				"call the SlabDebug.Performance function."
	)

	Slab.new_line()
	Slab.separator()

	if not DrawStats_SetPosition then
		SlabDebug.Performance_SetPosition(800.0, 175.0)
		DrawStats_SetPosition = true
	end

	Slab.textf(
		"This page has an example of capturing the performance of encoding data. The iterations and length can be changed to show how the performance is " ..
			"impacted when these values change."
	)

	Slab.new_line()

	Slab.text("Iterations")
	Slab.same_line()
	if
		Slab.input(
			"DrawStats_EncodeIterations",
			{text = tostring(DrawStats_EncodeIterations), return_on_text = false, numbers_only = true, min_number = 0}
		)
	 then
		DrawStats_EncodeIterations = Slab.get_input_number()
	end

	Slab.same_line()
	Slab.text("length")
	Slab.same_line()
	if
		Slab.input(
			"DrawStats_EncodeLength",
			{text = tostring(DrawStats_EncodeLength), return_on_text = false, numbers_only = true, min_number = 0}
		)
	 then
		DrawStats_EncodeLength = Slab.get_input_number()
	end

	local stat_handle = Slab.begin_stat("Encode", "Slab Test")

	for i = 1, DrawStats_EncodeIterations, 1 do
		local LengthStatHandle = Slab.begin_stat("Encode length", "Slab Test")

		local data = ""
		for j = 1, DrawStats_EncodeLength, 1 do
			local bite = love.math.random(255)
			data = data .. string.char(bite)
		end
		love.data.encode("string", "hex", data)

		Slab.end_stat(LengthStatHandle)
	end

	Slab.end_stat(stat_handle)

	SlabDebug.Performance()
end

local DrawLayout_AlignX = "left"
local DrawLayout_AlignY = "top"
local DrawLayout_AlignRowY = "top"
local DrawLayout_AlignX_Options = {"left", "center", "right"}
local DrawLayout_AlignY_Options = {"top", "center", "Bottom"}
local DrawLayout_Radio = 1
local DrawLayout_Input = "Input control"
local DrawLayout_ListBox_Selected = 1
local DrawLayout_Columns = 3

local function DrawLayout()
	Slab.textf(
		"The layout API allows for controls to be grouped together and aligned to a specific position based on the window. " ..
			"These controls can be aligned to the left, the center, or the right part of a window horizontally. They can also " ..
				"be aligned to the top, the center, or the bottom vertically in a window. Multiple controls can be declared on the " ..
					"same line and the API will properly align on the controls on the same line. Below are examples of how this API can " ..
						"be utilized."
	)

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"The below example shows how controls can be aligned within a window. Use the below options to dictate where the next " ..
			"set of controls are aligned."
	)
	Slab.new_line()

	Slab.begin_layout("DrawLayout_Options", {align_x = "center"})

	Slab.text("align_x")
	Slab.same_line()
	if Slab.begin_combo_box("DrawLayout_AlignX", {selected = DrawLayout_AlignX}) then
		for i, v in ipairs(DrawLayout_AlignX_Options) do
			if Slab.text_selectable(v) then
				DrawLayout_AlignX = v
			end
		end

		Slab.end_combo_box()
	end

	Slab.same_line()
	Slab.text("align_y")
	Slab.same_line()
	if Slab.begin_combo_box("DrawLayout_AlignY", {selected = DrawLayout_AlignY}) then
		for i, v in ipairs(DrawLayout_AlignY_Options) do
			if Slab.text_selectable(v) then
				DrawLayout_AlignY = v
			end
		end

		Slab.end_combo_box()
	end

	Slab.same_line()
	Slab.text("align_row_y")
	Slab.same_line()
	if Slab.begin_combo_box("DrawLayout_AlignRowY", {selected = DrawLayout_AlignRowY}) then
		for i, v in ipairs(DrawLayout_AlignY_Options) do
			if Slab.text_selectable(v) then
				DrawLayout_AlignRowY = v
			end
		end

		Slab.end_combo_box()
	end

	Slab.end_layout()

	Slab.new_line()

	Slab.begin_layout(
		"DrawLayout_General",
		{align_x = DrawLayout_AlignX, align_y = DrawLayout_AlignY, align_row_y = DrawLayout_AlignRowY}
	)

	Slab.button("button 1")
	Slab.same_line()
	Slab.button("button 2", {w = 150})

	Slab.button("button")
	Slab.same_line()
	Slab.button("button", {w = 50, h = 50, tooltip = "This is a large Button."})
	Slab.same_line()
	Slab.button("button")

	Slab.new_line()

	Slab.text("New lines are supported too.")

	Slab.end_layout()

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"controls can also be expanded in the width and height. Only controls that can have their size modified through the API " ..
			"will be affected by these options. The controls that will be affected are buttons, combo boxes (only the width), " ..
				"input controls, and list boxes. Non-expandable controls such as text can be mixed in with the controls and the size " ..
					"of the controls will be adjusted accordingly."
	)
	Slab.new_line()

	Slab.begin_layout("DrawLayout_Expand", {expand_w = true, expand_h = true})
	Slab.button("OK")
	Slab.same_line()
	Slab.text("Hello")
	Slab.same_line()
	Slab.input("DrawLayout_ExpandInput")
	Slab.same_line()
	if Slab.begin_combo_box("DrawLayout_ExpandComboBox") then
		Slab.end_combo_box()
	end
	Slab.same_line()
	Slab.begin_list_box("DrawLayout_ExpandListBox", {h = 0})
	Slab.end_list_box()

	Slab.button("Cancel")
	Slab.end_layout()

	Slab.new_line()
	Slab.separator()

	Slab.textf(
		"controls can be layed out in columns. The 'columns' option is a number that tells the layout how many columns to allocate for " ..
			"positioning the controls. The 'set_layout_column' function sets the current active column and all controls will be placed within " ..
				"the bounds of that column."
	)

	Slab.new_line()

	Slab.begin_layout("DrawLayout_Columns_Options", {align_x = "center"})
	Slab.text("columns")
	Slab.same_line()
	if
		Slab.input(
			"DrawLayout_Columns_Input",
			{text = tostring(DrawLayout_Columns), return_on_text = false, min_number = 1, numbers_only = true}
		)
	 then
		DrawLayout_Columns = Slab.get_input_number()
	end
	Slab.end_layout()

	Slab.new_line()

	Slab.begin_layout("DrawLayout_Columns", {columns = DrawLayout_Columns, align_x = "center"})
	for i = 1, DrawLayout_Columns, 1 do
		Slab.set_layout_column(i)
		Slab.text("column " .. i)
		Slab.text("This is a very long string")
	end
	Slab.end_layout()
end

local DrawFonts_Roboto = nil
local DrawFonts_Roboto_Path = SLAB_FILE_PATH .. "/Internal/Resources/Fonts/Roboto-Regular.ttf"

local function DrawFonts()
	if DrawFonts_Roboto == nil then
		DrawFonts_Roboto = love.graphics.newFont(DrawFonts_Roboto_Path, 18)
	end

	Slab.textf(
		"Fonts can be pushed to a stack to alter the rendering of any text. All controls will use this pushed font until " ..
			"the font is popped from the stack, using the last pushed font or the default font. Below is an example of font " ..
				"being pushed to the stack to render a single text control and then being popped before the next text control."
	)

	Slab.new_line()

	Slab.push_font(DrawFonts_Roboto)
	Slab.text("This text control is using the Roboto font with point size of 18.")
	Slab.pop_font()

	Slab.new_line()

	Slab.text("This text control is using the default font.")
end

local function DrawScroll()
	Slab.textf(
		"The scroll speed can be modified through the set_scroll_speed API call. There is also an API function to retrieve " ..
			"the current speed."
	)

	Slab.new_line()

	Slab.text("speed")
	Slab.same_line()
	if
		Slab.input(
			"DrawScroll_Speed",
			{text = tostring(Slab.get_scroll_speed()), return_on_text = false, numbers_only = true}
		)
	 then
		Slab.set_scroll_speed(Slab.get_input_number())
	end

	Slab.new_line()

	Slab.begin_list_box("DrawScroll_List")

	for i = 1, 25, 1 do
		Slab.text("item " .. i)
	end

	Slab.end_list_box()
end

local DrawShader_Object = nil
local DrawShader_Time = 0.0
local DrawShader_Source =
	[[extern number time;
vec4 effect(vec4 color, img texture, vec2 texture_coords, vec2 pixel_coords)
{
	vec4 TexColor = Texel(texture, texture_coords);
    return vec4((1.0+sin(time))/2.0, abs(cos(time)), abs(sin(time)), 1.0) * TexColor;
}]]
local DrawShader_Highlight = {
	["vec2"] = {0, 0, 1, 1},
	["vec3"] = {0, 0, 1, 1},
	["vec4"] = {0, 0, 1, 1},
	["mat4"] = {0, 0, 1, 1}
}

local function DrawShader()
	if DrawShader_Object == nil then
		DrawShader_Object = love.graphics.newShader(DrawShader_Source)
	end

	DrawShader_Time = DrawShader_Time + love.timer.getDelta()

	if DrawShader_Object ~= nil then
		DrawShader_Object:send("time", DrawShader_Time)
	end

	Slab.textf(
		"Shader effects can be applied to any control through the push_shader/pop_shader API calls. Any controls created after " ..
			"a push_shader call will have its effects applied. The next pop_shader call will disable the current effect and apply " ..
				"the previous shader on the stack if one is present. The shader object to be pushed must be managed by the user and must be " ..
					"valid when Slab.draw is called. Below is an example of a shader effect that changes the pixel color over time."
	)

	Slab.new_line()

	local w, h = Slab.get_window_active_size()
	local options = {
		text = DrawShader_Source,
		return_on_text = false,
		multi_line = true,
		w = w,
		h = 150,
		highlight = DrawShader_Highlight
	}
	Slab.input("DrawShader_Source", options)
	if Slab.button("Compile") then
		DrawShader_Source = Slab.GetInputText()

		if DrawShader_Object ~= nil then
			DrawShader_Object:release()
		end

		DrawShader_Object = love.graphics.newShader(DrawShader_Source)
	end

	Slab.new_line()

	Slab.push_shader(DrawShader_Object)
	Slab.image("DrawShader_Image", {path = DrawImage_Path})
	Slab.text("text")
	Slab.button("button")
	Slab.pop_shader()
end

local function DrawMessages()
	Slab.textf(
		"Slab has a messaging system that will gather any messages generated by the API and ensure these messages are only " ..
			"displayed a single time in the console. The messages may be generated if the developer is using a deprecated function " ..
				"or deprecated options for a control. The API offers a way to disable this system by passing 'NoMessages' to the args of " ..
					"Slab.initialize. The API also offers a function to retrieve all gathered messages. Below will display all messages " ..
						"gathered since the start of this application."
	)

	Slab.new_line()

	local Messages = Slab.get_messages()
	Slab.begin_layout("DrawMessages_ListBox_Layout", {expand_w = true, expand_h = true})
	Slab.begin_list_box("DrawMessages_ListBox")

	for i, v in ipairs(Messages) do
		Slab.begin_list_box_item("DrawMessages_Item_" .. i)
		Slab.text(v)
		Slab.end_list_box_item()
	end

	Slab.end_list_box()
	Slab.end_layout()
end

local SlabTest_Options = {title = "Slab", auto_size_window = false, w = 800.0, h = 600.0, is_open = true}

function SlabTest.MainMenuBar()
	if Slab.begin_main_menu_bar() then
		if Slab.begin_menu("File") then
			if Slab.menu_item_checked("Show Test Window", SlabTest_Options.is_open) then
				SlabTest_Options.is_open = not SlabTest_Options.is_open
			end

			if Slab.menu_item("Quit") then
				love.event.quit()
			end

			Slab.end_menu()
		end

		SlabDebug.Menu()

		Slab.end_main_menu_bar()
	end
end

local Categories = {
	{"Overview", DrawOverview},
	{"Window", DrawWindow},
	{"buttons", DrawButtons},
	{"text", DrawText},
	{"check Box", DrawCheckBox},
	{"Radio button", DrawRadioButton},
	{"Menus", DrawMenus},
	{"Combo Box", DrawComboBox},
	{"Input", DrawInput},
	{"img", DrawImage},
	{"Cursor", draw_cursor},
	{"list Box", DrawListBox},
	{"Tree", DrawTree},
	{"Dialog", DrawDialog},
	{"Interaction", DrawInteraction},
	{"Shapes", DrawShapes},
	{"Tooltips", DrawTooltip},
	{"Stats", DrawStats},
	{"Layout", DrawLayout},
	{"Fonts", DrawFonts},
	{"Scroll", DrawScroll},
	{"Shaders", DrawShader},
	{"Messages", DrawMessages}
}

local selected = nil

function SlabTest.begin()
	local stat_handle = Slab.begin_stat("Slab Test", "Slab Test")

	SlabTest.MainMenuBar()

	if selected == nil then
		selected = Categories[1]
	end

	Slab.begin_window("SlabTest", SlabTest_Options)

	local w, h = Slab.get_window_active_size()

	if Slab.begin_combo_box("Categories", {selected = selected[1], w = w}) then
		for i, v in ipairs(Categories) do
			if Slab.text_selectable(v[1]) then
				selected = Categories[i]
			end
		end

		Slab.end_combo_box()
	end

	Slab.separator()

	if selected ~= nil and selected[2] ~= nil then
		selected[2]()
	end

	Slab.end_window()

	SlabDebug.begin()

	Slab.end_stat(stat_handle)
end

return SlabTest
