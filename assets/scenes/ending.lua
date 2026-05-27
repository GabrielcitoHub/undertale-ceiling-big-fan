return function(endingtext,intro) local self = {}
    local offset_y = 40
    self.dialogue = require "objects.dialogue" (nil, "fnt_default_big", 52, 272 + offset_y, "SND_TXT1.wav")
    self.dialoguebox = require "objects.dialoguebox" (32, 250 + offset_y, 576, 140)
    self.queue = require "objects.queue" ()
    self.dialoguetext = {}

    function self:nextdialogue()
        local text = table.remove(self.dialoguetext, 1)
        print(text)

        if text == "" or text == nil then
            self.dialoguebox.hidden = true
        else
            self.dialoguebox.hidden = false
        end

        -- Set first table value to the dialogue current text
        local dialogue = text
        if type(text) == "table" then
            dialogue = text[1]
        end
        
        if dialogue then self.dialogue:settext(dialogue) end

        -- Run the second table balue function and give self as the first parameter
        if type(text) == "table" then
            local func = text[2]
            text = text[1]
            if func then func(self) end
        end
    end

    function self:endturn(dialogue)
        self.dialogue:settext("")
        self.dialoguetext = {unpack(dialogue or {})}
        self:nextdialogue()
    end

    function self:onupdate(dt) end

    function self:update(dt)
        self.dialogue:update(dt)
        self.queue:update(dt)

        if ISPRESSED "CANCEL" then
            if DEBUG and self.dialogue.text == self.dialogue.targettext then
                RELOAD()
            end
        end
            
        if ISPRESSED "SELECT" and self.dialogue.text == self.dialogue.targettext then
            self:nextdialogue()
        end

        self:onupdate(dt)
    end

    function self:draw()
        self.dialoguebox:draw()
        self.dialogue:draw()
    end

    function self:addDialogue(dialogue, text, potrait)
        local dialoguetext = {text, function() self.dialogue:setpotrait(potrait) end}
        table.insert(dialogue,dialoguetext)
    end

    local dialogue = endingtext or {}
    if intro == true then
        table.insert(dialogue,"* (Ring Ring...)")
        table.insert(dialogue,{"* Hello? is anyone there?",function() self.dialogue:setspeaker("sans") end})
        self:addDialogue(dialogue,"* Welp, i guess i'll leave a\n  message","chuckle")
        table.insert(dialogue,{"",function() MUSIC("z_ending.ogg"):play() MUSIC("z_ending.ogg"):setLooping(true) end})
    end
    
    if not endingtext then
        if love.math.random(1,100) == 1 then
            table.insert(dialogue, "* Thanks for playing my little Undertale fan game!")
            table.insert(dialogue, "* Made with Love2D and a lot of coffee :D")
            table.insert(dialogue, "* See you next time!")
            table.insert(dialogue, "(No coffe was harmed on the production of this software\n  i hate coffe)")
        else
            table.insert(dialogue, {"* This is an ending scene\n  test text",function() self.dialogue:setspeaker("sans") self.dialogue:setpotrait("wink") end})
            table.insert(dialogue, {"* You can use this to make\n  other endings",function() self.dialogue:setpotrait("chuckle") end})
            table.insert(dialogue, {"* ererer er",function() self.dialogue:setpotrait("chuckle2") end})
            table.insert(dialogue, {"* look at this shiny code, \n  its soo cool wow",function() self.dialogue:setpotrait("normal") end})
            table.insert(dialogue, {"* ererer er, ererer er er er",function() self.dialogue:setpotrait("blink") end})
            self:addDialogue(dialogue, "* this might be innacurate...","chuckle")
            self:addDialogue(dialogue, "* where is the dialogue at\n  :(?","blink")
            self:addDialogue(dialogue, "* ending text","normal")
            table.insert(dialogue, "")
            self:addDialogue(dialogue, "* You though that was the\n  last text? no lol","chuckle2")
            self:addDialogue(dialogue, "* The underground has got a\n  lot quieter since you came\n  here...","blink")
            self:addDialogue(dialogue, "* what did you do?","noeyes")
            self:addDialogue(dialogue, "* i can't go to hell, im out\n  of vacation days ;)","chuckle")
            self:addDialogue(dialogue, "* real ending text","normal")
            table.insert(dialogue, "")
        end
    end
    self:endturn(dialogue)
return self end