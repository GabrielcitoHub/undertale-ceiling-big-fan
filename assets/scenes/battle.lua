return function()
---@class BattleState
    local self = {}
    local Fightbar = require "objects.fightbar"
    local Attack = require "objects.attack"

    self.turns = 0
    self.music = MUSIC "mus_prebattle1.ogg"
    self.box = require "objects.battlebox" (32, 250, 576, 140)

---@type Soul[]
    self.souls = {self.box:makesoul()}

    --[[ local soul2 = self.box:makesoul()
    soul2.color = {0, 0, 1}
    table.insert(self.souls, soul2) ]]
    
---@type Soul[]
    self.unloadedSouls = {}
    self.soulsActions = {}

    local soulsTesting = false

    if soulsTesting then
        for i = 1, 20 do
            local rngSoul = self.box:makesoul()
            rngSoul.color = {love.math.random(1,100) / 100, love.math.random(1,100) / 100, love.math.random(1,100) / 100}
            table.insert(self.souls, rngSoul)
        end
    end

    self.soul = self.souls[1]

---@param func function
    function self:forSouls(func)
        local souls = self.souls
        if not souls then return end

        local removeSouls = {}
        for i,soul in ipairs(souls) do
            if soul.unloaded then
                table.insert(removeSouls, {index = i, soul = soul})
            end

            func(soul, i)
        end

        if removeSouls then
            local removed = 0
            for i, soulData in pairs(removeSouls) do
                local i = soulData.index
                local soul = soulData.soul
                table.insert(self.unloadedSouls, table.remove(self.souls, i - removed))
                removed = removed + 1
            end
        end
    end

---@param func function
    function self:queueSoulsAction(func)
        table.insert(self.soulsActions, func)
    end

---@param i number
---@param soul Soul
    function self:runQueueActions(i, soul)
        for _, func in pairs(self.soulsActions) do
            func(i,soul)
        end
    end

    function self:clearQueueActions()
        self.soulsActions = {}
    end

    self.soulname = require "objects.soulname" (self.soul, 30, 400)
    self.dialogue = require "objects.dialogue" (nil, "fnt_default_big", 52, 272)

---@type HealthMeter[]
    self.healthmeters = {}
    self.healthpositions = {
        275,
        475,
    }
    self:forSouls(
---@param soul Soul
---@param i number
    function(soul, i)
        local healthmeter = require "objects.healthmeter" (self.healthpositions[i], 400, nil, nil, soul)
        table.insert(self.healthmeters, healthmeter)
    end)

    self.healthmeter = self.healthmeters[1]
    self.hpmeter = self.healthmeter

    self.items = require "objects.items" ()
    self.items:loadItems()
    self.debug = require "objects.debug" ()
    self.battlebg = require "objects.image" (IMAGE "battle_bg", 15, 9)
    self.fightbar = nil
    self.opponent = nil
---@type Opponent[]
    self.opponents = {}

    self:forSouls(
---@param soul Soul
    function(soul)
        soul.active = true
        soul.locked = true
        soul.can_gameover = false
        -- soul.can_flee = false
    end)

---@type Attack[]
    self.attacks = {}
    self.buttons = {}
    self.events = {}
    self.dialoguetext = {}

    self.snaptobuttons = {}
    self:forSouls(function()
        table.insert(self.snaptobuttons, true)
    end)

    self.selectedbuttons = {}
    self:forSouls(function()
        table.insert(self.selectedbuttons, 1)
    end)

    self.selectedbutton = self.selectedbuttons[1]

    self.endingturn = false
    self.wintext = "* YOU WON!"
    self.battleisover = false
    self.activeItems = {}

    local scene = self
    local time = 0
    local attackid = 0
    local queuetime = 0
    local attackmode = false
    local attackIDS = {}
    local yum = true

    if DEBUG then
        local items = {
            self.items:getItem("TESTITEM"),
            self.items:getItem("HEALITEM"),
            self.items:getItem("ACID"),
            self.items:getItem("ACID"),
            self.items:getItem("ACID"),
            self.items:getItem("Special Acid"),
            self.items:getItem("TESTEST"),
        }

        if yum then
            items = {}
            for _ = 1,6 do
                table.insert(items, self.items:getItem("ACID"))
            end
        end
        self.items:addItems(items)

        -- for _ = 1,4 do
        --     self.items:addItems(items)
        -- end
    end

    function self:getState()
        if not self.soul.locked then
            if self.fleed then
                return "flee"
            elseif self.battleisover then
                return "win"
            else
                return "battle"
            end
        elseif attackmode then
            return "battle"
        elseif self.endingturn then
            return "attack"
        else
            return "menu"
        end
    end
    
