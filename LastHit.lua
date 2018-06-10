LastHit = {}

LastHit.table = {"Utility","LastHit creeps"}

LastHit.typeLang = "ru"

LastHit.lang = {

	["ru"] = {
		["Enabled"] = "Включить/Выключить",
		["LastHit auto"] = "Автоматический без удержания",
		["Key to LastHit"] = "Бинд",
		["Deny creeps"] = "Добивания своих крипов",
	},
	
	["eng"] = {
		["Enabled"] = "Enable",
		["LastHit auto"] = "Auto",
		["Key to LastHit"] = "Button",
		["Deny creeps"] = "Deny my creeps",
	},
	
}
-- LastHit.LangOption = Menu.AddOptionCombo(LastHit.table, "lang", {"ru","eng"},0)
LastHit.optionEnable = Menu.AddOptionBool(LastHit.table,LastHit.lang[LastHit.typeLang]["Enabled"], false)
LastHit.auto = Menu.AddOptionBool(LastHit.table,LastHit.lang[LastHit.typeLang]["LastHit auto"], false)
LastHit.key = Menu.AddKeyOption(LastHit.table,LastHit.lang[LastHit.typeLang]["Key to LastHit"], Enum.ButtonCode.KEY_5)
LastHit.DenyMyCreeps = Menu.AddOptionBool(LastHit.table,LastHit.lang[LastHit.typeLang][ "Deny creeps"],true)

Font = Renderer.LoadFont("Tahoma", 24, Enum.FontWeight.EXTRABOLD)

local target_type
local keyAuto


function LastHit.Initialization()
	LastHit.LastAttackTime = os.clock()
	LastHit.LastUpdateTime = os.clock()

	LastHit.AttackTime = 0.5
	LastHit.AttackRange = 0
end

function LastHit.OnUpdate()

	if not Engine.IsInGame() or Heroes.GetLocal() == nil or not Menu.IsEnabled(LastHit.optionEnable) or GameRules.IsPaused() then
		return
	end
		
	if not Menu.IsEnabled(LastHit.auto) then
		if not Menu.IsKeyDown(LastHit.key) then
			return
		end
		keyAuto = true
	else
		if Menu.IsKeyDownOnce(LastHit.key) then
			keyAuto = not keyAuto
		end
		if not keyAuto then
			return
		end
	end

	local myHero = Heroes.GetLocal()
	if not myHero then return end

	local range = NPC.GetAttackRange(myHero)
	local target

	if not target_type then
		return
	end
	
	if LastHit.IsHeroInvisible(myHero) then
		return
	end
	
	target = target_type
	
	LastHit.AttackTarget(target,myHero);
	
end

function LastHit.OnDraw()
	if not Menu.IsEnabled(LastHit.optionEnable) then
		return
	end
	local myHero = Heroes.GetLocal()
	if not myHero then return end
	if not NPC.IsVisible(myHero) then return end
	
	target_type = false
	local x2, y2 = Renderer.WorldToScreen(Entity.GetAbsOrigin(myHero))
	local creeps = false
	
	if ((os.clock() - LastHit.LastUpdateTime) >  0.25 ) then
		creeps =  NPC.GetUnitsInRadius(myHero, LastHit.AttackRange + 150, Enum.TeamType.TEAM_BOTH)
	end
	
	LastHit.AttackTime = NPC.GetAttackTime(myHero)
	LastHit.AttackRange = NPC.GetAttackRange(myHero)
	if creeps then
		for i, npc in ipairs ( creeps ) do
			if NPC.IsCreep(npc) and NPC.IsLaneCreep(npc) and Entity.IsAlive(npc) and LastHit.isCreepsDeny (myHero,npc) then
				local oneHitDamage = NPC.GetArmorDamageMultiplier(npc) * NPC.GetTrueMaximumDamage(myHero)
				local x, y = Renderer.WorldToScreen(Entity.GetAbsOrigin(npc))
				if Entity.GetHealth(npc) < oneHitDamage * 1.15 then
					Renderer.SetDrawColor(255, 0, 0, 110)
					Renderer.DrawLine(x, y, x2, y2)
					target_type = npc 
					Renderer.DrawText(Font, x, y, tostring(math.floor ( 100 * Entity.GetHealth(npc) / Entity.GetMaxHealth(npc))))
					LastHit.LastAttackTime = os.clock();
					break
				end
			end
		end
	end
	
	if Menu.IsEnabled(LastHit.auto) then
		local xS, yS = Renderer.GetScreenSize()
		local text = keyAuto and "On" or "Off" 
		Renderer.SetDrawColor(255, 255, 255)
		Renderer.DrawText(Font, xS - 120, yS - 200, "Auto hit - "..text)
	end
	
end

LastHit.talbeitems = {
	"invoker_ghost_walk",
	"item_invis_sword",
	"item_silver_edge",
	"Item_black_king_bar",
	"Item_cyclone",
	"Item_sheepstick",
	"Item_smoke_of_deceit",
	"Item_invis_sword",
}

function LastHit.IsHeroInvisible(myHero)

	assert ( myHero , " invalid ti" )
	
	if not Entity.IsAlive(myHero) then return false end

	if NPC.HasState(myHero, Enum.ModifierState.MODIFIER_STATE_INVISIBLE) then return true end
	if NPC.HasModifier(myHero, "modifier_invoker_ghost_walk_self") then return true end
	for a,v in ipairs ( LastHit.talbeitems ) do
		if NPC.HasAbility(myHero,v) then
			if Ability.SecondsSinceLastUse(NPC.GetAbility(myHero,v)) > -1 and Ability.SecondsSinceLastUse(NPC.GetAbility(myHero, v)) < 1 then 
				return true
			end
		end
	end
	return false
end

function LastHit.isCreepsDeny (myHero,npc)
	assert ( {myHero,npc} , " invalid ti" )
	if not Menu.IsEnabled(LastHit.DenyMyCreeps) then
		if Entity.IsSameTeam(npc, myHero) then
			if ( 100 * Entity.GetHealth(npc) / Entity.GetMaxHealth(npc) < 30 ) then
				return false
			end
		end
	end
	return true
end

function LastHit.OnGameStart()
	LastHit.Initialization()
end

LastHit.Initialization()

function LastHit.AttackTarget(target, entity, queue)
	if type ( target ) ~= "number" then
		return
	end;
	return Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET, target, Vector(0, 0, 0), nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, entity or nil, queue or false)
end

return LastHit
