local animations = {
    require 'pixel.animations.lines',
    require 'pixel.animations.fire',
    require 'pixel.animations.sine',
    require 'pixel.animations.random',
}

local frames_per_cycle = 150
local index = 1
local counter = frames_per_cycle
return function()
    counter = counter - 1
    if counter == 0 then
        counter = frames_per_cycle
        index = index + 1
        if index > #animations then
            index = 1
        end
    end
    animations[index]()
end
