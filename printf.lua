do
    function interpretCommand(command)
        local arguments = {}
        local argSep = command:find(":", 1, true)

        if argSep ~= nil then
            for argument in string.gmatch(command:sub(argSep + 1), '([^,]+)') do
                arguments[#arguments+1] = argument
            end
            command = command:sub(1, argSep - 1)
        end

        if printf[command] ~= nil then
            local cmdFunc = printf[command]
            return 0, cmdFunc(cmd, arguments)
        else
            return 1
        end
    end

	function printf_call(printf, text, x, y, limitx, halign, limity, valign, scroll)
		halign = halign or "left"
		limity = limity or 100000 --math.huge
		valign = valign or "top"
        scroll = scroll or -1
        text = text:gsub("\n", "[n]")

        local currentFont = love.graphics.getFont()
        local strSegment = function(str)
            return {str = str, size = {currentFont:getWidth(str), currentFont:getHeight()}, appendSpace = true}
        end

        -- split into segments
        local cursor = 1
        local errors = 0
        local segments = {}
        while cursor <= text:len() do
            local commandStart = text:find("[", cursor, true)
            local commandEnd = commandStart and text:find("]", commandStart + 1, true)
            local nextSpace = text:find(" ", cursor, true)

            if (commandStart == nil or commandEnd == nil) and nextSpace == nil  then
                segments[#segments+1] = strSegment(text:sub(cursor))
                cursor = text:len() + 1
            else
                local cut = nil
                if commandStart and commandEnd and (nextSpace and commandStart < nextSpace or not nextSpace) then
                    cut = commandStart
                else
                    cut = nextSpace
                end
                local beforeSegment = text:sub(cursor, cut - 1)
                if beforeSegment ~= "" then
                    segments[#segments+1] = strSegment(beforeSegment)
                end

                if cut == commandStart then
                    local err, ret = interpretCommand(text:sub(commandStart + 1, commandEnd - 1))
                    errors = errors + err
                    cursor = commandEnd + 1

                    if err == 0 then
                        ret.size = ret.size or {0, 0}
                        segments[#segments+1] = ret
                    end
                else
                    cursor = nextSpace + 1
                end
            end
        end

        -- split into lines
        local lines = {{width = 0}}
        local curLineIndex = 1
        for i = 1, #segments do
            local curLine = lines[curLineIndex]
            local feed = function()
                curLineIndex = curLineIndex + 1
                lines[curLineIndex] = {width = 0}
                curLine = lines[curLineIndex]
            end

            if segments[i].newline then
                for n = 1, segments[i].newline do feed() end
            end

            -- with scrolling text, don't wrap lines
            if scroll < 0 and curLine.width + segments[i].size[1] > limitx and curLine.width > 0 then
                feed()
            end

            curLine[#curLine+1] = segments[i]
            curLine.width = curLine.width + segments[i].size[1] + (segments[i].appendSpace == true and currentFont:getWidth(" ") or 0)
        end

        -- drawing
        local scissX, scissY, scissW, scissH = love.graphics.getScissor()
        love.graphics.setScissor(x, y, limitx, limity)

        local totalHeight = 0
        for l = 1, #lines do
            local maxHeight = 0
            for s = 1, #lines[l] do
                maxHeight = math.max(maxHeight, lines[l][s].size[2])
            end
            lines[l].height = maxHeight
            totalHeight = totalHeight + maxHeight
        end
        local cy = nil-- cursor
        if valign == "top" then cy = 0 end
        if valign == "center" then cy = limity / 2 - currentFont:getHeight() / 2 end
        if valign == "bottom" then cy = limity - currentFont:getHeight() end
        assert(cy ~= nil, "vertical align must be top, center or bottom")

        for l = 1, #lines do
            local cx = nil
            if halign == "left" then cx = 0 end
            if halign == "center" then cx = limitx / 2 - lines[l].width / 2 end
            if halign == "right" then cx = limitx - lines[l].width end
            assert(cx ~= nil, "horizontal align must be left, center or right")
            cx = cx - scroll * math.max(0, lines[l].width - limitx)

            -- actual drawing
            local minOffY = math.huge
            for s = 1, #lines[l] do
                local segment = lines[l][s]
                local offy = currentFont:getHeight() / 2 - segment.size[2] / 2
                minOffY = math.min(minOffY, offy)

                local px, py = cx + x, cy + y + offy
                if segment.draw then segment.draw(px, py) end
                if segment.str then love.graphics.print(segment.str, px, py) end

                cx = cx + segment.size[1] + (segment.appendSpace == true and currentFont:getWidth(" ") or 0)
            end
            cy = cy + minOffY + lines[l].height
        end

        love.graphics.setScissor(scissX, scissY, scissW, scissH)

		return errors
	end

	local printf = setmetatable({}, {__call = printf_call})

	printf["blank"] = function(cmd, arguments)
		return {size = {tonumber(arguments[1]), tonumber(arguments[2] or 0)}}
	end

	printf["["] = function(cmd, arguments)
        local font = love.graphics.getFont()
		return {str = "[", size = {font:getWidth("["), font:getHeight()}}
	end

    printf["color"] = function(cmd, arguments)
        return {draw = function() love.graphics.setColor(unpack(arguments)) end}
    end

    printf["n"] = function(cmd, arguments)
        return {newline = 1}
    end


    function img_call(printfImg, cmd, arguments)
        local img = printfImg[arguments[1]]
        local scale = arguments[2] or 1.0
        return {size = {img:getWidth() * scale, img:getHeight() * scale}, draw = function(x, y) love.graphics.draw(img, x, y, 0.0, scale, scale) end, appendSpace = true}
    end
    printf["img"] = setmetatable({}, {__call = img_call})

    return printf
end
