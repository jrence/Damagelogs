local DAMAGE_WEBHOOK = "Webhook"         -- Webhook URL for Damage Logs
local TOTAL_DAMAGE_WEBHOOK = "Webhook"     -- Webhook URL for Total Damage Logs
local DISCORD_LOG_IMAGE = "https://cdn.discordapp.com/attachments/873184959400149072/890646026044731412/dollar-black-poster.png"

-- Extract identifiers from a player
local function extractIdentifiers(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    local identifierData = {
        steam   = "N/A",
        license = "N/A",
        discord = "N/A",
        xbl     = "N/A",
        live    = "N/A",
        ip      = "N/A"
    }

    for _, identifier in ipairs(identifiers) do
        if identifier:find("steam:") then
            identifierData.steam = identifier
        elseif identifier:find("license:") then
            identifierData.license = identifier
        elseif identifier:find("discord:") then
            identifierData.discord = identifier
        elseif identifier:find("xbl:") then
            identifierData.xbl = identifier
        elseif identifier:find("live:") then
            identifierData.live = identifier
        elseif identifier:find("ip:") then
            identifierData.ip = identifier:sub(4)  -- Remove the "ip:" prefix
        end
    end

    return identifierData
end

-- Create a Discord embed object for the log
local function createLogEmbed(title, description)
    return {
        color = 66666,  -- Discord expects a number for the color value
        author = {
            name = "Damage Logs!",
            icon_url = DISCORD_LOG_IMAGE
        },
        type = "rich",
        title = title,
        description = description,
        footer = {
            text = "Damage Logs!!  |  " .. os.date("%m/%d/%Y")
        }
    }
end

-- Send the embed to the specified webhook URL
local function sendWebhook(webhookUrl, logEmbed)
    local payload = {
        username = "Heavens!",
        avatar_url = "",  -- Set an avatar URL if needed
        embeds = { logEmbed }
    }
    PerformHttpRequest(webhookUrl, function(err, text, headers)
        if err then
            print("[Damage logs] Error sending message to webhook: " .. err)
        end
    end, "POST", json.encode(payload), { ["Content-Type"] = "application/json" })
end

-- Common function to log a damage event
local function logDamageEvent(playerId, damage, title, webhookUrl)
    local identifiers = extractIdentifiers(playerId)
    local description = string.format(
        "%s\n **IP:** %s\n **SteamID:** %s\n **License:** %s\n **Discord:** %s\n **XBL:** %s\n **Live:** %s",
        tostring(damage),
        identifiers.ip,
        identifiers.steam,
        identifiers.license,
        identifiers.discord,
        identifiers.xbl,
        identifiers.live
    )
    local logEmbed = createLogEmbed(title, description)
    sendWebhook(webhookUrl, logEmbed)
end

-- Event listener for damagebone event
RegisterServerEvent('damagebone')
AddEventHandler('damagebone', function(damage)
    local playerId = source
    logDamageEvent(playerId, damage, "Damage Logs", DAMAGE_WEBHOOK)
end)

-- Event listener for totaldamage event
RegisterServerEvent('totaldamage')
AddEventHandler('totaldamage', function(damage)
    local playerId = source
    logDamageEvent(playerId, damage, "Total Damage Logs", TOTAL_DAMAGE_WEBHOOK)
end)

-- Listen for weapon damage event and trigger a client event
AddEventHandler('weaponDamageEvent', function(sender, data)
    local damage = data.weaponDamage
    local isKill = data.willKill
    TriggerClientEvent('damagelogs', sender, damage, sender, isKill)
end)
