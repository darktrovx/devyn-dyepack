
local STACKS = {}
local hasStack = false

local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local SetParticleFxNonLoopedColour = SetParticleFxNonLoopedColour
local SetParticleFxNonLoopedAlpha = SetParticleFxNonLoopedAlpha
local StartNetworkedParticleFxNonLoopedOnEntity = StartNetworkedParticleFxNonLoopedOnEntity
local GetVehiclePedIsIn = GetVehiclePedIsIn
local GetEntityHeading = GetEntityHeading
local Wait = Wait

local function CleanStackZones()
    for _,v in pairs(STACKS) do
        v.zone:remove()
        if v.object then
            DeleteObject(v.object)
        end
    end
end

local function CreateStackObect(self)
    lib.requestModel('bkr_prop_moneypack_03a')

    local data = STACKS[self.stackid]
    local stack = CreateObject('bkr_prop_moneypack_03a', data.coords.x, data.coords.y, data.coords.z, false, false, false)
    SetEntityCoords(stack, data.coords.x, data.coords.y, data.coords.z)
    SetEntityHeading(stack, data.coords.w)
    SetEntityCollision(stack, true, true)
    SetEntityInvincible(stack, true)
    FreezeEntityPosition(stack, true)
    PlaceObjectOnGroundProperly(stack)
    STACKS[self.stackid].object = stack

    exports.ox_target:addLocalEntity(stack, {
        {
            label = "Disarm Dye Pack",
            icon = "fas fa-calculator",
            event = "moneystack:Disarm",
            id = self.stackid,
            data = self.data,
            canInteract = function()
                return not STACKS[self.stackid].disarmed
            end,
        },
        {
            label = "Pick up",
            icon = "fas fa-money-bill",
            serverEvent = "moneystack:AttemptPickupStack",
            id = self.stackid,
            data = self.data
        },
    })
end

local function DeleteStackObject(self)
    local data = STACKS[self.stackid]
    if DoesEntityExist(data.object) then
        DeleteObject(data.object)
        STACKS[self.stackid].object = nil
    end
end

local function AddStack(stackid, data)
    STACKS[stackid] = data
    local sphere = lib.zones.sphere({
        coords = vec3(data.coords.x, data.coords.y, data.coords.z),
        radius = 10,
        debug = false,
        stackid = stackid,
        onEnter = CreateStackObect,
        onExit = DeleteStackObject
    })
    STACKS[stackid].zone = sphere
end

local function SetupStacks()
    CreateThread(function()
        for stackid,stack in pairs(STACKS) do
            AddStack(stackid, stack)
        end
    end)
end

local function DyeEffects()
    lib.requestNamedPtfxAsset("scr_recartheft")
    
    CreateThread(function()
        while hasStack do
            UseParticleFxAssetNextCall("scr_recartheft")
            SetParticleFxNonLoopedColour(30 / 255, 144 / 255, 255 / 255)
            SetParticleFxNonLoopedAlpha(1.0)

            local vehicle = GetVehiclePedIsIn(cache.ped, false)
            local direction = GetEntityHeading(cache.ped) + 190.0

            if vehicle ~= 0 then
                direction = GetEntityHeading(vehicle) + 190.0
                StartNetworkedParticleFxNonLoopedOnEntity("scr_wheel_burnout", vehicle, 0.0, 0.0, 0.9, 0.0, 0.0, direction, 0.5)
            else
                StartNetworkedParticleFxNonLoopedOnEntity("scr_wheel_burnout", cache.ped, 0.0, 0.0, 0.7, 0.0, 0.0, direction, 0.5)
            end

            Wait(500)
        end
    end)
end

RegisterNetEvent("moneystack:Disarm", function(data)
    exports['ps-ui']:Circle(function(success)
        if success then
            lib.notify({ type = "success", description = "Dye pack disarmed" })
            TriggerServerEvent("moneystack:Disarm", data.id, true)
        else
            lib.notify({ type = "error", description = "Failed to disarm dye pack." })
            TriggerServerEvent("moneystack:UpdateDye", data.id, true)
        end
    end, 2, 20) -- NumberOfCircles, MS
end)

RegisterNetEvent("moneystack:AddStack", function(stackid, data)
    AddStack(stackid, data)
end)

RegisterNetEvent("moneystack:RemoveStack", function(stackid)
    if STACKS[stackid].object then
        DeleteStackObject({ stackid = stackid })
    end

    STACKS[stackid].zone:remove()
    STACKS[stackid] = nil
end)

RegisterNetEvent("moneystack:UpdateStackDisarm", function(stackid, disarmed)
    print(stackid, disarmed)
    if not STACKS[stackid] then return end
    STACKS[stackid].disarmed = disarmed
end)

RegisterNetEvent("moneystack:SetStacks", function(stacks)
    CleanStackZones()
    STACKS = stacks
    SetupStacks()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CleanStackZones()
end)

AddEventHandler('ox_inventory:updateInventory', function(changes)
    local count = exports.ox_inventory:GetItemCount("moneystack", { dyePackExploded = true }, false)
    if count > 0 then
        if not hasStack then
            hasStack = true
            DyeEffects()
        end
    else
        hasStack = false
    end
end)