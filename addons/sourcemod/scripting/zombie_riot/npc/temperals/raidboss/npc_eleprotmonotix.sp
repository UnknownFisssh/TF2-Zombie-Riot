#pragma semicolon 1
#pragma newdecls required
 
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

static char g_AllySummons[][] = {
	"npc_lastknight",
	"npc_lastknight",
};
static char g_HigherAllySummons[][] = {
	"npc_raid_phlogstorm",
};

static float fl_DefaultSpeed_Eleprotmon = 300.0;

//TODO: End raid
//Eleprotmon can spawn any part of his army whenever he wants if he feels like it
//Ofc a cd will be applied so it doesn't happen constantly
//Includes the very special npcs from 56-59 that only spawn once and don't exist in 60
//Upon nearing Eleprotmon you feel a heavy weight upon you (slowdown)
//That weight will give you something after defeating him

//Melee brute, Single Target, Rng Time on hitting melees
//Combo attacker, deals more dmg the more specific combos have been done
//attackspeed is faster the more combos have been applied, Has very weak aoe upon combos
//after certain amount of punishes he hits with a hefty aoe laser
//after that he goes in a stands,
//calling his demon-army (bosses) towards him to help him

//Demonic buffer
//buffs himself and his army's speed up to 60% for 8s
//whenever they are in radius, cd is 20s

public void Eleprotmon_OnMapStart_NPC()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_IntroSound);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	PrecacheSoundArray(g_MeleeMissSounds);
	PrecacheSoundCustom("#zombiesurvival/temperals/raids/phlog_bgm.mp3");

	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Eleprotmonotix The ???");//Demon king or undertaker? idfk
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_raid_eleprotmonotix");
	strcopy(data.Icon, sizeof(data.Icon), "norm_headcrab_zombie");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Hidden;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int ally, const char[] data)
{
	return Eleprotmon(vecPos, vecAng, ally, data);
}

