#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Mobility Man",
	author = "ABGar",
	description = "The Mobility Man race for War3Source.",
    version = "1.0"
};
//Added version counter. Not usually useful, but helps if you're making major changes to a publicly released race

new thisRaceID;

new SKILL_SMALL, SKILL_CONTROL, SKILL_BOUNCE, ULT_BLINK;

// SKILL_SMALL
new Float:SizeScale[]={1.0,0.9,0.8,0.7,0.6};

// SKILL_CONTROL
new Float:ControlDamage[]={1.0,0.85,0.7,0.6,0.5};//Be consistent with your significant figures :)
new Float:PushForce[]={0.0,700.0,900.0,1200.0,1500.0};
new Float:ControlCD[]={0.0,8.0,7.0,6.0,5.0};
new Float:BlindTime[]={0.0,0.5,1.0,1.5,2.0};
new Float:BlindChance[]={0.0,0.2,0.3,0.4,0.5};
new String:BlindSND[]="war3source/shadowstrikebirth.wav";

// SKILL_BOUNCE
new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity;
new Float:SkillLongJump[]={0.0,0.25,0.375,0.5,0.625};//Usually a more gradual effect curve is more intuitive to players, but I won't change this

// ULT_BLINK
new Float:TeleRD[]={0.0,150.0,200.0,300.0,400.0};//Usually a more gradual effect curve is more intuitive to players, but I won't change this
new Float:teleCD[]={0.0,19.0,16.0,13.0,10.0};
new bool:inteleportcheck[MAXPLAYERS];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new String:teleport_sound[]="war3source/blinkarrival.wav";




public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Mini Man [PRIVATE]","miniman");//Shortnames should be lower case
	SKILL_SMALL = War3_AddRaceSkill(thisRaceID,"Small Stature","Reduce your size (passive)",false,4);
	SKILL_CONTROL = War3_AddRaceSkill(thisRaceID,"Damage Control","Left click pushes the enemy, right click has a chance to blind the enemy (attack)",false,4);
	SKILL_BOUNCE = War3_AddRaceSkill(thisRaceID,"Grasshopper","Long Jump (passive)",false,4);
	ULT_BLINK = War3_AddRaceSkill(thisRaceID,"Blink","Teleport (+ultimate)",false,4);
	War3_CreateRaceEnd(thisRaceID);
}


public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace != thisRaceID )
	{
		War3_WeaponRestrictTo(client, thisRaceID, "");
		W3ResetAllBuffRace( client, thisRaceID );
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
	}
	else
	{
        if (ValidPlayer(client, true))//If they're alive, apply the buffs. Otherwise it's more optimized to wait for a spawn
        {
            InitPassiveSkills(client);//When you're repeating code, especially where buffs or initializations are concerned, you should keep it to a single function to make editing/maintenance easier.
        }
	}
}

public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client) == thisRaceID)
	{
		InitPassiveSkills(client);
	}
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    if (ValidPlayer(client,true) && race==thisRaceID)//Always consider if they should be alive, or the right race! Functions like SmallSize should only do what they're advertised to do, race checking should happen in event management unless necessary for the purpose of the function.
    {
        SmallSize(client);
    }
}

public OnMapStart()
{
	War3_PrecacheSound(teleport_sound);
	War3_PrecacheSound(BlindSND);
}

/* *************************************** (SKILL_SMALL) *************************************** */
public SmallSize(client)
{
    //Removed race check, that should be in the event control functions.
    //Removed level check, to allow scaling to normal size.
    new SizeLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_SMALL);
    SetEntPropFloat(client, Prop_Send, "m_flModelScale", SizeScale[SizeLevel]);
}

