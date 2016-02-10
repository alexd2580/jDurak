-- http://tset.de/lsocket/README.html
local Socket = require "common/Socket"
local Card = require "common/Card"

require "common/util"
require "common/constants"

-- Window parameters
local window_size = nil
local background_path = nil
local background = nil
local background_size = nil

-- Server
local serv_addr = nil
local serv_port = nil
local server = nil

-- Game objects
local player_hand = nil
local opponent_hand = nil
local card_stack = nil

-- Graphics parts
local deck_card = nil
local font_path = nil
local main_font = nil
local font_height = nil

-- Graphics coordinates
local player_row = nil
local opponent_row = nil
local stack_pos = nil
local deck_pos = nil
local mouse_pos = nil

-- Game status
local game_running = nil
local pause_msg = nil
local turn_of_player = nil
local update_fps = nil
local draw_fps = nil

------------------- INIT -------------------

-- Connect to the selected server and exchange magicks
-- if connection fails, server is set to nil
function connect_server()
    local hdr = "[connect_server]"
    print(hdr, "Connecting to server: ", serv_addr..":"..serv_port)
    server = Socket(serv_addr, serv_port)
    server:write(client_magick)
    server_resp = server:read(magick_length)

    if server.err ~= nil then
        server:close()
        return
    end

    if server_resp ~= server_magick then
        local exp = " Invalid magick. Expected: "..server_magick
        server.err = hdr..exp.." Got: "..server_resp
        server:close()
        return
    end

    print(hdr, "Connected")
end

-- Loads images and fonts (used across games)
function prepare_graphics()
    local hdr = "[prepare_graphics] "
    print(hdr, "Loading background from ", background_path)
    background = love.graphics.newImage(background_path)
    if background == nil then
        return -- TODO
    end
    background_size = {
        w = background:getWidth(),
        h = background:getHeight()
    }
    print(hdr, "background_size.x = " .. background_size.w,
        "background_size.y = " .. background_size.h)

    print(hdr, "Loading cards")
    Card.load_deck() -- TODO errors?

    print(hdr, "Loading font from ", font_path)
    main_font = love.graphics.newFont(font_path, font_height)
    if main_font == nil then
        return --TODO
    end
    love.graphics.setFont(main_font)

end

-- Sets the position variables. fails if window is to small?
function compute_positions()
    print("[compute_positions]")
    w,h,_ = love.window.getMode()
    window_size = {
        w = w,
        h = h
    }

    local border_offset = 50
    player_row = window_size.h - border_offset - Card.draw_size.h
    opponent_row = border_offset
    stack_pos = {
        x = (window_size.w - Card.draw_size.w) / 2,
        y = (window_size.h - Card.draw_size.h) / 2
    }

    deck_pos = {
        x = window_size.w / 4 - Card.draw_size.w / 2,
        y = (window_size.h - Card.draw_size.h) / 2
    }

    mouse_pos = {
        x = 0, y = 0
    }

    -- load back card once (static graphical game object)
    deck_card = Card(0,0)
    deck_card.position.x = deck_pos.x
    deck_card.position.y = deck_pos.y
end

function love.load()
    print("[love.load]")

    font_path = "assets/fonts/blowbrush.otf"
    font_height = 50
    background_path = "assets/img/mapGround.jpeg"

    serv_addr = "127.0.0.1"
    serv_port = 7404

    -- Stuff required for empty game
    game_running = false
    pause_msg = "Waiting for server/opponent"
    update_fps = 0
    draw_fps = 0

    -- drawn in any case, therefore empty
    card_stack = {}
    player_hand = {}
    opponent_hand = {}

    connect_server()
    prepare_graphics()
    compute_positions()
end

------------ HANDLERS/UPDATE --------------

-- msg 0: Reset, start new game
function handle_init(str)
    print("[handle_init]", "Starting new game")

    card_stack = {}
    player_hand = {}
    opponent_hand = {}
    turn_of_player = msg_opponent
    game_running = true

    handle_server(str)
end

-- msg 1: Someone received a card
function handle_get(str)
    local p = nil
    p,str = server:get_digit(str)
    if p == msg_player then
        local card = nil
        card,str = server:get_card(str)
        table.insert(player_hand, card)
    else
        table.insert(opponent_hand, Card(0,0))
    end
    handle_server(str)
end

