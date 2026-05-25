return function()
---@class Items
    local self = {}
    local manager = self

    self.items = {}
    self.step = require("objects.step")()

    function self:loadItems()
        local items = CLOVE.requireLib("assets/items", true)
        for key,item in pairs(items) do
            item.name = item.name or key
            if item.enabled == nil then
                item.enabled = true
            end
        end

        self.loadedItems = items
    end

    local function cloneTable(t)
        local copy = {}
        for k, v in pairs(t) do
            if type(v) == "table" then
                copy[k] = cloneTable(v)
            else
                copy[k] = v
            end
        end
        return copy
    end

    -- Retrieve an item by name or index
---@param indexOrString number|string
    function self:getItem(indexOrString)
        if type(indexOrString) == "number" then
            return self.items[indexOrString]
        elseif type(indexOrString) == "string" then
            for _, item in pairs(self.loadedItems) do
                if item.name == indexOrString then
                    return cloneTable(item)
                end
            end
        end

        return nil
    end

    -- Add multiple items
---@param items table[]
    function self:addItems(items)
        for _, obj in pairs(items) do
            local name = obj.name
            self:addItem(name, obj)
        end
    end

    -- *Override* Called when an item is removed by any means
---@param item table
	function self:removed(item)
	end

    -- *Override* Called when an item is used
---@param item table
	function self:used(item)
	end

    -- *Override* Called when an item is clicked
---@param item table
	function self:clicked(item)
	end

    -- *Override* Called when an item is consumed
---@param item table
	function self:consumed(item)
	end

---@param name string
---@param obj table
    function self:addItem(name, obj)
        local newObj = obj
        local item = {
            name = name,
            object = newObj,
            active = false,
            enabled = true
        }

        function newObj:remove()
            for i, it in ipairs(manager.items) do
                if it == item then
                    table.remove(manager.items, i)
                    if manager.removed then
                        manager:removed(item)
                    end

                    break
                end
            end
        end

        function item:use(soul, state)
            self.active = true

            if manager.used then
                manager:used(self)
            end

            if newObj.onclick then
                if newObj.onclick(newObj, soul, state) ~= false then
                    if manager.clicked then
                        manager:clicked(self)
                    end
                end
            end

            if newObj.consume then
                if newObj.consume(item) ~= false then
                    if manager.consumed then
                        manager:consumed(self)
                    end
                    newObj:remove()
                end
            else
                newObj:remove()
            end
        end

        table.insert(self.items, item)
    end

    -- Remove an item (by name or index)
---@param itemt string|number
    function self:removeItem(itemt)
        if type(itemt) == "string" then
            for i, item in ipairs(self.items) do
                if item.name == itemt then
                    table.remove(self.items, i)
                    break
                end
            end
        elseif type(itemt) == "number" then
            table.remove(self.items, itemt)
        end
    end

    -- Set active state of an item
---@param itemt table|nil
---@param state boolean|nil
    function self:setActive(itemt, state)
        local item = self:getItem(itemt)
        if item then
            item.active = state and true or false
        end
    end

    -- Get all items (optionally enabled ones only)
---@param onlyEnabled boolean|nil
    function self:getItems(onlyEnabled)
        if not onlyEnabled then
            return self.items
        end
        local enabled = {}
        print(#self.items)
        for _, item in ipairs(self.items) do
            if item.enabled == true then
                table.insert(enabled, item)
            end
        end
        return enabled
    end

    -- Replace all items
---@param items table
    function self:setItems(items)
        self.items = {}
        self:addItems(items)
    end

    -- Update only active items
---@param dt number
    function self:update(dt)
        self.step:update(dt)
    end

    function self.step:stepped()
        if not manager.items then return end

        for _, item in ipairs(manager.items) do
            if item.active and item.object.step then
                item.object:step()
            end
        end
    end

    -- *Override* Called when a step happens
	function self:stepped()
	end

    return self
end