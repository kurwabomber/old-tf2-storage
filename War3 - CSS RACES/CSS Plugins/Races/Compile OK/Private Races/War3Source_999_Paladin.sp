/**
* File: War3Source_999_Paladin.sp
* Description: Paladin race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/haaaxfunctions"

new thisRaceID;
new SKILL_HEAL, SKILL_DAMAGE, SKILL_REVIVE, ULT_IMMUNE;



public Plugin:myinfo = 
{
    name = "War3Source Race - Paladin",
    author = "Remy Lebeau",
    description = "Spraynpray's private race for War3Source",
    version = "0.9",
    url = "http://sevensinsgaming.com"
};


new g_iHealAmount[] = { 0, 10,20,30,40 };
new Float:g_fDmgLevel[] = { 0.0, 0.90, 0.85, 0.80, 0.75 };
new g_iReviveHealth[] = {0, 110, 115, 120, 125};

new XBeamSprite,HaloSprite,BlueSprite;

new String:ultimateSound[256]; //="war3source/item_healthpotion.mp3";
new String:reviveSound[256];
new RevivedBy[MAXPLAYERSCUSTOM];

new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25,27,-27,30,-30};//,33,-33,40,-40};
new MyWeaponsOffset,AmmoOffset;

new bool:bIsActive[MAXPLAYERS];
new Float:g_fUltDuration[] = {0.0, 1.0,1.5,1.75,2.0};

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Paladin [PRIVATE]","paladin");
    
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Shield of faith","Damage reduction",false,4);
    SKILL_HEAL=War3_AddRaceSkill(thisRaceID,"Belt of truth","Heal your teammate with the least health (+ability)",false,4);
    SKILL_REVIVE=War3_AddRaceSkill(thisRaceID,"Paladin's Prayer","Resurrect a team mate (+ability1)",false,4);
    ULT_IMMUNE=War3_AddRaceSkill(thisRaceID,"Breastplate of righteousness","Holy armour provides immunity (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,SKILL_HEAL,10.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");

    AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
}



public OnMapStart()
{
    
    War3_AddSoundFolder(ultimateSound, sizeof(ultimateSound), "item_healthpotion.mp3");
    War3_AddSoundFolder(reviveSound, sizeof(reviveSound), "reincarnation.mp3");
    
    
    
    
    BlueSprite = PrecacheModel( "materials/sprites/physcannon_bluelight1.vmt" );
    XBeamSprite = PrecacheModel( "materials/sprites/XBeam2.vmt" );
    HaloSprite=War3_PrecacheHaloSprite();
    
    
    War3_AddCustomSound(reviveSound);
    War3_AddCustomSound(ultimateSound);
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
    bIsActive[client]=false;

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


public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && ValidPlayer(client,true)){
        if(!Silenced(client)){
            if(War3_SkillNotInCooldown(client,thisRaceID,ULT_IMMUNE,true)){
                new ult_level=War3_GetSkillLevel(client,thisRaceID,ULT_IMMUNE);
                if(ult_level>0){
                    if(War3_SkillNotInCooldown(client,thisRaceID,ULT_IMMUNE,true)){
                        War3_CooldownMGR(client,25.0,thisRaceID,ULT_IMMUNE);
                        CreateTimer(g_fUltDuration[ult_level],StopEthreal, client);
                        bIsActive[client]=true;
                        W3SetPlayerColor(client,thisRaceID,10,10,255,_,GLOW_ULTIMATE);
                        PrintHintText(client, "You're immune now");
                        W3FlashScreen(client,{0,120,255,50});
                    }
                
                }
                else
                {
                    PrintHintText(client, "Level your Ultimate first");
                }
            
            }
        }
        else
        {
            PrintHintText(client, "you are silenced");
        }
    }
}


public Action:StopEthreal(Handle:timer,any:client)
{
    if(ValidPlayer(client))
    {
        bIsActive[client]=false;
        W3ResetPlayerColor(client,thisRaceID);
        PrintHintText(client, "You're not immune anymore");
        W3FlashScreen(client,{0,120,255,50});
    }    
}


public OnAbilityCommand( client, ability, bool:pressed )
{
	if( War3_GetRace( client ) == thisRaceID && pressed && ValidPlayer( client,true ) && !Silenced(client) )
	{
        if (ability == 0 )
        {
            new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_HEAL );
            if( skill_level > 0 )
            {
                if( War3_SkillNotInCooldown( client, thisRaceID, SKILL_HEAL, true ))
                {
                    new target = 0;
                    if( GetClientTeam( client ) == TEAM_T )
                        target = War3_GetRandomPlayer( client, "#t", true, false, false, true );
                    if( GetClientTeam( client ) == TEAM_CT )
                        target = War3_GetRandomPlayer( client, "#ct", true, false, false, true );

                    if( target == 0 )
                    {
                        PrintHintText( client, "No players found for healing" );
                    }
                    else
                    {

                        decl Float:start_pos[3];
                        decl Float:target_pos[3];
                        GetClientAbsOrigin(client,start_pos);
                        GetClientAbsOrigin(target,target_pos);
                        target_pos[2]+=60.0;
                        start_pos[1]+=50.0;
                        TE_SetupBeamPoints(target_pos, start_pos, BlueSprite, HaloSprite, 0, 100, 2.0, 1.0, 3.0, 0, 0.0, {255,0,255,255}, 10);
                        TE_SendToAll();
                        TE_SetupBeamPoints(target_pos, start_pos, BlueSprite, HaloSprite, 0, 100, 2.0, 3.0, 5.0, 0, 0.0, {0,255,0,255}, 30);
                        TE_SendToAll(2.0);    
                        //TE_SetupBeamRingPoint(const Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex(Precache), HaloIndex(Precache), StartFrame, FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags);
                        TE_SetupBeamRingPoint(target_pos, 20.0, 90.0, XBeamSprite, HaloSprite, 0, 1, 1.0, 90.0, 0.0, {0,255,0,255}, 10, 0);
                        TE_SendToAll(2.0);                
                        TE_SetupBeamPoints(target_pos, start_pos, BlueSprite, HaloSprite, 0, 100, 2.0, 5.0, 7.0, 0, 0.0, {0,255,0,255}, 70);
                        TE_SendToAll(4.0);
                        TE_SetupBeamPoints(target_pos, start_pos, BlueSprite, HaloSprite, 0, 100, 2.0, 6.0, 8.0, 0, 0.0, {0,255,0,255}, 170);
                        TE_SendToAll(9.0);
                        
                        W3EmitSoundToAll(ultimateSound,client);
                        W3EmitSoundToAll(ultimateSound,target);
                        
                        War3_HealToMaxHP( target, g_iHealAmount[skill_level] );
                        War3_CooldownMGR( client, 20.0, thisRaceID, SKILL_HEAL, _, _ );
                    }
                    War3_CooldownMGR(client,20.0,thisRaceID,SKILL_HEAL);

                }
            }
        }
        if (ability == 1 )
        {
            new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_REVIVE );
            if( skill_level > 0 )
            {
                if( War3_SkillNotInCooldown( client, thisRaceID, SKILL_REVIVE, true ))
                {
                    new target = 0;
                    if( GetClientTeam( client ) == TEAM_T )
                        target = War3_GetRandomPlayer( client, "#t", false, false, false, false );
                    if( GetClientTeam( client ) == TEAM_CT )
                        target = War3_GetRandomPlayer( client, "#ct", false, false, false, false );
                    if( target == 0 )
                    {
                        PrintHintText( client, "No players found to revive" );
                    }
                    else
                    {
               
                        W3Hint(target,HINT_SKILL_STATUS,5.0,"PREPARE FOR RESPAWN!");
                        PrintCenterText(target,"PREPARE FOR RESPAWN!");
                        War3_ChatMessage(target,"PREPARE FOR RESPAWN!");
                        
                        new String:pName[256];
                        GetClientName (target, pName, 256 );
                        War3_ChatMessage(client,"RESPAWNING |%s| in 2!", pName);
                        RevivedBy[target] = client;
                        CreateTimer(2.0,DoRevival,GetClientUserId(target));
                    }
                    War3_CooldownMGR(client,32.0,thisRaceID,SKILL_REVIVE);
                }
            }
        }
	}
}


public Action:DoRevival(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    if(client>0)
    {
        new savior = RevivedBy[client];
        if(ValidPlayer(savior,true) && ValidPlayer(client))
        {
            if(GetClientTeam(savior)==GetClientTeam(client)&&!IsPlayerAlive(client))
            {
                War3_SpawnPlayer(client);
  
                new Float:VecPos[3];
                new Float:Angles[3];

                GetClientEyeAngles(savior,Angles);
                GetClientAbsOrigin(savior,VecPos);
                
                //VecPos[2] += 50.0;
                TeleportEntity(client, VecPos, Angles, NULL_VECTOR);
                W3EmitSoundToAll(reviveSound,client);
                
                
                
                new skill_level = War3_GetSkillLevel( savior, thisRaceID, SKILL_REVIVE );
                
                War3HealToHP(client, 25, g_iReviveHealth[skill_level]);
                
                
                
                if(War3_GetGame()==Game_CS){
                    //give weapons CS
                    for(new s=0;s<10;s++)
                    {
                        new ent=GetEntDataEnt2(client,MyWeaponsOffset+(s*4));
                        if(ent>0 && IsValidEdict(ent))
                        {
                            new String:ename[64];
                            GetEdictClassname(ent,ename,64);
                            if(StrEqual(ename,"weapon_c4") || StrEqual(ename,"weapon_knife"))
                            {
                                continue; // don't think we need to delete these
                            }
                            W3DropWeapon(client,ent);
                            UTIL_Remove(ent);
                        }
                    }
                    // restore iAmmo
                    for(new s=0;s<32;s++)
                    {
                        SetEntData(client,AmmoOffset+(s*4),War3_CachedDeadAmmo(client,s),4);
                    }
                    // give them their weapons
                    for(new s=0;s<10;s++)
                    {
                        new String:wep_check[64];
                        War3_CachedDeadWeaponName(client,s,wep_check,64);
                        if(!StrEqual(wep_check,"") && !StrEqual(wep_check,"",false) && !StrEqual(wep_check,"weapon_c4") && !StrEqual(wep_check,"weapon_knife"))
                        {
                            new wep_ent=GivePlayerItem(client,wep_check);
                            if(wep_ent>0)
                            {
                                //dont reduce ammo
                                //SetEntData(wep_ent,Clip1Offset,War3_CachedDeadClip1(client,s),4);
                            }
                        }
                    }
                    SetEntProp(client,Prop_Send,"m_ArmorValue",100); //give full armor
                }
                
                
                
                testhull(client);
                
            }
            else
            {
                //this guy changed team?
                RevivedBy[client]=0;

            }
        }
        else
        {
            // savior left or something? maybe dead?
            RevivedBy[client]=0;
        }
    }
    return Plugin_Continue;
}

/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/

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
                new skill_armour = War3_GetSkillLevel(victim, thisRaceID, SKILL_DAMAGE);
                if (skill_armour>0)
                {
                    War3_DamageModPercent(g_fDmgLevel[skill_armour]);
                    new Float:amount = (1-g_fDmgLevel[skill_armour]) * 100; 
                    PrintToConsole(attacker, "Damage Reduced by |%.2f| (percent) against Paladin", amount);
                    PrintToConsole(victim, "Damage Reduced by |%.2f| (percent) by Paladin Shield of Faith", amount);
                }
            }
        }
    }
}



public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
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
                if(bIsActive[victim] && !W3HasImmunity(attacker,Immunity_Ultimates))
                {
                    War3_DamageModPercent(0.0);
                    PrintToConsole(attacker, "|%f| Damage Blocked by Paladin's Holy Shield", damage);
                    PrintToConsole(victim, "|%f| Damage Blocked by Paladin's Holy Shield", damage);
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



public bool:testhull(client){
    
    //PrintToChatAll("BEG");
    new Float:mins[3];
    new Float:maxs[3];
    GetClientMins(client,mins);
    GetClientMaxs(client,maxs);
    
    //PrintToChatAll("min : %.1f %.1f %.1f MAX %.1f %.1f %.1f",mins[0],mins[1],mins[2],maxs[0],maxs[1],maxs[2]);
    new absincarraysize=sizeof(absincarray);
    new Float:originalpos[3];
    GetClientAbsOrigin(client,originalpos);
    
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
                        
                        //PrintToChatAll("hull at %.1f %.1f %.1f",pos[0],pos[1],pos[2]);
                        //PrintToServer("hull at %d %d %d",absincarray[x],absincarray[y],absincarray[z]);
                        TR_TraceHullFilter(pos,pos,mins,maxs,CONTENTS_SOLID|CONTENTS_MOVEABLE,CanHitThis,client);
                        //new ent;
                        if(TR_DidHit(_))
                        {
                            //PrintToChatAll("2");
                            //ent=TR_GetEntityIndex(_);
                            //PrintToChatAll("hit %d self: %d",ent,client);
                        }
                        else{
                            TeleportEntity(client,pos,NULL_VECTOR,NULL_VECTOR);
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
    //PrintToChatAll("END");
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

    