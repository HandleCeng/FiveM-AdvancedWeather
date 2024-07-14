local weatherTypes = {
    'CLEAR',
    'EXTRASUNNY',
    'CLOUDS',
    'OVERCAST',
    'RAIN',
    'CLEARING',
    'THUNDER',
    'SMOG',
    'FOGGY',
    'XMAS',
    'SNOWLIGHT',
    'BLIZZARD'
}

local currentWeather = 'CLEAR'
local timeCycle = true

RegisterCommand('setweather', function(source, args, rawCommand)
    local newWeather = string.upper(args[1])
    if newWeather and table.contains(weatherTypes, newWeather) then
        currentWeather = newWeather
        TriggerEvent('weather:changeWeather', newWeather)
        print('Weather changed to: ' .. newWeather)
    else
        print('Invalid weather type.')
    end
end, false)

RegisterCommand('toggleweather', function(source, args, rawCommand)
    timeCycle = not timeCycle
    if timeCycle then
        print('Weather cycle enabled.')
    else
        print('Weather cycle disabled.')
    end
end, false)

AddEventHandler('weather:changeWeather', function(weather)
    SetWeatherTypeOverTime(weather, 15.0)
    Citizen.Wait(15000)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypePersist(weather)
    SetWeatherTypeNow(weather)
    SetWeatherTypeNowPersist(weather)
end)

Citizen.CreateThread(function()
    while true do
        if timeCycle then
            local newWeather = weatherTypes[math.random(#weatherTypes)]
            TriggerEvent('weather:changeWeather', newWeather)
            Citizen.Wait(60000)
        else
            TriggerEvent('weather:changeWeather', currentWeather)
            Citizen.Wait(60000)
        end
    end
end)

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Time control
local hours = 0
local minutes = 0

RegisterCommand('settime', function(source, args, rawCommand)
    if #args == 2 then
        hours = tonumber(args[1])
        minutes = tonumber(args[2])
        NetworkOverrideClockTime(hours, minutes, 0)
        print('Time set to ' .. hours .. ':' .. minutes)
    else
        print('Usage: /settime <hours> <minutes>')
    end
end, false)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000) -- Every in-game minute
        minutes = minutes + 1
        if minutes >= 60 then
            minutes = 0
            hours = hours + 1
            if hours >= 24 then
                hours = 0
            end
        end
        NetworkOverrideClockTime(hours, minutes, 0)
    end
end)
