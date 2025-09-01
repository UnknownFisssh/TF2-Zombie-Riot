#pragma semicolon 1
#pragma newdecls required

//Temperlas have their own armor corrosions
//Plague, soul debuffing, RnG Increaser
//Gambler's is obviously RnG Increaser but i have no intention to add this without the main waveset
//or.. well rework his fucking kit again.
//Rng Increaser would just be a simple buff on all his % on cash gain, attackspeed and damage bonus

static float fl_Gambler_Hud_Time = 0.0;
static int GamblerMultiUseColor[4];
static int i_AngerLines_OfNonExistance = 0;
static int i_Introduction_Anim_State = 0;
static float fl_DefaultSpeed = 300.0;

enum 
{
	GAMBLER_WEAPONGAIN_ANIM = 1,
	GAMBLER_INTRODUCTION = 2,
	GAMBLER_REINFORCEMENT_CALL
}

static const char g_JawBreaker[][] = {
	"misc/doomsday_missile_explosion.wav",
};
static const char g_WeaponSounds[][] = {
	"vo/spy_jeers02.mp3",
	"vo/spy_jeers04.mp3",
	"vo/spy_jeers05.mp3",
	"vo/spy_jeers06.mp3",//Bad sounds 0-3

	"vo/spy_cheers07.mp3",
	"vo/spy_dominationmedic01.mp3",//Good sounds 4-5

	"vo/taunts/spy/spy_taunt_cong_fun_05.mp3",
	"vo/taunts/spy/spy_taunt_flip_fun_07.mp3",//Jawbreaker 6-7
};

static const char g_SlotMachineSounds[][] = {
	"mvm/mvm_player_died.wav",//fail
	"mvm/mvm_bought_upgrade.wav",
};
static const char g_MiscSounds[][] = {
	"ui/rd_2base_alarm.wav",//RnD Tier Sound
};

static const char hzhh[][] = {
	"",
};
static const char g_DeathSounds[][] = {
	"misc/halloween/spell_lightning_ball_cast.wav",
};

public void TheGambler_OnMapStart_NPC()
{
	PrecacheSoundArray(g_JawBreaker);
	PrecacheSoundArray(g_WeaponSounds);
	PrecacheSoundArray(g_SlotMachineSounds);
	PrecacheSoundArray(g_DeathSounds);
	/*PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_IntroSound);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	PrecacheSoundArray(g_MeleeMissSounds);
	PrecacheSoundCustom("#zombiesurvival/temperals/raids/phlog_bgm.mp3");*/
	fl_Gambler_Hud_Time = 0.0;
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Gambler");//Devil himself.
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_the_gambler");
	strcopy(data.Icon, sizeof(data.Icon), "norm_headcrab_zombie");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Hidden;
	data.Func = ClotSummon;
	NPC_Add(data);
	i_AngerLines_OfNonExistance = 0;
	i_Introduction_Anim_State = 0;
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team, const char[] data)
{
	return TheTemperalGambler(vecPos, vecAng, team, data);
}

