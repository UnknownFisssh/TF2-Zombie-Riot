#pragma semicolon 1
#pragma newdecls required

//TODO: WIP Zerofuse Abilities

// Ability EMBRACE DECEPTION, debuffs enemies and slowly damages them overtime
// Ability Instant severance, whoever got hit by it, gets their "soul" reduced for a bit as in they take more dmg
// Embrace Deception Effect: utaunt_poweraura_teamcolor_red
//Enjoyment of Agony : If enough damage is dealt while Zerofuse does XYZ taunt, he will receive a huge temporary buff.
//You have a Grace Period of 2 seconds before the ability actually activates (makes it alot easier to counter)

//Manifestation of Unknown Power : "Absorbs" all kind of damage he received in the past 5 seconds
//and receives a shield that absorbs Half of the damage that people cause
//Pinnacle of Physicality : Jumps around (like teleporting) and throws Slashes towards the closest enemy,
//each slice deals increased damage if it hits the same person

/*
	RaidBossStatus Raid;
	Raid.israid = true; //If raid true, If superboss false
	Raid.allow_builings = true;
	Raid.Reduction_45 = 0.15;
	Raid.Reduction_60 = 0.3;
	Raid.Reduction_Last = 0.4;
	Raid.RaidTime = 300.0;
	//If you want to check if there is already a raid, and want to add args for that !Raid.Setup(true, npc);
	//viceversa
	if(Raid.Setup(true, npc, data))//We are the raid!, if not use else or Check(). CAN BE IGNORED AND JUST DONE Raid.Setup(false, npc, data) INSTEAD
	{
		//add additional things
		
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
*/

enum struct RaidBossStatus
{
	bool israid;
	bool allow_builings;
	//float maxplayers;
	float RaidTime;
	//They are commented out, since we use the new method
	float Reduction_45;
	float Reduction_60;
	float Reduction_Last;
	bool ignore_scaling;
	
	bool Setup(bool check = false, CClotBody npc, const char[] data)
	{
		if(check && IsValidEntity(EntRefToEntIndex(RaidBossActive)))
		{
			return false;
		}

		RaidBossActive = EntIndexToEntRef(npc.index);
		RaidAllowsBuildings = this.allow_builings;

		b_thisNpcIsARaid[npc.index] = this.israid;
		npc.m_bThisNpcIsABoss = true;
		RaidModeTime = GetGameTime(npc.index) + this.RaidTime;
		if(this.ignore_scaling)
		{
			char buffers[3][64];
			ExplodeString(data, ";", buffers, sizeof(buffers), sizeof(buffers[]));
			//the very first and 2nd char are SC for scaling
			if(buffers[0][0] == 's' && buffers[0][1] == 'c')
			{
				//remove SC
				ReplaceString(buffers[0], 64, "sc", "");
				float value = StringToFloat(buffers[0]);
				RaidModeScaling = value;
			}
			else
			{
				RaidModeScaling = float(Waves_GetRoundScale()+1);
			}

			if(RaidModeScaling < 55)
			{
				RaidModeScaling *= 0.19; //abit low, inreacing
			}
			else
			{
				RaidModeScaling *= 0.38;
			}
			
			float amount_of_people = ZRStocks_PlayerScalingDynamic();
			if(amount_of_people > 12.0)
			{
				amount_of_people = 12.0;
			}

			amount_of_people *= 0.12;
			
			if(amount_of_people < 1.0)
			{
				amount_of_people = 1.0;
			}
			RaidModeScaling *= amount_of_people; //More then 9 and he raidboss gets some troubles, bufffffffff
		}
		
		/*if(!this.Reduction_45)//default
			this.Reduction_45 = 0.15;
		
		if(!this.Reduction_60)//default
			this.Reduction_60 = 0.3;

		if(Waves_GetRound()+1 > 40 && Waves_GetRound()+1 < 55)
			RaidModeScaling *= (1.0 - this.Reduction_45);//0.85;
		else if(Waves_GetRound()+1 > 55 && this.Reduction_60)
			RaidModeScaling *= (1.0 - this.Reduction_60);//0.7;
        
		//only do if it has nothing
		if(this.Reduction_Last)//some raids had this, kahml, purge, messenger
			RaidModeScaling *= (1.0 - this.Reduction_Last);//0.6;*/

		RemoveAllDamageAddition();
		Citizen_MiniBossSpawn();
		
		return true;
	}
	bool Check()//exists, cause idk, i forgot why i even added this.
	{
		if(IsValidEntity(EntRefToEntIndex(RaidBossActive)))
			return true;

		return false;
	}
	//was lazy
	void PlayMusic(char musicpath[255], char musicname[255],
	char musicartist[64], int time, float volume = 2.0, bool custom = true, bool instant = false)
	{
		if(!musicpath[0])
		{
			CPrintToChatAll("{lime}[ZR]{default} No music path found, {crimson}please insert {gold}5 coins.");
			return;
		}

		MusicEnum music;
		strcopy(music.Path, sizeof(music.Path), musicpath);
		music.Time = time;
		music.Volume = volume;
		music.Custom = custom;
		strcopy(music.Name, sizeof(music.Name), musicname);
		strcopy(music.Artist, sizeof(music.Artist), musicartist);
		Music_SetRaidMusic(music);
		if(instant)
		{
			for(int client = 1; client <= MaxClients; client++)
			{
				if(IsClientInGame(client) && !IsFakeClient(client))
				{
					SetMusicTimer(client, GetTime() /*+ 1*/);
				}
			}
		}
	}
}
/**
 * Backstab detection on npcs, rather then having it hardcoded fully. Facestabber will not work on this.
 * @param attacker    Client Attacker's ID (ONLY WORKS FOR CLIENTS NOT NPCS!)
 * @param victim      Npc That got stabbed.
 * @param weapon      Weapon Usage check.
 * @param damagetype  Damage type check.
 * @return  Returns true if all stuff is valid
 */
