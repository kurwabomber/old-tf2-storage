/**
* File: War3Source_999_Tank.sp
* Description: Tank Race for War3Source
* Author(s): Remy Lebeau
*
* To do: ADD SMOKE EFFECT TO FIRING GUN
* ADD TIMERS / DELAYS to ultimate
* restrict healing from other players. 
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

#define WEAPON_RESTRICT "weapon_knife,weapon_deagle"
#define WEAPON_GIVE "weapon_deagle"


new thisRaceID;
new SKILL_ARMOUR, SKILL_CANNON, SKILL_DAMAGEAURA, ULT_MOBILISE;
new AuraID;
new Float:g_fDamageBuffDistance=200.0;
new Float:g_fDamageBuffDistanceEffect;

public Plugin:myinfo = 
{
    name = "War3Source Race - Tank",
    author = "Remy Lebeau",
    description = "Tank race for War3Source",
    version = "1.2",
    url = "http://sevensinsgaming.com"
};

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Tank [SSG-DONATOR]","tank");
    
    SKILL_ARMOUR=War3_AddRaceSkill(thisRaceID,"Armour","Bullets just seem to bounce off you (50%-80% dmg reduction)",false,4);
    SKILL_DAMAGEAURA=War3_AddRaceSkill(thisRaceID,"Damage Buff Aura","Just being near the tank increases everyone else's firepower!",false,4);
    SKILL_CANNON=War3_AddRaceSkill(thisRaceID,"Cannon","Fire explosive bullets (slows fire rate)",false,4);
    ULT_MOBILISE=War3_AddRaceSkill(thisRaceID,"Mobilise","Pack your guns away for extra speed (hold down +ultimate)",true,4);
        
    War3_CreateRaceEnd(thisRaceID);
    
    g_fDamageBuffDistanceEffect=g_fDamageBuffDistance+50;
    AuraID=W3RegisterAura("tank_damagebuff",g_fDamageBuffDistance);
    
}

new Float:g_fElectricTideOrigin[MAXPLAYERSCUSTOM][3];

new Float:g_fDmgLevel[] = { 0.0, 0.5, 0.4, 0.3, 0.2 };
new Float:g_fSpeedLevel[] = { 1.0, 0.8, 0.7, 0.6, 0.5 };
new Float:g_fFireSpeed[] = { 1.0, 0.7, 0.5, 0.3, 0.2 };
new Float:g_fDamageAuraAmount[]={ 0.0, 0.2, 0.3, 0.4, 0.5 };

new g_iExplosionModel; 
new g_iExplosionRadius[]={0,60,80,100,120}; 

new Float:g_fExplosionDamage[]={0.0,40.0,50.0,60.0,70.0};

new g_iBulletCounter; 
new bool:g_bHitByExplosion;

new String:g_sPlayerModel[] = "models/player/slow/t600/slow.mdl";
new Float:g_fMobiliseSpeed[] = { 1.0, 1.2, 1.3, 1.4, 1.5};

new HaloSprite, BeamSprite;

public OnPluginStart()
{

    HookEvent("bullet_impact",BulletImpact);
    CreateTimer(1.5,Aura,_,TIMER_REPEAT);
}



public OnMapStart()
{
    g_iExplosionModel = PrecacheModel( "materials/sprites/zerogxplode.vmt", false );
    
    BeamSprite = War3_PrecacheBeamSprite();
    HaloSprite = War3_PrecacheHaloSprite();
    

    PrecacheModel(g_sPlayerModel, true);
    AddFileToDownloadsTable("materials/models/player/slow/t600/slow_eyes.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/t600/slow_eyes.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/t600/slow_eyes_chrome.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/t600/slow_eyes_glow.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/t600/slow_eyes_glow.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/t600/slow_lens.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/t600/slow_lens.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/t600/slow_t600.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/t600/slow_t600.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/t600/slow_t600_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/t600/slow_t600_highres.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/t600/slow_t600_highres.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/t600/slow_t600_highres_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/t600/slow_t600_highres_metalshader.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/t600/slow_t600_metalshader.vmt");
    AddFileToDownloadsTable("models/player/slow/t600/slow.dx80.vtx");
    AddFileToDownloadsTable("models/player/slow/t600/slow.dx90.vtx");
    AddFileToDownloadsTable("models/player/slow/t600/slow.mdl");
    AddFileToDownloadsTable("models/player/slow/t600/slow.phy");
    AddFileToDownloadsTable("models/player/slow/t600/slow.sw.vtx");
    AddFileToDownloadsTable("models/player/slow/t600/slow.vvd");


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
    
    War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);
    CreateTimer( 1.0, GiveWep, client );
    
    new skill_armour = War3_GetSkillLevel(client, thisRaceID, SKILL_ARMOUR);
    new skill_cannon = War3_GetSkillLevel(client, thisRaceID, SKILL_CANNON);
    
    War3_SetBuff( client, fSlow, thisRaceID, g_fSpeedLevel[skill_armour]);
    //War3_SetBuff( client, fDodgeChance, thisRaceID, g_fEvadeLevel[skill_armour]  );
    War3_SetBuff( client, fAttackSpeed, thisRaceID, g_fFireSpeed[skill_cannon]);
    g_bHitByExplosion = false;
    
    SetEntityModel(client, g_sPlayerModel);
    
}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        new level=War3_GetSkillLevel(client,thisRaceID,SKILL_DAMAGEAURA);
        W3SetAuraFromPlayer(AuraID,client,level>0?true:false,level);
        InitPassiveSkills(client);
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
        W3SetAuraFromPlayer(AuraID,client,false);
    }
}


public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    if(race==thisRaceID && War3_GetRace(client)==thisRaceID)
    {
        if(skill==SKILL_DAMAGEAURA) //1
        {
            W3SetAuraFromPlayer(AuraID,client,newskilllevel>0?true:false,newskilllevel);
        }
        else
        {
            InitPassiveSkills(client);
        }
    }
}

public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills(client);
        new level=War3_GetSkillLevel(client,thisRaceID,SKILL_DAMAGEAURA);
        W3SetAuraFromPlayer(AuraID,client,level>0?true:false,level);
    }
}




/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/



public OnUltimateCommand(client,race,bool:pressed)
{
    if( race == thisRaceID && ValidPlayer(client,true) && !Silenced(client))
    {
        new skill = War3_GetSkillLevel( client, thisRaceID, ULT_MOBILISE );
        if(skill)
        {
            if(War3_SkillNotInCooldown(client,thisRaceID, ULT_MOBILISE,true))
            {
                if(pressed)
                {
                    War3_SetBuff( client, bDisarm, thisRaceID, true  );
                    War3_SetBuff( client, fMaxSpeed, thisRaceID, g_fMobiliseSpeed[skill]);
                    CPrintToChat(client,"{green} MOBILIZED");
                }
                else
                {
                    War3_SetBuff( client, bDisarm, thisRaceID, false  );
                    War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0);
                    CPrintToChat(client,"{red} GUNS DEPLOYED");
                    War3_CooldownMGR(client,3.0,thisRaceID,ULT_MOBILISE,true,_);
                }
            }
        }
        else
        {
            PrintHintText(client, "Level your Ultimate first");
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


public OnWar3EventDeath(victim,attacker)
{
    if (ValidPlayer(victim))
        W3ResetAllBuffRace( victim, thisRaceID );
    new level, ilevel;
    if (W3HasAura(AuraID,attacker,level))
    {
        new victim_team = GetClientTeam(victim);
        new attacker_team = GetClientTeam(attacker);
        if (victim_team != attacker_team && victim != attacker && ValidPlayer(attacker, true) && ValidPlayer(victim))
        {
            for (new i=0;i<MAXPLAYERS;i++)           
            {
                if (W3HasAura(AuraID,i,ilevel) && GetClientTeam(i) == attacker_team)
                {
                    new bonusxp = W3GetKillXP(attacker, W3GetTotalLevels(attacker) - W3GetTotalLevels(victim));
                    bonusxp = RoundFloat(FloatDiv(float(bonusxp), 10.0));
                    if (bonusxp > 40)
                        bonusxp = 40;
                    if (bonusxp > 0)
                    {
                        if (War3_GetRace(i) == thisRaceID)
                        {
                            W3GiveXPGold(i,XPAwardByGeneric,0,1,"Your armada got a kill!");
                        }
                        else
                        {
                            W3GiveXPGold(i,XPAwardByGeneric,bonusxp,0,"Your armada got a kill!");
                        }
                    }
                }
            }
        }
    }
}



public BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client_userid = GetEventInt(event, "userid");    
    new client = GetClientOfUserId(client_userid);
    if(ValidPlayer(client, true) && (War3_GetRace( client ) == thisRaceID) )
    {
        new skill_cannon = War3_GetSkillLevel(client, thisRaceID, SKILL_CANNON);
        if (skill_cannon > 0)
        {
            new our_team = GetClientTeam(client);
            new radius = g_iExplosionRadius[skill_cannon];
            
            new Float:Origin[3];
            Origin[0] = GetEventFloat(event,"x");
            Origin[1] = GetEventFloat(event,"y");
            Origin[2] = GetEventFloat(event,"z");
                
            TE_SetupExplosion(Origin, g_iExplosionModel,10.0,1,0,g_iExplosionRadius[skill_cannon],160);
            TE_SendToAll();
            
            
            new bool:friendlyfire = GetConVarBool(FindConVar("mp_friendlyfire"));
            new Float:location_check[3];
            
            g_iBulletCounter += 1;
            for(new x=1;x<=MaxClients;x++)
            {
                if(ValidPlayer(x,true)&&client!=x)
                {
                    new String:xName[256];
                    GetClientName(x, xName, sizeof(xName));
                    
    
                    
                    new team=GetClientTeam(x);
                    if(team==our_team&&!friendlyfire)
                        continue;
            
                    GetClientAbsOrigin(x,location_check);
                    new Float:distance=GetVectorDistance(Origin,location_check);
                    if(distance>radius)
                        continue;
            
                    if(!W3HasImmunity(x,Immunity_Skills) && g_bHitByExplosion == false)
                    {
                        g_bHitByExplosion = true;
                        CreateTimer(0.2,Exploded,x);
                        new Float:factor=(radius-distance)/radius;
                        new damage;
                        damage=RoundFloat(g_fExplosionDamage[skill_cannon]*factor);
                        War3_DealDamage(x,damage,client,_,"tankexplosion",W3DMGORIGIN_SKILL,W3DMGTYPE_MAGIC);
                        War3_ShakeScreen(x,3.0*factor,250.0*factor,30.0);
                        W3FlashScreen(x,RGBA_COLOR_RED);
                        W3PrintSkillDmgHintConsole(x, client, damage, SKILL_CANNON);
                        
                    }
            
                }            
            }
        }
    }
}


public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        
        if(vteam!=ateam)
        {
            //new race_attacker=War3_GetRace(attacker);
            new race_victim=War3_GetRace(victim);
            if(race_victim==thisRaceID )
            {
                new skill_armour = War3_GetSkillLevel(victim, thisRaceID, SKILL_ARMOUR);
                if (skill_armour>0)
                {
                    
                    War3_DamageModPercent(g_fDmgLevel[skill_armour]);
                    new Float:amount = (1-g_fDmgLevel[skill_armour]) * 100; 
                    PrintToConsole(attacker, "Damage Reduced by |%.2f| (percent) against Tank", amount);
                    PrintToConsole(victim, "Damage Reduced by |%.2f| (percent) by Tank", amount);
                }
            }
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

public Action:Exploded(Handle:timer,any:client)
{

    g_bHitByExplosion = false;
    
}


public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        giveWeapon( client, WEAPON_GIVE );
    }
}

giveWeapon(client, String:weapon[])
{
    for(new s=0; s < 6; s++)
    {
        new weaponEnt = GetPlayerWeaponSlot(client,s);
        if(weaponEnt > 0 && IsValidEdict(weaponEnt))
        {
            new String:weaponName[128];
            GetEntityClassname(weaponEnt,weaponName,sizeof(weaponName));
            if(StrEqual(weaponName,weapon))
            {
                return;
            }
        }
    }
    GivePlayerItem(client, weapon);
    return;
}

    

public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level)
{
    if(aura==AuraID && ValidPlayer(client))
    {
        if (GetClientTeam(client) == TEAM_CT)
        {
            if (inAura && ValidPlayer(client, true))
            {
                War3_SetBuff(client,iDamageMode,thisRaceID,1);
                W3SetPlayerColor(client,thisRaceID,0,204,255,20,GLOW_SKILL);    
                War3_SetBuff(client,fDamageModifier,thisRaceID,g_fDamageAuraAmount[level]);
                new String:temp[256];
                GetClientName(client, temp, sizeof(temp));
            }
            else if (ValidPlayer(client))
            {
                new String:temp[256];
                GetClientName(client, temp, sizeof(temp));
                W3ResetPlayerColor(client,thisRaceID);
                War3_SetBuff(client,fDamageModifier,thisRaceID,0);
            }
        }
        else if (GetClientTeam(client) == TEAM_T)
        {
            if (inAura && ValidPlayer(client, true))
            {
                War3_SetBuff(client,iDamageMode,thisRaceID,1);
                W3SetPlayerColor(client,thisRaceID,255,51,0,20,GLOW_SKILL);    
                War3_SetBuff(client,fDamageModifier,thisRaceID,g_fDamageAuraAmount[level]);
            }
            else if (ValidPlayer(client))
            {
                W3ResetPlayerColor(client,thisRaceID);
                War3_SetBuff(client,fDamageModifier,thisRaceID,0);
            }
        }
    }
}

public Action:Aura(Handle:timer,any:userid)
{
    for(new client=1;client<=MaxClients;client++)
    {
        if(ValidPlayer(client,true))
        {
            if(War3_GetRace(client)==thisRaceID)
            {
                new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_DAMAGEAURA);
                if(skill>0)
                {
                    GetClientAbsOrigin(client,g_fElectricTideOrigin[client]);
                    g_fElectricTideOrigin[client][2]+=15.0;
                
                    new ownerteam=GetClientTeam(client);
                    if (ownerteam == TEAM_T)
                    {
                        TE_SetupBeamRingPoint(g_fElectricTideOrigin[client], 20.0, g_fDamageBuffDistanceEffect, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {255,0,0,133}, 60, 0);
                        TE_SendToAll();
                        CreateTimer(0.5, SecondRingT,GetClientUserId(client));
                    }
                    else if (ownerteam == TEAM_CT)
                    {
                        TE_SetupBeamRingPoint(g_fElectricTideOrigin[client], 20.0, g_fDamageBuffDistanceEffect, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {0,0,255,133}, 60, 0);
                        TE_SendToAll();
                        CreateTimer(0.5, SecondRingCT,GetClientUserId(client));
                    }
                    
                    
                
                }
            }
        }
    }
}

public Action:SecondRingT(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    TE_SetupBeamRingPoint(g_fElectricTideOrigin[client], g_fDamageBuffDistanceEffect,20.0, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {255,0,0,133}, 60, 0);
    TE_SendToAll();
}

public Action:SecondRingCT(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    TE_SetupBeamRingPoint(g_fElectricTideOrigin[client], g_fDamageBuffDistanceEffect,20.0, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {0,0,255,133}, 60, 0);
    TE_SendToAll();
}