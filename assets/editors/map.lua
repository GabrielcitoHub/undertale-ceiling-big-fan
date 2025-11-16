-- editor.lua
-- Single-file multi-mode map editor for LÖVE
-- Modes: 1=Tiles, 2=Objects, 3=Rooms, 4=Shapes

local prevX, prevY = 0, 0
local mouseDX, mouseDY = 0, 0
prevX, prevY = love.mouse.getPosition()
-- small helper for deep copy
local function vim_copy(t)
    if not t then return nil end
    local seen = {}
    local function _copy(obj)
        if type(obj) ~= "table" then return obj end
        if seen[obj] then return seen[obj] end
        local res = {}
        seen[obj] = res
        for k,v in pairs(obj) do res[_copy(k)] = _copy(v) end
        return res
    end
    return _copy(t)
end

return function() local self = {}
    self.debug = require "objects.debug" ()

    -- ---- Config ----
    local GRID = 32
    local PALETTE_PATH = "tiles/" -- tile files should be in this folder, or use IMAGE names
    local SAVE_FILE = "map_editor_save.lua"
    local DEFAULT_TILE = 1

    -- ---- State ----
    self.mode = 1 -- 1..4
    self.camera = { x = 0, y = 0, zoom = 1 }
    self.mouse = { x = 0, y = 0, wx = 0, wy = 0, down = false }
    self.gridSize = GRID
    self.tileSize = GRID

    -- Map data
    self.map = {
        width = 40, height = 25,
        tiles = {},        -- tiles[y][x] = globalTileIndex or nil
        objects = {},      -- list of {name, x, y, w,h,props}
        rooms = {},        -- list of {x,y,w,h,props}
        shapes = {},       -- list of {type="rect"/"circle", x,y,w,h,r,rot,props}
    }

    -- Simple tile palette (fill with names / indices); user can replace with IMAGE names
    self.palette = { "grass", "dirt", "water", "stone", "sand" }
    self.paletteIndex = 1

    -- Global tiles/quads (flattened across palettes)
    self.globalTiles = {}   -- entries: { img = <Image>, quad = <Quad>, palette = name, localIndex = n }
    self.globalIndex = 1    -- selected global tile index

    -- Images cache using IMAGE() if present
    local imageCache = {}
    local function loadImage(name)
        if not name then return nil end
        if imageCache[name] then return imageCache[name] end
        local img = nil
        local ok, res = pcall(function() return IMAGE(PALETTE_PATH .. name) end)
        if ok and res then
            img = res
            -- If IMAGE wrapper returns a table with .image, pick it (common wrappers)
            if type(img) == "table" and rawget(img, "image") and img.image then
                imageCache[name] = img.image
                return img.image
            end
            imageCache[name] = img
            return img
        end
        -- fallback: try love.graphics.newImage with path
        ok, res = pcall(love.graphics.newImage, PALETTE_PATH .. name .. ".png")
        if ok and res then
            imageCache[name] = res
            return res
        end
        imageCache[name] = nil
        return nil
    end

    -- Build globalTiles from self.palette and current grid/tile size
    local function buildGlobalTiles()
        self.globalTiles = {}
        for pIndex, name in ipairs(self.palette) do
            local img = loadImage(name)
            if img then
                local iw, ih = img:getWidth(), img:getHeight()
                local tilesX = math.max(1, math.floor(iw / self.tileSize))
                local tilesY = math.max(1, math.floor(ih / self.tileSize))
                local localIndex = 1
                for ty = 0, tilesY - 1 do
                    for tx = 0, tilesX - 1 do
                        local q = love.graphics.newQuad(
                            tx * self.tileSize, ty * self.tileSize,
                            self.tileSize, self.tileSize,
                            iw, ih
                        )
                        table.insert(self.globalTiles, {
                            img = img,
                            quad = q,
                            palette = name,
                            paletteIndex = pIndex,
                            localIndex = localIndex,
                            tilesX = tilesX,
                            tilesY = tilesY,
                        })
                        localIndex = localIndex + 1
                    end
                end
            end
        end

        if #self.globalTiles == 0 then
            -- ensure there's at least one dummy entry to avoid errors
            self.globalIndex = 1
        else
            -- clamp globalIndex
            if self.globalIndex < 1 then self.globalIndex = 1 end
            if self.globalIndex > #self.globalTiles then self.globalIndex = #self.globalTiles end
        end
    end

    -- Undo stack (simple)
    local undoStack = {}
    local function pushUndo()
        local state = {
            tiles = vim_copy(self.map.tiles),
            objects = vim_copy(self.map.objects),
            rooms = vim_copy(self.map.rooms),
            shapes = vim_copy(self.map.shapes),
        }
        table.insert(undoStack, state)
        if #undoStack > 50 then table.remove(undoStack, 1) end
    end

    -- Ensure tile table exists
    local function ensureTiles()
        for y=1,self.map.height do
            self.map.tiles[y] = self.map.tiles[y] or {}
        end
    end
    ensureTiles()

    -- Helpers for world coords
    local function screenToWorld(sx, sy)
        local wx = (sx / self.camera.zoom) + self.camera.x
        local wy = (sy / self.camera.zoom) + self.camera.y
        return wx, wy
    end
    local function worldToGrid(wx, wy)
        local gx = math.floor(wx / self.gridSize) + 1
        local gy = math.floor(wy / self.gridSize) + 1
        return gx, gy
    end

    -- Basic serializer (saves to love.filesystem as Lua)
    local function serialize(tbl)
        local seen = {}
        local function ser(v, indent)
            indent = indent or ""
            local t = type(v)
            if t == "number" or t == "boolean" then return tostring(v) end
            if t == "string" then return string.format("%q", v) end
            if t == "table" then
                if seen[v] then return '"<cycle>"' end
                seen[v] = true
                local parts = {}
                local isArray = (#v > 0)
                for k,val in pairs(v) do
                    if isArray then
                        table.insert(parts, ser(val, indent .. "  "))
                    else
                        local key = (type(k) == "string") and k or ("["..ser(k).."]")
                        table.insert(parts, indent .. "  " .. key .. " = " .. ser(val, indent .. "  "))
                    end
                end
                if isArray then
                    return "{ " .. table.concat(parts, ", ") .. " }"
                else
                    return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
                end
            end
            return "nil"
        end
        return "return " .. ser(tbl)
    end

    -- Load map snapshot from file
    local function saveMap()
        local save = {
            width = self.map.width,
            height = self.map.height,
            tiles = self.map.tiles,
            objects = self.map.objects,
            rooms = self.map.rooms,
            shapes = self.map.shapes,
            palette = self.palette
        }
        local ok, err = love.filesystem.write(SAVE_FILE, serialize(save))
        if not ok then
            self.debug:print("Save failed:", err)
        else
            self.debug:print("Saved to", SAVE_FILE)
        end
    end

    local function loadMap()
        if not love.filesystem.getInfo(SAVE_FILE) then
            self.debug:print("No save file found.")
            return
        end
        local chunk, err = love.filesystem.load(SAVE_FILE)
        if not chunk then
            self.debug:print("Load failed:", err)
            return
        end
        local data = chunk()
        if data then
            self.map.width = data.width or self.map.width
            self.map.height = data.height or self.map.height
            self.map.tiles = data.tiles or {}
            self.map.objects = data.objects or {}
            self.map.rooms = data.rooms or {}
            self.map.shapes = data.shapes or {}
            self.palette = data.palette or self.palette
            ensureTiles()
            buildGlobalTiles() -- rebuild quads after loading palette
            self.debug:print("Loaded", SAVE_FILE)
        end
    end

    -- ---- Interaction state ----
    local selection = { type = nil, idx = nil, sx = 0, sy = 0, ox = 0, oy = 0 } -- selection for drag
    local placingRect = nil -- used for rooms/shapes drag
    local dragging = false

    -- Utilities
    local function clamp(a,b,c) return math.max(b, math.min(c, a)) end

    -- UI draw helpers
    local function drawGrid()
        local w,h = love.graphics.getWidth(), love.graphics.getHeight()
        local startx = - (self.camera.x % self.gridSize)
        local starty = - (self.camera.y % self.gridSize)
        love.graphics.push()
        love.graphics.translate(-self.camera.x * self.camera.zoom, -self.camera.y * self.camera.zoom)
        love.graphics.scale(self.camera.zoom, self.camera.zoom)
        love.graphics.setLineWidth(1 / self.camera.zoom)
        love.graphics.setColor(0.7,0.7,0.7,0.25)
        for x = startx, w + self.gridSize, self.gridSize do
            love.graphics.line(x, 0, x, h + self.gridSize)
        end
        for y = starty, h + self.gridSize, self.gridSize do
            love.graphics.line(0, y, w + self.gridSize, y)
        end
        love.graphics.pop()
    end

    -- Film-roll preview for globalTiles
    local function drawFilmRollPreview(cx, cy, cr, csx, csy)
        if #self.globalTiles == 0 then return end
        local spacing = 38
        local displayRange = 4 -- how many above/below to show
        for offset = -displayRange, displayRange do
            local idx = self.globalIndex + offset
            -- wrap
            while idx < 1 do idx = idx + #self.globalTiles end
            while idx > #self.globalTiles do idx = idx - #self.globalTiles end
            local entry = self.globalTiles[idx]
            if entry and entry.img and entry.quad then
                local alpha = 1 - math.abs(offset) * 0.15
                if alpha < 0.12 then alpha = 0.12 end
                love.graphics.setColor(1,1,1,alpha)
                local scale = 3
                -- center the quad on cx, cy + offset*spacing
                local px = cx
                local py = cy + offset * spacing
                love.graphics.draw(entry.img, entry.quad, px, py, cr, csx * scale, csy * scale)
            end
        end
        -- highlight selected
        love.graphics.setColor(1,1,0,0.9)
        --love.graphics.rectangle("line", cx - 36, cy - 36, csx, csy)
        love.graphics.setColor(1,1,1,1)
    end

    -- Draw tiles (now using globalTiles quads)
    local function drawTiles()
        love.graphics.push()
        love.graphics.translate(-self.camera.x * self.camera.zoom, -self.camera.y * self.camera.zoom)
        love.graphics.scale(self.camera.zoom, self.camera.zoom)
        for y=1,self.map.height do
            for x=1,self.map.width do
                local t = (self.map.tiles[y] and self.map.tiles[y][x]) or nil
                if t then
                    local entry = self.globalTiles[t]
                    if entry and entry.img and entry.quad then
                        love.graphics.setColor(1,1,1,1)
                        -- scale to current grid size if different from tileSize
                        local sx = self.gridSize / self.tileSize
                        local sy = self.gridSize / self.tileSize
                        love.graphics.draw(entry.img, entry.quad, (x-1)*self.gridSize, (y-1)*self.gridSize, 0, sx, sy)
                    else
                        love.graphics.setColor(0.5,0.5,0.5,0.8)
                        love.graphics.rectangle("fill", (x-1)*self.gridSize, (y-1)*self.gridSize, self.gridSize, self.gridSize)
                        love.graphics.setColor(1,1,1,1)
                    end
                end
            end
        end
        love.graphics.pop()
    end

    -- Draw objects
    local function drawObjects()
        love.graphics.push()
        love.graphics.translate(-self.camera.x * self.camera.zoom, -self.camera.y * self.camera.zoom)
        love.graphics.scale(self.camera.zoom, self.camera.zoom)
        for i,obj in ipairs(self.map.objects) do
            love.graphics.setColor(0.2,0.6,0.2,0.9)
            love.graphics.rectangle("fill", obj.x, obj.y, obj.w or 16, obj.h or 16)
            love.graphics.setColor(1,1,1,1)
            if selection.type == "object" and selection.idx == i then
                love.graphics.setColor(1,1,0,0.8)
                love.graphics.rectangle("line", obj.x, obj.y, obj.w or 16, obj.h or 16)
            end
            love.graphics.print(obj.name or "obj", obj.x, obj.y - 12)
        end
        love.graphics.pop()
    end

    -- Draw rooms (rects)
    local function drawRooms()
        love.graphics.push()
        love.graphics.translate(-self.camera.x * self.camera.zoom, -self.camera.y * self.camera.zoom)
        love.graphics.scale(self.camera.zoom, self.camera.zoom)
        for i,r in ipairs(self.map.rooms) do
            love.graphics.setColor(0.6,0.4,0.2,0.4)
            love.graphics.rectangle("fill", r.x, r.y, r.w, r.h)
            love.graphics.setColor(0.9,0.7,0.4,1)
            love.graphics.rectangle("line", r.x, r.y, r.w, r.h)
            if selection.type == "room" and selection.idx == i then
                love.graphics.setColor(1,1,0,0.9)
                love.graphics.rectangle("line", r.x, r.y, r.w, r.h)
            end
        end
        love.graphics.pop()
    end

    -- Draw shapes
    local function drawShapes()
        love.graphics.push()
        love.graphics.translate(-self.camera.x * self.camera.zoom, -self.camera.y * self.camera.zoom)
        love.graphics.scale(self.camera.zoom, self.camera.zoom)
        for i,s in ipairs(self.map.shapes) do
            if s.type == "rect" then
                love.graphics.setColor(0.3,0.5,0.9,0.4)
                love.graphics.rectangle("fill", s.x, s.y, s.w, s.h)
                love.graphics.setColor(0.2,0.4,0.8,1)
                love.graphics.rectangle("line", s.x, s.y, s.w, s.h)
            else
                love.graphics.setColor(0.9,0.3,0.3,0.4)
                love.graphics.circle("fill", s.x, s.y, s.r)
                love.graphics.setColor(0.8,0.2,0.2,1)
                love.graphics.circle("line", s.x, s.y, s.r)
            end
            if selection.type == "shape" and selection.idx == i then
                love.graphics.setColor(1,1,0,0.9)
                if s.type == "rect" then
                    love.graphics.rectangle("line", s.x, s.y, s.w, s.h)
                else
                    love.graphics.circle("line", s.x, s.y, s.r)
                end
            end
        end
        love.graphics.pop()
    end

    -- UI overlay
    local function drawUI()
        love.graphics.setColor(0,0,0,0.6)
        love.graphics.rectangle("fill", 4, 4, 420, 180)
        love.graphics.setColor(1,1,1,1)
        love.graphics.print(("Mode: %d (1=Tiles 2=Objs 3=Rooms 4=Shapes)"):format(self.mode), 8, 8)
        love.graphics.print(("Grid: %d px    Palette idx: %d/%d"):format(self.gridSize, self.paletteIndex, #self.palette), 8, 24)
        love.graphics.print("LMB: place/select  RMB: erase/deselect   S:save L:load Z:undo", 8, 40)
        love.graphics.print("UP/DOWN: scroll tiles   LEFT/RIGHT: cycle palettes", 8, 56)
        love.graphics.print("Scroll: cycle palette/size. Click+drag to move camera (middle) or shapes/rooms/objects", 8, 72)
        love.graphics.print("Selected: "..(selection.type or "none"), 8, 88)

        -- draw small palette preview
        local px = 8; local py = 112
        for i,name in ipairs(self.palette) do
            local img = loadImage(name)
            love.graphics.setColor(1,1,1,1)
            if img then
                local iw,ih = img:getWidth(), img:getHeight()
                local scale = 32 / math.max(1, math.max(iw, ih))
                love.graphics.draw(img, px + (i-1)*36, py, 0, 32 / iw, 32 / ih)
                -- film-roll preview to the right of the UI box
                drawFilmRollPreview(px + (i-1)*36, py, 0, 32 / iw, 32 / ih)
            else
                love.graphics.setColor(0.4,0.4,0.4,1)
                love.graphics.rectangle("fill", px + (i-1)*36, py, 32, 32)
            end
            if i == self.paletteIndex then
                love.graphics.setColor(1,1,0,1)
                love.graphics.rectangle("line", px + (i-1)*36 - 1, py - 1, 34, 34)
            end
        end
    end

    -- Input handling
    function self:update(dt)
        local x, y = love.mouse.getPosition()
        mouseDX = x - prevX
        mouseDY = y - prevY
        prevX, prevY = x, y
        -- update mouse world pos
        local mx,my = MOUSEX(),MOUSEY()
        self.mouse.x, self.mouse.y = mx,my
        self.mouse.wx, self.mouse.wy = screenToWorld(mx, my)
        if love.mouse.isDown(1) then self.mouse.down = true else self.mouse.down = false end

        -- camera pan with middle mouse or alt+LMB
        if love.mouse.isDown(2) or (love.keyboard.isDown("lalt") and love.mouse.isDown(1)) then
            local dx,dy = mouseDX, mouseDY
            self.camera.x = self.camera.x - dx / self.camera.zoom
            self.camera.y = self.camera.y - dy / self.camera.zoom
        end

        -- shortcuts
        if love.keyboard.isDown("1") then self.mode = 1 end
        if love.keyboard.isDown("2") then self.mode = 2 end
        if love.keyboard.isDown("3") then self.mode = 3 end
        if love.keyboard.isDown("4") then self.mode = 4 end

        -- save/load/undo
        if love.keyboard.isDown("s") then
            saveMap()
        end
        if love.keyboard.isDown("l") then
            loadMap()
        end
        if ISPRESSED "SELECT" then
            -- simple undo: pop last snapshot
            local st = table.remove(undoStack)
            if st then
                self.map.tiles = st.tiles or {}
                self.map.objects = st.objects or {}
                self.map.rooms = st.rooms or {}
                self.map.shapes = st.shapes or {}
            end
        end

        -- palette left/right
        if ISPRESSED "RIGHT" then
            self.paletteIndex = clamp(self.paletteIndex + 1, 1, #self.palette)
            buildGlobalTiles()
        end
        if ISPRESSED "LEFT" then
            self.paletteIndex = clamp(self.paletteIndex - 1, 1, #self.palette)
            buildGlobalTiles()
        end

        -- tile film-roll scrolling (UP/DOWN)
        if ISPRESSED "UP" then
            self.globalIndex = (self.globalIndex - 2) % math.max(1,#self.globalTiles) + 1
        end
        if ISPRESSED "DOWN" then
            self.globalIndex = (self.globalIndex) % math.max(1,#self.globalTiles) + 1
        end

        -- place / select logic on LMB press (single-click)
        if love.mouse.isDown(1) then
            -- to avoid repeated fast actions we use a simple flagging; in heavy use you can replace with pressed event handling
            if not self._wasDown then
                self._wasDown = true
                -- click action
                local wx,wy = self.mouse.wx, self.mouse.wy
                if self.mode == 1 then
                    -- tile painting: place currently selected global tile
                    local gx,gy = worldToGrid(wx, wy)
                    if gx >=1 and gy >=1 and gx <= self.map.width and gy <= self.map.height then
                        pushUndo()
                        -- store the selected global tile index
                        if #self.globalTiles > 0 then
                            self.map.tiles[gy][gx] = self.globalIndex
                        else
                            self.map.tiles[gy][gx] = nil
                        end
                    end
                elseif self.mode == 2 then
                    -- object place / select
                    -- try select first
                    local found = false
                    for i,obj in ipairs(self.map.objects) do
                        if wx >= obj.x and wx <= obj.x + (obj.w or 16) and wy >= obj.y and wy <= obj.y + (obj.h or 16) then
                            selection = { type = "object", idx = i, sx = wx, sy = wy, ox = obj.x, oy = obj.y }
                            found = true
                            break
                        end
                    end
                    if not found then
                        pushUndo()
                        local newobj = { name = "obj"..(#self.map.objects+1), x = wx, y = wy, w = 16, h = 16, props = {} }
                        table.insert(self.map.objects, newobj)
                        selection = { type = "object", idx = #self.map.objects, sx = wx, sy = wy, ox = newobj.x, oy = newobj.y }
                    end
                elseif self.mode == 3 then
                    -- start room drag
                    placingRect = { x = wx, y = wy, w = 0, h = 0 }
                    selection = { type = "room", idx = nil }
                elseif self.mode == 4 then
                    -- shape place: cycle between rect/circle on shift
                    local sh = { type = love.keyboard.isDown("lshift") and "circle" or "rect", x = wx, y = wy, w = 32, h = 32, r = 16, props = {} }
                    pushUndo()
                    table.insert(self.map.shapes, sh)
                    selection = { type = "shape", idx = #self.map.shapes }
                end
            end
        else
            self._wasDown = false
        end

        -- mouse release handling for room placement
        if not love.mouse.isDown(1) and placingRect then
            local wx,wy = self.mouse.wx, self.mouse.wy
            placingRect.w = wx - placingRect.x
            placingRect.h = wy - placingRect.y
            pushUndo()
            table.insert(self.map.rooms, { x = placingRect.x, y = placingRect.y, w = placingRect.w, h = placingRect.h, props = {} })
            placingRect = nil
        end

        -- right-click erase/deselect
        if love.mouse.isDown(2) and not self._wasRDown then
            self._wasRDown = true
            local wx,wy = self.mouse.wx, self.mouse.wy
            if self.mode == 1 then
                local gx,gy = worldToGrid(wx,wy)
                pushUndo()
                if gx>=1 and gy>=1 and gx<=self.map.width and gy<=self.map.height then
                    self.map.tiles[gy][gx] = nil
                end
            elseif self.mode == 2 then
                -- remove object if clicked
                for i,obj in ipairs(self.map.objects) do
                    if wx >= obj.x and wx <= obj.x + (obj.w or 16) and wy >= obj.y and wy <= obj.y + (obj.h or 16) then
                        pushUndo()
                        table.remove(self.map.objects, i)
                        break
                    end
                end
            elseif self.mode == 3 then
                for i,r in ipairs(self.map.rooms) do
                    if wx >= r.x and wx <= r.x+r.w and wy >= r.y and wy <= r.y+r.h then
                        pushUndo()
                        table.remove(self.map.rooms, i)
                        break
                    end
                end
            elseif self.mode == 4 then
                for i,s in ipairs(self.map.shapes) do
                    if s.type == "rect" and wx >= s.x and wx <= s.x+s.w and wy >= s.y and wy <= s.y+s.h then
                        pushUndo()
                        table.remove(self.map.shapes, i)
                        break
                    elseif s.type == "circle" and ((wx - s.x)^2 + (wy - s.y)^2) <= (s.r*s.r) then
                        pushUndo()
                        table.remove(self.map.shapes, i)
                        break
                    end
                end
            end
        elseif not love.mouse.isDown(2) then
            self._wasRDown = false
        end

        -- dragging selected object
        if selection.type == "object" and selection.idx then
            if love.mouse.isDown(1) then
                -- drag
                local idx = selection.idx
                local obj = self.map.objects[idx]
                if obj then
                    local gx,gy = self.mouse.wx, self.mouse.wy
                    obj.x = gx - ((selection.sx - selection.ox) or 0)
                    obj.y = gy - ((selection.sy - selection.oy) or 0)
                end
            end
        end

        -- Handle ESC / CANCEL
        if ISPRESSED "CANCEL" then
            RELOAD()
        end

        self.debug:update(dt)
    end

    -- wheel callback (attach to love.wheelmoved from main or provide wrapper)
    function self:wheelmoved(x,y)
        if y == 0 then return end
        if self.mode == 1 then
            -- cycle palette
            self.paletteIndex = clamp(self.paletteIndex + (y > 0 and 1 or -1), 1, #self.palette)
            buildGlobalTiles()
        else
            -- change grid size for convenience
            self.gridSize = math.max(8, clamp(self.gridSize + (y > 0 and 8 or -8), 8, 128))
        end
    end

    -- draw
    function self:draw()
        love.graphics.clear(0.08, 0.08, 0.09)
        drawGrid()
        drawTiles()
        drawRooms()
        drawShapes()
        drawObjects()

        -- draw placingRect preview
        if placingRect then
            love.graphics.push()
            love.graphics.translate(-self.camera.x * self.camera.zoom, -self.camera.y * self.camera.zoom)
            love.graphics.scale(self.camera.zoom, self.camera.zoom)
            love.graphics.setColor(1,1,1,0.5)
            love.graphics.rectangle("line", placingRect.x, placingRect.y, self.mouse.wx - placingRect.x, self.mouse.wy - placingRect.y)
            love.graphics.pop()
        end

        drawUI()
        self.debug:draw()
    end

    -- optional callback wrappers so main can forward events
    function self:mousepressed(x,y,button)
        -- forward to internal
        if button == 2 then self._wasRDown = true end
        if button == 1 then self._wasDown = true end
    end
    function self:mousereleased(x,y,button)
        if button == 2 then self._wasRDown = false end
        if button == 1 then self._wasDown = false end
    end

    -- initialize: ensure tables exist and build quads
    ensureTiles()
    buildGlobalTiles()

    return self end