methodmap TheTemperalGambler < CClotBody
{
	property float fl_Ability_Usage
	{
		public get()							{ return fl_RangedSpecialDelay[this.index]; }
		public set(float TempValueForProperty) 	{ fl_RangedSpecialDelay[this.index] = TempValueForProperty; }
	}
	property float fl_Rolls_Timer
	{
		public get()							{ return fl_AngerDelay[this.index]; }
		public set(float TempValueForProperty) 	{ fl_AngerDelay[this.index] = TempValueForProperty; }
	}
	property float fl_SlotMachine_Cooldown
	{
		public get()							{ return fl_GrappleCooldown[this.index]; }
		public set(float TempValueForProperty) 	{ fl_GrappleCooldown[this.index] = TempValueForProperty; }
	}
	property float fl_Money
	{
		public get()							{ return fl_Dead_Ringer_Invis[this.index]; }
		public set(float TempValueForProperty) 	{ fl_Dead_Ringer_Invis[this.index] = TempValueForProperty; }
	}
	property float fl_CashGain_OnHit
	{
		public get()							{ return fl_Dead_Ringer[this.index]; }
		public set(float TempValueForProperty) 	{ fl_Dead_Ringer[this.index] = TempValueForProperty; }
	}
	property float fl_Weapons_Costs
	{
		public get()							{ return fl_AttackHappens_2[this.index]; }
		public set(float TempValueForProperty) 	{ fl_AttackHappens_2[this.index] = TempValueForProperty; }
	}
	property float fl_Damage_Bonus_BankRollers
	{
		public get()							{ return fl_NextRangedBarrage_Singular[this.index]; }
		public set(float TempValueForProperty) 	{ fl_NextRangedBarrage_Singular[this.index] = TempValueForProperty; }
	}
	property float fl_Speed_Bonus_BankRollers
	{
		public get()							{ return fl_NextRangedBarrage_Spam[this.index]; }
		public set(float TempValueForProperty) 	{ fl_NextRangedBarrage_Spam[this.index] = TempValueForProperty; }
	}
	property float fl_AttackSpeed_Bonus_BankRollers
	{
		public get()							{ return fl_InJump[this.index]; }
		public set(float TempValueForProperty) 	{ fl_InJump[this.index] = TempValueForProperty; }
	}
	property float fl_SlotMachine_Min
	{
		public get()							{ return fl_AttackHappensMinimum[this.index]; }
		public set(float TempValueForProperty) 	{ fl_AttackHappensMinimum[this.index] = TempValueForProperty; }
	}
	property float fl_SlotMachine_Max
	{
		public get()							{ return fl_AttackHappensMaximum[this.index]; }
		public set(float TempValueForProperty) 	{ fl_AttackHappensMaximum[this.index] = TempValueForProperty; }
	}
	property float fl_RnD_TierCost
	{
		public get()							{ return fl_XenoInfectedSpecialHurtTime[this.index]; }
		public set(float TempValueForProperty) 	{ fl_XenoInfectedSpecialHurtTime[this.index] = TempValueForProperty; }
	}
	property float fl_Weapons_Cooldown
	{
		public get()							{ return fl_Following_Master_Now[this.index]; }
		public set(float TempValueForProperty) 	{ fl_Following_Master_Now[this.index] = TempValueForProperty; }
	}
	property float fl_Weapons_Duration
	{
		public get()							{ return fl_JumpCooldown[this.index]; }
		public set(float TempValueForProperty) 	{ fl_JumpCooldown[this.index] = TempValueForProperty; }
	}
	property float fl_Damage_Intotal
	{
		public get()							{ return fl_NextChargeSpecialAttack[this.index]; }
		public set(float TempValueForProperty) 	{ fl_NextChargeSpecialAttack[this.index] = TempValueForProperty; }
	}
	property float fl_Speed_Intotal
	{
		public get()							{ return fl_Charge_Duration[this.index]; }
		public set(float TempValueForProperty) 	{ fl_Charge_Duration[this.index] = TempValueForProperty; }
	}
	property float fl_Jackpot_Timer
	{
		public get()							{ return fl_movedelay[this.index]; }
		public set(float TempValueForProperty) 	{ fl_movedelay[this.index] = TempValueForProperty; }
	}
	property bool b_AllowBuffsToWork
	{
		public get()							{ return b_XenoInfectedSpecialHurt[this.index]; }
		public set(bool TempValueForProperty) 	{ b_XenoInfectedSpecialHurt[this.index] = TempValueForProperty; }
	}
	//property bool b_
	//{
	//	public get()							{ return b_NextRangedBarrage_OnGoing[this.index]; }
	//	public set(bool TempValueForProperty) 	{ b_NextRangedBarrage_OnGoing[this.index] = TempValueForProperty; }
	//}
	property bool b_MaxCosmetics
	{
		public get()							{ return b_AttackHappenswillhappen[this.index]; }
		public set(bool TempValueForProperty) 	{ b_AttackHappenswillhappen[this.index] = TempValueForProperty; }
	}
	property int i_RnD_Tier
	{
		public get()							{ return i_TimesSummoned[this.index]; }
		public set(int TempValueForProperty) 	{ i_TimesSummoned[this.index] = TempValueForProperty; }
	}
	property int i_Stabbed
	{
		public get()							{ return i_AttacksTillMegahit[this.index]; }
		public set(int TempValueForProperty) 	{ i_AttacksTillMegahit[this.index] = TempValueForProperty; }
	}
	property int i_WeaponType
	{
		public get()							{ return i_OverlordComboAttack[this.index]; }
		public set(int TempValueForProperty) 	{ i_OverlordComboAttack[this.index] = TempValueForProperty; }
	}
	property int i_Animation_State
	{
		public get()							{ return i_MedkitAnnoyance[this.index]; }
		public set(int TempValueForProperty) 	{ i_MedkitAnnoyance[this.index] = TempValueForProperty; }
	}
	property float fl_Rollers_Effect_Time
	{
		public get()							{ return fl_JumpStartTime[this.index]; }
		public set(float TempValueForProperty) 	{ fl_JumpStartTime[this.index] = TempValueForProperty; }
	}
	property float fl_Max_Money
	{
		public get()							{ return fl_AbilityOrAttack[this.index][0]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][0] = TempValueForProperty; }
	}
	property float fl_Printing_Money
	{
		public get()							{ return fl_AbilityOrAttack[this.index][1]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][1] = TempValueForProperty; }
	}
	property float fl_Printing_Money_Time
	{
		public get()							{ return fl_AbilityOrAttack[this.index][2]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][2] = TempValueForProperty; }
	}
	property float fl_CashGain_OnHit_Timer
	{
		public get()							{ return fl_AbilityOrAttack[this.index][3]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][3] = TempValueForProperty; }
	}
	property float fl_Delay_AnimEffects
	{
		public get()							{ return fl_AbilityOrAttack[this.index][4]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][4] = TempValueForProperty; }
	}
	//property float fl_
	//{
	//	public get()							{ return fl_AbilityOrAttack[this.index][5]; }
	//	public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][5] = TempValueForProperty; }
	//}
	//property float fl_
	//{
	//	public get()							{ return fl_AbilityOrAttack[this.index][6]; }
	//	public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][6] = TempValueForProperty; }
	//}
	//property float fl_
	//{
	//	public get()							{ return fl_AbilityOrAttack[this.index][7]; }
	//	public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][7] = TempValueForProperty; }
	//}
	//property float fl_
	//{
	//	public get()							{ return fl_AbilityOrAttack[this.index][8]; }
	//	public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][8] = TempValueForProperty; }
	//}
	//property float fl_
	//{
	//	public get()							{ return fl_AbilityOrAttack[this.index][9]; }
	//	public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][9] = TempValueForProperty; }
	//}
	public bool SlotMachine(float gameTime)
	{
		PrintCenterTextAll("Min: %.3f | Max: %.3f", this.fl_SlotMachine_Min, this.fl_SlotMachine_Max);
		if(this.fl_SlotMachine_Cooldown >= gameTime)
		{
			return false;
		}

		float SlotMachineCashAmt = GetRandomFloat(this.fl_SlotMachine_Min, this.fl_SlotMachine_Max);
		if(SlotMachineCashAmt <= 1.00)
			CPrintToChatAll("{crimson}[Zombie Riot] {green}The Gambler lost {yellow}%i%% {green}of his cash.", 100 - RoundFloat(100 * SlotMachineCashAmt));
		else
			CPrintToChatAll("{crimson}[Zombie Riot] {green}The Gambler won {red}%i%% {green}of his cash.", -(100 - RoundFloat(100 * SlotMachineCashAmt)));
		this.fl_Money *= SlotMachineCashAmt;
		this.fl_SlotMachine_Cooldown = gameTime + 15.0;
		return true;
	}
	public void RnD_Tier_Gain_Stats()
	{//yes i hate this aswell, but yes..
		switch(this.i_RnD_Tier)
		{
			case -1://incase it fucked itself somehow? if so this is quacking bad
			{
				this.i_RnD_Tier = 0;
				this.RnD_Tier_Gain_Stats();
				CPrintToChatAll("[{crimson}WARNING{default}] {yellow}RnD TIER MANAGED TO BE ON {orange}-1 {red}EMERGENCY FIXXX");
			}
			case 0:
			{
				this.fl_SlotMachine_Min = 0.8;
				this.fl_SlotMachine_Max = 1.35;
				this.fl_CashGain_OnHit = 12.5;
				this.fl_Printing_Money = 0.5;
				this.fl_RnD_TierCost = 900.0;
				this.fl_Max_Money = 3000.0;
				this.fl_Weapons_Costs = 325.0;
			}
			case 1:
			{
				this.fl_SlotMachine_Min = 0.8;
				this.fl_SlotMachine_Max = 1.55;
				this.fl_CashGain_OnHit = 13.0;
				this.fl_Printing_Money = 1.5;
				this.fl_RnD_TierCost = 4000.0;
				this.fl_Max_Money = 4000.0;
				this.fl_Weapons_Costs = 525.0;
			}
			case 2:
			{
				this.fl_SlotMachine_Min = 0.8;
				this.fl_SlotMachine_Max = 1.79;
				this.fl_CashGain_OnHit = 13.5;
				this.fl_Printing_Money = 3.5;
				this.fl_RnD_TierCost = 5000.0;
				this.fl_Max_Money = 5000.0;
				this.fl_Weapons_Costs = 625.0;
			}
			case 3:
			{
				this.fl_SlotMachine_Min = 0.8;
				this.fl_SlotMachine_Max = 1.95;
				this.fl_CashGain_OnHit = 20.0;
				this.fl_Printing_Money = 5.0;
				this.fl_RnD_TierCost = 6000.0;
				this.fl_Max_Money = 6000.0;
				this.fl_Weapons_Costs = 825.0;
			}
			case 4:
			{
				this.fl_SlotMachine_Min = 0.8;
				this.fl_SlotMachine_Max = 2.15;
				this.fl_CashGain_OnHit = 30.0;
				this.fl_Printing_Money = 7.0;
				this.fl_RnD_TierCost = 9000.0;
				this.fl_Max_Money = 9000.0;
				this.fl_Weapons_Costs = 625.0;
			}
			case 5:
			{
				this.fl_SlotMachine_Min = 0.85;
				this.fl_SlotMachine_Max = 2.45;
				this.fl_CashGain_OnHit = 40.0;
				this.fl_Printing_Money = 9.0;
				this.fl_RnD_TierCost = 12000.0;
				this.fl_Max_Money = 12000.0;
				this.fl_Weapons_Costs = 2625.0;
			}
			default:
			{
				this.fl_SlotMachine_Min = 0.95;
				this.fl_SlotMachine_Max = 2.75;
				this.fl_CashGain_OnHit = 70.0;
				this.fl_Printing_Money = 13.0;
				this.fl_RnD_TierCost = 99999999.0;
				this.fl_Max_Money = 2500000.0;
				this.fl_Weapons_Costs = 4625.0;
			}
		}
	}
	
	public void GlobalCooldown(float cd)
	{//Easy way of making all stuff on cd, rather then well.. make a multi bools with some timers
		float gtaSa = GetGameTime(this.index);
		if(this.fl_Ability_Usage <= gtaSa)
		{
			this.fl_Ability_Usage = gtaSa + cd;
		}
		else
		{
			this.fl_Ability_Usage += cd;
		}

		if(this.fl_SlotMachine_Cooldown <= gtaSa)
		{
			this.fl_SlotMachine_Cooldown = gtaSa + cd;
		}
		else
		{
			this.fl_SlotMachine_Cooldown += cd;
		}

		if(this.fl_Rolls_Timer <= gtaSa)
		{
			this.fl_Rolls_Timer = gtaSa + cd;
		}
		else
		{
			this.fl_Rolls_Timer += cd;
		}
		if(this.fl_Weapons_Cooldown)//Don't put it in cd if it has no cd at all.
		{
			if(this.fl_Weapons_Cooldown <= gtaSa)
			{
				this.fl_Weapons_Cooldown = gtaSa + cd;
			}
			else
			{
				this.fl_Weapons_Cooldown += cd;
			}
		}
	}
	public void Gamblers_WeaponKit(bool revert = false)
	{
		if(IsValidEntity(this.m_iWearable1))
			RemoveEntity(this.m_iWearable1);

		char weaponname[255] = "", animation[255] = "";
		int skin = 1, rng = 0, anims = 0;
		bool gun = false;
		if(revert)
		{
			this.i_WeaponType = 0;
			weaponname = "models/weapons/c_models/c_ava_roseknife/c_ava_roseknife.mdl";
			this.fl_Weapons_Cooldown = GetGameTime(this.index) + 15.0;
		}
		else
		{
			int number = 2;
			switch(this.i_RnD_Tier)
			{
				case -1, 0:
					number = 2;
				case 1:
					number = 3;
				case 2:
					number = 4;
				case 3:
					number = 5;
				case 4:
					number = 6;
				case 5:
					number = 7;
				default:
					number = 8;
			}
			rng = GetURandomInt() % number;
			int rolltype = 0;
			//0 == medium
			//1 == good
			//-1 == horrible
			char weapongain[255] = "", buffer[255] = "", funnymsg2[255] = "";
			float dur = GetRandomFloat(6.0, 12.0);
			switch(rng)
			{
				case 0:{
					gun = true;
					anims = 2;
					rolltype = -1;
				}
				case 1:{
					weaponname = "models/weapons/c_models/c_big_mallet/c_big_mallet.mdl";
					switch(i_AngerLines_OfNonExistance)
					{
						case 0:
						{
							buffer = "{red}???{default}: Where the hell did you get this??";
							funnymsg2 = "{cyan}The Gambler{default}: I don't know. Ask this Endless pit of Inventory.";
						}
						case 1:
						{
							buffer = "{red}???{default}: I really wonder if you actually just tossed it in some day.";
							funnymsg2 = "{cyan}The Gambler{default}: ...";
						}
						case 2:
						{
							buffer = "{red}???{default}: You know what. Keep it i don't care anymore.";
						}
					}
					weapongain = "______";
					i_AngerLines_OfNonExistance++;
					rolltype = 1;
				}
				case 2:{
					weapongain = "Soul Absorber";//Simple yet deadly
					weaponname = "models/weapons/c_models/c_skullbat/c_skullbat.mdl";
					rolltype = 0;
				}
				case 3:{
					weapongain = "The Jawbreaker";
					rolltype = 1;
					this.i_WeaponType = 3;
					weaponname = "models/weapons/c_models/c_boxing_gloves/c_boxing_gloves.mdl";
				}
				case 4:
				{//Mini laser
					gun = true;
					weaponname = "models/workshop/weapons/c_models/c_invasion_pistol/c_invasion_pistol.mdl";
					anims = 2;
					rolltype = 0;
				}
				case 5:
				{
					weapongain = "Surprise Kamikaze";
					gun = false;
					anims = 2;
					rolltype = 0;
					this.i_WeaponType = 0;
				}
				case 6:
				{
					this.i_WeaponType = 4;
					weaponname = "models/weapons/c_models/c_ava_roseknife/c_ava_roseknife.mdl";
				}
				case 7:
				{
					weapongain = "Rail-Gun";
					gun = true;
					anims = 2;
					rolltype = 1;
				}
				case 8:
				{
					
				}
			}
			this.fl_Weapons_Duration = dur;
			if(buffer[0])
				CPrintToChatAll(buffer);
			if(funnymsg2[0])
				CPrintToChatAll(funnymsg2);
			if(weapongain[0])
			{
				char luckroll[255];
				switch(rolltype)
				{
					case -1:
						luckroll = "{green}";
					case 0:
						luckroll = "{orange}";
					case 1:
						luckroll = "{red}";
				}
				FormatEx(buffer, sizeof(buffer), "{crimson}[Zombie-Riot] {cyan}The Gambler {yellow}Gained %s%s{yellow} from his arsenal.", luckroll, weapongain);
				CPrintToChatAll(buffer);
			}
			this.m_fbGunout = gun;
		}
		switch(anims)
		{
			case 0:
				animation = "ACT_MP_RUN_MELEE";
			case 1:
				animation = "ACT_MP_RUN_BUILDING";
			case 2:
				animation = "ACT_MP_RUN_SECONDARY";
			case 3:
				animation = "ACT_MP_RUN_ITEM1";
		}

		int iActivity = this.LookupActivity(animation);
		if(iActivity > 0) this.StartActivity(iActivity);

		this.i_WeaponType = rng;
		this.m_fbGunout = gun;
		this.m_iWearable1 = this.EquipItem("weapon_bone", weaponname, "", skin);
	}
	public void Rollers_Cleanup(float gameTime)
	{
		if(this.fl_Rolls_Timer && this.fl_Rolls_Timer <= gameTime)
		{
			this.fl_Damage_Bonus_BankRollers = 0.0;
			this.fl_Speed_Bonus_BankRollers = 0.0;
			this.fl_AttackSpeed_Bonus_BankRollers = 0.0;
			this.fl_Rolls_Timer = 0.0;
		}
	}
	public void Gambler_Rollers(float gameTime)
	{
		if(this.fl_Rolls_Timer >= gameTime || !this.b_AllowBuffsToWork)
			return;
		float rollerscd = GetRandomFloat(5.0, 10.0);
		float cd = GetRandomFloat(8.0, 25.0) + rollerscd;
		this.fl_Rolls_Timer = gameTime + cd;
		this.fl_Rollers_Effect_Time = rollerscd;
		char buffs[255];
		FormatEx(buffs, sizeof(buffs), "");
		int chance = 4;

		float buffamt = GetRandomFloat(0.75, 1.2);
		this.fl_Damage_Bonus_BankRollers = (1.0 + buffamt);
		bool low = (buffamt <= 1.0);
		FormatEx(buffs, sizeof(buffs), "%s%sDamage Bonus %s by{default} %i%%", buffs, low ? "{green}" : "{orange}", low ? "decrease" : "increase", low ? (100 - RoundFloat(100 * buffamt)) : -(100 - RoundFloat(100 * buffamt)));

		if(GetURandomInt() % chance == GetURandomInt() % chance)
		{
			buffamt = GetRandomFloat(0.05, 0.2);
			this.fl_Speed_Bonus_BankRollers = (1.0 + buffamt);
			FormatEx(buffs, sizeof(buffs), "%s\n%sSpeed Bonus %s by{default} %i%%", buffs, low ? "{green}" : "{red}", low ? "decrease" : "increase", low ? (100 - RoundFloat(100 * buffamt)) : -(100 - RoundFloat(100 * buffamt)));
		}
		chance = 2;
		if(GetURandomInt() % chance == GetURandomInt() % chance)
		{
			buffamt = GetRandomFloat(1.05, 0.5);
			this.fl_AttackSpeed_Bonus_BankRollers = buffamt;
			low = (buffamt >= 1.0);
			FormatEx(buffs, sizeof(buffs), "%s\n%sAttack-Speed Bonus %s by{default} %i%%", buffs, low ? "{green}" : "{orange}", low ? "decrease" : "increase", low ? -(100 - RoundFloat(100 * buffamt)) : (100 - RoundFloat(100 * buffamt)));
		}
		
		CPrintToChatAll("[{crimson}Bank Rollers{default}] {yellow}The Gambler gained:");
		CPrintToChatAll("%s", buffs);

		this.GlobalCooldown(1.5);
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
	public void EmitHudNotification(bool zrhud = true, float time = 1.01)
	{//I'm sorry to say this, i am just worried with hud limitations so i am doing a new one entirely.
		float gta6 = GetGameTime();
		if(fl_Gambler_Hud_Time >= gta6)
		{
			return;
		}
		char text[256];
		FormatEx(text, sizeof(text), "[RnD Tier %i]", this.i_RnD_Tier);
		FormatEx(text, sizeof(text), "%s | %t |", text, "Gambler's Cash", this.fl_Money);
		if(this.fl_Damage_Bonus_BankRollers != 0.0)
		{//҉ ֍
			FormatEx(text, sizeof(text), "%s | [%s %.2f]", text, "ϡ", this.fl_Damage_Bonus_BankRollers);
		}
		if(this.fl_Speed_Bonus_BankRollers != 0.0)
		{//‼
			FormatEx(text, sizeof(text), "%s | [%s %.2f]", text, "»¹", this.fl_Speed_Bonus_BankRollers);
		}
		if(this.fl_AttackSpeed_Bonus_BankRollers != 0.0)
		{//ƛϟ
			FormatEx(text, sizeof(text), "%s | [%s %.2f]", text, "▲¹", this.fl_AttackSpeed_Bonus_BankRollers);
		}
		for(int client = 1; client <= MaxClients; client++)
		{
			if(!IsClientInGame(client))
			{
				continue;
			}
			float hudy = 0.33;
			if(DoesNpcHaveHudDebuffOrBuff(client, this.index))//this used to be not like this.., welp gotta call it per client now..
				hudy = 0.363;
			//SetHudTextParams(-1.0, hudy, 3.01, 0, 255, 20, 255);
			SetHudTextParams(-1.0, hudy, time, GamblerMultiUseColor[0], GamblerMultiUseColor[1], GamblerMultiUseColor[2], GamblerMultiUseColor[3]);
			SetGlobalTransTarget(client);
			if(zrhud)//Incase you wanna use this
				ShowSyncHudText(client, SyncHud_Notifaction, text);
			else
				ShowHudText(client, -1, text);
		}
		fl_Gambler_Hud_Time = gta6 + time;
	}
	public int Gambler_entitywearable(int wear = 1)
	{
		switch(wear)
		{
			case 1:
				return this.m_iWearable1;
			case 2:
				return this.m_iWearable2;
			case 3:
				return this.m_iWearable3;
			case 4:
				return this.m_iWearable4;
			case 5:
				return this.m_iWearable5;
			case 6:
				return this.m_iWearable6;
			case 7:
				return this.m_iWearable7;
		}
		return -1;
	}
	public void Gambler_RemoveAllCosmetics()
	{
		for(int i = 2; i <= 7; i++)
		{
			int wear = this.Gambler_entitywearable(i);
			if(IsValidEntity(wear))
			{
				RemoveEntity(wear);
			}
		}
	}
	public void Gambler_Cosmetics()
	{
		this.Gambler_RemoveAllCosmetics();
		
		int skin = 1;//23;
		//if(b_IsAlliedNpc[this.index])
		//	skin = 0;
		float pos[3], ang[3];
		this.GetAttachment("head", pos, ang);
		
		switch(this.i_RnD_Tier)
		{
			case -1, 0:
			{
				this.m_iWearable2 = this.EquipItem("partyhat", "models/player/items/spy/spy_gang_cap.mdl", "", skin);

				this.m_iWearable3 = this.EquipItem("partyhat", "models/player/items/spy/summer_shades.mdl", "", skin);
			}
			case 1:
			{
				this.m_iWearable2 = this.EquipItem("partyhat", "models/player/items/spy/spy_gang_cap.mdl", "", skin);
				
				this.m_iWearable3 = this.EquipItem("partyhat", "models/player/items/spy/spy_openjacket.mdl", "", skin);
				
				this.m_iWearable4 = this.EquipItem("partyhat", "models/player/items/spy/spy_spats.mdl", "", skin);
				
				this.m_iWearable5 = this.EquipItem("partyhat", "models/workshop/player/items/all_class/jogon/jogon_spy.mdl", "", skin);
				
				this.m_iWearable6 = this.EquipItem("partyhat", "models/player/items/spy/summer_shades.mdl", "", skin);
			}
			case 2:
			{
				this.m_iWearable2 = this.EquipItem("partyhat", "models/player/items/spy/spy_gang_cap.mdl", "", skin);
				
				this.m_iWearable3 = this.EquipItem("partyhat", "models/workshop/player/items/spy/short2014_spy_ascot_vest/short2014_spy_ascot_vest.mdl", "", skin);
				
				this.m_iWearable4 = this.EquipItem("partyhat", "models/player/items/spy/spy_spats.mdl", "", skin);
				
				this.m_iWearable5 = this.EquipItem("partyhat", "models/workshop/player/items/all_class/jogon/jogon_spy.mdl", "", skin);
				
				this.m_iWearable6 = this.EquipItem("partyhat", "models/player/items/spy/summer_shades.mdl", "", skin);
				
				this.m_iWearable7 = ParticleEffectAt_Parent(pos, "unusual_orbit_cash", this.index, "head", {0.0, 0.0, -10.0});
			}
			case 3:
			{
				this.m_iWearable2 = this.EquipItem("partyhat", "models/player/items/spy/spy_gang_cap.mdl", "", skin);
				
				this.m_iWearable3 = this.EquipItem("partyhat", "models/workshop/player/items/spy/short2014_spy_ascot_vest/short2014_spy_ascot_vest.mdl", "", skin);
				
				this.m_iWearable4 = this.EquipItem("partyhat", "models/player/items/spy/spy_spats.mdl", "", skin);
				
				this.m_iWearable5 = this.EquipItem("partyhat", "models/workshop/player/items/all_class/jogon/jogon_spy.mdl", "", skin);
				
				this.m_iWearable6 = this.EquipItem("partyhat", "models/player/items/spy/summer_shades.mdl", "", skin);
				
				this.m_iWearable7 = ParticleEffectAt_Parent(pos, "unusual_crisp_spotlights", this.index, "head", {0.0, 0.0, -10.0});
			}
			default:
			{
				this.m_iWearable2 = this.EquipItem("partyhat", "models/workshop/player/items/spy/jul13_harmburg/jul13_harmburg.mdl", "", skin);
				
				this.m_iWearable3 = this.EquipItem("partyhat", "models/workshop/player/items/spy/sept2014_lady_killer/sept2014_lady_killer.mdl", "", skin);
				
				this.m_iWearable4 = this.EquipItem("partyhat", "models/player/items/spy/spy_spats.mdl", "", skin);
				
				this.m_iWearable5 = this.EquipItem("partyhat", "models/workshop/player/items/all_class/jogon/jogon_spy.mdl", "", skin);
				
				this.m_iWearable6 = this.EquipItem("partyhat", "models/player/items/spy/summer_shades.mdl", "", skin);
				
				this.m_iWearable7 = ParticleEffectAt_Parent(pos, "unusual_storm_spooky", this.index, "head", {0.0, 0.0, -10.0});
				this.b_MaxCosmetics = true;
			}
		}
	}
	public void RnD_Tier_Up()
	{
		if(this.i_RnD_Tier <= 5)//tier 6 is max
		{
			if(this.fl_Money >= this.fl_RnD_TierCost)
			{
				this.fl_Money -= this.fl_RnD_TierCost;
				this.i_RnD_Tier++;
				this.Gambler_Cosmetics();
				this.RnD_Tier_Gain_Stats();
			}
		}
	}
	public void AnimChanger(char anim[255] = "", float rate = 9999.0, float cycle = 9999.0, bool walking = true)
	{
		this.m_bisWalking = walking;
		
		if(anim[0])
		{
			this.AddActivityViaSequence(anim);
		}
		
		if(rate != 9999.0)
			this.SetPlaybackRate(rate);
		
		if(cycle != 9999.0)
			this.SetCycle(cycle);
	}
	public void ClearanceHelp(bool off = false)
	{
		if(!off)
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
	public void Gambler_BuffsApply(float gameTime)
	{
		float TotalArmor = 1.0;

		if(this.m_flDoingAnimation && this.m_flDoingAnimation > gameTime)
		{
			TotalArmor *= 0.5;
		}
		
		fl_TotalArmor[this.index] = TotalArmor;

		if(!this.b_AllowBuffsToWork)
		{
			return;
		}

		float extradmg = this.fl_Damage_Intotal, extraspeed = this.fl_Speed_Intotal;
		if(this.fl_Damage_Bonus_BankRollers != 0.0)
		{
			extradmg *= this.fl_Damage_Bonus_BankRollers;
		}
		if(this.fl_Speed_Bonus_BankRollers != 0.0)
		{
			extraspeed *= this.fl_Speed_Bonus_BankRollers;
		}

		fl_Extra_Damage[this.index] = extradmg;
		fl_Extra_Speed[this.index] = extraspeed;
	}
	//public void PlayIdleSound() {
	//	if(this.m_flNextIdleSound > GetGameTime(this.index))
	//		return;
	//	EmitSoundToAll(g_IdleSounds[GetRandomInt(0, sizeof(g_IdleSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 90);
	//	this.m_flNextIdleSound = GetGameTime(this.index) + GetRandomFloat(3.0, 6.0);
	//}
	//public void PlayIntro() {
	//	EmitSoundToAll(g_IntroSound[GetRandomInt(0, sizeof(g_IntroSound) - 1)], _, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME-0.2, 90);
	//	this.m_flNextIdleSound = GetGameTime(this.index) + 8.0;
	//}
	//public void PlayHurtSound() {
	//	if(this.m_flNextHurtSound > GetGameTime(this.index))
	//		return;
	//		
	//	this.m_flNextHurtSound = GetGameTime(this.index) + 0.4;
	//	
	//	EmitSoundToAll(g_HurtSounds[GetRandomInt(0, sizeof(g_HurtSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 90);
	//}
	//public void PlayDeathSound() {
	//	EmitSoundToAll(g_DeathSounds[GetRandomInt(0, sizeof(g_DeathSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 90);
	//}
	//public void PlayMeleeSound() {
	//	EmitSoundToAll(g_MeleeAttackSounds[GetRandomInt(0, sizeof(g_MeleeAttackSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 90);
	//}
	//public void PlayMeleeHitSound() {
	//	EmitSoundToAll(g_MeleeHitSounds[GetRandomInt(0, sizeof(g_MeleeHitSounds) - 1)], this.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 90);
	//}
	//public void PlayMeleeMissSound() {
	//	EmitSoundToAll(g_MeleeMissSounds[GetRandomInt(0, sizeof(g_MeleeMissSounds) - 1)], this.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 90);
	//}

	public TheTemperalGambler(float vecPos[3], float vecAng[3], int ally, const char[] data)
	{
		TheTemperalGambler npc = view_as<TheTemperalGambler>(CClotBody(vecPos, vecAng, "models/player/spy.mdl", "1.35", "30000", ally, false, true, true, true));
		
		i_NpcWeight[npc.index] = 5;
		
		FormatEx(c_HeadPlaceAttachmentGibName[npc.index], sizeof(c_HeadPlaceAttachmentGibName[]), "head");

		int iActivity = npc.LookupActivity("ACT_MP_RUN_MELEE");
		if(iActivity > 0) npc.StartActivity(iActivity);

		npc.m_fbGunout = false;
		
		bool clone = StrContains(data, "clone") != -1;
		npc.m_bFUCKYOU = clone ? true : false;
		npc.m_bFUCKYOU_move_anim = clone ? true : false;

		npc.m_flNextMeleeAttack = 0.0;
		npc.fl_Ability_Usage = 0.0;
		npc.fl_Rolls_Timer = 0.0;
		
		npc.m_flDoingAnimation = 0.0;
		npc.fl_Damage_Intotal = 1.0;
		npc.fl_Speed_Intotal = 1.0;
		npc.fl_Jackpot_Timer = 0.0;
		//npc.i_Hit = 0;
		//npc.b_ReturnWalk = false;
		//npc.b_Lifelossed = false;

		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_GIANT;	
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		npc.m_bDissapearOnDeath = true;
		npc.b_AllowBuffsToWork = false;
		npc.i_Stabbed = 0;
		//npc.i_AngerLines_OfNonExistance = 0;
		i_Introduction_Anim_State = 0;
		fl_Gambler_Hud_Time = 0.30;
		
		npc.i_Animation_State = 0;
		npc.i_RnD_Tier = 0;
		bool intro = StrContains(data, "Intro", true) != -1;
		if(GetTeam(npc.index) != TFTeam_Red)
		{
			//b_NameNoTranslation[npc.index] = true;
			if(!clone)
			{
				bool notime = (Waves_InFreeplay() || StrContains(data, "worthless") != -1 || StrContains(data, "easymode") != -1);
				RaidBossStatus Raid;
				Raid.israid = true; //If raid true, If superboss false
				Raid.allow_builings = true;
				Raid.Reduction_45 = 0.15;
				Raid.Reduction_60 = 0.3;
				Raid.Reduction_Last = 0.4;
				Raid.RaidTime = notime ? 99999.0 : 300.0;
				
				//If you want to check if there is already a raid, and want to add args for that !Raid.Setup(true, npc);
				//viceversa
				if(Raid.Setup(true, npc, data))//We are the raid!, if not use else or Check()
				{
					if(StrContains(data, "MaxTier") != -1)//for shits an giggles
					{
						npc.i_RnD_Tier = 6;
					}
					//add additional things
					//npc.m_iWearable1 = TF2_CreateGlow_White("models/player/spy.mdl", npc.index, 1.35);
					//if(IsValidEntity(npc.m_iWearable1))
					//{
					//	SetEntProp(npc.m_iWearable1, Prop_Send, "m_bGlowEnabled", false);
					//	SetEntityRenderMode(npc.m_iWearable1, RENDER_ENVIRONMENTAL);
					//	//Cannot be used on the actual npc. Reason is, for whatever reason fire removes it.
					//	Start_TE_Body_Effect(npc.m_iWearable1, "utaunt_storm_parent_o");
					//	npc.Anger = true;
					//}
					//else
					//{
					//	//Even tho i don't wanna force it on him, no choice if it fails to spawn.
					//	//even then fire exists and removes this entirely.. HELP
					//	Start_TE_Body_Effect(npc.index, "utaunt_storm_parent_o");
					//}
					//npc.m_iHealthBar = 2;
					//b_NpcUnableToDie[npc.index] = true;
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
		}
		if(intro)
		{
			npc.i_Animation_State = GAMBLER_INTRODUCTION;
			npc.m_flDoingAnimation = 99999.0;
			//I just want him to be near players.. man
			int numb = TeleportDiversioToRandLocation(npc.index, true, 150.0, 50.0);
			if(numb == 2)
			{
				numb = TeleportDiversioToRandLocation(npc.index, true, 250.0, 150.0);
				if(numb == 2)
				{
					numb = TeleportDiversioToRandLocation(npc.index, true, 450.0, 250.0);
					if(numb == 2)
					{
						numb = TeleportDiversioToRandLocation(npc.index, true, 850.0, 250.0);

						if(numb == 2)
						{
							TeleportDiversioToRandLocation(npc.index, true);//if this also fails i give up.
						}
					}
				}
			}
		}
		else
		{
			npc.Gamblers_WeaponKit(true);
			npc.m_flSpeed = fl_DefaultSpeed;
		}
		
		npc.Gambler_Cosmetics();
		npc.RnD_Tier_Gain_Stats();
		float gameTime = GetGameTime(npc.index);
		npc.fl_Money = 0.0;
		npc.fl_Delay_AnimEffects = 0.0;
		npc.fl_Printing_Money_Time = gameTime + 0.6;
		npc.fl_SlotMachine_Cooldown = gameTime + 10.0;
		
		func_NPCDeath[npc.index] = TheGambler_NPCDeath;
		func_NPCThink[npc.index] = TheGambler_ClotThink;
		func_NPCOnTakeDamage[npc.index] = TheGambler_OnTakeDamage;

		npc.m_flSpeed = 0.0;

		npc.m_flJumpCooldown = gameTime + 10.0;
		npc.m_flNextRangedAttackHappening = 0.0;

		RequestFrame(RF_Damage_Speed_Adjustment, npc);

		npc.m_iTeamGlow = TF2_CreateGlow(npc.index);
		npc.m_bTeamGlowDefault = false;
		SetVariantColor(view_as<int>({255, 255, 255, 200}));
		AcceptEntityInput(npc.m_iTeamGlow, "SetGlowColor");
		if(IsValidEntity(npc.m_iTeamGlow))
		{//THIS ALSO AFFECTS HIS HUD COLOR!!
			DataPack pack;
			CreateDataTimer(0.2, TheGambler_GlowCustom, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(EntIndexToEntRef(npc.m_iTeamGlow));
			pack.WriteCell(EntIndexToEntRef(npc.index));
		}

		npc.StartPathing();
		//if(!clone)
		//npc.PlayIntro();
		
		return npc;
	}
}

//Get Bonuses from spawn. i can't have them instantly so delay by one frame
static void RF_Damage_Speed_Adjustment(TheTemperalGambler npc)
{
	npc.fl_Damage_Intotal = fl_Extra_Damage[npc.index];
	npc.fl_Speed_Intotal = fl_Extra_Speed[npc.index];
	npc.b_AllowBuffsToWork = true;
}

static void TheGambler_NPCDeath(int entity)
{
	TheTemperalGambler npc = view_as<TheTemperalGambler>(entity);
	//Every plugin doesn't care if someone else is the main raid. Why?
	RaidBossActive = INVALID_ENT_REFERENCE;

	if(IsValidEntity(npc.m_iWearable1))
		RemoveEntity(npc.m_iWearable1);
	
	npc.Gambler_RemoveAllCosmetics();
}
static void TheGambler_ClotThink(int iNPC)
{
	TheTemperalGambler npc = view_as<TheTemperalGambler>(iNPC);

	bool clone = npc.m_bFUCKYOU;
	if(!clone)
	{
		//Don't allow the ally version to fuck over the round, someone will make them red for sure..
		if(GetTeam(npc.index) != TFTeam_Red)
		{
			int mainraid = EntRefToEntIndex(RaidBossActive);
			if(RaidModeTime < GetGameTime() && npc.index == mainraid) {
				RaidBossActive = INVALID_ENT_REFERENCE;
				int hp = RoundFloat(ReturnEntityMaxHealth(npc.index)*3.0);
				Temperals_Spawner(npc, 25000, 10, "Defense-Mode", "npc_buster_man", 1.25, 1.25, 0.5, 0.85);
				Temperals_Spawner(npc, hp, 1, "sc60;Defense-Mode", "npc_phlogstorm", 1.65, 1.25, 0.5, 0.5);
				SmiteNpcToDeath(npc.index);
				CPrintToChatAll("{cyan}The Gambler{default}: I'll leave you guys with an Ancient Races{red} Defense System.");
				//ForcePlayerLoss();
				//func_NPCThink[npc.index] = INVALID_FUNCTION;
				return;
			}
			if(!IsValidEntity(mainraid)){
				RaidBossActive = EntIndexToEntRef(npc.index);
			}
		}
	}
	
	float gameTime = GetGameTime(npc.index);
	float gt = GetGameTime();

	npc.Gambler_BuffsApply(gameTime);
	
	if(npc.m_flDoingAnimation)
	{
		if(npc.m_flDoingAnimation <= gt)
		{
			npc.m_flDoingAnimation = 0.0;
			npc.AnimChanger(_, _, _, true);
			switch(npc.i_Animation_State)
			{
				case GAMBLER_WEAPONGAIN_ANIM:
				{
					npc.fl_Weapons_Cooldown = 0.0;
					npc.m_bisWalking = true;
				
					npc.Gamblers_WeaponKit();
				}
				case GAMBLER_INTRODUCTION:
				{
					//Add fancy effects 
					
					npc.Gamblers_WeaponKit(true);
					npc.ArmorSet(_, false);
				}
			}
			npc.ClearanceHelp(true);
			npc.i_Animation_State = 0;
			npc.m_flSpeed = fl_DefaultSpeed;
		}
		else
		{
			float Loc[3];
			GetEntPropVector(npc.index, Prop_Send, "m_vecOrigin", Loc);
			int color[4] = {255, 50, 40, 255};
			if(npc.fl_Delay_AnimEffects <= gt)
			{
				switch(npc.i_Animation_State)
				{
					case GAMBLER_WEAPONGAIN_ANIM:
					{
						//Add fancy effects
						spawnRing_Vectors(Loc, 200.0 * 2.0, 0.0, 0.0, 0.0, "materials/sprites/laserbeam.vmt", color[0], color[1], color[2], color[3], 1, 0.33, 6.0, 0.1, 1, 1.0);
					}
					case GAMBLER_INTRODUCTION:
					{
						//Add Introduction
						int amt = 10;
						switch(i_Introduction_Anim_State)
						{
							case 0:
							{
								TheGambler_Intro_Apply(npc, Loc, color);
								npc.GlobalCooldown(0.1 * float(amt));
							}
							case 10://176 without fl_Delay_AnimEffects
							{
								npc.m_flDoingAnimation = 1.0;
							}
						}
						
						i_Introduction_Anim_State++;
					}
				}
			}
			npc.fl_Delay_AnimEffects = gt + 0.1;

			return;
		}
	}
	npc.m_flNextDelayTime = gameTime + DEFAULT_UPDATE_DELAY_FLOAT;
	
	npc.Update();
	
	if(npc.m_blPlayHurtAnimation)
	{
		npc.m_blPlayHurtAnimation = false;
		//if(!npc.m_flAttackHappenswillhappen)
			npc.AddGesture("ACT_MP_GESTURE_FLINCH_CHEST", false);
		//npc.PlayHurtSound();
	}
	
	if(npc.m_flNextThinkTime > gameTime) {
		return;
	}

	npc.Rollers_Cleanup(gameTime);
	
	npc.m_flNextThinkTime = gameTime + 0.1;

	npc.RnD_Tier_Up();

	if(npc.fl_Printing_Money_Time)
	{
		if(npc.fl_Printing_Money_Time <= gameTime)
		{
			npc.fl_Money += npc.fl_Printing_Money;
			npc.fl_Printing_Money_Time = gameTime + 0.5;
		}
	}

	if(npc.fl_Money >= npc.fl_Max_Money)//this is technically just there so he doesn't go interg.
	{
		npc.fl_Money = npc.fl_Max_Money;
	}

	float TimeExtendCash = 5000.0;
	if((RaidModeTime - GetGameTime()) < 50.0 && GetURandomInt() % 30 == 21 && npc.fl_Money > TimeExtendCash && npc.i_RnD_Tier > 3)
	{
		float timextend = GetRandomFloat(10.0, 30.0);
		npc.fl_Money -= TimeExtendCash;
		//TimeExtend_Limit[npc.index]++;
		RaidModeTime += timextend;//Time increase
		EmitSoundToAll("vo/announcer_time_added.mp3", _, _, _, _, 1.0);
		EmitSoundToAll("vo/announcer_time_added.mp3", _, _, _, _, 1.0);
		CPrintToChatAll("{crimson}[Zombie Riot] {green}Gambler was kind enough to extend the timer by{yellow} %.0fs{green}.", timextend);
	}

	//npc.EmitHudNotification();

	npc.SlotMachine(gameTime);

	if(npc.fl_Weapons_Duration)
	{
		if(npc.fl_Weapons_Duration <= gameTime)
		{
			npc.fl_Weapons_Duration = 0.0;
			npc.Gamblers_WeaponKit(true);
		}
	}

	if(npc.fl_Weapons_Cooldown)
	{
		if(npc.fl_Weapons_Cooldown <= gameTime)
		{
			float time = GetGameTime() + 2.3;
			npc.fl_Weapons_Cooldown = 0.0;
			npc.m_flDoingAnimation = time;
			//taunt_tuefort_tango_a1
		}
	}

	npc.Gambler_Rollers(gameTime);

	if(LastMann)
	{
		if(!npc.m_bFUCKYOU_move_anim)
		{
			npc.m_bFUCKYOU_move_anim = true;
			//TheGambler_Lastman_Messages(npc);
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

		//I would've used this, but, i don't wanna modify zr's stuff so workaround it is.
		//gameTime = GetGameTime(npc.index, 3); //3 == attack rate buffs
		if(!npc.m_fbGunout)
		{
			TheGambler_SelfDefense_Melee(npc, gameTime, npc.m_iTarget, flDistanceToTarget);
		}
		else
		{
			TheGambler_SelfDefense_Guns(npc, gameTime, npc.m_iTarget, flDistanceToTarget);
		}
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

//I ONLY WANT HIS WEAPONS TO BE FAST NOT HIS ENTIRE KIT
static void TheGambler_BankRollersAttackSpeedModifer(TheTemperalGambler npc, float &gameTime)
{
	if(npc.fl_Rollers_Effect_Time > gameTime)
	{
		if(npc.fl_AttackSpeed_Bonus_BankRollers && npc.fl_AttackSpeed_Bonus_BankRollers != 0.0)
		{
			gameTime *= npc.fl_AttackSpeed_Bonus_BankRollers;
		}
	}
}

static void TheGambler_SelfDefense_Melee(TheTemperalGambler npc, float gameTime, int target, float flDistanceToTarget)
{
	float modifer_gt = gameTime;
	TheGambler_BankRollersAttackSpeedModifer(npc, modifer_gt);

	//if(npc.m_flAttackHappens)
	//{
	//	if (npc.m_flAttackHappens < modifer_gt)
	//	{
	//		npc.m_flAttackHappens = 0.0;
	//	}
	//}
	if(npc.m_flNextMeleeAttack > gameTime)
	{
		return;
	}
	
	if(flDistanceToTarget < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 1.25))
	{
		int Enemy_I_See;
		Enemy_I_See = Can_I_See_Enemy(npc.index, target);

		if(IsValidEnemy(npc.index, Enemy_I_See))
		{
			npc.m_iTarget = Enemy_I_See;

			//npc.PlayMeleeSound();

			float damage = TheGambler_MeleeDamage_Tier(npc);
			//If you want to buff the damage or decrease it a bit, just use
			//damage *= value; on their weapontype
			//I didn't felt like making this longer then it should be so i did this instead a dynamic melee system for this npc lol
			Function func = INVALID_FUNCTION;
			func = TheGambler_OnTimeHitGains;
			float attack = GetRandomFloat(0.56, 0.79);
			bool aoe = true;
			float knockback = 200.0;
			bool jawbreaker = (npc.i_WeaponType == 3);
			switch(npc.i_WeaponType)
			{
				case 0://Default
				{
					knockback = 300.0;
				}
				case 1://Hammer
				{
					knockback = ((GetURandomInt() % 1) ? 600.0 : 200.0);
				}
				case 2://Soul Absorber
				{
					//FuncHit = TheGambler_SingleDamage_Melee;
					attack = 0.3;
					aoe = false;
				}
				case 3://JawBreaker
				{
					//FuncHit = TheGambler_SingleDamage_Melee;
					knockback *= 4.0;
					aoe = false;
					func = TheGambler_JawBreaker_OnHit;
					attack = 1.0;
				}
				case 4://Corrupted Knife
				{
					damage *= 0.5;
					attack = 0.1;
				}
				case 5:
				{
					
				}
				case 6:
				{
					
				}
				case 7:
				{
					
				}
				case 8:
				{
					
				}
			}
			damage *= RaidModeScaling;
			
			npc.AddGesture(jawbreaker ? "ACT_MP_ATTACK_STAND_MELEE_SECONDARY" : "ACT_MP_ATTACK_STAND_MELEE");
			
			npc.m_flNextMeleeAttack = modifer_gt + attack;
			//if(FuncHit && FuncHit == INVALID_FUNCTION)
			//{
			//	FuncHit = TheGambler_SingleDamage_Melee;
			//}
			int frames = 12;
			DataPack pack = new DataPack();
			pack.WriteCell(EntIndexToEntRef(npc.index));
			pack.WriteFloat(damage);
			pack.WriteFunction(func);
			pack.WriteFloat(knockback);
			RequestFrames((aoe ? TheGambler_AoEDamage_Melee : Temperals_SingleDamage_Melee), frames, pack);
		}
	}
}

static float TheGambler_MeleeDamage_Tier(TheTemperalGambler npc)
{
	float damage = 8.0;
	switch(npc.i_RnD_Tier)
	{
		case -1, 0:
		{
			damage = 8.0;
		}
		case 1:
		{
			damage = 9.0;
		}
		case 2:
		{
			damage = 10.0;
		}
		case 3:
		{
			damage = 11.0;
		}
		case 4:
		{
			damage = 12.0;
		}
		case 5:
		{
			damage = 13.0;
		}
		default:
		{
			damage = 14.0;
		}
	}

	return damage;
}

void TheGambler_AoEDamage_Melee(DataPack data)
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

	int target = npc.m_iTarget;

	if(IsValidEnemy(npc.index, target))
	{
		int HowManyEnemeisAoeMelee = 64;
		Handle swingTrace;

		float VecEnemy[3]; WorldSpaceCenter(npc.m_iTarget, VecEnemy);
		npc.FaceTowards(VecEnemy, 15000.0);
		npc.DoSwingTrace(swingTrace, npc.m_iTarget, _, _, _, 1, _, HowManyEnemeisAoeMelee);
		delete swingTrace;
		bool PlaySound = false;
		bool silenced = NpcStats_IsEnemySilenced(npc.index);
		for(int counter = 1; counter <= HowManyEnemeisAoeMelee; counter++)
		{
			if(i_EntitiesHitAoeSwing_NpcSwing[counter] > 0)
			{
				if(IsValidEntity(i_EntitiesHitAoeSwing_NpcSwing[counter]))
				{
					int targetTrace = i_EntitiesHitAoeSwing_NpcSwing[counter];
					float vecHit[3];
					
					WorldSpaceCenter(targetTrace, vecHit);

					if(damage <= 1.0)
					{
						damage = 1.0;
					}
					
					// On Hit stuff
					//static void OnHitAoe(int entity, int victim, float damage, bool Once)
					bool Knocked = false;
					if(FuncOnHit && FuncOnHit != INVALID_FUNCTION)
					{
						Call_StartFunction(null, FuncOnHit);
						Call_PushCell(entity);
						Call_PushCell(targetTrace);
						Call_PushFloat(damage);
						Call_PushCell(PlaySound);
						Call_Finish();
					}

					SDKHooks_TakeDamage(targetTrace, npc.index, npc.index, damage, DMG_CLUB, -1, _, vecHit);
					//Reduce damage after dealing
					damage *= 0.92;
					if(!PlaySound)
					{
						PlaySound = true;
					}

					if(IsValidClient(targetTrace))
					{
						if(!silenced)
						{
							TF2_AddCondition(targetTrace, TFCond_LostFooting, 0.5);
							TF2_AddCondition(targetTrace, TFCond_AirCurrent, 0.5);
						}
					}
					Custom_Knockback(npc.index, targetTrace, knockback, true);
				} 
			}
		}
		if(PlaySound)
		{
			//npc.PlayMeleeHitSound();
		}
	}

	delete data;
}
static void TheGambler_OnTimeHitGains(int entity, int victim, float damage, bool PlaySound)
{
	if(!PlaySound)
	{
		npc.fl_Money += 20.0;
	}
}
/*
void TheGambler_SingleDamage_Melee(DataPack data)
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
	if(npc.DoSwingTrace(swingTrace, target))
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
					Call_PushCell(PlaySound);
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
}*/

static void TheGambler_JawBreaker_OnHit(int entity, int victim, float damage, bool PlaySound)
{
	if(PlaySound)//Exists so he cannot shut them down entirely
	{
		TheGambler_OnTimeHitGains(entity, victim, damage, PlaySound);
		return;
	}

	TheTemperalGambler npc = view_as<TheTemperalGambler>(entity);
	
	//Grab victims name
	char name[128];
	if(b_ThisWasAnNpc[victim])
	{
		FormatEx(name, sizeof(name), "%s", /*c_NpcName[victim]*/ NpcStats_ReturnNpcName(victim, true));
	}
	else
	{
		if(IsValidClient(victim))
		{
			FormatEx(name, sizeof(name), "%N", victim);
		}
		else
		{//Idk, if someone somehow gets called it's the creature.
			FormatEx(name, sizeof(name), "%s", "The Creature..");
		}
	}

	//The chances of getting quacked
	if(GetURandomInt() % 2)
	{
		damage *= 5.0;
		Temperlas_TimeSlow(0.4, 0.12);
		CPrintToChatAll("Victim {blue}%s{red} got drastically Obliterated..", name);
		if(GetURandomInt() % 2)
		{
			CPrintToChatAll("{Orange}%s{red} increased {cyan}The Gambler's{red} Money by 25%%%", name);
			npc.fl_Money *= 1.25;
		}
	}
	else
	{//This is moreso less chance of getting damaged but you'll buff his credit gain a lot.
		damage *= 0.45;
		if(GetURandomInt() % 5)
		{
			float gain = 1.95;
			CPrintToChatAll("{Orange}%s{red} increased {cyan}The Gambler's{red} Money by %i%%%", name, -(100 - RoundFloat(100 * gain)));
			npc.fl_Money *= 1.95;
		}
	}
	npc.fl_Weapons_Duration = 1.0;
}

static void TheGambler_SelfDefense_Guns(TheTemperalGambler npc, float gameTime, int target, float flDistanceToTarget)
{
	if(npc.m_flNextRangedSpecialAttack)
	{
		if(npc.m_flNextRangedSpecialAttack < gameTime)
		{
			npc.m_flNextRangedSpecialAttack = 0.0;
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
				//npc.PlayMeleeSound();
				//npc.AddGesture("ACT_MP_THROW");//ACT_MP_ATTACK_STAND_ITEM1
						
				npc.m_flNextRangedSpecialAttack = gameTime + 0.15;
				npc.m_flNextRangedAttack = gameTime + 1.85;
			}
		}
	}
}

static Action TheGambler_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	//Valid attackers only.
	if(attacker < 1)
		return Plugin_Continue;

	TheTemperalGambler npc = view_as<TheTemperalGambler>(victim);
	if(!npc.m_bFUCKYOU)//CLONES
	{
		float gameTime = GetGameTime(npc.index);
		if(npc.fl_CashGain_OnHit_Timer < gameTime)
		{
			npc.fl_Money += npc.fl_CashGain_OnHit;
			npc.fl_CashGain_OnHit_Timer = gameTime + 0.15;
		}
		
		if(Temperals_Stabbed(attacker, victim, weapon, damagetype))
		{
			npc.i_Stabbed++;
			if(npc.i_Stabbed >= 3)
			{
				//TheGambler_Backstab_Messages(attacker);
				/*float dmg = 13.0, radius = 160.0;
				dmg *= RaidModeScaling;
				Explode_Logic_Custom(dmg, npc.index, npc.index, -1, _, radius, _, _, true);*/
				npc.i_Stabbed = 0;
			}
		}
	}

	return Plugin_Continue;
}

static Action TheGambler_GlowCustom(Handle GlowTimer, DataPack data)
{
	data.Reset();
	int glow = EntRefToEntIndex(data.ReadCell());
	int entity = EntRefToEntIndex(data.ReadCell());
	
	if(!IsValidEntity(entity) || !IsValidEntity(glow))
	{
		delete GlowTimer;
		return Plugin_Stop;
	}
	
	//can't use int had to use float instead
	float Health = float(GetEntProp(entity, Prop_Data, "m_iHealth"));
	float MaxHealth = float(ReturnEntityMaxHealth(entity));
	float IntotalHp = Health/MaxHealth;
	float res/*= 0.09*/;
	res = 0.10;
	if((fl_MeleeArmor[entity] < res && fl_RangedArmor[entity] < res || b_NpcIsInvulnerable[entity]))
	{
		int one = 20, two = 255;
		GamblerMultiUseColor[0] = GetRandomInt(one, two);
		GamblerMultiUseColor[1] = GetRandomInt(one, two);
		GamblerMultiUseColor[2] = GetRandomInt(one, two);
	}
	else
	{
		GamblerMultiUseColor[0] = 255 - RoundFloat(IntotalHp * 255.0);
		GamblerMultiUseColor[1] = 0 + RoundFloat(IntotalHp * 255.0);
		GamblerMultiUseColor[2] = 0;
	}
	GamblerMultiUseColor[3] = 255;
	SetVariantColor(GamblerMultiUseColor);
	AcceptEntityInput(glow, "SetGlowColor");
	return Plugin_Continue;
}

static void TheGambler_Intro_Apply(TheTemperalGambler npc, float Loc[3], int color[4])
{
	//instantly break it after 10frames
	float endLoc[3];
	endLoc = Loc;

	for (int sequential = 1; sequential <= 3; sequential++)
	{
		spawnRing_Vectors(endLoc, 75.0 * 2.0, 0.0, 0.0, 5.0, "materials/sprites/laserbeam.vmt", color[0], color[1], color[2], color[3], 1, /*duration*/ 0.5, 5.0, 0.0, 1);
		endLoc[2] += 60.0 + (float(sequential) * 20.0);
	}
	//Reusing stuff.
	//vo/spy_sf12_goodmagic06.mp3
	EmitAmbientSound("misc/halloween/spell_lightning_ball_cast.wav", Loc, _, SNDLEVEL_RAIDSIREN, _, _, 80);
	npc.ArmorSet(_, true);
	npc.ClearanceHelp(false);
	npc.AnimChanger("taunt_curtain_call", 0.0, 0.65, false);
	
	endLoc[2] = 9999.0;
	TE_SetupBeamPoints(Loc, endLoc, g_Ruina_Laser_BEAM, 0, 0, 0, 0.8, 16.0, 16.0, 1, 15.0, color, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(Loc, endLoc, g_Ruina_BEAM_lightning, 0, 0, 0, 0.8, 16.0, 16.0, 1, 15.0, color, 0);
	TE_SendToAll();
}