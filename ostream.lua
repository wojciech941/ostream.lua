local stl = {} do
	local space = stl

	space.manipulator = (function()
		local this = {}
		local meta = {}

		function meta:__index(type_)
			return function(format)
				local t = {}
				t.type = type_
				t.format = format
				t.is_manipulator = true
				return setmetatable(t, { __index = this })
			end
		end

		return setmetatable(this, meta)
	end)()

	space.endl = space.manipulator["endl"](function(ostream)
		ostream.ios:write("\n")
		ostream.manipulators = {}
		ostream.flags = {}
	end)

	space.boolalpha = space.manipulator["boolean"](function(ostream, value)
		if value ~= nil then
			return value and "true" or "false"
		else
			ostream.flags.boolean = true
		end
	end)

	space.noboolalpha = space.manipulator["boolean"](function(ostream, value)
		if value ~= nil then
			return value and "1" or "0"
		else
			ostream.flags.boolean = false
		end
	end)

	space.showbase = space.manipulator["showbase"](function(ostream)
		ostream.flags.showbase = true
	end)
	
	space.noshowbase = space.manipulator["showbase"](function(ostream)
		ostream.flags.showbase = false
	end)

	-- showpoint
	-- noshowpoint

	space.showpos = space.manipulator["showpos"](function(ostream)
		ostream.flags.showpos = true
	end)

	space.noshowpos = space.manipulator["showpos"](function(ostream)
		ostream.flags.showpos = false
	end)

	-- skipws
	-- noskipws

	space.uppercase = space.manipulator["uppercase"](function(ostream)
		ostream.flags.uppercase = true
	end)

	space.nouppercase = space.manipulator["uppercase"](function(ostream)
		ostream.flags.uppercase = false
	end)

	-- unitbuf
	-- nounitbuf

	-- space.internal = space.manipulator["placement_of_fill"](function(ostream)
		-- ostream.flags.placement_of_fill = 1
	-- end)

	space.left = space.manipulator["placement_of_fill"](function(ostream)
		ostream.flags.placement_of_fill = 0
	end)

	space.right = space.manipulator["placement_of_fill"](function(ostream)
		ostream.flags.placement_of_fill = 1
	end)

	space.dec = space.manipulator["integer"](function(ostream, value)
		if value ~= nil then
			return ("%d"):format(value)
		else
			ostream.flags.integer = 0
		end
	end)

	space.hex = space.manipulator["integer"](function(ostream, value)
		if value ~= nil then
			local fmt = ("%s%%%s"):format(
				ostream.flags.showbase and "0x" or "",
				ostream.flags.uppercase and "X" or "x")
			return fmt:format(value)
		else
			ostream.flags.integer = 1
		end
	end)

	space.oct = space.manipulator["integer"](function(ostream, value)
		if value ~= nil then
			local fmt = ("%s%%o"):format(
				ostream.flags.showbase and "0" or "")
			return fmt:format(value)
		else
			ostream.flags.integer = 3
		end
	end)

	space.fixed = space.manipulator["floating"](function(ostream, value)
		if value ~= nil then
			local fmt = ("%%.%s%s"):format(
				ostream.flags.precision or 6,
				ostream.flags.uppercase and "f" or "f")
			return fmt:format(value)
		else
			ostream.flags.floating = 0
		end
	end)

	space.scientific = space.manipulator["floating"](function(ostream, value)
		if value ~= nil then
			local fmt = ("%%.%s%s"):format(
				ostream.flags.precision or 0,
				ostream.flags.uppercase and "E" or "e")
			return fmt:format(value)
		else
			ostream.flags.floating = 1
		end
	end)

	-- hexfloat

	space.defaultfloat = space.manipulator["floating"](function(ostream, value)
		if value ~= nil then
			local fmt = ("%%%s"):format(
				ostream.flags.uppercase and "G" or "g")
			return fmt:format(value)
		else
			ostream.flags.floating = 3
		end
	end)

	-- ws

	space.ends = space.manipulator["ends"](function(ostream)
		ostream.ios:write("\0")
	end)

	function space.setprecision(precision)
		return space.manipulator["setprecision"](function(ostream)
			if tonumber(precision) then
				ostream.flags.precision = precision
			end
		end)
	end

	function space.setw(width)
		return space.manipulator["setw"](function(ostream)
			if tonumber(width) then
				ostream.flags.width = width
			end
		end)
	end

	space.ostream = (function()
		local this = {}
		local meta = {}
		local flags_ = {}

		function flags_.integer(ostream, value, raw)
			value = tostring(value)
			if not ostream.flags.integer or ostream.flags.integer == 0 then
				if ostream.flags.showpos then
					value = (raw > 0 and "+" or "") .. value
				end
			end
			return value
		end

		function flags_.floating(ostream, value, raw)
			value = tostring(value)
			if ostream.flags.showpos then
				value = (raw > 0 and "+" or "") .. value
			end
			if ostream.flags.precision and not ostream.flags.floating then
				local fmt = ("%%.%sf"):format(
					ostream.flags.precision)
				return fmt:format(raw)
			else
				return value
			end
		end

		function flags_.boolean(ostream, value, raw)
			return (not ostream.flags.boolean) and (raw and "1" or "o") or (value)
		end

		function flags_.any(ostream, value, raw)
			return tostring(value)
		end

		---@any value
		---@return [nil]
		function this:put(value)
			local type_ = type(value)
			if type_ == "number" then
				type_ = (value == math.floor(value)) and "integer" or "floating"
			elseif type_ == "table" then
				if value.is_manipulator then
					self.manipulators[value.type] = value
					value.format(self)
					return
				end
			end
			local raw = value
			if self.manipulators[type_] then
				value = self.manipulators[type_].format(self, value)
				if not value then
					return
				end
			end

			local fmt = ("%%%s%ss"):format(self.flags.placement_of_fill == 0 and "-" or "", self.flags.width or 0)
			value = (flags_[type_] or flags_.any)(self, value, raw)

			self.ios:write(fmt:format(value))
		end

		meta.__index = this

		---@varargs
		---@return [ostream]
		function meta:__call(...)
			for i = 1, select("#", ...) do
				self:put(select(i, ...))
			end
			return self
		end

		---@userdata ios
		---@return [ostream]
		local function constructor(_, ios)
			assert(type(ios) == "userdata", "ostream: expected userdata with write method")
			assert(type(ios.write) == "function", "ostream: missing 'write' method")
			local t = {}
			t.ios = ios
			t.flags = {}
			t.manipulators = {}
			return setmetatable(t, meta)
		end

		return setmetatable(this, { __call = constructor })
	end)()

	space.cout = space.ostream(io.stdout)
	space.cerr = space.ostream(io.stderr)
end