-- msg 2: A card has benn placed
function handle_put(str)
    local p = nil
    p,str = server:get_digit(str)
    local card = nil
    if p == msg_player then
        local i = nil
        i,str = server:get_num(str)
        card = player_hand[i]
        table.remove(player_hand, i)
    else
        card,str = server:get_card(str)
        table.remove(opponent_hand, math.random(#opponent_hand))
    end
    card.position.x = stack_pos.x + love.math.random() * 40 - 20
    card.position.y = stack_pos.y + love.math.random() * 40 - 20
    card.rotation = love.math.random() * 4 - 2
    table.insert(card_stack, card)
    handle_server(str)
end

-- The game is over
function handle_end(str)
    local w = nil
    w,str = server:get_digit(str)
    pause_msg = (w == msg_player) and "You win :D" or "You lose D:"
    game_running = false
    handle_server(str)
end

-- The turn changed
function handle_turn(str)
    local p = nil
    p,str = server:get_digit(str)
    turn_of_player = p
    handle_server(str)
end

-- Graphical effect. Remove cards from stack and put them on the deck
function handle_restack(str)
    local card = card_stack[#card_stack]
    card_stack = { card }
    handle_server(str)
end

-- Player has chosen a color (queen)
function handle_choose(str)
    handle_server(str)
end

-- Check if server has sent data
function handle_server(str)
    if server.err ~= nil then
        return
    end

    if str == nil then
        str = ""
    end
    if str:len() == 0 then
        str = server:read_nonblocking()
    end
    if str == false then
        print("[handle_server]", "Connection lost")
        game_running = false
        pause_msg = "Connection to server lost D:"
        return
    end
    if str:len() == 0 then
        return -- nothing to do
    end

    local cmd,str = server:get_digit(str)
    if cmd == msg_init then handle_init(str)
    elseif cmd == msg_get then handle_get(str)
    elseif cmd == msg_put then handle_put(str)
    elseif cmd == msg_turn then handle_turn(str)
    elseif cmd == msg_restack then handle_restack(str)
    elseif cmd == msg_choose then handle_choose(str)
    elseif cmd == msg_end then handle_end(str) end
end

-- When the mousebutton was released
function love.mousereleased(x, y)
    if not game_running then
        return -- TODO notify user?
    end

    -- Check if click is located on deck
    if y > deck_pos.y and y < deck_pos.y + Card.draw_size.h then
        if x > deck_pos.x and x < deck_pos.x + Card.draw_size.w then
            server:write(""..msg_get)
        end
    end

    -- Starting from the right (cards are overlapping)
    -- check whether a card is hit
    if y > player_row and y < player_row + Card.draw_size.h then
        local num_p_cards = #player_hand
        local offs,dff = draw_hand_offset(num_p_cards)
        local brd_rgt = offs + (num_p_cards-1) * dff + Card.draw_size.w / 2
        if x > brd_rgt then
            return
        end
        for i=num_p_cards, 1, -1 do
            brd_lft = offs + (i-1) * dff - Card.draw_size.w / 2
            if x > brd_lft then
                server:write(""..msg_put)
                put_num(i, server)
                return
            end
        end
    end
end

function local_update(dt)
  love.timer.sleep(0.01)
  update_fps = math.floor((30*update_fps + 1/dt) / 31)
  mouse_pos.x, mouse_pos.y = love.mouse.getPosition()
end

-- Executed repeatedly - client-side game logic loop
function love.update(dt)
    local_update(dt)
    handle_server("")
    if server.err ~= nil then
      print(server.err)
      love.update = local_update
    end
end

---------------- DRAW ------------------

-- Get the draw configuration of a player's hand
function draw_hand_offset(n)
    if n == 1 then
        return window_size.w/2, 0
    end
    s = (n-1) * 3 * Card.draw_size.w / 5
    s = math.min(s, window_size.w-Card.draw_size.w)
    o = (window_size.w - s) / 2
    return o,s/(n-1)
end

function draw_table()
    n = #card_stack
    for i=1, n, 1 do
        card_stack[i]:draw()
    end

    deck_card:draw()
end

function draw_hand_at(hand, row)
    local n = #hand
    local offs,dff = draw_hand_offset(n)
    for i=1, n, 1 do
        hand[i].position.x = offs + (i-1) * dff - Card.draw_size.w / 2
        hand[i].position.y = row
        hand[i]:draw()
    end
end

function love.draw()
    draw_fps = love.timer.getFPS()

    love.graphics.setColor(255, 255, 255)

    love.graphics.push()
    love.graphics.scale(
        window_size.w / background_size.w,
        window_size.h / background_size.h
    )
    love.graphics.draw(background, 0, 0)
    love.graphics.pop()

    draw_table()
    draw_hand_at(player_hand, player_row)
    draw_hand_at(opponent_hand, opponent_row)

    love.graphics.setColor(100, 100, 255)
    love.graphics.circle("fill", mouse_pos.x, mouse_pos.y, 15)

    love.graphics.setColor(255, 255, 255)
    love.graphics.print("FPS: "..update_fps.."/"..draw_fps, 10, 10, 0, 0.5)

    if not game_running then
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(pause_msg,
            10,
            window_size.h - 10 - font_height,
            0, 1)
    end
end
