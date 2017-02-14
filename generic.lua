local n_name, glb               = ...
local XB                        = XB
local CameraOrSelectOrMoveStart = CameraOrSelectOrMoveStart
local CameraOrSelectOrMoveStop  = CameraOrSelectOrMoveStop
local CastSpellByName           = CastSpellByName
local GetCVar                   = GetCVar
local RunMacroText              = RunMacroText
local SetCVar                   = SetCVar
local UnitExists                = ObjectExists or UnitExists
local UseInventoryItem          = UseInventoryItem
local UseItemByName             = UseItemByName
local UnitIsVisible             = UnitIsVisible

-- Advanced APIs
local CancelPendingSpell        = CancelPendingSpell
local CastAtPosition            = CastAtPosition
local GetDistanceBetweenObjects = GetDistanceBetweenObjects
local IsHackEnabled             = IsHackEnabled
local ObjectCount               = ObjectCount
local ObjectFacing              = ObjectFacing
local ObjectIsFacing            = ObjectIsFacing
local ObjectPosition            = ObjectPosition
local ObjectWithIndex           = ObjectWithIndex
local TraceLine                 = TraceLine
local UnitCombatReach           = UnitCombatReach

-- Generic
glb.Generic = {}

function glb.Generic.Cast(spell, target)
    CastSpellByName(spell, target)
end

function glb.Generic.CastGround(spell)
    local stickyValue = GetCVar("deselectOnClick")
    SetCVar("deselectOnClick", "0")
    CameraOrSelectOrMoveStart(1)
    glb.Generic.Cast(spell)
    CameraOrSelectOrMoveStop(1)
    SetCVar("deselectOnClick", "1")
    SetCVar("deselectOnClick", stickyValue)
end

function glb.Generic.Macro(text)
    RunMacroText(text)
end

function glb.Generic.UseItem(name, target)
    UseItemByName(name, target)
end

function glb.Generic.UseInvItem(slotID)
    UseInventoryItem(slotID)
end

glb.FireHack = {}

function glb.FireHack.Distance(Unit1, Unit2)
    -- If Unit2 is nil we compare player to Unit1
    if Unit2 == nil then
        Unit2 = Unit1
        Unit1 = "player"
    end
    -- Check if objects exists and are visible
    if UnitExists(Unit1) and UnitIsVisible(Unit1)
        and UnitExists(Unit2) and UnitIsVisible(Unit2)
    then
    -- Get the distance
        local TargetCombatReach = UnitCombatReach(Unit2)
        local PlayerCombatReach = UnitCombatReach(Unit1)
        local MeleeCombatReachConstant = 4/3
        local IfSourceAndTargetAreRunning = 0
        if XB.Game:IsMoving(Unit1) and XB.Game:IsMoving(Unit2) then
            IfSourceAndTargetAreRunning = 8/3
        end
        local dist = GetDistanceBetweenObjects(Unit1,Unit2) - (PlayerCombatReach + TargetCombatReach)
        local dist2 = dist + 0.03 * ((13 - dist) / 0.13)
        local dist3 = dist + 0.05 * ((8 - dist) / 0.15)
        local dist4 = dist + (PlayerCombatReach + TargetCombatReach)
        local meleeRange = max(5, PlayerCombatReach + TargetCombatReach + MeleeCombatReachConstant + IfSourceAndTargetAreRunning)
        if dist > 13 then
            return dist
        elseif dist2 > 8 and dist3 > 8 then
            return dist2
        elseif dist3 > 5 and dist4 > 5 then
            return dist3
        elseif dist4 > meleeRange then -- Thanks Ssateneth
            return dist4
        else
            return 0
        end
    else
        return 100
    end
end

function glb.FireHack.Infront(a, b)
    return ObjectIsFacing(a,b)
end

