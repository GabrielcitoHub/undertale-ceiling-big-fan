return function(savedata) local self = {}
    savedata = savedata or {}
    self.dialogue = require "objects.dialogue" ()
    self.timer = 0
    self.fadein = false
    self.fadeintimer = 0
    self.menu = 1
    self.namemenu = 3
    self.name = ""
    self.real = savedata.real or 0
    self.inputletters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    self.letters = {}
    self.position = {1,1}
    self.confirm = {
        position = 1,
        text = "Is this name correct?",
        options = {"No","Yes"},
        enabled = true,
        sound = SOUND "mus_cymbal.ogg"
    }
    local function createLettersGrid(inputletters)
        local grid = {}
        local columns = 7
        local cellSizeX = 80
        local cellSizeY = 30
        local startX = 80
        local startY = 150

        local x, y = 1, 1

        for ii = 1, 2 do
            local yOffset = (ii - 1) * 20
            for i = 1, #inputletters do
                local char = inputletters:sub(i, i)
                if ii == 2 then
                    char = char:lower()
                end

                local charData = {
                    char = char,
                    x = startX + (x - 1) * cellSizeX,
                    y = startY + (y - 1) * cellSizeY + yOffset
                }

                -- make sure grid[y] exists
                grid[y] = grid[y] or {}
                grid[y][x] = charData

                -- advance grid position
                x = x + 1
                if x > columns then
                    x = 1
                    y = y + 1
                end
            end

            -- reset x/y for next layer (lowercase)
            x = 1
            y = y + 1
        end
        local specialButtons = {
            {char = "Quit",x = 120},
            {char = "Backspace",x = 240},
            {char = "Done",x = 460}
        }
        for i, button in ipairs(specialButtons) do
            grid[y] = grid[y] or {}
            grid[y][i] = {
                char = button.char,
                x = button.x,
                y = startY + (y - 1) * cellSizeY + 40
            }
        end
        return grid
    end
    local function showGrid(grid)
        for i = 1,#grid do
            for j = 1,#grid[i] do
                local charData = grid[i][j]
                if charData then
                    if self.position[2] == i and self.position[1] == j then
                        love.graphics.setColor(1,1,0)
                    else
                        love.graphics.setColor(1,1,1)
                    end
                    self.dialogue:print(charData.char, charData.x, charData.y)
                end
            end
        end
    end
    local function showConfirmOptions(confirmoptions)
        local offset = 60
        for i,opt in ipairs(confirmoptions) do
            local x = offset
            local y = 480 - offset
            if i == 2 then
                if not self.confirm.enabled then break end
                x = 640 - offset
            else
                x = offset * i
            end
            if self.confirm.position == i then
                love.graphics.setColor(1,1,0)
            else
                love.graphics.setColor(1,1,1)
            end
            self.dialogue:print(opt, x, y)
        end
    end
    self.grid = createLettersGrid(self.inputletters)
    local function getMusic(num)
        return MUSIC("menu" .. tostring(num) .. ".ogg")
    end
    self.music = getMusic(self.real)
    local function checkButton(pos)
        local row = self.grid[pos[2]]
        if row then
            local button = row[pos[1]]
            if button then
                return button.char
            end
        end
        return nil
    end

    local function buttonCode()
        local button = checkButton(self.position)
        if button == "Quit" then
            self.menu = self.menu - 1
            self.timer = 0
        elseif button == "Backspace" then
            self.name = string.sub(self.name,1,-2)
        elseif button == "Done" then
            self:updateConfirmText()
            self.menu = self.menu + 1
            self.timer = 0
        else
            self.name = self.name .. button
        end
    end
    function self:onConfirmButton(id,name) end

    local function confirmButtonCode()
        local button = self.confirm.options[self.confirm.position]
        if button == "Yes" then
            self.music:stop()
            self.fadein = true
            self.confirm.sound:play()
        elseif button == "No" then
            self.menu = self.menu - 1
        else
            self:onConfirmButton(self.confirm.position,button)
        end
    end

    function self:onGasterReset(name)
    end

    local function checkName()
        local name = string.lower(self.name)
        if name == "gaster" then
            -- nuh uh
            self:onGasterReset(name)
            RELOAD()
        end
    end

    function self:updateConfirmMenu()
        if not self.confirm.enabled then self.confirm.position = 1 return end
        if self.confirm.position < 1 then
            self.confirm.position = #self.confirm.options
        elseif self.confirm.position > #self.confirm.options then
            self.confirm.position = 1
        end
    end

    function self:funnyTexts(t)
        t["fr"] = "for real."
    end

    function self:updateConfirmText()
        local name = string.lower(self.name)
        local special = {
            chara = "The true name.",
            frisk = "Warning!\nThis will make your life a living\nhell.\nDo you wish to continue?",
            toriel = {"You may want to choose\nyour own name my child.",false}
        }
        self:funnyTexts(special)
        local gotname = special[name] or "Is this name correct?"
        if type(gotname) == "table" then
            self.confirm.enabled = gotname[2]
            gotname = gotname[1]
        else
            self.confirm.enabled = true
        end
        self.confirm.text = gotname
    end

    function self:onConfirm(name)
        RELOAD()
    end

    function self:load()
        PLAYSOUND "mus_intronoise.ogg"
    end
   
    function self:update(dt)
        self.timer = self.timer + 1 * dt
        if self.fadein then
            self.fadeintimer = self.fadeintimer + dt

            local length = self.confirm.sound:getDuration()

            if self.fadeintimer > length then
                self:onConfirm(self.name)
            end

            return
        end
        local maxY = #self.grid                     -- total rows
        local maxX = #self.grid[self.position[2]]   -- total columns for current row
        if ISPRESSED "LEFT" then
            if self.menu == 4 then
                self.confirm.position = self.confirm.position - 1
                self:updateConfirmMenu()
            end
            if self.menu ~= self.namemenu then return end
            if self.position[1] > 1 then
                self.position[1] = self.position[1] - 1
            end
        end

        if ISPRESSED "RIGHT" then
            if self.menu == 4 then
                self.confirm.position = self.confirm.position + 1
                self:updateConfirmMenu()
            end
            if self.menu ~= self.namemenu then return end
            if self.position[1] < maxX then
                self.position[1] = self.position[1] + 1
            end
        end

        if ISPRESSED "UP" then
            if self.menu ~= self.namemenu then return end
            if self.position[2] > 1 and checkButton({self.position[1],self.position[2]-1}) ~= nil then
                self.position[2] = self.position[2] - 1
            end
        end

        if ISPRESSED "DOWN" then
            if self.menu ~= self.namemenu then return end
            if self.position[2] < maxY and checkButton({self.position[1],self.position[2]+1}) ~= nil then
                self.position[2] = self.position[2] + 1
            end
        end
        if ISPRESSED "SELECT" then
            if self.menu == 1 then
                self.music:play()
                self.music:setLooping(true)
            end
            if self.menu < self.namemenu then
                self.menu = self.menu + 1
                self.timer = 0
            end
            if self.menu == self.namemenu then
                if self.timer > 0.02 then
                    buttonCode()
                end
            end
            if self.menu == 4 then
                if self.timer > 0.02 then
                    confirmButtonCode()
                end
            end
        end
        if ISPRESSED "CANCEL" then
            if DEBUG and self.menu < self.namemenu then
                RELOAD()
            end
            if self.menu == self.namemenu then
                self.name = string.sub(self.name,1,-2)
            else
                if self.menu > 2 then
                    self.menu = self.menu - 1
                    self.timer = 0
                end
            end
        end
    end
    function self:drawName(x,y,r,sx,sy)
        r = r or 0
        sx = sx or 1
        sy = sy or 1
        love.graphics.setColor(1,1,1)
        local limit = 640/4
        love.graphics.printf(self.name,x+220,y+70,limit,"justify",r,sx,sy)
        local startLow = 120
        local i = 1
        while string.len(self.name) > startLow do
            startLow = startLow + 120
            if i > 1 then
                startLow = startLow + 30
            end
            if i == 1 then
                startLow = 121
            end
            local cutName = string.sub(self.name,startLow+1)
            local cutX = 220-(10*i)
            local cutY = 0
            if cutX < 0 then
                cutX = 640-(10*(i-1))
            end
            love.graphics.printf(cutName,x+cutX,cutY,limit,"justify",r,sx,sy)
            i = i + 1
        end
    end
    function self:draw()
        if self.menu == 1 then
            love.graphics.setColor(1,1,1)
            love.graphics.draw(IMAGE "title", 0, 0, 0, 2, 2)
            if self.timer > 4 then
                love.graphics.setColor(0.5,0.5,0.5)
                local altSecond = GETKEY("SELECT",1)
                if altSecond then
                    love.graphics.printf("[PRESS " .. string.upper(GETKEY "SELECT") .. " OR " .. string.upper(altSecond) .. "]", 0, 400, 640, "center")
                else
                    love.graphics.printf("[PRESS " .. string.upper(GETKEY "SELECT") .."]", 0, 400, 640, "center")
                end
            end
        elseif self.menu == 2 then
            local gray = 0.8
            love.graphics.setColor(gray,gray,gray)
            local instructionStrings = {}
            local altKeySelect = GETKEY("SELECT",1)
            local altKeyCancel = GETKEY("CANCEL",1)
            local altKeyMenu = GETKEY("MENU",1)
            if altKeySelect then
                table.insert(instructionStrings,"[" .. string.upper(GETKEY "SELECT") .. "] or [" .. string.upper(altKeySelect) .. "] - Confirm\n")
            else
                table.insert(instructionStrings,"[" .. string.upper(GETKEY "SELECT") .. "] - Confirm\n")
            end
            if altKeyCancel then
                table.insert(instructionStrings,"[" .. string.upper(GETKEY "CANCEL") .. "] or [" .. string.upper(altKeyCancel) .. "] - Cancel\n")
            else
                table.insert(instructionStrings,"[" .. string.upper(GETKEY "CANCEL") .. "] - Cancel\n")
            end
            if altKeyMenu then
                table.insert(instructionStrings,"[" .. string.upper(GETKEY "MENU") .. "] or [" .. string.upper(altKeyMenu) .. "] - Menu (In-game)\n")
            else
                table.insert(instructionStrings,"[" .. string.upper(GETKEY "MENU") .. "] - Menu (In-game)\n")
            end
            table.insert(instructionStrings,"[" .. string.upper(GETKEY "EXTRA2") .. "] - Fullscreen\n")
            table.insert(instructionStrings,"[Hold " .. string.upper(GETKEY "EXIT") .."] - Quit\n")
            table.insert(instructionStrings,"When HP is 0, you lose.")
            love.graphics.setFont(FONT "fnt_default")
            local x,y = 60,20
            self.dialogue:print("--- Instruction ---\n",x+10,y)
            self.dialogue:print(table.concat(instructionStrings),x,y+40)
            --love.graphics.printf(table.concat(instructionStrings),x,y+40,640,"left",0,2,2)
            love.graphics.setColor(1,1,0)
            self.dialogue:print("Begin Game",x,y+250)
        elseif self.menu == self.namemenu then
            local x,y = 60,20
            love.graphics.setColor(1,1,1)
            self.dialogue:print("Name the fallen human.",x+110,y+40)
            showGrid(self.grid)
            local r = love.math.random(-100, 100) / 4000
            self:drawName(x,y,r)
            checkName()
        elseif self.menu == 4 then
            local t = 1 - math.exp(-self.timer * 3)

            local x_start = 60
            local x_end   = -3
            local x = x_start + (x_end - x_start) * t

            local y_start = 20
            local y_end   = 140
            local y = y_start + (y_end - y_start) * t

            local r = love.math.random(-100, 100) / 3500
            local s = 1 + 2 * (1 - math.exp(-self.timer * 3))
            love.graphics.setColor(1,1,1)
            self.dialogue:print(self.confirm.text,x+110,y-80)
            self:drawName(x,y,r,s,s)
            showConfirmOptions(self.confirm.options)
        end
        if self.fadein then
            local length = self.confirm.sound:getDuration() -- in seconds
            love.graphics.setColor(1, 1, 1, self.fadeintimer/length)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            love.graphics.setColor(1, 1, 1, 1) -- reset
        end
    end
    function self:debugdraw()
        love.graphics.setFont(FONT "fnt_default")
        love.graphics.setColor(1,1,1)
		love.graphics.print("Menu "..self.menu.."\nReal: "..self.real.."\nTimer: "..self.timer.."\nPosition: "..self.position[1]..","..self.position[2].."\nName: "..self.name.."\nNameLen: "..string.len(self.name).."\nConfirm = {".."Position: "..self.confirm.position..", Text: "..self.confirm.text..", Options: "..#self.confirm.options..", Enabled: "..tostring(self.confirm.enabled).."}")
	end
return self end