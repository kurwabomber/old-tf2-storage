#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include "W3SIncs/War3Source_Interface"  
new Handle:g_radius;

new thisRaceID;
new bool:bHasRespawned[65];

new spawnhp[5]={80,100,110,120,130};
new orbdamage[5]={10,20,25,28,30};

new nervegas[5]={1,1,2,3,3};
new Float:ReincarnationChance[5]={0.60,0.65,0.70,0.80,0.82};
new WardStartingArr[]={0,1,2,3,4}; 
new beamColor[4]={255,10,10,255};
new String:ultsnd[]="npc/antlion/attack_single1.wav";
new String:SND_EXPLODE[]="ambient/explosions/explode_6.wav";
new String:SND_LASER[]="npc/antlion/attack_single1.wav";
new String:SND_HELI[]="npc/attack_helicopter/aheli_rotor_loop1.wav";
new String:SND_HELIDOWN[]="ambient/machines/spindown.wav";
new Handle:ultCooldownCvar;
new Handle:OrbCooldownCvar;
new SKILL_ALASER,SKILL_CHELI,SKILL_NADE,ULT_BALL;
//new iVec,iVec2;
//new attacker;
new g_hirnrauch, g_OrangeGlowSprite, explosion,combineglass;
new BeamSprite,HaloSprite,plasmabeam,healthsp;
new plasma,helicopter,striderbulge,combineball,extendet;
new MyWeaponsOffset,Clip1Offset,AmmoOffset;

// Healing Ward Specific
#define MAXWARDS 64*4
#define WARDRADIUS 80
#define WARDDAMAGE 2
#define WARDHEAL 5
#define WARDBELOW -2.0
#define WARDABOVE 160.0

new CurrentWardCount[MAXPLAYERS];
new Float:WardLocation[MAXWARDS][3]; 
new WardOwner[MAXWARDS];
//new Float:LastThunderClap[MAXPLAYERS];
new String:wardDamageSound[]="npc/antlion/attack_single1.wav";
new String:wardHealSound[]="weapons/physcannon/physcannon_charge.wav";
new String:SND_HEAL[]="items/medshot4.wav";
public Plugin:myinfo = 
{
    name = "War3Source Race - Combine Soldier",
    author = "DonRevan much thanks to Peoples Army",
    description = "Combine Race wih 4 skills and 4 levels",
    version = "1.0.0.1",
    url = "http://wcs-lagerhaus.de"
};

public OnPluginStart()
{
    //HookEvent("player_death",PlayerDeathEvent,EventHookMode_Pre);
    HookEvent("round_start",RoundStartEvent);
    HookEvent("player_spawn",PlayerSpawnedEvent);
    ultCooldownCvar=CreateConVar("war3_combines_ult_cd","35","Combine Soldiers Extended Combineball Cooldown");
    OrbCooldownCvar=CreateConVar("war3_orbitallaser_cd","40","Combine Soldiers Orbital Laser Cooldown");
    HookEvent("smokegrenade_detonate",smoke_detonate);
    MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
    Clip1Offset=FindSendPropOffs("CBaseCombatWeapon","m_iClip1");
    AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
    g_radius = CreateConVar("war3_nervegas_radius","200");
    CreateTimer(1.0,CalcWards,_,TIMER_REPEAT);
}

public OnMapStart() 
{
    PrecacheSound(ultsnd, true );
    PrecacheSound(SND_EXPLODE, true);
    PrecacheSound(wardDamageSound, true);
    PrecacheSound(wardHealSound, true);
    PrecacheSound(SND_LASER, true);  
    PrecacheSound(SND_HEAL, true);
    PrecacheSound(SND_HELI, true);  
    PrecacheSound(SND_HELIDOWN, true);  
    g_hirnrauch = PrecacheModel( "particle/fire.vmt");
    g_OrangeGlowSprite = PrecacheModel("materials/sprites/orangeglow1.vmt");
    plasma = PrecacheModel("materials/sprites/plasma1.vmt");
    plasmabeam = PrecacheModel("sprites/plasmabeam.vmt");
    healthsp = PrecacheModel("effects/ar2ground2.vmt");
    //damagesp = PrecacheModel("materials/sprites/redglow3.vmt");
    //dunst = PrecacheModel("sprites/steam.vmt");
    BeamSprite=PrecacheModel("materials/sprites/laser.vmt");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
    striderbulge=PrecacheModel("effects/strider_bulge_dudv_dx60.vmt");
    helicopter=PrecacheModel("models/combine_helicopter.mdl");
    combineball=PrecacheModel("models/Effects/combineball.mdl");
    extendet=PrecacheModel("models/Effects/portalfunnel.mdl");
    combineglass=PrecacheModel("models/Effects/splodeglass.mdl");
    explosion=PrecacheModel("sprites/floorfire4_.vmt", true);
    PrintToServer("[WAR3] Race loaded : Combine Soldier");
}