function glb.FireHack.GetFacing(Unit1,Unit2,Degrees )
    if Degrees == nil then
        Degrees = 90
    end
    if Unit2 == nil then
        Unit2 = "player"
    end
    if UnitExists(Unit1) and UnitIsVisible(Unit1) and UnitExists(Unit2) and UnitIsVisible(Unit2) then
        local Angle1,Angle2,Angle3
        local Angle1 = ObjectFacing(Unit1)
        local Angle2 = ObjectFacing(Unit2)
        local Y1,X1,Z1 = ObjectPosition(Unit1)
        local Y2,X2,Z2 = ObjectPosition(Unit2)
        if Y1 and X1 and Z1 and Angle1 and Y2 and X2 and Z2 and Angle2 then
            local deltaY = Y2 - Y1
            local deltaX = X2 - X1
            Angle1 = math.deg(math.abs(Angle1-math.pi*2))
            if deltaX > 0 then
                Angle2 = math.deg(math.atan(deltaY/deltaX)+(math.pi/2)+math.pi)
            elseif deltaX <0 then
                Angle2 = math.deg(math.atan(deltaY/deltaX)+(math.pi/2))
            end
            if Angle2-Angle1 > 180 then
                Angle3 = math.abs(Angle2-Angle1-360)
            else
                Angle3 = math.abs(Angle2-Angle1)
            end
            if Angle3 < Degrees then
                return true
            else
                return false
            end
        end
    end
    return false
end

function glb.FireHack.CastGround(spell, target)
    -- this is to cast on cursor location
    if not target then
        glb.Generic.CastGround(spell)
        return
    end

    local rX, rY = math.random(), math.random()
    local oX, oY, oZ = ObjectPosition(target)
    if oX then oX = oX + rX; oY = oY + rY end
    glb.Generic.Cast(spell)
    if oX then CastAtPosition(oX, oY, oZ) end
    CancelPendingSpell()
end

function glb.FireHack.UnitCombatRange(unitA, unitB)
    return glb.FireHack.Distance(unitA, unitB) - (UnitCombatReach(unitA) + UnitCombatReach(unitB))
end

local losFlags = bit.bor(0x10, 0x100)
function glb.FireHack.LineOfSight(Unit1, Unit2)
    if Unit2 == nil then
        if Unit1 == "player" then
            Unit2 = "target"
        else
            Unit2 = "player"
        end
    end
    local skipLoSTable = {
        76585,     -- Ragewing
        77692,     -- Kromog
        77182,     -- Oregorger
        96759,     -- Helya
        100360,    -- Grasping Tentacle (Helya fight)
        100354,    -- Grasping Tentacle (Helya fight)
        100362,    -- Grasping Tentacle (Helya fight)
        98363,    -- Grasping Tentacle (Helya fight)
        98696,     -- Illysanna Ravencrest (Black Rook Hold)
        114900, -- Grasping Tentacle (Trials of Valor)
        114901, -- Gripping Tentacle (Trials of Valor)
        116195, -- Bilewater Slime (Trials of Valor)
        --86644, -- Ore Crate from Oregorger boss
    }
    for i = 1,#skipLoSTable do
        if XB.Game:UnitID(Unit1) == skipLoSTable[i] or XB.Game:UnitID(Unit2) == skipLoSTable[i] then
            return true
        end
    end
    if UnitExists(Unit1) and UnitIsVisible(Unit1) and UnitExists(Unit2) and UnitIsVisible(Unit2) then
        local X1,Y1,Z1 = ObjectPosition(Unit1)
        local X2,Y2,Z2 = ObjectPosition(Unit2)
        if TraceLine(X1,Y1,Z1 + 2.25,X2,Y2,Z2 + 2.25, losFlags) == nil then
            return true
        else
            return false
        end
    else
        return true
    end
end

function glb.FireHack.IsHackEnabled(flag)
    return IsHackEnabled(flag)
end

function glb.FireHack_OM()
    for i=1, ObjectCount() do
        XB.OM:Add(ObjectWithIndex(i))
    end
end

XB:AddUnlocker('EasyWoWToolBox', function()
    return EWT
end, glb.Generic, glb.FireHack, glb.FireHack_OM)

XB:AddUnlocker('FireHack', function()
    return FireHack
end, glb.Generic, glb.FireHack, glb.FireHack_OM)
