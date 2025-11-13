local Soul = require "objects.soul"
local soul = Soul()
local scripts
local files
local option = 1
local debugoptions = 0
local minoption = 1
local translatey = 0
local brightnesstimer = 0
local updater = require "objects.updater" ()
local function loadDebugFilesFromPath(path)
    local items = love.filesystem.getDirectoryItems(path)
    for _,item in pairs(items) do
        local fullpath = path.."/"..item
        if love.filesystem.getInfo(fullpath, "directory") then
            loadDebugFilesFromPath(fullpath)
        elseif item:sub(-4) == ".lua" then
            local requirepath = fullpath:gsub("/", "."):sub(1, -5)
            scripts[#scripts+1] = "*"..requirepath
            debugoptions = debugoptions + 1
        end
    end
end
-- Function to list and load mods from a given path
local function loadModsFromPath(files, modsPath)
    local command

    if PLATFORM == "Windows" then
        command = 'dir "' .. modsPath .. '" /b /ad'
    else
        command = 'ls -1 "' .. modsPath .. '"'
    end

    local p = io.popen(command)
    if p then
        for entry in p:lines() do
            table.insert(files, entry)
        end
        p:close()
    else
        print("Could not open mods directory: ", modsPath)
    end
end
local function reloadFiles()
    CLEARCACHE()
    scripts = {}
    loadDebugFilesFromPath("assets/scenes")
    loadDebugFilesFromPath("assets/scripts")
    debugoptions = #scripts
    files = love.filesystem.getDirectoryItems("mods")
    local basePath = love.filesystem.getSourceBaseDirectory() .. "/mods/"
    --loadModsFromPath(files, basePath)
    for index, value in ipairs(files) do
        scripts[#scripts+1] = value
    end
    if option > #scripts then
        option = #scripts
    end
    if option < minoption then
        option = minoption
    end
end
local function showBoldText(text, x, y)
    love.graphics.print(text, x, y)
    love.graphics.print(text, x + 6, y)
    love.graphics.print(text, x + 3, y - 3)
    love.graphics.print(text, x + 3, y + 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, x + 3, y)
end
reloadFiles()
if not DEBUG then
    option = 1 + debugoptions
else
    option = 1
end
if #files == 0 then
	option = 2
end
SETSCENE({
    focus = reloadFiles,
    update = function(self)
        soul.x = 32
        soul.y = option * 30 - 4
        if DEBUG then
            minoption = 1
        else
            minoption = 1 + debugoptions
        end
        if option < minoption then
            option = minoption
        end
        translatey = translatey + ((option * -30 + 275 + 30) - translatey) / 10
        if brightnesstimer < 50 then
            brightnesstimer = brightnesstimer + 2
        end
        if ISPRESSED "MENU" and not love.keyboard.isDown("lctrl") then
            PLAYSOUND "snd_select.wav"
            if love.system.getOS() == "Windows" then
                os.execute('start "" "'..love.filesystem.getSaveDirectory().."/mods"..'"')
            else
                os.execute('xdg-open "'..love.filesystem.getSaveDirectory().."/mods"..'"')
            end
        end
        if #scripts - minoption + 1 == 0 then
            return
        end
        local oldimg = ABSIMAGE("mods/"..scripts[option].."/preview")
        if ISPRESSED "DOWN" then
            PLAYSOUND "snd_squeak.wav"
            option = option + 1
            if option > #scripts then
                option = minoption
            end
        end
        if ISPRESSED "UP" then
            PLAYSOUND "snd_squeak.wav"
            option = option - 1
            if option < minoption then
                option = #scripts
            end
        end
        if ISPRESSED "SELECT" then
            love.graphics.clear(0, 0, 0)
            love.graphics.setFont(FONT "fnt_karma_big")
            love.graphics.print("Loading...", 5, love.graphics:getHeight() - 20)
            love.graphics.present()
            if option <= debugoptions then
                local scene
                local optionName = scripts[option]
                print(optionName)
                if optionName:sub(1,1) == "*" then
                    optionName = optionName:sub(2)
                    print(optionName)
                end
                if optionName:sub(1,13) == "assets.scenes" then
                    scene = require(optionName) ()
                elseif optionName:sub(1,14) == "assets.scripts" then
                    scene = require("assets.scenes.battle") ()
                    require(optionName) (scene)
                end
                SETSCENE(scene)
            else
				RELOAD("mods/"..scripts[option])
            end
        end
        local newimg = ABSIMAGE("mods/"..scripts[option].."/preview")
        if newimg ~= oldimg then
            brightnesstimer = 0
        end
    end,
    draw = function(self)
        love.graphics.setColor(brightnesstimer/100, brightnesstimer/100, brightnesstimer/100)
        local previewimage
        if scripts[option] then
            previewimage = ABSIMAGE("mods/"..scripts[option].."/preview")
        end
        if previewimage then
            love.graphics.draw(previewimage, 320 - previewimage:getWidth()/2, 240 - previewimage:getHeight()/2)
        else
            love.graphics.draw(IMAGE "boss_battle_bg", 15, 45)
            love.graphics.draw(IMAGE "dummy", 280, 177, 0, 2, 2)
        end
        love.graphics.setFont(FONT "fnt_default_big")
        love.graphics.translate(0, translatey)
        local listempty = true
        for index = minoption, #scripts do
            listempty = false
            local value = scripts[index]
            local opacity = 1
            if index < option then
                opacity = 1 - math.abs(index - option) / 11
            else
                opacity = 1 - math.abs(index - option) / 6
            end
            if opacity <= 0.1 then
                opacity = 0.1
            end
            if opacity > 0 then
                love.graphics.setColor(0, 0, 0)
                love.graphics.print(value, 62, -20 + index * 30)
                love.graphics.print(value, 58, -20 + index * 30)
                love.graphics.print(value, 60, -18 + index * 30)
                love.graphics.print(value, 60, -22 + index * 30)
            end
            if index == option then
                love.graphics.setColor(1, 0, 0)
                soul:draw()
                love.graphics.setColor(1, 1, 0)
            else
                love.graphics.setColor(1, 1, 1, opacity)
            end
            love.graphics.print(value, 60, -20 + index * 30)
        end
        if listempty then
            love.graphics.setColor(1, 1, 1, 0.3)
            love.graphics.print("- No mods installed -\n- Press " .. string.upper(GETKEY "MENU") .. " to open folder -", 60, 120)
            option = 2
        end
        love.graphics.translate(0, -translatey)
        love.graphics.setFont(FONT "fnt_karma_big")
        love.graphics.setColor(0, 0, 0)
        showBoldText("Select a mod:", 7, 10)
		if not DEBUG then
			love.graphics.setColor(1, 1, 1, 0.5)
			love.graphics.setFont(FONT "fnt_default")
			love.graphics.print("Press " .. string.upper(GETKEY "EXTRA1") .. " to toggle DEBUG MODE", 4, 464)
			love.graphics.print("Press " .. string.upper(GETKEY "MENU") .. " to open mods folder", 420, 464)
		end
    end,
    debugdraw = function(self)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(FONT "fnt_default")
        love.graphics.print("DEBUG MODE", 0, 464)
        love.graphics.print("Option: "..option, 200, 464)
        love.graphics.print("Translate Y: "..string.format("%f", translatey), 400, 464)
        updater:draw()
    end
})