bool Temperals_Stabbed(int attacker, int victim, int weapon, int damagetype)
{
	if(IsValidClient(attacker))
	{
		//int viewmodel = GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
		if(IsValidEntity(weapon))
		{
			int melee = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			if(f_BackstabDmgMulti[weapon] != 0.0 && !b_CannotBeBackstabbed[victim]
			&& damagetype & DMG_CLUB && !(i_HexCustomDamageTypes[victim] & ZR_DAMAGE_DO_NOT_APPLY_BURN_OR_BLEED))
			{
				if(IsBehindAndFacingTarget(attacker, victim) && !b_FaceStabber[attacker])
				{
					if(melee != 4 && melee != 1003) //&& viewmodel>MaxClients && IsValidEntity(viewmodel))
					{
						return true;
					}
				}
			}
		}
	}

	return false;
}
/**
 * Semi Corrupted Sounds that just reloop themselves a bit.
 * @param entity      Entity Caller.
 * @param sound       Sound Path
 * @param amt         Sound Play Amount
 * @param intervolt   Delay Intervolt.
 * @param pitch       Pitch
 * @param global      Global to all clients.
 * @param volume      Volume meter (only goes up to 1.0 for now.)
 * @param soundlevel  Sound level.
 * @param reset       Kill the sound then replay new one, (default on true.)
 * 
 * @error             Invalid Sound Path or Entity Doesn't exist anymore.
 */
