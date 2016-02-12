-- Util lib for Socket.lua and Card.lua
local Socket = require "common/Socket"

-- Reads a 2-digit positive decimal number.
-- returns the number and the unparsed string
function Socket:get_num(str)
    local n1, n2
    n1,str = self:get_digit(str)
    n2,str = self:get_digit(str)
    if self.error == nil then
        return n1*10+n2, str
    end
end

-- Reads a decimal digit
-- returns the number and the unparsed string
function Socket:get_digit(str)
    if self.err == nil then
        if str == nil or str:len() == 0 then
            return self:get_digit(self:read())
        end
        return str:byte(1)-48, str:sub(2)
    end
end

-- Writes a 2-digit decimal number to the socket
function Socket:put_num(n)
    local n1 = math.floor(n / 10) -- lua 5.1 compat
    local n2 = n % 10
    self:put_digit(n1)
    self:put_digit(n2)
end

function Socket:put_digit(n)
    self:write(string.char(n+48))
end

-- returns the number and the unparsed string
function Socket:get_card(str)
    local c,v
    c,str = self:get_digit(str)
    v,str = self:get_num(str)
    if self.error == nil then
        return Card(c,v), str
    end
end

function Socket:put_card(card)
    self:put_digit(card.color)
    self:put_num(card.value)
end
