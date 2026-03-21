local VC = VC

local mountSpellCache  = nil
local mountAllSpells   = nil
local ensembleSetCache = nil

VC.BuildEnsembleSetCache = function()
    if ensembleSetCache then return end
    ensembleSetCache = {}
    if not C_TransmogSets or not C_TransmogSets.GetUsableSets then return end
    local ok, sets = pcall(C_TransmogSets.GetUsableSets)
    if not ok or not sets then return end
    for _, setInfo in ipairs(sets) do
        if setInfo.name and setInfo.setID then
            ensembleSetCache[setInfo.name:lower()] = setInfo.setID
        end
    end
end

VC.BuildProfessionCache = function()
    VC.playerProfessions = {}
    local indices = { GetProfessions() }
    for _, idx in ipairs(indices) do
        if idx then
            local name = GetProfessionInfo(idx)
            if name then VC.playerProfessions[name:lower()] = true end
        end
    end
end

VC.BuildMountCache = function()
    if mountSpellCache then return end
    mountSpellCache = {}
    mountAllSpells  = {}
    local ids = C_MountJournal.GetMountIDs()
    for _, mountID in ipairs(ids) do
        local _, spellID, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
        if spellID then
            mountAllSpells[spellID] = true
            if isCollected then
                mountSpellCache[spellID] = true
            end
        end
    end
end

VC.IsCollectibleType = function(itemID)
    if not itemID then return false end

    if C_ToyBox and C_ToyBox.GetToyInfo then
        local ok, name = pcall(C_ToyBox.GetToyInfo, itemID)
        if ok and name then return true end
    end
    if PlayerHasToy(itemID) then return true end

    if C_Heirloom and C_Heirloom.IsItemHeirloom then
        local ok, result = pcall(C_Heirloom.IsItemHeirloom, itemID)
        if ok and result then return true end
    end
    if C_Heirloom and C_Heirloom.PlayerHasHeirloom(itemID) then return true end

    local _, spellID = GetItemSpell(itemID)
    if spellID and mountAllSpells then
        if mountAllSpells[spellID] then return true end
    end

    local _, _, _, _, _, classID, subClassID = GetItemInfoInstant(itemID)
    if classID == 15 and subClassID == 2 then return true end
    if classID == 9 then return true end

    if C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByItem then
        local ok, info = pcall(C_HousingCatalog.GetCatalogEntryInfoByItem, itemID, false)
        if ok and info then return true end
    end

    if C_TransmogCollection and C_TransmogCollection.GetItemInfo then
        local ok, appearanceID = pcall(C_TransmogCollection.GetItemInfo, itemID)
        if ok and appearanceID then return true end
    end

    return false
end

VC.IsItemCollected = function(merchantIndex)
    local itemID = GetMerchantItemID and GetMerchantItemID(merchantIndex)
    if not itemID then return false end

    if PlayerHasToy(itemID) then return true end
    if C_Heirloom and C_Heirloom.PlayerHasHeirloom(itemID) then return true end

    if C_TransmogCollection and C_TransmogCollection.PlayerHasTransmog then
        local ok, result = pcall(C_TransmogCollection.PlayerHasTransmog, itemID)
        if ok and result then return true end
    end

    local _, spellID = GetItemSpell(itemID)
    if spellID and mountSpellCache and mountSpellCache[spellID] then return true end

    if C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByItem then
        local ok, info = pcall(C_HousingCatalog.GetCatalogEntryInfoByItem, itemID, true)
        if ok and info and info.quantity and info.quantity > 0 then return true end
    end

    local tip = VC.ScanTooltip(merchantIndex)
    if tip.collected then return true end

    return false
end

VC.GetEnsembleName = function(merchantIndex)
    local name
    if GetMerchantItemInfo then
        local ok, n = pcall(GetMerchantItemInfo, merchantIndex)
        if ok and type(n) == "string" then name = n end
    end
    if not name and C_MerchantFrame and C_MerchantFrame.GetItemInfo then
        local ok, info = pcall(C_MerchantFrame.GetItemInfo, merchantIndex)
        if ok and type(info) == "table" then name = info.name end
    end
    if not name then
        local itemID = GetMerchantItemID and GetMerchantItemID(merchantIndex)
        if itemID then
            local ok, n = pcall(GetItemInfo, itemID)
            if ok and type(n) == "string" then name = n end
        end
    end
    if name and name:find("^Ensemble:") then return name end

    if C_TooltipInfo and C_TooltipInfo.GetMerchantItem then
        local ok, data = pcall(C_TooltipInfo.GetMerchantItem, merchantIndex)
        if ok and data and data.lines then
            for _, line in ipairs(data.lines) do
                local lt = line.leftText or ""
                local setName = lt:match("Ensemble:%s*(.+)%s+set%.?$")
                if setName then return "Ensemble: " .. setName end
            end
        end
    end

    return nil
end

VC.IsEnsembleCollected = function(name)
    if not name or not ensembleSetCache then return nil end
    local setName = name:match("^Ensemble:%s*(.+)$")
    if not setName then return nil end
    local setID = ensembleSetCache[setName:lower()]
    if not setID then return nil end
    local ok, items = pcall(C_TransmogSets.GetItems, setID)
    if not ok or not items or #items == 0 then return nil end
    for _, source in ipairs(items) do
        if not source.isCollected then return false end
    end
    return true
end
