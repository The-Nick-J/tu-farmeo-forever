local _, addon = ...
local spots = addon.spots
local db, selected, started, pending
local gold = {1, .78, .42}
local function panel(parent, w, h)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(w, h)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 14,
        insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    frame:SetBackdropColor(.08, .065, .045, .96)
    frame:SetBackdropBorderColor(.62, .46, .22)
    return frame
end

local function rate(spot)
    local seconds, direct, auction = 0, 0, 0
    local sessions = db.sessions[spot.id] or {}
    for _, entry in ipairs(sessions) do
        seconds = seconds + entry.seconds
        direct = direct + entry.direct
        auction = auction + entry.auction
    end
    if seconds == 0 then return "Sin medir" end
    local result = ("%.2f oro/h directo y vendedor"):format(direct * 3600 / seconds)
    if auction > 0 then
        result = result .. ("\n%.2f oro/h con AH estimada"):format((direct + auction) * 3600 / seconds)
    end
    return result .. ("\n%d sesiones · %.1f min"):format(#sessions, seconds / 60)
end

local function makeLabel(parent, font, x, y, width)
    local label = parent:CreateFontString(nil, "OVERLAY", font)
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width)
    label:SetJustifyH("LEFT")
    return label
end

local function button(parent, title, width, x, y, callback)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 24)
    b:SetPoint("BOTTOMLEFT", x, y)
    b:SetText(title)
    b:SetScript("OnClick", callback)
    return b
end

local hud, title, details, stats, timer, startButton, nextButton, editor
local function refresh()
    local spot = spots[selected]
    title:SetText(spot.name)
    details:SetText(("%s · Nv. %s\n\n%s\n%s"):format(spot.zone, spot.level, spot.target, spot.loot))
    stats:SetText(rate(spot))
    startButton:SetText(started and "Detener" or "Iniciar")
    startButton:SetEnabled(not pending)
    nextButton:SetEnabled(not started and not pending)
    timer:SetText(started and ("%02d:%02d"):format(
        math.floor((GetTime() - started) / 60), math.floor(GetTime() - started) % 60
    ) or (pending and "Sesión por guardar" or "Sesión lista"))
end

local function selectSpot(index)
    if not started and not pending then
        selected = index
        db.selected = index
    end
    hud:Show()
    refresh()
end

local function goldInput(box)
    local s = box:GetText():match("^%s*(.-)%s*$")
    if s == "" then return 0 end
    s = s:gsub(",", ".")
    if not s:match("^%d+%.?%d*$") then return end
    local value = tonumber(s)
    if value and value <= 100000000 then return math.floor(value * 10000 + .5) / 10000 end
end

local function buildEditor()
    editor = panel(UIParent, 290, 162)
    editor:SetPoint("CENTER")
    editor:SetFrameStrata("DIALOG")
    editor:EnableMouse(true)
    makeLabel(editor, "GameFontNormalLarge", 14, -12, 260):SetText("Guardar sesión")
    makeLabel(editor, "GameFontHighlightSmall", 14, -45, 160):SetText("Directo + vendedor (oro)")
    makeLabel(editor, "GameFontHighlightSmall", 14, -73, 160):SetText("AH neta estimada (oro)")
    local function input(y)
        local box = CreateFrame("EditBox", nil, editor, "InputBoxTemplate")
        box:SetSize(76, 22)
        box:SetPoint("TOPRIGHT", -17, y)
        box:SetAutoFocus(false)
        box:SetMaxLetters(16)
        return box
    end
    local direct, auction = input(-39), input(-67)
    local hint = makeLabel(editor, "GameFontHighlightSmall", 14, -103, 260)
    editor:SetScript("OnShow", function()
        direct:SetText("")
        auction:SetText("")
        hint:SetText("Ejemplo: 0,75 equivale a 75 de plata.")
    end)
    button(editor, "Guardar", 105, 14, 12, function()
        local a, b = goldInput(direct), goldInput(auction)
        if not a or not b then
            hint:SetText("Ingresa cantidades válidas en oro.")
            return
        end
        local key = spots[selected].id
        db.sessions[key] = db.sessions[key] or {}
        table.insert(db.sessions[key], {seconds = pending, direct = a, auction = b})
        pending = nil
        editor:Hide()
        refresh()
    end)
    button(editor, "Descartar", 105, 130, 12, function()
        pending = nil
        editor:Hide()
        refresh()
    end)
    editor:Hide()
end

