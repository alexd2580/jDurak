
function get_num(str, socket)
    n1,str = get_digit(str, socket)
    n2,str = get_digit(str, socket)
    return n1*10+n2, str
end

function get_digit(str, socket)
    if str:len() > 0 then
        return str:byte(1)-48, str:sub(2)
    else
        get_digit(socket:read())
    end
end

function put_num(n, socket)
    n1 = n // 10
    n2 = n % 10
    put_digit(n1, socket)
    put_digit(n1, socket)
end

function put_digit(n, socket)
    socket:write(string.char(n))
end

function get_card(str, socket)
    c,str = get_digit(str, socket)
    v,str = get_num(str, socket)
    return Card(c,v),str
end

function put_card(card, socket)
    put_digit(card.color, socket)
    put_num(card.value, socket)
end