---@param turncount number
    function self:onenemyturn(turncount)
        self:endattack("* Smells like flavor text")
    end

    function self:nextdialogue()
        local text = self.dialoguetext[1]
        if text == nil then
            self.endingturn = false
            self:onenemyturn(self.turns)
        else
            table.remove(self.dialoguetext, 1)
            self.dialogue:settext(text)
        end
    end

---@param opponent Opponent
	function self:postattack(opponent)
		if self.fightbar then
			self.fightbar.fadeanim = 1
		end

		for i = 1, #self.opponents do
			if self.opponents[i].hp <= 0 and not self.opponents[i].killed then
				self.opponents[i]:kill()
			end
		end

		self:trytoendbattle()
	end

	function self:trytoendbattle()
		local canendbattle = true
		for i = 1, #self.opponents do
			canendbattle = canendbattle and (self.opponents[i].killed or self.opponents[i].spared)
		end

		if canendbattle then
			self.soul.active = false
			self.soul.locked = false
			self.dialogue:settext(self.wintext.."\n* You got 0 EXP and 0 Gold")
			self.music:stop()
			self.battleisover = true

			return true
		else
			self:endturn()

			return false
		end
	end

---@param dialogue Dialogue|nil
    function self:endturn(dialogue)
        self.turns = self.turns + 1
        self.dialogue:settext("")

        self:forSouls(function(soul)
            soul.active = false
        end)

        self.dialoguetext = {unpack(dialogue or {})}
        self.endingturn = true
        self:nextdialogue()
    end

