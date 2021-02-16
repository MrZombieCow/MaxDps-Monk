local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end

local MaxDps = MaxDps;
local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;
local GetPowerRegen = GetPowerRegen;
local Chi = Enum.PowerType.Chi;
local Energy = Enum.PowerType.Energy;
local Monk = addonTable.Monk;

local WW = {
	ChiBurst                = 123986,
	Serenity                = 152173,
	FistOfTheWhiteTiger     = 261947,
	ChiWave                 = 115098,
	SpearHandStrike         = 116705,
	RushingJadeWind         = 116847,
	TouchOfKarma            = 122470,
	GoodKarma               = 280195,
	TigerPalm               = 100780,
	WhirlingDragonPunch     = 152175,
	WDPBuff                 = 196742,
	EnergizingElixir        = 115288,
	FistsOfFury             = 113656,
	RisingSunKick           = 107428,
	SpinningCraneKick       = 101546,
	DanceOfChiJi            = 325201,
	DanceOfChiJiBuff        = 325202,
	HitCombo                = 196740,
	FlyingSerpentKick       = 101545,
	FlyingSerpentKickActive = 115057,
	BlackoutKick            = 100784,
	TouchOfDeath            = 322109,
	InvokeXuenTheWhiteTiger = 123904,
	StormEarthAndFire       = 137639,
	SwiftRoundhouse         = 277669,
	BokProc                 = 116768,
	ReverseHarm             = 342928,
	ExpelHarm               = 322101,
	WeaponsOfOrder          = 310454,
	WeaponsOfOrderChiBuff   = 311054,
	FallenOrder				= 326860,
	BonedustBrew			= 325216,
	FaelineStomp			= 327104,
	CracklingJadeLightning  = 117952
};

local hitCombo = {
	TigerPalm               = 100780,
    BlackoutKick            = 100784,
    RisingSunKick           = 107428,
    FlyingSerpentKick       = 101545,
    FistsOfFury             = 113656,
    SpinningCraneKick       = 101546,
    RushingJadeWind         = 116847,
    WhirlingDragonPunch     = 152175,
    ChiWave                 = 115098,
    ChiBurst                = 123986,
    CracklingJadeLightning  = 117952,
    TouchOfDeath            = 322109
};

local CN = {
	None      = 0,
	Kyrian    = 1,
	Venthyr   = 2,
	NightFae  = 3,
	Necrolord = 4
};
	

setmetatable(WW, Monk.spellMeta);

