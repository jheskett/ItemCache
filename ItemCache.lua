--[[ ItemCache ]]

local _,ic = ...

local f = CreateFrame("Frame","IC")

f.cache = {worn={},[0]={},[1]={},[2]={},[3]={},[4]={}}
f.dirty = {worn=true,[0]=true,[1]=true,[2]=true,[3]=true,[4]=true}

f:SetScript("OnEvent",function(self,event,...)
    if self[event] then
        self[event](self,...)
    end
end)
f:RegisterEvent("PLAYER_LOGIN")

function f:PLAYER_LOGIN()
    f:BuildCache()
    -- f:CacheItems()
    -- print(f:ListItemsNotDataCached(),"items are not data cached")
    -- ic:StartTimer(1,function() print("After 1 second,",f:ListItemsNotDataCached(),"items are not data cached") end)
end

function f:BAG_UPDATE(bag)
    f.dirty[bag] = true
    ic:StartTimer(0.5,f.CacheItems)
end

function f:PLAYER_EQUIPMENT_CHANGED(bag)
    f.dirty.worn = true
    ic:StartTimer(0.5,f.CacheItems)
end

function f:BuildCache()
    for i=0,19 do
        if not f.cache.worn[i] then
            f.cache.worn[i] = Item:CreateFromEquipmentSlot(i)
        end
    end
    for bag=0,4 do
        for slot=1,GetContainerNumSlots(bag) do
            if not f.cache[bag][slot] then
                f.cache[bag][slot] = Item:CreateFromBagAndSlot(bag,slot)
            end
        end
    end
end

function f:CacheItems()
    if f.dirty.worn then
        wipe(f.cache.worn)
        for i=0,19 do
            local item = Item:CreateFromEquipmentSlot(i)
            if not item:IsItemEmpty() then
                f.cache.worn[i] = item
            end
        end
    end
    for bag=0,4 do
        if f.dirty[bag] then
            for slot=1,GetContainerNumSlots(bag) do
                local item = Item:CreateFromBagAndSlot(bag,slot)
                if not item:IsItemEmpty() then
                    f.cache[bag][slot] = item
                end
            end
        end
    end
    wipe(f.dirty)
end

function f:ListItemsNotDataCached()
    local count = 0
    for bag,contents in pairs(f.cache) do
        for _,item in pairs(contents) do
            if not item:IsItemDataCached() then
                print("item",item:GetItemID(),"is not data cached")
                count = count + 1
            end
        end
    end
    return count
end
