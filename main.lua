printf = require("printf")

function printf.red() return printf.color("", {255, 0, 0, 255}) end
function printf.blue() return printf.color("", {0, 0, 255, 255}) end

function printf.block(cmd, arguments) -- this should provide an example for including XBox-Button-Images or Emojis into your text!
	local fh = love.graphics.getFont():getHeight()
	local w, h = tonumber(arguments[1]), tonumber(arguments[2])
	return {size = {w, h}, draw = function(x, y) love.graphics.rectangle("line", x, y, w, h) end, str ="box", appendSpace = true}
end

printf["img"]["xbox_a"] = love.graphics.newImage("xbox_a.png")

function love.draw()
	local x, limit = 5, 400
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.rectangle("line", 5, 0, limit, love.window.getHeight())
	local errors = printf("Test string [blank:50] <- big [red] space [unknown] and or then what [block:50,35] after [blue] it with [[]blue] and now [n]new line", x, 5, limit)
	printf("[color:255,255,0,255]" .. tostring(errors) .. " Unknown directives", x, 100, limit)

	local y_img = 150
	printf("[color:255,255,255,255] Press [img:xbox_a] to do something awesome", x, y_img, limit, "center", love.window.getHeight() - y_img, "center")
end