function Monk:Windwalker()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell, spellHistory, spellCombo, gcd =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.spellHistory, fd.spellCombo, fd.gcd;

	local chi = UnitPower('player', Chi);
	local chiMax = UnitPowerMax('player', Chi);
	local energy = UnitPower('player', Energy);
	local energyRegen = GetPowerRegen();
	local energyMax = UnitPowerMax('player', Energy);
	local energyTimeToMax = (energyMax - energy) / energyRegen;
	local energyInOneSec = energy + (energyRegen * 1);
	local ispvp = UnitIsPVP("player");
	
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	
	local targets = MaxDps:SmartAoe();
	
	if currentSpell == WW.ChiBurst and targets == 1 then
		chi = chi + 1;
	elseif currentSpell == WW.ChiBurst and targets >= 2 then
		chi = chi + 2;
	end
	
	local _, _, i2 = GetSpellInfo(101545);
	local _, _, i3 = GetSpellInfo(115057);
	local _, _, _, FoFCastTime = GetSpellInfo(113656);
	local _, _, _, _, _, _, _, FoF = UnitChannelInfo(target or 'player');

	fd.chi, fd.chiMax, fd.energy, fd.energyRegen, fd.energyMax, fd.energyTimeToMax, fd.targets =
	chi, chiMax, energy, energyRegen, energyMax, energyTimeToMax, targets;

	MaxDps:GlowCooldown(WW.InvokeXuenTheWhiteTiger, cooldown[WW.InvokeXuenTheWhiteTiger].ready);
	MaxDps:GlowEssences();
	MaxDps:GlowCooldown(WW.TouchOfDeath, cooldown[WW.TouchOfDeath].ready and targetHp < 15);
	MaxDps:GlowCooldown(WW.WeaponsOfOrder, cooldown[WW.WeaponsOfOrder].ready and covenant == CN.Kyrian and cooldown[WW.RisingSunKick].remains < gcd * 2);
	MaxDps:GlowCooldown(WW.FaelineStomp, cooldown[WW.FaelineStomp].ready and covenant == CN.NightFae);
	MaxDps:GlowCooldown(WW.FallenOrder, cooldown[WW.FallenOrder].ready and covenant == CN.Venthyr);
	MaxDps:GlowCooldown(WW.BonedustBrew, cooldown[WW.BonedustBrew].ready and covenant == CN.Necrolord);

	if not talents[WW.Serenity] then
		MaxDps:GlowCooldown(
			WW.StormEarthAndFire,
			cooldown[WW.StormEarthAndFire].charges == 2 or
				(cooldown[WW.StormEarthAndFire].ready and cooldown[WW.FistsOfFury].remains <= 6 and chi >= 3 and cooldown[WW.RisingSunKick].remains <= 1)
		);
	else
		MaxDps:GlowCooldown(
			WW.Serenity,
			cooldown[WW.Serenity].ready and cooldown[WW.RisingSunKick].remains <= 2
		);
	end
	
	if i2 == i3 then
		return WW.FlyingSerpentKick;
	end
	
	--Don't cancel FoF if WeaponsOfOrderBuff!=up and StormEarthAndFire!=up or 2+ targets
	if (FoF == 113656 and not buff[WW.StormEarthAndFire].up) or (FoF == 113656 and targets > 1 and buff[WW.WeaponsOfOrder].up) or (FoF == 113656 and not buff[WW.WeaponsOfOrder].up) then
		return
	end
	
	if FoF == 101546 then
		return
	end
	
	if buff[WW.Serenity].up then
		return Monk:WindwalkerSerenity();
	end
	
	local result = Monk:WindwalkerCooldown();
	if result then
		return result;
	end
	
	if buff[WW.WeaponsOfOrder].up then
		return Monk:WindwalkerWeaponsOfOrder();
	end
	
	if talents[WW.FistOfTheWhiteTiger] and cooldown[WW.FistOfTheWhiteTiger].ready and
		energy >= 40 and chiMax - chi >= 3 and
		(energyTimeToMax < gcd or (talents[WW.Serenity] and cooldown[WW.Serenity].remains < 2) or
		(energyMax < 4 and cooldown[WW.FistsOfFury].remains < 1.5) or (cooldown[WW.WeaponsOfOrder].remains < 2 and covenant == CN.Kyrian and (Monk.db.AnyAsCooldown or not Monk.db.CovenantAsCooldown))) then
		return WW.FistOfTheWhiteTiger;
	end
	
	if cooldown[WW.ExpelHarm].ready and
		energy >= 15 and chiMax - chi >= 1 and
		(energyTimeToMax < gcd or (talents[WW.Serenity] and cooldown[WW.Serenity].remains < 2) or
		(energyMax < 4 and cooldown[WW.FistsOfFury].remains < 1.5) or (cooldown[WW.WeaponsOfOrder].remains < 2 and covenant == CN.Kyrian and (Monk.db.AnyAsCooldown or not Monk.db.CovenantAsCooldown))) then
		return WW.ExpelHarm;
	end
	
	if spellCombo[1] ~= WW.TigerPalm and energy >= 50 and chiMax - chi >= 2 and
		(energyTimeToMax < gcd or (talents[WW.Serenity] and cooldown[WW.Serenity].remains < 2) or
		(energyMax < 4 and cooldown[WW.FistsOfFury].remains < 1.5) or (cooldown[WW.WeaponsOfOrder].remains < 2 and covenant == CN.Kyrian and (Monk.db.AnyAsCooldown or not Monk.db.CovenantAsCooldown))) then
		return WW.TigerPalm;
	end

	if targets < 3 then
		return Monk:WindwalkerSingleTarget();
	end

	if targets >= 3 then
		return Monk:WindwalkerAoe();
	end
end

