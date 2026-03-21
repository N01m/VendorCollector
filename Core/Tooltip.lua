local VC = VC

local COLLECTED_LOWER   = COLLECTED and COLLECTED:lower() or "collected"
local IN_COLLECTION_STR = "in collection"

local function TextIndicatesCollected(text)
    if not text or text == "" then return false end
    local lower = text:lower()
    if lower == COLLECTED_LOWER
        or lower == IN_COLLECTION_STR
        or lower:find("^collected")        ~= nil
        or lower:find("^already known")    ~= nil
        or lower:find("^already collect")  ~= nil
        or lower:find("^already learned")  ~= nil
        or lower:find("^known$")           ~= nil
        or lower:find("^maximum.*already") ~= nil then
        return true
    end
    if lower:find("^owned:") then
        local count = tonumber(lower:match("^owned:%s*(%d+)"))
        if count and count > 0 then return true end
    end
    return false
end

local scanTip = CreateFrame("GameTooltip", "VCScanTooltip", nil, "GameTooltipTemplate")
scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

VC.tooltipCache = {}

VC.ScanTooltip = function(slot)
    local tooltipCache = VC.tooltipCache
    if tooltipCache[slot] then return tooltipCache[slot] end

    local result = { collected = false, locked = false, notCollectible = false, isDecor = false, requiresProfession = nil }

    if C_TooltipInfo and C_TooltipInfo.GetMerchantItem then
        local ok, data = pcall(C_TooltipInfo.GetMerchantItem, slot)
        if ok and data and data.lines then
            for _, line in ipairs(data.lines) do
                if TextIndicatesCollected(line.leftText)
                or TextIndicatesCollected(line.rightText) then
                    result.collected = true
                end
                local lt = (line.leftText or ""):lower()
                local rt = (line.rightText or ""):lower()
                local ownedText = lt:find("^owned") and (lt .. " " .. rt) or nil
                if ownedText then
                    local count = tonumber(ownedText:match("owned:?%s*(%d+)"))
                    if count and count > 0 then result.collected = true end
                end
                if lt == "crafting reagent" then
                    result.notCollectible = true
                end
                if lt == "housing decor" then
                    result.isDecor = true
                end
                local c = line.leftColor
                if c and (c.r or 0) > 0.7 and (c.g or 0) < 0.35 then
                    if lt:find("^requires") then
                        result.locked = true
                        local prof = lt:match("^requires ([^%(]+)")
                        if prof then
                            prof = prof:match("^(.-)%s*$")
                            if prof ~= "" and not prof:match("^level %d") then
                                result.requiresProfession = prof
                            end
                        end
                    end
                end
            end
        end
    end

    if not result.collected or not result.locked or not result.notCollectible then
        local ok = pcall(function()
            scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
            scanTip:ClearLines()
            scanTip:SetMerchantItem(slot)
        end)
        if ok then
            for i = 1, scanTip:NumLines() do
                local L = _G["VCScanTooltipTextLeft"  .. i]
                local R = _G["VCScanTooltipTextRight" .. i]
                local lText = L and L:GetText() or ""
                local rText = R and R:GetText() or ""
                if not result.collected then
                    if TextIndicatesCollected(lText)
                    or TextIndicatesCollected(rText) then
                        result.collected = true
                    end
                    local lLow = lText:lower()
                    if lLow:find("^owned") then
                        local combined = lLow .. " " .. rText:lower()
                        local count = tonumber(combined:match("owned:?%s*(%d+)"))
                        if count and count > 0 then result.collected = true end
                    end
                end
                local lLow = lText:lower()
                if not result.isDecor and lLow == "housing decor" then
                    result.isDecor = true
                end
                if not result.notCollectible and lLow == "crafting reagent" then
                    result.notCollectible = true
                end
                if not result.locked and L then
                    local r, g = L:GetTextColor()
                    if r and r > 0.7 and (g or 0) < 0.35 then
                        local lLow2 = lText:lower()
                        if lLow2:find("^requires") then
                            result.locked = true
                            local prof = lLow2:match("^requires ([^%(]+)")
                            if prof then
                                prof = prof:match("^(.-)%s*$")
                                if prof ~= "" and not prof:match("^level %d") then
                                    result.requiresProfession = prof
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    tooltipCache[slot] = result
    return result
end
