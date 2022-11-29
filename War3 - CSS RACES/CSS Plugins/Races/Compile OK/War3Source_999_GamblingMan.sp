/**
* File: War3Source_999_GamblingMan.sp
* Description: The Gambling Man race for War3Source.
* Author(s): Remy Lebeau
* Thanks: xDr.HaaaaaaaXx, Anthony Iacono, necavi, Ownz, M.A.C.A.B.R.A & Lucky - a lot of the code in here is from - or adapted from - their races.
* REQUIRED: Snapshot 882+ to compile/run
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"


// War3Source stuff + Sprite/Sound Variable
new thisRaceID;
new SKILL_HP, SKILL_SPEED, SKILL_PROPS, SKILL_IMMUNITY, SKILL_LUCKYDRAW, SKILL_WEPS;
new HaloSprite, BeamSprite, BurnSprite;
new String:entangleSound[256];
new String:teleportSound[256];
new bool:GambleToggle[MAXPLAYERS];


// Chance/Data Arrays  // HP
new bool:HPGambled[MAXPLAYERS];
new bool:VampireSelf[MAXPLAYERS];
new HealthPlusChance[6] = { 0, 20, 40, 60, 80, 99 };
new HealthMinusChance[6] = { 0, -20, -40, -60, -80, -99 };
new Float:RegenChance[6] = { 0.0, 1.0, 2.0, 3.0, 4.0, 5.0 };
new Float:DecayChance[6] = { 0.0, 0.5, 1.0, 1.5, 2.0, 2.5 };
new Float:VampirePlusChance[6] = { 0.0, 0.08, 0.14, 0.20, 0.25, 0.30 };
new Float:vampirebonus;


// Chance/Data Arrays  // SPEED
new bool:SpeedGambled[MAXPLAYERS];
new Float:SpeedPlusChance[6] = { 1.0, 1.05, 1.1, 1.2, 1.3, 1.4 };
new Float:SpeedMinusChance[6] = { 1.0, 0.95, 0.9, 0.8, 0.7, 0.6 };
new Float:AttackSpeedPlusChance[6] = { 1.0, 1.1, 1.2, 1.3, 1.4, 1.5 };
new Float:AttackSpeedMinusChance[6] = { 1.0, 0.9, 0.8, 0.7, 0.6, 0.5 };


// Chance/Data Arrays  // PROPERTIES
new bool:PropsGambled[MAXPLAYERS];
new bool:EvadeSelf[MAXPLAYERS];
new bool:DamageSelf[MAXPLAYERS];
new Float:InvisChance[6]={1.0, 0.8, 0.6, 0.4, 0.2, 0.01};
new Float:GravityPlusChance[6]={1.0, 0.85, 0.75, 0.6, 0.55, 0.5};
new Float:GravityMinusChance[6]={1.0, 1.15, 1.25, 1.4, 1.45, 1.5};
new Float:EvadeChance[6]={0.0,0.05,0.07,0.13,0.15, 0.17};
new Float:DamageChance[6]={0.0,0.05,0.10,0.15,0.20,0.25};
new Float:evadebonus; 
new Float:dmgbonus;


// Chance/Data Arrays  // IMMUNITY
new bool:ImmunityGambled[MAXPLAYERS];
new Float:GetImmunityChance[6] = { 0.0, 0.2, 0.3, 0.4, 0.5, 0.6 };
new W3Buff:ImmunityList[] = {bImmunitySkills, bImmunityUltimates, bImmunityWards, bImmunityItems};
new bool:BurnToggle[MAXPLAYERS];
new bool:ShopmenuToggle[MAXPLAYERS];


// Chance/Data Arrays  // WEPS
new String:WeaponChance[25][] = {"weapon_knife", "weapon_glock", "weapon_usp", "weapon_p228", "weapon_deagle", "weapon_elite", "weapon_fiveseven", "weapon_m3", "weapon_xm1014", "weapon_galil", "weapon_ak47", "weapon_scout", "weapon_sg552", "weapon_awp", "weapon_g3sg1", "weapon_famas", "weapon_m4a1", "weapon_aug", "weapon_sg550", "weapon_mac10", "weapon_tmp", "weapon_mp5navy", "weapon_ump45", "weapon_p90", "weapon_m249"};
new weaponGive[MAXPLAYERS];

// Chance/Data Arrays  // LUCKYDRAW
new bool:UltiGambled[MAXPLAYERS];
new UltiSelect[MAXPLAYERS];
new Float:UltiCooldown = 20.0;
new Float:EntangleDistance = 600.0;
new Float:EntangleDuration = 2.0;
new bool:bFlying[MAXPLAYERS];
new bool:bIsEntangled[MAXPLAYERS];
new Float:TeleportDistance=850.0;
new bool:inteleportcheck[MAXPLAYERS];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};




public Plugin:myinfo = 
{
    name = "War3Source Race - Gambling Man",
    author = "Remy Lebeau",
    description = "The Gambling Man race for War3Source.",
    version = "1.2.3",
    url = ""
};

public OnWar3PluginReady()
{
    thisRaceID = War3_CreateNewRace( "Gambling Man", "gambling" );
    
    SKILL_HP = War3_AddRaceSkill( thisRaceID, "Gamble with your health", "You have a chance of getting (+/-) health, regen and vampire (ability)", false, 5 );    
    SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Gamble with your speed", "You have a chance of getting (+/-) run and fire speed (ability1)", false, 5 );    
    SKILL_PROPS = War3_AddRaceSkill( thisRaceID, "Gamble with your self", "You have a chance of getting (+/-) visibility, damage bonus, grav and evade (ability2)", false, 5 );
    SKILL_IMMUNITY = War3_AddRaceSkill( thisRaceID, "Gamble at immunity", "If you're REALLY lucky, you'll be immune to ultis or wards or skills!\nUnlucky gamblers are set on fire and can't use shopmenu. (ability3) 10-50%", false, 4 );

    if(War3_GetGame()!=Game_TF) 
    SKILL_WEPS = War3_AddRaceSkill( thisRaceID, "Gamble for a weapon", "Anything from a knife to a machine gun (level up for more options) (passive)", false, 12 );
    
    
    SKILL_LUCKYDRAW = War3_AddRaceSkill( thisRaceID, "Try the luckydraw", "You could get some GREAT +ultimates (fly, entangle, teleport)\nYou could get some BAD stuff (beacon, disarmed) (ulti)", false, 5 );
    
    War3_CreateRaceEnd( thisRaceID );
}

public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
    
    RegConsoleCmd("gambletoggle",War3Source_GambleToggle,"Toggle between auto-gambling at the start of each round, or press ability keys to do it.");
    RegConsoleCmd("say gambletoggle",War3Source_GambleToggle,"Toggle between auto-gambling at the start of each round, or press ability keys to do it.");
    RegConsoleCmd("say_team gambletoggle",War3Source_GambleToggle,"Toggle between auto-gambling at the start of each round, or press ability keys to do it.");
}

public Action:War3Source_GambleToggle(client, args)
{
    if(War3_GetRace(client)==thisRaceID)
    {
        if (GambleToggle[client] == false)
        {
            GambleToggle[client] = true;
            PrintToChat(client, "Autogamble on spawn enabled.");
        }
        else 
        {
            GambleToggle[client] = false;
            PrintToChat(client, "You will now gamble manually!");
            
        }
    
    }
    return Plugin_Handled;
    
}

public OnMapStart()
{
    BeamSprite = War3_PrecacheBeamSprite();
    HaloSprite = War3_PrecacheHaloSprite();
    BurnSprite = PrecacheModel("materials/sprites/fire1.vmt");
    strcopy(entangleSound,sizeof(entangleSound),"war3source/entanglingrootsdecay1.mp3");
    strcopy(teleportSound,sizeof(teleportSound),"war3source/blinkarrival.mp3");
    
    War3_PrecacheSound(entangleSound);
    War3_PrecacheSound(teleportSound);
}

/***************************************************************************
*
*
*                PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/

public OnWar3EventDeath(victim,attacker)
{
    if( War3_GetRace( victim ) == thisRaceID )
    {
        ResetPassiveSkills(victim);
    }
}


public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            ResetPassiveSkills(i);
        }
    }
}


public ResetPassiveSkills( client )
{
    War3_WeaponRestrictTo(client,thisRaceID,"");
    W3ResetAllBuffRace( client, thisRaceID );
    UltiGambled[client] = false ;
    HPGambled[client] = false;
    SpeedGambled[client] = false;
    PropsGambled[client] = false;
    ImmunityGambled[client] = false;
    UltiSelect[client] = 0 ;
    VampireSelf[client]= false;
    EvadeSelf[client] = false;
    DamageSelf[client] = false;
    BurnToggle[client] = false;
    bIsEntangled[client] = false;
    bFlying[client] = false;
    weaponGive[client] = 0;
}

public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        ResetPassiveSkills(client);
        PrintToChat(client, "Say !gambletoggle to toggle between automatic gambling each round, or using ability keys to individually gamble.");
        if (GambleToggle[client] == false)
        {
            HaveAGamble( client );
        }
        else
        {
            if(War3_GetGame()!=Game_TF) 
                GambleWeapons(client);
        }
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
    if( race == thisRaceID && ValidPlayer( client ))
    {
        PrintToChat(client, "Say !gambletoggle to toggle between automatic gambling when spawning, or using ability keys to individually gamble.");
        ResetPassiveSkills(client);
        ShopmenuToggle[client] = false;
        if (GambleToggle[client] == false)
        {
            HaveAGamble( client );
        }
        else
        {
            if(War3_GetGame()!=Game_TF) 
                
                GambleWeapons(client);
        }
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
    if(War3_GetRace(client)==thisRaceID && pressed && ValidPlayer(client, true))
    {
        if(GambleToggle[client] == false)
        {
            if (ability == 0 && HPGambled[client] == false)
            {
                GambleHP(client);
                
        
            }
            else if (ability == 1 && SpeedGambled[client] == false)
            {
                GambleSpeed(client);
        
            }
            else if (ability == 2 && PropsGambled[client] == false)
            {
                GambleProps(client);
        
            }
            else if (ability == 3 && ImmunityGambled[client] == false)
            {
                GambleImmunity(client);
                
            }
    
        }
        else
        {
            PrintToChat(client, "Say !gambletoggle to toggle between automatic gambling each round, or using ability keys to individually gamble.");
        }
    
    }
}


public OnUltimateCommand( client, race, bool:pressed )
{
    if(race==thisRaceID && pressed && ValidPlayer(client,true))
    {
        new skill_luckydraw = War3_GetSkillLevel( client, thisRaceID, SKILL_LUCKYDRAW );
        if(!Silenced(client))
        {
            if(skill_luckydraw>0){
                // FIRST TIME ULTI IS PRESSED WE WANT TO GAMBLE
                if( UltiGambled[client] == false)
                {
                    UltiSelect[client] = GetRandomInt( 0,skill_luckydraw-1 );
                    UltiGambled[client] = true;
                    switch(UltiSelect[client])
                    {
                        case 0:
                        {
                            PrintHintText(client, "Good gamble, your ultimate is now set to | Entangle |");
                        }
                        case 1:
                        {
                            ServerCommand( "sm_beacon #%d", GetClientUserId( client ) );
                            PrintHintText(client, "Bad gamble! You are now beaconed.");
                        }
                        case 2:
                        {
                            PrintHintText(client, "Good gamble, you can now | FLY | ");
                        }
                        case 3:
                        {
                            War3_SetBuff( client, bDisarm, thisRaceID, true  );
                            PrintHintText(client, "BAD gamble! You are now disarmed.  You will be unable to fire this round.");
                        }
                        case 4:
                        {
                            PrintHintText(client, "Good gamble, your ultimate is now set to | Teleport |");
                        }
                    }
                                    
                }
                
                // SUBSEQUENT PRESSESS FIRE OUR NEW ULTIMATE IF IT EXISTS
                else
                {
                    switch(UltiSelect[client])
                    {
                        case 0:                      // Entangle
                        {
                            if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_LUCKYDRAW,true))
                            {
                                new Float:distance=EntangleDistance;
                                new target;
                                new Float:our_pos[3];
                                GetClientAbsOrigin(client,our_pos);
                                target=War3_GetTargetInViewCone(client,distance,false,23.0,ImmunityCheck);
                                if(ValidPlayer(target,true))
                                {                    
                                    bIsEntangled[target]=true;
                
                                    War3_SetBuff(target,bNoMoveMode,thisRaceID,true);
                                    new Float:entangle_time=EntangleDuration;
                                    CreateTimer(entangle_time,StopEntangle,target);
                                    new Float:effect_vec[3];
                                    GetClientAbsOrigin(target,effect_vec);
                                    effect_vec[2]+=15.0;
                                    TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,255,0,255},10,0);
                                    TE_SendToAll();
                                    effect_vec[2]+=15.0;
                                    TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,255,0,255},10,0);
                                    TE_SendToAll();
                                    effect_vec[2]+=15.0;
                                    TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,255,0,255},10,0);
                                    TE_SendToAll();
                                    our_pos[2]+=25.0;
                                    TE_SetupBeamPoints(our_pos,effect_vec,BeamSprite,HaloSprite,0,50,4.0,6.0,25.0,0,12.0,{80,255,90,255},40);
                                    TE_SendToAll();
                                    new String:name[64];
                                    GetClientName(target,name,64);
                                    W3EmitSoundToAll(entangleSound,target);
                                    W3EmitSoundToAll(entangleSound,target);
                    
                                    W3MsgEntangle(target,client);
                                    War3_CooldownMGR(client,UltiCooldown,thisRaceID,SKILL_LUCKYDRAW,_,_);
                                }
                                else
                                {
                                    W3MsgNoTargetFound(client,distance);
                                }
                            }
                        
                        }
                        case 1:
                        {
                            PrintHintText(client, "Beaconing only happens once!  Try gambling again next round.");
                        }
                        case 2:                        // FLY 
                        {
                            if( War3_SkillNotInCooldown( client, thisRaceID, SKILL_LUCKYDRAW, true ) ) 
                            {
                                if( !bFlying[client] )
                                {
                                    bFlying[client] = true;
                    
                                    War3_SetBuff( client, bFlyMode, thisRaceID, true );
                                    War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.9 );
                    
                                    PrintToChat( client, "\x01: \x04GAMBLING makes you feel like flying!" );
                    
                                    CreateTimer( 5.0, StopFly, client );
                    
                                    CreateTimer( 4.0, Land1, client );
                                    CreateTimer( 3.0, Land2, client );
                                    CreateTimer( 2.0, Land3, client );
                    
                                    War3_CooldownMGR( client,UltiCooldown, thisRaceID, SKILL_LUCKYDRAW, _, false );
                                }
                            }    
                        }
                        case 3:
                        {
                            PrintHintText(client, "Disarming only happens once!  Try gambling again next round.");
                        }
                        case 4:                        // TELEPORT
                        {
                            if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_LUCKYDRAW,true))
                            {
                                TeleportPlayerView(client,TeleportDistance);
                            }
                            
                        }
                    } 
                
                }
            
            }
            else
            {
                PrintHintText(client, "Level your Ultimate first");
            }
        }
        else
        {
            PrintHintText(client, "You cannot use ulti while silenced.");
        }
        
    }

}



public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( victim ) == thisRaceID )
        {
        
        // ******** REVERSE VAMPIRE (OTHER PLAYERS GET HEALTH OFF YOU) *****************
        
        
            new skill_hp = War3_GetSkillLevel( victim, thisRaceID, SKILL_HP );
            if( GetRandomFloat( 0.0, 1.0 ) <= 0.80 && skill_hp > 0 && VampireSelf[victim] == false && HPGambled[victim] == true)
            {
                new Float:start_pos[3];
                new Float:target_pos[3];
                new dmgreturn;
                GetClientAbsOrigin( attacker, start_pos );
                GetClientAbsOrigin( victim, target_pos );
                
                start_pos[2] += 40;
                target_pos[2] += 40;
                
                TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 35, 1.0, 40.0, 40.0, 0, 40.0, { 50, 50, 255, 255 }, 40 );
                TE_SendToAll();
                dmgreturn = RoundToFloor( damage * vampirebonus );
                War3_HealToBuffHP( attacker, dmgreturn );
                W3FlashScreen( victim, RGBA_COLOR_RED );
                W3FlashScreen( attacker, RGBA_COLOR_GREEN );
                PrintHintText(victim, "Your attacker stole %d health from you. That gamble keeps hurting!", dmgreturn);
                PrintHintText(attacker, "Your victim lost a gamble, they donated %d health to you.", dmgreturn);
            }
        }
    }
}

public OnW3TakeDmgBulletPre(victim, attacker, Float:damage)
{
    if( ValidPlayer(attacker) && ValidPlayer (victim) && victim > 0 && attacker > 0 && attacker != victim )
    {
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        if(vteam!=ateam)
        {
            new race_victim=War3_GetRace(victim);
            new race_attacker=War3_GetRace(attacker);
            new skill_props_v = War3_GetSkillLevel( victim, thisRaceID, SKILL_PROPS );
            new skill_props_a = War3_GetSkillLevel( attacker, thisRaceID, SKILL_PROPS );
            
            // ******** REVERSE DMG BONUS (OTHER PLAYERS DO EXTRA DMG TO YOU) *****************    
            
            if(race_victim==thisRaceID && skill_props_v > 0 && !Hexed(victim,false) && PropsGambled[victim])
            {
                if(!W3HasImmunity(attacker,Immunity_Skills) && DamageSelf[victim] == false && GetRandomFloat( 0.0, 1.0 ) <= 0.8)
                {        
                    War3_DamageModPercent(dmgbonus + 1.0);            
                    W3FlashScreen(victim,RGBA_COLOR_RED);
                    PrintHintText(victim, "Your attacker did %.2f bonus damage . That gamble keeps hurting!", dmgbonus);
                    PrintHintText(attacker, "Your victim lost a gamble, you did %.2f bonus damage to them.", dmgbonus);
                }    
            }
            
            
            // ******** REVERSE EVADE (OTHER PLAYERS EVADE YOUR SHOTS) *****************    
            
            if(race_attacker==thisRaceID && skill_props_a > 0 && !Hexed(attacker,false) && PropsGambled[attacker])
            {
                if(!W3HasImmunity(victim,Immunity_Skills) && EvadeSelf[attacker] == false && GetRandomFloat( 0.0, 1.0 ) < EvadeChance[skill_props_a])
                {    
                    W3FlashScreen(attacker,RGBA_COLOR_BLUE);
                    War3_DamageModPercent(0.0); //NO DAMAMGE
                    W3Hint(victim, HINT_SKILL_STATUS, 1.0, "%T", "You Evaded a Shot", victim);
                    W3Hint(attacker, HINT_SKILL_STATUS, 1.0, "%T", "Enemy Evaded", attacker);
                }            
            }
        }
    }
}

public GambleHP (client)
{
    new skill_hp = War3_GetSkillLevel( client, thisRaceID, SKILL_HP );
    HPGambled[client] = true;
    
    // ************** SET HP BUFFS ***************************
        
    if (skill_hp > 0) 
    {
        new hpbonus;
        new bool:regenpos = false;
        new Float:regenbonus;

        if (GetRandomFloat( 0.0, 1.0 ) <= 0.60)     // APPLY POSITIVE BONUS
        {
            hpbonus = HealthPlusChance[GetRandomInt( 0, skill_hp )];
            War3_SetBuff( client, iAdditionalMaxHealth, thisRaceID, hpbonus  );
            
        }
        else                                         // APPLY NEGATIVE BONUS
        {
            hpbonus = HealthMinusChance[GetRandomInt( 0, skill_hp )];
            War3_SetBuff( client, iAdditionalMaxHealth, thisRaceID, hpbonus  );
            
        }
        
                            
    
    // ************** SET REGEN/DECAY BUFFS ***************************
    
    
        if (GetRandomFloat( 0.0, 1.0 ) <= 0.60)     // APPLY POSITIVE BONUS
        {
            regenbonus = RegenChance[GetRandomInt( 0, skill_hp )];
            War3_SetBuff( client, fHPRegen, thisRaceID, regenbonus  );
            
        }
        else                                         // APPLY NEGATIVE BONUS
        {
            regenbonus = DecayChance[GetRandomInt( 0, skill_hp )];
            War3_SetBuff( client, fHPDecay, thisRaceID, regenbonus  );
            regenpos = true;
            
            
        }
    
    
        // ************** SET VAMPIRE BUFFS ***************************
        new Float:temp;
        vampirebonus = VampirePlusChance[GetRandomInt( 0, skill_hp )];
        if (GetRandomFloat( 0.0, 1.0 ) <= 0.60)
        {
            VampireSelf[client] = true;
            War3_SetBuff( client, fVampirePercent, thisRaceID, vampirebonus  );
            
        }
        else
        {
            VampireSelf[client] = false;
            
        }
    
        if (regenpos == true)
            regenbonus = -regenbonus;
    
        temp = vampirebonus;
        if (VampireSelf[client] == false)
            temp = -vampirebonus;
        PrintToChat(client, "\x01 HEALTH GAMBLE RESULTS: \x04 HP: (%d), REGEN: (%.2f), VAMP: (%.2f)",hpbonus,regenbonus, temp);
    }    
}

public GambleSpeed (client)
{
    new skill_speed = War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED );    
    SpeedGambled[client] = true;
    if (skill_speed > 0)
    {
        
        new Float:speedbonus, Float:attackbonus;
        
        // ************** SET SPEED BUFFS ***************************
    
    
        if (GetRandomFloat( 0.0, 1.0 ) <= 0.60)     // APPLY POSITIVE BONUS
        {
            speedbonus = SpeedPlusChance[GetRandomInt( 0, skill_speed )];
            War3_SetBuff( client, fMaxSpeed, thisRaceID, speedbonus  );
            
        }
        else                                         // APPLY NEGATIVE BONUS
        {
            speedbonus = SpeedMinusChance[GetRandomInt( 0, skill_speed )];
            War3_SetBuff( client, fSlow, thisRaceID, speedbonus  );
            
        }
    
        
    // ************** SET ATTACK SPEED BUFFS ***************************
    
        if (GetRandomFloat( 0.0, 1.0 ) <= 0.60)     // APPLY POSITIVE BONUS
        {
            attackbonus = AttackSpeedPlusChance[GetRandomInt( 0, skill_speed )];
            War3_SetBuff( client, fAttackSpeed, thisRaceID, attackbonus  );
            
        }
        else                                         // APPLY NEGATIVE BONUS
        {
            attackbonus = AttackSpeedMinusChance[GetRandomInt( 0, skill_speed )];
            War3_SetBuff( client, fAttackSpeed, thisRaceID, attackbonus  );
            
        }
    
    
        PrintToChat(client, "\x01 SPEED GAMBLE RESULTS: \x04 SPEED: (%.2f), ATT SPEED: (%.2f)",speedbonus,attackbonus);
    }
}

public GambleProps( client )
{
    new skill_props = War3_GetSkillLevel( client, thisRaceID, SKILL_PROPS );
    PropsGambled[client] = true;
    if (skill_props > 0 )
    {    
        new Float:invisbonus = 1.0;
        new Float:gravitybonus;    
            
                // ************** SET VISIBILITY BUFFS ***************************
        if (GetRandomFloat( 0.0, 1.0 ) <= 0.60)
        {
            invisbonus = InvisChance[GetRandomInt( 0, skill_props )];
            War3_SetBuff( client, fInvisibilitySkill, thisRaceID, invisbonus  );
            War3_SetBuff(client,bDoNotInvisWeapon,thisRaceID,true);
            
        }
        else
        {
            War3_SetBuff( client, iGlowRed, thisRaceID, true  );  
            
        
        }
        
            // ************** SET DAMAGE BUFFS ***************************
        new Float:temp;
        dmgbonus = DamageChance[GetRandomInt( 0, skill_props )];
        temp = dmgbonus;
        if (GetRandomFloat( 0.0, 1.0 ) <= 0.60)
        {
            DamageSelf[client] = true;
            War3_SetBuff( client, fDamageModifier, thisRaceID, dmgbonus  );
            
        }
        else
        {
            DamageSelf[client] = false; 
            
        
        }
        
        
            // ************** SET GRAVITY BUFFS ***************************
        
        if (GetRandomFloat( 0.0, 1.0 ) <= 0.60)     // APPLY POSITIVE BONUS
        {
            gravitybonus = GravityPlusChance[GetRandomInt( 0, skill_props )];
            War3_SetBuff( client, fLowGravitySkill, thisRaceID, gravitybonus  );
            
        }
        else                                         // APPLY NEGATIVE BONUS
        {
            gravitybonus = GravityMinusChance[GetRandomInt( 0, skill_props )];
            War3_SetBuff( client, fLowGravitySkill, thisRaceID, gravitybonus  );
            
        }
    
        // ************** SET EVADE BUFFS ***************************
        new Float:temp2;
        evadebonus = EvadeChance[GetRandomInt( 0, skill_props )];
        temp2 = evadebonus;
        EvadeSelf[client] = true;
        if (evadebonus != 0.0)
        {
            if (GetRandomFloat( 0.0, 1.0 ) <= 0.60)     // APPLY POSITIVE BONUS
            {
                EvadeSelf[client] = true;
                War3_SetBuff( client, fDodgeChance, thisRaceID, evadebonus  );
                
            }
            else                                         // APPLY NEGATIVE BONUS
            {
                EvadeSelf[client] = false;
                
            }
        }
        if (DamageSelf[client] == false)
            temp = -temp;
        if (EvadeSelf[client] == false)
            temp2 = -temp2;

        PrintToChat(client, "\x01 SELF GAMBLE RESULTS: \x04 VIS: (%.2f), DMG: (%.2f), GRAV: (%.2f), EVADE: (%.2f)", invisbonus, temp, gravitybonus, temp2);
        
    }
}

public GambleImmunity(client)
{
    new skill_immunity = War3_GetSkillLevel( client, thisRaceID, SKILL_IMMUNITY );
    ImmunityGambled[client] = true;
    if (skill_immunity > 0)
    {
        if (GetRandomFloat( 0.0, 1.0 ) <= 0.60)
        {
                // ************** SET IMMUNITY BUFFS ***************************
        
            if (GetRandomFloat( 0.0, 1.0 ) < GetImmunityChance[skill_immunity])
            {
                new immunitybonus = GetRandomInt(0, (skill_immunity-1));
                War3_SetBuff( client, ImmunityList[immunitybonus], thisRaceID, true  );
                switch(ImmunityList[immunitybonus])
                {
                    case bImmunitySkills :
                    {
                        PrintToChat(client, "\x01Immunty Gamble: You are immune to \x04ALL SKILLS \x01for this round.");    
                    }
                    case bImmunityUltimates:
                    {
                        PrintToChat(client, "\x01Immunty Gamble: You are immune to \x04ULTIMATES \x01for this round.");    
                    }
                    case bImmunityWards :
                    {
                        PrintToChat(client, "\x01Immunty Gamble: You are immune to \x04WARDS \x01for this round.");    
                    }
                    case bImmunityItems:
                    {
                        PrintToChat(client, "\x01Immunty Gamble: You are immune to \x04ITEM BONUSES \x01for this round.");    
                    }
                }                
                ShopmenuToggle[client] = true; // make sure they can't buy immunity to other things
                
                
            }
            else
            {
                BurnToggle[client] = true;
                IgniteEntity(client, 15.0);
                ShopmenuToggle[client] = true;
                PrintToChat(client, "\x04OUCH, Imunity Gamble failed.  You will now burn.  Oh, you can't buy from shopmenu either.");
            }
        
        }
        else 
            PrintToChat(client, "\x04 No immunity granted");
    }    
}

public GambleWeapons(client)
{
    new skill_weps = War3_GetSkillLevel( client, thisRaceID, SKILL_WEPS );
        // ************** RANDOM WEAPON CHANCE ***************************
    weaponGive[client] = GetRandomInt(0,(skill_weps*2));    
    new String:temp[64] = "weapon_knife,weapon_c4,";
    StrCat(temp, 64, WeaponChance[weaponGive[client]]);
    War3_WeaponRestrictTo( client,thisRaceID, temp);
    CreateTimer(2.0,giveWeapon,client);        
    PrintToChat(client, "\x04 This round you will use %s", WeaponChance[weaponGive[client]]);

}

public Action:giveWeapon(Handle:timer,any:client)
{
    if (ValidPlayer(client,true)){
        new String:name[64];
        GetClientName(client,name,64);
        PrintToChat(client, "\x04 Client |%s| should have been given a |%s|", name, WeaponChance[weaponGive[client]]);
        GivePlayerItem( client, WeaponChance[weaponGive[client]]);
    }
}


public HaveAGamble( client )
{
    if( (War3_GetRace( client ) == thisRaceID) && ValidPlayer(client, true) )
    {
        GambleHP(client);    
        GambleSpeed(client);
        GambleProps(client);
        GambleImmunity(client);
        if(War3_GetGame()!=Game_TF) 
            GambleWeapons(client);

    }
}





/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/

public OnW3Denyable(W3DENY:event, client)
{
    if( War3_GetRace( client ) == thisRaceID && ValidPlayer( client ) && ShopmenuToggle[client] == true)
    {
        if(event==DN_CanBuyItem1)
        {
            new item = W3GetVar(EventArg1);
            decl String:itemname[64];
            W3GetItemShortname(item,itemname,sizeof(itemname));
            if(StrEqual(itemname, "lace", false))
            {
                PrintToChat(client, "You may not buy necklace this round.");
                W3Deny();
            }
            else if(StrEqual(itemname, "shield", false))
            {
                PrintToChat(client, "You may not buy shield this round.");
                W3Deny();
            }
        }
    }
}



public Action:heataoe(Handle:timer,any:a){
    for(new i=0;i<=MaxClients;i++){
        if(ValidPlayer(i,true) && War3_GetRace(i)==thisRaceID && BurnToggle[i]==true){
            new Float:positioni[3];
            War3_CachedPosition(i,positioni);
            TE_SetupGlowSprite(positioni,BurnSprite,0.4,1.9,255);
            TE_SendToAll();
            
        }
    }
}

public Action:Deminish(Handle:timer,any:userid)
{
    for(new client=1;client<=MaxClients;client++){
        if(ValidPlayer(client,true)){
            if(War3_GetRace(client)==thisRaceID && BurnToggle[client]==true){
                War3_DecreaseHP(client,1);
            }
        }
    }
}


public Action:StopFly( Handle:timer, any:client )
{
    bFlying[client] = false;
    if( ValidPlayer( client, true ) )
    {
        War3_SetBuff( client, bFlyMode, thisRaceID, false );
        War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
    }
}

public Action:Land1( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        PrintToChat( client, "\x05: \x03Your going to land in \x041 \x03seconds!" );
    }
}

public Action:Land2( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        PrintToChat( client, "\x05: \x03Your going to land in \x042 \x03seconds!" );
    }
}

public Action:Land3( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        PrintToChat( client, "\x05: \x03Your going to land in \x043 \x03seconds!" );
    }
}



public bool:ImmunityCheck(client)
{
    if(bIsEntangled[client]||W3HasImmunity(client,Immunity_Ultimates))
    {
        return false;
    }
    return true;
}

public Action:StopEntangle(Handle:timer,any:client)
{

    bIsEntangled[client]=false;
    War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
    
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
            EmitSoundToAll(teleportSound,client);    
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
        War3_CooldownMGR(client,UltiCooldown,thisRaceID,SKILL_LUCKYDRAW);
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