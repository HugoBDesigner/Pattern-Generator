local selector = {
					sizes = {},
					spacing = 0,
					animspeed = 0,
					animmaxspeed = 0,
					dir = 0,
					imgs = {},
					selection= 1,
					maxsel = 1,
					angle = 0,
					lockedscroll = true,
					color = {255, 255, 255, 255}
				}

function selector.load(sizes, spacing, imgs, anim, sel, maxsel, angle)
	selector.sizes = sizes
	selector.spacing = spacing
	selector.imgs = imgs
	selector.animmaxspeed = anim or 1
	selector.selection = sel or 1
	selector.maxsel = maxsel or 1
	selector.angle = angle or 0
end

function selector.update(dt)
	if selector.dir ~= 0 then
		if selector.animspeed == 0 then selector.animspeed = selector.animmaxspeed end
		
		selector.animspeed = math.max(selector.animspeed - dt, 0)
		
		if selector.animspeed == 0 then
			selector.dir = 0
		end
	end
end

function selector.select(i)
	if (i ~= 1 and i ~= -1) or (selector.lockedscroll and selector.dir ~= 0) then
		i = 0
	end
	if i ~= 0 then
		selector.dir = i
	end
	
	selector.selection = selector.selection + i
	while selector.selection < 1 do
		selector.selection = selector.selection + selector.maxsel
	end
	while selector.selection > selector.maxsel do
		selector.selection = selector.selection - selector.maxsel
	end
	
	return selector.selection
end

function selector.draw(cX, cY, f1, f2)
	local xfact, yfact = math.cos(selector.angle), math.sin(selector.angle)
	local pS = selector
	local animfactor = pS.animspeed/pS.animmaxspeed --From 1 to 0
	
	local y = 0
	local x = 0
	for i = 1, 4 do
		for d = 0, 1 do
			local dir = d*2-1
			local psdir = pS.dir
			if pS.dir == 0 then psdir = 1 end
			if not (i == 1 and dir == -1) then
				local w = pS.sizes[ math.min(i, #pS.sizes) ][1]
				local h = pS.sizes[ math.min(i, #pS.sizes) ][2]
				
				w = w + math.abs(w - pS.sizes[ math.max(math.min(i+dir, #pS.sizes), 1) ][1])*animfactor*(-dir)
				h = h + math.abs(h - pS.sizes[ math.max(math.min(i+dir, #pS.sizes), 1) ][2])*animfactor*(-dir)
				
				local dist = i+d-1
				if dist > #pS.sizes then dist = #pS.sizes
				elseif dist < 1 then dist = 1 end
				
				local s1, s2 = (i-1)*dir, (i-1)*dir + 1
				
				dist = pS.sizes[ dist ][2]/2 + pS.spacing + pS.sizes[ math.min(#pS.sizes, dist+1) ][2]/2
				
				local sel = pS.selection+(i-1)*dir*psdir
				while sel > pS.maxsel do
					sel = sel - pS.maxsel
				end
				while sel < 1 do
					sel = sel + pS.maxsel
				end
				
				if f2 then
					f2(cX + (x*dir*psdir + pS.spacing/2 + dist*animfactor*psdir)*xfact - w/2, cY + (y*dir*psdir + pS.spacing/2 + dist*animfactor*psdir)*yfact - h/2, w, h, sel, i)
				end
				
				love.graphics.setColor(pS.color)
				if pS.imgs then
					love.graphics.draw(pS.imgs[sel], cX + (x*dir*psdir + pS.spacing/2 + dist*animfactor*psdir)*xfact - w/2, cY + (y*dir*psdir + pS.spacing/2 + dist*animfactor*psdir)*yfact - h/2, 0, w/pS.sizes[1][1], h/pS.sizes[1][2])
				end
				
				if f1 then
					f1(cX + (x*dir*psdir + pS.spacing/2 + dist*animfactor*psdir)*xfact - w/2, cY + (y*dir*psdir + pS.spacing/2 + dist*animfactor*psdir)*yfact - h/2, w, h, sel, i)
				end
			end
		end
		y = y + pS.sizes[ math.min(#pS.sizes, i) ][2]/2 + pS.spacing + pS.sizes[ math.min(#pS.sizes, i+1) ][2]/2
		x = x + pS.sizes[ math.min(#pS.sizes, i) ][1]/2 + pS.spacing + pS.sizes[ math.min(#pS.sizes, i+1) ][1]/2
	end
end

return selector