#pragma semicolon 1
#pragma newdecls required

//BASE OFF IT RN
//Pablo will get an RNG weapon system 
//upon getting the Amby, he will do the new guntaunt after that he fully shoots a big laser like attack
//anything that hits it gets debuffed for 10-20s, the first victim however gets damaged.
//Le Etrangle shoots fast deals weak damage last bullet is a aoe attack.
//Teleport of devastation, Pablo does the comp animation (wait/loose) after that teleports behind the victim 
//upon teleporting, Pablo does a Ion strike. Anyone near the victim will create more ion strikes
//whoever had the ion strike gets the full damage, anyone else takes less by 55%.
//Rage. upon activation pablo is doing the disco taunt and gains 50% resistance, doing repeated AoE effects.

//Add "trickstab" knockbacks the victim and he gains an attack rate buff.

static int i_LaserHits = 0;

static char g_DeathSounds[][] = {
	"npc/zombie/zombie_die1.wav",
};

static char g_HurtSounds[][] = {
	"npc/zombie/zombie_pain1.wav",
};

static char g_IdleSounds[][] = {
	"npc/zombie/zombie_voice_idle1.wav",
};

static char g_IdleAlertedSounds[][] = {
	"npc/zombie/zombie_alert1.wav",
};
static char g_IntroSound[][] = {
	"npc/zombie_poison/pz_call1.wav",
};

static char g_MeleeHitSounds[][] = {
	"npc/fast_zombie/claw_strike1.wav",
};
static char g_MeleeAttackSounds[][] = {
	"npc/zombie/zo_attack1.wav",
};

static char g_MeleeMissSounds[][] = {
	"npc/fast_zombie/claw_miss1.wav",
};
static char g_RageSound[][] = {
	"npc/fast_zombie/claw_miss1.wav",
};
static char g_BackstabSounds[][] = {
	"vo/spy_jaratehit03.mp3",
};
static char g_BackstabSFX[][] = {
	"player/spy_shield_break.wav",
};

static float fl_DefaultSpeed_Pablo_Gonzales = 300.0;

public void Pablo_Gonzales_OnMapStart_NPC()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_IntroSound);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	PrecacheSoundArray(g_MeleeMissSounds);
	PrecacheSoundArray(g_RageSound);
	PrecacheSoundArray(g_BackstabSounds);
	PrecacheSoundArray(g_BackstabSFX);
	PrecacheSoundCustom("#zombiesurvival/temperals/special/gonzales_bgm.mp3");

	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Pablo Gonzales");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_boss_pablo_gonzales");
	strcopy(data.Icon, sizeof(data.Icon), "norm_headcrab_zombie");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Hidden;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int ally, const char[] data)
{
	return Pablo_Gonzales(vecPos, vecAng, ally, data);
}