public OnWar3PluginReady(){
    thisRaceID=War3_CreateNewRace("Combine Soldier","combines");
    SKILL_ALASER=War3_AddRaceSkill(thisRaceID,"Oribal Laser Cannon","Control the Orbital Combine Laser Cannon to fire a huge Beam at a target!",false,4);
    SKILL_CHELI=War3_AddRaceSkill(thisRaceID,"Combine Helicopter","Request a helicopter for some ground backup trough the air",false,4);
    SKILL_NADE=War3_AddRaceSkill(thisRaceID,"Nervegas","Detonated Smokegrenades will release a cloud of nervegas to hurt victims",false,4);
    ULT_BALL=War3_AddRaceSkill(thisRaceID,"Extended Combine Ball","Drops a Combineball and extend it in his size\nThe energy that goes out from the ball can regenerate the health of your allies\n...with change...",true,4); 
    War3_CreateRaceEnd(thisRaceID);
}

public Action:PlayerSpawnedEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
    new race=War3_GetRace(client);
    if(race==thisRaceID)
    {
        new Float:dir[3]={0.0,0.0,0.0};
        new Float:iVec[ 3 ];
        GetClientAbsOrigin( client, Float:iVec );
        iVec[2]+=50.0;
        TE_SetupGlowSprite( iVec, combineglass, 2.0 , 2.0, 255);
        TE_SendToAll();
        TE_SetupSparks(iVec, dir, 500, 50);
        TE_SendToAll();
        TE_SetupDust(iVec, dir, 150.0, 10.0);
        TE_SendToAll();
        SetEntProp(client,Prop_Send,"m_ArmorValue",120);
        PrintToConsole(client,"[Combine Soldier] Spawned with a kelver");
    }
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && IsPlayerAlive(client))
    {    
        new skill=War3_GetSkillLevel(client,race,ULT_BALL);
        if(skill>0)
        {
            if(War3_SkillNotInCooldown(client,thisRaceID,ULT_BALL,true))
            {
                RemoveWards(client);
                War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_BALL,true,true);
                new Float:iVec[ 3 ];
                GetClientAbsOrigin( client, Float:iVec );
                new Float:dir[3]={0.0,0.0,0.0};
                TE_SetupSparks(iVec, dir, 500, 50);
                TE_SendToAll();
                TE_SetupDust(iVec, dir, 100.0, 10.0);
                TE_SendToAll();
                TE_SetupSmoke (iVec, g_hirnrauch, 500.0, 10 );
                TE_SendToAll();
                TE_SetupBeamRingPoint(iVec,5.0,10.0,striderbulge,HaloSprite,2,6,8.0,50.0,7.0,{255,255,170,255},40,0);
                TE_SendToAll();
                TE_SetupGlowSprite( iVec, extendet, 10.0 , 0.5, 255);
                TE_SendToAll();
                TE_SetupGlowSprite( iVec, extendet, 10.0 , 0.5, 255);
                TE_SendToAll();
                TE_SetupGlowSprite( iVec, extendet, 10.0 , 0.5, 255);
                TE_SendToAll();
                PrintToServer("[WAR3] Ultimate : Ultimate used (Extended Combine Ball)");
                War3_ChatMessage(client,"Extendet Combine Ball : You dropt a Combine Ball and extendet it in his size!");
                PrintHintText(client,"Ball dropped");
                CreateWard(client);
                // W3FlashScreen(client,RGBA_COLOR_GREEN,5.2,_,FFADE_IN);
                decl Ent;
                Ent = CreateEntityByName("env_muzzleflash");
                if (Ent == -1)
                return;

                if (Ent>0 && IsValidEdict(Ent))
                {
                    new Float:entl[ 3 ];
                    GetClientAbsOrigin( client, Float:entl );
                    new Float:muzzlesize=55.0;
                    
                    DispatchKeyValueFloat(Ent, "scale", muzzlesize);
                    DispatchSpawn(Ent);
                    ActivateEntity(Ent);
                    TeleportEntity(Ent, entl, NULL_VECTOR, NULL_VECTOR);
                    
                    AcceptEntityInput(Ent, "Fire");
                }
                else
                {
                    PrintToServer("[CRITICAL ERROR] Found a Critical Error Combine Soldier script want to create a edict but that edict is not valid!");
                }
            }
        }
    }
}

