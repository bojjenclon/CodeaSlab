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
local Config = required("Config")
local Cursor = required("Cursor")
local FileSystem = required("FileSystem")
local Utility = required("Utility")

local API = {}
local Styles = {}
local StylePaths = {}
local DefaultStyles = {}
local CurrentStyle = ""
local FontStack = {}

local Style = {
	font = nil,
	FontSize = 14,
	MenuColor = {0.2, 0.2, 0.2, 1.0},
	ScrollBarColor = {0.4, 0.4, 0.4, 1.0},
	ScrollBarHoveredColor = {0.8, 0.8, 0.8, 1.0},
	SeparatorColor = {0.5, 0.5, 0.5, 0.7},
	WindowBackgroundColor = {0.2, 0.2, 0.2, 1.0},
	WindowTitleFocusedColor = {0.26, 0.53, 0.96, 1.0},
	WindowCloseBgColor = {0.64, 0.64, 0.64, 1.0},
	WindowCloseColor = {0.0, 0.0, 0.0, 1.0},
	ButtonColor = {0.55, 0.55, 0.55, 1.0},
	RadioButtonSelectedColor = {0.2, 0.2, 0.2, 1.0},
	ButtonHoveredColor = {0.7, 0.7, 0.7, 1.0},
	ButtonPressedColor = {0.8, 0.8, 0.8, 1.0},
	ButtonDisabledTextColor = {0.35, 0.35, 0.35, 1.0},
	CheckBoxSelectedColor = {0.0, 0.0, 0.0, 1.0},
	text_color = {0.875, 0.875, 0.875, 1.0},
	TextDisabledColor = {0.45, 0.45, 0.45, 1.0},
	TextHoverBgColor = {0.5, 0.5, 0.5, 1.0},
	TextURLColor = {0.2, 0.2, 1.0, 1.0},
	ComboBoxColor = {0.4, 0.4, 0.4, 1.0},
	ComboBoxHoveredColor = {0.55, 0.55, 0.55, 1.0},
	ComboBoxDropDownColor = {0.4, 0.4, 0.4, 1.0},
	ComboBoxDropDownHoveredColor = {0.55, 0.55, 0.55, 1.0},
	ComboBoxArrowColor = {1.0, 1.0, 1.0, 1.0},
	input_bg_color = {0.4, 0.4, 0.4, 1.0},
	InputEditBgColor = {0.6, 0.6, 0.6, 1.0},
	InputSelectColor = {0.14, 0.29, 0.53, 0.4},
	InputSliderColor = {0.1, 0.1, 0.1, 1.0},
	MultilineTextColor = {0.0, 0.0, 0.0, 1.0},
	WindowRounding = 2.0,
	button_rounding = 2.0,
	CheckBoxRounding = 2.0,
	ComboBoxRounding = 2.0,
	InputBgRounding = 2.0,
	ScrollBarRounding = 2.0,
	indent = 14.0,
	API = API
}

function API.initialize()
	local StylePath = "/Internal/Resources/Styles/"
	local path = SLAB_FILE_PATH .. StylePath
	-- Use love's filesystem functions to support both packaged and unpackaged builds
	local items = love.filesystem.getDirectoryItems(path)

	local StyleName = nil
	for i, v in ipairs(items) do
		if string.find(v, path, 1, true) == nil then
			v = path .. v
		end

		local LoadedStyle = API.LoadStyle(v, false, true)

		if LoadedStyle ~= nil then
			local name = FileSystem.get_base_name(v, true)

			if StyleName == nil then
				StyleName = name
			end
		end
	end

	if not API.SetStyle("Dark") then
		API.SetStyle(StyleName)
	end

	Style.Font = love.graphics.newFont(Style.FontSize)
	API.push_font(Style.Font)
	Cursor.set_new_line_size(Style.Font:getHeight())
end

function API.LoadStyle(path, set, IsDefault)
	local Contents, err = Config.load_file(path, IsDefault)
	if Contents ~= nil then
		local name = FileSystem.get_base_name(path, true)
		Styles[name] = Contents
		StylePaths[name] = path
		if IsDefault then
			table.insert(DefaultStyles, name)
		end

		if set then
			API.SetStyle(name)
		end
	else
		print("Failed to load style '" .. path .. "'.\n" .. err)
	end
	return Contents
end

function API.SetStyle(name)
	if name == nil then
		return false
	end

	local other = Styles[name]
	if other ~= nil then
		CurrentStyle = name
		for k, v in pairs(Style) do
			local New = other[k]
			if New ~= nil then
				if type(v) == "table" then
					Utility.copy_values(Style[k], New)
				else
					Style[k] = New
				end
			end
		end

		return true
	else
		print("Style '" .. name .. "' is not loaded.")
	end

	return false
end

function API.GetStyleNames()
	local result = {}

	for k, v in pairs(Styles) do
		table.insert(result, k)
	end

	return result
end

function API.GetCurrentStyleName()
	return CurrentStyle
end

function API.CopyCurrentStyle(path)
	local NewStyle = Utility.copy(Styles[CurrentStyle])
	local result, err = Config.save(path, NewStyle)

	if result then
		local NewStyleName = FileSystem.get_base_name(path, true)
		Styles[NewStyleName] = NewStyle
		StylePaths[NewStyleName] = path
		API.SetStyle(NewStyleName)
	else
		print("Failed to create new style at path '" .. path "'. " .. err)
	end
end

function API.SaveCurrentStyle()
	API.StoreCurrentStyle()
	local path = StylePaths[CurrentStyle]
	local settings = Styles[CurrentStyle]
	local result, err = Config.save(path, settings)
	if not result then
		print("Failed to save style '" .. CurrentStyle .. "'. " .. err)
	end
end

function API.StoreCurrentStyle()
	Utility.copy_values(Styles[CurrentStyle], Style)
end

function API.IsDefaultStyle(name)
	return Utility.contains(DefaultStyles, name)
end

function API.push_font(font)
	if font ~= nil then
		Style.Font = font
		table.insert(FontStack, 1, font)
	end
end

function API.pop_font()
	if #FontStack > 1 then
		table.remove(FontStack, 1)
		Style.Font = FontStack[1]
	end
end

return Style
