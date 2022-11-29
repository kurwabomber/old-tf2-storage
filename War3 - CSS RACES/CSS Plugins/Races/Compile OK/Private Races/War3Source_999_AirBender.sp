/**
* File: War3Source_999_AirBender.sp
* Description: AirBender Race - JAs8621's private race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/RemyFunctions"

new thisRaceID;
new SKILL_SPEED, SKILL_POWER, SKILL_SWITCH, ULT_RANDOM;

#define WEAPON_RESTRICT "weapon_knife"
#define WEAPON_GIVE ""

public Plugin:myinfo = 
{
    name = "War3Source Race - The Last Airbender",
    author = "Remy Lebeau",
    description = "jas8621's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.1, 1.2, 1.2, 1.3 };
new g_iPlayerElement[MAXPLAYERS];
new g_bKnifeDamageCap[MAXPLAYERS];
new Float:g_fUltCooldown[] = {0.0, 45.0, 40.0, 35.0, 30.0};
new Float:g_fSwitchCooldown[] = {0.0, 50.0, 40.0, 30.0, 20.0};
new Float:AbilityCooldownTime=40.0;
new Handle:g_hElementMenu = INVALID_HANDLE;

//Air
new g_iAirDamage[] = {0, 5, 10, 15, 20};
new Float:g_fAirDuration = 5.0;
new Float:g_fAirRadius=300.0;
new Float:g_fAirOrigin[MAXPLAYERSCUSTOM][3];

new bool:HitOnForwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; //[VICTIM][ATTACKER]
new bool:HitOnBackwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM];
new HaloSprite, BeamSprite;

//Water
new WaterDamage[]={0,10,20,30,40};
new Float:WaterTime[]={0.0,2.0,3.0,4.0,5.0};
new Float:WaterSpoutDistance[] = {0.0, 50.0, 200.0, 350.0, 500.0};
new String:water[]="ambient/water_splash2.wav";
new String:waterCannon[]="weapons/rpg/rocketfire1.wav";

//Earth
new Float:g_fEarthTime[] = {0.0, 4.0, 6.0, 8.0, 10.0};

//Fire
new FireDamage[]={0,30,35,40,45,50,55,60,65,70,75};
new Float:FireTime[]={0.0,0.5,1.0,1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0};
new String:fire[]="war3source/roguewizard/fire.wav";
new BurnSprite;

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("The Last Airbender [PRIVATE]","airbender");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Air scooter","After mastering the thirty-six tiers of airbending Aang invented a new airbending technique, the 'air scooter'",false,4);
    SKILL_POWER=War3_AddRaceSkill(thisRaceID,"Master of the elements (+ability)","The avatar shows of his mastery of the elements using this attack",false,4);
    SKILL_SWITCH=War3_AddRaceSkill(thisRaceID,"Elemental master(+ability1)","Choose which element you shall master",false,4);
    ULT_RANDOM=War3_AddRaceSkill(thisRaceID,"Avatar spirit (+ultimate)","Aang is able to recall spells used by his ancestors through the avarat spirit",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_RANDOM,15.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
}



public OnMapStart()
{
    BeamSprite = War3_PrecacheBeamSprite();
    HaloSprite = War3_PrecacheHaloSprite();
    BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");
    War3_PrecacheSound(water);
    War3_PrecacheSound(waterCannon);
    War3_AddCustomSound(fire);
    g_hElementMenu = BuildSkillMenu();
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
    g_bKnifeDamageCap[client] = true;
    Buffs(client,false,false);
}

Buffs(client, bool:active=false, bool:random=false )
{
    if(!active)
    {
        W3ResetAllBuffRace( client, thisRaceID );
        new skill_speed=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
        switch (g_iPlayerElement[client])
        {
            case 0:
            {
                War3_SetBuff(client,fMaxSpeed,thisRaceID,g_fSpeed[skill_speed]);
                HUD_Add(GetClientUserId(client), "\nElement : Air");
            }
            case 1:
            {
                War3_SetBuff(client,fMaxSpeed,thisRaceID,g_fSpeed[skill_speed]);
                War3_SetBuff( client, iAdditionalMaxHealth, thisRaceID, 25);
                HUD_Add(GetClientUserId(client), "\nElement : Water");
            }
            case 2:
            {
                new Float:speedtemp = g_fSpeed[skill_speed] - 0.3;
                War3_SetBuff(client,fMaxSpeed,thisRaceID,speedtemp);
                SetEntProp( client, Prop_Send, "m_ArmorValue", 100, 1 );
                HUD_Add(GetClientUserId(client), "\nElement : Earth");
            }
            case 3:
            {
                War3_SetBuff(client,fMaxSpeed,thisRaceID,g_fSpeed[skill_speed]);
                War3_SetBuff( client, iAdditionalMaxHealth, thisRaceID, -20);
                g_bKnifeDamageCap[client] = false;
                HUD_Add(GetClientUserId(client), "\nElement : Fire");
            }
        }
    }
    else
    {
        new choice_counter = 0;
        if(!random)
        {
            choice_counter = g_iPlayerElement[client];
        }
        else
        {
            choice_counter = GetRandomInt(0,3);
        }
        //new team = GetClientTeam(client);
        switch (choice_counter)
        {
            case 0:
            {
                //  air Razor wind - enemies within ???? range are hit with wind as sharp as razors dealing 5,10,15,20 damage per second for 5 seconds
                GetClientAbsOrigin(client,g_fAirOrigin[client]);
                g_fAirOrigin[client][2]+=15.0;
                
                for(new i=1;i<=MaxClients;i++){
                    HitOnBackwardTide[i][client]=false;
                    HitOnForwardTide[i][client]=false;
                }
                TE_SetupBeamRingPoint(g_fAirOrigin[client], 20.0, g_fAirRadius+50, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {255,0,255,133}, 60, 0);
                TE_SendToAll();
                
                CreateTimer(0.1, StunLoop,GetClientUserId(client));
                                
                CreateTimer(0.5, SecondRing,GetClientUserId(client));
                
                
                PrintHintText(client,"Air Blast!");    
                        
            }
            case 1:
            {
                //water Tidal wave - players in a cone (rw fireball size) and within ???? range are hit with a tidal wave dealing 10,20,30,40 damage and slowing them for 5 seconds
                new skill_water=War3_GetSkillLevel(client,thisRaceID,SKILL_POWER);
                EmitSoundToAll(water,client);
                //g_bSummonedPokemon[client][2] = true;
                new Float:distance=WaterSpoutDistance[skill_water];
                new targetList[64];
                new our_team=GetClientTeam(client);
                new Float:our_pos[3];
                GetClientAbsOrigin(client,our_pos);

                new curIter=0;
                
                for(new x=0;x<=MAXPLAYERS;x++)
                {
                    if(ValidPlayer(x,true)&&client!=x&&GetClientTeam(x)!=our_team&&!W3HasImmunity(x,Immunity_Skills))
                    {
                        new Float:x_pos[3];
                        GetClientAbsOrigin(x,x_pos);
                        if(GetVectorDistance(our_pos,x_pos)<=distance )
                        {
                            
                            if (ClientViews(client, x, distance, 0.6))
                            {
                                targetList[curIter]=x;
                                ++curIter;
                            }
                        }
                    }
                }
                
                
                for(new x=0;x<MAXPLAYERS;x++)
                {
                    if(targetList[x]==0)
                        break;
                        
                    War3_DealDamage(targetList[x],WaterDamage[skill_water],client,DMG_BULLET,"Water Elemental");
                    
                    War3_SetBuff(targetList[x],fSlow,thisRaceID,0.7);
                    
                    CreateTimer(WaterTime[skill_water],StopSlow,GetClientUserId(targetList[x]));
                    W3SetPlayerColor( targetList[x], thisRaceID, 0, 0, 255, _, GLOW_SKILL );
                    W3FlashScreen(targetList[x],RGBA_COLOR_BLUE, 0.3, 0.4, FFADE_OUT);

                    War3_ChatMessage(targetList[x],"You have been hosed");
                    EmitSoundToAll(water,targetList[x]);
                    EmitSoundToAll(water,targetList[x]);
                    
                    PrintHintText(client,"Water Blast!");
                }

                // Waterspout effect
                new Float:origin[3];
                new Float:targetpos[3];
                War3_GetAimEndPoint(client,targetpos);
                GetClientAbsOrigin(client,origin);
                WaterEffects(client, RoundToFloor(distance));
            }
            case 2:
            {
                //earth Wall of earth - player is immobilised and becomes invunrable for 4,6,8,10
                new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_POWER);
                CreateTimer(g_fEarthTime[skill_level],StopEarth,GetClientUserId(client));
                War3_SetBuff(client,bNoMoveMode,thisRaceID, true);
                War3_SetBuff(client,fDodgeChance,thisRaceID,1.0);
                War3_SetBuff(client,bDodgeMode,thisRaceID,0);
                W3SetPlayerColor( client, thisRaceID, 255, 0, 0, _, GLOW_SKILL );
                PrintHintText(client,"Earth Element!");

            }
            case 3:
            {
                //fire Fireball - rougue wiz fireball dealing 30,40,50,60 damage
                new target = War3_GetTargetInViewCone(client,9000.0,false,20.0);
                new skill_fire=War3_GetSkillLevel(client,thisRaceID,SKILL_POWER);

                EmitSoundToAll(fire,client);
                if(target>0 && !W3HasImmunity(target,Immunity_Skills)){
                    new Float:origin[3];
                    new Float:targetpos[3];
                    
                    GetClientAbsOrigin(target,targetpos);
                    GetClientAbsOrigin(client,origin);
                    TE_SetupBeamPoints(origin, targetpos, BurnSprite, BurnSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {255,128,35,255}, 70);  
                    TE_SendToAll();
                    GetClientAbsOrigin(target,targetpos);
                    targetpos[2]+=70;
                    TE_SetupGlowSprite(targetpos,BurnSprite,1.0,1.9,255);
                    TE_SendToAll();
                    EmitSoundToAll(fire,target);
                    War3_DealDamage(target,FireDamage[skill_fire],client,DMG_BULLET,"Fireball");
                    IgniteEntity(target, FireTime[skill_fire]);
                }
                else
                {
                    new Float:origin[3];
                    new Float:targetpos[3];
                    War3_GetAimEndPoint(client,targetpos);
                    GetClientAbsOrigin(client,origin);
                    TE_SetupBeamPoints(origin, targetpos, BurnSprite, BurnSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {255,128,35,255}, 70);  
                    TE_SendToAll();
                    War3_GetAimEndPoint(client,targetpos);
                    targetpos[2]+=70;
                    TE_SetupGlowSprite(targetpos,BurnSprite,1.0,1.9,255);
                    TE_SendToAll();
                }
                    

            }
        }
    
    }


}

public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        g_iPlayerElement[client] = 0;
        InitPassiveSkills( client );
    }
    else
    {
        g_bKnifeDamageCap[client] = false;
        HUD_Add(GetClientUserId(client), "");
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
    }
}

public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {    
        InitPassiveSkills( client );
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
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_POWER,true))
                {
                    new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_POWER);
                    if(skill_level>0)
                    {      
                        Buffs(client, true, false );
                        War3_CooldownMGR(client,AbilityCooldownTime,thisRaceID,SKILL_POWER,_,_);
                    }
                    else
                    {
                        PrintHintText(client, "Level Master of the Elements first");
                    }
                }
            }
            if(ability==1 && pressed)
            {
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_SWITCH,true))
                {
                    new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_SWITCH);
                    if(skill_level>0)
                    {     
                        g_iPlayerElement[client] = GetRandomInt(0,3);
                        InitPassiveSkills(client);      
                        //DisplayMenu(g_hElementMenu, client, MENU_TIME_FOREVER);
                        War3_CooldownMGR(client,g_fSwitchCooldown[skill_level],thisRaceID,SKILL_SWITCH,_,_);
                    }
                    else
                    {
                        PrintHintText(client, "Level Elemental Mastery first");
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


public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && ValidPlayer( client,true ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_RANDOM );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_RANDOM, true ))
            {
                Buffs(client, true, true );
                War3_CooldownMGR( client, g_fUltCooldown[ult_level], thisRaceID, ULT_RANDOM, _, _ );
            }
        }
        else
        {
            W3MsgUltNotLeveled( client );
        }
    }
}



Handle:BuildSkillMenu()
{
    new Handle:menu = CreateMenu(Menu_ChangeElement);

    AddMenuItem(menu, "0", "Air");
    AddMenuItem(menu, "1", "Water");
    AddMenuItem(menu, "2", "Earth");
    AddMenuItem(menu, "3", "Fire");


    SetMenuTitle(menu, "Which Element will you Master?");
 
    return menu;
}

public Menu_ChangeElement(Handle:menu, MenuAction:action, client, selection)
{
    if (action == MenuAction_Select)
    {
        new String:info[32];
 
        /* Get item info */
        new bool:found = GetMenuItem(menu, selection, info, sizeof(info));
        PrintToConsole(client, "You selected item: %d (found? %d info: %s)", selection, found, info);
        
        g_iPlayerElement[client] = selection;   
        InitPassiveSkills(client);      
    }
}