public Action:KillBall(Handle:Timer, any:client)
{
    if(War3_GetRace(client)==thisRaceID && IsPlayerAlive(client))
    {
        new skill_level=War3_GetSkillLevel(client,thisRaceID,ULT_BALL);
        if(skill_level>0)
        {
            if(!Silenced(client)&&CurrentWardCount[client]<WardStartingArr[skill_level])
            {
                new iTeam=GetClientTeam(client);
                new bool:conf_found=false;
                if(War3_GetGame()==Game_TF)
                {
                    new Handle:hCheckEntities=War3_NearBuilding(client);
                    new size_arr=0;
                    if(hCheckEntities!=INVALID_HANDLE)
                    size_arr=GetArraySize(hCheckEntities);
                    for(new x=0;x<size_arr;x++)
                    {
                        new ent=GetArrayCell(hCheckEntities,x);
                        if(!IsValidEdict(ent)) continue;
                        new builder=GetEntPropEnt(ent,Prop_Send,"m_hBuilder");
                        if(builder>0 && ValidPlayer(builder) && GetClientTeam(builder)!=iTeam)
                        {
                            conf_found=true;
                            break;
                        }
                    }
                    if(size_arr>0)
                    CloseHandle(hCheckEntities);
                }
                if(conf_found)
                {
                    W3MsgWardLocationDeny(client);
                }
                else
                {
                    if(War3_IsCloaked(client))
                    {
                        W3MsgNoWardWhenInvis(client);
                        return;
                    }
                    CreateWard(client);
                    CurrentWardCount[client]++;
                    W3MsgCreatedWard(client,CurrentWardCount[client],WardStartingArr[skill_level]);
                }
            }
            else
            {
                W3MsgNoWardsLeft(client);
            }    
        }
    }
}

public OnRaceChanged(client,oldrace,newrace)
{
    if(newrace!=thisRaceID)
    {
        RemoveWards(client);
    }
}

public CreateWard(client)
{
    for(new i=0;i<MAXWARDS;i++)
    {
        if(WardOwner[i]==0)
        {
            WardOwner[i]=client;
            GetClientAbsOrigin(client,WardLocation[i]);
            break;
        }
    }
}

public RemoveWards(client)
{
    for(new i=0;i<MAXWARDS;i++)
    {
        if(WardOwner[i]==client)
        {
            WardOwner[i]=0;
        }
    }
    CurrentWardCount[client]=0;
}

