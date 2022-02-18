local self = {}

self.rateX = 32
self.rateY = 32
self.name = "Circled grid"
self.variables = {
	["1"] = {t = "Darker lines mode", value = {"None", "Diagonal", "Perpendicular", "Combined"}, extra = 1}
}
function self.draw(x, y, width, height, size, color)
	local xx, yy, ww, hh = (x-1)*self.rateX*size, (y-1)*self.rateY*size, self.rateX*size, self.rateY*size
	local mult = 1
	if size < 1 then
		mult = 1/(1/size)
	end
	
	local mode = self.variables["1"].value[self.variables["1"].extra]
	local c = {unpack(color)}
	for i = 1, 4 do c[i] = c[i]*.75 end
	love.graphics.setColor(c)
	love.graphics.setLineWidth(mult)
	
	if mode == "Diagonal" or mode == "Combined" then
		love.graphics.dashedLine(xx, yy, xx+ww, yy+hh, 4*mult)
		love.graphics.dashedLine(xx+ww, yy, xx, yy+hh, 4*mult)
	end
	
	if mode == "Perpendicular" or mode == "Combined" then
		love.graphics.dashedLine(xx+ww/2, yy, xx+ww/2, yy+hh, 4*mult)
		love.graphics.dashedLine(xx, yy+hh/2, xx+ww, yy+hh/2, 4*mult)
	end
	
	love.graphics.setColor(color)
	love.graphics.setLineWidth(2*mult)
	love.graphics.circle("line", xx+ww/2, yy+hh/2, ww/2, math.max(32, 32*size^2))
end

return self