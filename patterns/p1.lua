--[[																																				(this line was made so that the
	Pattern #1: squares with diagonal dashed lines																									'tutorial' would look prettier)
		by HugoBDesigner
		
	Reference on how to make patterns:																												]]
		
		local myTable = {} -- The table you'll return
		
		myTable.rateX = 'value' --[[ How many pixels each iteration of the pattern takes horizontally												]]
		myTable.rateY = 'value' --[[ How many pixels each iteration of the pattern takes vertically													]]
		myTable.name = "name"	--[[ Optional. The name to be displayed for pattern. Defaults to file name
		
		
		myTable.variables: A table containing all variables that you'd like to be configurable. Must follow this pattern:							]]
		myTable.variables = {
			name = {t, value, extra},
			name = {t, value, extra},
			name = {t, value, extra}
		}																																			--[[
		
		"name":		Represents the name of that variable (for example, "radius" or "dashed line color")
		"value":	Represents the value of said variable (for example, 45 or {105, 155, 205, 255})
		"extra":	Represents some extra configuration settings that vary for each type:
			table: 	"color", if the table represents an rgba value
					'numb', if the table represents options to choose from, numb will represent the currently-selected option
			
			number: 'table' {min, max, factor, cycles}
						'min': the minimum value.
						'max': the maximum value.
						'factor': how much adds/subtracts on that variable. (default: 1)
						'cycles': a boolean that tells if the value should cycle if it reaches an end. (default: false)
					
					function(arg), where the argument is either 1 or -1, and must return the new value for that variable.
			
			toggle: Requires no extra. If value is true, will set it to false, and vice-versa.
			
			button: Function, where it must return nothing.
			
		Examples:																																	]]
			myTable.variables = {
				
				["1"] = {t = "Dashed Line Color", value = {105, 155, 205, 255}, extra = "color"},
				["2"] = {t = "Dashed Line Radius", value = 45, extra = {0, 360-15, 15, true}},
				["3"] = {t = "Enable Dashed Line", value = true},
				["4"] = {t = "Dashed Line Mode", value = {"Diagonal", "Perpendicular", "Combined"}, extra = 1},
				["5"] = {t = "Set Random Line Color", value = function()
						local a = {}
						for i = 1, 3 do
							a[i] = math.random(255)
						end
						a[4] = 255
						
						myTable.variables["1"].value = {unpack(a)}
					end}
				
			}
		
		
		function myTable.setRate(width, height, size) 																								end--[[
		width:	The width of the image the pattern will be rendered over.
		height:	The height of the image the pattern will be rendered over.
		size:	The size of the pattern. It's a multiplier value for the default size you want.
		
		This function is optional and, if used, overwrites calculations with rateX and rateY
		Must return x and y, being x the number of horizontal iterations and y the number of vertical iterations									]]
		
		
		function myTable.draw(x, y, width, height, size, color)																						end--[[
		x:		The x index in the pattern. It's an index number, not a coordinate. Starts at 1 and ends at image width/rateX
		y:		The y index in the pattern. It's an index number, not a coordinate. Starts at 1 and ends at image height/rateY
		width:	The width of the image the pattern will be rendered over.
		height:	The height of the image the pattern will be rendered over.
		size:	The size of the pattern. It's a multiplier value for the default size you want.
		color:	Optional. Patterns's colors are preset, but if needed, you can adjust its color by changing the original rgba.
		
		This function must returns nothing																											]]local function ignore()
		
		return myTable --[[ Required for the data to become accessible																				]]end




local self = {}

self.variables = {
	["1"] = 	{t = "Darker lines visible", value = true},
	["2"] = 	{t = "Darker lines factor", value = 4, extra = {2, 16}},
	["3"] =		{t = "Dashed lines mode", value = {"None", "Diagonal", "Perpendicular", "Combined"}, extra = 2}
}
self.rateX = 32
self.rateY = 32
self.name = "Default Squared"

function self.draw(x, y, width, height, size, color)
	local xx, yy, ww, hh = (x-1)*self.rateX*size, (y-1)*self.rateY*size, self.rateX*size, self.rateY*size
	
	local t = {}
	local names = {	"1", "vis", "value",
					"2", "darkline", "value",
					"3", "mode", "extra"}
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
	
	love.graphics.setLineWidth(2*mult)
	
	love.graphics.dashedLine(xx, yy+hh, xx+ww, yy+hh, 6*mult) --bottom
	love.graphics.dashedLine(xx+ww, yy, xx+ww, yy+hh, 6*mult) --right
	
	if math.mod(x+(t.darkline-1), t.darkline) == 0 and t.vis then
		love.graphics.setColor(dark)
		love.graphics.setLineWidth(3*mult)
	end
	love.graphics.dashedLine(xx, yy, xx, yy+hh, 6*mult) --top
	
	love.graphics.setColor(color)
	love.graphics.setLineWidth(2*mult)
	if (math.mod(y-1, t.darkline) == 0) and t.vis then
		love.graphics.setColor(dark)
		love.graphics.setLineWidth(3*mult)
	end
	love.graphics.dashedLine(xx, yy, xx+ww, yy, 6*mult) --left
	
	love.graphics.setColor(alpha)
	
	love.graphics.setLineWidth(2*mult)
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