/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			if(race_attacker==thisRaceID && g_bKnifeDamageCap[attacker])
			{
                if(damage>50.0)
                {
                    new String:weapon[32]; 
                    GetClientWeapon( attacker, weapon, 32 );
                    if( StrEqual( weapon, "weapon_knife" ) )
                    {
                        new Float:damagemod = 50.0/damage;
                        War3_DamageModPercent(damagemod);
                        //PrintToChatAll("DEBUG TEXT: DAMAGE SHOULD BE REDUCED: DAMAGE: |%d| MOD |$f|",damage, damagemod );
                        
                    }
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



public Action:SecondRing(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    TE_SetupBeamRingPoint(g_fAirOrigin[client], g_fAirRadius+50,20.0, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {255,0,255,133}, 60, 0);
    TE_SendToAll();
}

public Action:StunLoop(Handle:timer,any:userid)
{
    new attacker=GetClientOfUserId(userid);
    if(ValidPlayer(attacker) )
    {
        new team = GetClientTeam(attacker);
        new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_POWER );
        
        new Float:otherVec[3];
        for(new i=1;i<=MaxClients;i++)
        {
            if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Skills))
            {        
                GetClientAbsOrigin(i,otherVec);
                otherVec[2]+=30.0;
                new Float:victimdistance=GetVectorDistance(g_fAirOrigin[attacker],otherVec);
                if(victimdistance<g_fAirRadius)
                {
                    
                    CreateTimer(g_fAirDuration,stopStun,i);
                    War3_SetBuff(i, fHPDecay, thisRaceID, g_iAirDamage[skill_level]);
                    W3SetPlayerColor( i, thisRaceID, 255, 255, 0, _, GLOW_SKILL );

                }
            }
        }
    }
    
}
public Action:stopStun(Handle:timer,any:userid)
{
    War3_SetBuff(userid, fHPDecay, thisRaceID, 0.0);
    W3ResetPlayerColor( userid, thisRaceID );
} 