function Monk:WindwalkerCooldown()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell, spellHistory, spellCombo,
	chi, chiMax, energy, energyRegen, energyMax, energyTimeToMax, energyInOneSec, targets, gcd, ispvp, timeToDie =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.spellHistory, fd.spellCombo,
	fd.chi, fd.chiMax, fd.energy, fd.energyRegen, fd.energyMax, fd.energyTimeToMax, fd.energyInOneSec, fd.targets, fd.gcd, fd.ispvp, fd.timeToDie;
	
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	
	if cooldown[WW.InvokeXuenTheWhiteTiger].ready and
	(Monk.db.AnyAsCooldown or not Monk.db.XuenAsCooldown)
	then
		return WW.InvokeXuenTheWhiteTiger;
	end
	
	if cooldown[WW.TouchOfDeath].ready and UnitExists("pet") and targetHp < 15 and
	(Monk.db.AnyAsCooldown or not Monk.db.ToDAsCooldown)
	then
		return WW.TouchOfDeath;
	end
	
	if cooldown[WW.WeaponsOfOrder].ready and covenant == CN.Kyrian and cooldown[WW.RisingSunKick].remains < gcd * 2 and
	(Monk.db.AnyAsCooldown or not Monk.db.CovenantAsCooldown)
	then
		return WW.WeaponsOfOrder;
	end
	
	if cooldown[WW.FaelineStomp].ready and covenant == CN.NightFae and
	(Monk.db.AnyAsCooldown or not Monk.db.CovenantAsCooldown)
	then
		return WW.FaelineStomp;
	end
	
	if cooldown[WW.FallenOrder].ready and covenant == CN.Venthyr and
	(Monk.db.AnyAsCooldown or not Monk.db.CovenantAsCooldown)
	then
		return WW.FallenOrder;
	end
	
	if cooldown[WW.BonedustBrew].ready and covenant == CN.Necrolord and
	(Monk.db.AnyAsCooldown or not Monk.db.CovenantAsCooldown)
	then
		return WW.BonedustBrew;
	end
	
	if cooldown[WW.StormEarthAndFire].charges == 2 and not buff[WW.StormEarthAndFire].up and
	(Monk.db.AnyAsCooldown or not Monk.db.StormEarthAndFireAsCooldown)
	then
		return WW.StormEarthAndFire;
	end
	
	if cooldown[WW.StormEarthAndFire].charges >= 1 and buff[WW.WeaponsOfOrder].up and not buff[WW.StormEarthAndFire].up and
	(Monk.db.AnyAsCooldown or not Monk.db.StormEarthAndFireAsCooldown)
	then
		return WW.StormEarthAndFire;
	end
	
	if cooldown[WW.TouchOfKarma].ready and UnitExists("pet") and
	(Monk.db.AnyAsCooldown or not Monk.db.TouchOfKarmaAsCooldown)
	then
		return WW.TouchOfKarma;
	end
end
	


function Monk:WindwalkerSingleTarget()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell, spellHistory, spellCombo,
	chi, chiMax, energy, energyRegen, energyMax, energyTimeToMax, energyInOneSec, targets, gcd, ispvp =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.spellHistory, fd.spellCombo,
	fd.chi, fd.chiMax, fd.energy, fd.energyRegen, fd.energyMax, fd.energyTimeToMax, fd.energyInOneSec, fd.targets, fd.gcd, fd.ispvp;
	
	local MotC = GetSpellCount("Spinning Crane Kick");
	local _, _, _, FoFCastTime = GetSpellInfo(113656);
	local currentSpeed = GetUnitSpeed("player") / 7 * 100;
	
	if talents[WW.WhirlingDragonPunch] and cooldown[WW.WhirlingDragonPunch].ready and
		buff[WW.WDPBuff].up
	then
		return WW.WhirlingDragonPunch;
	end
	
	if cooldown[WW.RisingSunKick].ready and chi >= 2 then
		return WW.RisingSunKick;
	end
	
	if cooldown[WW.FistsOfFury].ready and chi >= 3 and (energyTimeToMax > FoFCastTime or chiMax - chi <= 1) then
		return WW.FistsOfFury;
	end
	
	if cooldown[WW.FistOfTheWhiteTiger].ready and talents[WW.FistOfTheWhiteTiger] and energy >= 40 and chiMax - chi >= 3 then
		return WW.FistOfTheWhiteTiger;
	end
	
	if cooldown[WW.ExpelHarm].ready and energy >= 15 and chiMax - chi >= 1 then
		return WW.ExpelHarm;
	end
	
	if cooldown[WW.ChiBurst].ready and currentSpeed < 1 and talents[WW.ChiBurst] and chiMax - chi >= 1 then
		return WW.ChiBurst;
	end
	
	if cooldown[WW.ChiWave].ready and talents[WW.ChiWave] then
		return WW.ChiWave;
	end
	
	if energy >= 50 and chiMax - chi >= 2 and spellCombo[1] ~= WW.TigerPalm and not buff[WW.StormEarthAndFire].up then
		return WW.TigerPalm;
	end
	
	if buff[WW.DanceOfChiJiBuff].up and spellCombo[1] ~= WW.SpinningCraneKick and currentSpell ~= WW.SpinningCraneKick then
		return WW.SpinningCraneKick;
	end
		
	if ((buff[WW.BokProc].up or chi > 5) or 
	(cooldown[WW.FistsOfFury].remains > 1 and cooldown[WW.RisingSunKick].remains > 1 and chi >= 1) or 
	(cooldown[WW.FistsOfFury].remains > 3 and cooldown[WW.RisingSunKick].remains < 3 and chi > 2) or
	(cooldown[WW.FistsOfFury].remains < 3 and cooldown[WW.RisingSunKick].remains < 3 and chi > 3)) and spellCombo[1] ~= WW.BlackoutKick then
		return WW.BlackoutKick;
	end
		
	if energy >= 50 and chiMax - chi >= 2 and spellCombo[1] ~= WW.TigerPalm then
		return WW.TigerPalm;
	end
	
	if cooldown[WW.FlyingSerpentKick].ready and talents[WW.ChiBurst] then
		return WW.FlyingSerpentKick;
	end
	
	if cooldown[WW.FistsOfFury].remains < 3 and chi == 2 and spellCombo[1] == WW.TigerPalm and energy + (energyRegen * gcd) >= 50 and spellCombo[1] ~= WW.BlackoutKick then
		return WW.BlackoutKick;
	end
	
	if energyTimeToMax < (gcd * 2) and (chiMax - chi <= 1 or spellCombo[1] == WW.TigerPalm) and spellCombo[1] ~= WW.BlackoutKick then
		return WW.BlackoutKick;
	end
	
	--if energy >= 45 and energyTimeToMax < (gcd * 3) and spellCombo[1] ~= WW.TigerPalm then
	--	return WW.TigerPalm;
	--end