methodmap Eleprotmon < CClotBody
{
	property float f_Temper_Timer
	{
		public get()							{ return fl_RangedSpecialDelay[this.index]; }
		public set(float TempValueForProperty) 	{ fl_RangedSpecialDelay[this.index] = TempValueForProperty; }
	}
	property float f_Temper_DamageRequirement
	{
		public get()							{ return fl_AngerDelay[this.index]; }
		public set(float TempValueForProperty) 	{ fl_AngerDelay[this.index] = TempValueForProperty; }
	}
	property float f_Temper_DamageTaken
	{
		public get()							{ return fl_GrappleCooldown[this.index]; }
		public set(float TempValueForProperty) 	{ fl_GrappleCooldown[this.index] = TempValueForProperty; }
	}
	property float f_AS_CD
	{
		public get()							{ return fl_Dead_Ringer_Invis[this.index]; }
		public set(float TempValueForProperty) 	{ fl_Dead_Ringer_Invis[this.index] = TempValueForProperty; }
	}
	property float f_Temper_Animation_Time
	{
		public get()							{ return fl_Dead_Ringer[this.index]; }
		public set(float TempValueForProperty) 	{ fl_Dead_Ringer[this.index] = TempValueForProperty; }
	}
	property bool b_Temper_On
	{
		public get()							{ return b_XenoInfectedSpecialHurt[this.index]; }
		public set(bool TempValueForProperty) 	{ b_XenoInfectedSpecialHurt[this.index] = TempValueForProperty; }
	}
	property bool b_Enraged
	{
		public get()							{ return b_NextRangedBarrage_OnGoing[this.index]; }
		public set(bool TempValueForProperty) 	{ b_NextRangedBarrage_OnGoing[this.index] = TempValueForProperty; }
	}
	property int i_Temper_Amount
	{
		public get()							{ return i_TimesSummoned[this.index]; }
		public set(int TempValueForProperty) 	{ i_TimesSummoned[this.index] = TempValueForProperty; }
	}
	property int i_Hit
	{
		public get()							{ return i_OverlordComboAttack[this.index]; }
		public set(int TempValueForProperty) 	{ i_OverlordComboAttack[this.index] = TempValueForProperty; }
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
	public void ArmorSet(float resistance = -1.0, bool uber = false)
	{
		if(resistance != -1.0 && resistance >= 0.0)
		{
			this.m_flMeleeArmor = resistance;
			this.m_flRangedArmor = resistance;
		}
		b_NpcIsInvulnerable[this.index] = uber;
	}
	
	public Eleprotmon(float vecPos[3], float vecAng[3], int ally, const char[] data)
	{
		Eleprotmon npc = view_as<Eleprotmon>(CClotBody(vecPos, vecAng, "models/player/heavy.mdl", "1.25", "30000", ally, false));
		
		i_NpcWeight[npc.index] = 5;
		
		FormatEx(c_HeadPlaceAttachmentGibName[npc.index], sizeof(c_HeadPlaceAttachmentGibName[]), "head");
		
		int iActivity = npc.LookupActivity("ACT_MP_RUN_MELEE");
		if(iActivity > 0) npc.StartActivity(iActivity);

		bool clone = StrContains(data, "clone") != -1;
		npc.m_fbGunout = clone ? true : false;

		npc.m_flNextMeleeAttack = 0.0;
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_GIANT;	
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		npc.m_bDissapearOnDeath = true;
		
		if(!clone)
		{
			RaidBossStatus Raid;
			Raid.israid = true; //If raid true, If superboss false
			Raid.allow_builings = true;
			Raid.Reduction_45 = 0.15;
			Raid.Reduction_60 = 0.3;
			Raid.Reduction_Last = 0.4;
			Raid.RaidTime = 300.0;
			i_Stabbed[npc.index] = 0;
			//If you want to check if there is already a raid, and want to add args for that !Raid.Setup(true, npc);
			//viceversa
			if(Raid.Setup(true, npc))//We are the raid!, if not use else or Check()
			{
				//add additional things
			}
			//Normal npcs, if there is a raid going on and they managed to get spawned
			//if(Raid.Check())//if there is a raid going lets this arg instead
			//{
			//	the stuff
			//}

			Raid.PlayMusic("#zombiesurvival/temperals/raids/phlog_bgm.mp3", "Quake II - Rage (Cover)", "DoomDood", 151);
		}
		
		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);

		//SetVariantInt(1);
		//AcceptEntityInput(npc.index, "SetBodyGroup");

		int skin = 1;
		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/player/items/heavy/sbox2014_leftover_trap/sbox2014_leftover_trap.mdl", "", skin);
		npc.m_iWearable2 = npc.EquipItem("head", "models/player/items/all_class/all_reckoning_eagonn_heavy.mdl", "", skin);
		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop_partner/player/items/heavy/dex_sarifarm/dex_sarifarm.mdl", "", skin);
		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/heavy/sum19_defiant_day/sum19_defiant_day.mdl", "", skin);
		//npc.m_iWearable5 = npc.EquipItem("head", "models/workshop/player/items/pyro/hwn2020_fire_tooth/hwn2020_fire_tooth.mdl", "", skin);
		//npc.m_iWearable6 = npc.EquipItem("head", "models/workshop/player/items/all_class/hwn2021_bone_cone_style2/hwn2021_bone_cone_style2_pyro.mdl", "", skin);
		TE_Particle("utaunt_cremation_black_parent", OFF_THE_MAP_NONCONST, _, _, npc.index);
		//IDLE
		
		func_NPCDeath[npc.index] = Eleprotmon_NPCDeath;
		func_NPCThink[npc.index] = Eleprotmon_ClotThink;
		func_NPCOnTakeDamage[npc.index] = Eleprotmon_OnTakeDamage;
		npc.m_flSpeed = fl_DefaultSpeed_Eleprotmon;
		npc.f_Temper_DamageTaken = 0.0;
		npc.i_Temper_Amount = 1;
		npc.Anger = false;
		npc.b_Temper_On = false;
		npc.b_Enraged = false;
		npc.i_Hit = 0;
		npc.f_AS_CD = GetRandomFloat(10.0, 30.0);//first he won't instantly summon them

		npc.StartPathing();
		if(!clone)
		npc.PlayIntro();
		
		return npc;
	}
}

