#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source Race - Gonarch",
    author = "Kibbles",
    description = "Gonarch race for War3Source.",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};

new thisRaceID;

new SKILL_EXO,SKILL_LEGS,SKILL_ACID,ULT_BREEDING;

new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity;
new Float:fModelScale = 1.5;
new iAdditionalBaseHealth = 40;

//skill_exo
new Float:fExoDamageMod[] = {0.0, 0.4, 0.3, 0.2, 0.1};
new Float:fExoDuration[] = {0.0, 7.0, 8.0, 9.0, 10.0};
new bool:bExoActive[MAXPLAYERSCUSTOM];

//skill_legs
new Float:fLegsPower[] = {0.0, 350.0, 400.0, 450.0, 500.0};
new Float:fLegsCooldown[] = {0.0, 10.0, 8.0, 6.0, 4.0};

//skill_acid
new Float:AcidTime[]={0.0, 5.0, 5.0, 5.0, 5.0};
new Float:AcidCooldown[]={0.0, 35.0, 30.0, 25.0, 20.0};
new Float:AcidLocation[MAXPLAYERS][3];
new Float:IceLocation[MAXPLAYERS][3];
new String:acid_sound[]="war3source/archmage/acid.wav";
new String:acidloop_sound[]="war3source/archmage/acidloop.wav";
new AcidCLIENT[MAXPLAYERS];
new Float:AcidTimer[MAXPLAYERS];
new BeamSprite;
new HaloSprite;

//ult_breeding
new bool:bChanged[MAXPLAYERS];
new oldRace[MAXPLAYERS];
new String:infect[]="war3source/brood/infect.wav";
new Float:SpawnAvailableTime[MAXPLAYERSCUSTOM];
new Float:fBreedingCooldown[] = {0.0, 25.0, 20.0, 15.0, 10.0};

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Gonarch", "gonarch");
    SKILL_EXO=War3_AddRaceSkill(thisRaceID,"Thick Exoskeleton (passive)", "60-90% damage immunity for 7-10 seconds after being shot",false,4);
    SKILL_ACID=War3_AddRaceSkill(thisRaceID,"Powerful Legs (passive)", "Long jump",false,4);
    SKILL_LEGS=War3_AddRaceSkill(thisRaceID,"Acid Rain (+ability)", "5 DoT for 5 seconds",false,4);
    ULT_BREEDING=War3_AddRaceSkill(thisRaceID,"Mindless Breeding Machine (passive)", "Spawn baby headcrabs every 25-10 seconds",true,4);
    War3_CreateRaceEnd(thisRaceID);
}

public OnPluginStart()
{
    m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
    m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
    m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
    HookEvent("round_end",RoundEndEvent);
    CreateTimer(1.0,Acid,_,TIMER_REPEAT);
}

