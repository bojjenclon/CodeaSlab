local FileSystem = {}

local Bit = require("bit")
local FFI = require("ffi")

local function ShouldFilter(name, filter)
	filter = filter == nil and "*.*" or filter

	local extension = FileSystem.get_extension(name)

	if filter ~= "*.*" then
		local FilterExt = FileSystem.get_extension(filter)

		if extension ~= FilterExt then
			return true
		end
	end

	return false
end

local get_directory_items = nil
local exists = nil
local is_directory = nil

--[[
	The following code is based on the following sources:

	LoveFS v1.1
	https://github.com/linux-man/lovefs
	Pure Lua FileSystem Access
	Under the MIT license.
	copyright(c) 2016 Caldas Lopes aka linux-man

	luapower/fs_posix
	https://github.com/luapower/fs
	portable filesystem API for LuaJIT / Linux & OSX backend
	Written by Cosmin Apreutesei. Public Domain.
--]]
if FFI.os == "Windows" then
	FFI.cdef [[
		#pragma pack(push)
		#pragma pack(1)
		struct WIN32_FIND_DATAW {
			uint32_t dwFileAttributes;
			uint64_t ftCreationTime;
			uint64_t ftLastAccessTime;
			uint64_t ftLastWriteTime;
			uint32_t dwReserved[4];
			wchar_t cFileName[520];
			wchar_t cAlternateFileName[28];
		};
		#pragma pack(pop)

		typedef unsigned long DWORD;
		static const DWORD FILE_ATTRIBUTE_DIRECTORY = 0x10;
		static const DWORD INVALID_FILE_ATTRIBUTES = -1;
		
		void* FindFirstFileW(const wchar_t* pattern, struct WIN32_FIND_DATAW* fd);
		bool FindNextFileW(void* ff, struct WIN32_FIND_DATAW* fd);
		bool FindClose(void* ff);
		DWORD GetFileAttributesW(const wchar_t* path);
		
		int MultiByteToWideChar(unsigned int CodePage, uint32_t dwFlags, const char* lpMultiByteStr,
			int cbMultiByte, const wchar_t* lpWideCharStr, int cchWideChar);
		int WideCharToMultiByte(unsigned int CodePage, uint32_t dwFlags, const wchar_t* lpWideCharStr,
			int cchWideChar, const char* lpMultiByteStr, int cchMultiByte,
			const char* default, int* used);
	]]

	local WIN32_FIND_DATA = FFI.typeof("struct WIN32_FIND_DATAW")
	local INVALID_HANDLE = FFI.cast("void*", -1)

	local function u2w(str, code)
		local size = FFI.C.MultiByteToWideChar(code or 65001, 0, str, #str, nil, 0)
		local buf = FFI.new("wchar_t[?]", size * 2 + 2)
		FFI.C.MultiByteToWideChar(code or 65001, 0, str, #str, buf, size * 2)
		return buf
	end

	local function w2u(wstr, code)
		local size = FFI.C.WideCharToMultiByte(code or 65001, 0, wstr, -1, nil, 0, nil, nil)
		local buf = FFI.new("char[?]", size + 1)
		size = FFI.C.WideCharToMultiByte(code or 65001, 0, wstr, -1, buf, size, nil, nil)
		return FFI.string(buf)
	end

	get_directory_items = function(directory, options)
		local result = {}

		local FindData = FFI.new(WIN32_FIND_DATA)
		local handle = FFI.C.FindFirstFileW(u2w(directory .. "\\*"), FindData)
		FFI.gc(handle, FFI.C.FindClose)

		if handle ~= nil then
			repeat
				local name = w2u(FindData.cFileName)

				if name ~= "." and name ~= ".." then
					local AddDirectory = (FindData.dwFileAttributes == 16 or FindData.dwFileAttributes == 17) and options.directories
					local AddFile = FindData.dwFileAttributes == 32 and options.files

					if (AddDirectory or AddFile) and not ShouldFilter(name, options.filter) then
						table.insert(result, name)
					end
				end
			until not FFI.C.FindNextFileW(handle, FindData)
		end

		FFI.C.FindClose(FFI.gc(handle, nil))

		return result
	end

	exists = function(path)
		local Attributes = FFI.C.GetFileAttributesW(u2w(path))
		return Attributes ~= FFI.C.INVALID_FILE_ATTRIBUTES
	end

	is_directory = function(path)
		local Attributes = FFI.C.GetFileAttributesW(u2w(path))
		return Attributes ~= FFI.C.INVALID_FILE_ATTRIBUTES and Bit.band(Attributes, FFI.C.FILE_ATTRIBUTE_DIRECTORY) ~= 0
	end
else
	FFI.cdef [[
		typedef struct DIR DIR;
		typedef size_t time_t;
		static const int S_IFREG = 0x8000;
		static const int S_IFDIR = 0x4000;

		DIR* opendir(const char* name);
		int closedir(DIR* dirp);
	]]

	if FFI.os == "OSX" then
		FFI.cdef [[
			struct dirent {
				uint64_t	d_ino;
				uint64_t	d_off;
				uint16_t	d_reclen;
				uint16_t	d_namlen;
				uint8_t		d_type;
				char		d_name[1024];
			};

			struct stat {
				uint32_t	st_dev;
				uint16_t	st_mode;
				uint16_t	st_nlink;
				uint64_t	st_ino;
				uint32_t	st_uid;
				uint32_t	st_gid;
				uint32_t	st_rdev;
				time_t		st_atime;
				long		st_atime_nsec;
				time_t		st_mtime;
				long		st_mtime_nsec;
				time_t		st_ctime;
				long		st_ctime_nsec;
				time_t		st_btime;
				long		st_btime_nsec;
				int64_t		st_size;
				int64_t		st_blocks;
				int32_t		st_blksize;
				uint32_t	st_flags;
				uint32_t	st_gen;
				int32_t		st_lspare;
				int64_t		st_qspare[2];
			};

			struct dirent* readdir(DIR* dirp) asm("readdir$INODE64");
			int stat64(const char* path, struct stat* buf);
		]]
	else
		FFI.cdef [[
			struct dirent {
				uint64_t		d_ino;
				int64_t			d_off;
				unsigned short	d_reclen;
				unsigned char	d_type;
				char			d_name[256];
			};

			struct stat {
				uint64_t	st_dev;
				uint64_t	st_ino;
				uint64_t 	st_nlink;
				uint32_t	st_mode;
				uint32_t	st_uid;
				uint32_t	st_gid;
				uint32_t	__pad0;
				uint64_t	st_rdev;
				int64_t		st_size;
				int64_t		st_blksize;
				int64_t		st_blocks;
				uint64_t	st_atime;
				uint64_t	st_atime_nsec;
				uint64_t	st_mtime;
				uint64_t	st_mtime_nsec;
				uint64_t	st_ctime;
				uint64_t	st_ctime_nsec;
				int64_t		__unused[3];
			};

			struct dirent* readdir(DIR* dirp) asm("readdir64");
			int stat64(const char* path, struct stat* buf);
		]]
	end

	local Stat = FFI.typeof("struct stat")

	get_directory_items = function(directory, options)
		local result = {}

		local DIR = FFI.C.opendir(directory)

		if DIR ~= nil then
			local Entry = FFI.C.readdir(DIR)

			while Entry ~= nil do
				local name = FFI.string(Entry.d_name)

				if name ~= "." and name ~= ".." and string.sub(name, 1, 1) ~= "." then
					local AddDirectory = Entry.d_type == 4 and options.directories
					local AddFile = Entry.d_type == 8 and options.files

					if (AddDirectory or AddFile) and not ShouldFilter(name, options.filter) then
						table.insert(result, name)
					end
				end

				Entry = FFI.C.readdir(DIR)
			end

			FFI.C.closedir(DIR)
		end

		return result
	end

	exists = function(path)
		local Buffer = Stat()
		return FFI.C.stat64(path, Buffer) == 0
	end

	is_directory = function(path)
		local Buffer = Stat()

		if FFI.C.stat64(path, Buffer) == 0 then
			return Bit.band(Buffer.st_mode, 0xf000) == FFI.C.S_IFDIR
		end

		return false
	end
end

function FileSystem.separator()
	-- Lua/Love2D returns all paths with back slashes.
	return "/"
end

function FileSystem.get_directory_items(directory, options)
	options = options == nil and {} or options
	options.files = options.files == nil and true or options.files
	options.directories = options.directories == nil and true or options.directories
	options.filter = options.filter == nil and "*.*" or options.filter

	if string.sub(directory, #directory, #directory) ~= FileSystem.separator() then
		directory = directory .. FileSystem.separator()
	end

	local result = get_directory_items(directory, options)

	table.sort(result)

	return result
end

function FileSystem.exists(path)
	return exists(path)
end

function FileSystem.is_directory(path)
	return is_directory(path)
end

function FileSystem.Parent(path)
	local result = path

	local index = 1
	local i = index
	repeat
		index = i
		i = string.find(path, FileSystem.separator(), index + 1, true)
	until i == nil

	if index > 1 then
		result = string.sub(path, 1, index - 1)
	end

	return result
end

--[[
	IsAbsolute

	Determines if the given path is an absolute path or a relative path. This is determined by checking if the
	path starts with a drive letter on Windows, or the Unix root character '/'.

	path: [String] The path to check.

	rtn: [Boolean] True if the path is absolute, false if it is relative.
--]]
function FileSystem.IsAbsolute(path)
	if path == nil or path == "" then
		return false
	end

	if FFI.os == "Windows" then
		return string.match(path, "(.:-)\\") ~= nil
	end

	return string.sub(path, 1, 1) == FileSystem.separator()
end

--[[
	GetDrive

	Attempts to retrieve the drive letter from the given absolute path. This function is targeted for
	paths on Windows. Unix style paths will just return the root '/'.

	path: [String] The absolute path containing the drive letter.

	rtn: [String] The drive letter, colon, and path separator are returned. On Unix platforms, just the '/'
		character is returned.
--]]
function FileSystem.GetDrive(path)
	if not FileSystem.IsAbsolute(path) then
		return ""
	end

	if FFI.os == "Windows" then
		local result = string.match(path, "(.:-)\\")

		if result == nil then
			result = string.match(path, "(.:-)" .. FileSystem.separator())
		end

		if result ~= nil then
			return result .. FileSystem.separator()
		end
	end

	return FileSystem.separator()
end

--[[
	sanitize

	This function will attempt to remove any '.' or '..' components in the path and will appropriately modify
	the result to represent changes to the path based on if a '..' component is found. This function will keep
	the path's scope (relative/absolute) during sanitization.

	path: [String] The path to be sanitized.

	rtn: [String] The sanitized path string.
--]]
function FileSystem.sanitize(path)
	local result = ""

	local items = {}
	for item in string.gmatch(path, "([^" .. FileSystem.separator() .. "]+)") do
		-- Always add the first item. If the given path is relative, then this will help preserve that.
		if #items == 0 then
			table.insert(items, item)
		else
			-- If the parent directory item is found, pop the last item off of the stack.
			if item == ".." then
				-- ignore same directory item and push the item to the stack.
				table.remove(items, #items)
			elseif item ~= "." then
				table.insert(items, item)
			end
		end
	end

	for i, item in ipairs(items) do
		if result == "" then
			if item == "." or item == ".." then
				result = item
			else
				if FileSystem.IsAbsolute(path) then
					result = FileSystem.GetDrive(path) .. item
				else
					result = item
				end
			end
		else
			result = result .. FileSystem.separator() .. item
		end
	end

	return result
end

function FileSystem.get_base_name(path, RemoveExtension)
	local result = string.match(path, "^.+/(.+)$")

	if result == nil then
		result = path
	end

	if RemoveExtension then
		result = FileSystem.RemoveExtension(result)
	end

	return result
end

function FileSystem.GetDirectory(path)
	local result = string.match(path, "(.+)/")

	if result == nil then
		result = path
	end

	return result
end

function FileSystem.GetRootDirectory(path)
	local result = path

	local index = string.find(path, FileSystem.separator(), 1, true)

	if index ~= nil then
		result = string.sub(path, 1, index - 1)
	end

	return result
end

function FileSystem.GetSlabPath()
	local path = love.filesystem.getSource()
	if not FileSystem.is_directory(path) then
		path = love.filesystem.getSourceBaseDirectory()
	end
	return path .. "/Slab"
end

function FileSystem.get_extension(path)
	local result = string.match(path, "[^.]+$")

	if result == nil then
		result = ""
	end

	return result
end

function FileSystem.RemoveExtension(path)
	local result = string.match(path, "(.+)%.")

	if result == nil then
		result = path
	end

	return result
end

function FileSystem.ReadContents(path, IsBinary)
	local result = nil

	local mode = IsBinary and "rb" or "r"
	local handle, err = io.open(path, mode)
	if handle ~= nil then
		result = handle:read("*a")
		handle:close()
	end

	return result, err
end

function FileSystem.SaveContents(path, Contents)
	local result = false
	local handle, err = io.open(path, "w")
	if handle ~= nil then
		handle:write(Contents)
		handle:close()
		result = true
	end

	return result, err
end

return FileSystem
