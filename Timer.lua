local _,s = ...

s.timerFrame = CreateFrame("Frame", nil, UIParent)
s.timerFrame:Hide()

local times = {} -- lookup by function, the duration to wait before running the function
local running = {} -- ordered list, the current functions waiting to run

-- a function waiting to run will have its duration reset when the timer is restarted
function s:StartTimer(duration, func)
    times[func] = duration
    if not tContains(running, func) then
        tinsert(running, func)
    end
    s.timerFrame:Show()
end

-- every frame, run through each running timer and see if it's ready to run, and run if so
s.timerFrame:SetScript("OnUpdate", function(self, elapsed)
    local tick = false

    for i = #running, 1, -1 do
        local func = running[i]
        times[func] = times[func] - elapsed
        if times[func] < 0 then
            tremove(running, i)
            func(s)
        end
        tick = true
    end

    if not tick then
        self:Hide()
    end
end)