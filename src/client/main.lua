-- http://tset.de/lsocket/README.html
Socket = require "Socket"

print("Launching jDurak client")

serv_addr = "127.0.0.1"
serv_port = 7404

print("Connecting to server: ", serv_addr..":"..serv_port)
socket = Socket:new(serv_addr, serv_port)
socket:connect()
print(socket:read())
socket:write("lol ack")
socket:close()

print("Stopping jDurak client")