/* *************************************** (SKILL_CONTROL) *************************************** */
public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim, true) && ValidPlayer(attacker, true) && War3_GetRace(attacker)==thisRaceID && GetClientTeam(victim) != GetClientTeam(attacker) && attacker!=victim)//ValidPlayer is a much more condensed check (look in to War3Source_Interface). Also, don't nest if loops if you can avoid it (you can split checks over multiple lines if you want them organized). Also team checks should come early for optimization, unless you're looping through players and need to check team each time
	{
        new DamageLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_CONTROL);
        new String:weapon[32]; 
        GetClientWeapon(attacker,weapon,32);
        if(StrEqual(weapon,"weapon_knife") && DamageLevel>0 && !Silenced(attacker,true))//Silence check goes here, because it prints a hinttext by itself
        {
            if(!W3HasImmunity(victim,Immunity_Skills))
            {
                if(War3_SkillNotInCooldown(attacker,thisRaceID,SKILL_CONTROL,true))
                {
                    new buttons = GetClientButtons(attacker);
                    if (buttons & IN_ATTACK)//Don't use negative checks on a bitmask unless you want everything except that button. In this case, just check for IN_ATTACK
                    {
                        new Float:startpos[3];
                        new Float:endpos[3];
                        //new Float:localvector[3];
                        new Float:vector[3];
                        
                        GetClientAbsOrigin( attacker, startpos );
                        GetClientAbsOrigin( victim, endpos );
                        
                        /*localvector[0] = endpos[0] - startpos[0];
                        localvector[1] = endpos[1] - startpos[1];
                        localvector[2] = endpos[2] - startpos[2];*///Why bother with this at all, if you're using MakeVectorFromPoints?
                        MakeVectorFromPoints(startpos, endpos, vector);
                        NormalizeVector(vector, vector);
                        ScaleVector(vector, PushForce[DamageLevel]);
                        TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vector);//If you want it to always push a specific amount this is good. I prefer accounting for their current velocity so that fast or bunnyhopping races are affected less. I've attached the Push function from Element at the bottom of this file so you can see how that works :)
                        War3_CooldownMGR(attacker,ControlCD[DamageLevel],thisRaceID,SKILL_CONTROL,_,_);
                    }
                    else if (buttons & IN_ATTACK2)
                    {
                        if(GetRandomFloat(0.0,1.0)<=BlindChance[DamageLevel])//A function you might find interesting is W3Chance. The value you feed it is a chance to succeed between 0.0 and 1.0
                        {
                            W3FlashScreen(victim,{0,0,0,255},BlindTime[DamageLevel],_);
                            EmitSoundToAll(BlindSND,attacker);
                            War3_DamageModPercent(ControlDamage[DamageLevel]);
                            War3_CooldownMGR(attacker,ControlCD[DamageLevel],thisRaceID,SKILL_CONTROL,_,_);
                        }
                    }
                }
            }
            else
            {
                W3MsgEnemyHasImmunity(attacker,false);//Inbuilt function for immunity messages.
            }
        }
    }
}

/* *************************************** (SKILL_BOUNCE) *************************************** */
public OnPluginStart()
{
	HookEvent("player_jump",PlayerJumpEvent);
	m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
}


public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if(War3_GetRace(client)==thisRaceID)
	{
		new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_BOUNCE);
		if(skilllevel>0)
		{
			new Float:velocity[3]={0.0,0.0,0.0};
			velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
			velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
			velocity[0]*=SkillLongJump[skilllevel];//Why invlude the 0.25 here? I've modified the array values to make future maintenance easier to understand (I know Mr. E does the same, just keep an eye on things like that. Repetitive modifiers like that should either be included as a static variable or define rather than explicitly stated)
			velocity[1]*=SkillLongJump[skilllevel];
			SetEntDataVector(client,m_vecBaseVelocity,velocity,true);//Setting this rather than adding to the current base velocity will negate any other effects. Similar to your push's teleport, if that's what you want I'll leave it as-is, otherwise it's better to change this.
		}
	}
}

