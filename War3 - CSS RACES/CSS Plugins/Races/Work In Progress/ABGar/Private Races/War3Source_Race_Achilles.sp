/**************************************************************************************/
/**************************************************************************************/
/***************************************************************************************


			NEED TO IMPLEMENT THE HEAD / FOOT DAMAGE SWAP:
			
			achilles foot--    head and foot damage taken are swapped



***************************************************************************************/
/**************************************************************************************/

#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Achilles",
	author = "ABGar",
	description = "The Achilles race for War3Source.",
	version = "1.0",
	// Greed's Private Race Request - http://www.sevensinsgaming.com/forum/index.php?/topic/5352-achillesprivate/
}

new thisRaceID;

new SKILL_DEADLY, SKILL_SWIFT, SKILL_AGILE, ULT_TROJAN;

// SKILL_DEADLY
new Float:DeadlyChance[]={0.0,0.1,0.2,0.3,0.5};
new String:DeadlySound[]={"npc/roller/mine/rmine_blades_out2.wav"};

// SKILL_SWIFT
new Float:SwiftSpeed[]={1.0,1.1,1.15,1.2,1.32};

// SKILL_AGILE
new Float:AgileCD=10.0;
new LaserSprite;
new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity;

// ULT_TROJAN
new OriginOffset;
new String:sOldModel[MAXPLAYERS][256];
new Float:MoleChance[]={0.0,0.05,0.1,0.15,0.2};


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Achilles [PRIVATE]","achilles");
	SKILL_DEADLY = War3_AddRaceSkill(thisRaceID,"Deadly","Chance for Fatal Damage (attack)",false,4);
	SKILL_SWIFT = War3_AddRaceSkill(thisRaceID,"Swift","Move swiftly over the battlefield (passive)",false,4);
	SKILL_AGILE = War3_AddRaceSkill(thisRaceID,"Agile","Leap to finish your enemy (passive)",false,4);
	ULT_TROJAN=War3_AddRaceSkill(thisRaceID,"Trojan Horse","Conceal yourself as a gift to the Gods (passive ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_SWIFT,fMaxSpeed,SwiftSpeed);
}


public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
	}
	else
	{
		if (ValidPlayer(client,true))
        {
		}
	}
}

public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new TrojanLevel = War3_GetSkillLevel(client,thisRaceID,ULT_TROJAN);
		if(W3Chance(MoleChance[TrojanLevel]))
			StartMole(client);
	}
}

public OnMapStart()
{
	War3_PrecacheSound(DeadlySound);
	LaserSprite=PrecacheModel("materials/sprites/laserbeam.vmt");
}

public OnPluginStart()
{
	m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	OriginOffset = FindSendPropOffs("CBaseEntity","m_vecOrigin");
}
	
	
/* *************************************** (SKILL_DEADLY) *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new DeadlyLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_DEADLY);
			if(DeadlyLevel>0)
			{
				if(W3Chance(DeadlyChance[DeadlyLevel]))
				{
					War3_DamageModPercent(2.0);
					W3EmitSoundToAll(DeadlySound,attacker);
					W3FlashScreen(attacker,RGBA_COLOR_RED);
				}
			}
		}
	}
}
/* *************************************** (SKILL_AGILE) *************************************** */
public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if(War3_GetRace(client)==thisRaceID)
	{
		new AgileLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_AGILE);
		if(AgileLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,SKILL_AGILE,true,true,true))
			{
				War3_CooldownMGR(client,AgileCD,thisRaceID,SKILL_AGILE,_,_);
				new Float:velocity[3]={0.0,0.0,0.0};
				velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
				velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
				velocity[0]*=float(AgileLevel)*0.25;
				velocity[1]*=float(AgileLevel)*0.25;
				SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
				new TrailColour[4];
				
				if(GetClientTeam(client)==TEAM_T)
					TrailColour={0,25,255,200};
				else
					TrailColour={255,25,0,200};

				TE_SetupBeamFollow(client,LaserSprite,0,0.5,2.0,7.0,1,TrailColour);
				TE_SendToAll();
			}
		}
	}
}

/* *************************************** (ULT_TROJAN) *************************************** */
public StartMole( client )
{
    new Float:MoleTime = 5.0;
    W3MsgMoleIn(client,MoleTime);
    CreateTimer(0.2+MoleTime,DoMole,client);
}

public Action:DoMole(Handle:timer,any:client)
{
    if(ValidPlayer(client,true))
    {
        new team=GetClientTeam(client);
        new searchteam=(team==TEAM_T)?TEAM_CT:TEAM_T;
        new Float:emptyspawnlist[100][3];
        new availablelocs = 0;
        
        new Float:playerloc[3];
        new Float:spawnloc[3];
        new ent = -1;
        while((ent=FindEntityByClassname(ent,(searchteam==TEAM_T)?"info_player_terrorist":"info_player_counterterrorist"))!=-1)
        {
            if(!IsValidEdict(ent)) continue;
            GetEntDataVector(ent,OriginOffset,spawnloc);
            
            new bool:is_conflict = false;
            for(new i=1;i<=MaxClients;i++)
            {
                if(ValidPlayer(i,true))
                {
                    GetClientAbsOrigin(i,playerloc);
                    if(GetVectorDistance(spawnloc,playerloc)<60.0)
                    {
                        is_conflict = true;
                        break;
                    }                
                }
            }
            if(!is_conflict)
            {
                emptyspawnlist[availablelocs][0] = spawnloc[0];
                emptyspawnlist[availablelocs][1] = spawnloc[1];
                emptyspawnlist[availablelocs][2] = spawnloc[2];
                availablelocs++;
            }
        }
        if(availablelocs == 0)
        {
            War3_ChatMessage(client, "No suitable location found, can not mole!",client);
            return;
        }
        GetClientModel(client,sOldModel[client],256);
        SetEntityModel(client,(searchteam==TEAM_T)?"models/player/t_leet.mdl":"models/player/ct_urban.mdl");
        TeleportEntity(client,emptyspawnlist[GetRandomInt(0,availablelocs-1)],NULL_VECTOR,NULL_VECTOR);
        W3MsgMoled(client);
        War3_ShakeScreen(client,1.0,20.0,12.0);
        CreateTimer(10.0,ResetModel,client);
    }
}

public Action:ResetModel(Handle:timer,any:client)
{
    if(ValidPlayer(client,true))
    {
        SetEntityModel(client,sOldModel[client]);
        W3MsgNoLongerDisguised(client);
    }
}
