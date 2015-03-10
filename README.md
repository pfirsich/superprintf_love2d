# superprintf_love2d
This is a new printf function for love2d that let's you include images in your text, change colors inside the string and define custom commands.

## Usage
> printf = require("printf")
> printf["img"]["xbox_a"] = love.graphics.newImage("
> printf("[color:255,0,0,255]This is red text.[n]In a new line, I include an [img:xbox_a] inside the text", 5, 5, 300, "center", 300, "center")

Also for an example of almost every feature, see main.lua The usage is very similar to love2d's printf, but adds the option of having vertical alignment and of course custom strings.

To define your custom commands, just add another key to printf and have a look at printf.lua to see how exactly these functions have to be implemented:
function printf.red() return printf.color("", {255, 0, 0, 255}) end

If there are any questions or improvements, please let me know!