return {
	ctor = function(self)
		self.canvas = love.graphics.newCanvas()
		self.shader = love.graphics.newShader[[
vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _)
{
	vec4 col = vec4(0.0);

	vec2 off1 = vec2(1.411764705882353) * vec2(1, 1);
	vec2 off2 = vec2(3.2941176470588234) * vec2(1, -1);
	vec2 off3 = vec2(5.176470588235294) * vec2(1, 1);
	col += Texel(texture, tc) * 0.1964825501511404;
	col += Texel(texture, tc + (off1 / 720)) * 0.2969069646728344;
	col += Texel(texture, tc - (off1 / 720)) * 0.2969069646728344;
	col += Texel(texture, tc + (off2 / 720)) * 0.09447039785044732;
	col += Texel(texture, tc - (off2 / 720)) * 0.09447039785044732;
	col += Texel(texture, tc + (off3 / 720)) * 0.010381362401148057;
	col += Texel(texture, tc - (off3 / 720)) * 0.010381362401148057;
	return col;
}
		]]

		self.shader:send("opacity", 1.0)
		self.shader:send("offsetx", 0)
		self.shader:send("offsety", 0)
	end,

	render = function(self, func)
		local s = love.graphics.getShader()
		local old_canvas = love.graphics.getCanvas()
		love.graphics.setCanvas(self.canvas)
		love.graphics.clear()

		func()

		love.graphics.setCanvas(old_canvas)
		love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
		love.graphics.setShader(self.shader)
		local b = love.graphics.getBlendMode()
		love.graphics.setBlendMode('alpha', 'premultiplied')
		love.graphics.draw(self.canvas, 0, 0)
		love.graphics.setBlendMode(b)
		love.graphics.setShader(s)
	end,

	set = function(self, key, value)
	end
}