#pragma semicolon 1
#pragma newdecls required

//TODO: WIP Zerofuse Abilities
// Ability EMBRACE DECEPTION, debuffs enemies and slowly damages them overtime
// Ability Instant severance, whoever got hit by it, gets their "soul" reduced for a bit as in they take more dmg
// Embrace Deception Effect: utaunt_poweraura_teamcolor_red
//Enjoyment of Agony : If enough damage is dealt while Zerofuse does XYZ taunt, he will receive a huge temporary buff.
//You have a Grace Period of 2 seconds before the ability actually activates (makes it alot easier to counter)
//A TE beam will be shown how much it will last aswell.

//Manifestation of Unknown Power : "Absorbs" all kind of damage he received in the past 5 seconds
//and receives a shield that absorbs Half of the damage that people cause
//Pinnacle of Physicality : Jumps around (like teleporting) and throws Slashes towards the closest enemy,
//each slice deals increased damage if it hits the same person

#define ZERO_LOWTETIME 0.05019608415	//very specific i know

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
static char g_ExplosionSound[][] = {
	"weapons/mortar/mortar_explode1.wav",
};

static char g_Zerofuse_SoundUsage[][] = {
	"ui/quest_status_tick_bonus_complete_halloween.wav",
	"ui/quest_status_tick_complete_halloween.wav",
};
static char g_Stabbed[][] = {
	"ui/quest_status_tick_bonus_complete_halloween.wav",
	"ui/quest_status_tick_complete_halloween.wav",
};

static float fl_DefaultSpeed = 300.0;
static int i_Form_Level = 0;//I don't need this to be an Array. Just a normal one is fine.
static int i_PowerStage[MAXENTITIES][2];//I could've used the i_times and i_attacks, but that will limit my Int usages more

public void Zerofuse_Raid_OnMapStart_NPC()
{
	i_Form_Level = 0;
	Zero2(i_PowerStage);

	PrecacheModel("models/player/spy.mdl");
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Zerofuse");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_raid_zerofuse");
	strcopy(data.Icon, sizeof(data.Icon), "norm_headcrab_zombie");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Hidden;
	data.Func = ClotSummon;
	data.Precache = ClotPrecache;
	NPC_Add(data);
}
static void ClotPrecache()
{
	PrecacheSoundCustom("#zombie_riot/temperals/zerofuse/lifeloss.mp3");
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_IntroSound);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	PrecacheSoundArray(g_MeleeMissSounds);
	PrecacheSoundArray(g_ExplosionSound);
	PrecacheSoundArray(g_Zerofuse_SoundUsage);
	PrecacheCustomSoundArray(g_Stabbed);
	//PrecacheSoundCustom("");
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int ally, const char[] data)
{
	return Zerofuse_Raid(vecPos, vecAng, ally, data);
}