public Action:CalcWards(Handle:timer,any:userid)
{
    new client;
    for(new i=0;i<MAXWARDS;i++)
    {
        if(WardOwner[i]!=0)
        {
            client=WardOwner[i];
            if(!ValidPlayer(client,true))
            {
                WardOwner[i]=0;
                --CurrentWardCount[client];
            }
            else
            {
                WardFunc(client,i);
            }
        }
    }
}
public WardFunc(owner,wardindex)
{
    new ownerteam=GetClientTeam(owner);
    new beamcolor[]={0,0,200,255};
    if(ownerteam==2)
    {
        beamcolor[0]=255;
        beamcolor[1]=0;
        beamcolor[2]=0;
        
        beamcolor[3]=155;
    }
    new Float:start_pos[3];
    new Float:end_pos[3];
    new Float:tempVec1[]={0.0,0.0,WARDBELOW};
    new Float:tempVec2[]={0.0,0.0,WARDABOVE};
    AddVectors(WardLocation[wardindex],tempVec1,start_pos);
    AddVectors(WardLocation[wardindex],tempVec2,end_pos);
    //TE_SetupBeamPoints( startpos, iVec, Shield, Shield, 5, 30, 1.6, 5.0, 10.0, 1, 10.0, { 200, 100, 50, 255 }, 5 );
    TE_SetupBeamPoints(start_pos,end_pos,plasmabeam,HaloSprite,1,GetRandomInt(100,200),1.0,float(WARDRADIUS),float(WARDRADIUS),1,10.0,{255,255,255,255},10);
    TE_SendToAll();
    TE_SetupBeamPoints(start_pos,end_pos,plasmabeam,HaloSprite,0,41,1.6,6.0,15.0,0,20.5,{255,255,255,222},45);
    TE_SendToAll();
    TE_SetupDynamicLight(start_pos,255,255,255,8,float(WARDRADIUS),1.02,2.0);
    TE_SendToAll();
    //TE_SetupBeamPoints(start_pos,end_pos,plasmabeam,HaloSprite,0,GetRandomInt(20,40),5,30,30,0,0.0,beamcolor,10);
    //TE_SendToAll();
    EmitSoundToAll(wardHealSound, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, -1, start_pos, NULL_VECTOR, true, 0.0);
    TE_SetupBeamRingPoint(start_pos,1.0,float(WARDRADIUS),plasma,HaloSprite,0,10,0.80,35.0,10.5,{255,255,170,255},20,0);
    TE_SendToAll();
    TE_SetupBeamRingPoint(end_pos,1.1,float(WARDRADIUS),plasma,HaloSprite,0,10,0.80,35.0,10.5,{255,255,170,255},20,0);
    TE_SendToAll();
    start_pos[2]+=45.0;
    TE_SetupGlowSprite( start_pos, g_OrangeGlowSprite, 1.1 , 1.1, 255);
    TE_SendToAll();
    TE_SetupGlowSprite( start_pos, combineball, 1.5 , 1.4, 255);
    TE_SendToAll();
    start_pos[2]-=45.0;
    new Float:BeamXY[3];
    for(new x=0;x<3;x++) BeamXY[x]=start_pos[x];
    new Float:BeamZ= BeamXY[2];
    BeamXY[2]=0.0;
    
    new Float:VictimPos[3];
    new Float:tempZ;
    new Float:dir[3]={0.0,0.0,0.0};
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i,true)&&ValidPlayer(owner,true))
        {
            new vteam=GetClientTeam(i);
            if(vteam==ownerteam )
            {
                GetClientAbsOrigin(i,VictimPos);
                tempZ=VictimPos[2];
                VictimPos[2]=0.0;
                
                if(GetVectorDistance(BeamXY,VictimPos) < WARDRADIUS)
                {
                    if(tempZ>BeamZ+WARDBELOW && tempZ < BeamZ+WARDABOVE)
                    {
                        EmitSoundToAll(SND_HEAL,i,SNDCHAN_WEAPON);
                        //new skilllevel=War3_GetSkillLevel(client,thisRaceID,ULT_BALL);
                        //new hpadd=ballhp[skilllevel];
                        War3_HealToMaxHP(i,WARDHEAL);
                        new Float:TargetPos[3];
                        GetClientAbsOrigin(i,TargetPos);
                        TE_SetupGlowSprite( TargetPos, healthsp, 0.8 , 1.0, 255);
                        TE_SendToAll();
                        start_pos[2]+=56.0;
                        TargetPos[2]+=60.0;
                        TE_SetupBeamPoints(start_pos,TargetPos,plasmabeam,HaloSprite,0,50,1.0,30.0,20.0,0,0.0,{255,255,255,255},10);
                        TE_SendToAll();
                        TargetPos[2]-=5.0;
                        start_pos[2]-=60.0;
                        //TE_SetupBeamPoints(TargetPos,TargetPos,plasma,HaloSprite,0,GetRandomInt(60,80),0.22,30.0,10.0,0,0.0,beamcolor,10);
                        //TE_SendToAll();
                        TE_SetupSparks(TargetPos, dir, 500, 50);
                        TE_SendToAll();
                        //TE_SetupEnergySplash(TargetPos, dir);
                        //TE_SendToAll();
                        
                    }
                }
            }
    
        }
    }
}
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
//public Action:OnWar3TakeDmgBullet(victim,attacker,inflictor,Float:damage,damagetype)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&attacker!=victim&&GetClientTeam(attacker)!=GetClientTeam(victim))
    {
        new race_attacker=War3_GetRace(attacker);
        //new Float:chance_mod=W3ChanceModifier(attacker);
        if(race_attacker==thisRaceID)
        {
            new skill_cs_attacker=War3_GetSkillLevel(attacker,race_attacker,SKILL_ALASER);
            if(skill_cs_attacker>0)
            {
                // PrintToConsole(attacker,"[Notice] Skill used : Orbital Laser Cannon");
                new Float:chance=0.15*1.0;
                if(GetRandomFloat(0.0,1.0)<=chance && !W3HasImmunity(victim,Immunity_Skills))
                {
                    // PrintToConsole(attacker,"[Orbital Laser Cannon - Control] : Calculating the Area of Effect");
                    if(War3_SkillNotInCooldown(attacker,thisRaceID,SKILL_ALASER,true))
                    {
                        new Float:dir[3]={0.0,0.0,0.0};
                        new damage_i=orbdamage[skill_cs_attacker];
                        PrintHintText(attacker,"Orbital Laser Cannon:\nLaser has focused your victim!");
                        War3_ChatMessage(attacker,"Orbital Laser Cannon : Focused your current victim");
                        War3_DealDamage(victim,damage_i,attacker,DMG_ENERGYBEAM,"Orbital Laser Cannon");
                        PrintToConsole(attacker,"[Orbital Laser Cannon ~ CONTROL] Orbital Laser has targetted your victim and damaged him with %d damage!",damage_i);
                        PrintToConsole(victim,"[Notice] A Orbital Laser Cannon has targetted you!");
                        // herzstk. von der laser kanone bzw. die effekte
                        new Float:position2[3];
                        GetClientEyePosition(attacker,position2);
                        new Float:position[ 3 ];
                        GetClientAbsOrigin( victim, Float:position );
                        position2[2]+=5000.0;
                        TE_SetupExplosion(position, explosion, 8.5, 1, 4, 0, 0);
                        TE_SendToAll(); 
                        //DELAYED EXPLOSIONS
                        TE_SetupExplosion(position, explosion, 6.5, 1, 4, 0, 0);
                        TE_SendToAll(0.8); 
                        TE_SetupExplosion(position, explosion, 6.5, 1, 4, 0, 0);
                        TE_SendToAll(1.4); 
                        TE_SetupExplosion(position, explosion, 3.5, 1, 4, 0, 0);
                        TE_SendToAll(1.8); 
                        TE_SetupExplosion(position, explosion, 1.5, 1, 4, 0, 0);
                        TE_SendToAll(2.3); 
                        EmitSoundToAll(SND_EXPLODE, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, -1, position, NULL_VECTOR, true, 0.0);
                        TE_SetupSmoke (position, g_hirnrauch, 10.0, 10 );
                        TE_SendToAll();
                        TE_SetupSparks(position, dir, 800, 50);
                        TE_SendToAll();
                        EmitSoundToAll(SND_LASER, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, -1, position, NULL_VECTOR, true, 0.0);
                        TE_SetupBeamPoints(position,position2,BeamSprite,HaloSprite,0,50,3.8,35.5,35.5,8,20.5,beamColor,45);
                        TE_SendToAll();
                        War3_CooldownMGR(attacker, GetConVarFloat(OrbCooldownCvar),thisRaceID,SKILL_ALASER,true,true);
                        W3FlashScreen(victim,RGBA_COLOR_RED,2.3,_,FFADE_IN);
                        W3FlashScreen(attacker,RGBA_COLOR_RED,1.6,_,FFADE_IN);
                    }
                }
                if(W3HasImmunity(victim,Immunity_Skills))
                {
                    W3MsgSkillBlocked(victim,attacker,"Orbital Laser Cannon");
                }
            }
        }
    }
}

