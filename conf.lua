function love.conf(t)
    t.console = false
    t.modules.joystick = false
    t.modules.physics = false
    t.window.title = "short story organizer, for organizing short stories" 
    t.window.icon = "gfx/character.png"
    t.identity = "short-story-organizer" 
    t.window.msaa = 4
    t.window.borderless = false

    t.window.width = 1024
    t.window.height = 450
end