end


function Monk:WindwalkerAoe()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell, spellHistory, spellCombo,
	chi, chiMax, energy, energyRegen, energyMax, energyTimeToMax, energyInOneSec, targets, gcd, ispvp =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.spellHistory, fd.spellCombo,
	fd.chi, fd.chiMax, fd.energy, fd.energyRegen, fd.energyMax, fd.energyTimeToMax, fd.energyInOneSec, fd.targets, fd.gcd, fd.ispvp;
	
	local MotC = GetSpellCount("Spinning Crane Kick");
	local _, _, _, FoFCastTime = GetSpellInfo(113656);
	local currentSpeed = GetUnitSpeed("player") / 7 * 100;

	if talents[WW.WhirlingDragonPunch] and cooldown[WW.WhirlingDragonPunch].ready and
		buff[WW.WDPBuff].up
	then
		return WW.WhirlingDragonPunch;
	end
	
	if buff[WW.DanceOfChiJiBuff].up and spellCombo[1] ~= WW.SpinningCraneKick and currentSpell ~= WW.SpinningCraneKick then
		return WW.SpinningCraneKick;
	end

	if cooldown[WW.FistsOfFury].ready and chi >= 3 and (energyTimeToMax > FoFCastTime or chiMax - chi <= 1) then
		return WW.FistsOfFury;
	end
	
	if cooldown[WW.RisingSunKick].ready and chi >= 2 and
		(talents[WW.WhirlingDragonPunch] and cooldown[WW.WhirlingDragonPunch].remains < 4 + gcd) and
		(cooldown[WW.FistsOfFury].remains > 3 or chi >= 5) then
		return WW.RisingSunKick;
	end

	if talents[WW.RushingJadeWind] and not buff[WW.RushingJadeWind].up and energyTimeToMax > 1 then
		return WW.RushingJadeWind;
	end
	
	if spellCombo[1] ~= WW.SpinningCraneKick and currentSpell ~= WW.SpinningCraneKick and chi >= 2 and (((chi > 3 or cooldown[WW.FistsOfFury].remains > 6) and (chi >= 5 or cooldown[WW.FistsOfFury].remains > 2)) or energyTimeToMax <= 3) then
		return WW.SpinningCraneKick;
	end

	if cooldown[WW.ExpelHarm].ready and energy >= 15 and chiMax - chi >= 1 then
		return WW.ExpelHarm;
	end
	
	if cooldown[WW.FistOfTheWhiteTiger].ready and talents[WW.FistOfTheWhiteTiger] and energy >= 40 and chiMax - chi >= 3 then
		return WW.FistOfTheWhiteTiger;
	end
	
	if cooldown[WW.ChiBurst].ready and currentSpeed < 1 and talents[WW.ChiBurst] and chiMax - chi >= 2 then
		return WW.ChiBurst;
	end
	
	if energy >= 50 and chiMax - chi >= 2 and spellCombo[1] ~= WW.TigerPalm then
		return WW.TigerPalm;
	end
	
	if cooldown[WW.ChiWave].ready and talents[WW.ChiWave] then
		return WW.ChiWave;
	end
	
	if cooldown[WW.FlyingSerpentKick].ready and not buff[WW.BokProc].up and talents[WW.ChiBurst] then
		return WW.FlyingSerpentKick;
	end

	if (buff[WW.BokProc].up or (spellCombo[1] == WW.TigerPalm and chi == 2 and cooldown[WW.FistsOfFury].remains < 3) or (chiMax - chi <= 1 and spellCombo[1] == WW.SpinningCraneKick and energyTimeToMax < 3) or MotC < 3) and spellCombo[1] ~= WW.BlackoutKick then
		return WW.BlackoutKick;
	end
