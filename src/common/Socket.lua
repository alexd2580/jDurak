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

function Socket:accept()
  self:wait_for_read()
	sock,addr,port = self.socket:accept()
  return Socket(addr, port, sock)
end

function Socket:read(n)
  self:wait_for_read()
  string,err = self.socket:recv(n)
  if string == nil then
    print("socket:recv() failed", err)
    return false
  elseif string == false then
    print("no data to read, Socket:wait_for_read() misbehaving")
    return false
  end
  return string
end

function Socket:read_nonblocking()
    string,err = self.socket:recv()
    if string == nil then
      print("socket:recv() failed", err)
      return false
    elseif string == false then
      return ""
    end
    return string
end

function Socket:write(string)
  nbytes,err = self.socket:send(string)
  if nbytes == nil then
    print("socket:send() failed", err)
    return false
  elseif nbytes == false then
    print("TODO implement wait for send")
    return false
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