static void Eleprotmon_ClotThink(int iNPC)
{
	Eleprotmon npc = view_as<Eleprotmon>(iNPC);

	float gameTime = GetGameTime(npc.index);
	
	if(npc.m_flNextDelayTime > gameTime)
	{
		return;
	}
	
	npc.m_flNextDelayTime = gameTime + DEFAULT_UPDATE_DELAY_FLOAT;
	
	npc.Update();
	
	if(npc.m_blPlayHurtAnimation)
	{
		npc.m_blPlayHurtAnimation = false;
		if(!npc.m_flAttackHappenswillhappen)
			npc.AddGesture("ACT_MP_GESTURE_FLINCH_CHEST", false);
		npc.PlayHurtSound();
	}

	if(!npc.Anger)
	{
		npc.Anger = true;
	}
	
	if(npc.m_flNextThinkTime > gameTime)
	{
		return;
	}
	
	npc.m_flNextThinkTime = gameTime + 0.1;

	if(npc.f_AS_CD <= gameTime)
	{
		if(GetRandomInt(0, 55) == 55)
		{
			PrintToChatAll("Spawned");
			npc.f_AS_CD = gameTime + 20.0;
			float healthamt = GetRandomFloat(3.0, 7.0);
			int summon = GetRandomInt(0, sizeof(g_AllySummons) - 1);
			int amount = GetRandomInt(1, 14);
			char name[255];
			FormatEx(name, sizeof(name), "%s", g_AllySummons[summon]);
			Temperals_Spawner(npc, RoundToCeil(healthamt * MultiGlobalEnemy), amount, "clone", name, 1.0, 1.0);
		}
	}

	if(LastMann)
	{
		if(!npc.m_fbGunout)
		{
			npc.m_fbGunout = true;
			Eleprotmon_Lastman_Messages(npc);
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
		
		//Target close enough to hit
		Eleprotmon_SelfDefense(npc, gameTime, npc.m_iTarget, flDistanceToTarget);
	}
	else
	{
		npc.StopPathing();
		npc.m_bPathing = false;
		npc.m_flGetClosestTargetTime = 0.0;
		npc.m_iTarget = GetClosestTarget(npc.index);
	}
	//npc.PlayIdleSound();
}

static void Eleprotmon_SelfDefense(Eleprotmon npc, float gameTime, int target, float flDistanceToTarget)
{
	if(npc.m_flAttackHappens)
	{
		if (npc.m_flAttackHappens < gameTime)
		{
			npc.m_flAttackHappens = 0.0;
			Handle swingTrace;
			float vecTarget[3]; WorldSpaceCenter(target, vecTarget);

			npc.FaceTowards(vecTarget, 20000.0);
			if(npc.DoSwingTrace(swingTrace, target))
			{
				target = TR_GetEntityIndex(swingTrace);	
				float vecHit[3];
				TR_GetEndPosition(vecHit, swingTrace);
				if(IsValidEnemy(npc.index, target))
				{
					float damage = 13.0;
					damage *= RaidModeScaling;

					if(target > 0) 
					{
						// Hit sound
						npc.PlayMeleeHitSound();
						npc.i_Hit++;
						if(npc.i_Hit >= 4)
						{
							float exp_damage = 8.0, radius = 160.0;
							exp_damage *= RaidModeScaling;
							damage *= 1.3;
							
							float vicloc[3];
							Custom_Knockback(npc.index, target, 1500.0);
							WorldSpaceCenter(target, vicloc);
							ParticleEffectAt(vicloc, "drg_cow_explosioncore_charged_blue", 0.5);
							Explode_Logic_Custom(exp_damage, npc.index, npc.index, -1, _, radius, _, _, true);
							npc.i_Hit = 0;
						}
						SDKHooks_TakeDamage(target, npc.index, npc.index, damage, DMG_CLUB | DMG_BURN, -1, _, vecHit);
					}
					else
					{
						npc.PlayMeleeMissSound();
					}
				}
			}
			delete swingTrace;
		}
	}
	if(npc.m_flNextRangedSpecialAttack)
	{
		if(npc.m_flNextRangedSpecialAttack < gameTime)
		{
			npc.m_flNextRangedSpecialAttack = 0.0;
			//Eleprotmon_Hellfire_Attack(npc);
		}
		return;
	}
	
	if(gameTime > npc.m_flNextMeleeAttack)
	{
		if(flDistanceToTarget < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 1.25))
		{
			int Enemy_I_See;
			Enemy_I_See = Can_I_See_Enemy(npc.index, target);

			if(IsValidEnemy(npc.index, Enemy_I_See))
			{
				npc.m_iTarget = Enemy_I_See;

				npc.PlayMeleeSound();
				bool rng = view_as<bool>(GetRandomInt(0, 1));
				npc.AddGesture(rng ? "ACT_MP_ATTACK_STAND_MELEE_ALLCLASS" : "ACT_MP_ATTACK_STAND_MELEE");
				npc.m_flAttackHappens = gameTime + 0.3;
				float attack = GetRandomFloat(0.6, 1.2);
				npc.m_flNextMeleeAttack = gameTime + attack;
			}
		}
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

static Action Eleprotmon_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	//Valid attackers only.
	if(attacker < 1)
		return Plugin_Continue;

	Eleprotmon npc = view_as<Eleprotmon>(victim);
	
	if(Temperals_Stabbed(attacker, victim, weapon, damagetype))
	{
		i_Stabbed[npc.index]++;
		if(i_Stabbed[npc.index] >= 6)
		{
			Eleprotmon_Backstab_Messages(attacker);
			float dmg = 13.0, radius = 160.0;
			dmg *= RaidModeScaling;
			Explode_Logic_Custom(dmg, npc.index, npc.index, -1, _, radius, _, _, true);
			i_Stabbed[npc.index] = 0;
		}
	}

	return Plugin_Continue;
}

static void Eleprotmon_NPCDeath(int entity)
{
	Eleprotmon npc = view_as<Eleprotmon>(entity);

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

	if(IsValidEntity(npc.m_iWearable6))
		RemoveEntity(npc.m_iWearable6);

	npc.PlayDeathSound();
	if(ZR_GetWaveCount()+1 > 45)
	{
		//Eleprotmon_Death_Messages(GetRandomInt(0, 1));
	}
	else
	{
		//Eleprotmon_Death_Messages(GetRandomInt(2, 3));
	}

	if(npc.index == EntRefToEntIndex(RaidBossActive))
	{
		RaidBossActive = INVALID_ENT_REFERENCE;
	}

	Citizen_MiniBossDeath(entity);
}

static void Eleprotmon_Reply(const char[] text)
{
	CPrintToChatAll("{crimson}Eleprotmonotix{default}:{yellow} %s", text);
}

static void Eleprotmon_Lastman_Messages(Eleprotmon npc)
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

	Eleprotmon_Reply(text);
}
static void Eleprotmon_Backstab_Messages(int stabber)
{
	char text[255];
	switch(GetRandomInt(0, 3))
	{
		case 0:
		{
			FormatEx(text, sizeof(text), "You're a sneaky little curse aren't you %N", stabber);
		}
		case 1:
		{
			FormatEx(text, sizeof(text), "{crimson}You THINK i'm playing with you, you BETTER THINK AGAIN");
		}
		case 2:
		{
			FormatEx(text, sizeof(text), "You may think you got the upper hand but, i got a few {red}tricks{yellow} on me");
		}
		case 3:
		{
			FormatEx(text, sizeof(text), "That's what you get %N", stabber);
		}
	}
	Eleprotmon_Reply(text);
}
static void Eleprotmon_Final_Messages(int line)
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
	Eleprotmon_Reply(text);
}
