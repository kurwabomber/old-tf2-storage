/**
* File: War3Source_999_StarWars.sp
* Description: StarWars Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_LASER, SKILL_VAGA, SKILL_FEED, ULT_TELEPORT;

#define WEAPON_RESTRICT "weapon_knife"
#define WEAPON_GIVE "weapon_knife"

public Plugin:myinfo = 
{
    name = "War3Source Race - StarWars",
    author = "Remy Lebeau",
    description = "Ready's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};

// Laser
new bool:g_bHidden[MAXPLAYERS];
new Float:g_fDrugDuration[] = {0.0, 1.0, 2.0, 3.0, 5.0};
new Float:g_fStunDuration[] = {0.0, 0.5, 1.0, 1.5, 2.0};
new g_iLaserDamage[] = {0, 4, 6, 8, 10};
new Float:g_fLaserCoolDown = 5.0;
new String:fire[]="war3source/roguewizard/fire.wav";
new BurnSprite, MoonSprite;

// Camouflage
new Float:PushForce[5] = { 0.0, 0.7, 1.1, 1.3, 1.7 };
new String:UltOutstr[] = "weapons/physcannon/physcannon_claws_close.wav";
new String:UltInstr[] = "weapons/physcannon/physcannon_claws_open.wav";
new bool:bIsInvisible[MAXPLAYERS];
new m_vecBaseVelocity;
new Float:g_fVagaCoolDown = 10.0;
new SteamSprite;

//Feed
new g_iHealAmount[] = {0, 20, 30, 40 ,50};
new Skydome;


//Teleport
new Float:TeleRD[]={0.0,875.0,925.0,975.0,1000.0};
new bool:inteleportcheck[MAXPLAYERS];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new String:teleport_sound[]="war3source/archmage/teleport.wav";

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Star Wars [PRIVATE]","starwars");
    
    SKILL_LASER=War3_AddRaceSkill(thisRaceID,"Laser Gun","From the shadows, you shoot lasers at your enemy (+ability)",false,4);
    SKILL_VAGA=War3_AddRaceSkill(thisRaceID,"Camouflage","This can be like Vagabond's ultimate and you go 100% invisible with a 5/10 sec CD.",false,4);
    SKILL_FEED=War3_AddRaceSkill(thisRaceID,"Fed up","If you get a kill you heal up with 50HP at max level.",false,4);
    ULT_TELEPORT=War3_AddRaceSkill(thisRaceID,"Teleport "," You can teleport to your enemy, leveling this skill up increases the range of your teleport, with a 10sec CD",true,4);
    
    
    W3SkillCooldownOnSpawn(thisRaceID,SKILL_VAGA,5.0,_);
    W3SkillCooldownOnSpawn(thisRaceID,ULT_TELEPORT,5.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
}



public OnMapStart()
{
    BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");
    SteamSprite = PrecacheModel( "sprites/steam1.vmt" );
    Skydome=PrecacheModel("materials/sprites/physcannon_bluecore1b.vmt");
    MoonSprite = PrecacheModel( "sprites/strider_blackball.spr" );
    War3_AddCustomSound(fire, true);
    War3_PrecacheSound(fire);
    War3_AddCustomSound(teleport_sound, true);
    War3_PrecacheSound(teleport_sound);
    War3_PrecacheSound( UltInstr );
    War3_PrecacheSound( UltOutstr );
    

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
    if (War3_GetRace(client)==thisRaceID){
        if(!Silenced(client) &&  ValidPlayer(client, true)){
            if(ability==0 && pressed){
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_LASER,true))
                {
                    new target = War3_GetTargetInViewCone(client,9000.0,false,20.0);
                    new skill_laser=War3_GetSkillLevel(client,thisRaceID,SKILL_LASER);  
                    if(skill_laser>0)
                    {
                        if(g_bHidden[client])
                        {
                            EmitSoundToAll(fire,client);
                            War3_CooldownMGR(client,g_fLaserCoolDown,thisRaceID,SKILL_LASER);
                            if(target>0 && !W3HasImmunity(target,Immunity_Skills))
                            {
                                if(GetRandomFloat(0.0,1.0) < 0.5) // DRUG
                                {
                                    new Float:origin[3];
                                    new Float:targetpos[3];
                                    
                                    GetClientAbsOrigin(target,targetpos);
                                    GetClientAbsOrigin(client,origin);
                                    
                                    TE_SetupBeamPoints(origin, targetpos, BurnSprite, BurnSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {0,0,207,255}, 70);  
                                    TE_SendToAll();
                                    GetClientAbsOrigin(target,targetpos);
                                    targetpos[2]+=70;
                                    TE_SetupGlowSprite(targetpos,MoonSprite,1.0,1.9,255);
                                    TE_SendToAll();
                                    EmitSoundToAll(fire,target);
                                    War3_DealDamage(target,g_iLaserDamage[skill_laser],client,DMG_BULLET,"Laser");
                                    ServerCommand( "sm_drug #%d 1", GetClientUserId( target ) );
                                    CreateTimer( g_fDrugDuration[skill_laser], StopLaser, GetClientUserId(target) );
                                
                                }
                                else // STUN
                                {
                                    new Float:origin[3];
                                    new Float:targetpos[3];
                                    
                                    GetClientAbsOrigin(target,targetpos);
                                    GetClientAbsOrigin(client,origin);
                                    
                                    TE_SetupBeamPoints(origin, targetpos, BurnSprite, BurnSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {0,205,0,255}, 70);  
                                    TE_SendToAll();
                                    GetClientAbsOrigin(target,targetpos);
                                    targetpos[2]+=70;
                                    TE_SetupGlowSprite(targetpos,MoonSprite,1.0,1.9,255);
                                    TE_SendToAll();
                                    EmitSoundToAll(fire,target);
                                    War3_DealDamage(target,g_iLaserDamage[skill_laser],client,DMG_BULLET,"Laser");
                                    War3_SetBuff( target, bBashed, thisRaceID, true );
                                    CreateTimer( g_fStunDuration[skill_laser], StopLaser, GetClientUserId(target) );
                                
                                
                                }
                                
                                
                            }
                            else
                            {
                                new Float:origin[3];
                                new Float:targetpos[3];
                                
                                War3_GetAimEndPoint(client,targetpos);
                                GetClientAbsOrigin(client,origin);
                                TE_SetupBeamPoints(origin, targetpos, BurnSprite, BurnSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {0,0,0,255}, 70);  
                                TE_SendToAll();
                                War3_GetAimEndPoint(client,targetpos);
                                targetpos[2]+=70;
                                TE_SetupGlowSprite(targetpos,MoonSprite,1.0,1.9,255);
                                TE_SendToAll();
                            }
                        }
                        else
                        {
                            PrintHintText(client, "You must be camouflaged to use your laser");
                        }
                    }
                    else
                    {
                        PrintHintText(client, "Level your laser first");
                    }
                    
                    
                }
                
            }
            if(ability==1 && pressed)
            {
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_VAGA,true))
                {

                    new skill_vaga=War3_GetSkillLevel(client,thisRaceID,SKILL_VAGA);  
                    if(skill_vaga>0)
                    {
                        if( !bIsInvisible[client] )
                        {
                            ToggleInvisibility( client );
                            TeleportPlayer( client );
                            War3_CooldownMGR( client, g_fVagaCoolDown, thisRaceID, SKILL_VAGA);
                            g_bHidden[client] = true;
                        }
                        else
                        {
                            ToggleInvisibility( client );
                            War3_CooldownMGR( client, g_fVagaCoolDown, thisRaceID, SKILL_VAGA);
                            g_bHidden[client] = false;
                        }
                        
                        new Float:pos[3];
                        
                        GetClientAbsOrigin( client, pos );
                        
                        pos[2] += 50;
                        
                        TE_SetupGlowSprite( pos, SteamSprite, 1.0, 2.5, 130 );
                        TE_SendToAll();
                    }
                    else
                    {
                        PrintHintText(client, "Level Camouflage first");
                    }
                    
                    
                }
            }
            
        }
    }
}


public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true)){
		if(!Silenced(client)){
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_TELEPORT,true)){
				new ult_teleport=War3_GetSkillLevel(client,thisRaceID,ULT_TELEPORT);
				if(ult_teleport>0){
					TeleportPlayerView(client,TeleRD[ult_teleport]);
				}
				else
				{
					PrintHintText(client, "Level your Teleport first");
				}
			}
		}	
		else
		{
			PrintHintText(client, "You are silenced!");
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
	new race=War3_GetRace(attacker);
	new skill=War3_GetSkillLevel(attacker,thisRaceID,SKILL_FEED);
	if(race==thisRaceID && skill>0 && ValidPlayer( victim, false ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		War3_HealToMaxHP(attacker,g_iHealAmount[skill]);
		W3FlashScreen(attacker,RGBA_COLOR_GREEN,1.2,_,FFADE_IN);
		new Float:fVec[3] = {0.0,0.0,900.0};
		TE_SetupGlowSprite(fVec,Skydome,5.0,1.0,255);
		TE_SendToAll();
		CreateTesla(victim,1.0,3.0,10.0,60.0,3.0,4.0,600.0,"160","200","255 25 25","ambient/atmosphere/city_skypass1.wav","sprites/tp_beam001.vmt",true);
		
		PrintHintText(attacker,"Feed :\nGained %d Health",g_iHealAmount[skill]);
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
            W3ResetAllBuffRace( i, thisRaceID );
        }
    }
}



public Action:StopLaser( Handle:timer, any:user)
{
    new client = GetClientOfUserId(user);
    if( ValidPlayer( client ) )
    {
        ServerCommand( "sm_drug #%d 0", GetClientUserId( client ) );
        War3_SetBuff( client, bBashed, thisRaceID, false );
    }

}



stock StopInvis( client )
{
    if( bIsInvisible[client] )
    {
        bIsInvisible[client] = false;
        War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
        War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
        EmitSoundToAll( UltOutstr, client );
    }
}

stock StartInvis( client )
{
    if ( !bIsInvisible[client] )
    {
        bIsInvisible[client] = true;
        CreateTimer( 1.0, StartStop, client );
        War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.0 );
        EmitSoundToAll( UltInstr, client );
    }
}

public Action:StartStop( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        War3_SetBuff( client, bNoMoveMode, thisRaceID, true );
    }
}

stock ToggleInvisibility( client )
{
    if( bIsInvisible[client] )
    {
        StopInvis( client );
    }
    else
    {
        StartInvis( client );
    }
}

stock TeleportPlayer( client )
{
    if( client > 0 && IsPlayerAlive( client ) )
    {
        new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_VAGA );
        new Float:startpos[3];
        new Float:endpos[3];
        new Float:localvector[3];
        new Float:velocity[3];
        
        GetClientAbsOrigin( client, startpos );
        War3_GetAimEndPoint( client, endpos );
        
        localvector[0] = endpos[0] - startpos[0];
        localvector[1] = endpos[1] - startpos[1];
        localvector[2] = endpos[2] - startpos[2];
        
        velocity[0] = localvector[0] * PushForce[skill_level];
        velocity[1] = localvector[1] * PushForce[skill_level];
        velocity[2] = localvector[2] * PushForce[skill_level];
        
        SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
    }
}


bool:TeleportPlayerView(client,Float:distance)
{
	if(client>0){
		if(IsPlayerAlive(client)){
			new Float:angle[3];
			GetClientEyeAngles(client,angle);
			new Float:endpos[3];
			new Float:startpos[3];
			GetClientEyePosition(client,startpos);
			new Float:dir[3];
			GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(dir, distance);
			AddVectors(startpos, dir, endpos);
			GetClientAbsOrigin(client,oldpos[client]);
			ClientTracer=client;
			TR_TraceRayFilter(startpos,endpos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
			TR_GetEndPosition(endpos);			
			
			if(enemyImmunityInRange(client,endpos)){
				W3MsgEnemyHasImmunity(client);
				return false;
			}
			distance=GetVectorDistance(startpos,endpos);
			GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(dir, distance-33.0);
			AddVectors(startpos,dir,endpos);
			emptypos[0]=0.0;
			emptypos[1]=0.0;
			emptypos[2]=0.0;
			endpos[2]-=30.0;
			getEmptyLocationHull(client,endpos);
			if(GetVectorLength(emptypos)<1.0){
				//new String:buffer[100];
				//Format(buffer, sizeof(buffer), "%T", "NoEmptyLocation", client);
				PrintHintText(client, "No Empty Location");
				return false;
			}
			TeleportEntity(client,emptypos,NULL_VECTOR,NULL_VECTOR);
			EmitSoundToAll(teleport_sound,client);	
			teleportpos[client][0]=emptypos[0];
			teleportpos[client][1]=emptypos[1];
			teleportpos[client][2]=emptypos[2];
			inteleportcheck[client]=true;
			CreateTimer(0.14,checkTeleport,client);			
			return true;
		}
	}
	return false;
}

public Action:checkTeleport(Handle:h,any:client){
	inteleportcheck[client]=false;
	new Float:pos[3];	
	GetClientAbsOrigin(client,pos);
	
	if(GetVectorDistance(teleportpos[client],pos)<0.001){
		TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
	}
	else
	{	
		War3_CooldownMGR(client,20.0,thisRaceID,ULT_TELEPORT);
	}
}
public bool:AimTargetFilter(entity,mask)
{
	return !(entity==ClientTracer);
}

public bool:getEmptyLocationHull(client,Float:originalpos[3]){
	new Float:mins[3];
	new Float:maxs[3];
	GetClientMins(client,mins);
	GetClientMaxs(client,maxs);
	new absincarraysize=sizeof(absincarray);
	new limit=5000;
	for(new x=0;x<absincarraysize;x++){
		if(limit>0){
			for(new y=0;y<=x;y++){
				if(limit>0){
					for(new z=0;z<=y;z++){
						new Float:pos[3]={0.0,0.0,0.0};
						AddVectors(pos,originalpos,pos);
						pos[0]+=float(absincarray[x]);
						pos[1]+=float(absincarray[y]);
						pos[2]+=float(absincarray[z]);
						
						TR_TraceHullFilter(pos,pos,mins,maxs,MASK_SOLID,CanHitThis,client);
						if(TR_DidHit(_)){
						}
						else
						{
							AddVectors(emptypos,pos,emptypos);
							limit=-1;
							break;
						}
					
						if(limit--<0){
							break;
						}
					}
					
					if(limit--<0){
						break;
					}
				}
			}
			
			if(limit--<0){
				break;
			}
			
		}
		
	}

} 

public bool:CanHitThis(entityhit, mask, any:data)
{
	if(entityhit == data ){
		return false;
	}
	if(ValidPlayer(entityhit)&&ValidPlayer(data)&&War3_GetGame()==Game_TF&&GetClientTeam(entityhit)==GetClientTeam(data)){
		return false;
	}
	return true;
}


public bool:enemyImmunityInRange(client,Float:playerVec[3])
{
	new Float:otherVec[3];
	new team = GetClientTeam(client);

	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates)){
			GetClientAbsOrigin(i,otherVec);
			if(GetVectorDistance(playerVec,otherVec)<300){
				return true;
			}
		}
	}
	return false;
}             

    