-- module
local graphics = {}

-- fix bugged 'line' in love2d
function graphics.rectangle(style, x, y, w, h)
	if 'line' == style then
		love.graphics.rectangle('line', x + 1, y, w - 1, h - 1)
		return
	end
	love.graphics.rectangle('fill', x, y, w, h)
end

return graphics
