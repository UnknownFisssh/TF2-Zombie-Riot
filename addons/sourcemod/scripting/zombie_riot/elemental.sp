#pragma semicolon 1
#pragma newdecls required

// TODO: enum list of elements instead of each one being it's own variable

enum
{
	Element_Nervous,
	Element_Chaos,
	Element_Cyro,
	Element_Necrosis,
	Element_Void,

	Element_MAX
}

static const char ElementName[][] =
{
	"AC",
	"CH",
	"CY",
	"NE",
	"VO"
};

static float LastTime[MAXENTITIES];
static int LastElement[MAXENTITIES];
static int ElementDamage[MAXENTITIES][Element_MAX];

// OnEntityCreated
void Elemental_ClearDamage(int entity)
{
	LastTime[entity] = 0.0;

	for(int i; i < Element_MAX; i++)
	{
		ElementDamage[entity][i] = 0;
	}
}

stock bool Elemental_HasDamage(int entity)
{
	for(int i; i < Element_MAX; i++)
	{
		if(ElementDamage[entity][i])
			return true;
	}
	
	return false;
}

stock void Elemental_RemoveDamage(int entity, int amount)
{
	for(int i; i < Element_MAX; i++)
	{
		if(ElementDamage[entity][i] > 0)
		{
			ElementDamage[entity][i] -= amount;
			if(ElementDamage[entity][i] < 0)
				ElementDamage[entity][i] = 0;
		}
	}
}

static int TriggerDamage(int entity, int type)
{
	if(entity <= MaxClients)
		return MaxArmorCalculation(Armor_Level[entity], entity, 1.0);
	

	float divide = 3.0;

	switch(type)
	{
		case Element_Necrosis:
		{
			if(GetTeam(entity) == TFTeam_Red)
				return 1000;
			
			if(b_thisNpcIsARaid[entity])
				return 50000;
			
			return b_thisNpcIsABoss[entity] ? 25000 : 12500;
		}
		case Element_Cyro:
		{
			divide = 4.0;
		}
		case Element_Void:
		{
			divide = 2.0;
		}
	}

	if(Citizen_IsIt(entity))
		return view_as<Citizen>(entity).m_iGunValue / 20;

	//also works against superbosses.
	if(b_thisNpcIsARaid[entity] || EntRefToEntIndex(RaidBossActive) == entity)
	{
		divide *= (5.2 * MultiGlobalHighHealthBoss); //Reduce way further so its good against raids.
	}
	else if(b_thisNpcIsABoss[entity])
	{
		divide *= (3.0 * MultiGlobalHealth); //Reduce way further so its good against bosses.
	}
	else if (b_IsGiant[entity])
	{
		divide *= 2.0;
	}

	return RoundToCeil((float(ReturnEntityMaxHealth(entity)) / fl_GibVulnerablity[entity]) / divide);
}

bool Elemental_HurtHud(int entity, char Debuff_Adder[64])
{
	float gameTime = GetGameTime();
	if(f_ArmorCurrosionImmunity[entity] > gameTime)
	{
		// An elemental effect is in cooldown
		Format(Debuff_Adder, sizeof(Debuff_Adder), "<%s %ds>", ElementName[LastElement[entity]], RoundToCeil(f_ArmorCurrosionImmunity[entity] - gameTime));
		return true;
	}
	
	// Don't display anything after 5 seconds of nothing
	if((LastTime[entity] + 5.0) < gameTime && GetTeam(entity) != TFTeam_Red)
		return false;
	
	// Find the element that's closest to trigger
	int low = -1;
	int lowHealth = 1000000;
	for(int i; i < Element_MAX; i++)
	{
		if(ElementDamage[entity][i] > 0)
		{
			int health = TriggerDamage(entity, i) - ElementDamage[entity][i];
			if(health < lowHealth)
			{
				low = i;
				lowHealth = health;
			}
		}
	}

	// Nothing found
	if(low == -1)
		return false;
	
	// <CY 50%>
	Format(Debuff_Adder, sizeof(Debuff_Adder), "<%s %d%%>", ElementName[low], ElementDamage[entity][low] * 100 /TriggerDamage(entity, low));
	return true;
}