public OnWar3EventDeath(index,attacker)
{    
    if(ValidPlayer(index)){
        new race=W3GetVar(DeathRace); //get  immediate variable, which indicates the race of the player when he died
        if(race==thisRaceID&&!bHasRespawned[index]&&War3_GetGame()!=Game_TF)
        {
            new skill=War3_GetSkillLevel(index,race,SKILL_CHELI);
            if(skill)
            {
                new Float:percent=ReincarnationChance[skill];
                if(GetRandomFloat(0.0,1.0)<=percent)
                {
                    CreateTimer(6.0,RespawnPlayer,index);
                    PrintHintText(index,"Helicopter requested");
                    War3_ChatMessage(index,"You Request a Helicopter for some ground backup");
                    new Float:iVec[ 3 ];
                    GetClientAbsOrigin( index, Float:iVec );
                    TE_SetupSmoke( iVec, g_hirnrauch, 10.0, 3 );
                    TE_SendToAll();
                }
            }
        }
    }
}

public Action:RespawnPlayer(Handle:timer,any:client)
{
    //new client=GetClientOfUserId(userid);
    if(client>0&&!IsPlayerAlive(client)&&GetClientTeam(client)!=1)
    {
        War3_SpawnPlayer(client);
        new Float:pos[3];
        new Float:ang[3];
        War3_CachedAngle(client,ang);
        War3_CachedPosition(client,pos);
        TeleportEntity(client,pos,ang,NULL_VECTOR);
        for(new s=0;s<10;s++)
        {
            new ent=GetEntDataEnt2(client,MyWeaponsOffset+(s*4));
            if(ent>0 && IsValidEdict(ent))
            {
                new String:ename[64];
                GetEdictClassname(ent,ename,64);
                if(StrEqual(ename,"weapon_c4") || StrEqual(ename,"weapon_knife"))
                {
                    continue;
                }
                UTIL_Remove(ent);
            }
        }
        // hp set
        new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_CHELI);
        new hpadd=spawnhp[skilllevel];
        SetEntityHealth(client,GetClientHealth(client)+hpadd);
        War3_DealDamage(client,94,client,DMG_ENERGYBEAM,"Combine Helicopter");
        // ammo
        for(new s=0;s<32;s++)
        {
            SetEntData(client,AmmoOffset+(s*4),War3_CachedDeadAmmo(client,s),4);
        }
        // addintionaly sfx
        
        
        new Float:iVec[ 3 ];
        GetClientAbsOrigin( client, Float:iVec );
        TE_SetupSmoke( iVec, g_hirnrauch, 295.8, 60 );
        TE_SendToAll();
        //EmitSoundToAll(SND_HELIDOWN, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, -1, iVec, NULL_VECTOR, true, 11.1);
        iVec[2]+=210.0;
        TE_SetupSmoke( iVec, g_hirnrauch, 120.0, 60 );
        TE_SendToAll();
        TE_SetupGlowSprite( iVec, helicopter, 11.1 , 1.5 , 255);
        TE_SendToAll();
        //EmitSoundToAll(SND_HELI, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, -1, iVec, NULL_VECTOR, true, 11.1);
        iVec[2]-=200.0;

        TE_SetupBeamFollow(client,BeamSprite,0,4.1,3.0,5.0,20,{255,255,255,255});
        TE_SendToAll();
        iVec[2]+=20.0;
        TE_SetupGlowSprite( iVec, g_OrangeGlowSprite, 5.0 , 4.5 , 188);
        TE_SendToAll();
        TE_SetupGlowSprite( iVec, plasma, 4.9 , 1.2 , 140);
        TE_SendToAll();
        iVec[2]+=80.0;
        TE_SetupBeamRingPoint( iVec,99.9,400.4,plasma,HaloSprite,2,35,3.48,80.0,3.2,{255,255,255,255},60,0);
        TE_SendToAll();
        // weapons
        for(new s=0;s<10;s++)
        {
            new String:wep_check[64];
            War3_CachedDeadWeaponName(client,s,wep_check,64);
            if(!StrEqual(wep_check,"") && !StrEqual(wep_check,"",false) && !StrEqual(wep_check,"weapon_c4") && !StrEqual(wep_check,"weapon_knife"))
            {
                new wep_ent=GivePlayerItem(client,wep_check);
                if(wep_ent>0)
                {
                    SetEntData(wep_ent,Clip1Offset,War3_CachedDeadClip1(client,s),4);
                    PrintToConsole(client,"[Combine Helicopter] You Respawned with %d Health",hpadd);
                }
            }
        }
        War3_ChatMessage(client,"Combine Soldier : Standart Equipment!");
        bHasRespawned[client]=true;
        EmitSoundToAll(ultsnd,client);
    }
    else{
        bHasRespawned[client]=false;
    }
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new x=1;x<=64;x++)
    bHasRespawned[x]=false;
}

