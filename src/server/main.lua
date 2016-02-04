Socket = require "Socket"

print("Launching jDurak server")

server_socket = Socket:new(lsocket.INADDR_ANY, 7404)
server_socket:bind()
client_socket = server_socket:accept()
print("Client connected", client_socket.addr..":"..client_socket.port)

client_socket:write("syn rofl")
print(client_socket:read())

client_socket:close()
server_socket:close()

print("Stopping jDurak server")
