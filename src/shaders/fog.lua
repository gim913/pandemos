return {
	ctor = function(self)
		self.canvas = love.graphics.newCanvas()
		self.shader = love.graphics.newShader[[
extern number opacity;
extern number utime;
float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noisef(vec2 st) {
	vec2 i = floor(st);
	vec2 f = fract(st);

	// Four corners in 2D of a tile
	float a = rand(i);
	float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0));
	float d = rand(i + vec2(1.0, 1.0));

	// Smooth Interpolation

	// Cubic Hermine Curve.  Same as SmoothStep()
	vec2 u = f*f*(3.0-2.0*f);
	// u = smoothstep(0.,1.,f);

	// Mix 4 coorners percentages
	return mix(a, b, u.x) +
			(c - a)* u.y * (1.0 - u.x) +
			(d - b) * u.x * u.y;
}

float fbm(vec2 st) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100.0);
	mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
	for (int i = 0; i < 5; ++i) {
		v += a * noisef(st);
		st = rot * st * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

vec4 effect(vec4 color, Image texture, vec2 _tc, vec2 _)
{
	vec2 tc = vec2((_tc.x) * 14.4, (_tc.y) * 9.0);

	vec2 q = vec2(0);
	q.x = fbm(tc + 3.00 * utime / 40.0);
	q.y = fbm(tc + vec2(1.0));

	vec2 r = vec2(0);
	r.x = fbm(tc + q + vec2(1.7,9.2)+ 0.15 * utime * 2.5);
	r.y = fbm(tc + q + vec2(8.3,2.8)+ 0.126 * utime * 2.5);

	float f = fbm(tc + r);
	float v = mix(0.5, 1.0, (f*f*f+0.6*f*f+0.5*f));
	return Texel(texture, _tc) * color * mix(0.0, v, opacity);
}
		]]

		-- return Texel(texture, tc) * color * vec4((f*f*f+0.6*f*f+0.5*f)*col, opacity);

		-- return color *
		-- * mix(0.0, pow(noisef(pos) + 0.1, 3), opacity);

		self.shader:send('opacity', 1.0)
		self.shader:send('utime', 0)
	end,

	render = function(self, func)
		-- call without instance
		self.renderShader(self.shader, self.canvas, func)
	end,

	set = function(self, key, value)
		if 'time' == key then
			self.shader:send('utime', value)
		end
	end
}