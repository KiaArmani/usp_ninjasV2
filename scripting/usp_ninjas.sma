/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <engine>

#define PLUGIN "usp_ninjas V2"
#define VERSION "2.0"
#define AUTHOR "Kia 'Xi4' Armani"

// ===============================================================================
// 	Plugin Options
// ===============================================================================

#define GAME_HIDETIME 15.0
// Time in Seconds how long Terrorists have time to hide themselves at round begin.

#define DMG_TOGGLEFALLDAMGE 1
// If set to 1, CTs will not recieve falldamage.

#define HUD_REFRESHRATE 1.0
// Time in Seconds how often the HUD will refresh.

#define ENV_LIGHTP "e"
// Sets the Environment Light Intensity

#define USP_CLIPSIZE 12
// Sets Clip size for the USP you get.

#define USP_CLIPAMOUNT 1
// Amount of Clips you get for your USP

// ===============================================================================
// 	Variables
// ===============================================================================

/* Defines */
#define EXTRAOFFSET_WEAPONS 4
#define m_pPlayer 41
#define m_flNextSecondaryAttack 47
#define OFFSET_SILENCER_FIREMODE 74
#define XO_WEAPON 4

#define set_usp_silent(%1)    set_pdata_int(%1, OFFSET_SILENCER_FIREMODE, USP_SILENCED, EXTRAOFFSET_WEAPONS)
#define get_weapon_owner(%1)  get_pdata_cbase(%1, m_pPlayer, EXTRAOFFSET_WEAPONS) 

/* Booleans */
new bool:g_bIsReady

/* Consts */
const USP_SILENCED = (1<<0)

/* Integer */
new const g_iTaskBaseID = 7211
new const g_iTaskHUDID = 812
new const g_iTaskSwapID = 2000

new g_iCountDownTime
new g_iMaxPlayers

/* HUD */
new g_HudSyncObj

/* Hamsandwich */
new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame 

// ===============================================================================
// 	plugin_init
// ===============================================================================

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	/* Events */
	register_event("HLTV", "Event_HLTVNewRound", "a", "1=0", "2=0")
	register_event("SendAudio", "Event_CTWin", "a", "2&%!MRAD_ctwin" ) 
	
	/* Hamsandwich */
	RegisterHam(Ham_Spawn, "player", "Ham_OnPostPlayerSpawn", 1)
	RegisterHam(Ham_TakeDamage, "player", "Ham_OnPrePlayerTakeDamage")
	RegisterHam(Ham_Item_Deploy, "weapon_usp", "Ham_OnPostUSPDeploy", 0)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_usp", "Ham_OnPreUSPPrimary", 0)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_usp", "Ham_OnPostUSPSecondary", 1)
	RegisterHam(Ham_Player_ResetMaxSpeed, "player", "Ham_OnPostPlayerMaxRes", 1)
	
	/* HUD */
	g_HudSyncObj = CreateHudSyncObj()
	
	set_lights(ENV_LIGHTP)
	g_iMaxPlayers = get_maxplayers()
	
}

// ===============================================================================
// 	Event_HLTVNewRound - Called when a new Round begins.
// ===============================================================================

public Event_HLTVNewRound()
{
	set_task(0.1, "Game_PostRoundStart")
}

// ===============================================================================
// 	Event - @ CT Win - Credits go to Exolent
// ===============================================================================

public Event_CTWin()
{
	static iCount, client;
	
	iCount = 0;
	
	for( client = 1; client <= g_iMaxPlayers; client++ )
	{
		if( is_user_connected( client ) )
		{
			if( iCount >= 5 )
			{
				set_task( 0.5, "Event_CTWin", g_iTaskSwapID );
			}
			
			switch( cs_get_user_team( client ) )
			{
				case CS_TEAM_T:
				{
					cs_set_user_team( client, CS_TEAM_CT, CS_CT_GIGN );
					
					iCount++;
				}
				case CS_TEAM_CT:
				{
					cs_set_user_team( client, CS_TEAM_T, CS_T_LEET );
					
					iCount++;
				}
			}
		}
	}
	
	remove_task(g_iTaskSwapID)
}

public Game_PostRoundStart()
{
	g_bIsReady = false
	Game_RemoveTasks()
	Game_StartTimer()
	Game_ToggleCTs(1)
}

// ===============================================================================
// 	Ham_OnPostPlayerSpawn - Called after a player spawned.
// ===============================================================================

public Ham_OnPostPlayerSpawn(id)
{
	if(is_user_alive(id)) // Checking if User is alive (and connected)
	{
		strip_user_weapons(id) 			// Take away his weapons.
		
		give_item(id, "weapon_knife") 		// Give him a knife
		new iUSP = give_item(id, "weapon_usp") 	// and a USP.
		cs_set_weapon_ammo(iUSP, USP_CLIPSIZE)
		cs_set_user_bpammo(id, CSW_USP, USP_CLIPAMOUNT * 12)
	}
}

// ===============================================================================
// 	Ham_OnPrePlayerTakeDamage
// ===============================================================================

