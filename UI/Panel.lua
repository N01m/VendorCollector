local VC = VC

VC.rows = {}

VC.CreatePanel = function()
    if VC.panel then return end

    local panel = CreateFrame("Frame", "VendorCollectorPanel", UIParent, "BackdropTemplate")
    panel:SetSize(VC.PANEL_W, VC.PANEL_H)
    panel:SetFrameStrata("DIALOG")

    panel:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    panel:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
    panel:SetBackdropBorderColor(0.4, 0.4, 0.5, 1)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop",  panel.StopMovingOrSizing)
    panel:Hide()

    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.title:SetPoint("TOPLEFT", 10, -10)
    panel.title:SetText("VendorCollector")

    local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        panel:Hide()
        if VC.tabBtn then
            VC.tabBtn._active = false
            PanelTemplates_DeselectTab(VC.tabBtn)
            VC.tabBtn:SetNormalFontObject(GameFontNormalSmall)
        end
    end)

    local settingsBtn = CreateFrame("Button", "VCSettingsButton", panel, "BackdropTemplate")
    settingsBtn:SetSize(50, 16)
    settingsBtn:SetPoint("TOPRIGHT", -26, -10)
    settingsBtn:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    settingsBtn:SetBackdropColor(0.1, 0.1, 0.15, 0.9)
    settingsBtn:SetBackdropBorderColor(0.5, 0.55, 0.65, 0.9)
    settingsBtn:SetScript("OnMouseDown", function(self)
        self:SetBackdropBorderColor(0.7, 0.75, 0.9, 1)
    end)
    settingsBtn:SetScript("OnMouseUp", function(self)
        self:SetBackdropBorderColor(0.5, 0.55, 0.65, 0.9)
    end)
    settingsBtn:SetNormalFontObject("GameFontHighlightSmall")
    settingsBtn:SetHighlightFontObject("GameFontHighlight")
    settingsBtn:SetText("|cffa8d8f0Settings|r")

    local hdrIcon = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdrIcon:SetPoint("TOPLEFT", 8, -30)
    hdrIcon:SetText("|cffaaaaaa Item|r")

    local hdrPrice = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdrPrice:SetPoint("TOPRIGHT", -8, -30)
    hdrPrice:SetText("|cffaaaaaa Price|r")

    local div = panel:CreateTexture(nil, "ARTWORK")
    div:SetHeight(1)
    div:SetPoint("TOPLEFT",  6, -41)
    div:SetPoint("TOPRIGHT", -6, -41)
    div:SetColorTexture(0.3, 0.3, 0.4, 0.8)

    panel.footerLine = panel:CreateTexture(nil, "ARTWORK")
    panel.footerLine:SetHeight(1)
    panel.footerLine:SetPoint("BOTTOMLEFT",  6, 42)
    panel.footerLine:SetPoint("BOTTOMRIGHT", -6, 42)
    panel.footerLine:SetColorTexture(0.3, 0.3, 0.4, 0.8)

    panel.totalLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.totalLbl:SetPoint("BOTTOMLEFT",  10,  6)
    panel.totalLbl:SetPoint("BOTTOMRIGHT", -10, 6)
    panel.totalLbl:SetJustifyH("LEFT")
    panel.totalLbl:SetJustifyV("BOTTOM")
    panel.totalLbl:SetWordWrap(true)
    panel.totalLbl:SetText("")

    local sf = CreateFrame("ScrollFrame", "VCScrollFrame", panel, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     6,  -44)
    sf:SetPoint("BOTTOMRIGHT", -26, 46)
    panel.scrollFrame = sf

    local content = CreateFrame("Frame", nil, sf)
    content:SetWidth(VC.PANEL_W - 42)
    content:SetHeight(1)
    sf:SetScrollChild(content)
    panel.content = content

    local ROW_H  = VC.ROW_H
    local ICON_SZ = VC.ICON_SZ
    local rows   = VC.rows

    for i = 1, VC.MAX_ROWS do
        local row = CreateFrame("Button", nil, content)
        row:SetHeight(ROW_H)
        row:SetPoint("TOPLEFT",  0, -(i - 1) * ROW_H)
        row:SetPoint("TOPRIGHT", 0, -(i - 1) * ROW_H)
        row:Hide()

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(1, 1, 1, i % 2 == 0 and 0.04 or 0)

        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.08)

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(ICON_SZ, ICON_SZ)
        icon:SetPoint("LEFT", 2, 0)
        row.icon = icon

        local lockTex = row:CreateTexture(nil, "OVERLAY")
        lockTex:SetSize(12, 12)
        lockTex:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        lockTex:SetTexture("Interface/Buttons/LockButton-Locked-Up")
        lockTex:Hide()
        row.lockTex = lockTex

        local ownedTex = row:CreateTexture(nil, "OVERLAY")
        ownedTex:SetSize(12, 12)
        ownedTex:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        ownedTex:SetTexture("Interface/RaidFrame/ReadyCheck-Ready")
        ownedTex:Hide()
        row.ownedTex = ownedTex

        local nameLbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameLbl:SetPoint("LEFT",  icon, "RIGHT", 4,  0)
        nameLbl:SetPoint("RIGHT", row,  "RIGHT", -74, 0)
        nameLbl:SetJustifyH("LEFT")
        nameLbl:SetWordWrap(false)
        row.nameLbl = nameLbl

        local priceLbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        priceLbl:SetPoint("RIGHT", -2, 0)
        priceLbl:SetJustifyH("RIGHT")
        row.priceLbl = priceLbl

        row:SetScript("OnClick", function(self)
            if not self.merchantIndex or self.isLocked then return end
            if VendorCollectorDB.skipConfirm then
                local ok = false
                if BuyMerchantItem then
                    ok = pcall(BuyMerchantItem, self.merchantIndex, 1)
                end
                if not ok and C_MerchantFrame and C_MerchantFrame.BuyItem then
                    pcall(C_MerchantFrame.BuyItem, self.merchantIndex, 1)
                end
                C_Timer.After(1, VendorCollector_PopulatePanel)
            else
                local dialog = StaticPopup_Show("VENDORCOLLECTOR_BUY_CONFIRM",
                    self.itemName or "?", self.priceStr or "")
                if dialog then dialog.data = { index = self.merchantIndex } end
            end
        end)
        row:SetScript("OnEnter", function(self)
            if self.merchantIndex then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                pcall(GameTooltip.SetMerchantItem, GameTooltip, self.merchantIndex)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)

        rows[i] = row
    end

    if ElvUI then
        local E = unpack(ElvUI)
        local S = E and E:GetModule("Skins", true)
        if S then
            if S.HandleFrame       then pcall(S.HandleFrame,       S, panel) end
            if S.HandleButton      then pcall(S.HandleButton,      S, settingsBtn) end
            if S.HandleCloseButton then pcall(S.HandleCloseButton, S, closeBtn) end
            if S.HandleScrollBar   then
                local sb = _G["VCScrollFrameScrollBar"]
                if sb then pcall(S.HandleScrollBar, S, sb) end
            end
        end
    end

    local flyout = CreateFrame("Frame", "VCSettingsFlyout", panel, "BackdropTemplate")
    flyout:SetSize(190, 70)
    flyout:SetFrameLevel(panel:GetFrameLevel() + 20)
    flyout:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    flyout:SetBackdropColor(0.05, 0.05, 0.08, 0.98)
    flyout:SetBackdropBorderColor(0.4, 0.4, 0.5, 1)
    flyout:Hide()
    panel:SetScript("OnHide", function() flyout:Hide() end)

    local flyoutClose = CreateFrame("Button", nil, flyout, "UIPanelCloseButton")
    flyoutClose:SetSize(18, 18)
    flyoutClose:SetPoint("TOPRIGHT", -1, -1)
    flyoutClose:SetScript("OnClick", function() flyout:Hide() end)

    local autoChk = CreateFrame("CheckButton", nil, flyout, "UICheckButtonTemplate")
    autoChk:SetSize(18, 18)
    autoChk:SetPoint("TOPLEFT", 8, -8)
    autoChk:SetChecked(VendorCollectorDB.autoOpen or false)
    autoChk:SetScript("OnClick", function(self)
        VendorCollectorDB.autoOpen = self:GetChecked()
    end)
    local autoLbl = flyout:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    autoLbl:SetPoint("LEFT", autoChk, "RIGHT", 2, 0)
    autoLbl:SetText("Auto-open with vendor")

    local skipChk = CreateFrame("CheckButton", nil, flyout, "UICheckButtonTemplate")
    skipChk:SetSize(18, 18)
    skipChk:SetPoint("TOPLEFT", 8, -34)
    skipChk:SetChecked(VendorCollectorDB.skipConfirm or false)
    skipChk:SetScript("OnClick", function(self)
        if self:GetChecked() then
            self:SetChecked(false)
            local d = StaticPopup_Show("VENDORCOLLECTOR_SKIP_CONFIRM_WARNING")
            if d then d.data = { checkbox = self } end
        else
            VendorCollectorDB.skipConfirm = false
        end
    end)
    local skipLbl = flyout:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    skipLbl:SetPoint("LEFT", skipChk, "RIGHT", 2, 0)
    skipLbl:SetText("Skip buy confirmation")
    local skipWarn = flyout:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    skipWarn:SetPoint("TOPLEFT", skipChk, "BOTTOMLEFT", 20, -1)
    skipWarn:SetText("|cffff8800Items buy instantly on click|r")

    if ElvUI then
        local E = unpack(ElvUI)
        local S = E and E:GetModule("Skins", true)
        if S then
            if S.HandleFrame       then pcall(S.HandleFrame,       S, flyout) end
            if S.HandleCloseButton then pcall(S.HandleCloseButton, S, flyoutClose) end
            if S.HandleCheckBox then
                pcall(S.HandleCheckBox, S, autoChk)
                pcall(S.HandleCheckBox, S, skipChk)
            end
        end
    end

    settingsBtn:SetScript("OnClick", function()
        if flyout:IsShown() then
            flyout:Hide()
        else
            flyout:ClearAllPoints()
            flyout:SetPoint("TOPLEFT", panel, "TOPRIGHT", 4, 0)
            autoChk:SetChecked(VendorCollectorDB.autoOpen or false)
            skipChk:SetChecked(VendorCollectorDB.skipConfirm or false)
            flyout:Show()
        end
    end)

    VC.panel = panel
