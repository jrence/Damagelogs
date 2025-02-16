-----------------------------------------
-- Bone IDs mapped to their names
-----------------------------------------
local boneIds = {
    ['eyebrow'] = 1356,
    ['left toe'] = 2108,
    ['right elbow'] = 2992,
    ['left arm'] = 5232,
    ['right hand'] = 6286,
    ['right thigh'] = 6442,
    ['right collarbone'] = 10706,
    ['right corner of the mouth'] = 11174,
    ['sinks'] = 11816,
    ['head'] = 12844,
    ['left foot'] = 14201,
    ['right knee'] = 16335,
    ['lower lip'] = 17188,
    ['lip'] = 17719,
    ['left hand'] = 18905,
    ['right cheekbone'] = 19336,
    ['right toe'] = 20781,
    ['nerve of the lower lip'] = 20279,
    ['left cheekbone'] = 21550,
    ['left elbow'] = 22711,
    ['spinal root'] = 23553,
    ['left thigh'] = 23639,
    ['right foot'] = 24806,
    ['lower part of the spine'] = 24816,
    ['the middle part of the spine'] = 24817,
    ['the upper part of the spine'] = 24818,
    ['left eye'] = 25260,
    ['right eye'] = 27474,
    ['right arm'] = 28252,
    ['left corner of the mouth'] = 29868,
    ['neck'] = 35731,
    ['right calf'] = 36864,
    ['right forearm'] = 43810,
    ['left shoulder'] = 45509,
    ['left knee'] = 46078,
    ['jaw'] = 46240,
    ['tongue'] = 47495,
    ['nerve of the upper lip'] = 49979,
    ['right thigh'] = 51826,
    ['root'] = 56604,
    ['spine'] = 57597,
    ['left foot bone'] = 57717,
    ['left eyebrow'] = 58331,
    ['left hand bone'] = 60309,
    ['left forearm'] = 61163,
    ['upper lip'] = 61839,
    ['left calf'] = 63931,
    ['left collarbone'] = 64729,
    ['face'] = 65068
}

-----------------------------------------
-- Utility Functions
-----------------------------------------

-- Returns the bone name by its ID from the boneIds table.
local function getBoneNameById(boneId)
    for name, id in pairs(boneIds) do
        if id == boneId then
            return name
        end
    end
    return nil
end

-- Draws text on screen.
local function drawTxt(x, y, scale, text, r, g, b, font, centered)
    SetTextFont(font or 4)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    if centered then
        SetTextCentre(true)
    end
    SetTextColour(r, g, b, 255)
    SetTextDropShadow(0, 0, 0, 0, 150)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

-----------------------------------------
-- Damage Log Management
-----------------------------------------
local damageLogs = {}
local MAX_DAMAGE_LOGS = 5

-- Removes expired damage logs (logs older than their timestamp).
local function cleanupDamageLogs()
    while #damageLogs > 0 and GetGameTimer() >= damageLogs[1].timestamp do
        table.remove(damageLogs, 1)
    end
end

-----------------------------------------
-- Threads
-----------------------------------------

-- Thread: Check for the last damaged bone and notify the server.
local lastDamagedBoneId = nil
Citizen.CreateThread(function()
    while true do
        local waitTime = 2000
        local playerPed = PlayerPedId()
        local foundBone, currentBoneId = GetPedLastDamageBone(playerPed)
        
        if foundBone and currentBoneId ~= lastDamagedBoneId then
            local boneName = getBoneNameById(currentBoneId)
            if boneName then
                local remainingHP = GetEntityHealth(playerPed) - 100
                local remainingArmor = GetPedArmour(playerPed)
                local message = string.format(
                    "%s [Damage Area] %s [Remaining HP] %d [Remaining Armor] %d",
                    GetPlayerName(PlayerId()),
                    boneName,
                    remainingHP,
                    remainingArmor
                )
                TriggerServerEvent('asd', message)
                lastDamagedBoneId = currentBoneId
                waitTime = 0
            end
        end
        
        Citizen.Wait(waitTime)
    end
end)

-- Thread: Display damage logs on screen.
Citizen.CreateThread(function()
    while true do
        local waitTime = 2000
        cleanupDamageLogs()
        
        if #damageLogs > 0 then
            local posY = 0.50
            for _, log in ipairs(damageLogs) do
                drawTxt(0.53, posY, 0.6, tostring(log.totalDamage), 252, 78, 66, 2, true)
                posY = posY - 0.025
            end
            waitTime = 0
        end
        
        Citizen.Wait(waitTime)
    end
end)

-----------------------------------------
-- Event Handlers
-----------------------------------------

-- Handles damage log events coming from the server.
RegisterNetEvent("damagelogs")
AddEventHandler("damagelogs", function(damageAmount, senderId, isDead)
    local displayedDamage = isDead and string.format("DEAD(%d)", math.min(damageAmount, 200)) or tostring(math.min(damageAmount, 200))
    table.insert(damageLogs, { timestamp = GetGameTimer() + 500, totalDamage = displayedDamage })
    
    if #damageLogs > MAX_DAMAGE_LOGS then
        table.remove(damageLogs, 1)
    end

    TriggerServerEvent('totaldamage', displayedDamage)
end)
