--!strict
--[[
	API,
		Signal.new(), :Connect(), :Once(), :Fire(), :Wait(), :Disconnect(), :Destroy()
]]

local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

function Signal.new(): Signal
	return setmetatable({ _handlers = {} :: { any } }, Signal)
end

function Signal:Connect(fn): any
	assert(type(fn) == "function", "Connect espera una función")
	local connection = setmetatable({ _fn = fn, _signal = self, Connected = true }, Connection)
	table.insert(self._handlers, connection)
	return connection
end

function Connection:Disconnect()
	if self.Connected then
		self.Connected = false
		local handlers = self._signal._handlers
		local idx = table.find(handlers, self)
		if idx then
			table.remove(handlers, idx)
		end
	end
end

function Signal:Once(fn): any
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		fn(...)
	end)
	return connection
end

function Signal:Fire(...)
	local args = table.pack(...)
	-- Copia para que desconectar durante el Fire no cause problemas
	local handlers = table.clone(self._handlers)
	for _, connection in ipairs(handlers) do
		task.spawn(connection._fn, table.unpack(args, 1, args.n))
	end
end

function Signal:Wait()
	local thread = coroutine.running()
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:DisconnectAll()
	for _, connection in ipairs(table.clone(self._handlers)) do
		connection:Disconnect()
	end
end

Signal.Destroy = Signal.DisconnectAll

export type Connection = typeof(setmetatable({} :: { Connected: boolean, _fn: () -> (), _signal: any }, Connection))
export type Signal = typeof(setmetatable({} :: { _handlers: { any } }, Signal))

return Signal