public Ham_OnPrePlayerTakeDamage(const id, const iInflictor, const iAttacker, const Float:flDamage, const iDamageType )
{
	if( iDamageType == DMG_FALL && DMG_TOGGLEFALLDAMGE && cs_get_user_team(id) == CS_TEAM_CT)
	{
		SetHamReturnInteger(0)
		return HAM_SUPERCEDE
	}
	
	return HAM_IGNORED
}

// ===============================================================================
// 	Ham_OnPostUSPDeploy - Called after someone pulled out a USP
// ===============================================================================

public Ham_OnPostUSPDeploy(iEnt)
{
	if(!pev_valid(iEnt))
		return HAM_HANDLED
	
	new id = get_pdata_cbase(iEnt, m_pPlayer, XO_WEAPON)
	if(!is_user_alive(id))
		return HAM_HANDLED
	
	if (!cs_get_weapon_silen(iEnt))
		cs_set_weapon_silen(iEnt, 1, 0)  
	
	return PLUGIN_CONTINUE
}

// ===============================================================================
// 	Ham_OnPreUSPPrimary
// ===============================================================================

public Ham_OnPreUSPPrimary(iEnt)
{
	if(!pev_valid(iEnt))
		return HAM_HANDLED
	
	new id = get_pdata_cbase(iEnt, m_pPlayer, XO_WEAPON)
	if(!is_user_alive(id))
		return HAM_HANDLED

	if (!cs_get_weapon_silen(iEnt))
	{
		cs_set_weapon_silen(iEnt, 1, 0) 
	}
	
	return PLUGIN_CONTINUE
}

// ===============================================================================
// 	Ham_OnPostUSPSecondary
// ===============================================================================

public Ham_OnPostUSPSecondary(iEnt)
{
	if(!pev_valid(iEnt))
		return HAM_HANDLED
		
	new id = get_pdata_cbase(iEnt, m_pPlayer, XO_WEAPON)
	if(!is_user_alive(id))
		return HAM_HANDLED

	if (!cs_get_weapon_silen(iEnt))
	{
		cs_set_weapon_silen(iEnt, 1, 0) 
	}
	
	return PLUGIN_CONTINUE
}

// ===============================================================================
// 	Ham_OnPostPlayerMaxRes
// ===============================================================================

public Ham_OnPostPlayerMaxRes(id)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED
	
	if(!g_bIsReady && cs_get_user_team(id) == CS_TEAM_CT)
		Game_DisablePlayer(id)
		
	return PLUGIN_CONTINUE	
}

// ===============================================================================
// 	Game_RemoveTasks
// ===============================================================================

public Game_RemoveTasks()
{
	if(task_exists(g_iTaskBaseID)) remove_task(g_iTaskBaseID)
	if(task_exists(g_iTaskHUDID)) remove_task(g_iTaskHUDID)
}

// ===============================================================================
// 	Game_StartTimer
// ===============================================================================

public Game_StartTimer()
{
	set_task(GAME_HIDETIME, "Game_StopTimer", g_iTaskBaseID)
	Game_ToggleCountdownHUD(1)
}

// ===============================================================================
// 	Game_StopTimer
// ===============================================================================

public Game_StopTimer(iTaskID)
{
	g_bIsReady = true
	Game_ToggleCTs(0)
	Game_ToggleCountdownHUD(2)
}

// ===============================================================================
// 	Game_DisableCTs
// ===============================================================================

public Game_ToggleCTs(iState)
{
	new szPlayers[32] 
	new iPlayerCount, i, id 
	get_players(szPlayers, iPlayerCount, "ae", "CT") // Get all alive CTs
	
	for (i = 0; i < iPlayerCount; i++) 
	{
		id = szPlayers[i]
		iState == 1 ? Game_DisablePlayer(id) : Game_EnablePlayer(id)
	}
}

// ===============================================================================
// 	Game_DisablePlayer
// ===============================================================================

public Game_DisablePlayer(id)
{
	set_user_maxspeed(id, 0.1)
}

// ===============================================================================
// 	Game_EnablePlayer
// ===============================================================================

public Game_EnablePlayer(id)
{
	ExecuteHamB(Ham_Player_ResetMaxSpeed, id)
}

// ===============================================================================
// 	Game_ToggleCountdownHUD
// ===============================================================================

public Game_ToggleCountdownHUD(iState)
{
	if(iState == 1)
	{
		g_iCountDownTime = floatround(GAME_HIDETIME)
		Game_CountdownHUD()
		set_task(HUD_REFRESHRATE, "Game_CountdownHUD", g_iTaskHUDID, _, _, "b")
	}
	else
	{
		if(task_exists(g_iTaskHUDID)) 
			remove_task(g_iTaskHUDID)
	}
}

// ===============================================================================
// 	Game_CountdownHUD
// ===============================================================================

public Game_CountdownHUD()
{
	new szPlayers[32] 
	new iPlayerCount, i, id 
	get_players(szPlayers, iPlayerCount, "a") // Get all alive players
	
	set_hudmessage(0, 255, 0, -1.0, 0.15, 0, 6.0, HUD_REFRESHRATE)
	
	for (i = 0; i < iPlayerCount; i++) 
	{
		id = szPlayers[i]
		ShowSyncHudMsg(id, g_HudSyncObj, "Remaining time until CTs get unleashed: %i second(s).", g_iCountDownTime)
	}
	
	g_iCountDownTime--
}