end

VC.CreateTabButton = function()
    if VC.tabBtn then return end

    local tabBtn = CreateFrame("Button", "VCTabButton", MerchantFrame, "PanelTabButtonTemplate")
    tabBtn:SetText("VendorC")
    PanelTemplates_TabResize(tabBtn, 24)
    local tabAnchor = MerchantFrameTab2 or MerchantFrameTab1
    if ElvUI and type(ElvUI) == "table" and unpack(ElvUI) then
        tabBtn:SetPoint("LEFT", tabAnchor, "RIGHT", -5, 0)
    else
        tabBtn:SetPoint("LEFT", tabAnchor, "RIGHT", 1, 0)
    end
    PanelTemplates_DeselectTab(tabBtn)

    if ElvUI then
        local E = unpack(ElvUI)
        local S = E and E:GetModule("Skins", true)
        if S and S.HandleTab then
            pcall(S.HandleTab, S, tabBtn)
        end
    end

    tabBtn:SetScript("OnClick", function(self)
        if not VC.panel then VC.CreatePanel() end
        if VC.panel:IsShown() then
            VC.panel:Hide()
            self._active = false
            local btn = self
            C_Timer.After(0, function()
                PanelTemplates_DeselectTab(btn)
                btn:SetNormalFontObject(GameFontNormalSmall)
            end)
            return
        end
        local mh = MerchantFrame:GetHeight()
        VC.panel:SetHeight(mh > 0 and mh or VC.PANEL_H)
        VC.panel:ClearAllPoints()
        VC.panel:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 0, 0)
        VC.panel:Show()
        VC.panel.scrollFrame:SetVerticalScroll(0)
        VendorCollector_PopulatePanel()
        PanelTemplates_SelectTab(self)
        self:Enable()
        self:SetNormalFontObject(GameFontHighlightSmall)
    end)

    tabBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(tabBtn, "ANCHOR_RIGHT")
        GameTooltip:SetText("VendorCollector", 1, 1, 1)
        GameTooltip:AddLine("Show all uncollected items from this\nvendor across every page.", nil, nil, nil, true)
        GameTooltip:Show()
    end)
    tabBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    VC.tabBtn = tabBtn
end
