
magick_length = 17
client_magick = "18923472837461283"
server_magick = "76976543437095976"

-- Server -> to indicate game start
msg_init = 0

-- Server -> player gets a card
-- @1 player"id"
-- @2 @1 == local ? card : nil
-- Client -> request card
msg_get = 1

-- Server -> card is put on table by @1
-- @1 player"id"
-- @2 @1 == local ? index : card
-- Client -> request put card
-- @1 index
msg_put = 2

-- Server -> player @1 won
-- @1 player"id"
msg_end = 3

-- Server -> no more cards in deck, resupply
msg_restack = 4

-- Server -> Change the color of the top card (usually queen)
-- @1 color
-- Client -> Select the color of the top card (usually queen)
-- @1 color
msg_choose = 5

-- Server -> notify the player whose turn it is
-- @1 player"id"
msg_turn = 6

-- player"id"
msg_player = 0
msg_opponent = 1

msg_lose = 0
msg_win = 1