end


function Monk:WindwalkerWeaponsOfOrder()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell, spellHistory, spellCombo,
	chi, chiMax, energy, energyRegen, energyMax, energyTimeToMax, energyInOneSec, targets, gcd, ispvp =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.spellHistory, fd.spellCombo,
	fd.chi, fd.chiMax, fd.energy, fd.energyRegen, fd.energyMax, fd.energyTimeToMax, fd.energyInOneSec, fd.targets, fd.gcd, fd.ispvp;
	
	local MotC = GetSpellCount("Spinning Crane Kick");
	local _, _, _, FoFCastTime = GetSpellInfo(113656);
	local currentSpeed = GetUnitSpeed("player") / 7 * 100;
	
	if cooldown[WW.RisingSunKick].ready and (chi >= 2 or (chi >= 1 and buff[WW.WeaponsOfOrderChiBuff].up)) then
		return WW.RisingSunKick;
	end
	
	if buff[WW.DanceOfChiJiBuff].up and spellCombo[1] ~= WW.SpinningCraneKick then
		return WW.SpinningCraneKick;
	end
	
	if talents[WW.WhirlingDragonPunch] and cooldown[WW.WhirlingDragonPunch].ready and
		buff[WW.WDPBuff].up and targets >= 2
	then
		return WW.WhirlingDragonPunch;
	end
	
	if chi >= 1 and targets >= 3 and buff[WW.WeaponsOfOrderChiBuff].up and spellCombo[1] ~= WW.SpinningCraneKick and currentSpell ~= WW.SpinningCraneKick then
		return WW.SpinningCraneKick;
	end
	
	if buff[WW.WeaponsOfOrderChiBuff].up and targets <= 2 and spellCombo[1] ~= WW.BlackoutKick then
		return WW.BlackoutKick;
	end
	
	if talents[WW.WhirlingDragonPunch] and cooldown[WW.WhirlingDragonPunch].ready and
		buff[WW.WDPBuff].up
	then
		return WW.WhirlingDragonPunch;
	end
	
	if cooldown[WW.FistsOfFury].ready and (chi >= 3 or (chi >= 2 and buff[WW.WeaponsOfOrderChiBuff].up)) then
		return WW.FistsOfFury;
	end
	
	if cooldown[WW.FistOfTheWhiteTiger].ready and talents[WW.FistOfTheWhiteTiger] and energy >= 40 and chiMax - chi >= 3 then
		return WW.FistOfTheWhiteTiger;
	end
	
	if energy > 15 and cooldown[WW.ExpelHarm].ready then
		return WW.ExpelHarm;
	end
	
	if cooldown[WW.ChiBurst].ready and currentSpeed < 1 and talents[WW.ChiBurst] and ((targets == 1 and chiMax - chi >= 4) or (targets > 1 and chiMax - chi >= 3)) then
		return WW.ChiBurst;
	end
	
	if chiMax - chi >= 2 and energy >= 50 and spellCombo[1] ~= WW.TigerPalm then
		return WW.TigerPalm;
	end
	
	if chi >= 3 and buff[WW.WeaponsOfOrderChiBuff].up then
		return WW.BlackoutKick;
	end
	
	if cooldown[WW.FlyingSerpentKick].ready and talents[WW.ChiBurst] then
		return WW.FlyingSerpentKick;
	end
end
