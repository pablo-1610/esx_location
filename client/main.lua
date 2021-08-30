local ESX, cat, title, desc, isMenuOpened, serverInteraction = nil, "location", "Location", "~b~Louez un véhicule", false, false

local cam

local function customGroupDigits(value)
	local left,num,right = string.match(value,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1' .. "."):reverse())..right
end

local function sub(name)
    return cat..name
end

local vehicle = nil
local function createMenuPanes()
    RMenu.Add(cat, sub("main"), RageUI.CreateMenu(title, desc, nil, nil, "pablo", "black"))
    RMenu:Get(cat, sub("main")).Closed = function()
        FreezeEntityPosition(PlayerPedId(), false)
        RenderScriptCams(0, 1, 5000, 0, 0)
        SetCamActive(cam, false)
        DestroyCam(cam, false)
        if DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
        Wait(5000)
        isMenuOpened = false
    end

    RMenu.Add(cat, sub("confirm"), RageUI.CreateMenu(title, desc, nil, nil, "pablo", "black"))
    RMenu:Get(cat, sub("confirm")).Closed = function()
    end
end
--
local function openMenu()
    local camOk = false
    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", false)
    local selectedVehicle = 0
    local heading = 0
    SetCamActive(cam, true)
    SetCamCoord(cam, Config.positions.cameraPos)
    PointCamAtCoord(cam, Config.positions.displayZone)

    if isMenuOpened then return end
    isMenuOpened = true
    FreezeEntityPosition(PlayerPedId(), true)

    local firstModel = GetHashKey(Config.location[1].model)
    for k,v in pairs(Config.location) do
        local model = GetHashKey(v.model)
        RequestModel(model)
        while not HasModelLoaded(model) do RageUI.Text({message = "Chargement du modèle ~y~"..v.model}) Wait(1) end
    end
    
    RenderScriptCams(1, 1, 5000, 0,0)
    SetTimeout(5000, function()
        camOk = true
        SetCamFov(cam, Config.camFov)
    end)

    RageUI.Visible(RMenu:Get(cat, sub("main")), true)

    Citizen.CreateThread(function()
        while isMenuOpened do
            Wait(1)
            heading = heading + 0.08
            if heading > 360 then
                heading = 0
            end
            if DoesEntityExist(vehicle) then SetEntityHeading(vehicle, heading) end
        end
    end)

    local colorVar = "~s~"
    Citizen.CreateThread(function()
        while isMenuOpened do
            Wait(800)
            if colorVar == "~s~" then colorVar = "~y~" else colorVar = "~s~" end
        end
    end)

    Citizen.CreateThread(function()
        while isMenuOpened do 
            RageUI.IsVisible(RMenu:Get(cat, sub("main")), true, true, true, function()
                if not camOk then
                    RageUI.Separator("")
                    RageUI.Separator(colorVar.."Chargement en cours...")
                    RageUI.Separator("")
                else
                    for k,v in pairs(Config.location) do
                        RageUI.ButtonWithStyle(v.label.." ", "Appuyez pour acheter ce véhicule", {RightLabel = selectedVehicle ~= 0 and "~g~"..customGroupDigits(Config.location[k].price).."$~s~ →→" or ""}, true, function(a,h,s)
                            if h then
                                if selectedVehicle ~= k then
                                    selectedVehicle = k
                                    if DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
                                    vehicle = CreateVehicle(GetHashKey(Config.location[k].model), Config.positions.displayZone, heading, false, false)
                                    FreezeEntityPosition(vehicle, true)
                                    SetEntityAsMissionEntity(vehicle, 0,0)
                                    SetEntityInvincible(vehicle, true)
                                    SetEntityAlpha(vehicle, 180, false)
                                    SetVehicleDoorsLocked(vehicle, 2)
                                    SetVehicleCustomPrimaryColour(vehicle, Config.locationRGBColor[1], Config.locationRGBColor[2], Config.locationRGBColor[3])
                                    SetVehicleCustomSecondaryColour(vehicle, Config.locationRGBColor[1], Config.locationRGBColor[2], Config.locationRGBColor[3])
                                end
                            end
                        end, RMenu:Get(cat, sub("confirm")))
                    end
                end
            end, function()
            end)

            RageUI.IsVisible(RMenu:Get(cat, sub("confirm")), true, true, true, function()
                if serverInteraction then
                    RageUI.Separator(colorVar.."Transaction en attente...")
                end
                RageUI.Separator("Selection: ~y~"..Config.location[selectedVehicle].label)
                RageUI.Separator("↓ ~g~Interactions ~s~↓")
                RageUI.ButtonWithStyle("Louer ce véhicule", "Appuyez pour louer ce véhicule", {RightLabel = "~g~"..customGroupDigits(Config.location[selectedVehicle].price).."$~s~ →→"}, not serverInteraction, function(_,_,s)
                    if s then
                        serverInteraction = true
                        RMenu:Get(cat, sub("confirm")).Closable = false
                        TriggerServerEvent("location:rent", selectedVehicle)
                    end
                end)
            end, function()
            end)
            Wait(0)
        end
    end)
end

TriggerEvent(Config.esxGetter, function(obj)
    ESX = obj
    
    createMenuPanes()

    if Config.blip then
        local blip = AddBlipForCoord(Config.positions.interactionZone)
        SetBlipSprite (blip, 77)
        SetBlipColour(blip, 28)
        SetBlipScale  (blip, 0.9)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Location de véhicules")
        EndTextCommandSetBlipName(blip)
    end


    Citizen.CreateThread(function()
        local model = GetHashKey(Config.positions.pedLocation.model)
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(10) end
        
        local npc = nil
        while true do
            local interval = 250
            local pPos, pos = GetEntityCoords(PlayerPedId()), Config.positions.interactionZone
            local dst = #(pPos-pos)

            if dst <= 30.0 and not isMenuOpened then
                interval = 0
                DrawMarker(22, pos, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 245, 186, 37, 255, 55555, false, true, 2, false, false, false, false)
                if dst <= 1.0 then
                    ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir la location de véhicules")
                    if IsControlJustPressed(0, 51) then
                        PlayAmbientSpeech1(npc, "GENERIC_HI", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
                        openMenu()
                    end
                end
            end

            pos = Config.positions.pedLocation.coords
            
            dst = #(pPos-pos)
            if dst <= 70.0 and not DoesEntityExist(npc) then
                npc = CreatePed(4, model, pos.x, pos.y, (pos.z-1.0), Config.positions.pedLocation.heading, false, false)
                SetEntityInvincible(npc, true)
                FreezeEntityPosition(npc, true)
                TaskStartScenarioInPlace(npc, "WORLD_HUMAN_CLIPBOARD", 0, false)
                SetBlockingOfNonTemporaryEvents(npc, true)
            elseif DoesEntityExist(npc) and dst > 70.0 then
                DeleteEntity(npc)
            end

            Wait(interval)
        end
    end)
end)

RegisterNetEvent("location:cb")
AddEventHandler("location:cb", function(sucess, message, vehicleData)
    serverInteraction = false
    if message ~= nil then ESX.ShowNotification(message) end
    if sucess then
        RMenu:Get(cat, sub("confirm")).Closable = true
        RageUI.CloseAll()
        isMenuOpened = false
        local spawn = Config.outPossibilites[math.random(1, #Config.outPossibilites)]    
        local model = GetHashKey(vehicleData.model) 
        FreezeEntityPosition(PlayerPedId(), false)
        RenderScriptCams(0, 0, 0, 0, 0)
        SetCamActive(cam, false)
        DestroyCam(cam, false)
        if DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
        local vehicle = CreateVehicle(model, spawn.coords, spawn.heading, true, false)
        SetVehicleCustomPrimaryColour(vehicle, r, g, b)
        SetVehicleCustomPrimaryColour(vehicle, Config.locationRGBColor[1], Config.locationRGBColor[2], Config.locationRGBColor[3])
        SetVehicleCustomSecondaryColour(vehicle, Config.locationRGBColor[1], Config.locationRGBColor[2], Config.locationRGBColor[3])
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end
end)