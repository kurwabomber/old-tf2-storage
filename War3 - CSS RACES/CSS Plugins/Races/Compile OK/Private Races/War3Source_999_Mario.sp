/**
* File: War3Source_999_Mario.sp
* Description: Mario Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_GRAV, SKILL_SPEED, SKILL_NADE, ULT_VOODOO;

#define WEAPON_RESTRICT ""
#define WEAPON_GIVE ""

public Plugin:myinfo = 
{
    name = "War3Source Race - Mario",
    author = "Remy Lebeau",
    description = "Camdog's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.1, 1.2, 1.3, 1.4 };
new Float:g_fGravity[] = { 1.0, 0.9, 0.8, 0.7, 0.6 };
new g_iHealth[]={0,-5,-10,-15,-20};


new bool:bOrb[MAXPLAYERS];
new bool:bBurn[MAXPLAYERS];

// g_iBurnOwner[VICTIMS] = OWNER;
new g_iBurnOwner[MAXPLAYERS];
new g_iNadeDam[] = {0, 1, 2, 3, 4};
new BurnSprite;

new String:fire[]="war3source/roguewizard/fire.wav";
new String:star[]="war3source/mario/smb_powerup.wav";
new String:flower[]="war3source/mario/smw_fireball.wav";


new Float:UltimateDuration[]={0.0,1.0,2.0,3.0,4.0};
new Float:g_fUltSpeed[] = { 0.0, 1.45, 1.5, 1.55, 1.6 };
new String:ultimateSound[256]; //="war3source/divineshield.mp3";
new bool:bVoodoo[MAXPLAYERS];

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Mario [PRIVATE]","mario");
    
    SKILL_GRAV=War3_AddRaceSkill(thisRaceID,"Jump","Jump like Mario at the cost of max health",false,4);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Speed","Run like Mario at the cost of max health",false,4);
    SKILL_NADE=War3_AddRaceSkill(thisRaceID,"Flower Power","Throw a fireball (+ability)",false,4);
    ULT_VOODOO=War3_AddRaceSkill(thisRaceID,"Star Power"," Become faster and immune to physical damage! (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_VOODOO,15.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_GRAV, fLowGravitySkill, g_fGravity);
}



public OnPluginStart()
{
    CreateTimer(1.0,Burn,_,TIMER_REPEAT);
    HookEvent("round_end",RoundOverEvent);
    HookEvent("weapon_fire",WeaponFire);
}



public OnMapStart()
{
    War3_AddCustomSound(fire);
    War3_AddCustomSound(star);
    War3_AddCustomSound(flower);
    BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");
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


public InitPassiveSkills( client )
{

    new skill_speed=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
    new skill_grav=War3_GetSkillLevel(client,thisRaceID,SKILL_GRAV);
    
    new totalhealth = g_iHealth[skill_speed] + g_iHealth[skill_grav];
    War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,totalhealth);    

}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills( client );
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
    }
}

public OnWar3EventSpawn( client )
{
    bBurn[client] = false;

    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {    
        InitPassiveSkills( client );
        bOrb[client]=false;
        bVoodoo[client]=false;
    }
}




public OnSkillLevelChanged(client,race,skill,newskilllevel )
{
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills(client);
    }    
}




/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/


public OnAbilityCommand(client,ability,bool:pressed)
{
    if (War3_GetRace(client)==thisRaceID)
    {
        if(!Silenced(client) &&  ValidPlayer(client, true))
        {
            if(ability==0 && pressed)
            {
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_NADE,true))
                {
                    new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_NADE);
                    if(skill_level>0)
                    {      
                        GivePlayerItem(client,"weapon_hegrenade");
                        PrintHintText(client, "Flower Nade Loaded!");
                        bOrb[client]=true;
                    }
                    else
                    {
                        PrintHintText(client, "Level Flower Power first");
                    }
                }
            }
        }
        else
        {
            PrintHintText(client,"Silenced: Can not cast");
        }
    }
}


public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed  && ValidPlayer(client, true) )
    {
        new ult_level=War3_GetSkillLevel(client,race,ULT_VOODOO);
        if(ult_level>0)
        {
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_VOODOO,true))
            {
                bVoodoo[client]=true;
                W3SetPlayerColor(client,thisRaceID,255,200,0,_,GLOW_ULTIMATE); //255,200,0);
                CreateTimer(UltimateDuration[ult_level],EndVoodoo,client);
                War3_CooldownMGR(client,30.0,thisRaceID,ULT_VOODOO,_,_);
                //W3EmitSoundToAll(ultimateSound,client);
                //W3EmitSoundToAll(ultimateSound,client);
                War3_SetBuff(client,fMaxSpeed,thisRaceID,g_fUltSpeed[ult_level]);
                EmitSoundToAll(star,client);
            }

        }
        else
        {
            W3MsgUltNotLeveled(client);
        }
    }
}


public Action:EndVoodoo(Handle:timer,any:client)
{
    bVoodoo[client]=false;
    W3ResetPlayerColor(client,thisRaceID);
    if(ValidPlayer(client,true))
    {
        new skill_speed=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
        War3_SetBuff(client,fMaxSpeed,thisRaceID,g_fSpeed[skill_speed]);
        
        PrintHintText(client,"Star Power Faded");
    }
}

/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/


public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        
        if(vteam!=ateam){
            new race_attacker=War3_GetRace(attacker);
            new skill_nade=War3_GetSkillLevel(attacker,thisRaceID,SKILL_NADE);
            if(race_attacker==thisRaceID && skill_nade>0 && bOrb[attacker] && StrEqual(weapon,"hegrenade_projectile",false))
            {
                if(!W3HasImmunity(victim,Immunity_Skills))
                {
                    EmitSoundToAll(flower,victim);
                    g_iBurnOwner[victim] = attacker;
                    bBurn[victim] = true;
                    CreateTimer(5.0,BurnOff,victim);

                }
                
            }
            
        }
        
    }
    
}



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


/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/


public Action:Burn(Handle:timer,any:userid)
{
    for(new client=1;client<=MaxClients;client++)
    {
        if(ValidPlayer(client,true) && bBurn[client])
        {
            if(!W3HasImmunity(client,Immunity_Skills))
            {
                new race_attacker=War3_GetRace(g_iBurnOwner[client]);
                if(race_attacker==thisRaceID)
                {
                    new skill_nade=War3_GetSkillLevel(g_iBurnOwner[client],thisRaceID,SKILL_NADE);
                    if(skill_nade)
                    {
                        War3_DealDamage(client,g_iNadeDam[skill_nade],g_iBurnOwner[client],DMG_BULLET,"Flower Power");
                        new Float:targetpos[3];
                        GetClientAbsOrigin(client,targetpos);
                        TE_SetupGlowSprite(targetpos,BurnSprite,1.0,1.9,255);
                        TE_SendToAll();
                        W3FlashScreen(client,RGBA_COLOR_RED,1.0);
                        EmitSoundToAll(fire,client);
                        EmitSoundToAll(flower,client);
                    }
                }
            }
        }
    }
}


public Action:BurnOff(Handle:timer,any:victim)
{
    if (ValidPlayer(victim))
    {
        g_iBurnOwner[victim] = 0;
        bBurn[victim] = false;
    }    
}

public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            W3ResetAllBuffRace( i, thisRaceID );
        }
    }
}



public WeaponFire(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client_userid = GetEventInt(event, "userid");    
    new client = GetClientOfUserId(client_userid);
    if (ValidPlayer(client) && War3_GetRace(client) ==  thisRaceID && bOrb[client])
    {
        new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        new String:weaponname[32];
        GetEdictClassname(weapon, weaponname, 32);
        new skill_nade=War3_GetSkillLevel(client,thisRaceID,SKILL_NADE);
        if(skill_nade && StrEqual(weaponname, "weapon_hegrenade"))
        {
            War3_CooldownMGR( client, 30.0, thisRaceID, SKILL_NADE, _, _ );
            CreateTimer(2.0,OrbOff,client);
            EmitSoundToAll(flower,client);
        }
    }
}
    
public Action:OrbOff(Handle:timer,any:client)
{
    if (ValidPlayer(client))
    {
        bOrb[client] = false;
    }    
}

public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        Client_GiveWeapon(client, WEAPON_GIVE, true); 
    }
}