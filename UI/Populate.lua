local VC = VC

StaticPopupDialogs["VENDORCOLLECTOR_SKIP_CONFIRM_WARNING"] = {
    text        = "|cffff8800Warning:|r Items will be purchased |cffffffffimmediately on click|r with no confirmation prompt.\n\nAre you sure?",
    button1     = "Yes, skip confirmation",
    button2     = "Cancel",
    OnAccept    = function(self)
        VendorCollectorDB.skipConfirm = true
        if self.data and self.data.checkbox then
            self.data.checkbox:SetChecked(true)
        end
    end,
    OnCancel    = function(self)
        VendorCollectorDB.skipConfirm = false
        if self.data and self.data.checkbox then
            self.data.checkbox:SetChecked(false)
        end
    end,
    timeout      = 0,
    whileDead    = false,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["VENDORCOLLECTOR_BUY_CONFIRM"] = {
    text        = "Purchase\n|cffffd700%s|r\nfor %s?",
    button1     = "Buy",
    button2     = "Cancel",
    OnAccept    = function(self)
        local d = self.data
        if not d then return end
        local ok = false
        if BuyMerchantItem then
            ok = pcall(BuyMerchantItem, d.index, 1)
        end
        if not ok and C_MerchantFrame and C_MerchantFrame.BuyItem then
            pcall(C_MerchantFrame.BuyItem, d.index, 1)
        end
        C_Timer.After(1, VendorCollector_PopulatePanel)
    end,
    timeout      = 0,
    whileDead    = false,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function GetMerchantItemData(i, playerGold)
    local name, texture, price, isPurchasable, extendedCost

    if GetMerchantItemInfo then
        local ok, n, t, p, _q, _na, ip, _iu, ec = pcall(GetMerchantItemInfo, i)
        if ok and n then
            name, texture, price, isPurchasable, extendedCost = n, t, p, ip, ec
        end
    end

    if not name and C_MerchantFrame and C_MerchantFrame.GetItemInfo then
        local ok, info = pcall(C_MerchantFrame.GetItemInfo, i)
        if ok and type(info) == "table" and info.name then
            name          = info.name
            texture       = info.texture or info.icon
            price         = info.price
            isPurchasable = info.isPurchasable
            extendedCost  = info.extendedCost or info.hasExtendedCost
        end
    end

    if not name then
        local itemID = GetMerchantItemID and GetMerchantItemID(i)
        if itemID then
            if C_Item and C_Item.GetItemInfo then
                local ok, info = pcall(C_Item.GetItemInfo, itemID)
                if ok and type(info) == "table" then
                    name    = info.name
                    texture = info.iconFileDataID or info.icon
                end
            end
            if not name and GetItemInfo then
                local ok, n, _, _, _, _, _, _, _, _, t = pcall(GetItemInfo, itemID)
                if ok and n then name, texture = n, t end
            end
            isPurchasable = true
        end
    end

    if not name then return nil end

    local tip    = VC.ScanTooltip(i)
    local locked = (isPurchasable == false) or tip.locked

    local canAfford = false
    if not locked then
        if extendedCost and GetMerchantItemCostInfo and GetMerchantItemCostItem then
            local ok, numCost = pcall(GetMerchantItemCostInfo, i)
            canAfford = true
            if ok and numCost and numCost > 0 then
                for ci = 1, numCost do
                    local ok2, _, val, clink = pcall(GetMerchantItemCostItem, i, ci)
                    if ok2 and val and val > 0 then
                        local bal = VC.GetCurrencyBalance(clink)
                        if not bal or bal < val then canAfford = false end
                    end
                end
            end
        elseif price and price == 0 then
            canAfford = true
        elseif price and price > 0 then
            canAfford = playerGold >= price
        end
    end
    local buyable = not locked and canAfford

    local sortPrice = price or 0
    if extendedCost and GetMerchantItemCostInfo and GetMerchantItemCostItem then
        local ok, numCost = pcall(GetMerchantItemCostInfo, i)
        if ok and numCost and numCost > 0 then
            local total = 0
            for ci = 1, numCost do
                local ok2, _, val = pcall(GetMerchantItemCostItem, i, ci)
                if ok2 and val then total = total + val end
            end
            if total > 0 then sortPrice = total end
        end
    end

    return {
        index        = i,
        name         = name,
        texture      = texture,
        price        = price,
        extendedCost = extendedCost,
        locked       = locked,
        canAfford    = canAfford,
        buyable      = buyable,
        sortPrice    = sortPrice,
    }
end

local function FormatItemPrice(item, currencyTotals)
    if item.extendedCost then
        local costParts = {}
        if GetMerchantItemCostInfo and GetMerchantItemCostItem then
            local ok, numCost = pcall(GetMerchantItemCostInfo, item.index)
            if ok and numCost and numCost > 0 then
                for ci = 1, numCost do
                    local ok2, tex, val, _link, cname =
                        pcall(GetMerchantItemCostItem, item.index, ci)
                    if ok2 and val and val > 0 then
                        if currencyTotals then
                            local key = cname or tostring(tex)
                            if not currencyTotals[key] then
                                currencyTotals[key] = { total = 0, texture = tex, name = cname, link = _link }
                            end
                            currencyTotals[key].total = currencyTotals[key].total + val
                        end
                        local ic = tex and ("|T" .. tex .. ":14:14:0:0|t") or ""
                        costParts[#costParts + 1] = ic .. val
                    end
                end
            end
        end
        if #costParts > 0 then
            if not item.buyable then
                return "|cff888888" .. table.concat(costParts, " ") .. "|r"
            else
                return table.concat(costParts, "  ")
            end
        else
            local color = item.buyable and "ffff00" or "888888"
            return "|cff" .. color .. "Token|r"
        end
    elseif item.price and item.price == 0 then
        local color = item.buyable and "00ff00" or "888888"
        return "|cff" .. color .. "Free|r"
    else
        return VC.FormatMoney(item.price, item.canAfford, not item.buyable)
    end
end

function VendorCollector_PopulatePanel()
    local panel = VC.panel
    if not panel then return end

    local numItems   = GetMerchantNumItems and GetMerchantNumItems() or 0
    local playerGold = GetMoney and GetMoney() or 0
    local rows       = VC.rows
    local MAX_ROWS   = VC.MAX_ROWS
    local ROW_H      = VC.ROW_H

    for _, r in ipairs(rows) do r:Hide() end

    local uncollected = {}
    wipe(VC.tooltipCache)

    for i = 1, numItems do
        local tip          = VC.ScanTooltip(i)
        local ensembleName = VC.GetEnsembleName(i)
        if ensembleName then
            if not VC.IsEnsembleCollected(ensembleName) then
                local data = GetMerchantItemData(i, playerGold)
                if data then
                    uncollected[#uncollected + 1] = data
                end
            end
        elseif not tip.notCollectible then
            local itemID = GetMerchantItemID and GetMerchantItemID(i)
            if itemID and VC.IsCollectibleType(itemID) and not VC.IsItemCollected(i) then
                local _, _, _, _, _, classID = GetItemInfoInstant(itemID)
                local prof = tip.requiresProfession
                local wrongProf = classID == 9 and prof and VC.playerProfessions and not VC.playerProfessions[prof]
                if not wrongProf then
                    local data = GetMerchantItemData(i, playerGold)
                    if data then
                        uncollected[#uncollected + 1] = data
                    end
                end
            end
        end
    end

    local function SortItems(a, b)
        if a.buyable ~= b.buyable then return a.buyable end
        if a.sortPrice ~= b.sortPrice then return a.sortPrice < b.sortPrice end
        return a.name < b.name
    end
    table.sort(uncollected, SortItems)

    local totalCost      = 0
    local currencyTotals = {}
    local rowIdx         = 0

    local function PopulateRow(item)
        rowIdx = rowIdx + 1
        if rowIdx > MAX_ROWS then return end
        local row = rows[rowIdx]

        row.merchantIndex = item.index
        row.isLearned     = false
        row.isLocked      = item.locked
        row.itemName      = item.name

        row.icon:SetTexture(item.texture)
        row.icon:Show()

        row.nameLbl:ClearAllPoints()
        row.nameLbl:SetPoint("LEFT",  row.icon, "RIGHT", 4,  0)
        row.nameLbl:SetPoint("RIGHT", row,      "RIGHT", -74, 0)
        row.nameLbl:SetJustifyH("LEFT")

        if item.buyable then
            row.nameLbl:SetText(item.name)
            row.icon:SetDesaturated(false)
            row.icon:SetAlpha(1)
        else
            row.nameLbl:SetText("|cff888888" .. item.name .. "|r")
            row.icon:SetDesaturated(true)
            row.icon:SetAlpha(0.5)
        end

        if row.lockTex  then row.lockTex:SetShown(item.locked) end
        if row.ownedTex then row.ownedTex:SetShown(false)      end

        local priceStr = FormatItemPrice(item, not item.locked and currencyTotals or nil)
        if item.price and item.price > 0 and item.buyable and not item.extendedCost then
            totalCost = totalCost + item.price
        end

        row.priceStr = priceStr
        row.priceLbl:SetText(priceStr)
        row:Show()
    end

    for _, item in ipairs(uncollected) do
        PopulateRow(item)
    end

    if #uncollected == 0 then
        rowIdx = rowIdx + 1
        if rowIdx <= MAX_ROWS then
            local row = rows[rowIdx]
            row.merchantIndex = nil
            row.isLocked      = true
            row.itemName      = nil
            row.priceStr      = nil
            row.icon:SetTexture(nil)
            row.icon:Hide()
            if row.lockTex  then row.lockTex:Hide()  end
            if row.ownedTex then row.ownedTex:Hide() end
            row.nameLbl:ClearAllPoints()
            row.nameLbl:SetPoint("LEFT",  row, "LEFT",  8, 0)
            row.nameLbl:SetPoint("RIGHT", row, "RIGHT", -8, 0)
            row.nameLbl:SetJustifyH("CENTER")
            row.nameLbl:SetText("|cffaaaaaaNothing to collect here|r")
            row.priceLbl:SetText("")
            row:Show()
        end
    end

    panel.content:SetHeight(math.max(1, rowIdx * ROW_H))
    panel._hasItems = #uncollected > 0
    panel.title:SetText("VendorCollector  |cffaaaaaa" .. #uncollected .. " uncollected|r")

    local lines = {}
    local sep = " |cffaaaaaa·|r "

    if totalCost > 0 then
        local have    = playerGold
        local haveCol = have >= totalCost and "|cff44cc44" or "|cffff4444"
        lines[#lines + 1] = "|cffffff00" .. VC.FormatMoneyPlain(totalCost) .. "|r"
            .. sep .. haveCol .. "have " .. VC.FormatMoneyPlain(have) .. "|r"
    end

    for _, data in pairs(currencyTotals) do
        local tag     = data.name or "Currency"
        local balance = VC.GetCurrencyBalance(data.link)
        local line    = "|cffffff00" .. data.total .. "|r " .. tag
        if balance then
            local haveCol = balance >= data.total and "|cff44cc44" or "|cffff4444"
            line = line .. sep .. haveCol .. "have " .. balance .. "|r"
        end
        lines[#lines + 1] = line
    end

    panel.totalLbl:SetText(table.concat(lines, "\n"))

    local footerTextH = panel.totalLbl:GetStringHeight() or 0
    local footerPad   = footerTextH + 10
    if footerTextH == 0 then footerPad = 4 end

    panel.footerLine:ClearAllPoints()
    panel.footerLine:SetPoint("BOTTOMLEFT",  6, footerPad)
    panel.footerLine:SetPoint("BOTTOMRIGHT", -6, footerPad)
    panel.footerLine:SetShown(footerTextH > 0)

    local contentH    = rowIdx * ROW_H
    local panelH      = panel:GetHeight()
    local scrollAreaH = panelH - 44 - footerPad - 4
    local needsScroll = contentH > scrollAreaH

    panel.scrollFrame:ClearAllPoints()
    panel.scrollFrame:SetPoint("TOPLEFT", 6, -44)
    panel.scrollFrame:SetPoint("BOTTOMRIGHT", needsScroll and -26 or -6, footerPad + 4)

    local scrollBar = _G["VCScrollFrameScrollBar"]
    if scrollBar then scrollBar:SetShown(needsScroll) end
end
