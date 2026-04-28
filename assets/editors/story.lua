return
---@param sound love.Source
function(sound) local self = {}
    self.dragging = false
    self.wasPlaying = false
    self.sound = sound or MUSIC "story.ogg"
    self.scene = require("assets.scenes.story") ()
    local scene = self.scene
    scene.ignoreinput = true
    scene.sound = self.sound

    self.line = {
        x = 0,
        y = 480,
        w = 640,
        h = 2,
        offset = 20,
        playback = {
            image = IMAGE "attack_default",
            playing = false
        },
    }

    -- get total duration once
    self.duration = self.sound:getDuration("seconds")

    function self:update(dt)
        if self.line.playback.playing then
            self.scene:update(dt)
        end

        if ISPRESSED("EXIT") and DEBUG then
            RELOAD()
        end
    end

    function self:drawStoryPreviews()
        local line = self.line
        local entries = self.scene.timeline   -- your story entries table

        if not entries then return end

        local barX = line.x + line.offset
        local barY = line.y - line.offset
        local barW = line.w - line.offset * 2

        for _, entry in ipairs(entries) do
            -- entry.time normalized to 0..1
            local t = math.min(1, entry.time / self.duration)
            local px = barX + t * barW
            local targetH = 30
            local img,scale,imgx,imgy

            ------------------------------------------------------------
            -- DRAW MINI IMAGE
            ------------------------------------------------------------
            if entry.image then
                -- your images come as strings, so load if needed
                img = entry._cachedImage
                if not img then
                    img = IMAGE("story/spr_"..entry.image)
                    entry._cachedImage = img
                end

                -- scale down to a fixed miniature size
                scale = targetH / img:getHeight()
                imgx,imgy = px - ((img:getWidth()*scale)/2)+self.line.offset, barY - 40

                love.graphics.draw(
                    img,
                    imgx,
                    imgy,
                    0,
                    scale, scale
                )
            end

            ------------------------------------------------------------
            -- DRAW MINI TEXT
            ------------------------------------------------------------
            if entry.text then
                local tx,ty = px-40,barY-10
                if img and scale then
                    tx,ty = imgx,imgy
                end

                -- ts = 0.2
                --love.graphics.print(entry.text, tx, ty, 0, ts, ts)
            end
        end
    end

    function self:draw()
        self.scene:draw()
        local line = self.line
        local playback = line.playback

        if playback.playing then
            love.graphics.setColor(1,1,1,0.12)
        else
            love.graphics.setColor(1,1,1,1)
        end

        local barW = line.w - line.offset * 2

        -- background bar
        love.graphics.rectangle(
            "fill",
            line.x + line.offset,
            line.y - line.offset,
            barW,
            line.h
        )

        -- current sound time
        local current = self.sound:tell("seconds")

        -- clamp
        if current > self.duration then current = self.duration end

        -- normalized 0..1
        local t = 0
        if self.duration > 0 then
            t = current / self.duration
        end

        -- x position of playback marker
        local px = line.x + line.offset + t * barW

        -- draw marker image
        love.graphics.draw(playback.image, px - playback.image:getWidth()/2, line.y - self.line.offset - playback.image:getHeight()/2)
        self:drawStoryPreviews()
        love.graphics.setColor(1,1,1,1)
    end

    function self:updateplayback(playing,stop)
        stop = stop or false
        if playing then
            self.sound:play()
        else
            if not stop then
                self.sound:pause()
            else
                self.sound:stop()
                self:updatetimeline(true)
            end
        end
    end

    function self:updatetimeline(restart)
        if restart == true then
            self.scene.activeIndex = 0
        end

        for i,entry in ipairs(self.scene.timeline) do
            if self.sound:tell("seconds") > entry.time then
                self.scene.activeIndex = i
                break
            end
        end
    end

    function self:keypressed(key)
        local line = self.line
        local playback = line.playback
        if key == "space" or key == "return" then
            playback.playing = not playback.playing
            self:updateplayback(playback.playing)
        elseif key == "backspace" then
            playback.playing = false
            playback.time = 0
            self:updateplayback(playback.playing,true)
        end
    end

    function self:mousepressed(mx, my, button)
        mx,my = MOUSEX(),MOUSEY()
        if button ~= 1 then return end

        local line = self.line
        local barX = line.x + line.offset
        local barY = line.y - line.offset
        local barW = line.w - line.offset * 2
        local barH = line.h + 20 -- click tolerance

        -- Check if clicked inside bar
        if mx >= barX and mx <= barX + barW and
        my >= barY - 10 and my <= barY + barH then

            -- Start dragging
            self.dragging = true
            self.wasPlaying = self.line.playback.playing

            -- Pause while dragging
            self.sound:pause()

            -- Seek immediately on click
            local t = (mx - barX) / barW
            t = math.max(0, math.min(1, t))
            self.sound:seek(t * self.duration, "seconds")
        end
    end

    function self:mousereleased(mx, my, button)
        if button ~= 1 then return end
        if self.dragging then
            self.dragging = false

            -- Return to previous state
            if self.wasPlaying then
                self.sound:play()
            end
        end
    end

    function self:mousemoved(mx, my, dx, dy)
        mx = MOUSEX()
        if not self.dragging then return end

        local line = self.line
        local barX = line.x + line.offset
        local barW = line.w - line.offset * 2

        local t = (mx - barX) / barW
        t = math.max(0, math.min(1, t))

        self.sound:seek(t * self.duration, "seconds")

        if t == 0 then
            self:updatetimeline(true)
        end

        self:updatetimeline()
    end
return self end