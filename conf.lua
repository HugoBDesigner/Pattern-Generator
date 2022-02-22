function love.conf(t)
	t.identity = "PatternGen2"
	t.author = "HugoBDesigner"
	t.console = true
	if love.filesystem.getInfo("console.txt") and love.filesystem.read("console.txt") == "true" then
		t.console = true
	end
	
	t.version = "11.3.0"
end
