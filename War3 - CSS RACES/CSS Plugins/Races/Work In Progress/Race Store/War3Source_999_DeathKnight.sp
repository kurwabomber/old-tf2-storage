/**
* File: War3Source_DeathKnight.sp
* Description: The Death Knight race for War3Source.
* Author(s): Cereal Killer 
*/
#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdkhooks>
#include <smlib>
new thisRaceID;
public Plugin:myinfo = 
{
    name = "War3Source Race - Death Knight",
    author = "Cereal Killer",
    description = "Death Knight for War3Source.",
    version = "1.3.2",
    url = "http://warcraft-source.net/"
};

new MyWeaponsOffset,AmmoOffset;
new COIL, PACT, UNHOLY, RESPAWNSKILL;
new BeamSprite,HaloSprite;
//new StarSprite,TSprite,CTSprite,BurnSprite,g_iExplosionModel,g_iSmokeModel;
//new ShieldSprite;
new spawnlocation[MAXPLAYERS];
new Float:LastSeenLocation[MAXPLAYERS][3];
new GetAmmo[MAXPLAYERS];
new Float:Coilcooldown[7]={0.0,15.0,12.0,10.0,8.0,7.0,6.0};
new coildamage[7]={0,5,8,10,12,15,18};
new coilheal[7]={0,5,8,10,12,15,18};
new Float:PactChance[7]={0.0,0.5,0.6,0.7,0.8,0.9,1.0};
new Float:UnholySpeed[7]={0.0,1.05,1.1,1.15,1.2,1.25,1.3};
new Float:UnholyHeal[] = {0.0,0.5,1.0,1.5,2.0,2.5,3.0,4.0};
new Laser;
//new Grim;
new AuraID;
new Float:g_fAuraBuffDistance=200.0;

public OnPluginStart(){
//    RegConsoleCmd("DKRM", DKRM);
//    CreateTimer(0.5,Unholyaura,_,TIMER_REPEAT);
    MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
    AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
    HookEvent("round_start",RoundStartEvent);
}
public OnMapStart(){
    BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
//    StarSprite=PrecacheModel("materials/effects/fluttercore.vmt");
//    TSprite=PrecacheModel("VGUI/gfx/VGUI/guerilla.vmt");
//    CTSprite=PrecacheModel("VGUI/gfx/VGUI/gign.vmt");
//    BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");
//    g_iExplosionModel = PrecacheModel("materials/effects/fire_cloud1.vmt");
//    g_iSmokeModel     = PrecacheModel("materials/effects/fire_cloud2.vmt");
//    ShieldSprite=PrecacheModel("sprites/strider_blackball.vmt");
    Laser=PrecacheModel("materials/sprites/laserbeam.vmt");
//    Grim=PrecacheModel("models/player/elis/gr/grimreaper.mdl");
}

public OnWar3PluginReady(){
    
        thisRaceID=War3_CreateNewRace("Death Knight","death");
        COIL=War3_AddRaceSkill(thisRaceID,"Death Coil (+ability)","Heals friends and damages your victim (+ability)",false,6);
        PACT=War3_AddRaceSkill(thisRaceID,"Death Pact","For each player that dies all your team gain health",false,6);
        UNHOLY=War3_AddRaceSkill(thisRaceID,"Unholy Aura","Increases the movement speed and life regeneration rate of nearby friendly units",false,6);
        RESPAWNSKILL=War3_AddRaceSkill(thisRaceID,"Animate Dead","Respawn Infinitely",false,1);
        War3_CreateRaceEnd(thisRaceID);
        
        AuraID=W3RegisterAura("deathknight_speedregenbuff",g_fAuraBuffDistance);
    
}
public OnWar3EventSpawn(client){
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
        W3ResetAllBuffRace( client, thisRaceID );
        new level=War3_GetSkillLevel(client,thisRaceID,UNHOLY);
        W3SetAuraFromPlayer(AuraID,client,level>0?true:false,level);
        War3_SetBuff( client, fDodgeChance, thisRaceID, 1.0);
        War3_SetBuff( client, bDodgeMode, thisRaceID, 0 ) ;
        War3_SetBuff( client, iGlowRed, thisRaceID, true ) ;
        CreateTimer(2.0, StopImmune, client);
        
    }
}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        new level=War3_GetSkillLevel(client,thisRaceID,UNHOLY);
        W3SetAuraFromPlayer(AuraID,client,level>0?true:false,level);
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
        W3SetAuraFromPlayer(AuraID,client,false);
    }
}
public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast){
    for(new i=1;i<=MaxClients;i++){
        if(War3_GetRace(i)==thisRaceID&&ValidPlayer(i,true)){
            LastSeenLocation[i][0]=0.0;
            GetAmmo[i]=0;
        }
    }
}