void Elemental_AddNervousDamage(int victim, int attacker, int damagebase, bool sound = true, bool ignoreArmor = false)
{
	int damage = RoundFloat(damagebase * fl_Extra_Damage[attacker]);
	if(victim <= MaxClients && victim > 0)
	{
		Armor_DebuffType[victim] = 1;
		if(f_ArmorCurrosionImmunity[victim] < GetGameTime() && (ignoreArmor || Armor_Charge[victim] < 1))
		{
			if(i_HealthBeforeSuit[victim] > 0)
			{
				SDKHooks_TakeDamage(victim, attacker, attacker, damagebase * 4.0, DMG_SLASH|DMG_PREVENT_PHYSICS_FORCE);
			}
			else
			{
				damage -= RoundToNearest(Attributes_GetOnPlayer(victim, Attrib_ElementalDef, false));
				if(damage < 1)
					damage = 1;
				
				Armor_Charge[victim] -= damage;
				if(Armor_Charge[victim] < (-MaxArmorCalculation(Armor_Level[victim], victim, 1.0)))
				{
					Armor_Charge[victim] = 0;
					f_ArmorCurrosionImmunity[victim] = GetGameTime() + 5.0;

					TF2_StunPlayer(victim, b_BobsTrueFear[victim] ? 3.0 : 5.0, 0.9, TF_STUNFLAG_SLOWDOWN);

					DealTruedamageToEnemy(0, victim, b_BobsTrueFear[victim] ? 400.0 : 500.0);
				}
			}
			
			if(sound || !Armor_Charge[victim])
				ClientCommand(victim, "playgamesound player/crit_received%d.wav", (GetURandomInt() % 3) + 1);
		}
	}
	else if(!b_NpcHasDied[victim])	// NPCs
	{
		if(f_ArmorCurrosionImmunity[victim] < GetGameTime())
		{
			int trigger;
			if(Citizen_IsIt(victim))	// Rebels
			{
				if(!ignoreArmor)
				{
					// Has "armor" at 75% HP
					if(GetEntProp(victim, Prop_Data, "m_iHealth") > (ReturnEntityMaxHealth(victim) * 3 / 4))
						return;
				}

			}
			
			trigger = TriggerDamage(victim, Element_Nervous);

			LastTime[victim] = GetGameTime();
			LastElement[victim] = Element_Nervous;
			ElementDamage[victim][Element_Nervous] += damage;
			if(ElementDamage[victim][Element_Nervous] > trigger)
			{
				ElementDamage[victim][Element_Nervous] = 0;
				f_ArmorCurrosionImmunity[victim] = GetGameTime() + 5.0;

				if(GetTeam(victim) == TFTeam_Red)
				{
					FreezeNpcInTime(victim, 3.0);
					SDKHooks_TakeDamage(victim, attacker, attacker, 400.0, DMG_SLASH|DMG_PREVENT_PHYSICS_FORCE);
				}
				else
				{
					FreezeNpcInTime(victim, b_thisNpcIsARaid[victim] ? 3.0 : 5.0);
					SDKHooks_TakeDamage(victim, attacker, attacker, 1000.0, DMG_SLASH|DMG_PREVENT_PHYSICS_FORCE);
				}
			}
		}
	}
	else if(i_IsABuilding[victim])	// Buildings
	{
		int health = Object_GetRepairHealth(victim);
		if(health < 1 || ignoreArmor)
		{
			DealTruedamageToEnemy(0, victim, damage * 100.0);
		}
	}
}

