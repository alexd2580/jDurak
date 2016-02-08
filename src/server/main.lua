Socket = require "common/Socket"
require "common/constants"
require "common/util"

Card = class("Card")

Card.valet = 11
Card.queen = 12
Card.king = 13
Card.ace = 14

Card.clubs = 1
Card.hearts = 2
Card.diamonds = 3
Card.spades = 4

function Card:initialize(color, value)
    self.color = color
    self.value = value
end

function Card:to_string()
    return "".. self.color .. self.value // 10 .. self.value % 10
end

function Card:print()
    if self.value < 11 then
        io.write(self.value)
    elseif self.value == Card.valet then
        io.write("valet")
    elseif self.value == Card.queen then
        io.write("queen")
    elseif self.value == Card.king then
        io.write("king")
    elseif self.value == Card.ace then
        io.write("ace")
    end
    io.write(" of ")
    if self.color == Card.diamonds then
        print("diamonds")
    elseif self.color == Card.hearts then
        print("hearts")
    elseif self.color == Card.spades then
        print("spades")
    elseif self.color == Card.clubs then
        print("clubs")
    end
end

server_socket = nil
clients = nil
card_stack = nil
card_deck = nil

turn_of_player = nil
prev_can_play = nil
has_to_draw = nil

function init_server()
    server_socket = Socket(lsocket.INADDR_ANY, 7404)
    server_socket:bind()
end

function wait_connection()
    client_socket = server_socket:accept()
    print("Client connected", client_socket.addr..":"..client_socket.port)

    client_resp = client_socket:read(magick_length)
    if client_resp ~= client_magick then
        print("Invalid magick. Expected", client_magick, "Got", client_resp)
        return
    end
    client_socket:write(server_magick)

    table.insert(clients, {
        socket = client_socket,
        hand = {}
    })
end

function broadcast(msg, clt_i, clt_msg)
    n = #clients
    for i=1, n, 1 do
        if i ~= clt_i then
            clients[i].socket:write(msg)
        end
    end
    if clt_i ~= nil then
        clients[clt_i].socket:write(clt_msg)
    end
end

function draw_rand_card()
    n = #card_deck
    i = math.random(n)
    c = card_deck[i]
    table.remove(card_deck, i)
    return c
end

function give_n_cards(clt_i, n)
    for i=1, n, 1 do
        crd = draw_rand_card()
        table.insert(clients[clt_i].hand, crd)
        opmsg = ""..msg_get..msg_opponent
        plmsg = ""..msg_get..msg_player..crd:to_string()
        broadcast(opmsg, clt_i, plmsg)
        io.write("Giving "..clt_i..": ")
        crd:print()
    end
end

function put_on_table(crd_i, clt_i)
    crd = clients[clt_i].hand[crd_i]
    table.remove(clients[clt_i].hand, crd_i)
    table.insert(card_stack, crd)
    pref = ""..msg_put
    crd_i_s = ""..(crd_i//10)..(crd_i%10)
    broadcast(pref..msg_opponent..crd:to_string(),
        clt_i, pref..msg_player..crd_i_s)
    io.write(clt_i.." played ")
    crd:print()
    print("turn_of ", turn_of_player)
    print("penalty ", has_to_draw)
    print("prev_ins ", prev_can_play)
end

function init_game()
    broadcast(""..msg_init)
    card_stack = {}
    card_deck = {}
    for i=1, 4, 1 do
        for j=6, 14, 1 do
            table.insert(card_deck, Card(i, j))
        end
    end

    n = #clients
    for i=1, n, 1 do
        clients[i].hand = {}
        give_n_cards(i, 5)
    end

    turn_of_player = 2
    has_to_draw = 0
    prev_can_play = false
    put_on_table(1, 1)
end

function advance_player()
    turn_of_player = (turn_of_player % #clients) + 1
end

function add_penalty(n)
    has_to_draw = has_to_draw + n
end

function handle_get(clt_i, clt)
    if turn_of_player == clt_i then
        if has_to_draw == 0 then
            give_n_cards(clt_i, 1)
            prev_can_play = true
        else
            give_n_cards(clt_i, has_to_draw)
            prev_can_play = false
        end
        has_to_draw = 0
        advance_player()
        print("turn_of ", turn_of_player)
        print("penalty ", has_to_draw)
        print("prev_ins ", prev_can_play)
    end
end

function matches_top_card(crd)
    top = card_stack[#card_stack]
    -- Does the card match at all?
    if crd.value == top.value or crd.color == top.color
    then
        -- If you're in a 6-draw you can only place 6s
        if top.value == 6 and has_to_draw ~= 0
        then
            return crd.value == 6
        -- If you're in a 7-draw you can only place 7s
        elseif top.value == 7 and has_to_draw ~= 0
        then
            return crd.value == 7
        -- The the top card is a king and prev. a pique king was played
        elseif top.value == Card.king and has_to_draw ~= 0
        then
            return crd.value == Card.king
        -- An 8 can only be covered by 8s or larger same color cards
        elseif top.value == 8
        then
            return crd.value >= 8
        end
        return true
    -- Exception for queens
    elseif crd.value == Card.queen and has_to_draw == 0
    then
        return true
    end
    -- Card doesn'n match
    return false
end

function handle_put(clt_i, clt, crd_i)
    if turn_of_player == clt_i or prev_can_play == true then
        crd = clt.hand[crd_i]
        if matches_top_card(crd) then
            turn_of_player = clt_i
            prev_can_play = false
            if crd.value == 6 then
                add_penalty(1)
                advance_player()
            elseif crd.value == 7 then
                add_penalty(2)
                advance_player()
            elseif crd.value == 8 then
                -- nothing // does not skip next
            elseif crd.value == Card.king and crd.color == Card.spades then
                add_penalty(5)
                advance_player()
            elseif crd.value == Card.ace then
                advance_player() --skips next
                advance_player()
            else
                advance_player()
            end
            put_on_table(crd_i, clt_i)
        end
        -- else do nothing
    end
end

function handle_end(clt_i)
    broadcast(""..msg_end..msg_opponent, clt_i, ""..msg_end..msg_player)
end

function handle_client(clt_i)
    clt = clients[clt_i]
    res = clt.socket:read_nonblocking()
    if res ~= false then -- if socket was still connected
        while res:len() > 0 do
            cmd,res = get_digit(res) -- socket not required: len > 0
            print("msg:", cmd)
            if cmd == msg_get then
                handle_get(clt_i, clt)
            elseif cmd == msg_put then
                crd_i,res = get_num(res, clt.socket)
                handle_put(clt_i, clt, crd_i)
                if turn_of_player ~= clt_i and #clt.hand == 0 then
                    handle_end(clt_i)
                end
            end
        end
        return true
    else
        return false
    end
end

function handle_clients()
    n = #clients
    for i=1, n, 1 do
        if not handle_client(i) then
            return false
        end
    end
    return true
end

function main()
    init_server()
    clients = {}
    num_players = 2
    while #clients ~= num_players do
        wait_connection()
    end
    init_game()
    while 1 ~= 2 do
        if not handle_clients() then
            return
        end
        a,b,c = os.execute("sleep 0.5")
        if b == "signal" then
            return
        end
    end
end

main()