/* *************************************** (ULT_BLINK) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true)){
		if(!Silenced(client,true) && War3_SkillNotInCooldown(client,thisRaceID,ULT_BLINK,true))//Removed the extra silence message. War3's Silenced function has an unbuilt message
		{
            new ult_teleport=War3_GetSkillLevel(client,thisRaceID,ULT_BLINK);
            if(ult_teleport>0)
            {
                TeleportPlayerView(client,TeleRD[ult_teleport]);
            }
            else
            {
                PrintHintText(client, "Level your Teleport first");
            }
		}
	}
}

bool:TeleportPlayerView(client,Float:distance)
{
	if(client>0)
	{
		if(IsPlayerAlive(client))
		{
            new ult_level=War3_GetSkillLevel(client,thisRaceID,ULT_BLINK);
            War3_CooldownMGR(client,teleCD[ult_level],thisRaceID,ULT_BLINK,_,_);//Cooldown setting goes here, or people can use scrollwheel binds to cross the entire map. Resets are then placed at any failure state (normally you could just return false and reset if so outside the function, but teleports rely on timers.
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
			
			if(enemyImmunityInRange(client,endpos))
			{
				W3MsgEnemyHasImmunity(client);
                War3_CooldownReset(client,thisRaceID,ULT_BLINK);
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
			if(GetVectorLength(emptypos)<1.0)
			{
				new String:buffer[100];
				Format(buffer, sizeof(buffer), "", "NoEmptyLocation", client);
				PrintHintText(client,buffer);
                War3_CooldownReset(client,thisRaceID,ULT_BLINK);
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

public Action:checkTeleport(Handle:h,any:client)
{
	inteleportcheck[client]=false;
	new Float:pos[3];	
	GetClientAbsOrigin(client,pos);
	
	if(GetVectorDistance(teleportpos[client],pos)<0.001)
	{
		TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
        War3_CooldownReset(client,thisRaceID,ULT_BLINK);
	}
	else
	{	
		//War3_CooldownMGR(client,teleCD[ult_level],thisRaceID,ULT_BLINK,_,_);
	}
}

public bool:AimTargetFilter(entity,mask)
{
	return !(entity==ClientTracer);
}

public bool:getEmptyLocationHull(client,Float:originalpos[3])
{
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
	if(entityhit == data )
	{
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

	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates))
		{
			GetClientAbsOrigin(i,otherVec);
			if(GetVectorDistance(playerVec,otherVec)<300){
				return true;
			}
		}
	}
	return false;
}


static InitPassiveSkills(client)
{
    War3_WeaponRestrictTo(client, thisRaceID, "weapon_knife,weapon_hegrenade,weapon_flashbang,weapon_smokegrenade");
    SmallSize(client);
}


/*
Action:Push( client )
{
	new Float:besttargetDistance = 850.0; 
	new Float:posVec[3];
	new Float:otherVec[3];
	new team = GetClientTeam( client );
	new besttarget;
	new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_PUSH );
	
	GetClientAbsOrigin( client, posVec );
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( ValidPlayer( i, true ) && GetClientTeam( i ) != team && !W3HasImmunity( i, Immunity_Ultimates ) )
		{
			GetClientAbsOrigin( i, otherVec );
			new Float:dist = GetVectorDistance( posVec, otherVec );
			if( dist < besttargetDistance )
			{
				besttarget = i;
				besttargetDistance = GetVectorDistance( posVec, otherVec );
			}
		}
	}
	
	if( besttarget == 0 )
	{
		PrintHintText( client, "No Target Found within %.1f feet", besttargetDistance / 10 );
	}
	else
	{
		new Float:pos1[3];
		new Float:pos2[3];
		
		GetClientAbsOrigin( client, pos1 );
		GetClientAbsOrigin( besttarget, pos2 );
		
		new Float:localvector[3];
		
		localvector[0] = pos1[0] - pos2[0];
		localvector[1] = pos1[1] - pos2[1];
		localvector[2] = pos1[2] - pos2[2];

		new Float:velocity1[3];
		new Float:velocity2[3];
		
		velocity1[0] += 0;
		velocity1[1] += 0;
		velocity1[2] += 300;
		
		velocity2[0] = localvector[0] * ( 100 * GravForce[ult_level] );
		velocity2[1] = localvector[1] * ( 100 * GravForce[ult_level] );
		velocity2[2] = localvector[2] * ( 100 * GravForce[ult_level] );
		
		SetEntDataVector( besttarget, m_vecBaseVelocity, velocity1, true );
		SetEntDataVector( besttarget, m_vecBaseVelocity, velocity2, true );
		
		EmitSoundToAll( sound1, client );
		EmitSoundToAll( sound1, besttarget );
		
		EmitSoundToAll( sound2, client );
		EmitSoundToAll( sound2, besttarget );
		
		War3_SetBuff( besttarget, bFlyMode, thisRaceID, true );
		War3_DealDamage( besttarget, 1, client, DMG_BULLET, "element_crit" );
		CreateTimer( FlyDuration, StopFly, besttarget );
		
		new String:NameAttacker[64];
		GetClientName( client, NameAttacker, 64 );
		
		new String:NameVictim[64];
		GetClientName( besttarget, NameVictim, 64 );
		
		PrintToChat( client, ": You have pulled %s closer to you", NameVictim );
		PrintToChat( besttarget, ": You have been pulled torward %s", NameAttacker );
		
		new Float:startpos[3];
		new Float:endpos[3];
		GetClientAbsOrigin( client, startpos );
		GetClientAbsOrigin( besttarget, endpos );
		startpos[2]+=45;
		endpos[2]+=45;
		TE_SetupBeamPoints( startpos, endpos, AttackSprite1, HaloSprite, 0, 20, 1.5, 1.0, 20.0, 0, 8.5, { 200, 200, 200, 255 }, 0 );
		TE_SendToAll();

		War3_CooldownMGR( client, 20.0, thisRaceID, ULT_PUSH, _, true);
	}
}
*/