local STACKS = {}

-- Add a Money Stack to the server.
---@param coords table
---@param disableTime boolean | number
local function AddStack(coords, disableTime)
    local id = #STACKS + 1

    STACKS[id] = {
        created = os.time(),
        coords = coords,
        disableTime = disableTime or false,
        disarmed = false,
        dyePackExploded = false,
    }

    TriggerClientEvent("moneystack:AddStack", -1, id, STACKS[id])
end
exports('AddStack', AddStack)

-- Remove a Money Stack from the server.
---@param id number
local function RemoveStack(id)
    if not STACKS[id] then return end
    TriggerClientEvent("moneystack:RemoveStack", -1, id)
    STACKS[id] = nil
end
exports('RemoveStack', RemoveStack)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    TriggerClientEvent("moneystack:SetSTACKS", src, STACKS)
end)

RegisterNetEvent("moneystack:AttemptPickupStack", function(id)
    local src = source

    if type(id) == 'table' then
        id = id.id
    end
    if not STACKS[id] then return end

    if not STACKS[id].dyePackExploded and STACKS[id].disarmed then
        exports.ox_inventory:AddItem(src, 'moneystack', 1)
    else
        exports.ox_inventory:AddItem(src, 'moneystack', 1, { dyePackExploded = true })
    end
    
    RemoveStack(id)
end)

RegisterNetEvent("moneystack:UpdateDye", function(id, exploded)
    local src = source
    if not STACKS[id] then return end

    STACKS[id].dyePackExploded = exploded
end)

RegisterNetEvent("moneystack:Disarm", function(id, disarmed)
    local src = source
    if not STACKS[id] then return end

    STACKS[id].disarmed = disarmed
    TriggerClientEvent("moneystack:UpdateStackDisarm", -1, id, disarmed)
end)

lib.addCommand("addstack",{
        help = "Add a money stack to the server.",
        params = {}
    },
    function(source, args, raw)
        local coords = GetEntityCoords(GetPlayerPed(source))
        AddStack(coords, false)
    end
)

