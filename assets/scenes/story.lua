return function()
    local self = {}

    -- Dialogue object (same as before)
    self.dialogue = require "objects.dialogue" (nil, "fnt_default_big", 52, 322, nil)
    self.scale = 2

    -- Story music
    self.sound = MUSIC("story.ogg")
    self.sound:play()

    -------------------------------------------------------------
    -- TIMELINE (Option A)
    -------------------------------------------------------------
    self.timeline = {
        { time = 0, text = "  Once upon a time\n  humans and monster lived\n  peacefully", image = "introimage_0" },
        { time = 6, text = "  But then war", image = "introimage_1" },
        { time = 13, text = "  Humans were victorious", image = "introimage_2" },
        { time = 18, text = "  And they casted a spell that would\n  take 7 human souls to\n  dispell", image = "introimage_3" },
        { time = 22, text = "  Forever dooming the monsters\n  in the underground", image = "introimage_4" },
        { time = 26, text = "  Mettaton Ebott\n  20XX", image = "introimage_5" },
        { time = 33, text = "  Legends say that those who climb\n  the mountain", image = "introimage_5" },
        { time = 40, text = "  ...Never return", image = "introimage_6" },
        { time = 47, text = "", image = "introimage_7" },
        { time = 54, text = "", image = "introimage_8" },
        { time = 59, text = "", image = "introimage_9" },
        { time = 66, text = "", image = "introimage_10" }
    }

    -------------------------------------------------------------
    -- FADING IMAGE CONTROLS (cross-fade)
    -------------------------------------------------------------
    self.currentImage = nil
    self.currentAlpha = 0

    self.prevImage = nil
    self.prevAlpha = 0

    self.fadeSpeed = 2.5
    self.activeIndex = 0

    -------------------------------------------------------------
    -- triggerEntry (uses your IMAGE function)
    -------------------------------------------------------------
    function self:triggerEntry(entry)
        -- Set text
        self.dialogue:settext(entry.text)

        -- Move current → prev for fading out
        if self.currentImage then
            self.prevImage = self.currentImage
            self.prevAlpha = self.currentAlpha
        else
            self.prevImage = nil
            self.prevAlpha = 0
        end

        -- Load new image with your custom IMAGE() loader
        if entry.image then
            self.currentImage = IMAGE("story/spr_" .. entry.image)
        else
            self.currentImage = nil
        end

        -- new entry starts faded-in from 0
        self.currentAlpha = 0
    end

    function self:onStoryEnd(skipped)
        self.sound:stop()
        local scene = require("assets.scenes.intro") ()
        SETSCENE(scene)
    end

    function self:update(dt)
        if ISPRESSED "SELECT" then
            self:onStoryEnd(true)
            return
        end
        self.dialogue:update()

        local t = self.sound:tell("seconds")

        -- Trigger timeline entries when sound passes their timestamp
        while true do
            local nextEntry = self.timeline[self.activeIndex + 1]
            if not nextEntry then break end

            if t >= nextEntry.time then
                self.activeIndex = self.activeIndex + 1
                self:triggerEntry(nextEntry)
            else
                break
            end
        end

        -- Fade IN new image
        if self.currentImage and self.currentAlpha < 1 then
            self.currentAlpha = math.min(1, self.currentAlpha + dt * self.fadeSpeed)
        end

        -- Fade OUT old image
        if self.prevImage and self.prevAlpha > 0 then
            self.prevAlpha = math.max(0, self.prevAlpha - dt * self.fadeSpeed)
            if self.prevAlpha == 0 then
                self.prevImage = nil
            end
        end

        -- Auto-end when music ends
        local len = self.sound:getDuration()
        if t >= len - 0.05 then
            self:onStoryEnd(false)
            return
        end
    end

    function self:draw()
        -- Old image fading OUT under everything
        if self.prevImage and self.prevAlpha > 0 then
            love.graphics.setColor(1, 1, 1, self.prevAlpha)
            love.graphics.draw(self.prevImage,0,0,0,self.scale,self.scale)
        end

        -- New image fading IN
        if self.currentImage and self.currentAlpha > 0 then
            love.graphics.setColor(1, 1, 1, self.currentAlpha)
            love.graphics.draw(self.currentImage,0,0,0,self.scale,self.scale)
        end

        love.graphics.setColor(1,1,1,1)
        self.dialogue:draw()
    end

    return self
end