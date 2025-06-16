-- Yo, this is my weather and time control script for FiveM, let's make it dope!

local weatherTypes = {
    'CLEAR', 'EXTRASUNNY', 'CLOUDS', 'OVERCAST', 'RAIN', 'CLEARING',
    'THUNDER', 'SMOG', 'FOGGY', 'XMAS', 'SNOWLIGHT', 'BLIZZARD'
}

local currentWeather = 'CLEAR'
local timeCycle = true
local hours = 0
local minutes = 0

-- Quick check if something's in a table, keepin' it simple
local function contains(table, element)
    for _, value in ipairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Gotta make sure only admins can mess with this, ya know?
local function isAdmin(source)
    return true -- Just for testing, swap with real admin check later
end

-- Command to switch up the weather
RegisterCommand('setweather', function(source, args, rawCommand)
    if not isAdmin(source) then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Error', 'Nah, you ain’t got perms for this!' } })
        return
    end

    local newWeather = args[1] and string.upper(args[1]) or nil
    if newWeather and contains(weatherTypes, newWeather) then
        currentWeather = newWeather
        TriggerClientEvent('weather:changeWeather', -1, newWeather)
        TriggerClientEvent('chat:addMessage', -1, { args = { '^2Weather', 'Switched to ' .. newWeather } })
    else
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Error', 'Bad weather type, try: ' .. table.concat(weatherTypes, ', ') } })
    end
end, false)

-- Flip the weather cycle on or off
RegisterCommand('toggleweather', function(source, args, rawCommand)
    if not isAdmin(source) then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Error', 'No perms, bro!' } })
        return
    end

    timeCycle = not timeCycle
    TriggerClientEvent('chat:addMessage', -1, { args = { '^2Weather', timeCycle and 'Cycle’s on!' or 'Cycle’s off!' } })
end, false)

-- Set the time, keep it clean
RegisterCommand('settime', function(source, args, rawCommand)
    if not isAdmin(source) then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Error', 'Only admins can do this!' } })
        return
    end

    local h, m = tonumber(args[1]), tonumber(args[2])
    if h and m and h >= 0 and h < 24 and m >= 0 and m < 60 then
        hours = h
        minutes = m
        TriggerClientEvent('weather:setTime', -1, hours, minutes)
        TriggerClientEvent('chat:addMessage', -1, { args = { '^2Time', 'Set to ' .. string.format('%02d:%02d', hours, minutes) } })
    else
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Error', 'Use: /settime <hours> <minutes> like /settime 12 30' } })
    end
end, false)

-- Make the weather change happen
RegisterNetEvent('weather:changeWeather')
AddEventHandler('weather:changeWeather', function(weather)
    SetWeatherTypeOverTime(weather, 15.0)
    Citizen.Wait(15000)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypePersist(weather)
    SetWeatherTypeNow(weather)
    SetWeatherTypeNowPersist(weather)
end)

-- Sync the time for everyone
RegisterNetEvent('weather:setTime')
AddEventHandler('weather:setTime', function(h, m)
    NetworkOverrideClockTime(h, m, 0)
end)

-- Keep the weather rollin’ or locked
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        if timeCycle then
            currentWeather = weatherTypes[math.random(#weatherTypes)]
            TriggerClientEvent('weather:changeWeather', -1, currentWeather)
        else
            TriggerClientEvent('weather:changeWeather', -1, currentWeather)
        end
    end
end)

-- Time keeps tickin’
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        minutes = minutes + 1
        if minutes >= 60 then
            minutes = 0
            hours = hours + 1
            if hours >= 24 then
                hours = 0
            end
        end
        TriggerClientEvent('weather:setTime', -1, hours, minutes)
    end
end)

-- Sync new players up
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('weather:requestSync')
end)

RegisterNetEvent('weather:requestSync')
AddEventHandler('weather:requestSync', function()
    TriggerClientEvent('weather:changeWeather', source, currentWeather)
    TriggerClientEvent('weather:setTime', source, hours, minutes)
end)
