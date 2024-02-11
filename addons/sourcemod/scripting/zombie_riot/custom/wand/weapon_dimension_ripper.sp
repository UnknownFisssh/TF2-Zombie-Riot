#pragma semicolon 1
#pragma newdecls required

#define SOUND_WAND_SHOT_DIM	"misc/doomsday_lift_stop.wav"
#define SOUND_DIM_IMPACT "weapons/cow_mangler_explosion_normal_01.wav"
#define SOUND_ABILITY "misc/rd_points_return01.wav"
#define MAX_DIMENSION_CHARGE 20
static Handle h_TimerDimensionWeaponManagement[MAXPLAYERS+1]={null, ...};
static int how_many_times_swinged[MAXTF2PLAYERS];
static float f_DIMAbilityActive[MAXPLAYERS+1]={0.0, ...};
static float f_DIMhuddelay[MAXPLAYERS+1]={0.0, ...};
#define WEAPON_EXTRA_DAMAGE_MODIF 2.0


void ResetMapStartDimWeapon()
{
	Zero(f_DIMhuddelay);
	Wand_Dimension_Map_Precache();
}
void Wand_Dimension_Map_Precache()
{
	PrecacheSound(SOUND_WAND_SHOT_DIM);
	PrecacheSound(SOUND_DIM_IMPACT);
	PrecacheSound(SOUND_ABILITY);
}

public void Enable_Dimension_Wand(int client, int weapon) // Enable management, handle weapons change but also delete the timer if the client have the max weapon
{
	if (h_TimerDimensionWeaponManagement[client] != null)
	{
		//This timer already exists.
		if(i_CustomWeaponEquipLogic[weapon] == WEAPON_DIMENSION_RIPPER)
		{
			//Is the weapon it again?
			//Yes?
			delete h_TimerDimensionWeaponManagement[client];
			h_TimerDimensionWeaponManagement[client] = null;
			DataPack pack;
			h_TimerDimensionWeaponManagement[client] = CreateDataTimer(0.1, Timer_Management_Dimension, pack, TIMER_REPEAT);
			pack.WriteCell(client);
			pack.WriteCell(EntIndexToEntRef(weapon));
		}
		return;
	}
		
	if(i_CustomWeaponEquipLogic[weapon] == WEAPON_DIMENSION_RIPPER)
	{
		DataPack pack;
		h_TimerDimensionWeaponManagement[client] = CreateDataTimer(0.1, Timer_Management_Dimension, pack, TIMER_REPEAT);
		pack.WriteCell(client);
		pack.WriteCell(EntIndexToEntRef(weapon));
	}
}

public Action Timer_Management_Dimension(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	int weapon = EntRefToEntIndex(pack.ReadCell());
	if(!IsValidClient(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsValidEntity(weapon))
	{
		h_TimerDimensionWeaponManagement[client] = null;
		return Plugin_Stop;
	}
	int weapon_holding = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(weapon_holding == weapon) //Only show if the weapon is actually in your hand right now.
	{	
		Dimension_Cooldown_Logic(client, weapon);
	}	
	return Plugin_Continue;
}

public void Dimension_Cooldown_Logic(int client, int weapon)
{
	if(f_DIMhuddelay[client] < GetGameTime())
	{
		int weapon_holding = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(weapon_holding == weapon) //Only show if the weapon is actually in your hand right now.
		{
			if(f_DIMAbilityActive[client] < GetGameTime())
			{
				if(how_many_times_swinged[client] < MAX_DIMENSION_CHARGE)
				{
					PrintHintText(client,"Dimension power [%i%/%i]", how_many_times_swinged[client], MAX_DIMENSION_CHARGE);
				}
				else
				{
					PrintHintText(client,"Summon Ready");
				}
			}
			else
			{
				PrintHintText(client,"Hi ;D");
			}
			
			StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
			f_DIMhuddelay[client] = GetGameTime() + 0.5;
		}
	}
}

public void Weapon_Dimension_Wand(int client, int weapon, bool crit)
{
	int mana_cost;
	mana_cost = RoundToCeil(Attributes_Get(weapon, 733, 1.0));

	if(mana_cost <= Current_Mana[client])
	{
		float damage = 100.0;
		damage *= Attributes_Get(weapon, 410, 1.0);
		
		Mana_Regen_Delay[client] = GetGameTime() + 1.0;
		Mana_Hud_Delay[client] = 0.0;
		
		Current_Mana[client] -= mana_cost;
		
		delay_hud[client] = 0.0;
			
		float speed = 1000.0;
		speed *= Attributes_Get(weapon, 103, 1.0);
		
		speed *= Attributes_Get(weapon, 104, 1.0);
		
		speed *= Attributes_Get(weapon, 475, 1.0);
		
		float time = 500.0 / speed;
		time *= Attributes_Get(weapon, 101, 1.0);
		
		time *= Attributes_Get(weapon, 102, 1.0);
		

		EmitSoundToAll(SOUND_WAND_SHOT_DIM, client, SNDCHAN_WEAPON, 65, _, 0.4, 100);
		//This spawns the projectile, this is a return int, if you want, you can do extra stuff with it, otherwise, it can be used as a void.
		switch(GetRandomInt(1, 4))
		{
			case 1:
			{
				Wand_Projectile_Spawn(client, speed, time, damage, 3/*Default wand*/, weapon, "raygun_projectile_blue_trail");
			}
			case 2:
			{
				Wand_Projectile_Spawn(client, speed, time, damage, 3/*Default wand*/, weapon, "raygun_projectile_blue_crit_trail");
			}
			case 3:
			{
				Wand_Projectile_Spawn(client, speed, time, damage, 3/*Default wand*/, weapon, "raygun_projectile_red_trail");
			}
			case 4:
			{
				Wand_Projectile_Spawn(client, speed, time, damage, 3/*Default wand*/, weapon, "raygun_projectile_red_crit_trail");
			}
			default: //This should not happen
			{
				ShowSyncHudText(client,  SyncHud_Notifaction, "An error occured. Scream at devs");//none
			}
		}

	}
	else
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetDefaultHudPosition(client);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
	}
}

public void Wand_DimensionTouch(int entity, int target)
{
	int particle = EntRefToEntIndex(i_WandParticle[entity]);
	if (target > 0)	
	{
		//Code to do damage position and ragdolls
		static float angles[3];
		GetEntPropVector(entity, Prop_Send, "m_angRotation", angles);
		float vecForward[3];
		GetAngleVectors(angles, vecForward, NULL_VECTOR, NULL_VECTOR);
		static float Entity_Position[3];
		Entity_Position = WorldSpaceCenterOld(target);

		int owner = EntRefToEntIndex(i_WandOwner[entity]);
		int weapon = EntRefToEntIndex(i_WandWeapon[entity]);

		SDKHooks_TakeDamage(target, owner, owner, f_WandDamage[entity], DMG_PLASMA, weapon, CalculateDamageForceOld(vecForward, 10000.0), Entity_Position, false);	// 2048 is DMG_NOGIB?
		if(IsValidEntity(particle))
		{
			RemoveEntity(particle);
		}
		EmitSoundToAll(SOUND_DIM_IMPACT, entity, SNDCHAN_STATIC, 80, _, 1.0);
		RemoveEntity(entity);
	}
	else if(target == 0)
	{
		if(IsValidEntity(particle))
		{
			RemoveEntity(particle);
		}
		EmitSoundToAll(SOUND_DIM_IMPACT, entity, SNDCHAN_STATIC, 80, _, 1.0);
		RemoveEntity(entity);
	}
}