---@param name string|nil
---@param img love.image|string|nil
---@param hp number|nil
---@param options table|nil
    function self:makeopponent(name, img, hp, options)
        local opponent = require "objects.opponent" (name or "Unknown Enemy", (#self.opponents+1) / (#self.opponents + 2) * 640, 240, img or "dummy", hp or 30, options or {})
        self.opponents[#self.opponents+1] = opponent

        return opponent
    end

---@param x number
---@param y number
---@param sprite love.Image|string|nil
---@param spriteselected love.Image|string|nil
---@param color table|nil
---@param colorselected table|nil
---@param soulx number|nil
---@param souly number|nil
    function self:makebutton(x, y, sprite, spriteselected, color, colorselected, soulx, souly)
        local index = #self.buttons + 1
        self.buttons[index] = require "objects.battlebutton" (x, y, color, colorselected, sprite, spriteselected, soulx, souly)
        return self.buttons[index]
    end

---@param func function
    function self:makeopponentselectors(func)
        local options = {}

        for i = 1, #self.opponents do
            local opponent = self.opponents[i]
            if opponent and not opponent.spared and not opponent.killed then
				local ocol = {1, 1, 1}

				if opponent.canspare then
					ocol = {1, 1, 0}
				end

                options[#options+1] = {
                    text = "* " .. opponent.name,

					color = ocol,

                    onclick = function(index)
                        func(opponent, index)
                    end
                }
            end
        end

		local rows
		if #self.opponents > 3 then
			rows = 3
		end

        self.dialogue:makechoices(options, self.soul, 1, rows)
    end

    function self:makedefaultbuttons()
        self:makebutton(32, 432, "fight_button", "fight_button_selected", nil, {1, 1, 0.294117647}, function ()
			-- print("killyou")
            self:makeopponentselectors(function(opponent)
                self.soul.active = false
                self.dialogue:settext("")
				local at = 10

				if self.soul then
					at = self.soul.at
				end

                self.fightbar = Fightbar(opponent, at, self.box.x + self.box.width / 2, self.box.y + self.box.height / 2)
            end)
        end)

        self:makebutton(185, 432, "act_button", "act_button_selected", nil, nil, function ()
            self:makeopponentselectors(function(opponent)
				if opponent.checktext then
					self.dialogue:makechoices({
						{
							text = "* Check",
							onclick = function()
								self:endturn(opponent.checktext)
							end
						},
						unpack(opponent.acts)
					}, self.soul, 2)
				else
					self.dialogue:makechoices(opponent.acts, self.soul, 2)
				end
            end)
        end)

        local state = self
        self:makebutton(345, 432, "item_button", "item_button_selected", nil, nil, function ()
            if self.items then
                local itemsChoices = {}

                for i, item in pairs(self.items:getItems(true)) do
                    local name = item.name
                    local itemDialogue = {
                        menu = "item",
                        text = "* " .. name,
                        onclick = function()
                            item:use(state.soul, state)
                        end
                    }
                    table.insert(itemsChoices, #itemsChoices + 1, itemDialogue)
                end

                self.dialogue:makechoices(itemsChoices, self.soul, 2)
            end
        end)

        self:makebutton(500, 432, "mercy_button", "mercy_button_selected", nil, nil, function ()
			local canspare = false
			for i = 1, #self.opponents do
				if self.opponents[i].canspare then
					canspare = true
					break
				end
			end

			local sparecol = {1, 1, 1}
			if canspare then
				sparecol = {1, 1, 0}
			end

            self.dialogue:makechoices({
                {
                    text = "* Spare",
					color = sparecol,
                    onclick = function()
                        for i = 1, #self.opponents do
                            if self.opponents[i].canspare and not self.opponents[i].killed then
                                self.opponents[i]:spare()
                            end
                        end

						self:trytoendbattle()
                    end
                },
                {
                    text = "* Flee",
                    onclick = function()
                        local canflee = true
                        for i = 1, #self.opponents do
                            canflee = canflee and (math.random() < self.opponents[i].fleechance)
                        end

                        if canflee then
                            self.dialogue:settext("   * I'm outta here...")
                            self.dialogue:skip()
                            self.soul:flee()
                            self.soul.locked = false
                            self.soul.fleed = true
                            self.fleed = true
                        else
                            self:endturn()
                        end
                    end
                },
            }, self.soul)
        end)
    end

---@param item table
    function self.items:used(item)
    end

---@param item table
    function self.items:clicked(item)
        scene:endturn()
    end

---@param mus love.Source
    function self:setmusic(mus)
        self.music:stop()
        self.music = MUSIC(mus)
        self.music:play()
        self.music:setLooping(true)
    end

    self.music:play()
    self.music:setLooping(true)

    -- *override* Called when the battlefield is updated
    function self:onupdate(dt) end

    -- *override* Called when the battle ends
    function self:onBattleEnd()
        POPSCENE()
    end

---@param dt number
    function self:update(dt)
        self.items:update(dt)

        self.aliveSouls = {}
        -- Update souls
        self:forSouls(
---@param soul Soul
---@param i number
        function(soul, i)
            if soul.hp > 0 then
                table.insert(self.aliveSouls, soul)
                -- On menu button selection
                if not attackmode then
                    local selectedbutton = self.selectedbuttons[i]
                    local snaptobutton = self.snaptobuttons[i]

                    if snaptobutton and #self.dialogue.menus == 0 and soul.active and soul.locked then
                        if ISPRESSED "LEFT" then
                            selectedbutton = selectedbutton - 1
                            PLAYSOUND "snd_squeak.wav"
                            if selectedbutton < 1 then
                                selectedbutton = #self.buttons
                            end
                        end

                        if ISPRESSED "RIGHT" then
                            selectedbutton = selectedbutton + 1
                            PLAYSOUND "snd_squeak.wav"
                            if selectedbutton > #self.buttons then
                                selectedbutton = 1
                            end
                        end

                        if #self.buttons > 0 then
                            soul.x = self.buttons[selectedbutton].x + self.buttons[selectedbutton].soulx
                            soul.y = self.buttons[selectedbutton].y + self.buttons[selectedbutton].souly
                        end

                        self.selectedbuttons[i] = selectedbutton
                    end

                    if snaptobutton and #self.buttons > 0 then
                        self.buttons[selectedbutton].hover = true
                    end
                end

                -- Souls attacks collision detection
                for index, attack in pairs(self.attacks) do
                    if not self.attacksUpdated then
                        attack:update(self, dt)
                    end

                    if not attack.disabled then
                        if soul.active then
                            if soul:takedamage(attack) then
                                if not attack.no_hit_destroy then
                                    self.attacks[index] = nil
                                end

                                self.last_hit = soul
                            end
                        end
                    end
                end

                self.attacksUpdated = true
            end

            if soul.active then
                soul:update(dt)
                self:runQueueActions(i, soul)
            end
        end)

        self:clearQueueActions()

        self.attacksUpdated = false
        local aliveSoulsCount = #self.aliveSouls
        if aliveSoulsCount <= 0 then
            local deadSoul = self.last_hit or self.souls[1] -- TO-DO: This may cause issues with multiple souls, think of way to fix asap
            deadSoul.can_gameover = true
            return
        end

        if self.battleisover then
            if ISPRESSED "SELECT" and self.dialogue.text == self.dialogue.targettext then
                self:onBattleEnd()
            end
        end

        for i = 1, #self.opponents do
            local opponent = self.opponents[i]
            opponent.x = i / (#self.opponents + 1) * 640
            opponent:update(self)
        end

        self.battlebg:update()

        for index, value in pairs(self.buttons) do
            value:update(self)
        end

		if self.fightbar then
			if self.fightbar:update(dt) == false then
				self.fightbar = nil
			end
		end

		self.dialogue:update(dt)

        for _,healthmeter in ipairs(self.healthmeters) do
            healthmeter:update()
        end

        self.box:update(dt)

        if not self.box.resizing then
            for index, value in ipairs(self.events) do
                if value[1] <= time then
                    value[2](self)
                    table.remove(self.events, index)
                else
                    break
                end
            end
        end

        if not self.box.resizing then
            time = time + 1
            if queuetime < time then
                queuetime = time
            end
        end

        if self.endingturn then
            if ISPRESSED "SELECT" and self.dialogue.text == self.dialogue.targettext then
                self:nextdialogue()
            end
        end

        self:onupdate(dt)
        self.debug:update(dt)
    end

    function self.items:stepped()
        for _, item in ipairs(self.items) do
            if item.active and item.object and item.object.step then
                item.object:step(scene:getState())
            end
        end
    end

    function self:draw()
        local cond = #self.aliveSouls <= 0
        self:forSouls(
---@param soul Soul
        function(soul)
            if cond then
                soul:draw()
            end
        end)

        -- This makes the BG black, possible option to disable it in the future
        if cond then
            return
        end

        self.battlebg:draw()

        for i = 1, #self.opponents do
            local opponent = self.opponents[i]
            opponent:draw()
        end

        self.soulname:draw()

        for index, value in pairs(self.buttons) do
            value:draw(self)
        end

        self.box:draw()

        for _,healthmeter in ipairs(self.healthmeters) do
            healthmeter:draw()
        end

        if not cond then
            self:forSouls(
---@param soul Soul
            function(soul)
                if soul.active then
                    soul:draw()
                end
            end)
        end

		if self.fightbar then
			self.fightbar:draw()
		end

		self.dialogue:draw()

        for index, value in pairs(self.attacks) do
            value:draw(self)
        end

        self.debug:draw()
    end

    function self:debugdraw()
        love.graphics.outline(self.box, {1, 1, 1})
        love.graphics.outline(self.box, {1, 0, 1}, 0, 0, 8)

        self:forSouls(
---@param soul Soul
        function(soul) 
            love.graphics.outline(soul, {0, 1, 1}, -0.5, -0.5)
        end)

        love.graphics.outline(self.dialogue, {1, 1, 0})

        for _,healthmeter in ipairs(self.healthmeters) do
            love.graphics.outline(healthmeter, {1, 1, 0})
        end

        love.graphics.outline(self.soulname, {1, 1, 0})
        love.graphics.outline(self.battlebg, {1, 1, 0})

        for i = 1, #self.opponents do
            local opponent = self.opponents[i]
            love.graphics.outline(opponent, {1, 0.5, 0}, -0.5, -1)
        end

        for index, value in pairs(self.attacks) do
            love.graphics.outline(value, {1, 0, 0}, -0.5, -0.5)
        end

        for index, value in pairs(self.buttons) do
            love.graphics.outline(value, {0, 1, 0})
        end

        if love.keyboard.isDown("p") then
            love.graphics.setColor(0.2, 1, 0.2, 0.25)
            love.graphics.draw(IMAGE "froggit hopped close", 0, 0)
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(FONT "fnt_default")

        local eventcount = 0
        for key, value in pairs(self.events) do
            eventcount = eventcount + 1
        end

        love.graphics.print("Events: "..eventcount, 0, 0)
        love.graphics.print("Queuetime: "..queuetime, 0, 16)
        love.graphics.print("Time: "..time, 0, 32)
        love.graphics.print("Mouse: "..(MOUSEX())..", "..(MOUSEY()), 0, 48)
        love.graphics.print("Attack: "..tostring(attackmode), 0, 64)
        love.graphics.print("Box resizing: "..tostring(self.box.resizing), 0, 64+16)
        love.graphics.print("StepTime: "..self.items.step.steptime, 0, 64+32)
        love.graphics.print("Step: "..tostring(self.items.step.step), 0, 64+32+16)
        love.graphics.print("State: "..self:getState(), 0, 64+64)
        love.graphics.print("IFrames: "..self.soul.iframes, 0, 64+64+16)
    end

    ---@return Attack|AttackConstructor
    ---@param options table
    function self:makebullet(options)
        local image = IMAGE(options.image or "attack_default")
        local width = options.width or image:getWidth()
        local height = options.height or image:getHeight()
        local spawned = options.spawned
        local update = options.update
        local draw = options.draw

        return Attack(width, height, image, spawned, update, draw)
    end

    -- local t = self:makebullet()

    function self:queue(event)
        self.events[#self.events+1] = {queuetime, event}
    end

---@param waittime number
    function self:wait(waittime)
        self:delayqueue(waittime * 60)
    end

---@param waittime number
    function self:delayqueue(waittime)
        if queuetime < time then
            queuetime = time
        end

        queuetime = queuetime + waittime
    end

---@param bulletconstructor AttackConstructor
---@param x number
---@param y number
    function self:queuespawn(bulletconstructor, x, y, ...)
        local args = {...}
        self:queue(function()
            self:spawn(bulletconstructor, x, y, unpack(args))
        end)
    end

	function self:clearqueue()
		self.events = {}
        queuetime = time
	end

---@param bulletconstructor AttackConstructor
---@param x number
---@param y number
    function self:spawn(bulletconstructor, x, y, ...)
        local bullet = bulletconstructor()
        attackid = attackid + 1
        self.attacks[attackid] = bullet
        attackIDS[bullet] = attackid
        bullet.x = x
        bullet.y = y
        bullet:spawned(...)
    end

---@param attack Attack
    function self:destroy(attack)
        self.attacks[attackIDS[attack]] = nil
        attackIDS[attack] = nil
    end

---@param flavortext string|nil
    function self:endattack(flavortext)
        -- time = 0
        queuetime = time
        self.attacks = {}
        attackIDS = {}
        -- self.events = {}
        self.box:removesoul()
        self.box:resize(576, 140)
        self.dialogue:settext(flavortext or "* Smells like flavor text.")
        attackmode = false
        self:forSouls(function(soul, i)
            soul.active = true
            soul.locked = true
        end)
    end

---@param func function
---@param width number|nil
---@param height number|nil
---@param instant boolean|nil
    function self:startattack(func, width, height, instant)
        -- time = 0
        queuetime = time
        self.attacks = {}
        attackIDS = {}
        -- self.soul.locked = false
        self.events = {
            {0, function(self)
                self.box:makesoul(self.souls)
---@param soul Soul
---@param i number
                self:forSouls(function(soul, i)
                    soul.active = true
                    soul.locked = false
                end)
            end},
            {0, func}
        }
		self.dialogue:settext("")
        self.box:resize(width or 140, height or 140)

		if instant then
			self.box.resizetimer = self.box.resizetime
			self.box.width = width
			self.box.height = height
		end

        attackmode = true
    end
    
    self:endattack()
    self:makedefaultbuttons()
return self end