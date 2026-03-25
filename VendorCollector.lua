local VC = VC

SLASH_VCD1 = "/vcd"
SlashCmdList["VCD"] = function(input)
    local itemID = tonumber(input)
    if not itemID then
        print("Usage: /vcd <itemID>")
        return
    end

    local function dump(label, t)
        if type(t) ~= "table" then
            print("  [" .. label .. "] =", tostring(t))
            return
        end
        print("  [" .. label .. "]")
        for k, v in pairs(t) do
            if type(v) ~= "table" then
                print("    " .. tostring(k) .. " = " .. tostring(v))
            end
        end
    end

    print("=== /vcd itemID:", itemID, "===")

    -- Item info
    local name, _, _, _, _, classID, subClassID = GetItemInfoInstant(itemID)
    print("  name:", tostring(name), "| classID:", tostring(classID), "| subClassID:", tostring(subClassID))

    -- Toy
    if C_ToyBox and C_ToyBox.GetToyInfo then
        local ok, n, tex, flags, fav, fanfare = pcall(C_ToyBox.GetToyInfo, itemID)
        if ok and n then
            print("  [Toy] name:", tostring(n), "| isFavorite:", tostring(fav), "| hasFanfare:", tostring(fanfare))
            print("  [Toy] PlayerHasToy:", tostring(PlayerHasToy and PlayerHasToy(itemID)))
        end
    end

    -- Heirloom
    if C_Heirloom and C_Heirloom.IsItemHeirloom then
        local ok, result = pcall(C_Heirloom.IsItemHeirloom, itemID)
        if ok and result then
            print("  [Heirloom] IsItemHeirloom: true | PlayerHasHeirloom:", tostring(C_Heirloom.PlayerHasHeirloom(itemID)))
        end
    end

    -- Mount
    if C_MountJournal and C_MountJournal.GetMountFromItem then
        local mountID = C_MountJournal.GetMountFromItem(itemID)
        if mountID and mountID > 0 then
            local mname, spellID, icon, active, isUsable, src, isFav, isFactionSpecific, faction, isFiltered, isCollected = C_MountJournal.GetMountInfoByID(mountID)
            print("  [Mount] mountID:", mountID, "| name:", tostring(mname), "| isCollected:", tostring(isCollected), "| isUsable:", tostring(isUsable))
        end
    end

    -- Pet
    if C_PetJournal and C_PetJournal.GetPetInfoByItemID then
        local _, _, _, _, _, _, _, _, _, _, _, _, speciesID = C_PetJournal.GetPetInfoByItemID(itemID)
        if speciesID then
            local numCollected, limit = C_PetJournal.GetNumCollectedInfo(speciesID)
            print("  [Pet] speciesID:", speciesID, "| numCollected:", tostring(numCollected), "| limit:", tostring(limit))
        end
    end

    -- Transmog
    if C_TransmogCollection and C_TransmogCollection.GetItemInfo then
        local ok, appearanceID, sourceID = pcall(C_TransmogCollection.GetItemInfo, itemID)
        if ok and appearanceID then
            local hasTransmog = C_TransmogCollection.PlayerHasTransmog and C_TransmogCollection.PlayerHasTransmog(itemID)
            print("  [Transmog] appearanceID:", tostring(appearanceID), "| sourceID:", tostring(sourceID), "| PlayerHasTransmog:", tostring(hasTransmog))
        end
    end

    -- Housing Decor
    if C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByItem then
        local ok, base = pcall(C_HousingCatalog.GetCatalogEntryInfoByItem, itemID, false)
        if ok and base and base.entryID then
            local info = C_HousingCatalog.GetCatalogEntryInfoByRecordID(
                base.entryID.entryType, base.entryID.recordID, true
            )
            if info then
                dump("HousingDecor", info)
            end
        end
    end

    print("=== end ===")
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_CLOSED")
eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
eventFrame:RegisterEvent("NEW_TOY_ADDED")
eventFrame:RegisterEvent("TRANSMOG_COLLECTION_UPDATED")
eventFrame:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
eventFrame:RegisterEvent("NEW_MOUNT_ADDED")
eventFrame:RegisterEvent("PET_JOURNAL_LIST_UPDATE")
eventFrame:RegisterEvent("HOUSING_MARKET_AVAILABILITY_UPDATED")
eventFrame:RegisterEvent("HOUSE_DECOR_ADDED_TO_CHEST")
eventFrame:RegisterEvent("PLAYER_LOGIN")
if C_EventUtils and C_EventUtils.IsEventValid then
    if C_EventUtils.IsEventValid("HOUSING_COLLECTION_UPDATED") then
        eventFrame:RegisterEvent("HOUSING_COLLECTION_UPDATED")
    end
    if C_EventUtils.IsEventValid("HOUSING_DECOR_ITEM_LEARNED") then
        eventFrame:RegisterEvent("HOUSING_DECOR_ITEM_LEARNED")
    end
else
    pcall(eventFrame.RegisterEvent, eventFrame, "HOUSING_COLLECTION_UPDATED")
    pcall(eventFrame.RegisterEvent, eventFrame, "HOUSING_DECOR_ITEM_LEARNED")
end

