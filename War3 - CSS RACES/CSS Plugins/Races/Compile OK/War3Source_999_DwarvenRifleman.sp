 /**
* File: War3Source_Dwarven Rifleman.sp
* Description: The Dwarven Rifleman unti for War3Source.
* Author(s): [Oddity]TeacherCreature
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <smlib>


new thisRaceID;
new Handle:ultCooldownCvar;
new Handle:g_radius;
//skill 1
//new LongRifleAmmo[9]={0,12,14,16,18,20,22,24,26};
new nervegas[]={0,1,1,2,3,4,5,6,7};
new g_hirnrauch;
new Handle:timer_handle[MAXPLAYERS+1];

//skill 2
new Float:GunPowderPercent[9]={0.0,0.2,0.22,0.24,0.26,0.28,0.30,0.32,0.35};
new Float:GunPowderChance[9]={0.0,0.3,0.35,0.4,0.45,0.5,0.55,0.6,0.65};

//skill 3
new Float:DragonHideSpeedArr[9]={1.0,0.96,0.94,0.92,0.9,0.88,0.86,0.84,0.82};
new DragonHideHealthArr[9]={0,25,35,45,55,65,75,86,95};

//skill 4
new bool:bTakeAim[66];
new String:takeaimSound1[]="war3source/particle_suck1.wav";
new String:takeaimSound2[]="weapons/explode5.wav";

new SKILL_NADE, SKILL_GUNPOWDER, SKILL_DRAGONHIDE, ULT_TAKEAIM;

public Plugin:myinfo = 
{
    name = "War3Source Race - Dwarven Rifleman",
    author = "[Oddity]TeacherCreature & Remy Lebeau",
    description = "The Dwarven Rifleman race for War3Source.",
    version = "1.2.1",
    url = "warcraft-source.net"
}

public OnPluginStart()
{
    HookEvent("weapon_fire", WeaponFire);
    HookEvent("smokegrenade_detonate",smoke_detonate);
    g_radius = CreateConVar("war3_dr_nervegas_radius","200");
    ultCooldownCvar=CreateConVar("war3_dr_takeaim_cooldown","15.0","Cooldown for Take Aim");
    HookEvent("round_end",RoundOverEvent);
}

public OnMapStart()
{
    PrecacheSound("weapons/explode5.wav",false);
    g_hirnrauch = PrecacheModel( "particle/fire.vmt");
    if(!War3_AddCustomSound(takeaimSound1)){
        SetFailState("[War3Source DWARVEN RIFLEMAN] FATAL ERROR! FAILURE TO PRECACHE SOUND %s!!! CHECK TO SEE IF U HAVE THE SOUND FILES",takeaimSound1);
    }
}

public OnWar3PluginReady()
{
        //SKILL_LONGRIFLE=War3_AddRaceSkill(thisRaceID,"Long Rifle (passive)","Ammo for your rifle",false,8);
        thisRaceID=War3_CreateNewRace("Dwarven Rifleman","dwarvenrifle");
        SKILL_NADE=War3_AddRaceSkill(thisRaceID,"Nervegas","Detonated Smokegrenades will release a cloud of nervegas to hurt victims",false,8);
        
        SKILL_GUNPOWDER=War3_AddRaceSkill(thisRaceID,"Gun Powder (attacker)","Extra Damage",false,8);
        SKILL_DRAGONHIDE=War3_AddRaceSkill(thisRaceID,"Dragon Hide (passive)","More health less speed",false,8);
        ULT_TAKEAIM=War3_AddRaceSkill(thisRaceID,"Take Aim","Your next bullet will do double damage if it hits",true,1); 
        War3_CreateRaceEnd(thisRaceID);
    
    
}

public OnRaceChanged(client,oldrace,newrace)
{
    if(newrace != thisRaceID)
    {
        W3ResetAllBuffRace(client,thisRaceID);
        War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
        War3_WeaponRestrictTo(client,thisRaceID,"");
    }
    if(newrace == thisRaceID)
    {
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_awp,weapon_smokegrenade");
        if(ValidPlayer(client,true))
        {
            GivePlayerItem(client,"weapon_awp");
            GivePlayerItem(client,"weapon_smokegrenade");
        }
    }
}


public OnWar3EventDeath(victim, attacker)
{
    if (War3_GetRace(victim) == thisRaceID && ValidPlayer(victim))
    {
        W3ResetAllBuffRace(victim,thisRaceID);
        if(timer_handle[victim] != INVALID_HANDLE)
        {
            KillTimer(timer_handle[victim]);
            timer_handle[victim] = INVALID_HANDLE;
        }
    } 
}


public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
    {
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        if(vteam!=ateam)
        {
            new race_attacker=War3_GetRace(attacker);
            new Float:chance_mod=W3ChanceModifier(attacker);
            // Take Aim
            new skill_level_takeaim=War3_GetSkillLevel(attacker,thisRaceID,ULT_TAKEAIM);
            if(race_attacker==thisRaceID && bTakeAim[attacker] && skill_level_takeaim>0 && !W3HasImmunity(victim,Immunity_Ultimates)&&!Silenced(attacker))
            {
                War3_DamageModPercent(2.0);
                W3FlashScreen(victim,RGBA_COLOR_RED);
                bTakeAim[attacker]=false;
                PrintHintText(attacker,"DOUBLE DAMAGE");
            }
            // Gun Powder
            new skill_level_gunpowder=War3_GetSkillLevel(attacker,thisRaceID,SKILL_GUNPOWDER);
            if(race_attacker==thisRaceID && skill_level_gunpowder>0 && !Silenced(attacker))
            {
                if(GetRandomFloat(0.0,1.0)<=GunPowderChance[skill_level_gunpowder]*chance_mod && !W3HasImmunity(victim,Immunity_Skills))
                {
                    EmitSoundToAll(takeaimSound2,attacker);
                    War3_DamageModPercent(GunPowderPercent[skill_level_gunpowder]+1.0);
                    //PrintToConsole(attacker,"+%d GUNPOWDER DAMAGE (SDKhooks)");
                    W3FlashScreen(victim,RGBA_COLOR_RED);
                    W3FlashScreen(attacker,RGBA_COLOR_WHITE);
                    PrintHintText(attacker,"GUNPOWDER");
                }
            }
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && ValidPlayer(client))
    {
        new ultLevel=War3_GetSkillLevel(client,thisRaceID,ULT_TAKEAIM);
        if(ultLevel>0)
        {
            if(!Silenced(client))
            {
                new Float:cooldown=GetConVarFloat(ultCooldownCvar);
                if(War3_SkillNotInCooldown(client,thisRaceID,ULT_TAKEAIM,true ) && !bTakeAim[client])
                {    
                    EmitSoundToAll(takeaimSound1,client);
                    bTakeAim[client]=true;
                    
                    SetEntityMoveType(client,MOVETYPE_NONE);
                    War3_SetBuff(client,bNoMoveMode,thisRaceID,true);
                    PrintHintText(client,"Take Aim");
                    //EmitSoundToAll(takeaimSound1,client);
                    War3_CooldownMGR(client,cooldown,thisRaceID,ULT_TAKEAIM,_,_);
                }
            }
            else
            {
                PrintHintText(client,"Silenced: Can Not Cast"); 
            }
        }
        else
        {
            PrintHintText(client,"Level Your Ultimate First");
        }    
    }
}

public Action:WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new index=GetClientOfUserId(userid);
    if(index>0)
    {
        new race=War3_GetRace(index);
        if(race==thisRaceID&&War3_GetGame()!=Game_TF&&bTakeAim[index])
        {
            CreateTimer(0.7,removeaim,index);
            SetEntityMoveType(index,MOVETYPE_WALK);
            War3_SetBuff(index,bNoMoveMode,thisRaceID,false);
        }
    }
}    

public Action:removeaim(Handle:h,any:index){
    bTakeAim[index]=false;
}

public OnWar3EventSpawn(client)
{
    if(War3_GetRace(client)==thisRaceID)
    {
        War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
        bTakeAim[client]=false;
        new skill_drag=War3_GetSkillLevel(client,thisRaceID,SKILL_DRAGONHIDE);
        if(skill_drag)
        {
            // Dragon Hide
            new hpadd=DragonHideHealthArr[skill_drag];
            War3_SetBuff( client, iAdditionalMaxHealth, thisRaceID, hpadd);
            new Float:speed=DragonHideSpeedArr[skill_drag];
            War3_SetBuff(client,fSlow,thisRaceID,speed);
        }
        
        GivePlayerItem(client,"weapon_awp");
        timer_handle[client]=CreateTimer(2.0,smoke,GetClientUserId(client));
    }
}

public Action:smoke(Handle:t,any:userid)
{
    new client = GetClientOfUserId(userid);
    timer_handle[client]=INVALID_HANDLE;
    if (War3_GetRace(client)== thisRaceID && ValidPlayer(client,true))
    {       
        Client_RemoveWeapon(client, "weapon_smokegrenade");
        GivePlayerItem(client,"weapon_smokegrenade");
    }    
}


public Action:smoke_detonate(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
    new race=War3_GetRace(client);
    if(race==thisRaceID&&War3_GetGame()!=Game_TF)
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
            War3_ChatMessage(client,"Nervegas Released be carefull!");
            PrintToConsole(client,"[Notice] Your nervegas has a damage level of %d ...",nervegasdmg);
            new Float:position[ 3 ];
            GetClientAbsOrigin( client , Float:position );
            TE_SetupSmoke( position, g_hirnrauch, 10.0, 1 );
            TE_SendToAll();
            PrintHintText(client,"You will receive another smoke nade in 45 seconds");
            CreateTimer(45.0,smoke,GetClientUserId(client));
        }
    }
    return Plugin_Continue;
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



public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if(ValidPlayer(i) && timer_handle[i] != INVALID_HANDLE)
        {
            KillTimer(timer_handle[i]);
            timer_handle[i] = INVALID_HANDLE;
        }
    }
}
