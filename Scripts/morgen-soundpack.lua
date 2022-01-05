local szSoundsDir = "C:\\kamidere\\Sounds\\"
local bLoopback = true

local m_bBombTicking = Netvars.GetOffset("CPlantedC4->m_bBombTicking")
local m_flC4Blow = Netvars.GetOffset("CPlantedC4->m_flC4Blow")
local m_flTimerLength = Netvars.GetOffset("CPlantedC4->m_flTimerLength")
local m_bBombDefused = Netvars.GetOffset("CPlantedC4->m_bBombDefused")

local szDefaultFormat = ".wav"

local szOnRifle = szSoundsDir .. "onRifle" .. szDefaultFormat
local szOnExplosion = szSoundsDir .. "onExplosion" .. szDefaultFormat
local szOnKill = szSoundsDir .. "onKill" .. szDefaultFormat

local function GetBombTimer(pBomb, flCurrentTime)

	local bDefused = pBomb:GetPropBool(m_bBombDefused)
	local bTicking = pBomb:GetPropBool(m_bBombTicking)

	if(bDefused or not bTicking) then
		return 0.0
	end
	
	local flBlowTime = pBomb:GetPropFloat(m_flC4Blow) - flCurrentTime
	
	if(flBlowTime < 0.0) then
		return 0.0
	end

	return flBlowTime
end

local function GetBomb()
	for i = GlobalVars.nMaxClients, EntityList.GetMaxEntities() do
	
		local pEntity = EntityList.GetEntityByIndex(i)
		
		if(pEntity ~= nil and not pEntity:IsDormant()) then
			-- EClassId::CPlantedC4 = 129
			if (pEntity:GetClassId() == 129) then
				return pEntity
			end
		end
		
	end
	
	return nil
end

local function OnEvent(pEvent)

	local szName = pEvent:GetName()
	
	if(szName == "item_equip") then
	
		local iUserId = pEvent:GetInt("userid")
		
		local pLocal = CBaseEntity.GetLocalPlayer()
		local pTarget = EntityList.GetEntityByUserId(iUserId)
		
		if(pLocal == nil or pTarget ~= pLocal) then
			return
		end
	
		local iWeptype = pEvent:GetInt("weptype")
		
		-- 3 is rifle
		if(iWeptype ~= 3) then
			return
		end
		
		Utils.PlaySoundToVoice(szOnRifle, bLoopback)
		
		return
	end
	
	if(szName == "player_death") then
	
		local pLocal = CBaseEntity.GetLocalPlayer()
		local pTarget = EntityList.GetEntityByUserId(pEvent:GetInt("userid"))
		local pAttacker = EntityList.GetEntityByUserId(pEvent:GetInt("attacker"))
		
		if(pLocal == nil or pTarget == pLocal or pAttacker ~= pLocal) then
			return
		end
		
		Utils.PlaySoundToVoice(szOnKill, bLoopback)
		
		return
	end
	
end

local flLastTime = 0.0
local flBombSoundLegth = Utils.GetSoundLength(szOnExplosion) - 1.25

local function ProcessExplosionSound(pBomb)

	if(pBomb == nil) then
		return
	end

	local pLocal = CBaseEntity.GetLocalPlayer()
	
	if(pLocal == nil or pLocal:IsDormant()) then
		return
	end

	local flCurrentTime = pLocal:GetTickBase() * GlobalVars.flIntervalPerTick
	local flBlowTime = GetBombTimer(pBomb, flCurrentTime)
	
	if(flBlowTime > 0.0) then
		if(flLastTime - flBombSoundLegth > 0.0 and flBlowTime - flBombSoundLegth <= 0.0) then
			Utils.PlaySoundToVoice(szOnExplosion, bLoopback)
		end
	end
	
	flLastTime = flBlowTime
end

local function OnCreateMove(pCmd)
	local pBomb = GetBomb()
	
	ProcessExplosionSound(pBomb)
end

Hooks.RegisterCallback("OnCreateMove", OnCreateMove)

-- this requires bomb esp enabled but requires less resources
--[[
local function OnBombEsp(pBomb, pBounds)
	ProcessExplosionSound(pBomb)
end

Hooks.RegisterCallback("OnBombEsp", OnBombEsp)
--]]

EventListener.AddEvent("item_equip")
EventListener.AddEvent("player_death")

Hooks.RegisterCallback("OnGameEvent", OnEvent)