/**
* File: War3Source_999_ShadowReaper.sp
* Description: Shadow Reaper Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_INVIS, SKILL_REGEN, SKILL_WARD, ULT_TELEPORT;

#define WEAPON_RESTRICT ""
#define WEAPON_GIVE ""

public Plugin:myinfo = 
{
    name = "War3Source Race - Shadow Reaper",
    author = "Remy Lebeau",
    description = "Kurama's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};



new Float:InvisibilityAlphaCS[5]={1.0,0.90,0.8,0.7,0.6};

//Cannibalize
new String:Nom[]="war3source/nomnom.mp3";
new Float:corpselocation[3][MAXPLAYERS][20];
new dietimes[MAXPLAYERS];
new cannibal[]={0,16,17,18,19,20};
new corpsehealth[MAXPLAYERS][20];
new bool:corpsedied[MAXPLAYERS][20];
new BeamSprite,HaloSprite;



// Wards
#define MAXWARDS 64*5
#define WARDRADIUS 95
#define WARDDAMAGE 15
#define WARDBELOW -2.0

new WardStartingArr[] = { 0, 1, 2, 3, 4};
new Float:WardLocation[MAXWARDS][3];
new CurrentWardCount[MAXPLAYERS];
new Float:LastWardRing[MAXWARDS];
new Float:LastWardClap[MAXWARDS];
new WardOwner[MAXWARDS];
new LightningSprite, PurpleGlowSprite;


// ULT_TELEPORT VARIABLES

new Float:TeleportDistance[]={0.0, 500.0, 600.0, 700.0, 800.0};
new TPFailCDResetToRace[MAXPLAYERSCUSTOM];
new TPFailCDResetToSkill[MAXPLAYERSCUSTOM];
new bool:inteleportcheck[MAXPLAYERS];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new Float:UltiCooldown = 30.0;

new String:teleport_sound[]="war3source/archmage/teleport.wav";

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Shadow Reaper [PRIVATE]","sreaper");
    
    SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Shadow Blend","Blend in the shadows",false,4);
    SKILL_REGEN=War3_AddRaceSkill(thisRaceID,"Shadows of regeneration","Feed on the shadows of ur victims",false,4);
    SKILL_WARD=War3_AddRaceSkill(thisRaceID,"Shadow Wards","Stepping into the shadows can be costly (+ability)",false,4);
    ULT_TELEPORT=War3_AddRaceSkill(thisRaceID,"Shadow Warp","Jump through shadows (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_TELEPORT,10.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_INVIS, fInvisibilitySkill, InvisibilityAlphaCS);
    
}



public OnPluginStart()
{
    HookEvent("round_start",EventRoundStart);
    CreateTimer(0.5,nomnomnom,_,TIMER_REPEAT);
    CreateTimer( 0.14, CalcWards, _, TIMER_REPEAT );
}


public OnMapStart()
{
    War3_AddCustomSound(Nom);
    War3_AddCustomSound(teleport_sound);
    BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
    LightningSprite = PrecacheModel( "sprites/lgtning.vmt" );
    PurpleGlowSprite = PrecacheModel( "sprites/purpleglow1.vmt" );
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
    War3_SetBuff(client, iAdditionalMaxHealthNoHPChange, thisRaceID, 50);
}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills( client );
    }
    else
    {
        RemoveWards( client );
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
    }
}

public OnWar3EventSpawn( client )
{
    RemoveWards( client );
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

public OnAbilityCommand( client, ability, bool:pressed )
{
    if( War3_GetRace( client ) == thisRaceID && ability == 0 && pressed && IsPlayerAlive( client ) )
    {
        new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_WARD );
        if( skill_level > 0 )
        {
            if( !Silenced( client ) && CurrentWardCount[client] < WardStartingArr[skill_level] )
            {
                CreateWard( client );
                CurrentWardCount[client]++;
                W3MsgCreatedWard( client, CurrentWardCount[client], WardStartingArr[skill_level] );
            }
            else
            {
                W3MsgNoWardsLeft( client );
            }
        }
    }
}

public CreateWard( client )
{
    for( new i = 0; i < MAXWARDS; i++ )
    {
        if( WardOwner[i] == 0 )
        {
            WardOwner[i] = client;
            GetClientAbsOrigin( client, WardLocation[i] );
            break;
        }
    }
}

public RemoveWards( client )
{
    for( new i = 0; i < MAXWARDS; i++ )
    {
        if( WardOwner[i] == client )
        {
            WardOwner[i] = 0;
            LastWardRing[i] = 0.0;
            LastWardClap[i] = 0.0;
        }
    }
    CurrentWardCount[client] = 0;
}

public Action:CalcWards( Handle:timer, any:userid )
{
    new client;
    for( new i = 0; i < MAXWARDS; i++ )
    {
        if( WardOwner[i] != 0 )
        {
            client = WardOwner[i];
            if( !ValidPlayer( client, true ) )
            {
                WardOwner[i] = 0;
                --CurrentWardCount[client];
            }
            else
            {
                WardEffectAndDamage( client, i );
            }
        }
    }
}

public WardEffectAndDamage( owner, wardindex )
{
    new ownerteam = GetClientTeam( owner );
    new beamcolor[] = { 0, 0, 200, 255 };
    if( ownerteam == 2 )
    {
        beamcolor[0] = 255;
        beamcolor[1] = 0;
        beamcolor[2] = 0;
        beamcolor[3] = 255;
    }
    
    new Float:start_pos[3];
    new Float:end_pos[3];
    new Float:tempVec1[] = { 0.0, 0.0, WARDBELOW };
    new Float:tempVec2[] = { 0.0, 0.0, WARDABOVE };
    
    AddVectors( WardLocation[wardindex], tempVec1, start_pos );
    AddVectors( WardLocation[wardindex], tempVec2, end_pos );

    TE_SetupBeamPoints( start_pos, end_pos, LightningSprite, LightningSprite, 0, GetRandomInt( 30, 100 ), 0.17, 20.0, 20.0, 0, 0.0, beamcolor, 0 );
    TE_SendToAll();
    
    if( LastWardRing[wardindex] < GetGameTime() - 0.25 )
    {
        LastWardRing[wardindex] = GetGameTime();
        TE_SetupBeamRingPoint( start_pos, 20.0, float( WARDRADIUS * 2 ), LightningSprite, LightningSprite, 0, 15, 1.0, 20.0, 1.0, beamcolor, 10, FBEAM_ISACTIVE );
        TE_SendToAll();
    }
    
    TE_SetupGlowSprite( end_pos, PurpleGlowSprite, 1.0, 1.25, 50 );
    TE_SendToAll();
    
    new Float:BeamXY[3];
    for( new x = 0; x < 3; x++ ) BeamXY[x] = start_pos[x];
    new Float:BeamZ = BeamXY[2];
    BeamXY[2] = 0.0;
    
    new Float:VictimPos[3];
    new Float:tempZ;
    for( new i = 1; i <= MaxClients; i++ )
    {
        if( ValidPlayer( i, true ) && GetClientTeam(i) != ownerteam )
        {
            GetClientAbsOrigin( i, VictimPos );
            tempZ = VictimPos[2];
            VictimPos[2] = 0.0;
            
            if( GetVectorDistance( BeamXY, VictimPos ) < WARDRADIUS )
            {
                if( tempZ > BeamZ + WARDBELOW && tempZ < BeamZ + WARDABOVE )
                {
                    if(W3HasImmunity(i,Immunity_Wards))
                    {
                        W3MsgSkillBlocked(i,_,"Wards");
                    }
                    else if(W3HasImmunity(i,Immunity_Skills))
                    {
                        W3MsgSkillBlocked(i,_,"Wards");        
                    }
                    else
                    {
                        if( LastWardClap[wardindex] < GetGameTime() - 1 )
                        {
                            new DamageScreen[4];
                            new Float:pos[3];
                            
                            GetClientAbsOrigin( i, pos );
                            
                            DamageScreen[0] = beamcolor[0];
                            DamageScreen[1] = beamcolor[1];
                            DamageScreen[2] = beamcolor[2];
                            DamageScreen[3] = 50;
                            
                            W3FlashScreen( i, DamageScreen );
                            
                            War3_DealDamage( i, WARDDAMAGE, owner, DMG_ENERGYBEAM, "wards", _, W3DMGTYPE_MAGIC );
                            
                            War3_SetBuff( i, fSlow, thisRaceID, 0.7 );
                            
                            CreateTimer( 2.0, StopSlow, i );
                            
                            pos[2] += 40;
                            
                            TE_SetupBeamPoints( start_pos, pos, LightningSprite, LightningSprite, 0, 0, 1.0, 10.0, 20.0, 0, 0.0, { 255, 150, 70, 255 }, 0 );
                            TE_SendToAll();
                            
                            PrintToChat( i, "\x05: \x03You got hit by a shadow ward." );
                            
                            LastWardClap[i] = GetGameTime();
                        }
                    }
                }
            }
        }
    }
}

public Action:StopSlow( Handle:timer, any:client )
{
    if( ValidPlayer( client ) )
    {
        War3_SetBuff( client, fSlow, thisRaceID, 1.0 );
    }
}




public OnUltimateCommand(client,race,bool:pressed)
{
	if( race == thisRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
	{
		new skill_tp = War3_GetSkillLevel( client, thisRaceID, ULT_TELEPORT );
		if(skill_tp>0)
		{
				if(War3_SkillNotInCooldown(client,thisRaceID, ULT_TELEPORT,true)) //not in the 0.2 second delay when we check stuck via moving
				{
					new bool:success = Teleport(client,TeleportDistance[skill_tp]);
					if(success)
					{
						TPFailCDResetToRace[client]=thisRaceID;
						TPFailCDResetToSkill[client]=ULT_TELEPORT;
						
						War3_CooldownMGR(client,UltiCooldown,thisRaceID,ULT_TELEPORT,_,_);
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
    new deaths=dietimes[victim];
    dietimes[victim]++;
    corpsedied[victim][deaths]=true;
    corpsehealth[victim][deaths]=60;
    new Float:pos[3];
    War3_CachedPosition(victim,pos);
    corpselocation[0][victim][deaths]=pos[0];
    corpselocation[1][victim][deaths]=pos[1];
    corpselocation[2][victim][deaths]=pos[2];
    for(new client=0;client<=MaxClients;client++){
        if(War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true)){
            TE_SetupBeamRingPoint(pos,25.0,75.0,BeamSprite,HaloSprite,0,15,6.0,20.0,3.0,{178,34,34,255},20,0);
            TE_SendToClient(client);
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

public EventRoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
    resetcorpses();
}

public Action:nomnomnom(Handle:timer)
{
    for(new client=0;client<=MaxClients;client++){
        if(War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true)){
            new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_REGEN);
            if(skill_level>0){
                for(new corpse=0;corpse<=MaxClients;corpse++){
                    for(new deaths=0;deaths<=19;deaths++){
                        if(corpsedied[corpse][deaths]==true){
                            new Float:corpsepos[3];
                            new Float:clientpos[3];
                            GetClientAbsOrigin(client,clientpos);
                            corpsepos[0]=corpselocation[0][corpse][deaths];
                            corpsepos[1]=corpselocation[1][corpse][deaths];
                            corpsepos[2]=corpselocation[2][corpse][deaths];
                            
                            if(GetVectorDistance(clientpos,corpsepos)<50){
                                if(corpsehealth[corpse][deaths]>=0){
                                    EmitSoundToAll(Nom,client);
                                    W3FlashScreen(client,{155,0,0,40},0.1);
                                    corpsehealth[corpse][deaths]-=5;
                                    new addhp1=cannibal[skill_level];
                                    War3_HealToMaxHP(client,addhp1);
                                }
                            }
                            else
                            {
                                corpsehealth[corpse][deaths]-=5;
                            }
                        }
                    }
                }
            }
        }
    }
}

    
public resetcorpses()
{
    for(new client=0;client<=MaxClients;client++){
        for(new deaths=0;deaths<=19;deaths++){
            corpselocation[0][client][deaths]=0.0;
            corpselocation[1][client][deaths]=0.0;
            corpselocation[2][client][deaths]=0.0;
            dietimes[client]=0;
            corpsehealth[client][deaths]=0;
            corpsedied[client][deaths]=false;
        }
    }
}


/***************************************************************************
*
*
*                TELEPORT FUNCTIONS
*
*
***************************************************************************/




