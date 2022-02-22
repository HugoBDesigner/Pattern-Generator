local self = {}

self.variables = {
	[1] = 	{t = "Line width", value = 2, extra = {0.1, 100, 0.1}},
	[2] = 	{t = "Darker lines visible", value = true},
	[3] = 	{t = "Darker lines gap", value = 4, extra = {1, 32}},
	[4] = 	{t = "Dashed lines mode", value = {"None", "Diagonal", "Perpendicular", "Combined"}, extra = 2}
}
self.rateX = 32
self.rateY = 32
self.name = "Default Squared"

function self.draw(x, y, width, height, size, color)
	local xx, yy, ww, hh = (x-1)*self.rateX*size, (y-1)*self.rateY*size, self.rateX*size, self.rateY*size
	
	local t = {}
	local names = {	1, "width", "value",
					2, "vis", "value",
					3, "darkline", "value",
					4, "mode", "extra"}
	for i = 3, #names, 3 do
		t[ names[i-1] ] = self.variables[ names[i-2] ][ names[i] ]
		if names[i] == "extra" then
			t[ names[i-1] ] = self.variables[ names[i-2] ].value[ t[ names[i-1] ] ]
		end
	end
	
	local alpha = {unpack(color)}
	local dark = {unpack(color)}
	for i = 1, 3 do dark[i] = dark[i]*.9 end
	alpha[4] = .75
	
	local mult = 1
	if size < 1 then
		mult = 1/(1/size)
	end
	
	love.graphics.setLineWidth(t.width)
	
	love.graphics.dashedLine(xx, yy+hh, xx+ww, yy+hh, 6*mult) --bottom
	love.graphics.dashedLine(xx+ww, yy, xx+ww, yy+hh, 6*mult) --right
	
	if math.mod(x+(t.darkline-1), t.darkline) == 0 and t.vis then
		love.graphics.setColor(dark)
		love.graphics.setLineWidth(t.width*2)
	end
	love.graphics.dashedLine(xx, yy, xx, yy+hh, 6*mult) --top
	
	love.graphics.setColor(color)
	love.graphics.setLineWidth(t.width)
	if (math.mod(y-1, t.darkline) == 0) and t.vis then
		love.graphics.setColor(dark)
		love.graphics.setLineWidth(t.width*2)
	end
	love.graphics.dashedLine(xx, yy, xx+ww, yy, 6*mult) --left
	
	love.graphics.setColor(alpha)
	
	love.graphics.setLineWidth(t.width)
	if t.mode ~= "None" then
		if t.mode == "Diagonal" or t.mode == "Combined" then
			love.graphics.dashedLine(xx+ww, yy, xx, yy+hh, 3*mult)
			love.graphics.dashedLine(xx, yy, xx+ww, yy+hh, 3*mult)
		end
		if t.mode == "Perpendicular" or t.mode == "Combined" then
			love.graphics.dashedLine(xx+ww/2, yy, xx+ww/2, yy+hh, 3*mult)
			love.graphics.dashedLine(xx, yy+hh/2, xx+ww, yy+hh/2, 3*mult)
		end
	end
end

return self
