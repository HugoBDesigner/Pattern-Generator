function love.conf(t)
	t.identity = "PatternGen"
	t.author = "HugoBDesigner"
	t.console = false
	if love.filesystem.exists("console.txt") and love.filesystem.read("console.txt") == "true" then
		t.console = true
	end
	
	t.version = "0.10.1"
end