return function() local self = {}
    local manager = self

    self.items = {}
    self.step = require("objects.step")()

    -- Retrieve an item by name or index
    function self:getItem(nameOrIndex)
        if type(nameOrIndex) == "number" then
            return self.items[nameOrIndex]
        elseif type(nameOrIndex) == "string" then
            for _, item in ipairs(self.items) do
                if item.name == nameOrIndex then
                    return item
                end
            end
        end
        return nil
    end

    -- Internal helper for adding multiple items
    function self:_addItems(items)
        for name, obj in pairs(items) do
            self:addItem(name, obj)
        end
    end

    -- Add multiple items
    function self:addItems(items)
        self:_addItems(items)
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

    function self:addItem(name, obj)
        local newObj = cloneTable(obj)
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

        function item:use()
            self.active = true

            if manager.used then
                manager:used(self)
            end

            -- use newObj (the actual instance), not obj
            if newObj.onclick then
                if newObj.onclick(item) ~= false then
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
    function self:setActive(itemt, state)
        local item = self:getItem(itemt)
        if item then
            item.active = state and true or false
        end
    end

    -- Get all items (optionally enabled ones only)
    function self:getItems(onlyEnabled)
        if not onlyEnabled then
            return self.items
        end
        local enabled = {}
        for _, item in ipairs(self.items) do
            if item.enabled == true then
                table.insert(enabled, item)
            end
        end
        return enabled
    end

    -- Replace all items
    function self:setItems(items)
        self.items = {}
        self:_addItems(items)
    end

    -- Update only active items
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

    return self
end