stock void Corruption_Sound(int entity, const char[] sound, int amt, float intervolt = 0.1, int pitch = 100, bool global = false, float volume = NORMAL_ZOMBIE_VOLUME, int soundlevel = NORMAL_ZOMBIE_SOUNDLEVEL, bool reset = true)
{
	//char text[255];
	//FormatEx(text, sizeof(text), "%s", text);
	if(!sound[0] || !IsValidEntity(entity))//Don't bother if no sound or the npc doesn't exist
		return;

	//char soundfile[255];
	//FormatEx(soundfile, sizeof(soundfile), "%s", sound);
	DataPack pack;
	CreateDataTimer(0.0, Timer_Sound_Repeat_Corruption, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(EntIndexToEntRef(entity));
	pack.WriteCell(amt);
	pack.WriteFloat(intervolt);
	pack.WriteString(sound);
	pack.WriteCell(pitch);
	pack.WriteCell(global);
	pack.WriteCell(soundlevel);
	pack.WriteCell(reset);
	pack.WriteFloat(volume);
}

static Action Timer_Sound_Repeat_Corruption(Handle timer, DataPack pack)
{
	pack.Reset();
	int ref = pack.ReadCell();
	int entity = EntRefToEntIndex(ref);
	int amt = pack.ReadCell();
	float intervolt = pack.ReadFloat();
	char sound[255];
	pack.ReadString(sound, sizeof(sound));
	int pitch = pack.ReadCell();
	bool global = view_as<bool>(pack.ReadCell());
	int soundlevel = pack.ReadCell();
	bool reset = view_as<bool>(pack.ReadCell());
	float volume = pack.ReadFloat();

	if(!IsValidEntity(entity))//don't bother if he doesn't exists anymore
	{
		return Plugin_Stop;
	}
	
	if(reset)
	{
		if(!global)
		{
			for(int i ; i < 2 ; i++)
			{
				StopSound(entity, SNDCHAN_STATIC, sound);
			}
		}
		else
		{
			for(int i = 1; i <= MaxClients ; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i))
				{
					StopSound(i, SNDCHAN_STATIC, sound);
				}
			}
		}
	}

	EmitSoundToAll(sound, global ? -2 : entity, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, volume, pitch);
	if(amt >= 1)
	{
		amt--;
		DataPack data;
		CreateDataTimer(intervolt, Timer_Sound_Repeat_Corruption, data);
		data.WriteCell(ref);
		data.WriteCell(amt);
		data.WriteFloat(intervolt);
		data.WriteString(sound);
		data.WriteCell(pitch);
		data.WriteCell(global);
		data.WriteCell(soundlevel);
		data.WriteCell(reset);
		data.WriteFloat(volume);
	}

	return Plugin_Stop;
}

/**
 * Temperals Waveset Clone/Minion Spawner. Now that i think about it. Why isn't this just a default spawner.
 * @param npc        NPC Host
 * @param hp         Amount of Health.
 * @param amount     How many npcs amount.
 * @param data       What data does this need.
 * @param name       New Npcs Plugin Name that you want to spawn.
 * @param dmgbonus   Damage Bonus management.
 * @param speedbon   Speed Bonus management.
 * @param meleeres   Melee Resistance management.
 * @param rangedres  Ranged Resistance management.
 * @param size       Size of the new npc.
 * @param outline    Outline toggle.
 * @param nukeimu    Nuke immunity Toggle.
 * 
 * @error            Invalid Npc Name.
 */
stock void Temperals_Spawner(CClotBody npc, int hp, int amount = 1, char data[64], char name[255], float dmgbonus = 0.85, float speedbon = 1.0, float meleeres = 1.0, float rangedres = 1.0, float size = 1.0, bool outline = true, bool nukeimu = true)
{
	if(!name[0])
	{
		return;
	}
	Enemy enemy;
	enemy.Index = NPC_GetByPlugin(name);
	int health = hp;
	if(health != 0)
		enemy.Health = health;
	
	enemy.Is_Outlined = outline;
	enemy.Is_Immune_To_Nuke = nukeimu;
	//do not bother outlining.
	enemy.ExtraMeleeRes = meleeres;
	enemy.ExtraRangedRes = rangedres;
	enemy.ExtraSpeed = speedbon;
	enemy.ExtraDamage = dmgbonus;
	enemy.ExtraSize = size;
	if(data[0])
		enemy.Data = data;
    
	enemy.Team = GetTeam(npc.index);
	for(int i; i<amount; i++)
	{
		Waves_AddNextEnemy(enemy);
	}
	Zombies_Currently_Still_Ongoing += amount;
}

/**
 * Time Slow Decrease, can be used to speed time aswell.
 * @param amount  Amount you want to lower/increase the speed of the game.
 * @param revert  When it's time to revert the change.
 */
stock void Temperlas_TimeSlow(float amount = 1.0, float revert = 0.1)
{
	if(amount < 0.35)
	{
		amount = 0.35;
	}

	//PrintToChatAll("amount %.4f | revert %.4f", amount, revert);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SendConVarValue(i, sv_cheats, "1");
		}
	}
	cvarTimeScale.SetFloat(amount);
	CreateTimer(revert, SetTimeBack);
}