methodmap Pablo_Gonzales < CClotBody
{
	property int i_Hit
	{
		public get()							{ return i_OverlordComboAttack[this.index]; }
		public set(int TempValueForProperty) 	{ i_OverlordComboAttack[this.index] = TempValueForProperty; }
	}
	property int i_Stabbed
	{
		public get()							{ return i_AttacksTillMegahit[this.index]; }
		public set(int TempValueForProperty) 	{ i_AttacksTillMegahit[this.index] = TempValueForProperty; }
	}
	property int i_WeaponArg
	{
		public get()							{ return i_TimesSummoned[this.index]; }
		public set(int TempValueForProperty) 	{ i_TimesSummoned[this.index] = TempValueForProperty; }
	}
	property float fl_Rage_Amount
	{
		public get()							{ return fl_NextRangedBarrage_Singular[this.index]; }
		public set(float TempValueForProperty) 	{ fl_NextRangedBarrage_Singular[this.index] = TempValueForProperty; }
	}
	property float fl_Rage_Requirement
	{
		public get()							{ return fl_NextRangedBarrage_Spam[this.index]; }
		public set(float TempValueForProperty) 	{ fl_NextRangedBarrage_Spam[this.index] = TempValueForProperty; }
	}
	property float fl_Weapon_Timer
	{
		public get()							{ return fl_movedelay[this.index]; }
		public set(float TempValueForProperty) 	{ fl_movedelay[this.index] = TempValueForProperty; }
	}
	property float fl_LaserGun_AboutToShoot
	{
		public get()							{ return fl_AbilityOrAttack[this.index][0]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][0] = TempValueForProperty; }
	}
	property float fl_AbilityGain_Timer
	{
		public get()							{ return fl_AbilityOrAttack[this.index][1]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][1] = TempValueForProperty; }
	}
	property float fl_Delay_RageEffect
	{
		public get()							{ return fl_AbilityOrAttack[this.index][2]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][2] = TempValueForProperty; }
	}
	property float fl_Trickstab_Buff
	{
		public get()							{ return fl_AbilityOrAttack[this.index][3]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][3] = TempValueForProperty; }
	}
	public void PlayBackstabSfx(int target)
	{
		EmitSoundToAll(g_BackstabSounds[GetRandomInt(0, sizeof(g_BackstabSounds) - 1)], this.index, SNDCHAN_AUTO, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
		EmitSoundToAll(g_BackstabSFX[GetRandomInt(0, sizeof(g_BackstabSFX) - 1)], this.index, SNDCHAN_AUTO, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME, 90);
		if(target <= MaxClients)
		{
			EmitSoundToClient(target, g_BackstabSounds[GetRandomInt(0, sizeof(g_BackstabSounds) - 1)], target, SNDCHAN_AUTO, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
			EmitSoundToClient(target, g_BackstabSFX[GetRandomInt(0, sizeof(g_BackstabSFX) - 1)], target, SNDCHAN_AUTO, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
		}
	}
	public void PlayIdleSound() {
		if(this.m_flNextIdleSound > GetGameTime(this.index))
			return;
		EmitSoundToAll(g_IdleSounds[GetRandomInt(0, sizeof(g_IdleSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 90);
		this.m_flNextIdleSound = GetGameTime(this.index) + GetRandomFloat(3.0, 6.0);
	}
	public void PlayIntro() {
		if(this.m_flNextIdleSound > GetGameTime(this.index))
			return;
		EmitSoundToAll(g_IntroSound[GetRandomInt(0, sizeof(g_IntroSound) - 1)], _, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME-0.2, 90);
		this.m_flNextIdleSound = GetGameTime(this.index) + 8.0;
	}
	public void PlayHurtSound() {
		if(this.m_flNextHurtSound > GetGameTime(this.index))
			return;
			
		this.m_flNextHurtSound = GetGameTime(this.index) + 0.4;
		
		EmitSoundToAll(g_HurtSounds[GetRandomInt(0, sizeof(g_HurtSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 90);
	}
	public void PlayDeathSound() {
		EmitSoundToAll(g_DeathSounds[GetRandomInt(0, sizeof(g_DeathSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 90);
	}
	public void PlayMeleeSound() {
		EmitSoundToAll(g_MeleeAttackSounds[GetRandomInt(0, sizeof(g_MeleeAttackSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 90);
	}
	public void PlayMeleeHitSound() {
		EmitSoundToAll(g_MeleeHitSounds[GetRandomInt(0, sizeof(g_MeleeHitSounds) - 1)], this.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 90);
	}
	public void PlayMeleeMissSound() {
		EmitSoundToAll(g_MeleeMissSounds[GetRandomInt(0, sizeof(g_MeleeMissSounds) - 1)], this.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 90);
	}
	public void PlayRageSound() {
		EmitSoundToAll(g_RageSound[GetRandomInt(0, sizeof(g_RageSound) - 1)], _, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 90);
	}
	public void Rage()
	{
		float gameTime = GetGameTime(this.index);
		this.fl_Rage_Amount -= this.fl_Rage_Requirement;
		float timer = this.fl_AbilityGain_Timer - gameTime;
		if(timer < 4.0)
		{
			this.fl_AbilityGain_Timer += 4.0;
		}
		else if(timer <= 0.0)
		{
			this.fl_AbilityGain_Timer = gameTime + 4.0;
		}
		this.PlayRageSound();
		
		//ADD RAGE STUFF HERE
	}
	public bool Rage_FullyCharged()
	{
		return (this.fl_Rage_Amount >= this.fl_Rage_Requirement);
	}
	public bool DenyRageUsage()
	{
		if(this.i_WeaponArg == 1 || this.i_WeaponArg == 3 || this.i_WeaponArg == 4)
			return true;
		
		return false;
	}
	public void Rage_Requirement_Value()
	{
		float requirement = float(ReturnEntityMaxHealth(this.index));
		requirement *= 0.35;//65% less of his current hp.
		this.fl_Rage_Requirement = requirement;
	}
	public void ArmorSet(float resistance = -1.0, bool uber = false)
	{
		if(resistance != -1.0 && resistance >= 0.0)
		{
			this.m_flMeleeArmor = resistance;
			this.m_flRangedArmor = resistance;
		}
		b_NpcIsInvulnerable[this.index] = uber;
	}
	public void AnimChanger(int type = 0, char anim[255] = "", float rate = 9999.0, float cycle = 9999.0, bool walking = true)
	{
		this.m_bisWalking = walking;
		if(!type)
		{
			if(anim[0])
			{
				int iActivity = this.LookupActivity(anim);
				if(iActivity > 0) 
					this.StartActivity(iActivity);
			}
		}
		else
		{
			if(anim[0])
			{
				this.AddActivityViaSequence(anim);
			}
		}
		
		if(rate != 9999.0)
			this.SetPlaybackRate(rate);
		
		if(cycle != 9999.0)
			this.SetCycle(cycle);
	}
	public void RemoveWeapon()
	{
		if(this.IsValidEntity(this.m_iWearable6))
		{
			RemoveEntity(this.m_iWearable6);
		}
	}
	public void GetAnimUsage(int usage)
	{
		bool disable = false;
		switch(usage)
		{
			case 0, 3:
			{
				this.AnimChanger(_, "ACT_MP_RUN_MELEE");
			}
			case 1://Amby Laser Taunt
			{
				this.AnimChanger(1, "taunt_the_punchline",_, _, false);
				disable = true;
			}
			case 2:
			{
				this.AnimChanger(_, "ACT_MP_RUN_SECONDARY");
			}
			case 4://Rage Taunt
			{
				this.AnimChanger(1, "taunt06", _, _, false);
				disable = true;
			}
		}
		this.ClearanceHelp(disable);
	}
	public void ChangeWeapons(int usage = 0)//DEFAULT IS MELEE
	{
		this.RemoveWeapon();
		char weaponchar[255] = "";
		float timer = 10.0;
		switch(usage)
		{
			case 1: {
				i_LaserHits = 0;
				weaponchar = "models/weapons/c_models/c_ambassador/c_ambassador.mdl";
				timer = 6.35;
				this.fl_LaserGun_AboutToShoot = GetGameTime(this.index) + (timer/2);
				this.ArmorSet(0.5);
			}
			case 2: {
				weaponchar = "models/weapons/c_models/c_letranger/c_letranger.mdl";
			}
			case 3: {
				timer = 7.0;
				weaponchar = "models/workshop_partner/weapons/c_models/c_shogun_kunai/c_shogun_kunai.mdl";
			}
			case 4:{
				timer = 6.0;
			}
			default: {
				usage = 0;
				timer = 0.0;
				weaponchar = "models/weapons/c_models/c_voodoo_pin/c_voodoo_pin.mdl";
				this.ArmorSet(1.0);
			}
		}
		this.GetAnimUsage(usage);
				
		this.i_WeaponArg = usage;

		if(timer != 0.0)
			this.fl_Weapon_Timer = GetGameTime(this.index);
		
		if(weaponchar[0])
			this.m_iWearable6 = this.EquipItem("weapon_bone", weaponchar);
	}
	public void ClearanceHelp(bool disable = false)
	{
		if(!disable)
		{
			ApplyStatusEffect(this.index, this.index, "Clear Head", FAR_FUTURE);	
			ApplyStatusEffect(this.index, this.index, "Solid Stance", FAR_FUTURE);	
			ApplyStatusEffect(this.index, this.index, "Fluid Movement", FAR_FUTURE);
		}
		else
		{
			RemoveSpecificBuff(this.index, "Clear Head");
			RemoveSpecificBuff(this.index, "Solid Stance");
			RemoveSpecificBuff(this.index, "Fluid Movement");
		}
	}
	public void CleanUpPreset()
	{
		this.fl_Weapon_Timer = 0.0;
		this.fl_Delay_RageEffect = 0.0;
		this.fl_Rage_Amount = 0.0;
		this.fl_LaserGun_AboutToShoot = 0.0;
		this.fl_AbilityGain_Timer = GetGameTime(this.index) + 10.0;
		this.i_Stabbed = 0;
		this.m_flNextMeleeAttack = 0.0;
		this.Rage_Requirement_Value();
	}

	public Pablo_Gonzales(float vecPos[3], float vecAng[3], int ally, const char[] data)
	{
		Pablo_Gonzales npc = view_as<Pablo_Gonzales>(CClotBody(vecPos, vecAng, "models/player/heavy.mdl", "1.25", "30000", ally, false));
		
		i_NpcWeight[npc.index] = 5;
		
		FormatEx(c_HeadPlaceAttachmentGibName[npc.index], sizeof(c_HeadPlaceAttachmentGibName[]), "head");
		
		npc.ChangeWeapons();

		bool clone = StrContains(data, "clone") != -1;
		npc.m_fbGunout = clone ? true : false;
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_GIANT;	
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		npc.m_bDissapearOnDeath = true;

		npc.CleanUpPreset();
		
		if(!clone)
		{
			bool noscaling = !(StrContains(data, "Scaling") != -1);
			RaidBossStatus Raid;
			Raid.israid = false; //If raid true, If superboss false
			Raid.allow_builings = true;
			Raid.Reduction_45 = 0.15;
			Raid.Reduction_60 = 0.3;
			Raid.Reduction_Last = 0.4;
			Raid.RaidTime = 300.0;
			Raid.ignore_scaling = noscaling;
			
			//If you want to check if there is already a raid, and want to add args for that !Raid.Setup(true, npc);
			//viceversa
			if(Raid.Setup(true, npc, data))//We are the raid!, if not use else or Check()
			{
				//add additional things
				if(noscaling)
					RaidModeScaling = 0.0;
				
				npc.m_iWearable5 = TF2_CreateGlow_White(npc.index, "models/player/spy.mdl", npc.index, 1.35);
				if(IsValidEntity(npc.m_iWearable5))
				{
					SetEntProp(npc.m_iWearable5, Prop_Send, "m_bGlowEnabled", false);
					SetEntityRenderMode(npc.m_iWearable5, RENDER_ENVIRONMENTAL);
					//Cannot be used on the actual npc. Reason is, for whatever reason fire removes it.
					Start_TE_Body_Effect(npc.m_iWearable5, "utaunt_heavyrain_parent");
				}
				CPrintToChat("{crimson}Difficulty {default}- {yellow}⁂");
			}
			//Normal npcs, if there is a raid going on and they managed to get spawned
			//if(Raid.Check())//if there is a raid going lets this arg instead
			//{
			//	the stuff
			//}

			Raid.PlayMusic("#zombiesurvival/temperals/special/gonzales_bgm.mp3", "Discussion -PANIC- Instrumental Mix Cover (Danganronpa)", "Vetrom", 215);
		}
		int skin = 1;
		SetEntProp(npc.index, Prop_Send, "m_nSkin", skin);

		//SetVariantInt(1);
		//AcceptEntityInput(npc.index, "SetBodyGroup");
		
		npc.m_iWearable1 = npc.EquipItem("head", "models/player/items/all_class/ghostly_gibus_spy.mdl", "", skin);
		npc.m_iWearable2 = npc.EquipItem("head", "models/player/items/all_class/all_class_oculus_spy_on.mdl", "", skin);
		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/spy/spr17_the_upgrade/spr17_the_upgrade.mdl", "", skin);
		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/scout/robo_all_mvm_canteen/robo_all_mvm_canteen.mdl", "", skin);
		//IDLE
		
		func_NPCDeath[npc.index] = Pablo_Gonzales_NPCDeath;
		func_NPCThink[npc.index] = Pablo_Gonzales_ClotThink;
		func_NPCOnTakeDamage[npc.index] = Pablo_Gonzales_OnTakeDamage;
		npc.m_flSpeed = fl_DefaultSpeed_Pablo_Gonzales;

		npc.StartPathing();
		if(!clone)
			npc.PlayIntro();

		return npc;
	}
}

static void Pablo_Gonzales_ClotThink(int iNPC)
{
	Pablo_Gonzales npc = view_as<Pablo_Gonzales>(iNPC);

	float gameTime = GetGameTime(npc.index);
	
	if(npc.m_flNextDelayTime > gameTime)
	{
		return;
	}
	
	npc.m_flNextDelayTime = gameTime + DEFAULT_UPDATE_DELAY_FLOAT;
	
	npc.Update();

	RaidBossStatus Raid;
	if(!Raid.Check() && EntRefToEntIndex(RaidBossActive) != npc.index)
	{
		RaidBossActive = EntIndexToEntRef(npc.index);
	}
	
	if(npc.m_blPlayHurtAnimation)
	{
		npc.m_blPlayHurtAnimation = false;
		if(!npc.m_flAttackHappenswillhappen)
			npc.AddGesture("ACT_MP_GESTURE_FLINCH_CHEST", false);
		npc.PlayHurtSound();
	}
	npc.Anger = !npc.Anger;//Passively angry!, cause he sucks ingame.
	if(!npc.Anger)
	{
		npc.m_flSpeed = (fl_DefaultSpeed_Pablo_Gonzales * 1.07);
	}
	else
	{
		npc.m_flSpeed = fl_DefaultSpeed_Pablo_Gonzales;
	}
	
	if(npc.m_flNextThinkTime > gameTime)
	{
		return;
	}

	switch(npc.i_WeaponArg)
	{
		case 0:
		{
			if(npc.fl_AbilityGain_Timer < gameTime)
			{
				int abilityRng = GetRandomInt(1, 3);
				npc.ChangeWeapons(abilityRng);
			}
		}
		case 4:
		{
			//Add all logic in here
			if(npc.fl_Weapon_Timer < gameTime)
			{
				npc.i_WeaponArg = 5;
			}
			else
			{
				
			}
		}
		default:
		{
			if(npc.fl_Weapon_Timer && npc.fl_Weapon_Timer < gameTime)
			{
				npc.AnimChanger(_, "ACT_MP_RUN_MELEE");
				npc.ChangeWeapons();
				npc.fl_Weapon_Timer = 0.0;
				npc.fl_AbilityGain_Timer = gameTime + 12.0;
			}
		}
	}
	
	npc.m_flNextThinkTime = gameTime + 0.1;

	if(LastMann)
	{
		if(!npc.m_fbGunout)
		{
			npc.m_fbGunout = true;
			Pablo_Gonzales_Lastman_Messages(npc);
		}
	}

	//bool silence = NpcStats_IsEnemySilenced(npc.index);

	if(npc.m_flGetClosestTargetTime < gameTime)
	{
		npc.m_iTarget = GetClosestTarget(npc.index);
		npc.m_flGetClosestTargetTime = gameTime + GetRandomRetargetTime();
		npc.StartPathing();
	}
	
	int closest = npc.m_iTarget;
	
	if(IsValidEnemy(npc.index, closest))
	{
		float vecTarget[3]; WorldSpaceCenter(closest, vecTarget);
			
		float VecSelfNpc[3]; WorldSpaceCenter(npc.index, VecSelfNpc);
		float flDistanceToTarget = GetVectorDistance(vecTarget, VecSelfNpc, true);
				
		//Predict their pos.
		if(flDistanceToTarget < npc.GetLeadRadius())
		{
			float vPredictedPos[3]; PredictSubjectPosition(npc, closest, _, _, vPredictedPos);
			npc.SetGoalVector(vPredictedPos);
		}
		else
		{
			npc.SetGoalEntity(closest);
		}

		if(npc.i_WeaponArg == 4)
		{
			float time = npc.fl_LaserGun_AboutToShoot - gameTime;
			if(time >= 99999.0 || time < 3.35 && time > 3.0)
			return;

			int color[4] = {40, 60, 255, 255};
			bool shoot = false;
			if(time < 2.0)
			{
				color = {255, 40, 60, 255};
				npc.fl_LaserGun_AboutToShoot = 999999.0;
				shoot = true;
			}
			else
			{
				
			}
			float radius = 1000.0;
			TE_Cube_Line_Visual(npc, radius, vecTarget, VecSelfNpc, color);
			if(shoot)
			{
				Ruina_Laser_Logic Laser;
				Laser.client = npc.index;
				Laser.Start_Point = VecSelfNpc;
				Laser.End_Point = vecTarget;
				Laser.Radius = float(RoundFloat(radius / 28.5));
				Laser.DoForwardTrace_Custom(vecTarget, VecSelfNpc, radius);
				Laser.Enumerate_Simple();

				float damage = 850.0;
				float tempdmg = damage/3;
				if(tempdmg < 1)
					tempdmg = 1;
				
				for (int loop = 0; loop < sizeof(i_Ruina_Laser_BEAM_HitDetected); loop++)
				{
					int vic = i_Ruina_Laser_BEAM_HitDetected[loop];
					if(!vic)//No more victims.
						break;
					
					if(i_LaserHits <= 0)
					{
						SDKHooks_TakeDamage(vic, npc.index, npc.index, damage, DMG_PLASMA, -1, _, vecTarget);
					}
					else
					{
						IncreaseEntityDamageTakenBy(vic, 0.35, GetRandomFloat(10.0, 20.0), true);
						SDKHooks_TakeDamage(vic, npc.index, npc.index, tempdmg, DMG_PLASMA, -1, _, vecTarget);
					}
					i_LaserHits++;
				}
			}
			return;
		}
		
		//Target close enough to hit
		if(npc.i_WeaponArg != 2)//If it isn't leetrangle
			Pablo_Gonzales_SelfDefense(npc, gameTime, npc.m_iTarget, flDistanceToTarget);
		else
			Pablo_Gonzales_SelfDefense_Gun(npc, gameTime, npc.m_iTarget, flDistanceToTarget);
		
	}
	else
	{
		//npc.StopPathing();
		//npc.m_bPathing = false;
		npc.m_flGetClosestTargetTime = 0.0;
		npc.m_iTarget = GetClosestTarget(npc.index);
	}
	//npc.PlayIdleSound();
}

static void Pablo_Gonzales_SelfDefense(Pablo_Gonzales npc, float gameTime, int target, float flDistanceToTarget)
{
	if(gameTime > npc.m_flNextMeleeAttack)
	{
		if(flDistanceToTarget < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 1.25))
		{
			int Enemy_I_See;
			Enemy_I_See = Can_I_See_Enemy(npc.index, target);

			if(IsValidEnemy(npc.index, Enemy_I_See))
			{
				bool trickstab_buff = (npc.fl_Trickstab_Buff > gameTime);
				npc.m_iTarget = Enemy_I_See;
				float damage = 750.0;
				npc.PlayMeleeSound();
				bool trick = view_as<bool>(npc.i_WeaponArg == 3);
				npc.AddGesture(trick ? "ACT_MP_ATTACK_STAND_MELEE_SECONDARY" : "ACT_MP_ATTACK_STAND_MELEE");
				float attackrate = trickstab_buff ? 0.27 : 0.65;
				npc.m_flNextMeleeAttack = gameTime + attackrate;
				int frames = 11;
				DataPack pack = new DataPack();
				pack.WriteCell(EntIndexToEntRef(npc.index));
				pack.WriteFloat(damage);
				pack.WriteFunction(trick ? Pablo_OnHit_Trickstab : Pablo_OnHit);
				pack.WriteFloat(trick ? 300.0 : 0.0);
				RequestFrames(Temperals_SingleDamage_Melee, frames, pack);
			}
		}
	}
}
static void Pablo_Gonzales_SelfDefense_Gun(Pablo_Gonzales npc, float gameTime, int target, float flDistanceToTarget)
{
	if(npc.m_flNextRangedSpecialAttack)
	{
		if(npc.m_flNextRangedSpecialAttack < gameTime)
		{
			npc.m_flNextRangedSpecialAttack = 0.0;
			//Pablo_Gonzales_Hellfire_Attack(npc);
		}
		return;
	}

	if(gameTime > npc.m_flNextRangedAttack)
	{
		if(flDistanceToTarget > (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 1.25) && flDistanceToTarget < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 10.0))
		{
			int Enemy_I_See;			
			Enemy_I_See = Can_I_See_Enemy(npc.index, target);
					
			if(IsValidEnemy(npc.index, Enemy_I_See))
			{
				npc.m_iTarget = Enemy_I_See;
				npc.PlayMeleeSound();
				npc.AddGesture("ACT_MP_THROW");//ACT_MP_ATTACK_STAND_ITEM1
						
				npc.m_flNextRangedSpecialAttack = gameTime + 0.15;
				npc.m_flNextRangedAttack = gameTime + 1.85;
			}
		}
	}
}

static void Pablo_OnHit(int entity, int victim, float damage)
{
	//Add trickstab buff attack speed in here.
	Pablo_Gonzales npc = view_as<Pablo_Gonzales>(entity);
	npc.PlayMeleeHitSound();
}
static void Pablo_OnHit_Trickstab(int entity, int victim, float damage)
{
	//Add trickstab buff attack speed in here.
	Pablo_Gonzales npc = view_as<Pablo_Gonzales>(entity);
	npc.fl_Weapon_Timer = 0.0;
	npc.fl_Trickstab_Buff = GetGameTime(npc.index) + 4.0;
	npc.PlayMeleeHitSound();
}

static Action Pablo_Gonzales_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	//Valid attackers only.
	if(attacker < 1)
		return Plugin_Continue;

	Pablo_Gonzales npc = view_as<Pablo_Gonzales>(victim);
	
	if(Temperals_Stabbed(attacker, victim, weapon, damagetype))
	{	
		npc.i_Stabbed++;
		npc.PlayBackstabSfx(attacker);
		if(npc.i_Stabbed >= 3)
		{
			Pablo_Gonzales_Backstab_Messages(attacker);
			float dmg = 200.0, radius = 160.0;
			//dmg *= RaidModeScaling;
			Explode_Logic_Custom(dmg, npc.index, npc.index, -1, _, radius, _, _, true);
			npc.i_Stabbed = 0;
		}
		else
		{
			
		}
	}
	if(npc.Rage_FullyCharged() && !npc.DenyRageUsage())
	{
		npc.Rage();
	}
	else
	{
		npc.fl_Rage_Amount += damage;
	}

	return Plugin_Continue;
}

static void Pablo_Gonzales_NPCDeath(int entity)
{
	Pablo_Gonzales npc = view_as<Pablo_Gonzales>(entity);

	if(IsValidEntity(npc.m_iWearable1))
		RemoveEntity(npc.m_iWearable1);

	if(IsValidEntity(npc.m_iWearable2))
		RemoveEntity(npc.m_iWearable2);

	if(IsValidEntity(npc.m_iWearable3))
		RemoveEntity(npc.m_iWearable3);

	if(IsValidEntity(npc.m_iWearable4))
		RemoveEntity(npc.m_iWearable4);

	if(IsValidEntity(npc.m_iWearable5))
		RemoveEntity(npc.m_iWearable5);

	npc.RemoveWeapon();

	npc.PlayDeathSound();
	//if(Waves_GetRoundScale()+1 > 45)
	//{
	//	//Pablo_Gonzales_Death_Messages(GetRandomInt(0, 1));
	//}
	//else
	//{
	//	//Pablo_Gonzales_Death_Messages(GetRandomInt(2, 3));
	//}

	if(npc.index == EntRefToEntIndex(RaidBossActive))
	{
		RaidBossActive = INVALID_ENT_REFERENCE;
	}

	Citizen_MiniBossDeath(entity);
}

static void Pablo_Gonzales_Reply(const char[] text)
{
	CPrintToChatAll("{crimson}???{default}:{yellow} %s", text);
}

static void Pablo_Gonzales_Lastman_Messages(Pablo_Gonzales npc)
{
	char text[255];
	switch(GetRandomInt(0, 5))
	{
		case 0:
		{
			FormatEx(text, sizeof(text), "");
		}
		case 1:
		{
			FormatEx(text, sizeof(text), "");
		}
		case 2:
		{
			FormatEx(text, sizeof(text), "");
		}
		case 3:
		{
			FormatEx(text, sizeof(text), "");
		}
		case 4:
		{
			FormatEx(text, sizeof(text), "");
		}
		case 5:
		{
			FormatEx(text, sizeof(text), "");
		}
		case 6:
		{
			FormatEx(text, sizeof(text), "");
		}
	}

	Pablo_Gonzales_Reply(text);
}
static void Pablo_Gonzales_Backstab_Messages(int stabber)
{
	char text[255];
	switch(GetRandomInt(0, 3))
	{
		case 0:
		{
			FormatEx(text, sizeof(text), "", stabber);
		}
		case 1:
		{
			FormatEx(text, sizeof(text), "");
		}
		case 2:
		{
			FormatEx(text, sizeof(text), "");
		}
		case 3:
		{
			FormatEx(text, sizeof(text), "", stabber);
		}
	}
	Pablo_Gonzales_Reply(text);
}
static void Pablo_Gonzales_Final_Messages(int line)
{
	char text[255];
	switch(line)
	{
		case 0:
		{
			FormatEx(text, sizeof(text), "");
		}
		case 1:
		{
			FormatEx(text, sizeof(text), "");
		}
		case 2:
		{
			FormatEx(text, sizeof(text), "");
		}
		case 3:
		{
			FormatEx(text, sizeof(text), "");
		}
	}
	Pablo_Gonzales_Reply(text);
}
void TE_Cube_Line_Visual(CClotBody npc, float VectorForward = 1000.0, float VectorTarget[3], float VectorStart[3], int color[4] = {255, 255, 255, 255}, int size = 35, float hitrange = 35.0, float time = 0.05019608415)
{
	if(time <= 0.05019608415)
	{
		time = 0.05019608415;
	}
	float vecForward[3], Angles[3];

	GetVectorAnglesTwoPoints(VectorStart, VectorTarget, Angles);

	GetAngleVectors(Angles, vecForward, NULL_VECTOR, NULL_VECTOR);

	float VectorTarget_2[3];
	for(int i = 0 ; i <= 3 ; i++)
		VectorTarget_2[i] = VectorStart[i] + vecForward[i] * VectorForward;

	float diameter = float(size * 4);

	for(int BeamCube = 0; BeamCube < 4 ; BeamCube++)
	{
		float OffsetFromMiddle[3];
		switch(BeamCube)
		{
			case 0:
				OffsetFromMiddle = {0.0, hitrange, hitrange};
			case 1:
				OffsetFromMiddle = {0.0, -hitrange, -hitrange};
			case 2:
				OffsetFromMiddle = {0.0, hitrange, -hitrange};
			case 3:
				OffsetFromMiddle = {0.0, -hitrange, hitrange};
		}
		float AnglesEdit[3], VectorStartEdit[3];
		AnglesEdit = Angles;//EditTheSameLoop(AnglesEdit, Angles);
		VectorStartEdit = VectorStart;//EditTheSameLoop(VectorStartEdit, VectorStart);

		GetBeamDrawStartPoint_Stock(npc.index, VectorStartEdit, OffsetFromMiddle, AnglesEdit);

		TE_SetupBeamPoints(VectorStartEdit, VectorTarget_2, Shared_BEAM_Laser, 0, 0, 0, time, ClampBeamWidth(diameter * 0.1), ClampBeamWidth(diameter * 0.1), 0, 0.0, color, 0);
		TE_SendToAll(0.0);
	}
}

//static void EditTheSameLoop(float[] endresult, float[] result, int loop = 3)
//{
//	for(int i = 0; i <= loop ; i++)
//		endresult[i] = result[i];
//}