bool:Teleport(client,Float:distance){
	if(!inteleportcheck[client])
	{
		
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
		
		new Float:distanceteleport=GetVectorDistance(startpos,endpos);
		if(distanceteleport<200.0){
			
			
			PrintHintText(client,"Distance too short.");
			return false;
		}
		GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);///get dir again
		ScaleVector(dir, distanceteleport-33.0);
		
		AddVectors(startpos,dir,endpos);
		emptypos[0]=0.0;
		emptypos[1]=0.0;
		emptypos[2]=0.0;
		
		endpos[2]-=30.0;
		getEmptyLocationHull(client,endpos);
		
		if(GetVectorLength(emptypos)<1.0){
			
			PrintHintText(client,"NoEmptyLocation");
			return false; //it returned 0 0 0
		}
		
		
		TeleportEntity(client,emptypos,NULL_VECTOR,NULL_VECTOR);
		EmitSoundToAll(teleport_sound,client);
		EmitSoundToAll(teleport_sound,client);
		
		
		
		teleportpos[client][0]=emptypos[0];
		teleportpos[client][1]=emptypos[1];
		teleportpos[client][2]=emptypos[2];
		
		inteleportcheck[client]=true;
		CreateTimer(0.14,checkTeleport,client);
		
		
		
		
		
		
		return true;
	}

	return false;
}
public Action:checkTeleport(Handle:h,any:client){
	inteleportcheck[client]=false;
	new Float:pos[3];
	
	GetClientAbsOrigin(client,pos);
	
	if(GetVectorDistance(teleportpos[client],pos)<0.001)//he didnt move in this 0.1 second
	{
		TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
		PrintHintText(client,"CantTeleportHere");
		War3_CooldownReset(client,TPFailCDResetToRace[client],TPFailCDResetToSkill[client]);
		
		
	}
	else{
		
		
		PrintHintText(client,"Teleported");
		
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
						//new ent;
						if(!TR_DidHit(_))
						{
							AddVectors(emptypos,pos,emptypos); ///set this gloval variable
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
	if(entityhit == data )
	{// Check if the TraceRay hit the itself.
		return false; // Don't allow self to be hit, skip this result
	}
	if(ValidPlayer(entityhit)&&ValidPlayer(data)&&War3_GetGame()==Game_TF&&GetClientTeam(entityhit)==GetClientTeam(data)){
		return false; //skip result, prend this space is not taken cuz they on same team
	}
	return true; // It didn't hit itself
}


public bool:enemyImmunityInRange(client,Float:playerVec[3])
{
	//ELIMINATE ULTIMATE IF THERE IS IMMUNITY AROUND
	new Float:otherVec[3];
	new team = GetClientTeam(client);
	
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates))
		{
			GetClientAbsOrigin(i,otherVec);
			if(GetVectorDistance(playerVec,otherVec)<350)
			{
				return true;
			}
		}
	}
	return false;
}             


