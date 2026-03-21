local VC = VC

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
        VC.BuildMountCache()
        VC.BuildEnsembleSetCache()
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
