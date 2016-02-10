local class = require "common/middleclass"
local lsocket = require "lsocket"

local Socket = class("Socket")

function Socket:initialize(addr, port, socket, err)
    self.addr = addr
    self.port = port
    self.socket = socket
    self.err = err
end

-- Binds the socket to its address
function Socket:bind()
    if self.err == nil then
        if self.socket ~= nil then
            print("Overwriting an already assigned socket")
        end
        self.socket = lsocket.bind("tcp", self.addr, self.port)
        local ok,err = self.socket:status()
        if not ok then
            self.err = "[Socket:bind] "..err
        end
    end
end

-- Tries to connect to its address
function Socket:connect()
    if self.err == nil then
        if self.socket ~= nil then
            print("Overwriting an already assigned socket")
        end
        self.socket = lsocket.connect("tcp", self.addr, self.port)
        local ok,err = self.socket:status()
        if not ok then
            self.err = "[Socket:connect] "..err
        end
    end
end

-- Blocks until at least one byte can be read from the socket
function Socket:wait_for_read()
    if self.err == nil then
        local rd,err = lsocket.select({self.socket})
        if rd == nil then
            self.err = "[Socket:wait_for_read] "..err
        end
    end
end

-- blocks until at least one byte can be written to the socket
function Socket:wait_for_write()
    if self.err == nil then
        local rd,wr = lsocket.select({}, {self.socket})
        if rd == nil then
            self.err = "[Socket:wait_for_write] "..wr
        end
    end
end

-- Blocks until a client tries to connect to this socket
function Socket:accept()
    self:wait_for_read()
    local sock,addr,port
    if self.err == nil then
        sock,addr,port = self.socket:accept()
        if sock == nil then
            self.err = "[socket:accept] "..addr
        elseif sock == false then
            self.err = "[Socket:accept] Socket:wait_for_read() misbehaving"
        end
    end
    return Socket(addr, port, sock, err)
end

-- Reads at most n bytes from the socket
-- @1 the max number of bytes to read
-- returns undefined on error
function Socket:read(n)
    self:wait_for_read()
    local str = self:read_nonblocking(n)
    if str == "" then
        self.err = "[Socket:read] Socket:wait_for_read() misbehaving"
    end
    return str
end

-- Returns a possibly empty string
-- returns undefined on error
function Socket:read_nonblocking(n)
    if self.err == nil then
        local str,err = self.socket:recv(n)
        if str == nil then
            self.err = "[Socket:read_nonblocking]"..err
        end
        return str == false and "" or str
    end
end

-- Tries to write the string to the socket
function Socket:write(str)
    local written = 0
    local to_write = #str
    while written < to_write do
        self:wait_for_write()
        if self.err ~= nil then return end
        local nbytes,err = self.socket:send(str)
        if nbytes == nil then
            self.err = "[Socket:write] "..err
            return
        elseif nbytes == false then
            self.err = "[Socket:write] Socket:wait_for_write() misbehaving"
            return
        end
        written = written + nbytes
        str = str:sub(nbytes+1)
    end
end

function Socket:close()
    -- Try to close it anyway, for the sake of closing it
    if self.socket ~= nil then
        local ok,err = self.socket:close()
        if not ok then
            -- Append the error
            self.err = self.err.."\n[Socket:close] "..err
        end
    end
end

return Socket