stock TE_SetupDynamicLight(const Float:vecOrigin[3], r,g,b,iExponent,Float:fRadius,Float:fTime,Float:fDecay)
{
    TE_Start("Dynamic Light");
    TE_WriteVector("m_vecOrigin",vecOrigin);
    TE_WriteNum("r",r);
    TE_WriteNum("g",g);
    TE_WriteNum("b",b);
    TE_WriteNum("exponent",iExponent);
    TE_WriteFloat("m_fRadius",fRadius);
    TE_WriteFloat("m_fTime",fTime);
    TE_WriteFloat("m_fDecay",fDecay);
}

public Action:smoke_detonate(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
    new race=War3_GetRace(client);
    if(race==thisRaceID&&!bHasRespawned[client]&&War3_GetGame()!=Game_TF)
    {
        new skill=War3_GetSkillLevel(client,race,SKILL_NADE);
        if(skill)
        {
            if( !IsClientConnected(client) && !IsClientInGame(client) )
            return Plugin_Continue;
            
            new index = CreateEntityByName("point_hurt");
            
            if (index == -1)
            return Plugin_Handled;
            new nervegasdmg=nervegas[skill];
            decl String:explosiondmg[256];
            IntToString(nervegasdmg, explosiondmg, sizeof(explosiondmg));
            DispatchKeyValueFloat(index, "DamageRadius", GetConVarFloat(g_radius));
            //DispatchKeyValueFloat(index, "Damage", GetConVarFloat(g_damage));
            DispatchKeyValue(index, "Damage", explosiondmg);
            DispatchKeyValueFloat(index, "DamageType", 32.00);
            DispatchSpawn(index);
            decl Float:VectorPos[3];
            VectorPos[0]=GetEventFloat(event,"x");
            VectorPos[1]=GetEventFloat(event,"y");
            VectorPos[2]=GetEventFloat(event,"z");
            TeleportEntity(index, VectorPos, NULL_VECTOR, NULL_VECTOR);
            TE_SetupDynamicLight(VectorPos,128,0,255,5,100.0,19.6,2.0);
            TE_SendToAll();
            SetVariantString("OnUser1 !self,kill,-1,20");
            AcceptEntityInput(index, "AddOutput");
            AcceptEntityInput(index, "TurnOn");
            AcceptEntityInput(index, "FireUser1");
            SetEntPropEnt(index, Prop_Send, "m_hOwnerEntity", client);
            //SetEntProp( index, Prop_Data, "m_hOwnerEntity", client);
            War3_ChatMessage(client,"Nervegas Released be carefully!");
            PrintToConsole(client,"[Notice] Your nervegas has a damage level of %d ...",nervegasdmg);
            new Float:position[ 3 ];
            GetClientAbsOrigin( client , Float:position );
            TE_SetupSmoke( position, g_hirnrauch, 10.0, 1 );
            TE_SendToAll();
        }
    }
    return Plugin_Continue;
}