local function buildHUD()
    hud = panel(UIParent, 310, 233)
    hud:SetFrameStrata("MEDIUM")
    hud:SetPoint("RIGHT", -40, 40)
    hud:SetClampedToScreen(true)
    hud:SetMovable(true)
    hud:EnableMouse(true)
    hud:RegisterForDrag("LeftButton")
    hud:SetScript("OnDragStart", hud.StartMoving)
    hud:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        if x and y then
            db.x, db.y = x - UIParent:GetWidth() / 2, y - UIParent:GetHeight() / 2
        end
    end)
    if db.x and db.y then
        hud:ClearAllPoints()
        hud:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)
    end
    title = makeLabel(hud, "GameFontNormalLarge", 14, -13, 249)
    details = makeLabel(hud, "GameFontHighlightSmall", 14, -43, 282)
    details:SetSpacing(3)
    stats = makeLabel(hud, "GameFontNormalSmall", 14, -141, 282)
    timer = makeLabel(hud, "GameFontHighlightSmall", 14, -182, 282)
    local close = CreateFrame("Button", nil, hud, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -2)
    startButton = button(hud, "Iniciar", 109, 14, 11, function()
        if started then
            pending = math.max(1, math.floor(GetTime() - started + .5))
            started = nil
            editor:Show()
        else
            started = GetTime()
        end
        refresh()
    end)
    nextButton = button(hud, "Siguiente", 109, 135, 11, function()
        selectSpot(selected % #spots + 1)
    end)
    local tick = 0
    hud:SetScript("OnUpdate", function(_, elapsed)
        if not started then return end
        tick = tick + elapsed
        if tick >= .25 then
            tick = 0
            local seconds = math.floor(GetTime() - started)
            timer:SetText(("%02d:%02d"):format(math.floor(seconds / 60), seconds % 60))
        end
    end)
    hud:Hide()
    refresh()
end

local function buildMap()
    local map = WorldMapFrame
    if not map or not map.GetCanvas then return false end
    local canvas = map:GetCanvas()
    if not canvas then return false end
    local overlay = CreateFrame("Frame", nil, canvas)
    overlay:SetAllPoints()
    overlay:EnableMouse(false)
    local watcher = CreateFrame("Frame", nil, map)
    local owner = CreateFrame("Frame", nil, map)
    owner:SetSize(1, 1)
    owner:SetPoint("TOPRIGHT")
    local groups = {}
    local visibleMap, lastWidth, lastHeight, lastStitched, lastLevel, hovered

    local function hideTooltip()
        if GameTooltip:IsOwned(owner) then GameTooltip:Hide() end
        hovered = nil
    end

    local function tooltip(index)
        local spot = spots[index]
        GameTooltip:SetOwner(owner, "ANCHOR_CURSOR")
        GameTooltip:SetText(spot.name, unpack(gold))
        GameTooltip:AddLine(("Nivel recomendado: %s · V1.2 pág. %d"):format(spot.level, spot.page), .85, .79, .65, true)
        GameTooltip:AddLine(spot.target, 1, 1, 1, true)
        GameTooltip:AddLine(spot.loot, .8, .9, 1, true)
        for line in rate(spot):gmatch("[^\n]+") do
            GameTooltip:AddLine(line, .9, .78, .45)
        end
        GameTooltip:AddLine("Pulsa el marcador para abrir el HUD.", .75, .75, .75)
        GameTooltip:Show()
    end

    local bands = 30
    for index, spot in ipairs(spots) do
        local group = CreateFrame("Frame", nil, overlay)
        group:SetAllPoints()
        group:Hide()
        group.regions = {}
        groups[index] = group
        for _, area in ipairs(spot.areas) do
            local region = {coords = area, strips = {}}
            table.insert(group.regions, region)
            for n = 1, bands do
                local strip = group:CreateTexture(nil, "ARTWORK")
                strip:SetColorTexture(spot.color[1], spot.color[2], spot.color[3], .42)
                region.strips[n] = strip
            end
            local marker = CreateFrame("Button", nil, group)
            marker:SetSize(17, 17)
            marker:SetNormalTexture("Interface\\MoneyFrame\\UI-GoldIcon")
            marker:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
            marker:SetScript("OnClick", function() selectSpot(index) end)
            marker:SetScript("OnEnter", function()
                hovered = index
                tooltip(index)
            end)
            marker:SetScript("OnLeave", hideTooltip)
            region.marker = marker
        end
    end

    local function project(api, sourceMap, mapID, x, y)
        if sourceMap == mapID then return x, y end
        if not api or not api.WorldFromMap or not api.MapFromWorld then return end
        local u, v = api.WorldFromMap(sourceMap, x, y)
        if u and v then return api.MapFromWorld(mapID, u, v) end
    end

    local function layout(mapID, width, height, api, level)
        overlay:SetFrameLevel(level)
        for index, group in ipairs(groups) do
            local sourceMap = spots[index].map
            group:SetFrameLevel(level + 1)
            group:SetShown(sourceMap == mapID or api ~= nil)
            if group:IsShown() then
                for _, region in ipairs(group.regions) do
                    local cx, cy, rawRX, rawRY = unpack(region.coords)
                    local x, y = project(api, sourceMap, mapID, cx, cy)
                    local edgeX, edgeY = project(api, sourceMap, mapID, cx + rawRX, cy + rawRY)
                    local rx = x and edgeX and math.abs(edgeX - x)
                    local ry = y and edgeY and math.abs(edgeY - y)
                    local valid = rx and ry and rx > 0 and ry > 0
                    region.projected = valid and {x, y, rx, ry} or nil
                    region.marker:SetShown(not not valid)
                    region.marker:SetFrameLevel(level + 2)
                    for _, strip in ipairs(region.strips) do strip:SetShown(not not valid) end
                    if valid then
                        region.marker:ClearAllPoints()
                        region.marker:SetPoint("CENTER", overlay, "TOPLEFT", x * width, -y * height)
                        for n, strip in ipairs(region.strips) do
                            local fraction = (2 * n - 1) / bands - 1
                            local halfWidth = rx * math.sqrt(1 - fraction * fraction)
                            strip:ClearAllPoints()
                            strip:SetPoint("TOPLEFT", overlay, "TOPLEFT",
                                (x - halfWidth) * width, -(y + ry * (fraction - 1 / bands)) * height)
                            strip:SetSize(2 * halfWidth * width, 2 * ry * height / bands + .05)
                        end
                    end
                end
            end
        end
        hideTooltip()
    end

    local elapsedTotal = 0
    watcher:SetScript("OnUpdate", function(_, elapsed)
        elapsedTotal = elapsedTotal + elapsed
        if elapsedTotal < .05 then return end
        elapsedTotal = 0
        local mapID = map:GetMapID()
        local width, height = canvas:GetSize()
        if not mapID or width <= 0 or height <= 0 then return end
        local api = _G.OpenMapAPI
        local stitched = api and api.IsStitched and api.IsStitched()
        local artLevel = stitched and api.ArtTopLevel and api.ArtTopLevel()
        local level = math.max(canvas:GetFrameLevel() + 4, artLevel and artLevel + 1 or 0)
        if visibleMap ~= mapID or lastWidth ~= width or lastHeight ~= height
            or lastStitched ~= stitched or lastLevel ~= level then
            visibleMap, lastWidth, lastHeight, lastStitched, lastLevel = mapID, width, height, stitched, level
            layout(mapID, width, height, stitched and api or nil, level)
        end
        if not map.GetNormalizedCursorPosition then return end
        local x, y
        if stitched and api.CursorPosition and api.MapFromWorld then
            local u, v = api.CursorPosition()
            if u and v then x, y = api.MapFromWorld(mapID, u, v) end
        elseif not map.IsCanvasMouseFocus or map:IsCanvasMouseFocus() then
            x, y = map:GetNormalizedCursorPosition()
        end
        local hit
        for index, group in ipairs(groups) do
            if group:IsShown() then
                for _, region in ipairs(group.regions) do
                    local cx, cy, rx, ry
                    if region.projected then cx, cy, rx, ry = unpack(region.projected) end
                    if cx and (region.marker:IsMouseOver() or (x and y and
                        ((x - cx) / rx)^2 + ((y - cy) / ry)^2 <= 1)) then
                        hit = index
                        break
                    end
                end
            end
            if hit then break end
        end
        if hit ~= hovered then
            hideTooltip()
            if hit and (not GameTooltip:IsShown() or GameTooltip:IsOwned(owner)) then
                hovered = hit
                tooltip(hit)
            end
        end
    end)
    watcher:SetScript("OnHide", hideTooltip)
    return true
end

local init = CreateFrame("Frame")
init:RegisterEvent("ADDON_LOADED")
init:RegisterEvent("PLAYER_LOGIN")
local mapReady
init:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == "TuFarmeoForever" then
        TuFarmeoForeverDB = TuFarmeoForeverDB or {}
        db = TuFarmeoForeverDB
        db.sessions = db.sessions or {}
        selected = spots[db.selected or 0] and db.selected or 1
        buildEditor()
        buildHUD()
        SLASH_TUFARMEOFOREVER1 = "/tf"
        SlashCmdList.TUFARMEOFOREVER = function()
            if hud:IsShown() then hud:Hide() else hud:Show(); refresh() end
        end
    end
    if db and not mapReady then mapReady = buildMap() end
    if mapReady then init:UnregisterAllEvents() end
end)
