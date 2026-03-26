local VC = VC

local ensembleSetCache = nil

VC.BuildEnsembleSetCache = function()
    if ensembleSetCache then return end
    ensembleSetCache = {}
    if not C_TransmogSets or not C_TransmogSets.GetUsableSets then return end
    local ok, sets = pcall(C_TransmogSets.GetUsableSets)
    if not ok or not sets then return end
    for _, setInfo in ipairs(sets) do
        if setInfo.name then
            ensembleSetCache[setInfo.name:lower()] = setInfo.collected or false
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

    if C_MountJournal and C_MountJournal.GetMountFromItem then
        local mountID = C_MountJournal.GetMountFromItem(itemID)
        if mountID and mountID > 0 then return true end
    end

    if C_PetJournal and C_PetJournal.GetPetInfoByItemID then
        local name = C_PetJournal.GetPetInfoByItemID(itemID)
        if name then return true end
    end

    local itemName, _, _, _, _, classID, subClassID = GetItemInfoInstant(itemID)
    if classID == 15 and subClassID == 2 then return true end
    if type(itemName) == "string" and itemName:find("^Illusion:") then return true end

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

    if C_MountJournal and C_MountJournal.GetMountFromItem then
        local mountID = C_MountJournal.GetMountFromItem(itemID)
        if mountID and mountID > 0 then
            local _, _, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
            if isCollected then return true end
        end
    end

    if C_PetJournal and C_PetJournal.GetPetInfoByItemID then
        local _, _, _, _, _, _, _, _, _, _, _, _, speciesID = C_PetJournal.GetPetInfoByItemID(itemID)
        if speciesID then
            local numCollected = C_PetJournal.GetNumCollectedInfo(speciesID)
            if numCollected and numCollected > 0 then return true end
        end
    end

    if C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByItem then
        local ok, base = pcall(C_HousingCatalog.GetCatalogEntryInfoByItem, itemID, false)
        if ok and base and base.entryID then
            local ok2, info = pcall(C_HousingCatalog.GetCatalogEntryInfoByRecordID,
                base.entryID.entryType, base.entryID.recordID, true
            )
            if ok2 and info then
                if type(info.isOwned) == "boolean" then return info.isOwned end
                if type(info.isCollected) == "boolean" then return info.isCollected end
                if info.firstAcquisitionBonus == 0 then return true end
                local qty = (tonumber(info.quantity) or 0) + (tonumber(info.numPlaced) or 0)
                          + (tonumber(info.remainingRedeemable) or 0)
                if qty > 0 and qty < 1000000 then return true end
            end
        end
        -- fallback: parse owned count from item tooltip
        if C_TooltipInfo and C_TooltipInfo.GetOwnedItemByID then
            local ok3, tooltip = pcall(C_TooltipInfo.GetOwnedItemByID, itemID)
            if ok3 and tooltip and tooltip.lines then
                for _, line in ipairs(tooltip.lines) do
                    local lt = line.leftText
                    if lt then
                        local lower = lt:lower()
                        if lower:find("^owned") then
                            local count = tonumber(lt:match("(%d+)"))
                            if count and count > 0 then return true end
                        end
                    end
                end
            end
        end
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
    local cached = ensembleSetCache[setName:lower()]
    if cached == nil then return nil end
    return cached
end