public OnMapStart()
{
    PrecacheModel("models/headcrab.mdl", true);
    PrecacheModel("models/headcrabblack.mdl", true);
    War3_AddCustomSound(acid_sound);
	War3_AddCustomSound(acidloop_sound);
    War3_AddCustomSound(infect);
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
    CreateTimer(5.0, SpawnBabyCrabLoop, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnWar3EventSpawn(client)
{
    W3ResetAllBuffRace(client, thisRaceID);
    oldRace[client] = -1;
    new race = War3_GetRace(client);
    if (race == thisRaceID)
    {
        InitRace(client);
    }
}

public OnWar3EventDeath(victim,attacker)
{
	new race_victim=War3_GetRace(victim);
	if(race_victim==thisRaceID){
		AcidTimer[victim]=0.0;
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
    if(newrace != thisRaceID)
    {
        if (ValidPlayer(client))
        {
            War3_WeaponRestrictTo(client,thisRaceID,"");
            W3ResetAllBuffRace( client, thisRaceID );
            SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
        }
    }
    else
    {
        if (ValidPlayer(client, true))
        {
            InitRace(client);
        }
    }
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
    if(ValidPlayer(attacker)&&ValidPlayer(victim, true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
    {
        if (War3_GetRace(victim) == thisRaceID && !Hexed(victim,true) && !bExoActive[victim])
        {
            bExoActive[victim] = true;
            new skill_exo = War3_GetSkillLevel(victim, thisRaceID, SKILL_EXO);
            CreateTimer(fExoDuration[skill_exo], StopExo, victim);
        }
    }
}
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
    if(ValidPlayer(attacker)&&ValidPlayer(victim,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
    {
        if (War3_GetRace(victim) == thisRaceID && bExoActive[victim])
        {
            new skill_exo = War3_GetSkillLevel(victim, thisRaceID, SKILL_EXO);
            if (skill_exo > 0)
            {
                War3_DamageModPercent(fExoDamageMod[skill_exo]);
            }
        }
    }
}
public Action:StopExo(Handle:timer, any:client)
{
    bExoActive[client] = false;
}


public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client=GetClientOfUserId(GetEventInt(event,"userid"));

    if(ValidPlayer(client,true)){
        new race=War3_GetRace(client);
        if (race==thisRaceID)
        {
            
            new skill_legs=War3_GetSkillLevel(client,race,SKILL_LEGS);
            
            if(!Hexed(client)&&skill_legs>0&&SkillAvailable(client,thisRaceID,SKILL_LEGS,false))
            {
                
                new Float:velocity[3]={0.0,0.0,0.0};
                velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
                velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
                new Float:len=GetVectorLength(velocity);
                if(len>3.0){
                    //PrintToChatAll("pre  vec %f %f %f",velocity[0],velocity[1],velocity[2]);
                    ScaleVector(velocity,fLegsPower[skill_legs]/len);
                    
                    //PrintToChatAll("post vec %f %f %f",velocity[0],velocity[1],velocity[2]);
                    SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
                    War3_CooldownMGR(client,fLegsCooldown[skill_legs],thisRaceID,SKILL_LEGS,_,_);
                }
            }
        }
    }
}


public OnAbilityCommand(client,ability,bool:pressed)
{
	if(!Silenced(client)){
		new skill_acid=War3_GetSkillLevel(client,thisRaceID,SKILL_ACID);
		
		if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)){
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_ACID,true)){
				if(skill_acid>0){
					War3_CooldownMGR(client,AcidCooldown[skill_acid],thisRaceID,SKILL_ACID);
					EmitSoundToAll(acidloop_sound,client);
					AcidCLIENT[client]=client;
					AcidTimer[client]=AcidTime[skill_acid];
					new Float:clientpos[3];
					GetClientAbsOrigin(client,clientpos);
					clientpos[0]+=50.0;
					clientpos[1]+=50.0;
					clientpos[2]+=999.0;
					IceLocation[client][0]=clientpos[0];
					IceLocation[client][1]=clientpos[1];
					IceLocation[client][2]=clientpos[2];
					new target = War3_GetTargetInViewCone(client,1000.0,false,20.0);
					
					if(target>0){
						GetClientAbsOrigin(target,AcidLocation[client]);	
					}
					else
					{
						War3_GetAimTraceMaxLen(client,AcidLocation[client],1000.0);
					}
					
					new Float:ranPos1[3];
					new Float:ranPos2[3];
					new Float:ranPos3[3];
					new Float:ranPos4[3];
					ranPos1[1]=GetRandomFloat((AcidLocation[client][1]-150.0),(AcidLocation[client][1]+150.0));
					ranPos1[0]=GetRandomFloat((AcidLocation[client][0]-150.0),(AcidLocation[client][0]+150.0));
					ranPos1[2]=AcidLocation[client][2];
					TE_SetupBeamPoints(ranPos1,IceLocation[client],HaloSprite,BeamSprite,0,1,1.0,10.0,5.0,0,1.0,{51,102,0,255},50);
					TE_SendToAll();
					TE_SetupBeamRingPoint(ranPos1, 0.0, 75.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {51,102,0,255}, 50, 0);
					TE_SendToAll();
					ranPos2[1]=GetRandomFloat((AcidLocation[client][1]-150.0),(AcidLocation[client][1]+150.0));
					ranPos2[0]=GetRandomFloat((AcidLocation[client][0]-150.0),(AcidLocation[client][0]+150.0));
					ranPos2[2]=AcidLocation[client][2];
					TE_SetupBeamPoints(ranPos2,IceLocation[client],HaloSprite,BeamSprite,0,1,1.0,10.0,5.0,0,1.0,{51,102,0,255},50);
					TE_SendToAll();
					TE_SetupBeamRingPoint(ranPos2, 0.0, 75.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {51,102,0,255}, 50, 0);
					TE_SendToAll();
					ranPos3[1]=GetRandomFloat((AcidLocation[client][1]-150.0),(AcidLocation[client][1]+150.0));
					ranPos3[0]=GetRandomFloat((AcidLocation[client][0]-150.0),(AcidLocation[client][0]+150.0));
					ranPos3[2]=AcidLocation[client][2];
					TE_SetupBeamPoints(ranPos3,IceLocation[client],HaloSprite,BeamSprite,0,1,1.0,10.0,5.0,0,1.0,{51,102,0,255},50);
					TE_SendToAll();
					TE_SetupBeamRingPoint(ranPos3, 0.0, 75.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {51,102,0,255}, 50, 0);
					TE_SendToAll();
					ranPos4[1]=GetRandomFloat((AcidLocation[client][1]-150.0),(AcidLocation[client][1]+150.0));
					ranPos4[0]=GetRandomFloat((AcidLocation[client][0]-150.0),(AcidLocation[client][0]+150.0));
					ranPos4[2]=AcidLocation[client][2];
					TE_SetupBeamPoints(ranPos4,IceLocation[client],HaloSprite,BeamSprite,0,1,1.0,10.0,5.0,0,1.0,{51,102,0,255},50);
					TE_SendToAll();	
					TE_SetupBeamRingPoint(ranPos4, 0.0, 75.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {51,102,0,255}, 50, 0);
					TE_SendToAll();
				}
				else
				{
					PrintHintText(client, "Level Acid first");
				}	
			}
		}
	}
	else
	{
		PrintHintText(client,"Silenced: Can not cast");
	}
}
public Action:Acid(Handle:timer,any:userid)
{
	for(new x=1;x<=MaxClients;x++){
		if(ValidPlayer(x,true)){
			if(War3_GetRace(x)==thisRaceID){
				new client=AcidCLIENT[x];
				new Float:victimPos[3];
				if(AcidLocation[client][0]==0.0&&AcidLocation[client][1]==0.0&&AcidLocation[client][2]==0.0){
				}
				else 
				{
					if(AcidTimer[client]>1.0){
						AcidTimer[client]--;
						new ownerteam=GetClientTeam(client);
						
						new Float:ranPos1[3];
						new Float:ranPos2[3];
						new Float:ranPos3[3];
						new Float:ranPos4[3];
						ranPos1[1]=GetRandomFloat((AcidLocation[client][1]-150.0),(AcidLocation[client][1]+150.0));
						ranPos1[0]=GetRandomFloat((AcidLocation[client][0]-150.0),(AcidLocation[client][0]+150.0));
						ranPos1[2]=AcidLocation[client][2];
						TE_SetupBeamPoints(ranPos1,IceLocation[client],HaloSprite,BeamSprite,0,1,1.0,10.0,5.0,0,1.0,{51,102,0,255},50);
						TE_SendToAll();	
						TE_SetupBeamRingPoint(ranPos1, 0.0, 75.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {51,102,0,255}, 50, 0);
						TE_SendToAll();
						ranPos2[1]=GetRandomFloat((AcidLocation[client][1]-150.0),(AcidLocation[client][1]+150.0));
						ranPos2[0]=GetRandomFloat((AcidLocation[client][0]-150.0),(AcidLocation[client][0]+150.0));
						ranPos2[2]=AcidLocation[client][2];
						TE_SetupBeamPoints(ranPos2,IceLocation[client],HaloSprite,BeamSprite,0,1,1.0,10.0,5.0,0,1.0,{51,102,0,255},50);
						TE_SendToAll();	
						TE_SetupBeamRingPoint(ranPos2, 0.0, 75.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {51,102,0,255}, 50, 0);
						TE_SendToAll();
						ranPos3[1]=GetRandomFloat((AcidLocation[client][1]-150.0),(AcidLocation[client][1]+150.0));
						ranPos3[0]=GetRandomFloat((AcidLocation[client][0]-150.0),(AcidLocation[client][0]+150.0));
						ranPos3[2]=AcidLocation[client][2];
						TE_SetupBeamPoints(ranPos3,IceLocation[client],HaloSprite,BeamSprite,0,1,1.0,10.0,5.0,0,1.0,{51,102,0,255},50);
						TE_SendToAll();	
						TE_SetupBeamRingPoint(ranPos3, 0.0, 75.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {51,102,0,255}, 50, 0);
						TE_SendToAll();
						ranPos4[1]=GetRandomFloat((AcidLocation[client][1]-150.0),(AcidLocation[client][1]+150.0));
						ranPos4[0]=GetRandomFloat((AcidLocation[client][0]-150.0),(AcidLocation[client][0]+150.0));
						ranPos4[2]=AcidLocation[client][2];
						TE_SetupBeamPoints(ranPos4,IceLocation[client],HaloSprite,BeamSprite,0,1,1.0,10.0,5.0,0,1.0,{51,102,0,255},50);
						TE_SendToAll();	
						TE_SetupBeamRingPoint(ranPos4, 0.0, 75.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {51,102,0,255}, 50, 0);
						TE_SendToAll();
						
						for (new i=1;i<=MaxClients;i++){
							if(ValidPlayer(i,true)&& GetClientTeam(i)!=ownerteam){
								GetClientAbsOrigin(i,victimPos);
								if(GetVectorDistance(AcidLocation[client],victimPos)<300.0){
									if(!W3HasImmunity(i,Immunity_Skills)){
										W3FlashScreen(i,{0,0,255,50});
										War3_DealDamage(i,5,client,DMG_BULLET,"Acid");
										War3_SetBuff(i,fSlow,thisRaceID,0.8);
										CreateTimer(0.9,slow,i);
										
										TE_SetupBeamPoints(IceLocation[client],victimPos,BeamSprite,BeamSprite,0,1,1.0,10.0,5.0,0,1.0,{51,102,0,255},50);
										TE_SendToAll();	
										TE_SetupBeamRingPoint(victimPos, 0.0, 75.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {51,102,0,255}, 50, 0);
										TE_SendToAll();
										
										EmitSoundToAll(acid_sound,i);
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
public Action:slow(Handle:timer,any:victim)
{
	War3_SetBuff(victim,fSlow,thisRaceID,1.0);
}


public Action:SpawnBabyCrabLoop(Handle:timer)
{
    for (new i=1; i<=MaxClients; i++)
    {
        if (ValidPlayer(i, true) && War3_GetRace(i) == thisRaceID)
        {
            new iTeam = GetClientTeam(i);
            new ult_breeding = War3_GetSkillLevel(i, thisRaceID, ULT_BREEDING);
            if (ult_breeding > 0 && IsSpawnAvailable(i))
            {
                for (new j=1; j<=MaxClients; j++)
                {
                    if (ValidPlayer(j) && !IsPlayerAlive(j) && GetClientTeam(j) == iTeam && j != i)
                    {
                        SetSpawnCooldown(i, fBreedingCooldown[ult_breeding]);
                        SpawnBabyCrab(j, i);
                        break;
                    }
                }
            }
        }
    }
}
static SetSpawnCooldown(client, Float:cooldown)
{
    SpawnAvailableTime[client]=GetGameTime()+cooldown;
}
static bool:IsSpawnAvailable(client)
{
    return (GetGameTime()>=SpawnAvailableTime[client]) ? true : false;
}
static SpawnBabyCrab(client, mother)
{
    new babyCrabID=War3_GetRaceIDByShortname("babyheadcrab");
    oldRace[client]=War3_GetRace(client);
    W3SetPlayerProp(client,RaceChosenTime,GetGameTime());
    W3SetPlayerProp(client,RaceSetByAdmin,true);
    War3_SetRace(client,babyCrabID);
    bChanged[client]=true;    
    War3_SpawnPlayer(client);
    PrintCenterText(client, "You are a Baby Headcrab");
    new Float:ang[3];
    GetClientEyeAngles(mother,ang);
    new Float:pos2[3];
    GetClientAbsOrigin(mother,pos2);
    decl Float:fAngles[3];
    GetClientEyeAngles(mother, fAngles);
    new ax = 0;
    fAngles[0]=0.0,fAngles[2]=0.0;
    if(fAngles[1]<135 && fAngles[1]>45) {
        ax = 1;
    }
    else if(fAngles[1]>-135 && fAngles[1]<-45) {
        ax = 1;
    }
    pos2[ax]+=20;
    TeleportEntity(client,pos2,ang,NULL_VECTOR);
    EmitSoundToAll(infect,client);
}
public RoundEndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i = 1;i <= MaxClients;i++)
    {
        if(ValidPlayer(i))
        {
            if(bChanged[i])
            {
                CreateTimer(1.0, Delay, i);    
            }
        }
    }
}
public Action:Delay(Handle:timer,any:i)
{
    if(bChanged[i])
    {
        W3SetPlayerProp(i,RaceChosenTime,GetGameTime());
        W3SetPlayerProp(i,RaceSetByAdmin,true);
        War3_SetRace(i,oldRace[i]);
        oldRace[i] = -1;
        bChanged[i] = false;
    }
}


static InitRace(client)
{
    War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
    War3_SetBuff(client,bInvisWeaponOverride,thisRaceID,true);
    War3_SetBuff(client,iInvisWeaponOverrideAmount,thisRaceID,0);
    War3_SetBuff(client, iAdditionalMaxHealth, thisRaceID, iAdditionalBaseHealth);
    new clientTeam = GetClientTeam(client);
    if(clientTeam == TEAM_T)
    {
        SetEntityModel(client, "models/headcrab.mdl");
    }
    else if (clientTeam == TEAM_CT)
    {
        SetEntityModel(client, "models/headcrabblack.mdl");
    }
    SetEntPropFloat(client, Prop_Send, "m_flModelScale", fModelScale);
    bExoActive[client] = false;
    SetSpawnCooldown(client, 0.0);
}