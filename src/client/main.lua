-- http://tset.de/lsocket/README.html
local Socket = require "common/Socket"
local card = require "common/Card"

require "common/util"
require "common/constants"

local server = nil
local player = nil
local opponent = nil
local card_stack = nil
local window_size = nil
local background = nil
local background_size = nil

local player_row = nil
local opponent_row = nil
local stack_pos = nil
local deck_pos = nil
local mouse_pos = nil

local deck_card = nil

local main_font = nil
local font_height = nil
local game_running = nil
local pause_msg = nil

local turn_of_player = nil

local fps = nil

------------------- INIT -------------------

function connect_server()
    local serv_addr = "127.0.0.1"
    local serv_port = 7404

    print("Connecting to server: ", serv_addr..":"..serv_port)
    server = Socket:new(serv_addr, serv_port)
    if not server:connect() then
        server = nil
        return
    end

    server:write(client_magick)
    server_resp = server:read(magick_length)
    if server_resp ~= server_magick then
        server:close()
        server = nil
    end
end

connect_server() -- must be done before love loads

function love.load()
    imagePath = "assets/img/mapGround.jpeg"
    background = love.graphics.newImage(imagePath)
    background_size = {
      w = background:getWidth(),
      h = background:getHeight()
    }
    Card.load_deck()

    player = {
        num_cards = 0,
        hand = {}
    }

    opponent = {
        num_cards = 0,
        hand = {}
    }

    card_stack = {}

    w,h,_ = love.window.getMode()
    window_size = {
        w = w,
        h = h
    }

    player_row = window_size.h - 50 - Card.draw_size.h
    opponent_row = 50
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

    deck_card = Card(0,0) -- back_card
    deck_card.position.x = deck_pos.x
    deck_card.position.y = deck_pos.y

    local font_path = "assets/fonts/blowbrush.otf"
    font_height = 50
    main_font = love.graphics.newFont(font_path, font_height)
    love.graphics.setFont(main_font)

    game_running = false
    pause_msg = "Waiting for server"
    turn_of_player = msg_opponent
    fps = 0
end

------------ HANDLERS/UPDATE --------------

function handle_init(str)
    print "init"
    card_stack = {}

    player = {
        num_cards = 0,
        hand = {}
    }
    opponent = {
        num_cards = 0,
        hand = {}
    }

    turn_of_player = msg_opponent
    game_running = true

    handle_server(str)
end

function handle_get(str)
    print "get"
    p,str = get_digit(str, server)
    if p == msg_player then
        card,str = get_card(str, server)
        table.insert(player.hand, card)
        player.num_cards = table.getn(player.hand)
    else
        opponent.num_cards = opponent.num_cards + 1
        table.insert(opponent.hand, Card(0,0))
    end
    handle_server(str)
end

function handle_put(str)
    print "put"
    p,str = get_digit(str, server)
    if p == msg_player then
        i,str = get_num(str, server)
        card = player.hand[i]
        table.remove(player.hand, i)
        player.num_cards = table.getn(player.hand)
    else
        card,str = get_card(str, server)
        opponent.num_cards = opponent.num_cards - 1
        table.remove(opponent.hand, math.random(opponent.num_cards))
    end
    card.position.x = stack_pos.x + love.math.random() * 40 - 20
    card.position.y = stack_pos.y + love.math.random() * 40 - 20
    card.rotation = love.math.random() * 4 - 2
    table.insert(card_stack, card)
    handle_server(str)
end

function handle_end(str)
  w,str = get_digit(str, server)
  pause_msg = (w == msg_player) and "you win" or "you lose"
  game_running = false
  handle_server(str)
end

function handle_turn(str)
  p,str = get_digit(str, server)
  turn_of_player = p
  handle_server(str)
end

function handle_restack(str)
  crd = card_stack[#card_stack]
  card_stack = { crd }
  handle_server(str)
end

function handle_choose(str)
  handle_server(str)
end

function handle_server(str)
    if str == nil then
        str = ""
    end
    if str:len() == 0 then
        str = server:read_nonblocking()
    end
    if str:len() == 0 then
        return
    end

    cmd,str = get_digit(str) -- socket not required: len > 0
    print("msg:", cmd)
    if cmd == msg_init then handle_init(str)
    elseif cmd == msg_get then handle_get(str)
    elseif cmd == msg_put then handle_put(str)
    elseif cmd == msg_turn then handle_turn(str)
    elseif cmd == msg_restack then handle_restack(str)
    elseif cmd == msg_choose then handle_choose(str)
    elseif cmd == msg_end then handle_end(str) end
end

function love.mousereleased(x, y)
    if not game_running then
        print("game not running, ignoring mouse")
        return
    end
    if y > deck_pos.y and y < deck_pos.y + Card.draw_size.h then
        if x > deck_pos.x and x < deck_pos.x + Card.draw_size.w then
            server:write(""..msg_get)
            print("get cards")
        end
    end
    if y > player_row and y < player_row + Card.draw_size.h then
        offs,dff = draw_hand_offset(player.num_cards)
        brd_rgt = offs + (player.num_cards-1) * dff + Card.draw_size.w / 2
        if x > brd_rgt then
            print("too far right")
            return
        end
        for i=player.num_cards, 1, -1 do
            brd_lft = offs + (i-1) * dff - Card.draw_size.w / 2
            if x > brd_lft then
                server:write(""..msg_put)
                put_num(i, server)
                print("hit card ".. i)
                return
            end
        end
    end
end

function love.update(dt)
    fps = math.floor((30*fps + 1/dt) / 31)
    handle_server("")
    mouse_pos.x, mouse_pos.y = love.mouse.getPosition()
end

---------------- DRAW ------------------

function draw_hand_offset(n)
    if n == 1 then
        return window_size.w/2, 0
    end
    s = (n-1) * 3 * Card.draw_size.w / 5
    s = math.min(s, window_size.w-Card.draw_size.w)
    o = (window_size.w - s) / 2
    return o,s/(n-1)
end

function draw_opponent()
    offs,dff = draw_hand_offset(opponent.num_cards)

    for i=1, opponent.num_cards, 1 do
        opponent.hand[i].position.x = offs + (i-1) * dff - Card.draw_size.w / 2
        opponent.hand[i].position.y = opponent_row -- once?
        opponent.hand[i]:draw()
    end
end

function draw_table()
    n = #card_stack
    for i=1, n, 1 do
        card_stack[i]:draw()
    end

    deck_card:draw()
end

function draw_player()
    offs,dff = draw_hand_offset(player.num_cards)

    for i=1, player.num_cards, 1 do
        player.hand[i].position.x = offs + (i-1) * dff - Card.draw_size.w / 2
        player.hand[i].position.y = player_row -- once?
        player.hand[i]:draw()
    end
end

function love.draw()
  love.graphics.setColor(255, 255, 255)

  love.graphics.push()
  love.graphics.scale(
    window_size.w / background_size.w,
    window_size.h / background_size.h
  )
  love.graphics.draw(background, 0, 0)
  love.graphics.pop()

  draw_table()
  draw_player()
  draw_opponent()

  love.graphics.setColor(100, 100, 255)
  love.graphics.circle("fill", mouse_pos.x, mouse_pos.y, 15)

  love.graphics.setColor(255, 255, 255)
  love.graphics.print("FPS: "..fps, 10, 10, 0, 1)

  if not game_running then
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(pause_msg,
      10,
      window_size.h - 10 - font_height,
      0, 1)
  end
end

--[[ END ]]