public void Weapon_Dimension_Summon_Normal(int client, int weapon, bool &result, int slot)
{
	if(weapon >= MaxClients)
	{
		if (how_many_times_swinged[client] >= MAX_DIMENSION_CHARGE)
		{
			int mana_cost = 100;
			if(mana_cost <= Current_Mana[client])
			{
				Rogue_OnAbilityUse(weapon);
				float pos1[3], ang[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", pos1);
				GetEntPropVector(client, Prop_Data, "m_angRotation", ang);
				float Dimension_Loc[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", Dimension_Loc);
				ParticleEffectAt(Dimension_Loc, "ghost_appearation", 1.0);
				EmitSoundToAll(SOUND_ABILITY, client, SNDCHAN_STATIC, 70, _, 1.0);
				switch(GetRandomInt(1, 19))
				{
					case 1:
					{
						int entity = Npc_Create(HEADCRAB_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 2:
					{
						int entity = Npc_Create(FORTIFIED_HEADCRAB_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)* 13.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 3:
					{
						int entity = Npc_Create(FASTZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*11.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.30 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 4:
					{
						int entity = Npc_Create(FORTIFIED_FASTZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.30 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 5:
					{
						int entity = Npc_Create(TORSOLESS_HEADCRAB_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.30 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 6:
					{
						int entity = Npc_Create(FORTIFIED_GIANT_POISON_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 7:
					{
						int entity = Npc_Create(POISON_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 8:
					{
						int entity = Npc_Create(FORTIFIED_POISON_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 9:
					{
						int entity = Npc_Create(FATHER_GRIGORI, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*25.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.33 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 10:
					{
						int entity = Npc_Create(COMBINE_POLICE_PISTOL, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 11:
					{
						int entity = Npc_Create(COMBINE_SOLDIER_AR2, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 12:
					{
						int entity = Npc_Create(COMBINE_SOLDIER_SHOTGUN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*13.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 13:
					{
						int entity = Npc_Create(COMBINE_POLICE_SMG, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*13.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 14:
					{
						int entity = Npc_Create(COMBINE_SOLDIER_SWORDSMAN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 15:
					{
						int entity = Npc_Create(COMBINE_SOLDIER_ELITE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 16:
					{
						int entity = Npc_Create(COMBINE_SOLDIER_GIANT_SWORDSMAN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*24.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 17:
					{
						int entity = Npc_Create(COMBINE_SOLDIER_DDT, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);

							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 18:
					{
						int entity = Npc_Create(COMBINE_SOLDIER_COLLOSS, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*27.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 19:
					{
						int entity = Npc_Create(COMBINE_OVERLORD, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*30);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					default: //This should not happen
					{
						ShowSyncHudText(client,  SyncHud_Notifaction, "Summon Failed. Scream at devs");//none
					}
				}
				
				int spellbook = SpawnWeapon_Special(client, "tf_weapon_spellbook", 1070, 100, 5, "13 ; 9999");
				Attributes_Set(client, 178, 0.25 * WEAPON_EXTRA_DAMAGE_MODIF);
				FakeClientCommand(client, "use tf_weapon_spellbook");
				Attributes_Set(client, 698, 1.0);
				Delete_Flame[client] = true;
				
				SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
				SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 0);	
					
				Mana_Regen_Delay[client] = GetGameTime() + 1.0;
				Mana_Hud_Delay[client] = 0.0;
				
				Current_Mana[client] -= mana_cost;
					
				delay_hud[client] = 0.0;
				how_many_times_swinged[client] = 0;
			}
			else
			{
				ClientCommand(client, "playgamesound items/medshotno1.wav");
				SetDefaultHudPosition(client);
				SetGlobalTransTarget(client);
				ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
			}
		}
		else
		{
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetDefaultHudPosition(client);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "Not enough Charges");
		}
	}
}

public void Weapon_Dimension_Summon_Normal_PAP(int client, int weapon, bool &result, int slot)
{
	if(weapon >= MaxClients)
	{
		if (how_many_times_swinged[client] >= MAX_DIMENSION_CHARGE)
		{
			int mana_cost = 100;
			if(mana_cost <= Current_Mana[client])
			{
				Rogue_OnAbilityUse(weapon);
				float pos1[3], ang[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", pos1);
				GetEntPropVector(client, Prop_Data, "m_angRotation", ang);
				float Dimension_Loc[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", Dimension_Loc);
				ParticleEffectAt(Dimension_Loc, "ghost_appearation", 1.0);
				EmitSoundToAll(SOUND_ABILITY, client, SNDCHAN_STATIC, 70, _, 1.0);
				switch(GetRandomInt(1, 36))
				{
					case 1:
					{
						int entity = Npc_Create(HEADCRAB_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 2:
					{
						int entity = Npc_Create(FORTIFIED_HEADCRAB_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)* 13.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 3:
					{
						int entity = Npc_Create(FASTZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*11.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 4:
					{
						int entity = Npc_Create(FORTIFIED_FASTZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 5:
					{
						int entity = Npc_Create(TORSOLESS_HEADCRAB_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 6:
					{
						int entity = Npc_Create(FORTIFIED_GIANT_POISON_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 7:
					{
						int entity = Npc_Create(POISON_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 8:
					{
						int entity = Npc_Create(FORTIFIED_POISON_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 9:
					{
						int entity = Npc_Create(FATHER_GRIGORI, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*25.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 10:
					{
						int entity = Npc_Create(COMBINE_POLICE_PISTOL, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 11:
					{
						int entity = Npc_Create(COMBINE_SOLDIER_AR2, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 12:
					{
						int entity = Npc_Create(COMBINE_SOLDIER_SHOTGUN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*13.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 13:
					{
						int entity = Npc_Create(COMBINE_POLICE_SMG, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*13.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 14:
					{
						int entity = Npc_Create(COMBINE_SOLDIER_SWORDSMAN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 15:
					{
						int entity = Npc_Create(COMBINE_SOLDIER_ELITE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 16:
					{
						int entity = Npc_Create(COMBINE_SOLDIER_GIANT_SWORDSMAN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*24.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 17:
					{
						int entity = Npc_Create(COMBINE_SOLDIER_DDT, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);

							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 18:
					{
						int entity = Npc_Create(COMBINE_SOLDIER_COLLOSS, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*27.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 19:
					{
						int entity = Npc_Create(COMBINE_OVERLORD, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*30);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 20:
					{
						int entity = Npc_Create(SPY_MAIN_BOSS, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*31);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.39 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 21:
					{
						int entity = Npc_Create(ENGINEER_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 22:
					{
						int entity = Npc_Create(HEAVY_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 23:
					{
						int entity = Npc_Create(KAMIKAZE_DEMO, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 24:
					{
						int entity = Npc_Create(MEDIC_HEALER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 25:
					{
						int entity = Npc_Create(HEAVY_ZOMBIE_GIANT, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*24.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 26:
					{
						int entity = Npc_Create(SPY_FACESTABBER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 27:
					{
						int entity = Npc_Create(SOLDIER_ROCKET_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 28:
					{
						int entity = Npc_Create(SOLDIER_ZOMBIE_MINION, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 29:
					{
						int entity = Npc_Create(SPY_THIEF, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 30:
					{
						int entity = Npc_Create(SPY_TRICKSTABBER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 31:
					{
						int entity = Npc_Create(SPY_HALF_CLOACKED, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 32:
					{
						int entity = Npc_Create(SNIPER_MAIN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.37 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 33:
					{
						int entity = Npc_Create(DEMO_MAIN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.37 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 34:
					{
						int entity = Npc_Create(BATTLE_MEDIC_MAIN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*21.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.37 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 35:
					{
						int entity = Npc_Create(GIANT_PYRO_MAIN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*24.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.37 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 36:
					{
						int entity = Npc_Create(COMBINE_DEUTSCH_RITTER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 10.0)*22);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					default: //This should not happen
					{
						ShowSyncHudText(client,  SyncHud_Notifaction, "Summon Failed. Scream at devs");//none
					}
				}
				
				int spellbook = SpawnWeapon_Special(client, "tf_weapon_spellbook", 1070, 100, 5, "13 ; 9999");
				Attributes_Set(client, 178, 0.25 * WEAPON_EXTRA_DAMAGE_MODIF);
				FakeClientCommand(client, "use tf_weapon_spellbook");
				Attributes_Set(client, 698, 1.0);
				Delete_Flame[client] = true;
				
				SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
				SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 0);	
					
				Mana_Regen_Delay[client] = GetGameTime() + 1.0;
				Mana_Hud_Delay[client] = 0.0;
				
				Current_Mana[client] -= mana_cost;
					
				delay_hud[client] = 0.0;

				how_many_times_swinged[client] = 0;
			}
			else
			{
				ClientCommand(client, "playgamesound items/medshotno1.wav");
				SetDefaultHudPosition(client);
				SetGlobalTransTarget(client);
				ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
			}
		}
		else
		{
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetDefaultHudPosition(client);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "Not enough Charges");
		}
	}
}

public void Weapon_Dimension_Summon_Blitz_PAP(int client, int weapon, bool &result, int slot)
{
	if(weapon >= MaxClients)
	{
		if (how_many_times_swinged[client] >= MAX_DIMENSION_CHARGE)
		{
			int mana_cost = 100;
			if(mana_cost <= Current_Mana[client])
			{
				Rogue_OnAbilityUse(weapon);
				float pos1[3], ang[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", pos1);
				GetEntPropVector(client, Prop_Data, "m_angRotation", ang);
				float Dimension_Loc[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", Dimension_Loc);
				ParticleEffectAt(Dimension_Loc, "eyeboss_tp_player", 1.0);
				EmitSoundToAll(SOUND_ABILITY, client, SNDCHAN_STATIC, 70, _, 1.0);
				switch(GetRandomInt(1, 17))
				{
					case 1:
					{
						int entity = Npc_Create(ALT_COMBINE_MAGE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 250.0)*11.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 2:
					{
						int entity = Npc_Create(ALT_MEDIC_APPRENTICE_MAGE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*11.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 3:
					{
						int entity = Npc_Create(ALT_MEDIC_CHARGER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.35 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 4:
					{
						int entity = Npc_Create(ALT_MEDIC_BERSERKER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*18.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.35 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 5:
					{
						int entity = Npc_Create(ALT_MEDIC_SUPPERIOR_MAGE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*20.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.33 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 6:
					{
						int entity = Npc_Create(ALT_SNIPER_RAILGUNNER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*9.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.33 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 7:
					{
						int entity = Npc_Create(ALT_SOLDIER_BARRAGER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*13.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.33 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 8:
					{
						int entity = Npc_Create(ALT_The_Shit_Slapper, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*22.5);
							maxhealth = RoundFloat(float(maxhealth) * 1.1);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.35 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 9:
					{
						int entity = Npc_Create(ALT_MECHA_ENGINEER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 10:
					{
						int entity = Npc_Create(ALT_MECHA_HEAVY, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) *0.25 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 11:
					{
						int entity = Npc_Create(ALT_MECHA_SCOUT, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.25 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 12:
					{
						int entity = Npc_Create(ALT_MECHASOLDIER_BARRAGER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.35 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 13:
					{
						int entity = Npc_Create(ALT_MECHA_HEAVYGIANT, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*22.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.25 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 14:
					{
						int entity = Npc_Create(ALT_MECHA_PYROGIANT, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*22.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.25 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 15:
					{
						int entity = Npc_Create(ALT_COMBINE_DEUTSCH_RITTER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*22.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 16:
					{
						int entity = Npc_Create(ALT_MEDIC_HEALER_3, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.20);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 17:
					{
						int entity = Npc_Create(ALT_SCHWERTKRIEG, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*30.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.25 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					default: //This should not happen
					{
						ShowSyncHudText(client,  SyncHud_Notifaction, "Summon Failed. Scream at devs");//none
					}
				}
				
				int spellbook = SpawnWeapon_Special(client, "tf_weapon_spellbook", 1070, 100, 5, "13 ; 9999");
				Attributes_Set(client, 178, 0.25 * WEAPON_EXTRA_DAMAGE_MODIF);
				FakeClientCommand(client, "use tf_weapon_spellbook");
				Attributes_Set(client, 698, 1.0);
				Delete_Flame[client] = true;
				
				SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
				SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 0);	
					
				Mana_Regen_Delay[client] = GetGameTime() + 1.0;
				Mana_Hud_Delay[client] = 0.0;
				
				Current_Mana[client] -= mana_cost;
					
				delay_hud[client] = 0.0;

				how_many_times_swinged[client] = 0;
			}
			else
			{
				ClientCommand(client, "playgamesound items/medshotno1.wav");
				SetDefaultHudPosition(client);
				SetGlobalTransTarget(client);
				ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
			}
		}
		else
		{
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetDefaultHudPosition(client);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "Not enough Charges");
		}
	}
}

public void Weapon_Dimension_Summon_Blitz(int client, int weapon, bool &result, int slot)
{
	if(weapon >= MaxClients)
	{
		if (how_many_times_swinged[client] >= MAX_DIMENSION_CHARGE)
		{
			int mana_cost = 100;
			if(mana_cost <= Current_Mana[client])
			{
				Rogue_OnAbilityUse(weapon);
				float pos1[3], ang[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", pos1);
				GetEntPropVector(client, Prop_Data, "m_angRotation", ang);
				float Dimension_Loc[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", Dimension_Loc);
				ParticleEffectAt(Dimension_Loc, "eyeboss_tp_player", 1.0);
				EmitSoundToAll(SOUND_ABILITY, client, SNDCHAN_STATIC, 70, _, 1.0);
				switch(GetRandomInt(1, 12))
				{
					case 1:
					{
						int entity = Npc_Create(ALT_COMBINE_MAGE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 250.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 2:
					{
						int entity = Npc_Create(ALT_MEDIC_APPRENTICE_MAGE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 3:
					{
						int entity = Npc_Create(ALT_MEDIC_CHARGER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 4:
					{
						int entity = Npc_Create(ALT_MEDIC_BERSERKER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*20.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.33 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 5:
					{
						int entity = Npc_Create(ALT_MEDIC_SUPPERIOR_MAGE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*24.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.33 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 6:
					{
						int entity = Npc_Create(ALT_SNIPER_RAILGUNNER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*13.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.33 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 7:
					{
						int entity = Npc_Create(ALT_SOLDIER_BARRAGER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.33 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 8:
					{
						int entity = Npc_Create(ALT_The_Shit_Slapper, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*24.5);
							maxhealth = RoundFloat(float(maxhealth) * 1.1);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 9:
					{
						int entity = Npc_Create(ALT_MECHA_ENGINEER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 10:
					{
						int entity = Npc_Create(ALT_MECHA_HEAVY, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) *0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 11:
					{
						int entity = Npc_Create(ALT_MECHA_SCOUT, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 12:
					{
						int entity = Npc_Create(ALT_MECHASOLDIER_BARRAGER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.35 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					default: //This should not happen
					{
						ShowSyncHudText(client,  SyncHud_Notifaction, "Summon Failed. Scream at devs");//none
					}
				}
				
				int spellbook = SpawnWeapon_Special(client, "tf_weapon_spellbook", 1070, 100, 5, "13 ; 9999");
				Attributes_Set(client, 178, 0.25 * WEAPON_EXTRA_DAMAGE_MODIF);
				FakeClientCommand(client, "use tf_weapon_spellbook");
				Attributes_Set(client, 698, 1.0);
				Delete_Flame[client] = true;
				
				SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
				SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 0);	
					
				Mana_Regen_Delay[client] = GetGameTime() + 1.0;
				Mana_Hud_Delay[client] = 0.0;
				
				Current_Mana[client] -= mana_cost;
					
				delay_hud[client] = 0.0;

				how_many_times_swinged[client] = 0;
			}
			else
			{
				ClientCommand(client, "playgamesound items/medshotno1.wav");
				SetDefaultHudPosition(client);
				SetGlobalTransTarget(client);
				ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
			}
		}
		else
		{
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetDefaultHudPosition(client);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "Not enough Charges");
		}
	}
}

public void Weapon_Dimension_Summon_Xeno(int client, int weapon, bool &result, int slot)
{
	if(weapon >= MaxClients)
	{
		if (how_many_times_swinged[client] >= MAX_DIMENSION_CHARGE)
		{
			int mana_cost = 150;
			if(mana_cost <= Current_Mana[client])
			{
				Rogue_OnAbilityUse(weapon);
				float pos1[3], ang[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", pos1);
				GetEntPropVector(client, Prop_Data, "m_angRotation", ang);
				float Dimension_Loc[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", Dimension_Loc);
				ParticleEffectAt(Dimension_Loc, "utaunt_smoke_floor1_green", 1.0);
				EmitSoundToAll(SOUND_ABILITY, client, SNDCHAN_STATIC, 70, _, 1.0);
				switch(GetRandomInt(1, 28))
				{
					case 1:
					{
						int entity = Npc_Create(XENO_HEADCRAB_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 2:
					{
						int entity = Npc_Create(XENO_FORTIFIED_HEADCRAB_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*13.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 3:
					{
						int entity = Npc_Create(XENO_FASTZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 11.5));
							maxhealth = RoundFloat(float(maxhealth) * 0.9);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 4:
					{
						int entity = Npc_Create(XENO_FORTIFIED_FASTZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 5:
					{
						int entity = Npc_Create(XENO_TORSOLESS_HEADCRAB_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*13.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 6:
					{
						int entity = Npc_Create(XENO_FORTIFIED_GIANT_POISON_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 7:
					{
						int entity = Npc_Create(XENO_POISON_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 8:
					{
						int entity = Npc_Create(XENO_FORTIFIED_POISON_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 9:
					{
						int entity = Npc_Create(XENO_COMBINE_POLICE_PISTOL, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 10:
					{
						int entity = Npc_Create(XENO_COMBINE_POLICE_SMG, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*13.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 11:
					{
						int entity = Npc_Create(XENO_COMBINE_SOLDIER_AR2, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*13.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 12:
					{
						int entity = Npc_Create(XENO_COMBINE_SOLDIER_SHOTGUN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*13.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 13:
					{
						int entity = Npc_Create(XENO_COMBINE_SOLDIER_SWORDSMAN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 14:
					{
						int entity = Npc_Create(XENO_COMBINE_SOLDIER_ELITE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 15:
					{
						int entity = Npc_Create(XENO_COMBINE_SOLDIER_GIANT_SWORDSMAN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*24.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 16:
					{
						int entity = Npc_Create(XENO_COMBINE_SOLDIER_DDT, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 17:
					{
						int entity = Npc_Create(XENO_COMBINE_SOLDIER_COLLOSS, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*27.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 18:
					{
						int entity = Npc_Create(XENO_SCOUT_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 19:
					{
						int entity = Npc_Create(XENO_ENGINEER_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 20:
					{
						int entity = Npc_Create(XENO_HEAVY_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 21:
					{
						int entity = Npc_Create(XENO_KAMIKAZE_DEMO, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.35 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 22:
					{
						int entity = Npc_Create(XENO_SPY_FACESTABBER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 23:
					{
						int entity = Npc_Create(XENO_SOLDIER_ROCKET_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 24:
					{
						int entity = Npc_Create(XENO_SPY_THIEF, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 25:
					{
						int entity = Npc_Create(XENO_SPY_TRICKSTABBER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 26:
					{
						int entity = Npc_Create(XENO_SPY_HALF_CLOACKED, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 27:
					{
						int entity = Npc_Create(XENO_SNIPER_MAIN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 28:
					{
						int entity = Npc_Create(XENO_DEMO_MAIN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					default: //This should not happen
					{
						ShowSyncHudText(client,  SyncHud_Notifaction, "Summon Failed. Scream at devs");//none
					}
				}
				
				int spellbook = SpawnWeapon_Special(client, "tf_weapon_spellbook", 1070, 100, 5, "13 ; 9999");
				Attributes_Set(client, 178, 0.25 * WEAPON_EXTRA_DAMAGE_MODIF);
				FakeClientCommand(client, "use tf_weapon_spellbook");
				Attributes_Set(client, 698, 1.0);
				Delete_Flame[client] = true;
				
				SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
				SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 0);	
					
				Mana_Regen_Delay[client] = GetGameTime() + 1.0;
				Mana_Hud_Delay[client] = 0.0;
				
				Current_Mana[client] -= mana_cost;
					
				delay_hud[client] = 0.0;

				how_many_times_swinged[client] = 0;
			}
			else
			{
				ClientCommand(client, "playgamesound items/medshotno1.wav");
				SetDefaultHudPosition(client);
				SetGlobalTransTarget(client);
				ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
			}
		}
		else
		{
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetDefaultHudPosition(client);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "Not enough Charges");
		}
	}
}

public void Weapon_Dimension_Summon_Xeno_PAP(int client, int weapon, bool &result, int slot)
{
	if(weapon >= MaxClients)
	{
		if (how_many_times_swinged[client] >= MAX_DIMENSION_CHARGE)
		{
			int mana_cost = 150;
			if(mana_cost <= Current_Mana[client])
			{
				Rogue_OnAbilityUse(weapon);
				float pos1[3], ang[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", pos1);
				GetEntPropVector(client, Prop_Data, "m_angRotation", ang);
				float Dimension_Loc[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", Dimension_Loc);
				ParticleEffectAt(Dimension_Loc, "utaunt_smoke_floor1_green", 1.0);
				EmitSoundToAll(SOUND_ABILITY, client, SNDCHAN_STATIC, 70, _, 1.0);
				switch(GetRandomInt(1, 36))
				{
					case 1:
					{
						int entity = Npc_Create(XENO_HEADCRAB_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 2:
					{
						int entity = Npc_Create(XENO_FORTIFIED_HEADCRAB_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*13.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 3:
					{
						int entity = Npc_Create(XENO_FASTZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 11.5));
							maxhealth = RoundFloat(float(maxhealth) * 0.9);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 4:
					{
						int entity = Npc_Create(XENO_FORTIFIED_FASTZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 5:
					{
						int entity = Npc_Create(XENO_TORSOLESS_HEADCRAB_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*13.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 6:
					{
						int entity = Npc_Create(XENO_FORTIFIED_GIANT_POISON_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 7:
					{
						int entity = Npc_Create(XENO_POISON_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 8:
					{
						int entity = Npc_Create(XENO_FORTIFIED_POISON_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 9:
					{
						int entity = Npc_Create(XENO_COMBINE_POLICE_PISTOL, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 10:
					{
						int entity = Npc_Create(XENO_COMBINE_POLICE_SMG, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*13.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 11:
					{
						int entity = Npc_Create(XENO_COMBINE_SOLDIER_AR2, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*13.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 12:
					{
						int entity = Npc_Create(XENO_COMBINE_SOLDIER_SHOTGUN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*13.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 13:
					{
						int entity = Npc_Create(XENO_COMBINE_SOLDIER_SWORDSMAN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 14:
					{
						int entity = Npc_Create(XENO_COMBINE_SOLDIER_ELITE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 15:
					{
						int entity = Npc_Create(XENO_COMBINE_SOLDIER_GIANT_SWORDSMAN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*24.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 16:
					{
						int entity = Npc_Create(XENO_COMBINE_SOLDIER_DDT, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 17:
					{
						int entity = Npc_Create(XENO_COMBINE_SOLDIER_COLLOSS, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*27.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 18:
					{
						int entity = Npc_Create(XENO_SCOUT_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 19:
					{
						int entity = Npc_Create(XENO_ENGINEER_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 20:
					{
						int entity = Npc_Create(XENO_HEAVY_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 21:
					{
						int entity = Npc_Create(XENO_KAMIKAZE_DEMO, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.35 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 22:
					{
						int entity = Npc_Create(XENO_SPY_FACESTABBER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 23:
					{
						int entity = Npc_Create(XENO_SOLDIER_ROCKET_ZOMBIE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 24:
					{
						int entity = Npc_Create(XENO_SPY_THIEF, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 25:
					{
						int entity = Npc_Create(XENO_SPY_TRICKSTABBER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 26:
					{
						int entity = Npc_Create(XENO_SPY_HALF_CLOACKED, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 27:
					{
						int entity = Npc_Create(XENO_SNIPER_MAIN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 28:
					{
						int entity = Npc_Create(XENO_DEMO_MAIN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 29:
					{
						int entity = Npc_Create(XENO_COMBINE_OVERLORD, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*30);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 30:
					{
						int entity = Npc_Create(XENO_FATHER_GRIGORI, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*30);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 31:
					{
						int entity = Npc_Create(XENO_MEDIC_HEALER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.21);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 32:
					{
						int entity = Npc_Create(XENO_BATTLE_MEDIC_MAIN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*21.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 33:
					{
						int entity = Npc_Create(XENO_GIANT_PYRO_MAIN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*25.0);

							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 34:
					{
						int entity = Npc_Create(XENO_COMBINE_DEUTSCH_RITTER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*22.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 35:
					{
						int entity = Npc_Create(XENO_SPY_MAIN_BOSS, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*31);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					default: //This should not happen
					{
						ShowSyncHudText(client,  SyncHud_Notifaction, "Summon Failed. Scream at devs");//none
					}
				}
				
				int spellbook = SpawnWeapon_Special(client, "tf_weapon_spellbook", 1070, 100, 5, "13 ; 9999");
				Attributes_Set(client, 178, 0.25 * WEAPON_EXTRA_DAMAGE_MODIF);
				FakeClientCommand(client, "use tf_weapon_spellbook");
				Attributes_Set(client, 698, 1.0);
				Delete_Flame[client] = true;
				
				SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
				SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 0);	
					
				Mana_Regen_Delay[client] = GetGameTime() + 1.0;
				Mana_Hud_Delay[client] = 0.0;
				
				Current_Mana[client] -= mana_cost;
					
				delay_hud[client] = 0.0;

				how_many_times_swinged[client] = 0;
			}
			else
			{
				ClientCommand(client, "playgamesound items/medshotno1.wav");
				SetDefaultHudPosition(client);
				SetGlobalTransTarget(client);
				ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
			}
		}
		else
		{
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetDefaultHudPosition(client);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "Not enough Charges");
		}
	}
}

public void Weapon_Dimension_Summon_Medeival(int client, int weapon, bool &result, int slot)
{
	if(weapon >= MaxClients)
	{
		if (how_many_times_swinged[client] >= MAX_DIMENSION_CHARGE)
		{
			int mana_cost = 150;
			if(mana_cost <= Current_Mana[client])
			{
				Rogue_OnAbilityUse(weapon);
				float pos1[3], ang[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", pos1);
				GetEntPropVector(client, Prop_Data, "m_angRotation", ang);
				float Dimension_Loc[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", Dimension_Loc);
				ParticleEffectAt(Dimension_Loc, "npc_boss_bomb_alert", 1.0);
				EmitSoundToAll(SOUND_ABILITY, client, SNDCHAN_STATIC, 70, _, 1.0);
				switch(GetRandomInt(1, 22))
				{
					case 1:
					{
						int entity = Npc_Create(MEDIVAL_MILITIA, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 2:
					{
						int entity = Npc_Create(MEDIVAL_ARCHER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 3:
					{
						int entity = Npc_Create(MEDIVAL_MAN_AT_ARMS, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 4:
					{
						int entity = Npc_Create(MEDIVAL_SWORDSMAN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 5:
					{
						int entity = Npc_Create(MEDIVAL_TWOHANDED_SWORDSMAN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*18.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 6:
					{
						int entity = Npc_Create(MEDIVAL_CROSSBOW_MAN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 7:
					{
						int entity = Npc_Create(MEDIVAL_SPEARMEN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 8:
					{
						int entity = Npc_Create(MEDIVAL_HANDCANNONEER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 9:
					{
						int entity = Npc_Create(MEDIVAL_ELITE_SKIRMISHER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 10:
					{
						int entity = Npc_Create(MEDIVAL_EAGLE_SCOUT, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 11:
					{
						int entity = Npc_Create(MEDIVAL_SAMURAI, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 12:
					{
						int entity = Npc_Create(MEDIVAL_CHAMPION, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 13:
					{
						int entity = Npc_Create(MEDIVAL_LIGHT_CAV, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 14:
					{
						int entity = Npc_Create(MEDIVAL_BRAWLER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 15:
					{
						int entity = Npc_Create(MEDIVAL_EAGLE_WARRIOR, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*18.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 16:
					{
						int entity = Npc_Create(MEDIVAL_CAVALARY, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*18.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 17:
					{
						int entity = Npc_Create(MEDIVAL_HALB, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*21.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 18:
					{
						int entity = Npc_Create(MEDIVAL_LONGBOWMEN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 19:
					{
						int entity = Npc_Create(MEDIVAL_ARBALEST, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 20:
					{
						int entity = Npc_Create(MEDIVAL_ELITE_LONGBOWMEN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*18.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 21:
					{
						int entity = Npc_Create(MEDIVAL_PALADIN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*22.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 22:
					{
						int entity = Npc_Create(MEDIVAL_RIDDENARCHER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					default: //This should not happen
					{
						ShowSyncHudText(client,  SyncHud_Notifaction, "Summon Failed. Scream at devs");//none
					}
				}
				
				int spellbook = SpawnWeapon_Special(client, "tf_weapon_spellbook", 1070, 100, 5, "13 ; 9999");
				Attributes_Set(client, 178, 0.25 * WEAPON_EXTRA_DAMAGE_MODIF);
				FakeClientCommand(client, "use tf_weapon_spellbook");
				Attributes_Set(client, 698, 1.0);
				Delete_Flame[client] = true;
				
				SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
				SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 0);	
					
				Mana_Regen_Delay[client] = GetGameTime() + 1.0;
				Mana_Hud_Delay[client] = 0.0;
				
				Current_Mana[client] -= mana_cost;
					
				delay_hud[client] = 0.0;

				how_many_times_swinged[client] = 0;
			}
			else
			{
				ClientCommand(client, "playgamesound items/medshotno1.wav");
				SetDefaultHudPosition(client);
				SetGlobalTransTarget(client);
				ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
			}
		}
		else
		{
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetDefaultHudPosition(client);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "Not enough Charges");
		}
	}
}

public void Weapon_Dimension_Summon_Medeival_PAP(int client, int weapon, bool &result, int slot)
{
	if(weapon >= MaxClients)
	{
		if (how_many_times_swinged[client] >= MAX_DIMENSION_CHARGE)
		{
			int mana_cost = 150;
			if(mana_cost <= Current_Mana[client])
			{
				Rogue_OnAbilityUse(weapon);
				float pos1[3], ang[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", pos1);
				GetEntPropVector(client, Prop_Data, "m_angRotation", ang);
				float Dimension_Loc[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", Dimension_Loc);
				ParticleEffectAt(Dimension_Loc, "npc_boss_bomb_alert", 1.0);
				EmitSoundToAll(SOUND_ABILITY, client, SNDCHAN_STATIC, 70, _, 1.0);
				switch(GetRandomInt(1,33))
				{
					case 1:
					{
						int entity = Npc_Create(MEDIVAL_MILITIA, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 2:
					{
						int entity = Npc_Create(MEDIVAL_ARCHER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 3:
					{
						int entity = Npc_Create(MEDIVAL_MAN_AT_ARMS, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 4:
					{
						int entity = Npc_Create(MEDIVAL_SWORDSMAN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 5:
					{
						int entity = Npc_Create(MEDIVAL_TWOHANDED_SWORDSMAN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*18.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 6:
					{
						int entity = Npc_Create(MEDIVAL_CROSSBOW_MAN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 7:
					{
						int entity = Npc_Create(MEDIVAL_SPEARMEN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 8:
					{
						int entity = Npc_Create(MEDIVAL_HANDCANNONEER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 9:
					{
						int entity = Npc_Create(MEDIVAL_ELITE_SKIRMISHER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 10:
					{
						int entity = Npc_Create(MEDIVAL_EAGLE_SCOUT, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 11:
					{
						int entity = Npc_Create(MEDIVAL_SAMURAI, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 12:
					{
						int entity = Npc_Create(MEDIVAL_CHAMPION, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 13:
					{
						int entity = Npc_Create(MEDIVAL_LIGHT_CAV, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 14:
					{
						int entity = Npc_Create(MEDIVAL_BRAWLER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 15:
					{
						int entity = Npc_Create(MEDIVAL_EAGLE_WARRIOR, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*18.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 16:
					{
						int entity = Npc_Create(MEDIVAL_CAVALARY, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*18.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 17:
					{
						int entity = Npc_Create(MEDIVAL_HALB, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*21.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 18:
					{
						int entity = Npc_Create(MEDIVAL_LONGBOWMEN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 19:
					{
						int entity = Npc_Create(MEDIVAL_ARBALEST, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 20:
					{
						int entity = Npc_Create(MEDIVAL_ELITE_LONGBOWMEN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*18.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 21:
					{
						int entity = Npc_Create(MEDIVAL_PALADIN, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*22.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 22:
					{
						int entity = Npc_Create(MEDIVAL_RIDDENARCHER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 23:
					{
						int entity = Npc_Create(MEDIVAL_CONSTRUCT, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*29.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 24:
					{
						int entity = Npc_Create(MEDIVAL_RAM, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.20);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 25:
					{
						int entity = Npc_Create(MEDIVAL_SCOUT, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 26:
					{
						int entity = Npc_Create(MEDIVAL_HUSSAR, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*24.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 27:
					{
						int entity = Npc_Create(MEDIVAL_OBUCH, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)* 23.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 28:
					{
						int entity = Npc_Create(MEDIVAL_MONK, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0) * 12.0 );
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 29:
					{
						int entity = Npc_Create(MEDIVAL_CROSSBOW_GIANT, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0) * 27.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 30:
					{
						int entity = Npc_Create(MEDIVAL_SWORDSMAN_GIANT, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0) * 27.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 31:
					{
						int entity = Npc_Create(MEDIVAL_EAGLE_GIANT, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0) * 27.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 32:
					{
						int entity = Npc_Create(MEDIVAL_ACHILLES, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0) * 30);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.30 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 33:
					{
						int entity = Npc_Create(MEDIVAL_SON_OF_OSIRIS, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0) * 31);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					default: //This should not happen
					{
						ShowSyncHudText(client,  SyncHud_Notifaction, "Summon Failed. Scream at devs");//none
					}
				}
				
				int spellbook = SpawnWeapon_Special(client, "tf_weapon_spellbook", 1070, 100, 5, "13 ; 9999");
				Attributes_Set(client, 178, 0.25 * WEAPON_EXTRA_DAMAGE_MODIF);
				FakeClientCommand(client, "use tf_weapon_spellbook");
				Attributes_Set(client, 698, 1.0);
				Delete_Flame[client] = true;
				
				SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
				SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 0);	
					
				Mana_Regen_Delay[client] = GetGameTime() + 1.0;
				Mana_Hud_Delay[client] = 0.0;
				
				Current_Mana[client] -= mana_cost;
					
				delay_hud[client] = 0.0;

				how_many_times_swinged[client] = 0;
			}
			else
			{
				ClientCommand(client, "playgamesound items/medshotno1.wav");
				SetDefaultHudPosition(client);
				SetGlobalTransTarget(client);
				ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
			}
		}
		else
		{
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetDefaultHudPosition(client);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "Not enough Charges");
		}
	}
}


public void Weapon_Dimension_Summon_Seaborn(int client, int weapon, bool &result, int slot)
{
	if(weapon >= MaxClients)
	{
		if (how_many_times_swinged[client] >= MAX_DIMENSION_CHARGE)
		{
			int mana_cost = 150;
			if(mana_cost <= Current_Mana[client])
			{
				Rogue_OnAbilityUse(weapon);
				float pos1[3], ang[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", pos1);
				GetEntPropVector(client, Prop_Data, "m_angRotation", ang);
				float Dimension_Loc[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", Dimension_Loc);
				ParticleEffectAt(Dimension_Loc, "utaunt_constellations_blue_base", 1.0);
				EmitSoundToAll(SOUND_ABILITY, client, SNDCHAN_STATIC, 70, _, 1.0);
				switch(GetRandomInt(1, 10))
				{
					case 1:
					{
						int entity = Npc_Create(SEARUNNER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 2:
					{
						int entity = Npc_Create(SEASLIDER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 3:
					{
						int entity = Npc_Create(SEASPITTER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 4:
					{
						int entity = Npc_Create(SEAREAPER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*21.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.20);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 5:
					{
						int entity = Npc_Create(SEACRAWLER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 6:
					{
						int entity = Npc_Create(SEAPIERCER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 7:
					{
						int entity = Npc_Create(SEAPREDATOR, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*10.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 8:
					{
						int entity = Npc_Create(SEASPEWER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 9:
					{
						int entity = Npc_Create(SEASWARMCALLER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 10:
					{
						int entity = Npc_Create(SEAREEFBREAKER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*20.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					default: //This should not happen
					{
						ShowSyncHudText(client,  SyncHud_Notifaction, "Summon Failed. Scream at devs");//none
					}
				}
				
				int spellbook = SpawnWeapon_Special(client, "tf_weapon_spellbook", 1070, 100, 5, "13 ; 9999");
				Attributes_Set(client, 178, 0.25 * WEAPON_EXTRA_DAMAGE_MODIF);
				FakeClientCommand(client, "use tf_weapon_spellbook");
				Attributes_Set(client, 698, 1.0);
				Delete_Flame[client] = true;
				
				SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
				SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 0);	
					
				Mana_Regen_Delay[client] = GetGameTime() + 1.0;
				Mana_Hud_Delay[client] = 0.0;
				
				Current_Mana[client] -= mana_cost;
					
				delay_hud[client] = 0.0;

				how_many_times_swinged[client] = 0;
			}
			else
			{
				ClientCommand(client, "playgamesound items/medshotno1.wav");
				SetDefaultHudPosition(client);
				SetGlobalTransTarget(client);
				ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
			}
		}
		else
		{
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetDefaultHudPosition(client);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "Not enough Charges");
		}
	}
}

public void Weapon_Dimension_Summon_Seaborn_PAP(int client, int weapon, bool &result, int slot)
{
	if(weapon >= MaxClients)
	{
		if (how_many_times_swinged[client] >= MAX_DIMENSION_CHARGE)
		{
			int mana_cost = 150;
			if(mana_cost <= Current_Mana[client])
			{
				Rogue_OnAbilityUse(weapon);
				float pos1[3], ang[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", pos1);
				GetEntPropVector(client, Prop_Data, "m_angRotation", ang);
				float Dimension_Loc[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", Dimension_Loc);
				ParticleEffectAt(Dimension_Loc, "utaunt_constellations_blue_base", 1.0);
				EmitSoundToAll(SOUND_ABILITY, client, SNDCHAN_STATIC, 70, _, 1.0);
				switch(GetRandomInt(1, 26))
				{
					case 1:
					{
						int entity = Npc_Create(SEARUNNER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 2:
					{
						int entity = Npc_Create(SEASLIDER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 3:
					{
						int entity = Npc_Create(SEASPITTER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 4:
					{
						int entity = Npc_Create(SEAREAPER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*21.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.20);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 5:
					{
						int entity = Npc_Create(SEACRAWLER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 6:
					{
						int entity = Npc_Create(SEAPIERCER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 7:
					{
						int entity = Npc_Create(SEAPREDATOR, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*10.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 8:
					{
						int entity = Npc_Create(SEASPEWER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 9:
					{
						int entity = Npc_Create(SEASWARMCALLER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 10:
					{
						int entity = Npc_Create(SEAREEFBREAKER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*20.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 11:
					{
						int entity = Npc_Create(SEABORN_KAZIMIERZ_KNIGHT, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 12:
					{
						int entity = Npc_Create(SEABORN_KAZIMIERZ_KNIGHT_ARCHER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 13:
					{
						int entity = Npc_Create(SEABORN_KAZIMIERZ_LONGARCHER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 14:
					{
						int entity = Npc_Create(SEABORN_KAZIMIERZ_ASSASIN_MELEE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*18.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 15:
					{
						int entity = Npc_Create(SEABORN_SCOUT, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 16:
					{
						int entity = Npc_Create(SEABORN_PYRO, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 17:
					{
						int entity = Npc_Create(SEABORN_DEMO, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.35 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 18:
					{
						int entity = Npc_Create(SEABORN_HEAVY, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 19:
					{
						int entity = Npc_Create(SEABORN_MEDIC, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*13.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 20:
					{
						int entity = Npc_Create(SEABORN_SNIPER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 21:
					{
						int entity = Npc_Create(SEABORN_SPY, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 22:
					{
						int entity = Npc_Create(SEABORN_GUARD, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*22.0);
							maxhealth = RoundFloat(float(maxhealth) * 1.1);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 23:
					{
						int entity = Npc_Create(SEABORN_DEFENDER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*24.5);
							maxhealth = RoundFloat(float(maxhealth) * 1.2);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 24:
					{
						int entity = Npc_Create(SEABORN_CASTER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 25:
					{
						int entity = Npc_Create(SEABORN_SPECIALIST, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					default: //This should not happen
					{
						ShowSyncHudText(client,  SyncHud_Notifaction, "Summon Failed. Scream at devs");//none
					}
				}
				
				int spellbook = SpawnWeapon_Special(client, "tf_weapon_spellbook", 1070, 100, 5, "13 ; 9999");
				Attributes_Set(client, 178, 0.25 * WEAPON_EXTRA_DAMAGE_MODIF);
				FakeClientCommand(client, "use tf_weapon_spellbook");
				Attributes_Set(client, 698, 1.0);
				Delete_Flame[client] = true;
				
				SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
				SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 0);	
					
				Mana_Regen_Delay[client] = GetGameTime() + 1.0;
				Mana_Hud_Delay[client] = 0.0;
				
				Current_Mana[client] -= mana_cost;
					
				delay_hud[client] = 0.0;

				how_many_times_swinged[client] = 0;
			}
			else
			{
				ClientCommand(client, "playgamesound items/medshotno1.wav");
				SetDefaultHudPosition(client);
				SetGlobalTransTarget(client);
				ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
			}
		}
		else
		{
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetDefaultHudPosition(client);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "Not enough Charges");
		}
	}
}

public void Weapon_Dimension_Summon_Expidonsa(int client, int weapon, bool &result, int slot)
{
	if(weapon >= MaxClients)
	{
		if (how_many_times_swinged[client] >= MAX_DIMENSION_CHARGE)
		{
			int mana_cost = 150;
			if(mana_cost <= Current_Mana[client])
			{
				Rogue_OnAbilityUse(weapon);
				float pos1[3], ang[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", pos1);
				GetEntPropVector(client, Prop_Data, "m_angRotation", ang);
				float Dimension_Loc[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", Dimension_Loc);
				ParticleEffectAt(Dimension_Loc, "eyeboss_death_vortex", 1.5);
				EmitSoundToAll(SOUND_ABILITY, client, SNDCHAN_STATIC, 70, _, 1.0);
				switch(GetRandomInt(1, 14))
				{
					case 1:
					{
						int entity = Npc_Create(EXPIDONSA_BENERA, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 2:
					{
						int entity = Npc_Create(EXPIDONSA_PENTAL, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 3:
					{
						int entity = Npc_Create(EXPIDONSA_DEFANDA, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 4:
					{
						int entity = Npc_Create(EXPIDONSA_SELFAM_IRE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 5:
					{
						int entity = Npc_Create(EXPIDONSA_VAUSMAGICA, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.20);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 6:
					{
						int entity = Npc_Create(EXPIDONSA_PISTOLEER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 7:
					{
						int entity = Npc_Create(EXPIDONSA_DIVERSIONISTICO, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 8:
					{
						int entity = Npc_Create(EXPIDONSA_RIFALMANU, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 9:
					{
						int entity = Npc_Create(EXPIDONSA_SICCERINO, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 10:
					{
						int entity = Npc_Create(EXPIDONSA_SOLDINE_PROTOTYPE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*24.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 11:
					{
						int entity = Npc_Create(EXPIDONSA_PROTECTA, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 12:
					{
						int entity = Npc_Create(EXPIDONSA_EGABUNAR, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 13:
					{
						int entity = Npc_Create(EXPIDONSA_ENEGAKAPUS, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.30 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 14:
					{
						int entity = Npc_Create(EXPIDONSA_VAUSTECHICUS, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					default: //This should not happen
					{
						ShowSyncHudText(client,  SyncHud_Notifaction, "Summon Failed. Scream at devs");//none
					}
				}
				
				int spellbook = SpawnWeapon_Special(client, "tf_weapon_spellbook", 1070, 100, 5, "13 ; 9999");
				Attributes_Set(client, 178, 0.25 * WEAPON_EXTRA_DAMAGE_MODIF);
				FakeClientCommand(client, "use tf_weapon_spellbook");
				Attributes_Set(client, 698, 1.0);
				Delete_Flame[client] = true;
				
				SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
				SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 0);	
					
				Mana_Regen_Delay[client] = GetGameTime() + 1.0;
				Mana_Hud_Delay[client] = 0.0;
				
				Current_Mana[client] -= mana_cost;
					
				delay_hud[client] = 0.0;

				how_many_times_swinged[client] = 0;
			}
			else
			{
				ClientCommand(client, "playgamesound items/medshotno1.wav");
				SetDefaultHudPosition(client);
				SetGlobalTransTarget(client);
				ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
			}
		}
		else
		{
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetDefaultHudPosition(client);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "Not enough Charges");
		}
	}
}

public void Weapon_Dimension_Summon_Expidonsa_PAP(int client, int weapon, bool &result, int slot)
{
	if(weapon >= MaxClients)
	{
		if (how_many_times_swinged[client] >= MAX_DIMENSION_CHARGE)
		{
			int mana_cost = 150;
			if(mana_cost <= Current_Mana[client])
			{
				Rogue_OnAbilityUse(weapon);
				float pos1[3], ang[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", pos1);
				GetEntPropVector(client, Prop_Data, "m_angRotation", ang);
				float Dimension_Loc[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", Dimension_Loc);
				ParticleEffectAt(Dimension_Loc, "eyeboss_death_vortex", 1.5);
				EmitSoundToAll(SOUND_ABILITY, client, SNDCHAN_STATIC, 70, _, 1.0);
				switch(GetRandomInt(1, 26))
				{
					case 1:
					{
						int entity = Npc_Create(EXPIDONSA_BENERA, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 2:
					{
						int entity = Npc_Create(EXPIDONSA_PENTAL, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 3:
					{
						int entity = Npc_Create(EXPIDONSA_DEFANDA, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 4:
					{
						int entity = Npc_Create(EXPIDONSA_SELFAM_IRE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 5:
					{
						int entity = Npc_Create(EXPIDONSA_VAUSMAGICA, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.20);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 6:
					{
						int entity = Npc_Create(EXPIDONSA_PISTOLEER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*12.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 7:
					{
						int entity = Npc_Create(EXPIDONSA_DIVERSIONISTICO, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 8:
					{
						int entity = Npc_Create(EXPIDONSA_RIFALMANU, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*16.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 9:
					{
						int entity = Npc_Create(EXPIDONSA_SICCERINO, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 10:
					{
						int entity = Npc_Create(EXPIDONSA_SOLDINE_PROTOTYPE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*24.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 11:
					{
						int entity = Npc_Create(EXPIDONSA_PROTECTA, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 12:
					{
						int entity = Npc_Create(EXPIDONSA_EGABUNAR, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 13:
					{
						int entity = Npc_Create(EXPIDONSA_ENEGAKAPUS, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*14.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.30 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 14:
					{
						int entity = Npc_Create(EXPIDONSA_VAUSTECHICUS, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 15:
					{
						int entity = Npc_Create(EXPIDONSA_HEAVYPUNUEL, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*27.0);
							maxhealth = RoundFloat(float(maxhealth) * 1.1);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 16:
					{
						int entity = Npc_Create(EXPIDONSA_SNIPONEER, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0) * 15.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 17:
					{
						int entity = Npc_Create(EXPIDONSA_DUALREA, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0)*19.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 18:
					{
						int entity = Npc_Create(EXPIDONSA_GUARDUS, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0) * 27.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 19:
					{
						int entity = Npc_Create(EXPIDONSA_MINIGUNASSISA, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0) * 21.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 20:
					{
						int entity = Npc_Create(EXPIDONSA_IGNITUS, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0) * 26.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 21:
					{
						int entity = Npc_Create(EXPIDONSA_HELENA, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0) * 14.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.22);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 22:
					{
						int entity = Npc_Create(EXPIDONSA_ERASUS, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0) * 21.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 23:
					{
						int entity = Npc_Create(EXPIDONSA_GIANTTANKUS, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0) * 27.5);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 24:
					{
						int entity = Npc_Create(EXPIDONSA_SPEEDUSADIVUS, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0) * 17.0);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.31 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 25:
					{
						int entity = Npc_Create(EXPIDONSA_SOLDINE, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0) * 30);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.4 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					case 26:
					{
						int entity = Npc_Create(EXPIDONSA_SEARGENTIDEAL, client, pos1, ang, TFTeam_Red);
						if(entity > MaxClients)
						{
							int maxhealth = RoundFloat(Attributes_Get(weapon, 410, 1.0) * 31);
							SetEntProp(entity, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
							
							fl_Extra_Damage[entity] = (RoundFloat(Attributes_Get(weapon, 410, 1.0)) * 0.32 * WEAPON_EXTRA_DAMAGE_MODIF);
							CreateTimer(45.0, Dimension_KillNPC, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
							i_NpcOverrideAttacker[entity] = EntIndexToEntRef(client);
						}
					}
					default: //This should not happen
					{
						ShowSyncHudText(client,  SyncHud_Notifaction, "Summon Failed. Scream at devs");//none
					}
				}
				
				int spellbook = SpawnWeapon_Special(client, "tf_weapon_spellbook", 1070, 100, 5, "13 ; 9999");
				Attributes_Set(client, 178, 0.25 * WEAPON_EXTRA_DAMAGE_MODIF);
				FakeClientCommand(client, "use tf_weapon_spellbook");
				Attributes_Set(client, 698, 1.0);
				Delete_Flame[client] = true;
				
				SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
				SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 0);	
					
				Mana_Regen_Delay[client] = GetGameTime() + 1.0;
				Mana_Hud_Delay[client] = 0.0;
				
				Current_Mana[client] -= mana_cost;
					
				delay_hud[client] = 0.0;

				how_many_times_swinged[client] = 0;
			}
			else
			{
				ClientCommand(client, "playgamesound items/medshotno1.wav");
				SetDefaultHudPosition(client);
				SetGlobalTransTarget(client);
				ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
			}
		}
		else
		{
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetDefaultHudPosition(client);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "Not enough Charges");
		}
	}
}

public Action Dimension_KillNPC(Handle timer, int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(IsValidEntity(entity) && !b_NpcHasDied[entity])
	{
		SmiteNpcToDeath(entity);
	}
	
	return Plugin_Stop;
}



void Npc_OnTakeDamage_DimensionalRipper(int attacker, int victim)
{
	/*
		++ add charge code xd
	*/
	if(how_many_times_swinged[attacker] <= MAX_DIMENSION_CHARGE)
	{
		how_many_times_swinged[attacker] += 1;
	}
	if(b_thisNpcIsARaid[victim])
	{
		how_many_times_swinged[attacker] += 1;
	}
}