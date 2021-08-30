ESX = nil

TriggerEvent(Config.esxGetter, function(obj)
    ESX = obj
    
end)

RegisterNetEvent("location:rent")
AddEventHandler("location:rent", function(vehicleId)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local price = Config.location[vehicleId].price

    if xPlayer.getMoney() >= price then
        xPlayer.removeMoney(price)
    elseif xPlayer.getAccount("bank").money >= price then
        xPlayer.removeAccountMoney("bank", price)
    else
        TriggerClientEvent("location:cb", _src, false, "~r~Vous n'avez pas assez d'argent")
        return
    end

    TriggerClientEvent("location:cb", _src, true, "~g~Bonne route", Config.location[vehicleId])
end)