methodmap Zerofuse_Raid < CClotBody
{
	property float f_PowerSpike_Time
	{
		public get()							{ return fl_RangedSpecialDelay[this.index]; }
		public set(float TempValueForProperty) 	{ fl_RangedSpecialDelay[this.index] = TempValueForProperty; }
	}
	property float f_Umbragous_Time
	{
		public get()							{ return fl_AngerDelay[this.index]; }
		public set(float TempValueForProperty) 	{ fl_AngerDelay[this.index] = TempValueForProperty; }
	}
	property float f_Deception_Time
	{
		public get()							{ return fl_AbilityOrAttack[this.index][1]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][1] = TempValueForProperty; }
	}
	property float f_Damage_Intotal
	{
		public get()							{ return fl_NextChargeSpecialAttack[this.index]; }
		public set(float TempValueForProperty) 	{ fl_NextChargeSpecialAttack[this.index] = TempValueForProperty; }
	}
	property float f_Speed_Intotal
	{
		public get()							{ return fl_Charge_Duration[this.index]; }
		public set(float TempValueForProperty) 	{ fl_Charge_Duration[this.index] = TempValueForProperty; }
	}
	property float fl_CorruptiveArea_Timer
	{
		public get()							{ return fl_AttackHappensMaximum[this.index]; }
		public set(float TempValueForProperty) 	{ fl_AttackHappensMaximum[this.index] = TempValueForProperty; }
	}
	property bool b_ReturnWalk
	{
		public get()							{ return b_XenoInfectedSpecialHurt[this.index]; }
		public set(bool TempValueForProperty) 	{ b_XenoInfectedSpecialHurt[this.index] = TempValueForProperty; }
	}
	property bool b_Lifelossed
	{
		public get()							{ return b_AttackHappenswillhappen[this.index]; }
		public set(bool TempValueForProperty) 	{ b_AttackHappenswillhappen[this.index] = TempValueForProperty; }
	}
	property int i_Hit
	{
		public get()							{ return i_TimesSummoned[this.index]; }
		public set(int TempValueForProperty) 	{ i_TimesSummoned[this.index] = TempValueForProperty; }
	}
	property int i_Stabbed
	{
		public get()							{ return i_AttacksTillMegahit[this.index][this.index]; }
		public set(int TempValueForProperty) 	{ i_AttacksTillMegahit[this.index][this.index] = TempValueForProperty; }
	}
	public void PlayIdleSound() {
		if(this.m_flNextIdleSound > GetGameTime(this.index))
			return;
		EmitSoundToAll(g_IdleSounds[GetRandomInt(0, sizeof(g_IdleSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 90);
		this.m_flNextIdleSound = GetGameTime(this.index) + GetRandomFloat(3.0, 6.0);
	}
	public void PlayIntro() {
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
	public void Play_ZeroExplosion() {
		EmitSoundToAll(g_ExplosionSound[GetRandomInt(0, sizeof(g_ExplosionSound) - 1)], _, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 100);
	}
	public void Play_ZeroAbility_Sounds(int usage = 0) {
		EmitSoundToAll(g_Zerofuse_SoundUsage[usage], _, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 90);
	}
	public void ArmorSet(float resistance = -1.0, bool uber = false)
	{
		if(resistance >= 0.0)
		{
			this.m_flMeleeArmor = resistance;
			this.m_flRangedArmor = resistance;
		}
		b_NpcIsInvulnerable[this.index] = uber;
	}
	public void EmitHudNotification(char text[255], bool zrhud = true, float time = 3.01)
	{//THIS ONLY HAPPENS ONCE PER USAGE PLEASE DONT MURDER
		for(int client = 1; client <= MaxClients; client++)
		{
			if(!IsClientInGame(client))
			{
				continue;
			}
			float hudy = 0.33;
			if(DoesNpcHaveHudDebuffOrBuff(client, this.index, GetGameTime()))//this used to be not like this..
				hudy = 0.363;
			SetHudTextParams(-1.0, hudy, 3.01, 0, 255, 20, 255);
			if(zrhud)//Incase you wanna use this
			{
				SetGlobalTransTarget(client);
				ShowSyncHudText(client, SyncHud_Notifaction, "%s", text);
			}
			else
			{
				ShowHudText(client, -1, text);
			}
		}
	}
	
	public Zerofuse_Raid(float vecPos[3], float vecAng[3], int ally, const char[] data)
	{
		Zerofuse_Raid npc = view_as<Zerofuse_Raid>(CClotBody(vecPos, vecAng, "models/player/spy.mdl", "1.35", "30000", ally, false));
		
		i_NpcWeight[npc.index] = 5;
		
		FormatEx(c_HeadPlaceAttachmentGibName[npc.index], sizeof(c_HeadPlaceAttachmentGibName[]), "head");

		int iActivity = npc.LookupActivity("ACT_MP_RUN_MELEE");
		if(iActivity > 0) npc.StartActivity(iActivity);
		npc.m_fbGunout = false;
		bool clone = StrContains(data, "clone") != -1;
		npc.m_bFUCKYOU = clone ? true : false;

		npc.m_flNextMeleeAttack = 0.0;
		npc.f_PowerSpike_Time = 0.0;
		npc.f_Umbragous_Time = 0.0;
		npc.f_Deception_Time = 0.0;
		npc.m_flDoingAnimation = 0.0;
		npc.f_Damage_Intotal = 0.0;
		npc.f_Speed_Intotal = 0.0;
		npc.fl_CorruptiveArea_Timer = 0.0;
		npc.i_Hit = 0;
		npc.b_ReturnWalk = false;
		npc.b_Lifelossed = false;
		i_PowerStage[npc.index][0] = 0;
		i_PowerStage[npc.index][1] = 0;
		i_Form_Level = 0;

		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_GIANT;	
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		npc.m_bDissapearOnDeath = true;
		npc.i_Stabbed = 0;
		if(GetTeam(npc.index) != TFTeam_Red)
		{
			b_NameNoTranslation[npc.index] = true;
			if(!clone)
			{
				RaidBossStatus Raid;
				Raid.israid = true; //If raid true, If superboss false
				Raid.allow_builings = true;
				Raid.Reduction_45 = 0.15;
				Raid.Reduction_60 = 0.3;
				Raid.Reduction_Last = 0.4;
				Raid.RaidTime = Waves_InFreeplay() ? 99999.0 : 300.0;
				
				//If you want to check if there is already a raid, and want to add args for that !Raid.Setup(true, npc);
				//viceversa
				if(Raid.Setup(true, npc, data))//We are the raid!, if not use else or Check()
				{
					//add additional things
					npc.m_iWearable1 = TF2_CreateGlow_White(npc.index, "models/player/spy.mdl", npc.index, 1.35);
					if(IsValidEntity(npc.m_iWearable1))
					{
						SetEntProp(npc.m_iWearable1, Prop_Send, "m_bGlowEnabled", false);
						SetEntityRenderMode(npc.m_iWearable1, RENDER_ENVIRONMENTAL);
						//Cannot be used on the actual npc. Reason is, for whatever reason fire removes it.
						Start_TE_Body_Effect(npc.m_iWearable1, "utaunt_storm_parent_o");
						npc.Anger = true;
					}
					else
					{
						//Even tho i don't wanna force it on him, no choice if it fails to spawn.
						//even then fire exists and removes this entirely.. HELP
						Start_TE_Body_Effect(npc.index, "utaunt_storm_parent_o");
					}
					Zerofuse_ChangeFormNames(npc);
					npc.m_iHealthBar = 2;
					b_NpcUnableToDie[npc.index] = true;
					npc.ArmorSet(1.1);
					//Raid.PlayMusic("#zombiesurvival/temperals/raids/phlog_bgm.mp3", "Quake II - Rage (Cover)", "DoomDood", 151);
				}
				else
				{
					//uh, who is the funny person who did multiple spawns..?
				}
				//Normal npcs, if there is a raid going on and they managed to get spawned
				//if(Raid.Check())//if there is a raid going lets this arg instead
				//{
				//	the stuff
				//}
			}
			else
			{
				//idk if this even works via translations, if not oh well..(forshadowed it, doesn't work) i'll just add Support for this later on.
				FormatEx(c_NpcName[npc.index], sizeof(c_NpcName[]), "%s %s", "Zerofuse", "[Clone]");
			}
		}
		
		int skin = 1;

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 23);

		//SetVariantInt(1);
		//AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.m_iWearable2 = npc.EquipItem("head", "models/player/items/spy/spy_hat.mdl", "", skin);
		npc.m_iWearable3 = npc.EquipItem("head", "models/player/items/spy/spy_party_phantom.mdl", "", skin);
		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/all_class/jogon/jogon_spy.mdl", "", 23);
		npc.m_iWearable5 = npc.EquipItem("head", "models/player/items/spy/spy_zombie.mdl", "", 24);
		npc.m_iWearable6 = npc.EquipItem("head", "models/workshop/player/items/all_class/xmas2013_jacket_s2/xmas2013_jacket_s2_spy.mdl", "", skin);
		float Loc[3];
		GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", Loc);
		
		//IDLE
		float gameTime = GetGameTime(npc.index);
		func_NPCDeath[npc.index] = Zerofuse_Raid_NPCDeath;
		func_NPCThink[npc.index] = Zerofuse_Raid_ClotThink;
		func_NPCOnTakeDamage[npc.index] = Zerofuse_Raid_OnTakeDamage;

		npc.m_flSpeed = fl_DefaultSpeed;
		
		npc.m_flAbilityOrAttack0 = gameTime + 12.0;//FORM
		npc.m_flAbilityOrAttack8 = 0.0;//Dash Leech
		npc.m_flAbilityOrAttack9 = 0.0;//Transform effect?

		npc.m_flJumpCooldown = gameTime + 10.0;
		npc.m_flNextRangedAttackHappening = 0.0;

		RequestFrame(RF_Damage_Speed_Adjustment, npc);

		npc.StartPathing();
		if(!clone)
		npc.PlayIntro();
		
		return npc;
	}
}

//Plot twist, he is actually just a puppet. the actual zero is nowhere nearby and is just controlling him from far away but still feels the pain etc.
static void Zerofuse_ChangeFormNames(Zerofuse_Raid npc)
{
	switch(i_Form_Level)
	{
		case -1, 0, 1, 2:
		{
			FormatEx(c_NpcName[npc.index], sizeof(c_NpcName[]), "%s %s", "Zerofuse", "[Base Form]");
		}
		case 3:
		{
			FormatEx(c_NpcName[npc.index], sizeof(c_NpcName[]), "%s %s", "Zerofuse", "[First Form]");
		}
		case 4, 5:
		{
			FormatEx(c_NpcName[npc.index], sizeof(c_NpcName[]), "%s %s", "Zerofuse", "[Second Form]");
		}
		default:
		{
			FormatEx(c_NpcName[npc.index], sizeof(c_NpcName[]), "%s %s", "Zerofuse", "[Final Form]");
		}
	}
}

static void Zerofuse_Raid_ClotThink(int iNPC)
{
	Zerofuse_Raid npc = view_as<Zerofuse_Raid>(iNPC);
	//Only once, so i can get the normal extra_speed/damage, didn't work when it's in the actual npc spawn setting

	bool clone = npc.m_bFUCKYOU;
	if(!clone)
	{
		if(GetTeam(npc.index) != TFTeam_Red)//Don't allow the ally version to fuck over the round
		{
			if(RaidModeTime < GetGameTime())
			{
				ForcePlayerLoss();
				RaidBossActive = INVALID_ENT_REFERENCE;
				func_NPCThink[npc.index] = INVALID_FUNCTION;
				return;
			}
			Zerofuse_ChangeFormNames(npc);
		}
	}
	
	float gameTime = GetGameTime(npc.index);
	if(npc.m_flAbilityOrAttack8 > gameTime)
	{
		if(npc.m_flNextRangedAttackHappening <= gameTime)
		{
			float Loc[3];
			GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", Loc);
			npc.m_flNextRangedAttackHappening = gameTime + 0.1;
			spawnRing_Vectors(Loc, 150.0 * 2.0, 0.0, 0.0, 5.0, "materials/sprites/laserbeam.vmt", 40, 160, 255, 200, 1, /*duration*/ ZERO_LOWTETIME, 5.0, 0.0, 1);
			Explode_Logic_Custom(0.0, npc.index, npc.index, -1, Loc, 150.0, _, _, _, _, false, _, Zerofuse_Leeching_CustomExplosion);
		}
	}
	bool transform = false;
	if(npc.m_flAbilityOrAttack9)//Transform effect
	{
		if(npc.m_flAbilityOrAttack9 <= gameTime)
		{
			npc.m_flAbilityOrAttack9 = 0.0;
			float Loc[3];
			GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", Loc);
			ParticleEffectAt(Loc, "hammer_bell_ring_shockwave", 1.25);
			//I did both, but apparently it just deletes any??
			//whatever, probably why fire deleted it off him even.
			Zerofuse_RemoveBodyParticle(npc, "utaunt_astralbodies_teamcolor_blue");
			Zerofuse_RemoveBodyParticle(npc, "utaunt_astralbodies_teamcolor_red");
			Zerofuse_AddBodyParticle(npc);
			transform = true;
		}
	}

	float TotalArmor = 1.0, TotalDamage = 1.0, TotalSpeed = 1.0;
	bool Stop = false;
	if(npc.m_flDoingAnimation < gameTime)
	{
		if(npc.b_ReturnWalk)
		{
			npc.m_flSpeed = fl_DefaultSpeed;
			if(!npc.m_bisWalking)
			{
				int iActivity = npc.LookupActivity("ACT_MP_RUN_MELEE");
				if(iActivity > 0) npc.StartActivity(iActivity);
				npc.m_bisWalking = true;
				if(transform)
				{
					if(GetRandomInt(0, 7) == GetRandomInt(0, 7))
					{
						npc.Play_ZeroExplosion();
						float Loc[3];
						GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", Loc);
						ParticleEffectAt(Loc, "hightower_explosion", 0.2);
						Explode_Logic_Custom(15.0 * RaidModeScaling, npc.index, npc.index, -1, Loc, 150.0, _, _, _, _, true);
					}
				}
			}
		}
		//i allowed multi form support cause yes :)
		if(npc.f_PowerSpike_Time > gameTime)
		{
			Zerofuse_PowerStage(npc, TotalArmor, TotalDamage, TotalSpeed, 1);
		}
		if(npc.f_Umbragous_Time > gameTime)
		{
			Zerofuse_PowerStage(npc, TotalArmor, TotalDamage, TotalSpeed, 0);
		}
	}
	else
	{
		TotalArmor *= 0.27;
		Stop = true;
	}

	//PrintCenterTextAll("Umbragous - %i | PowerSpike - %i", i_PowerStage[npc.index][0], i_PowerStage[npc.index][1]);
	
	fl_TotalArmor[npc.index] = TotalArmor;
	fl_Extra_Damage[npc.index] = (npc.f_Damage_Intotal * TotalDamage);
	fl_Extra_Speed[npc.index] = (npc.f_Speed_Intotal * TotalSpeed);
	
	//PrintCenterTextAll("Damage: %.2f | Speed: %.2f", fl_Extra_Damage[npc.index], fl_Extra_Speed[npc.index]);
	if(npc.b_Lifelossed)
	{
		if(npc.fl_CorruptiveArea_Timer)
		{
			if(npc.fl_CorruptiveArea_Timer >= gameTime)
			{
				if(npc.m_flNextRangedAttackHappening <= gameTime)
				{
					float Loc[3];
					GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", Loc);
					float radius = 400.0, damage = 3.0 * RaidModeScaling;
					bool overtime = ((npc.fl_CorruptiveArea_Timer - gameTime) >= 3.0);
					int color[3] = {180, 40, 70};
					spawnRing_Vectors(Loc, radius * 2.0, 0.0, 0.0, 5.0, "materials/sprites/laserbeam.vmt", color[0], color[1], color[2], 200, 1, /*duration*/ ZERO_LOWTETIME, 5.0, 0.0, 1);
					if(!overtime)
					{
						Explode_Logic_Custom(damage, npc.index, npc.index, -1, Loc, radius, _, _, _, _, true, _);
					}
					npc.m_flNextRangedAttackHappening = gameTime + 0.1;
				}
				npc.m_flSpeed = fl_DefaultSpeed * 0.35;
				//Stop = true;
			}
			else
			{
				npc.fl_CorruptiveArea_Timer = 0.0;
				npc.m_flSpeed = fl_DefaultSpeed;
			}
		}
	}

	if(npc.m_flNextDelayTime > gameTime || Stop)
	{
		return;
	}
	//I'm aware this is kinda pointless, just incase tho.
	if((npc.f_PowerSpike_Time <= gameTime || npc.f_Umbragous_Time <= gameTime))
	{
		if(npc.m_flAbilityOrAttack0)
		{
			if(npc.m_flAbilityOrAttack0 <= gameTime)
			{
				int rng = GetRandomInt(0, 1);
				float Duration = 12.0;
				Zerofuse_ShortTransforms(npc, Duration, rng);
				return;
			}
		}
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
	
	if(npc.m_flNextThinkTime > gameTime)
	{
		return;
	}
	
	npc.m_flNextThinkTime = gameTime + 0.1;

	if(LastMann)
	{
		if(!npc.m_fbGunout)
		{
			npc.m_fbGunout = true;
			Zero_Lastman_Messages(npc);
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
		
		if(npc.b_Lifelossed && npc.fl_CorruptiveArea_Timer <= gameTime)
		{
			if(flDistanceToTarget <= (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 1.2))
			{
				if(npc.m_flAbilityOrAttack7 <= gameTime && npc.m_flAbilityOrAttack0 > gameTime)
				{
					bool increase = false;
					npc.fl_CorruptiveArea_Timer = gameTime + 4.25;
					if(npc.m_flAbilityOrAttack0 > gameTime)
					{
						npc.m_flAbilityOrAttack0 += 4.25;
					}
					else
					{
						npc.m_flAbilityOrAttack0 = gameTime + 6.25;
						increase = true;
					}
					float time = increase ? 31.0 : 25.0;
					npc.m_flAbilityOrAttack7 = gameTime + time;
					Corruption_Sound(npc.index, "mvm/mvm_cpoint_klaxon.wav", 8, 0.1, 70, true, _, _, false);
					return;
				}
			}
		}

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
		if(i_Form_Level >= 6)
		{
			if(npc.m_flJumpCooldown < gameTime)
			{
				int Enemy_I_See = Can_I_See_Enemy(npc.index, closest);
				if(IsValidEnemy(npc.index, Enemy_I_See))
				{
					if(flDistanceToTarget >= (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 13.0))
					{
						npc.FaceTowards(vecTarget, 15000.0);
						npc.m_flJumpCooldown = gameTime + 10.0;
						npc.m_flAbilityOrAttack8 = gameTime + 2.0;
						float Predict = flDistanceToTarget * 1.4;
						PredictSubjectPositionForProjectiles(npc, npc.m_iTarget, Predict, _, vecTarget);
						PluginBot_Jump(npc.index, vecTarget);
						npc.FaceTowards(vecTarget, 15000.0);
						float Loc[3];
						GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", Loc);
						Zerofuse_ParticleLocation(npc, Loc, "utaunt_hellpit_parent", 2.0);
						return;//DONT USE OTHER STUFF AFTER THIS!!
					}
				}
			}
		}
		
		//Target close enough to hit
		Zero_SelfDefense(npc, gameTime, npc.m_iTarget, flDistanceToTarget);
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

static void Zerofuse_Leeching_CustomExplosion(int entity, int victim, float damage, int weapon)
{
	float flMaxhealth = float(ReturnEntityMaxHealth(entity));
	flMaxhealth *= 0.0025;//i honestly should've done a ratio rather then this, oh well.
	HealEntityGlobal(entity, entity, flMaxhealth, 1.0, 0.0, HEAL_SELFHEAL);
	PrintToChatAll("Healing: %.1f", flMaxhealth);
}

static void Zero_SelfDefense(Zerofuse_Raid npc, float gameTime, int target, float flDistanceToTarget)
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
	//if(npc.m_flNextRangedSpecialAttack)
	//{
	//	if(npc.m_flNextRangedSpecialAttack < gameTime)
	//	{
	//		npc.m_flNextRangedSpecialAttack = 0.0;
	//	}
	//	return;
	//}
	
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

static void Zerofuse_ShortTransforms(Zerofuse_Raid npc, float Duration, int type)
{
	float gameTime = GetGameTime(npc.index);
	npc.m_flDoingAnimation = gameTime + 2.0;
	
	npc.m_flSpeed = 0.0;
	npc.m_bisWalking = false;
	float Loc[3];
	GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", Loc);
	//spawnRing_Vectors(Loc, 350.0 * 2.0, 0.0, 0.0, 5.0, "materials/sprites/laserbeam.vmt", 40, 160, 255, 200, 1, /*duration*/ 2.0, 5.0, 0.0, 1);
	//spawnRing_Vectors(Loc, 350.0 * 2.0, 0.0, 0.0, 0.0, "materials/sprites/laserbeam.vmt", 220, 40, 160, 200, 1, /*duration*/ 1.9, 5.0, 1.0, 1, 150.0);
	i_Form_Level++;
	float timebong = 1.85;
	i_PowerStage[npc.index][type]++;
	char particle[255];
	Zerofuse_RemoveBodyParticle(npc);
	switch(type)
	{
		case 0:
		{
			npc.EmitHudNotification("Fortitude Consumption..");
			npc.AddActivityViaSequence("taunt_neck_snap_spy");
			timebong = 1.6;
			npc.f_Umbragous_Time = gameTime + Duration;
			particle = "utaunt_tarotcard_teamcolor_blue";
			Zerofuse_AddBodyParticle(npc, "utaunt_astralbodies_teamcolor_blue");
		}
		case 1:
		{
			npc.EmitHudNotification("Wrathful Strike..");
			npc.AddActivityViaSequence("taunt_unleashed_rage_spy");
			npc.f_PowerSpike_Time = gameTime + Duration;
			particle = "utaunt_tarotcard_teamcolor_red";
			Zerofuse_AddBodyParticle(npc, "utaunt_astralbodies_teamcolor_red");
		}
	}
	npc.m_flAbilityOrAttack9 = gameTime + timebong;
	
	npc.Play_ZeroAbility_Sounds(type);
	npc.SetCycle(0.75);
	npc.SetPlaybackRate(0.2);
	npc.b_ReturnWalk = true;
	Zerofuse_ParticleLocation(npc, Loc, particle, 2.0);
	npc.m_flAbilityOrAttack0 = gameTime + (Duration * 1.45);
}


static Action Zerofuse_Raid_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	//Valid attackers only.
	if(attacker < 1)
		return Plugin_Continue;

	Zerofuse_Raid npc = view_as<Zerofuse_Raid>(victim);
	
	if(Temperals_Stabbed(attacker, victim, weapon, damagetype))
	{
		npc.i_Stabbed++;
		if(npc.i_Stabbed >= 3)
		{
			Zero_Backstab_Messages(attacker);
			/*float dmg = 13.0, radius = 160.0;
			dmg *= RaidModeScaling;
			Explode_Logic_Custom(dmg, npc.index, npc.index, -1, _, radius, _, _, true);*/
			npc.i_Stabbed = 0;
		}
	}
	if(!npc.m_bFUCKYOU)//CLONES
	{
		if(Temperlas_MultiLifeCheck(npc, damage, false))
		{
			npc.m_iHealthBar--;//double removal cause i want it to be accurate as in ff2.
			if(npc.m_iHealthBar <= 1)//I don't like how it still shows x1, cause that isn't how lives are suppose to work.
			{
				npc.b_Lifelossed = true;
				float gameTime = GetGameTime(npc.index);
				float dur = 14.0;//IK IT MEANS STOP SHUUUU
				if(npc.f_PowerSpike_Time >= gameTime)
				{
					npc.f_PowerSpike_Time += dur;
				}
				Zerofuse_ShortTransforms(npc, dur, 0);
				//OnTakeDamage is manipulating the health, delay a bit.
				RequestFrames(Zerofuse_MaxHealthBack, 8, npc.index);
				npc.m_iHealthBar = 0;
				RaidBossStatus Raid;//Damn are custom sounds that quiet if it custom = true on..
				Raid.PlayMusic("#zombie_riot/temperals/zerofuse/lifeloss.mp3", "li_boss_elysion003 - Solace's Fortress Boss 2", "Elsword", 118, 2.0, true, true);
			}
		}
	}

	return Plugin_Continue;
}

//FF2R Now respects lives properly and doesn't erase hp anymore.
static void Zerofuse_MaxHealthBack(int entity)
{
	if(!IsValidEntity(entity))
	{
		return;
	}
	b_NpcUnableToDie[entity] = false;
	SetEntProp(entity, Prop_Data, "m_iHealth", ReturnEntityMaxHealth(entity));
}

static void Zerofuse_RemoveBodyParticle(Zerofuse_Raid npc, char particle[255] = "utaunt_storm_parent_o")
{
	bool whohadit = npc.Anger;

	if(whohadit)
	{
		if(IsValidEntity(npc.m_iWearable1))
		{
			Remove_TE_Body_Effect(npc.m_iWearable1, particle);
		}
	}
	else
	{
		Remove_TE_Body_Effect(npc.index, particle);
	}
}
static void Zerofuse_AddBodyParticle(Zerofuse_Raid npc, char particle[255] = "utaunt_storm_parent_o")
{
	bool whohadit = npc.Anger;

	if(whohadit)
	{
		if(IsValidEntity(npc.m_iWearable1))//If it is gone, DO NOT BOTHER!!!!!!!
		{
			Start_TE_Body_Effect(npc.m_iWearable1, particle);
		}
	}
	else
	{
		Start_TE_Body_Effect(npc.index, particle);
	}
}

static void Zerofuse_Raid_NPCDeath(int entity)
{
	Zerofuse_Raid npc = view_as<Zerofuse_Raid>(entity);

	bool whohadit = npc.Anger;

	if(IsValidEntity(npc.m_iWearable1))
	{
		if(whohadit)
			Remove_TE_Body_Effect(npc.m_iWearable1, "utaunt_storm_parent_o");
		
		RemoveEntity(npc.m_iWearable1);
	}

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
		
	if(IsValidEntity(npc.m_iWearable7))
		RemoveEntity(npc.m_iWearable7);

	npc.PlayDeathSound();
	if(Waves_GetRound()+1 > 45)
	{
		Zero_Death_Messages(GetRandomInt(0, 1));
	}
	else
	{
		Zero_Death_Messages(GetRandomInt(2, 3));
	}

	if(npc.index == EntRefToEntIndex(RaidBossActive))
	{
		RaidBossActive = INVALID_ENT_REFERENCE;
	}

	if(!whohadit)
		Remove_TE_Body_Effect(entity, "utaunt_storm_parent_o");
	
	Citizen_MiniBossDeath(entity);
}

//There was non that deleted itself after specific time!!
static int Zerofuse_ParticleLocation(Zerofuse_Raid npc, float Loc[3], char particle_effect[255], float duration = 2.0)
{
	int particle = ParticleEffectAt_Parent(Loc, particle_effect, npc.index, "root");
	if(IsValidEntity(particle))
	{
		if(duration > 0.0)
		{
			CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
		}

		return particle;
	}
	return -1;
}

static void Zerofuse_PowerStage(Zerofuse_Raid npc, float &TotalArmor = 1.0, float &TotalDamage = 1.0, float &TotalSpeed = 1.0, int type = 0)
{
	int stage = i_PowerStage[npc.index][type];
	switch(type)
	{
		case 0:
		{
			switch(stage)
			{
				case -1, 0, 1:
				{
					TotalArmor *= 0.835;
					TotalDamage = 0.75;
					TotalSpeed = 0.85;
				}
				case 2:
				{
					TotalArmor *= 0.75;
					TotalDamage = 0.85;
					TotalSpeed = 0.9;
				}
				case 3:
				{
					TotalArmor *= 0.715;
					TotalDamage = 0.9;
					TotalSpeed = 0.95;
				}
				default:
				{
					TotalArmor *= 0.6345;
					TotalDamage = 0.95;
					TotalSpeed = 1.0;
				}
			}
		}
		case 1:
		{
			switch(stage)
			{
				case -1, 0, 1:
				{
					TotalArmor *= 1.1175;
					TotalDamage = 1.15;
					TotalSpeed = 1.15;
				}
				case 2:
				{
					TotalArmor *= 1.1175;
					TotalDamage = 1.185;
					TotalSpeed = 1.185;
				}
				case 3, 4:
				{
					TotalArmor *= 1.125;
					TotalDamage = 1.195;
					TotalSpeed = 1.195;
				}
				default:
				{
					TotalArmor *= 1.37;
					TotalDamage = 1.275;
					TotalSpeed = 1.25;
				}
			}
		}
	}
}

//Get Bonuses from spawn.
static void RF_Damage_Speed_Adjustment(Zerofuse_Raid npc)
{
	npc.f_Damage_Intotal = fl_Extra_Damage[npc.index];
	npc.f_Speed_Intotal = fl_Extra_Speed[npc.index];
}

static void Zero_Reply(const char[] text, any ...)
{
	CPrintToChatAll("{crimson}Zerofuse{default}: %s", text);
}

static void Zero_Lastman_Messages(Zerofuse_Raid npc)
{
	char text[255];
	switch(GetRandomInt(0, 5))
	{
		case 0:
		{
			if(IsValidClient(npc.m_iTarget))
			{
				FormatEx(text, sizeof(text), "What part of {crimson}die{yellow} did you not understand {default}%N.", npc.m_iTarget);
			}
			else
			{
				FormatEx(text, sizeof(text), "Well well well. What do we have {crimson}here.");
			}
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

	Zero_Reply(text);
}
//VALID CLIENT, unless you somehow made stabber work on npcs then uhhh.
static void Zero_Backstab_Messages(int stabber)
{
	char text[255];
	switch(GetRandomInt(0, 3))
	{
		case 0:
		{
			FormatEx(text, sizeof(text), "{red}Your as good as {crimson}DEAD {yellow}%N", stabber);
		}
		case 1:
		{
			FormatEx(text, sizeof(text), "{crimson}NO WAY");
		}
		case 2:
		{
			FormatEx(text, sizeof(text), "{red}MHHHN{crimson}RGH");
		}
		case 3:
		{
			FormatEx(text, sizeof(text), "{red}WEAKLING {yellow}%N", stabber);
		}
	}
	Zero_Reply(text);
}
static void Zero_Death_Messages(int line)
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
	Zero_Reply(text);
}