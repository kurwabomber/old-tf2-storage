/**
* File: War3Source_999_Pokemon.sp
* Description: Agentkrispy's Races for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_SPEED, SKILL_ENTANGLE, SKILL_FIREBALL, SKILL_WATER, SKILL_LIGHTNING;



public Plugin:myinfo = 
{
    name = "War3Source Race - Ash Ketchum, Pokemon Master",
    author = "Remy Lebeau",
    description = "Agentkrispy's private race for War3Source",
    version = "1.2",
    url = "http://sevensinsgaming.com"
};

// General
new Float:g_fSpeed[] = {1.0, 1.1, 1.15, 1.2, 1.3};
new bool:g_bSummonedPokemon[MAXPLAYERS][4];
new Float:g_fCooldown = 25.0;
new Float:g_fAbilityTimer = 5.0;
new bool:g_bCanFireAbility[MAXPLAYERS];


//Vines
new bool:bIsEntangled[MAXPLAYERS];
new String:entangleSound[]="war3source/entanglingrootsdecay1.wav";
new Float:EntangleDistance[5]={0.0,200.0,300.0,400.0,500.0};

//Fire
new FireDamage[]={0,40,50,60,70};
new Float:FireTime[]={0.0,2.0,3.0,4.0,5.0};
new String:fire[]="war3source/roguewizard/fire.wav";

//Water
new WaterDamage[]={0,40,50,60,70};
new Float:WaterTime[]={0.0,2.0,3.0,4.0,5.0};
new Float:WaterSpoutDistance[] = {0.0, 50.0, 200.0, 350.0, 500.0};
new String:water[]="ambient/water_splash2.wav";
new String:waterCannon[]="weapons/rpg/rocketfire1.wav";



//Lightning
new LightningDamage[]={0,30,40,50,60};
new Float:LightningDistance[]={0.0,250.0,250.0,350.0,450.0};
new bool:bBeenHit[MAXPLAYERS][MAXPLAYERS];
new String:lightning[]="war3source/roguewizard/lightning.wav";
//new String:lightningMiss[]="weapons/ar2/ar2_empty.wav";

// Effects
new BeamSprite,HaloSprite;
new BurnSprite;


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Ash Ketchum, Pokemon Master [PRIVATE]","pokemon");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"The very best, like no one ever was","Let me show you my pokemans",false,4);
    SKILL_ENTANGLE=War3_AddRaceSkill(thisRaceID,"Bulbasaur","Bulbasaur, Vine Whip attack! (+ability)",false,4);
    SKILL_FIREBALL=War3_AddRaceSkill(thisRaceID,"Charmander","Charmander, use Flamethrower! (+ability1)",false,4);
    SKILL_WATER=War3_AddRaceSkill(thisRaceID,"Squirtle","Squirtle, Water Gun now! (+ability2)",false,4);
    SKILL_LIGHTNING=War3_AddRaceSkill(thisRaceID,"Pikachu","Pikachu, Thunderbolt! (+ultimate)",true,4);
    
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
}



public OnPluginStart()
{


}



public OnMapStart()
{
    BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");  
    BurnSprite=PrecacheModel("materials/sprites/fire1.vmt"); 
    War3_AddCustomSound(entangleSound);
    War3_AddCustomSound(fire);
    War3_PrecacheSound(water);
    War3_AddCustomSound(lightning);
    War3_PrecacheSound(waterCannon);
 //   War3_PrecacheSound(lightningMiss);
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
    g_bCanFireAbility[client] = true;
    

}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife");
        InitPassiveSkills(client);
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
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife");
        for(new i=0;i<=3;i++)
        {
            g_bSummonedPokemon[client][i] = false;
        }
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

public OnUltimateCommand(client,race,bool:pressed)
{
    if( race == thisRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new skill_lightning = War3_GetSkillLevel( client, thisRaceID, SKILL_LIGHTNING );
        if(skill_lightning>0)
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, SKILL_LIGHTNING, true ) )
            {
                if (g_bCanFireAbility[client] == true)
                {
                    for(new target=0;target<MAXPLAYERS;target++)
                    {
                        bBeenHit[client][target]=false;
                    }            
                    new target = War3_GetTargetInViewCone(client,LightningDistance[skill_lightning],false,20.0);
                    
                    if(target>0 && !W3HasImmunity(target,Immunity_Ultimates))
                    {
                        
                        War3_CooldownMGR(client,g_fCooldown,thisRaceID,SKILL_LIGHTNING);
                        new Float:distance=LightningDistance[skill_lightning];
                        new Float:target_pos[3];
                        new Float:start_pos[3];
                        
                        GetClientAbsOrigin(target,target_pos);                        
                        GetClientAbsOrigin(client,start_pos);
                        TE_SetupBeamPoints(start_pos,target_pos,BeamSprite,BeamSprite,0,35,1.0,40.0,40.0,0,40.0,{255,100,255,255},40);
                        TE_SendToAll();
                        EmitSoundToAll(lightning,client,SNDCHAN_AUTO);
                        CreateTimer(2.0, Stop, client);
                        DoChain(client,distance,LightningDamage[skill_lightning],true,0);
                        g_bCanFireAbility[client] = false;
                        CreateTimer(g_fAbilityTimer, AbilityTimer, client);
                    }
                    else
                    {
                        PrintHintText(client, "No target in range");
                        
                        //EmitSoundToAll(lightningMiss,client,SNDCHAN_AUTO);
                    }
                }
                else
                {
                    PrintHintText(client, "Pokemon are resting!");
                }
                        
                    
                    
            }
                
        }
        else
        {
            PrintHintText(client, "Level your Ultimate first");
        }
            
    }
}
       


public OnAbilityCommand(client,ability,bool:pressed)
{
    if (War3_GetRace(client)==thisRaceID)
    {
        if(!Silenced(client) &&  ValidPlayer(client, true))
        { 
            if (g_bCanFireAbility[client] == true)
            {


                // ENTANGLE
                if(ability==0 && pressed )
                {
                    if( War3_SkillNotInCooldown( client, thisRaceID, SKILL_ENTANGLE, true ) )
                    {
                        new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_ENTANGLE);
                        if(skill_level>0)
                        { 
                            War3_CooldownMGR(client,g_fCooldown,thisRaceID,SKILL_ENTANGLE);    
                            //g_bSummonedPokemon[client][0] = true;
                            new Float:distance=EntangleDistance[skill_level];
                            new targetList[64];
                            new our_team=GetClientTeam(client);
                            new Float:our_pos[3];
                            GetClientAbsOrigin(client,our_pos);
                            
                            TE_SetupBeamRingPoint(our_pos, 30.0, distance+50, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {0,100,0,255}, 60, 0);
                            TE_SendToAll();
                            CreateTimer(0.5, SecondRing,GetClientUserId(client));
                            
                            new curIter=0;
                            for(new x=1;x<=MAXPLAYERS;x++)
                            {
                                if(ValidPlayer(x,true)&&client!=x&&GetClientTeam(x)!=our_team&&!bIsEntangled[x]&&!W3HasImmunity(x,Immunity_Skills))
                                {
                                    new Float:x_pos[3];
                                    GetClientAbsOrigin(x,x_pos);
                                    if(GetVectorDistance(our_pos,x_pos)<=distance)
                                    {
                                        targetList[curIter]=x;
                                        ++curIter;
                                    }
                                }
                            }
                            
                            
                            for(new x=0;x<MAXPLAYERS;x++)
                            {
                                if(targetList[x]==0)
                                    break;
                            
                                bIsEntangled[targetList[x]]=true;
                                War3_SetBuff(targetList[x],bNoMoveMode,thisRaceID,true);
                                new Float:entangle_time=5.0;
                                CreateTimer(entangle_time,StopEntangle,GetClientUserId(targetList[x]));
                                new Float:effect_vec[3];
                                GetClientAbsOrigin(targetList[x],effect_vec);
                                effect_vec[2]+=15.0;
                                TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,50.0,{0,255,0,255},0,0);
                                TE_SendToAll();
                                effect_vec[2]+=15.0;
                                TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,50.0,{0,255,0,255},0,0);
                                TE_SendToAll();
                                effect_vec[2]+=15.0;
                                TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,50.0,{0,255,0,255},0,0);
                                TE_SendToAll(); 
                                new String:name[64];
                                GetClientName(targetList[x],name,64);
                                War3_ChatMessage(targetList[x],"You have been entangled");
                                EmitSoundToAll(entangleSound,targetList[x]);
                                EmitSoundToAll(entangleSound,targetList[x]);
                                
                                PrintHintText(client,"ENTANGLE!");
                                g_bCanFireAbility[client] = false;
                                CreateTimer(g_fAbilityTimer, AbilityTimer, client);
                            }
                            
                            
                        }
                    }
                    
                }
                
                // FIREBALL
                if(ability==1 && pressed)
                {
                    if( War3_SkillNotInCooldown( client, thisRaceID, SKILL_FIREBALL, true ) )
                    {
                        
                        
                        new target = War3_GetTargetInViewCone(client,9000.0,false,20.0, SkillFilter);
                        new skill_fire=War3_GetSkillLevel(client,thisRaceID,SKILL_FIREBALL);
                        
                        if(skill_fire>0)
                        {     
                            EmitSoundToAll(fire,client);
                            War3_CooldownMGR(client,g_fCooldown,thisRaceID,SKILL_FIREBALL);    
                            //g_bSummonedPokemon[client][1] = true;
                            if(target>0)
                            {
                                
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
                            g_bCanFireAbility[client] = false;
                            CreateTimer(g_fAbilityTimer, AbilityTimer, client);
                        }      
                    
                        else
                        {
                            PrintHintText(client, "Level your fireball first");
                        }
                    
                    }
                    
                }
                
                
                // WATERSPOUT
                if(ability==2 && pressed)
                {
                    if( War3_SkillNotInCooldown( client, thisRaceID, SKILL_WATER, true ) )
                    {
                        new skill_water=War3_GetSkillLevel(client,thisRaceID,SKILL_WATER);
                        
                        if(skill_water>0)
                        {   
                            War3_CooldownMGR(client,g_fCooldown,thisRaceID,SKILL_WATER);    
                            EmitSoundToAll(water,client);
                            //g_bSummonedPokemon[client][2] = true;
                            new Float:distance=WaterSpoutDistance[skill_water];
                            new targetList[64];
                            new our_team=GetClientTeam(client);
                            new Float:our_pos[3];
                            GetClientAbsOrigin(client,our_pos);
                            
                            
                            
                            new curIter=0;
                            
                            for(new x=1;x<=MAXPLAYERS;x++)
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
                                    
                                War3_DealDamage(targetList[x],WaterDamage[skill_water],client,DMG_BULLET,"Waterhose");
                                
                                War3_SetBuff(targetList[x],fSlow,thisRaceID,0.7);
                                
                                CreateTimer(WaterTime[skill_water],StopSlow,GetClientUserId(targetList[x]));
                                W3SetPlayerColor( targetList[x], thisRaceID, 0, 0, 255, _, GLOW_SKILL );
                                W3FlashScreen(targetList[x],RGBA_COLOR_BLUE, 0.3, 0.4, FFADE_OUT);
                                
                                
    
                                War3_ChatMessage(targetList[x],"You have been hosed");
                                EmitSoundToAll(water,targetList[x]);
                                EmitSoundToAll(water,targetList[x]);
                                
                                PrintHintText(client,"Squirtle, WATER GUN NOW!");
                            }
    
                            // Waterspout effect
                            new Float:origin[3];
                            new Float:targetpos[3];
                            War3_GetAimEndPoint(client,targetpos);
                            GetClientAbsOrigin(client,origin);
        //                    TE_SetupBeamPoints(origin, targetpos, BeamSprite, HaloSprite, 0, 5, 1.0, 30.0, 40.0, 2, 2.0, {25,25,112,255}, 70);  
        //                    TE_SendToAll();
                            WaterEffects(client, RoundToFloor(distance));
                            g_bCanFireAbility[client] = false;
                            CreateTimer(g_fAbilityTimer, AbilityTimer, client);
    
                        }
                        else
                        {
                            PrintHintText(client, "Level your watergun first");
                        }
                    }
                }
            }
            else
            {
                PrintHintText(client, "Pokemon are resting!");
            }
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






/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/



public Action:StopEntangle(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    if(ValidPlayer(client))
    {
        bIsEntangled[client]=false;
        War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
    }
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

public Action:Stop(Handle:timer,any:client)
{
    StopSound(client,SNDCHAN_AUTO,lightning);
}

public Action:AbilityTimer(Handle:timer,any:client)
{
    if (ValidPlayer(client, true) && g_bCanFireAbility[client] == false)
    {
        g_bCanFireAbility[client] = true;
        PrintHintText (client, "Pokemon are ready to fight!");
    }
}



public DoChain(client,Float:distance,dmg,bool:first_call,last_target)
{
    new target=0;
    new Float:target_dist=distance+1.0;
    new caster_team=GetClientTeam(client);
    new Float:start_pos[3];
    new skill_lightning=War3_GetSkillLevel(client,thisRaceID,SKILL_LIGHTNING);
    
    if(last_target<=0)
        GetClientAbsOrigin(client,start_pos);
    else
        GetClientAbsOrigin(last_target,start_pos);
        
    for(new x=1;x<=MaxClients;x++){
        if(ValidPlayer(x,true)&&!bBeenHit[client][x]&&caster_team!=GetClientTeam(x)&&!W3HasImmunity(x,Immunity_Skills)){
            new Float:this_pos[3];
            
            GetClientAbsOrigin(x,this_pos);
            new Float:dist_check=GetVectorDistance(start_pos,this_pos);
            
            if(dist_check<=target_dist){
                target=x;
                target_dist=dist_check;
            }
            
        }
        
    }
    
    if(target>0){
        bBeenHit[client][target]=true;
        War3_DealDamage(target,LightningDamage[skill_lightning],client,DMG_ENERGYBEAM,"Forked Lightning");
        start_pos[2]+=30.0;
        new Float:target_pos[3];
        GetClientAbsOrigin(target,target_pos);
        target_pos[2]+=30.0;
        TE_SetupBeamPoints(start_pos,target_pos,BeamSprite,BeamSprite,0,35,1.0,40.0,40.0,0,40.0,{255,100,255,255},40);
        TE_SendToAll();
        EmitSoundToAll(lightning,target,SNDCHAN_AUTO);
        CreateTimer(2.0, Stop, target);
        new new_dmg=RoundFloat(float(dmg)*0.66);
        DoChain(client,distance,new_dmg,false,target);    
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


public Action:SecondRing(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    new Float:our_pos[3];
    GetClientAbsOrigin(client,our_pos);
    new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_ENTANGLE);
    new Float:distance=EntangleDistance[skill_level];                    
    TE_SetupBeamRingPoint(our_pos, distance+50,30.0, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {0,100,0,255}, 60, 0);
    TE_SendToAll();
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