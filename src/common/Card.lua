class = require "common/middleclass"

Card = class("Card")

function Card.load_color(tbl, color)
    for value=6, Card.ace, 1 do
        imagePath = 'assets/img/card_' .. color .. '_' .. value .. '.png'
        image = love.graphics.newImage(imagePath)
        tbl[value] = {
            image = image,
            size = {
                w = image:getWidth(),
                h = image:getHeight()
            }
        }
    end
end

function Card.load_deck()
    Card.valet = 11
    Card.queen = 12
    Card.king = 13
    Card.ace = 14

    Card.clubs = 1
    Card.hearts = 2
    Card.diamonds = 3
    Card.spades = 4

    Card.deck = {}
    table.insert(Card.deck, {})
    table.insert(Card.deck, {})
    table.insert(Card.deck, {})
    table.insert(Card.deck, {})

    Card.load_color(Card.deck[Card.clubs], Card.clubs)
    Card.load_color(Card.deck[Card.hearts], Card.hearts)
    Card.load_color(Card.deck[Card.diamonds], Card.diamonds)
    Card.load_color(Card.deck[Card.spades], Card.spades)

    Card.size = Card.deck[1][6].size
    Card.ratio = Card.size.h / Card.size.w
    Card.draw_size = {
        w = 100,
        h = 100*Card.ratio
    }

    backPath = 'assets/img/back.png'
    Card.back_image = love.graphics.newImage(backPath)
end

function Card:initialize(color, value)
    self.color = color
    self.value = value
    if color == 0 and value == 0 then
      self.image = Card.back_image
      self.size = Card.deck[1][6].size
    else
      self.image = Card.deck[color][value].image
      self.size = Card.deck[color][value].size
    end
    self.position = {
        x = 0,
        y = 0
    }
    self.color_rgb = {
      r = 150 + love.math.random(100),
      g = 150 + love.math.random(100),
      b = 150 + love.math.random(100)
    }
    self.rotation = 0
end

function Card:to_string()
    return "".. self.color .. math.floor(self.value / 10) .. (self.value % 10)
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

function Card:draw()
    love.graphics.push()
    love.graphics.setColor(self.color_rgb.r, self.color_rgb.g, self.color_rgb.b)
    love.graphics.translate(
        self.position.x + Card.draw_size.w / 2,
        self.position.y + Card.draw_size.h / 2
    )
    love.graphics.scale(Card.draw_size.w / self.size.w, Card.draw_size.h / self.size.h)
    love.graphics.rotate(self.rotation)
    --love.graphics.setColor(255, 255, 255, 128 + 128 * (self.ttl / item_max_ttl))
	love.graphics.draw(self.image, -Card.size.w/2, -Card.size.h/2)
    love.graphics.pop()
end

return Card
