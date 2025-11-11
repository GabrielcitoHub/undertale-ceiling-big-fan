return function() local self = {}
    self.dialogue = require "objects.dialogue" ()
    self.menu = 1
    self.namemenu = 3
    self.name = ""
    self.real = love.math.random(0,6)
    self.inputletters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    self.letters = {}
    self.position = {1,1}
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
    self.grid = createLettersGrid(self.inputletters)
    self.timer = 0
    PLAYSOUND "mus_intronoise.ogg"
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
            self.menu = self.menu + 1
        else
            self.name = self.name .. button
        end
    end

    local function checkName()
        local name = string.lower(self.name)
        if name == "gaster" then
            -- nuh uh
            RELOAD()
        end
    end
   
    function self:update(dt)
        self.timer = self.timer + 1 * dt
        local maxY = #self.grid                     -- total rows
        local maxX = #self.grid[self.position[2]]   -- total columns for current row
        if ISPRESSED "LEFT" then
            if self.menu ~= self.namemenu then return end
            if self.position[1] > 1 then
                self.position[1] = self.position[1] - 1
            end
        end

        if ISPRESSED "RIGHT" then
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
                if self.timer > 0.1 then
                    buttonCode()
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
            love.graphics.setColor(1,1,1)
            love.graphics.printf(self.name,x+220,y+70,640/4,"left",0,1,1)
            checkName()
        end
    end
    function self:debugdraw()
        love.graphics.setFont(FONT "fnt_default")
        love.graphics.setColor(1,1,1)
		love.graphics.print("Menu "..self.menu.."\nReal: "..self.real.."\nTimer: "..self.timer.."\nPosition: "..self.position[1]..","..self.position[2].."\nName: "..self.name)
	end
return self end