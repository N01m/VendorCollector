local VC = VC

VC.FormatMoneyPlain = function(copper)
    if not copper or copper <= 0 then return "0c" end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    local parts = {}
    if g > 0 then parts[#parts+1] = g .. "g" end
    if s > 0 then parts[#parts+1] = s .. "s" end
    if c > 0 then parts[#parts+1] = c .. "c" end
    if #parts == 0 then parts[#parts+1] = "0c" end
    return table.concat(parts, " ")
end

VC.FormatMoney = function(copper, canAfford, locked)
    if not copper or copper <= 0 then return "|cffaaaaaa—|r" end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    local parts = {}
    if g > 0 then parts[#parts+1] = g .. "g" end
    if s > 0 then parts[#parts+1] = s .. "s" end
    if c > 0 then parts[#parts+1] = c .. "c" end
    if #parts == 0 then parts[#parts+1] = "0c" end
    local str = table.concat(parts, " ")
    if locked then return "|cff888888" .. str .. "|r" end
    return canAfford and ("|cffffd700" .. str .. "|r")
                      or ("|cffff4444" .. str .. "|r")
end

VC.GetCurrencyBalance = function(link)
    if not link then return nil end

    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfoFromLink then
        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfoFromLink, link)
        if ok and info then return info.quantity or info.amount end
    end

    local id = tonumber(link:match("|Hcurrency:(%d+)"))
    if id then
        if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
            local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
            if ok and info then return info.quantity or info.amount end
        end
        if C_Currency and C_Currency.GetCurrencyInfo then
            local ok, info = pcall(C_Currency.GetCurrencyInfo, id)
            if ok and info then return info.quantity or info.amount end
        end
    end

    local itemID = tonumber(link:match("|Hitem:(%d+)"))
    if itemID and GetItemCount then
        local ok, count = pcall(GetItemCount, itemID, true)
        if ok and count then return count end
    end

    return nil
end