public Action:StopSlow(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    if(ValidPlayer(client))
    {
        War3_SetBuff(client,fSlow,thisRaceID,1.0);
        W3ResetPlayerColor( client, thisRaceID );
    }
}


public Action:StopEarth(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    if(ValidPlayer(client))
    {
        War3_SetBuff(client,bNoMoveMode,thisRaceID, false);
        War3_SetBuff(client,fDodgeChance,thisRaceID,0.0);
        W3ResetPlayerColor( client, thisRaceID );
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



    
// ----------------------------------------------------------------------------
// WaterEffects()
// ----------------------------------------------------------------------------


public WaterEffects(client,distance)
{
   					
    new Float:vAngles[3];
    new Float:vOrigin[3];
    new Float:aOrigin[3];
    new Float:AnglesVec[3];
    new String:tName[128];
    
    GetClientEyePosition(client, vOrigin);
    GetClientAbsOrigin(client, aOrigin);
    GetClientEyeAngles(client, vAngles);
    GetAngleVectors(vAngles, AnglesVec, NULL_VECTOR, NULL_VECTOR);
   
    
    // Ident the player
    Format(tName, sizeof(tName), "target%i", client);
    DispatchKeyValue(client, "targetname", tName);
    
    EmitSoundToAll(waterCannon,client,SNDCHAN_AUTO);
    
    // Create the Flame
    new String:flame_name[128];
    Format(flame_name, sizeof(flame_name), "Flame%i", client);
    new flame = CreateEntityByName("env_steam");
    DispatchKeyValue(flame,"targetname", flame_name);
    DispatchKeyValue(flame, "parentname", tName);
    DispatchKeyValue(flame,"SpawnFlags", "1");
    DispatchKeyValue(flame,"Type", "0");
    DispatchKeyValue(flame,"InitialState", "1");
    DispatchKeyValue(flame,"Spreadspeed", "10");
    DispatchKeyValue(flame,"Speed", "800");
    DispatchKeyValue(flame,"Startsize", "1200");
    DispatchKeyValue(flame,"EndSize", "1200");
    DispatchKeyValue(flame,"Rate", "15");
    DispatchKeyValue(flame,"JetLength", "400");
    DispatchKeyValue(flame,"RenderColor", "122 215 255");
    DispatchKeyValue(flame,"RenderAmt", "180");
    DispatchSpawn(flame);
    TeleportEntity(flame, aOrigin, vAngles, NULL_VECTOR);
    SetVariantString(tName);

    AcceptEntityInput(flame, "TurnOn");
    
    // Create the Heat Plasma
    new String:flame_name2[128];
    Format(flame_name2, sizeof(flame_name2), "Flame2%i", client);
    new flame2 = CreateEntityByName("env_steam");
    DispatchKeyValue(flame2,"targetname", flame_name2);
    DispatchKeyValue(flame2, "parentname", tName);
    DispatchKeyValue(flame2,"SpawnFlags", "1");
    DispatchKeyValue(flame2,"Type", "1");
    DispatchKeyValue(flame2,"InitialState", "1");
    DispatchKeyValue(flame2,"Spreadspeed", "10");
    DispatchKeyValue(flame2,"Speed", "600");
    DispatchKeyValue(flame2,"Startsize", "50");
    DispatchKeyValue(flame2,"EndSize", "400");
    DispatchKeyValue(flame2,"Rate", "10");
    DispatchKeyValue(flame2,"JetLength", "500");
    DispatchSpawn(flame2);
    TeleportEntity(flame2, aOrigin, vAngles, NULL_VECTOR);
    SetVariantString(tName);
    
    AcceptEntityInput(flame2, "TurnOn");
    
    new Handle:flamedata = CreateDataPack();
    CreateTimer(1.0, KillFlame, flamedata);
    WritePackCell(flamedata, flame);
    WritePackCell(flamedata, flame2);
}


public Action:KillFlame(Handle:timer, Handle:flamedata)
{
	ResetPack(flamedata);
	new ent1 = ReadPackCell(flamedata);
	new ent2 = ReadPackCell(flamedata);
	CloseHandle(flamedata);
	
	new String:classname[256];
	
	if (IsValidEntity(ent1))
    {
		AcceptEntityInput(ent1, "TurnOff");
		GetEdictClassname(ent1, classname, sizeof(classname));
		if (StrEqual(classname, "env_steam", false))
        {
            RemoveEdict(ent1);
        }
    }
	
	if (IsValidEntity(ent2))
    {
		AcceptEntityInput(ent2, "TurnOff");
		GetEdictClassname(ent2, classname, sizeof(classname));
		if (StrEqual(classname, "env_steam", false))
        {
            RemoveEdict(ent2);
        }
    }
}

// ----------------------------------------------------------------------------
// ClientViews()
// ----------------------------------------------------------------------------
stock bool:ClientViews(Viewer, Target, Float:fMaxDistance=0.0, Float:fThreshold=0.73)
{
    // Retrieve view and target eyes position
    decl Float:fViewPos[3];   GetClientEyePosition(Viewer, fViewPos);
    decl Float:fViewAng[3];   GetClientEyeAngles(Viewer, fViewAng);
    decl Float:fViewDir[3];
    decl Float:fTargetPos[3]; GetClientEyePosition(Target, fTargetPos);
    decl Float:fTargetDir[3];
    decl Float:fDistance[3];
    
    // Calculate view direction
    fViewAng[0] = fViewAng[2] = 0.0;
    GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);
    
    // Calculate distance to viewer to see if it can be seen.
    fDistance[0] = fTargetPos[0]-fViewPos[0];
    fDistance[1] = fTargetPos[1]-fViewPos[1];
    fDistance[2] = 0.0;
    if (fMaxDistance != 0.0)
    {
        if (((fDistance[0]*fDistance[0])+(fDistance[1]*fDistance[1])) >= (fMaxDistance*fMaxDistance))
            return false;
    }
    
    // Check dot product. If it's negative, that means the viewer is facing
    // backwards to the target.
    NormalizeVector(fDistance, fTargetDir);
    if (GetVectorDotProduct(fViewDir, fTargetDir) < fThreshold) return false;
    
    // Now check if there are no obstacles in between through raycasting
    new Handle:hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
    if (TR_DidHit(hTrace)) { CloseHandle(hTrace); return false; }
    CloseHandle(hTrace);
    
    // Done, it's visible
    return true;
}

// ----------------------------------------------------------------------------
// ClientViewsFilter()
// ----------------------------------------------------------------------------
public bool:ClientViewsFilter(Entity, Mask, any:Junk)
{
    if (Entity >= 1 && Entity <= MaxClients) return false;
    return true;
}  
