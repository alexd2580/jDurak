class = require "common/middleclass"
lsocket = require "lsocket"

Socket = class("Socket")

function Socket:initialize(addr, port, socket)
  self.addr = addr
  self.port = port
  self.socket = socket
end

function Socket:bind()
  if self.socket ~= nil then
    print("Overwriting an already assigned socket")
  end
  self.socket = lsocket.bind("tcp", self.addr, self.port)
  ok,err = self.socket:status()
  if not ok then
    print("Could not bind socket", err)
    return false
  end
  return true
end

function Socket:connect()
  if self.socket ~= nil then
    print("Overwriting an already assigned socket")
  end
  self.socket = lsocket.connect("tcp", self.addr, self.port)
  ok,err = self.socket:status()
  if not ok then
    print("Could not connect", err)
    return false
  end
  return true
end

function Socket:wait_for_read()
  rd,err = lsocket.select({self.socket})
  if rd == nil then
    print(err)
    return false
  end
  return true -- no timeout
end

function Socket:wait_for_write()
  rd,wr = lsocket.select({}, {self.socket})
  if rd == nil then
    print(wr)
    return false
  end
  return true -- no timeout
end

function Socket:accept()
  self:wait_for_read()
	sock,addr,port = self.socket:accept()
  return Socket(addr, port, sock)
end

function Socket:read(n)
  self:wait_for_read()
  str,err = self.socket:recv(n)
  if str == nil then
    print("socket:recv() failed", err)
    return false
  elseif str == false then
    print("no data to read, Socket:wait_for_read() misbehaving")
    return false
  end
  return str
end

function Socket:read_nonblocking()
    str,err = self.socket:recv()
    if str == nil then
      print("socket:recv() failed", err)
      return false
    elseif str == false then
      return ""
    end
    return str
end

function Socket:write(str)
  local written = 0
  local to_write = #str
  while written < to_write do
    self:wait_for_write()
    nbytes,err = self.socket:send(str)
    if nbytes == nil then
      print("socket:send() failed", err)
      return false
    elseif nbytes == false then
      print("Impossible case")
      return false
    end
    written = written + nbytes
    str = str:sub(nbytes+1)
  end
  return true
end

function Socket:close()
  ok,err = self.socket:close()
  if not ok then
    print("Failed to close socket", err)
    return false
  end
  return true
end

return Socket