public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level)
{
    if(aura==AuraID && ValidPlayer(client))
    {
        if (inAura && ValidPlayer(client, true))
        {
            if(level>0)
            {
                //War3_SetBuff( client, iAdditionalMaxHealthNoHPChange, thisRaceID, 0);
                W3FlashScreen(client,RGBA_COLOR_RED);
                War3_SetBuff(client,fMaxSpeed,thisRaceID,UnholySpeed[level]);
                War3_SetBuff(client, fHPRegen, thisRaceID, UnholyHeal[level] );
                W3SetPlayerColor(client,thisRaceID,0,255,0,_,GLOW_SKILL);    
            }
        }
        else if (ValidPlayer(client))
        {
            W3ResetPlayerColor(client,thisRaceID);
            War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
            War3_SetBuff( client, fHPRegen, thisRaceID, 0 );
        }
    }
}


public OnAbilityCommand(client,ability,bool:pressed){
    if (ability==0){
        if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true)){
            new team=GetClientTeam(client);
            if(team == 1 || team == 0)
            {
                new String:SteamID[64];
                new String:pName[256];
                GetClientAuthString( client, SteamID, 64 );
                GetClientName (client, pName, 256 );
                Client_PrintToChat(client,false, "{R}Attempting to glitch hey?  NAUGHTY!");
                Client_PrintToChat(client,false, "\x04Your STEAM ID has been logged, consequences will be forthcoming..");
                LogMessage("Player |%s| with SteamID |%s| has attempted the deathknight glitch", pName, SteamID);
            }
            else
            {
                new skill_level=War3_GetSkillLevel(client,thisRaceID,COIL);
                if(skill_level>0){
                    if(War3_SkillNotInCooldown(client,thisRaceID,COIL,false)){
                        new target = War3_GetTargetInViewCone(client,300.0,true,15.0);
                        if(!Silenced(client)){
                            if(target>0){
                                
                                new targetteam=GetClientTeam(target);
                                if(team==targetteam){
                                    PrintHintText(client,"Death Coil!");
                                    War3_HealToMaxHP(target, coilheal[skill_level]);
                                    //SetEntityHealth(target,GetClientHealth(target)+coilheal[skill_level]);
                                    PrintHintText(target,"Death Coil heals you");
                                    new Float:iPosition[3];
                                    new Float:clientPosition[3];
                                    GetClientAbsOrigin(client, clientPosition);
                                    GetClientAbsOrigin(target, iPosition);
                                    iPosition[2]+=35;
                                    clientPosition[2]+=35;
                                    TE_SetupBeamPoints(iPosition,clientPosition,BeamSprite,HaloSprite,0,35,0.5,6.0,5.0,0,1.0,{50,200,50,255},20);
                                    TE_SendToAll();
                                    War3_CooldownMGR(client,Coilcooldown[skill_level],thisRaceID,COIL,_,_);
                                    new String:wpnstr[32];
                                    GetClientWeapon(target, wpnstr, 32);
                                    for(new slot=0;slot<10;slot++){
                                        
                                        new wpn=GetPlayerWeaponSlot(target, slot);
                                        if(wpn>0){
                                            //PrintToChatAll("wpn %d",wpn);
                                            new String:comparestr[32];
                                            GetEdictClassname(wpn, comparestr, 32);
                                            //PrintToChatAll("%s %s",wpn, comparestr);
                                            if(StrEqual(wpnstr,comparestr,false)){
                                                TE_SetupKillPlayerAttachments(wpn);
                                                TE_SendToAll();
                                                new color[4]={50,200,50,200};
                                                TE_SetupBeamFollow(wpn,Laser,0,0.5,2.0,7.0,1,color);
                                                TE_SendToAll();
                                                break;
                                            }
                                        }
                                    }
                                }
                                else if (!W3HasImmunity( target, Immunity_Skills ))
                                {
                                    PrintHintText(client,"Death Coil!");
                                    War3_DealDamage(target,coildamage[skill_level],client,DMG_CRUSH,"death coil",_,W3DMGTYPE_MAGIC);
                                    new Float:iPosition[3];
                                    new Float:clientPosition[3];
                                    GetClientAbsOrigin(client, clientPosition);
                                    GetClientAbsOrigin(target, iPosition);
                                    iPosition[2]+=35;
                                    clientPosition[2]+=35;
                                    TE_SetupBeamPoints(iPosition,clientPosition,BeamSprite,HaloSprite,0,35,0.5,6.0,5.0,0,1.0,{255,000,255,255},20);
                                    TE_SendToAll();
                                    War3_CooldownMGR(client,Coilcooldown[skill_level],thisRaceID,COIL,_,_ );
                                    new String:wpnstr[32];
                                    GetClientWeapon(target, wpnstr, 32);
                                    for(new slot=0;slot<10;slot++){
                                        
                                        new wpn=GetPlayerWeaponSlot(target, slot);
                                        if(wpn>0){
                                            //PrintToChatAll("wpn %d",wpn);
                                            new String:comparestr[32];
                                            GetEdictClassname(wpn, comparestr, 32);
                                            //PrintToChatAll("%s %s",wpn, comparestr);
                                            if(StrEqual(wpnstr,comparestr,false)){
                                                
                                                TE_SetupKillPlayerAttachments(wpn);
                                                TE_SendToAll();
                                                
                                                new color[4]={255,0,255,200};
                                                TE_SetupBeamFollow(wpn,Laser,0,0.5,2.0,7.0,1,color);
                                                TE_SendToAll();
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                            else {
                                PrintHintText(client,"NO VALID TARGETS");
                                new Float:iPosition[3];
                                new Float:clientPosition[3];
                                GetClientAbsOrigin(client, clientPosition);
                                War3_GetAimEndPoint(client,iPosition);
                                clientPosition[2]+=35;
                                TE_SetupBeamPoints(iPosition,clientPosition,BeamSprite,HaloSprite,0,35,0.5,6.0,5.0,0,1.0,{55,055,055,255},20);
                                TE_SendToAll();
                            }
                        }
                    }
                }
            }
        }    
    }
}    
public OnWar3EventDeath(victim,attacker){
    for(new i=1;i<=MaxClients;i++){
        if(War3_GetRace(i)==thisRaceID){
            new team=GetClientTeam(i);
            if(ValidPlayer(i,true)){
                new skill=War3_GetSkillLevel(i,thisRaceID,PACT);
                if(skill>0){
                    for(new x=1;x<=MaxClients;x++){
                        if(ValidPlayer(x,true)&&GetClientTeam(x)==team){            
                            if(GetRandomFloat(0.0,1.0)<PactChance[skill]){
                                new hpadd=2;
                                War3_HealToMaxHP(x, hpadd);
                                // SetEntityHealth(x,GetClientHealth(i)+hpadd);
                                PrintHintText(x,"Death Pact Gives You 2 HP");
                            }
                            /*else {
                                    PrintHintText(x,"Death Pact Failed");
                            }*/
                        }
                    }
                }
            }
        }
    }
    for(new client=1;client<=MaxClients;client++){
        new skill=War3_GetSkillLevel(client,thisRaceID,RESPAWNSKILL);
        if(skill>0){
            if(War3_GetRace(client)==thisRaceID&&victim==client  ){
                if (!W3HasImmunity(victim,Immunity_Skills)){
                    new Float:waitspawnfloat=GetRandomFloat(5.0,20.0);
                    new String:str[100];
                    Format(str,100,"You will spawn in %.1f seconds",waitspawnfloat);
                    PrintToChat(client, str);
                    //PrintToChat(client, "Say DKRM in console to choose your spawn location");
                    GetClientAbsOrigin(client, LastSeenLocation[client]);
                    GetAmmo[client]=1;
                    CreateTimer(waitspawnfloat,RESPAWNINF,client);
                }
                else{
                    PrintToChat(client, "Someone with skill immunity killed you.  No more respawns!");
                }
            }
        }
    }
}

public Action:StopImmune(Handle:timer,any:client) 
{
    War3_SetBuff( client, fDodgeChance, thisRaceID, 0.0);
    War3_SetBuff( client, iGlowRed, thisRaceID, false ) ;       
}



public Action:RESPAWNINF(Handle:timer,any:client) {
    if(spawnlocation[client]==0){
        War3_SpawnPlayer(client);
    }
    else {
        War3_SpawnPlayer(client);
        if(LastSeenLocation[client][0]==0.0){
        }
        else {
            TeleportEntity(client, LastSeenLocation[client], NULL_VECTOR, NULL_VECTOR);
        }
    }
    if(GetAmmo[client]==1){
        for(new slot=0;slot<10;slot++)
            {
                new ent=GetEntDataEnt2(client,MyWeaponsOffset+(slot*4));
                if(ent>0 && IsValidEdict(ent))
                {
                    new String:ename[64];
                    GetEdictClassname(ent,ename,64);
                    if(StrEqual(ename,"weapon_c4") || StrEqual(ename,"weapon_knife"))
                    {
                        continue; // don't think we need to delete these
                    }
                    UTIL_Remove(ent);
                }
            }
            // restore iAmmo
        for(new ammotype=0;ammotype<32;ammotype++){
            SetEntData(client,AmmoOffset+(ammotype*4),War3_CachedDeadAmmo(client,ammotype),4);
        }
            // give them their weapons
        for(new slot=0;slot<10;slot++){
            new String:wep_check[64];
            War3_CachedDeadWeaponName(client,slot,wep_check,64);
            if(!StrEqual(wep_check,"") && !StrEqual(wep_check,"",false) && !StrEqual(wep_check,"weapon_c4") && !StrEqual(wep_check,"weapon_knife")){
                new wep_ent=GivePlayerItem(client,wep_check);
                if(wep_ent>0) {
                    ///dont set clip
                    //SetEntData(wep_ent,Clip1Offset,War3_CachedDeadClip1(client,slot),4);
                }
            }
        }
    }
}

/*public MenuHandler1(Handle:menu, MenuAction:action, param1, param2)
{
    // If an option was selected, tell the client about the item.
    if (action == MenuAction_Select)
    {
        new String:info[32];
        new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
        PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);
        for(new client=1;client<=MaxClients;client++){
            if(War3_GetRace(client)==thisRaceID){
                if (param1 == 0){
                    spawnlocation[client]=0;
                }
                else {
                    spawnlocation[client]=1;
                }
            }
        }
    }
    // If the menu was cancelled, print a message to the server about it. 
    else if (action == MenuAction_Cancel)
    {
        PrintToConsole(param1, "Client %d's menu was cancelled.  Reason: %d", param1, param2);
    }
    // If the menu has ended, destroy it 
    else if (action == MenuAction_End)
    {
        CloseHandle(menu); 
    }
}*/
 
/*public Action:DKRM(client, args)
{
    if(War3_GetRace(client)==thisRaceID){
        new Handle:menu = CreateMenu(MenuHandler1);
        SetMenuTitle(menu, "Where do you want to spawn?");
        if(spawnlocation[client]==0){
            AddMenuItem(menu, "spawn", "Spawn(selected)");
            AddMenuItem(menu, "sameplace", "Same place where you died");
        }
        if(spawnlocation[client]==1){
            AddMenuItem(menu, "spawn", "Spawn");
            AddMenuItem(menu, "sameplace", "Same place where you died(selected)");
        }
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, client, 20);
     
        return Plugin_Handled;
    }
    else
    {
        return Plugin_Handled;
    }
    
}*/