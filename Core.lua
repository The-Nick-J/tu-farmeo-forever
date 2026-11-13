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
    local visibleMap, lastWidth, lastHeight, lastStitched, lastLevel, lastScale, hovered
    local toggle = CreateFrame("CheckButton", nil, map, "UICheckButtonTemplate")
    toggle:SetSize(24, 24)
    toggle:SetPoint("TOPRIGHT", -50, -3)
    local toggleLabel = toggle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    toggleLabel:SetPoint("RIGHT", toggle, "LEFT", -2, 0)
    toggleLabel:SetText("Farmeos")
    toggle:SetChecked(not db.hideMapSpots)

    local function hideTooltip()
        if GameTooltip:IsOwned(owner) then GameTooltip:Hide() end
        hovered = nil
    end
    toggle:SetScript("OnClick", function(self)
        db.hideMapSpots = not self:GetChecked()
        overlay:SetShown(not db.hideMapSpots)
        hideTooltip()
    end)
    overlay:SetShown(not db.hideMapSpots)

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

    local bands = 64
    for index, spot in ipairs(spots) do
        local group = CreateFrame("Frame", nil, overlay)
        group:SetAllPoints()
        group:Hide()
        group.regions = {}
        groups[index] = group
        for areaIndex, area in ipairs(spot.areas) do
            local region = {coords = area, strips = {}, borders = {}, outline = spot.outlines and spot.outlines[areaIndex]}
            if not region.outline then
                region.outline = {}
                for n = 1, 32 do
                    local angle = n * 2 * math.pi / 32
                    region.outline[n] = {area[1] + area[3] * math.cos(angle), area[2] + area[4] * math.sin(angle)}
                end
            end
            for n = 1, #region.outline do
                local line = group:CreateLine(nil, "OVERLAY")
                line:SetColorTexture(spot.color[1], spot.color[2], spot.color[3], .95)
                region.borders[n] = line
            end
            table.insert(group.regions, region)
            for n = 1, bands * 2 do
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

    local function crossings(points, y)
        local xs = {}
        for n, a in ipairs(points) do
            local b = points[n % #points + 1]
            if (a[2] > y) ~= (b[2] > y) then
                xs[#xs + 1] = a[1] + (y - a[2]) * (b[1] - a[1]) / (b[2] - a[2])
            end
        end
        table.sort(xs)
        return xs
    end

    local function layout(mapID, width, height, api, level, scale, viewWidth)
        overlay:SetFrameLevel(level)
        for index, group in ipairs(groups) do
            local sourceMap = spots[index].map
            group:SetFrameLevel(level + 1)
            group:SetShown(sourceMap == mapID or api ~= nil)
            if group:IsShown() then
                for areaIndex, region in ipairs(group.regions) do
                    local cx, cy, rawRX, rawRY = unpack(region.coords)
                    local x, y = project(api, sourceMap, mapID, cx, cy)
                    local edgeX, edgeY = project(api, sourceMap, mapID, cx + rawRX, cy + rawRY)
                    local rx = x and edgeX and math.abs(edgeX - x)
                    local ry = y and edgeY and math.abs(edgeY - y)
                    local valid = rx and ry and rx > 0 and ry > 0
                    local detailed = valid and (not api or width * scale * rx / rawRX >= viewWidth * .8)
                    region.projected = nil
                    region.marker:SetShown(not not (valid and (detailed or areaIndex == 1)))
                    region.marker:SetSize(14 / scale, 14 / scale)
                    region.marker:SetFrameLevel(level + 2)
                    for _, strip in ipairs(region.strips) do strip:Hide() end
                    for _, line in ipairs(region.borders) do line:Hide() end
                    if valid then
                        region.marker:ClearAllPoints()
                        region.marker:SetPoint("CENTER", overlay, "TOPLEFT", x * width, -y * height)
                    end
                    if detailed then
                        local points, top, bottom = {}, math.huge, -math.huge
                        for n, point in ipairs(region.outline) do
                            local px = x + (point[1] - cx) * rx / rawRX
                            local py = y + (point[2] - cy) * ry / rawRY
                            points[n] = {px, py}
                            top, bottom = math.min(top, py), math.max(bottom, py)
                        end
                        region.projected = points
                        local step, used = (bottom - top) / bands, 0
                        for n = 1, bands do
                            local py = top + (n - 1) * step
                            local xs = crossings(points, py + step / 2)
                            for i = 1, #xs - 1, 2 do
                                used = used + 1
                                local strip = region.strips[used]
                                if strip then
                                    strip:ClearAllPoints()
                                    strip:SetPoint("TOPLEFT", overlay, "TOPLEFT", xs[i] * width, -py * height)
                                    strip:SetSize((xs[i + 1] - xs[i]) * width, step * height)
                                    strip:Show()
                                end
                            end
                        end
                        for n, a in ipairs(points) do
                            local b = points[n % #points + 1]
                            local line = region.borders[n]
                            line:SetThickness(2 / scale)
                            line:SetStartPoint("TOPLEFT", overlay, a[1] * width, -a[2] * height)
                            line:SetEndPoint("TOPLEFT", overlay, b[1] * width, -b[2] * height)
                            line:Show()
                        end
                    end
                end
            end
        end
        hideTooltip()
    end

    local elapsedTotal = 0
    watcher:SetScript("OnUpdate", function(_, elapsed)
        if db.hideMapSpots then return end
        elapsedTotal = elapsedTotal + elapsed
        if elapsedTotal < .05 then return end
        elapsedTotal = 0
        local mapID = map:GetMapID()
        local width, height = canvas:GetSize()
        local view = map.ScrollContainer or map
        local scale = canvas:GetEffectiveScale() / view:GetEffectiveScale()
        if scale <= 0 then return end
        if not mapID or width <= 0 or height <= 0 then return end
        local api = _G.OpenMapAPI
        local stitched = api and api.IsStitched and api.IsStitched()
        local artLevel = stitched and api.ArtTopLevel and api.ArtTopLevel()
        local level = math.max(canvas:GetFrameLevel() + 4, artLevel and artLevel + 1 or 0)
        if visibleMap ~= mapID or lastWidth ~= width or lastHeight ~= height
            or lastStitched ~= stitched or lastLevel ~= level or lastScale ~= scale then
            visibleMap, lastWidth, lastHeight, lastStitched, lastLevel = mapID, width, height, stitched, level
            lastScale = scale
            layout(mapID, width, height, stitched and api or nil, level, view:GetWidth())
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
                    local inside
                    if x and y and region.projected then
                        local xs = crossings(region.projected, y)
                        for n = 1, #xs - 1, 2 do
                            if x >= xs[n] and x <= xs[n + 1] then inside = true; break end
                        end
                    end
                    if inside or (region.marker:IsVisible() and region.marker:IsMouseOver()) then
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
