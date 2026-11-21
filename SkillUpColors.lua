-- Skill-Up Colors
-- Colors recipe names in the game's profession window by skill-up chance,
-- the same colors as the little arrows next to them:
--   orange = always a skill point, yellow = usually, green = sometimes.
-- Recipes that give no more points (gray) are left as the game shows them.

-- ---------------------------------------------------------------------
-- Settings: change these to true/false as you like.
local COLOR_LIST   = true   -- the recipe names in the list on the left
local COLOR_COUNT  = true   -- the "[2]" after a name (how many you can make), same color
local COLOR_TITLE  = true   -- the big recipe name on the right (normally its rarity color)
local COLOR_GRAY   = false  -- also turn names that give no skill-ups gray

-- The colors (red, green, blue from 0 to 1).
local COLORS = {
    optimal = { r = 1.00, g = 0.50, b = 0.25 },  -- orange
    medium  = { r = 1.00, g = 1.00, b = 0.00 },  -- yellow
    easy    = { r = 0.25, g = 0.75, b = 0.25 },  -- green
    trivial = { r = 0.50, g = 0.50, b = 0.50 },  -- gray
}
-- ---------------------------------------------------------------------

local function colorFor(recipeInfo)
    if type(recipeInfo) ~= "table" then return nil end
    local d = recipeInfo.relativeDifficulty
    local E = Enum and Enum.TradeskillRelativeDifficulty or {}
    if d == (E.Optimal or 0) then return COLORS.optimal end
    if d == (E.Medium or 1) then return COLORS.medium end
    if d == (E.Easy or 2) then return COLORS.easy end
    if COLOR_GRAY and d == (E.Trivial or 3) then return COLORS.trivial end
    return nil
end

-- Keeps a font string in our color: when the game sets a color (or a new
-- font, or text with a color code in it), we put ours back on top.
local function lock(fs)
    if fs.__sucLocked then return end
    fs.__sucLocked = true
    local busy = false
    local function reapply(self)
        if busy then return end
        local c = self.__sucColor
        if not c then return end
        busy = true
        self:SetTextColor(c.r, c.g, c.b)
        busy = false
    end
    hooksecurefunc(fs, "SetTextColor", reapply)
    hooksecurefunc(fs, "SetFontObject", reapply)
    if fs.SetVertexColor then hooksecurefunc(fs, "SetVertexColor", reapply) end
    hooksecurefunc(fs, "SetText", function(self, text)
        if busy or not self.__sucColor or type(text) ~= "string" then return end
        if text:find("|c") then
            busy = true
            self:SetText((text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")))
            busy = false
        end
        reapply(self)
    end)
end

local function paint(fs, color)
    if not fs then return end
    if not fs.__sucDefault then fs.__sucDefault = { fs:GetTextColor() } end
    lock(fs)
    fs.__sucColor = color
    if color then
        fs:SetTextColor(color.r, color.g, color.b)
    else
        -- A reused line that now shows a recipe we don't color: back to the game's color.
        local d = fs.__sucDefault
        fs:SetTextColor(d[1], d[2], d[3], d[4])
    end
end

-- The recipe's current info: asked fresh from the game, since the copy the
-- list holds can be from before the skill-up data came in.
local function freshInfo(info)
    if Professions and Professions.GetHighestLearnedRecipe then
        info = Professions.GetHighestLearnedRecipe(info) or info
    end
    local id = info and info.recipeID
    if id and C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
        local fresh = C_TradeSkillUI.GetRecipeInfo(id)
        if type(fresh) == "table" and fresh.relativeDifficulty ~= nil then return fresh end
    end
    return info
end

local function paintRow(frame, node)
    if not frame or not frame.Label then return end
    node = node or (frame.GetElementData and frame:GetElementData())
    local data = node and node.GetData and node:GetData()
    if not data or not data.recipeInfo then return end
    local color = colorFor(freshInfo(data.recipeInfo))
    paint(frame.Label, color)
    -- The "[2]" after the name (how many you can make) in the same color.
    if COLOR_COUNT then
        local count = frame.Count
        if not count and frame.GetRegions then
            -- Not under the usual name: the line's other text.
            for _, region in ipairs({ frame:GetRegions() }) do
                if region ~= frame.Label and region.GetObjectType and region:GetObjectType() == "FontString" then
                    count = region
                    break
                end
            end
            frame.Count = count
        end
        if count then paint(count, color) end
    end
end

-- The recipe list on the left.
local listBox
local function repaintList()
    if listBox and listBox.ForEachFrame then
        listBox:ForEachFrame(function(frame) paintRow(frame) end)
    end
end

local function setupList(page)
    local list = page.RecipeList
    local box = list and list.ScrollBox
    if not box or not ScrollUtil or not ScrollUtil.AddInitializedFrameCallback then return end
    listBox = box
    ScrollUtil.AddInitializedFrameCallback(box, function(_, frame, node)
        paintRow(frame, node)
        -- Once more a moment later, after the game has finished with the line.
        C_Timer.After(0, function() paintRow(frame) end)
    end, "SkillUpColors", true)

    -- Repaint what's shown whenever the game updates the recipe data.
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_DATA_SOURCE_CHANGED", "SKILL_LINES_CHANGED" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", function()
        C_Timer.After(0, repaintList)
        C_Timer.After(0.3, repaintList)
    end)
    if ProfessionsFrame and ProfessionsFrame.HookScript then
        ProfessionsFrame:HookScript("OnShow", function() C_Timer.After(0.1, repaintList) end)
    end
end

-- The recipe's name on the right.
local function setupTitle(page)
    local form = page.SchematicForm
    if not form or not form.OutputText or type(form.Init) ~= "function" then return end
    hooksecurefunc(form, "Init", function(self, recipeInfo)
        recipeInfo = recipeInfo or (self.GetRecipeInfo and self:GetRecipeInfo())
        paint(self.OutputText, colorFor(recipeInfo))
    end)
end

local function setup()
    local page = ProfessionsFrame and ProfessionsFrame.CraftingPage
    if not page then return end
    if COLOR_LIST then setupList(page) end
    if COLOR_TITLE then setupTitle(page) end
end

if EventUtil and EventUtil.ContinueOnAddOnLoaded then
    EventUtil.ContinueOnAddOnLoaded("Blizzard_Professions", setup)
else
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, _, name)
        if name == "Blizzard_Professions" then
            self:UnregisterEvent("ADDON_LOADED")
            setup()
        end
    end)
end