-- warm the housing catalog so ownership fields are populated
local function WarmHousingCatalog()
    if not C_HousingCatalog or not C_HousingCatalog.CreateCatalogSearcher then return end
    local searcher = C_HousingCatalog.CreateCatalogSearcher()
    if not searcher then return end
    if searcher.SetOwnedOnly then searcher:SetOwnedOnly(false) end
    if searcher.SetCollected then searcher:SetCollected(true) end
    if searcher.SetUncollected then searcher:SetUncollected(true) end
    if searcher.SetAutoUpdateOnParamChanges then searcher:SetAutoUpdateOnParamChanges(false) end
    if searcher.SetResultsUpdatedCallback then
        searcher:SetResultsUpdatedCallback(function()
            VC._housingCatalogReady = true
        end)
    end
    if searcher.RunSearch then searcher:RunSearch() end
end

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= VC.ADDON_NAME then return end
        VendorCollectorDB = VendorCollectorDB or {}
        eventFrame:UnregisterEvent("ADDON_LOADED")

    elseif event == "PLAYER_LOGIN" then
        C_Timer.After(0, WarmHousingCatalog)
        eventFrame:UnregisterEvent("PLAYER_LOGIN")

    elseif event == "MERCHANT_SHOW" then
        VC.BuildEnsembleSetCache()
        VC.BuildProfessionCache()
        VC.CreateTabButton()
        VC.CreatePanel()
        if not VC._housingCatalogReady then WarmHousingCatalog() end
        if C_HousingCatalog and C_HousingCatalog.RequestHousingMarketInfoRefresh then
            C_HousingCatalog.RequestHousingMarketInfoRefresh()
        end
        eventFrame._merchantOpenTime = GetTime()
        local panel  = VC.panel
        local tabBtn = VC.tabBtn
        local wantAutoOpen = VendorCollectorDB.autoOpen and not panel:IsShown()
        if tabBtn then
            tabBtn:Show()
            if panel:IsShown() then
                panel.scrollFrame:SetVerticalScroll(0)
            end
        end
        local attempts = 0
        local MIN_ATTEMPTS = 10 -- minimum 0.5s delay for collection APIs to load
        local function WaitAndRepopulate()
            attempts = attempts + 1
            if attempts > 100 then return end -- hard cap at ~5s
            local panel = VC.panel
            if not panel then return end
            -- if not auto-opening, require panel to already be shown
            if not wantAutoOpen and not panel:IsShown() then return end
            -- enforce minimum wait for collection APIs
            if attempts < MIN_ATTEMPTS then
                C_Timer.After(0.05, WaitAndRepopulate)
                return
            end
            local total = GetMerchantNumItems and GetMerchantNumItems() or 0
            for i = 1, total do
                local itemID = GetMerchantItemID and GetMerchantItemID(i)
                if not itemID then
                    C_Timer.After(0.05, WaitAndRepopulate)
                    return
                end
                local name, _, _, _, _, classID = GetItemInfoInstant and GetItemInfoInstant(itemID)
                if not name then
                    C_Timer.After(0.05, WaitAndRepopulate)
                    return
                end
                if classID == 20 and C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByItem then
                    local ok, info = pcall(C_HousingCatalog.GetCatalogEntryInfoByItem, itemID, false)
                    if not ok or not info then
                        C_Timer.After(0.05, WaitAndRepopulate)
                        return
                    end
                end
            end
            VendorCollector_PopulatePanel()
            -- auto-open: show panel after first valid populate
            if wantAutoOpen and not panel:IsShown() and panel._hasItems then
                panel.scrollFrame:SetVerticalScroll(0)
                local mh = MerchantFrame:GetHeight()
                panel:SetHeight(mh > 0 and mh or VC.PANEL_H)
                panel:ClearAllPoints()
                panel:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 0, 0)
                panel:Show()
                PanelTemplates_SelectTab(tabBtn)
                tabBtn:Enable()
                tabBtn:SetNormalFontObject(GameFontHighlightSmall)
                wantAutoOpen = false
            end
        end
        C_Timer.After(0.05, WaitAndRepopulate)

    elseif event == "MERCHANT_CLOSED" then
        local panel  = VC.panel
        local tabBtn = VC.tabBtn
        if panel  then panel:Hide() end
        if tabBtn then
            PanelTemplates_DeselectTab(tabBtn)
            tabBtn:SetNormalFontObject(GameFontNormalSmall)
            tabBtn:Hide()
        end

    elseif event == "GET_ITEM_INFO_RECEIVED" then
        local elapsed = GetTime() - (eventFrame._merchantOpenTime or 0)
        local panel   = VC.panel
        if elapsed < 2 and panel and panel:IsShown() and not eventFrame._pendingRefresh then
            eventFrame._pendingRefresh = true
            C_Timer.After(0.5, function()
                eventFrame._pendingRefresh = nil
                if panel and panel:IsShown() then
                    VendorCollector_PopulatePanel()
                end
            end)
        end

    elseif event == "NEW_TOY_ADDED"
        or event == "TRANSMOG_COLLECTION_UPDATED"
        or event == "MOUNT_JOURNAL_USABILITY_CHANGED"
        or event == "NEW_MOUNT_ADDED"
        or event == "PET_JOURNAL_LIST_UPDATE"
        or event == "HOUSING_MARKET_AVAILABILITY_UPDATED"
        or event == "HOUSE_DECOR_ADDED_TO_CHEST"
        or event == "HOUSING_COLLECTION_UPDATED"
        or event == "HOUSING_DECOR_ITEM_LEARNED"
    then
        local panel = VC.panel
        if panel and panel:IsShown() and not eventFrame._pendingCollectionRefresh then
            eventFrame._pendingCollectionRefresh = true
            C_Timer.After(0.1, function()
                eventFrame._pendingCollectionRefresh = nil
                if panel and panel:IsShown() then
                    VendorCollector_PopulatePanel()
                end
            end)
        end
    end
end)
