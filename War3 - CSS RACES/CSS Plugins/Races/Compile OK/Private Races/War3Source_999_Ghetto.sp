/**
* File: War3Source_999_Ghetto.sp
* Description: Livin in da ghetto race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <smlib>

new thisRaceID;
new SKILL_SPEED, SKILL_CRIT, SKILL_VAMPIRE, SKILL_WEAPON, ULT_INVUL;



public Plugin:myinfo = 
{
    name = "War3Source Race - Livin in da ghetto",
    author = "Remy Lebeau",
    description = "Kablamo's private race for War3Source",
    version = "1.1",
    url = "http://sevensinsgaming.com"
};



new Float:UnholySpeed[5] = {1.0, 1.1, 1.15, 1.2, 1.25};
new Float:LevitationGravity[5] = {1.0, 0.85, 0.7, 0.6, 0.5};
new Float:VampirePercent[5] = {0.0, 0.1, 0.2, 0.3, 0.4};
new Float:CritChance[5] = {0.0, 0.10, 0.20, 0.30, 0.40};
//new Float:CritModifier[5] = {0.0, 0.08, 0.14, 0.20, 0.25};
new HaloSprite;
new String:wep[MAXPLAYERS][64];
new Float:WeaponDuration[5] = { 0.0, 5.0, 7.5, 10.0, 12.5 };
new bool:bVoodoo[MAXPLAYERS];
new Float:UltimateDuration[]={0.0,1.0,2.0,2.5,3.0};
new String:ultimateSound[256]; //="war3source/divineshield.mp3";

new Handle:WeaponTimer[MAXPLAYERS+1];
new Handle:UltiTimer[MAXPLAYERS+1];

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Livin' in da ghetto [PRIVATE]","ghetto");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Outrun the popo","Increased speed and lower gravity",false,4);
    SKILL_CRIT=War3_AddRaceSkill(thisRaceID,"Hoods got ur back","Chance to do critical damage",false,4);
    SKILL_VAMPIRE=War3_AddRaceSkill(thisRaceID,"Take what you can","Steal health",false,4);
    SKILL_WEAPON=War3_AddRaceSkill(thisRaceID,"High rollin","Borrow an AK from your cuz (+ability)",false,4);
    ULT_INVUL=War3_AddRaceSkill(thisRaceID,"Million dollar deal","Money can buy protection from anything (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_INVUL,10.0,_);
    W3SkillCooldownOnSpawn(thisRaceID,SKILL_WEAPON,10.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_VAMPIRE, fVampirePercent, VampirePercent);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, UnholySpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fLowGravitySkill, LevitationGravity);

    War3_AddSkillBuff(thisRaceID, SKILL_CRIT, fCritChance, CritChance);    
//    War3_AddSkillBuff(thisRaceID, SKILL_CRIT, fCritModifier, CritModifier);


}





public OnMapStart()
{
    HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
    War3_AddSoundFolder(ultimateSound, sizeof(ultimateSound), "divineshield.mp3");

    War3_AddCustomSound(ultimateSound);
}
    

/***************************************************************************
*
*
*                PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife,weapon_glock,weapon_mac10");
        CreateTimer( 1.0, GiveWep, client );
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
    }
}

public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    bVoodoo[client]=false;
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife,weapon_glock,weapon_mac10");
        CreateTimer( 1.0, GiveWep, client );
    }
}







/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/


public OnAbilityCommand( client, ability, bool:pressed )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID && pressed && ValidPlayer( client, true )  && ability == 0 )
    {
        new skill_level = War3_GetSkillLevel( client, race, SKILL_WEAPON );
        if( skill_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, SKILL_WEAPON, true ) )
            {
                RingEffectPlayer(client);
                GetClientWeapon( client, wep[client], 64 );
                Client_RemoveWeapon(client, "weapon_mac10");
                War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife,weapon_glock,weapon_ak47");
                GivePlayerItem( client, "weapon_ak47" );
                WeaponTimer[client] = CreateTimer( WeaponDuration[skill_level], GiveWeapon, client );
                War3_CooldownMGR( client, WeaponDuration[skill_level] + 15.0, thisRaceID, SKILL_WEAPON, _, true );
                    
            }
        }
        else
        {
            PrintHintText( client, "Level Your Ability First" );
        }
    }
}




public OnUltimateCommand(client,race,bool:pressed)
{

    if(race==thisRaceID && pressed && ValidPlayer(client, true) )
    {
        new ult_level=War3_GetSkillLevel(client,race,ULT_INVUL);
        if(ult_level>0)
        {
            if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,ULT_INVUL,true))
            {
                bVoodoo[client]=true;
                
                W3SetPlayerColor(client,thisRaceID,255,200,0,_,GLOW_ULTIMATE); //255,200,0);
                
                UltiTimer[client] = CreateTimer(UltimateDuration[ult_level],EndVoodoo,client);
                W3FlashScreen(client,RGBA_COLOR_YELLOW, 0.4, 0.2, FFADE_IN);
                War3_CooldownMGR(client,UltimateDuration[ult_level] + 20.0,thisRaceID,ULT_INVUL);
                
                PrintToChat(client, "Money buys protection for |%i| seconds", RoundToFloor(UltimateDuration[ult_level]));
                W3EmitSoundToAll(ultimateSound,client);
                W3EmitSoundToAll(ultimateSound,client);
            }

        }
        else
        {
            W3MsgUltNotLeveled(client);
        }
    }
}


/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/
public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0) //block self inflicted damage
    {
        if(bVoodoo[victim]&&attacker==victim){
            War3_DamageModPercent(0.0);
            return;
        }
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        
        
        if(vteam!=ateam)
        {
            if(bVoodoo[victim])
            {
                if(!W3HasImmunity(attacker,Immunity_Ultimates))
                {
                    War3_DamageModPercent(0.0);
                }
                else
                {
                    W3MsgEnemyHasImmunity(victim,true);
                }
            }
        }
    }
    return;
}



public OnWar3EventDeath(victim,attacker)
{
    new race = War3_GetRace( victim );
    if( race == thisRaceID && ValidPlayer( victim ))
    {
    	if (WeaponTimer[victim] != INVALID_HANDLE)
        {
	        KillTimer(WeaponTimer[victim]);
	        WeaponTimer[victim] = INVALID_HANDLE;
        }
        
        if (UltiTimer[victim] != INVALID_HANDLE)
        {
	        KillTimer(UltiTimer[victim]);
	        UltiTimer[victim] = INVALID_HANDLE;
        }
    }
}


/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/


public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            
        	if (WeaponTimer[i] != INVALID_HANDLE)
	        {
		        KillTimer(WeaponTimer[i]);
		        WeaponTimer[i] = INVALID_HANDLE;
	        }
	        
	        if (UltiTimer[i] != INVALID_HANDLE)
	        {
		        KillTimer(UltiTimer[i]);
		        UltiTimer[i] = INVALID_HANDLE;
	        }
        }
    }
}

   
public Action:GiveWeapon( Handle:timer, any:client )
{
    if(ValidPlayer(client,true))
    {
        //let's check if he's wearing the AK, and not something else..
        RingEffectPlayer(client);
        Client_RemoveWeapon(client, "weapon_ak47");
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife,weapon_glock,weapon_mac10");
        GivePlayerItem( client, wep[client] );
        WeaponTimer[client] = INVALID_HANDLE;
    }
}

    
public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
    
        GivePlayerItem( client, "weapon_glock" );
        GivePlayerItem( client, "weapon_mac10" );
        
    }
}


public Action:EndVoodoo(Handle:timer,any:client)
{
    if(ValidPlayer(client))
    {
        if(ValidPlayer(client,true))
        {
            PrintToChat(client, "Back to being a normal ghetto dweller");
            bVoodoo[client]=false;
            W3ResetPlayerColor(client,thisRaceID);
            W3FlashScreen(client,RGBA_COLOR_YELLOW, 0.4, 0.2, FFADE_OUT);
        }
        UltiTimer[client] = INVALID_HANDLE;
    }
    
}


public RingEffectPlayer(client)
{
    new Float:client_pos[3];            
    GetClientAbsOrigin( client, client_pos );
    TE_SetupBeamRingPoint(client_pos,82.0,28.0,HaloSprite,HaloSprite,0,20,3.0,5.0,12.0,{255,255,255,255},0,0);
    TE_SendToAll();
    TE_SetupBeamRingPoint(client_pos,72.0,5.0,HaloSprite,HaloSprite,0,40,3.0,1.0,2.0,{255,150,150,255},5,0);
    TE_SendToAll(0.35);
}