--[[ ItemCache ]]

-- watch for new bags being equipped and BuildCache() if it's bag 1-4

-- things to test:
-- disable all addons, does creating an itemmixin data load it?
-- see if one itemmixin is sufficient for everything (use continue bit and see if right item is remembered)


local _,ic = ...

local f = CreateFrame("Frame","IC")

f.cache = {worn={},[0]={},[1]={},[2]={},[3]={},[4]={},unloaded={}}
f.dirty = {worn=true,[0]=true,[1]=true,[2]=true,[3]=true,[4]=true}
f.item = CreateFromMixins(ItemMixin)

f:SetScript("OnEvent",function(self,event,...)
    if self[event] then
        self[event](self,...)
    end
end)
f:RegisterEvent("PLAYER_LOGIN")

function f:PLAYER_LOGIN()
    --f:BuildCache()
    f:CacheItems()
    print("After 0 seconds,",f:CountItemsNotDataCached(),"items are not data cached")
    ic:StartTimer(1,function() print("After 1 second,",f:CountItemsNotDataCached(),"items are not data cached") end)
    ic:StartTimer(2,function() print("After 2 seconds,",f:CountItemsNotDataCached(),"items are not data cached") end)
    f:RegisterEvent("BAG_UPDATE")
    f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
end

function f:BAG_UPDATE(bag)
    f.dirty[bag] = true
    ic:StartTimer(0.5,f.CacheItems)
end

function f:PLAYER_EQUIPMENT_CHANGED()
    f.dirty.worn = true
    ic:StartTimer(0.5,f.CacheItems)
end

function f:CacheItems()
    print("CacheItems",f.dirty.worn and "worn" or "",f.dirty[0] and 0 or "",f.dirty[1] and 1 or "",f.dirty[2] and 2 or "",f.dirty[3] and 3 or "",f.dirty[4] and 4 or "")
    local somethingNeedsLoaded = false
    if f.dirty.worn then
        wipe(f.cache.worn)
        for i=0,19 do
            local link = GetInventoryItemLink("player",i)
            if link then
                f.item:SetItemLink(link)
                local itemID = f.item:GetItemID()
                if f.item:IsItemDataCached() then
                    f.cache.worn[i] = link
                else
                    f.cache.unloaded[itemID] = "worn"
                    somethingNeedsLoaded = true
                end
            end
        end
    end
    for bag=0,4 do
        if f.dirty[bag] then
            wipe(f.cache[bag])
            for slot=1,GetContainerNumSlots(bag) do
                local link = GetContainerItemLink(bag,slot)
                if link then
                    f.item:SetItemLink(link)
                    local itemID = f.item:GetItemID()
                    if f.item:IsItemDataCached() then
                        f.cache[bag][slot] = link
                    else
                        f.cache.unloaded[itemID] = bag
                        somethingNeedsLoaded = true
                    end
                end
            end
        end
    end
    wipe(f.dirty)
    if somethingNeedsLoaded then
        ic:StartTimer(0.5,f.LoadItemData)
    end
end

function f:LoadItemData()
    print("LoadItemData")
    local somethingLoaded = false
    local somethingNeedsLoaded = false
    for itemID,bag in pairs(f.cache.unloaded) do
        f.item:SetItemID(itemID)
        if f.item:IsItemDataCached() then -- if something was loaded that wasn't before
            f.dirty[bag] = true -- flag the bag for re-cacheing
            f.cache.unloaded[itemID] = nil -- remove itemID from unloaded
            somethingLoaded = true
        else -- something is still not data cached
            somethingNeedsLoaded = true
        end
    end
    if somethingNeedsLoaded then -- if anything still needs data cached then come back later to try again
        ic:StartTimer(0.5,f.LoadItemData)
    end
    if somethingLoaded then -- something was cached that wasn't before, cache its bag again
        print("Something loaded")
        f:CacheItems()
    end
end

function f:CountItemsNotDataCached()
    local count = 0
    for k,v in pairs(f.cache.unloaded) do
        count = count + 1
    end
    return count
end
