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

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= VC.ADDON_NAME then return end
        VendorCollectorDB = VendorCollectorDB or {}
        eventFrame:UnregisterEvent("ADDON_LOADED")

    elseif event == "MERCHANT_SHOW" then
        VC.BuildEnsembleSetCache()
        VC.BuildProfessionCache()
        VC.CreateTabButton()
        VC.CreatePanel()
        eventFrame._merchantOpenTime = GetTime()
        local panel  = VC.panel
        local tabBtn = VC.tabBtn
        if tabBtn then
            tabBtn:Show()
            if VendorCollectorDB.autoOpen and not panel:IsShown() then
                C_Timer.After(0, function()
                    panel.scrollFrame:SetVerticalScroll(0)
                    VendorCollector_PopulatePanel()
                    if panel._hasItems then
                        local mh = MerchantFrame:GetHeight()
                        panel:SetHeight(mh > 0 and mh or VC.PANEL_H)
                        panel:ClearAllPoints()
                        panel:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 0, 0)
                        panel:Show()
                        PanelTemplates_SelectTab(tabBtn)
                        tabBtn:Enable()
                        tabBtn:SetNormalFontObject(GameFontHighlightSmall)
                    end
                end)
            elseif panel:IsShown() then
                panel.scrollFrame:SetVerticalScroll(0)
                C_Timer.After(0, VendorCollector_PopulatePanel)
            end
        end

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
    end
end)
