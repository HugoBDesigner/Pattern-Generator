local self = {}

self.rateX = 64
self.rateY = 64

self.name = "Image Repeater"
self.variables = {
	{t = "Horizontal Spacing", value = 0, extra = {0, 100, 1}},
	{t = "Vertical Spacing", value = 0, extra = {0, 100, 1}},
	{t = "Image", extra = "image"},
	{t = "Colored", value = true},
	{t = "Random Seed", value = 1, extra = {1, 1000, 1}},
	{t = "Rotate Randomly", value = false},
	{t = "Keep Aspect Ratio", value = true}
}

function self.draw(x, y, width, height, size, color)
	if self.variables[4].value then
		love.graphics.setColor(color)
	else
		love.graphics.setColor(255, 255, 255, 255)
	end
	
	local img = self.variables[3].value
	
	local asp = self.variables[7].value
	local ww, hh = img:getWidth(), img:getHeight()
	if asp == false then
		ww = math.max(ww, hh)
		hh = ww
	end
	local rX = math.ceil(width/(ww*size+self.variables[1].value))
	local rY = math.ceil(height/(hh*size+self.variables[2].value))
	
	for x = 1, rX do
		for y = 1, rY do
			if y == 1 then
				math.randomseed(self.variables[5].value + x)
			end
			math.randomseed(x + y + math.random())
			local xx = self.variables[1].value/2 + (x-1)*self.variables[1].value + (x-1)*img:getWidth()*size
			if img:getWidth() < img:getHeight() and not asp then
				local off = (img:getHeight() - img:getWidth())/2*size
				xx = xx + off + off*2*(x-1)
			end
			local yy = self.variables[2].value/2 + (y-1)*self.variables[2].value + (y-1)*img:getHeight()*size
			if img:getWidth() > img:getHeight() and not asp then
				local off = (img:getWidth() - img:getHeight())/2*size
				yy = yy + off + off*2*(y-1)
			end
			
			local a = math.rad((math.random(4)-1) * 90)
			if not self.variables[6].value then
				a = 0
			end
			love.graphics.draw(img, xx + img:getWidth()/2*size - math.cos(a)*img:getWidth()/2*size - math.cos(a+math.pi/2)*img:getHeight()/2*size,
			yy + img:getHeight()/2*size - math.cos(a)*img:getHeight()/2*size + math.cos(a+math.pi/2)*img:getWidth()/2*size, a, size, size)
		end
	end
end

function self.setRate(width, height, size)
	return 1, 1
end

function self.setIcon(w, h, c)
	local xx, yy = self.setRate(w, h, .5)
	for x = 1, xx do
		for y = 1, yy do
			self.draw(x, y, w, h, .5, c)
		end
	end
end

return self