void Projectile_DealElementalDamage(int victim, int attacker, float Scale = 1.0)
{
	if(i_ChaosArrowAmount[attacker] > 0)
	{
		Elemental_AddChaosDamage(victim, attacker, RoundToCeil(float(i_ChaosArrowAmount[attacker]) * Scale));
	}
	if(i_VoidArrowAmount[attacker] > 0)
	{
		Elemental_AddVoidDamage(victim, attacker, RoundToCeil(float(i_VoidArrowAmount[attacker]) * Scale));
	}
	if(i_NervousImpairmentArrowAmount[attacker] > 0)
	{
#if defined ZR
		Elemental_AddNervousDamage(victim, attacker, RoundToCeil(float(i_NervousImpairmentArrowAmount[attacker]) * Scale));
#endif
	}	
}
void Elemental_AddChaosDamage(int victim, int attacker, int damagebase, bool sound = true, bool ignoreArmor = false)
{
	int damage = RoundFloat(damagebase * fl_Extra_Damage[attacker]);
	if(victim <= MaxClients)
	{
		Armor_DebuffType[victim] = 2;
		if((b_thisNpcIsARaid[attacker] || f_ArmorCurrosionImmunity[victim] < GetGameTime()) && (ignoreArmor || Armor_Charge[victim] < 1))
		{
			if(i_HealthBeforeSuit[victim] > 0)
			{
				SDKHooks_TakeDamage(victim, attacker, attacker, damagebase * 4.0, DMG_SLASH|DMG_PREVENT_PHYSICS_FORCE);
			}
			else
			{
				damage -= RoundToNearest(Attributes_GetOnPlayer(victim, Attrib_ElementalDef, false));
				if(damage < 1)
					damage = 1;
				
				Armor_Charge[victim] -= damage;
				if(Armor_Charge[victim] < (-MaxArmorCalculation(Armor_Level[victim], victim, 1.0)))
				{
					Armor_Charge[victim] = 0;
					float ProjectileLoc[3];
					GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", ProjectileLoc);
					ProjectileLoc[2] += 45.0;

					//if server starts crashing out of nowhere, change how to change teamnum
					EmitSoundToAll("mvm/mvm_tank_explode.wav", victim, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
					ParticleEffectAt(ProjectileLoc, "hightower_explosion", 1.0);
					b_NpcIsTeamkiller[victim] = true;
					Explode_Logic_Custom(0.0,
					attacker,
					attacker,
					-1,
					ProjectileLoc,
					250.0,
					_,
					_,
					true,
					99,
					false,
					_,
					SakratanGroupDebuff);
					b_NpcIsTeamkiller[victim] = false;
					f_ArmorCurrosionImmunity[victim] = GetGameTime() + 10.0;
				//	Explode_Logic_Custom(fl_rocket_particle_dmg[entity] , inflictor , owner , -1 , ProjectileLoc , fl_rocket_particle_radius[entity] , _ , _ , b_rocket_particle_from_blue_npc[entity]);	//acts like a rocket
				}
			}
			
			if(sound || !Armor_Charge[victim])
				ClientCommand(victim, "playgamesound friends/friend_online.wav");
		}
	}
	else if(!b_NpcHasDied[victim])	// NPCs
	{
		if(f_ArmorCurrosionImmunity[victim] < GetGameTime())
		{
			int trigger;
			if(Citizen_IsIt(victim))	// Rebels
			{
				if(!ignoreArmor)
				{
					// Has "armor" at 75% HP
					if(GetEntProp(victim, Prop_Data, "m_iHealth") > (ReturnEntityMaxHealth(victim) * 3 / 4))
						return;
				}
			}
			
			trigger = TriggerDamage(victim, Element_Chaos);

			LastTime[victim] = GetGameTime();
			LastElement[victim] = Element_Chaos;
			ElementDamage[victim][Element_Chaos] += damage;
			if(ElementDamage[victim][Element_Chaos] > trigger)
			{
				ElementDamage[victim][Element_Chaos] = 0;
				f_ArmorCurrosionImmunity[victim] = GetGameTime() + 5.0;

				IncreaceEntityDamageTakenBy(victim, 1.30, 10.0);
				NPC_Ignite(victim, attacker, 10.0, -1);

				float burn = GetTeam(victim) == TFTeam_Red ? 10.0 : 25.0;
				if(BurnDamage[victim] < burn)
					BurnDamage[victim] = burn;
			}
		}
	}
	else if(i_IsABuilding[victim])	// Buildings
	{
		IncreaceEntityDamageTakenBy(victim, (damage * 0.001), 5.0, true);
	}
}


void Elemental_AddVoidDamage(int victim, int attacker, int damagebase, bool sound = true, bool ignoreArmor = false, bool VoidWeaponDo = false)
{
	if(view_as<CClotBody>(victim).m_iBleedType == BLEEDTYPE_VOID || (victim <= MaxClients && ClientPossesesVoidBlade(victim)))
		return;
	//cant void other voids!


	int damage = RoundFloat(damagebase * fl_Extra_Damage[attacker]);
	if(victim <= MaxClients)
	{
		Armor_DebuffType[victim] = 3;
		if((b_thisNpcIsARaid[attacker] || f_ArmorCurrosionImmunity[victim] < GetGameTime()) && (ignoreArmor || Armor_Charge[victim] < 1))
		{
			if(i_HealthBeforeSuit[victim] > 0)
			{
				SDKHooks_TakeDamage(victim, attacker, attacker, damagebase * 4.0, DMG_SLASH|DMG_PREVENT_PHYSICS_FORCE);
			}
			else
			{
				damage -= RoundToNearest(Attributes_GetOnPlayer(victim, Attrib_ElementalDef, false));
				if(damage < 1)
					damage = 1;
				
				Armor_Charge[victim] -= damage;
				if(Armor_Charge[victim] < (-MaxArmorCalculation(Armor_Level[victim], victim, 1.0)))
				{
					Armor_Charge[victim] = 0;
					float ProjectileLoc[3];
					GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", ProjectileLoc);
					ProjectileLoc[2] += 5.0;
					VoidArea_SpawnNethersea(ProjectileLoc, VoidWeaponDo);
					FramingInfestorSpread(victim);
					EmitSoundToAll("npc/scanner/cbot_discharge1.wav", victim, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
					f_ArmorCurrosionImmunity[victim] = GetGameTime() + 5.0;
					//Do code for void spread
				}
			}
			
			if(sound || !Armor_Charge[victim])
				ClientCommand(victim, "playgamesound npc/scanner/cbot_servoscared.wav ; playgamesound npc/scanner/cbot_servoscared.wav");
		}
	}
	else if(!b_NpcHasDied[victim])	// NPCs
	{
		if(f_ArmorCurrosionImmunity[victim] < GetGameTime())
		{
			int trigger;
			if(Citizen_IsIt(victim))	// Rebels
			{
				if(!ignoreArmor)
				{
					// Has "armor" at 75% HP
					if(GetEntProp(victim, Prop_Data, "m_iHealth") > (ReturnEntityMaxHealth(victim) * 3 / 4))
						return;
				}

			}
			
			trigger = TriggerDamage(victim, Element_Void);

			LastTime[victim] = GetGameTime();
			LastElement[victim] = Element_Void;
			ElementDamage[victim][Element_Void] += damage;
			if(ElementDamage[victim][Element_Void] > trigger)
			{
				ElementDamage[victim][Element_Void] = 0;
				f_ArmorCurrosionImmunity[victim] = GetGameTime() + 5.0;
				float ProjectileLoc[3];
				GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", ProjectileLoc);
				ProjectileLoc[2] += 5.0;
				EmitSoundToAll("npc/scanner/cbot_discharge1.wav", victim, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
				VoidArea_SpawnNethersea(ProjectileLoc, VoidWeaponDo);
				//do not spread.
				FramingInfestorSpread(victim);
			}
		}
	}
	else if(i_IsABuilding[victim])	// Buildings
	{
		//removes repair of buildings.
		int Repair = GetEntProp(victim, Prop_Data, "m_iRepair");
		Repair -= (damage / 2);
		if(Repair <= 0)
			Repair = 0;

		SetEntProp(victim, Prop_Data, "m_iRepair", Repair);
	}
}

static void SakratanGroupDebuff(int entity, int victim, float damage, int weapon)
{
	if(entity == victim)
		return;

	if (GetTeam(victim) != GetTeam(entity))
		SakratanGroupDebuffInternal(victim);
		
}

static void SakratanGroupDebuffInternal(int victim)
{
	if(victim <= MaxClients && !b_BobsTrueFear[victim])
	{
		DealTruedamageToEnemy(0, victim, 250.0);
	}
	else
	{
		DealTruedamageToEnemy(0, victim, 200.0);
	}
	IncreaceEntityDamageTakenBy(victim, 1.30, 10.0);
}

void Elemental_AddCyroDamage(int victim, int attacker, int damagebase, int type)
{
	int damage = RoundFloat(damagebase * fl_Extra_Damage[attacker]);
	if(victim <= MaxClients)
	{
		// Cyro is treated as Chaos vs Players
		Elemental_AddChaosDamage(victim, attacker, damagebase, _, true);
	}
	else if(!b_NpcHasDied[victim])	// NPCs
	{
		if(f_ArmorCurrosionImmunity[victim] < GetGameTime())
		{
			int trigger = TriggerDamage(victim, Element_Cyro);

			LastTime[victim] = GetGameTime();
			LastElement[victim] = Element_Cyro;
			ElementDamage[victim][Element_Cyro] += damage;
			if(ElementDamage[victim][Element_Cyro] > trigger)
			{
				ElementDamage[victim][Element_Cyro] = 0;
				f_ArmorCurrosionImmunity[victim] = GetGameTime() + (9.5 + (type * 0.5));

				Cryo_FreezeZombie(victim, type);
			}
		}
	}
	else if(i_IsABuilding[victim])	// Buildings
	{
		IncreaceEntityDamageTakenBy(victim, (damage * 0.001), 5.0, true);
	}
}

void Elemental_AddNecrosisDamage(int victim, int attacker, int damagebase, int weapon = -1)
{
	int damage = RoundFloat(damagebase * fl_Extra_Damage[attacker]);
	if(victim <= MaxClients)
	{
		// No effect currently for Necrosis vs Players
	}
	else if(!b_NpcHasDied[victim])	// NPCs
	{
		if(f_ArmorCurrosionImmunity[victim] < GetGameTime())
		{
			int trigger = TriggerDamage(victim, Element_Necrosis);

			LastTime[victim] = GetGameTime();
			LastElement[victim] = Element_Necrosis;
			ElementDamage[victim][Element_Necrosis] += damage;
			if(ElementDamage[victim][Element_Necrosis] > trigger)
			{
				ElementDamage[victim][Element_Necrosis] = 0;
				f_ArmorCurrosionImmunity[victim] = GetGameTime() + 7.5;

				StartBleedingTimer(victim, attacker, 800.0, 15, weapon, DMG_SLASH, ZR_DAMAGE_NOAPPLYBUFFS_OR_DEBUFFS);
				
				float time = 7.5;
				if(b_thisNpcIsARaid[victim])
					time = 3.0;
				
				if(f_EnfeebleEffect[victim] < (GetGameTime() + time))
					f_EnfeebleEffect[victim] =  (GetGameTime() + time);
			}
		}
	}
}