//This exist so i can easily modify the health pronto. or do my own logic etc.
//I wish there was a preFunc for ontakedamage so i can overwrite the healthbar logic.
stock bool Temperlas_MultiLifeCheck(CClotBody npc, float damage, bool cantdie)
{
	if(cantdie)
	{
		if(npc.m_iHealthBar > 0 && b_NpcUnableToDie[npc.index])
		{
			if(damage >= GetEntProp(npc.index, Prop_Data, "m_iHealth"))
				return true;
		}
	}
	else
	{
		if(npc.m_iHealthBar > 0)
		{
			if(damage >= GetEntProp(npc.index, Prop_Data, "m_iHealth"))
			{
				return true;
			}
		}
	}
	
	return false;
}

stock void Temperals_SingleDamage_Melee(DataPack data)
{
	data.Reset();

	int entity = EntRefToEntIndex(data.ReadCell());

	if(!IsValidEntity(entity))
	{
		delete data;
		return;
	}

	CClotBody npc = view_as<CClotBody>(entity);

	float damage = data.ReadFloat();

	Function FuncOnHit = data.ReadFunction();

	float knockback = data.ReadFloat();

	Handle swingTrace;
	int target = npc.m_iTarget;
	float vecTarget[3]; WorldSpaceCenter(target, vecTarget);

	npc.FaceTowards(vecTarget, 20000.0);
	float minVec[3] = {-64.0, -64.0, -128.0}, maxVec[3] = {64.0, 64.0, 128.0};

	data.ReadFloatArray(minVec, sizeof(minVec));
	data.ReadFloatArray(maxVec, sizeof(maxVec));
	if(IsNullVector(minVec))
		minVec = {-64.0, -64.0, -128.0};
	if(IsNullVector(maxVec))
		maxVec = {64.0, 64.0, 128.0};

	if(npc.DoSwingTrace(swingTrace, target, maxVec, minVec))
	{
		target = TR_GetEntityIndex(swingTrace);	
		float vecHit[3];
		TR_GetEndPosition(vecHit, swingTrace);
		if(IsValidEnemy(npc.index, target))
		{
			if(target > 0) 
			{
				// Hit sound
				//npc.PlayMeleeHitSound();
				//static void OnHitSingle(int entity, int victim, float damage)
				if(FuncOnHit && FuncOnHit != INVALID_FUNCTION)
				{
					Call_StartFunction(null, FuncOnHit);
					Call_PushCell(entity);
					Call_PushCell(target);
					Call_PushFloat(damage);
					//Call_PushCell(PlaySound);
					Call_Finish();
				}
				SDKHooks_TakeDamage(target, npc.index, npc.index, damage, DMG_CLUB, -1, _, vecHit);
				if(IsValidClient(target))
				{
					//if(!silenced)
					if(knockback)
					{
						TF2_AddCondition(target, TFCond_LostFooting, 0.5);
						TF2_AddCondition(target, TFCond_AirCurrent, 0.5);
					}
				}
				if(knockback)
					Custom_Knockback(npc.index, target, knockback, true);
			}
			else
			{
				//npc.PlayMeleeMissSound();
			}
		}
	}
	delete swingTrace;
	delete data;
}

//I am aware TE_SetupEffectDispatch exists, i only need it to spawn properly without any modifications.
//it was either that or force manual prop(like how i did it on zerofuse)
//into the stock itself.
stock void Start_TE_Body_Effect(int entity, char particle[255], bool reapply = false)
{
	if(reapply)
	{
		Remove_TE_Body_Effect(entity, particle);
	}
	TE_SetupParticleEffect(particle, PATTACH_ABSORIGIN_FOLLOW, entity);
	TE_WriteNum("m_bControlPoint1", entity);	
	TE_SendToAll();
}
//whatever i do, it'll just remove any particle.
stock void Remove_TE_Body_Effect(int entity, char particle[255])
{
	TE_Start("EffectDispatch");
	TE_WriteNum("entindex", entity);
	TE_WriteNum("m_nHitBox", GetParticleEffectIndex(particle));
	TE_WriteNum("m_iEffectName", GetEffectIndex("ParticleEffectStop"));
	TE_SendToAll();
}

stock void PrecacheCustomSoundList(const char[][] array, int length)
{
	for(int i; i < length; i++)
	{
		PrecacheSoundCustom(array[i]);
	}
}

#define PrecacheCustomSoundArray(%1)		PrecacheSoundList(%1, sizeof(%1))