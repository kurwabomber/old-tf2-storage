#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>


new thisRaceID;

new SKILL_SOUL, SKILL_WHIRLWIND, SKILL_ELDER, SKILL_ETHEREAL, ULT_FORCE;

// Soul of Dragon
new Float:SoulSpeed[]={1.0,1.05,1.10,1.15,1.20,1.25};
new Float:SoulGravity[]={1.0,0.95,0.90,0.85,0.80,0.75};
new SoulArmor[]={0,25,50,75,100,125};
new SoulHP[]={100,105,110,115,120,125};
new SoulsAbsorbed[MAXPLAYERS];
new Float:SoulAbsorbChance[] = {0.0,0.1,0.2,0.3,0.4,0.5};
new String:SoulSnd[]="war3source/dovahkiin/soul.mp3";
new BeamSprite; 
new HaloSprite;
new SoulSprite1;

// Whirlwind Sprint
new String:SprintSnd[]="war3source/dovahkiin/sprint.mp3";

// Elder Knowledge
new String:ElderSnd[]="war3source/dovahkiin/elder.mp3";
new Float:KnowledgeTime[] ={0.0, 10.0, 8.0, 6.0, 4.0, 2.0};
new bool:bKnowledgeUsed[MAXPLAYERS];
new ElderMin = 1;
new ElderMax[] = {0, 50, 40, 30, 20, 10};

// Ethereal Form
new bool:bFormActived[MAXPLAYERS];
new Float:FormTime[] = {0.0, 2.0, 4.0, 6.0, 8.0, 10.0};
new String:FormSnd[]="war3source/dovahkiin/form.mp3";

// Unrelenting Force
new Float:ForceRange[] = {0.0, 100.0, 175.0, 250.0, 325.0, 400.0};
new Float:PushForce[] = {0.0, 0.1, 0.25, 0.50, 0.75, 1.0};
new ForceDmg[] = {0, 5, 10, 15, 20, 25};
new m_vecBaseVelocity;
new String:ForceSnd[]="war3source/dovahkiin/force.mp3";


public Plugin:myinfo = 
{
    name = "War3Source Race - Dovahkiin",
    author = "M.A.C.A.B.R.A",
    description = "The Dovahkiin race for War3Source.",
    version = "1.1.7",
    url = "http://strefagier.com.pl/"
}


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Dovahkiin","dovahkiin");
    
    SKILL_SOUL=War3_AddRaceSkill(thisRaceID,"Soul of Dragon","You become very powerful due to absorbed Dragon Souls.",false,5); //[X]
    SKILL_WHIRLWIND=War3_AddRaceSkill(thisRaceID,"Whirlwind Sprint","Propels you forward. (+ability)",false,5); // [X]
    SKILL_ELDER=War3_AddRaceSkill(thisRaceID,"Elder Knowledge","Allows you to travel back in time.",false,5); // [X]
    SKILL_ETHEREAL=War3_AddRaceSkill(thisRaceID,"Ethereal Form","Allows you to become immune to damage for a short period of time, however, you will be unable to fight. (+ability1)",false,5); //[X]
    ULT_FORCE=War3_AddRaceSkill(thisRaceID,"Unrelenting Force","Fires a shockwave of force energy that pushes enemies away. (+ultimate)",true,5); //[X]
    
    War3_CreateRaceEnd(thisRaceID);
}

public OnMapStart()
{  
    //Sounds
    War3_AddCustomSound(ForceSnd);
    War3_AddCustomSound(SprintSnd);
    War3_AddCustomSound(FormSnd);
    War3_AddCustomSound(ElderSnd);
    War3_AddCustomSound(SoulSnd);
    
    //Sprites
    BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
    SoulSprite1=PrecacheModel( "sprites/steam1.vmt" );
}

public OnPluginStart()
{    
    m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
    HookEvent( "player_death", PlayerDeathEvent );
}

public OnWar3EventSpawn(client)
{
    InitPassiveSkills(client);
    bFormActived[client] = false;
    bKnowledgeUsed[client] = false;
    War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
    W3ResetPlayerColor( client, thisRaceID );
}

public OnWar3EventDeath( victim, attacker )
{
    W3ResetAllBuffRace( victim, thisRaceID );
    
    if(War3_GetRace(victim) == thisRaceID && bKnowledgeUsed[victim] == false)
    {
        new skill_lvl = War3_GetSkillLevel(victim,thisRaceID,SKILL_ELDER);    
        if( skill_lvl > 0 && GetRandomInt( ElderMin, ElderMax[skill_lvl] ) <= 10 )
        {
            CreateTimer( KnowledgeTime[skill_lvl], SpawnPlayer, victim );
        }
    }
}

public Action:SpawnPlayer( Handle:timer, any:client )
{
    if( ValidPlayer( client, false ) )
    {
        War3_SpawnPlayer(client);        
        bKnowledgeUsed[client] = true;
        InitPassiveSkills(client);
        bFormActived[client] = false;
        War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
        EmitSoundToAll(ElderSnd,client); // Shout
        PrintHintText(client, "You have used an Elder Knowledge to go back in time.");
    }
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    InitPassiveSkills(client);
}

public OnRaceChanged(client,oldrace,newrace)
{
    if(newrace!=thisRaceID)
    {
        War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
        War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);
        War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
        War3_SetMaxHP_INTERNAL(client,100);
        War3_SetCSArmor(client,0);
        War3_SetCSArmorHasHelmet(client,false);
        SoulsAbsorbed[client] = 0;
    }
}


/* *************************************** InitPassiveSkills (Soul of Dragon) *************************************** */
public InitPassiveSkills(client)
{
    if(War3_GetRace(client)==thisRaceID)
    {
        new skill_lvl = War3_GetSkillLevel(client,thisRaceID,SKILL_SOUL);    
        if(skill_lvl > 0)
        {
            switch(skill_lvl)
            {
                case 1: 
                {
                    switch(SoulsAbsorbed[client])
                    {
                        case 1: 
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.02);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.02);
                            SetEntityHealth(client,SoulHP[skill_lvl]-2);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-2);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-2);                            
                        }
                        case 2:
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]);
                            SetEntityHealth(client,SoulHP[skill_lvl]);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]);                            
                        }
                    }
                }
                case 2: 
                {
                    switch(SoulsAbsorbed[client])
                    {
                        case 1: 
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.07);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.07);
                            SetEntityHealth(client,SoulHP[skill_lvl]-7);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-7);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-7);                            
                        }
                        case 2:
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.05);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.05);
                            SetEntityHealth(client,SoulHP[skill_lvl]-5);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-5);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-5);                            
                        }
                        case 3: 
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.02);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.02);
                            SetEntityHealth(client,SoulHP[skill_lvl]-2);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-2);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-2);                            
                        }
                        case 4:
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]);
                            SetEntityHealth(client,SoulHP[skill_lvl]);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]);                            
                        }
                    }
                }
                case 3: 
                {
                    switch(SoulsAbsorbed[client])
                    {
                        case 1: 
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.12);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.12);
                            SetEntityHealth(client,SoulHP[skill_lvl]-12);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-12);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-12);                            
                        }
                        case 2:
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.1);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]-0.1);
                            SetEntityHealth(client,SoulHP[skill_lvl]-10);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-10);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-10);                            
                        }
                        case 3: 
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.07);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.07);
                            SetEntityHealth(client,SoulHP[skill_lvl]-7);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-7);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-7);                            
                        }
                        case 4:
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.05);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.05);
                            SetEntityHealth(client,SoulHP[skill_lvl]-5);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-5);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-5);                            
                        }
                        case 5: 
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.02);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.02);
                            SetEntityHealth(client,SoulHP[skill_lvl]-2);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-2);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-2);                            
                        }
                        case 6:
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]);
                            SetEntityHealth(client,SoulHP[skill_lvl]);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]);                            
                        }
                    }
                }
                case 4:
                {
                    switch(SoulsAbsorbed[client])
                    {
                        case 1: 
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.17);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.17);
                            SetEntityHealth(client,SoulHP[skill_lvl]-17);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-17);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-17);                            
                        }
                        case 2:
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.15);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.15);
                            SetEntityHealth(client,SoulHP[skill_lvl]-15);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-15);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-15);                            
                        }
                        case 3: 
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.12);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.12);
                            SetEntityHealth(client,SoulHP[skill_lvl]-12);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-12);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-12);                            
                        }
                        case 4:
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.1);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]-0.1);
                            SetEntityHealth(client,SoulHP[skill_lvl]-10);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-10);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-10);                            
                        }
                        case 5: 
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.07);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.07);
                            SetEntityHealth(client,SoulHP[skill_lvl]-7);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-7);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-7);                            
                        }
                        case 6:
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.05);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.05);
                            SetEntityHealth(client,SoulHP[skill_lvl]-5);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-5);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-5);                            
                        }
                        case 7: 
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.02);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.02);
                            SetEntityHealth(client,SoulHP[skill_lvl]-2);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-2);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-2);                            
                        }
                        case 8:
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]);
                            SetEntityHealth(client,SoulHP[skill_lvl]);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]);                            
                        }
                    }
                }
                case 5:
                {
                    switch(SoulsAbsorbed[client])
                    {
                        case 1: 
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.22);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.22);
                            SetEntityHealth(client,SoulHP[skill_lvl]-22);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-22);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-22);                            
                        }
                        case 2:
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.2);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.2);
                            SetEntityHealth(client,SoulHP[skill_lvl]-20);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-20);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-20);                            
                        }
                        case 3: 
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.17);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.17);
                            SetEntityHealth(client,SoulHP[skill_lvl]-17);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-17);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-17);                            
                        }
                        case 4:
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.15);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.15);
                            SetEntityHealth(client,SoulHP[skill_lvl]-15);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-15);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-15);                            
                        }
                        case 5: 
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.12);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.12);
                            SetEntityHealth(client,SoulHP[skill_lvl]-12);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-12);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-12);                            
                        }
                        case 6:
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.1);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]-0.1);
                            SetEntityHealth(client,SoulHP[skill_lvl]-10);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-10);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-10);                            
                        }
                        case 7: 
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.07);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.07);
                            SetEntityHealth(client,SoulHP[skill_lvl]-7);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-7);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-7);                            
                        }
                        case 8:
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.05);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.05);
                            SetEntityHealth(client,SoulHP[skill_lvl]-5);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-5);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-5);                            
                        }
                        case 9: 
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]-0.02);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]+0.02);
                            SetEntityHealth(client,SoulHP[skill_lvl]-2);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]-2);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]-2);                            
                        }
                        case 10:
                        {
                            War3_SetBuff(client,fMaxSpeed,thisRaceID,SoulSpeed[skill_lvl]);
                            War3_SetBuff(client,fLowGravitySkill,thisRaceID,SoulGravity[skill_lvl]);
                            SetEntityHealth(client,SoulHP[skill_lvl]);
                            War3_SetMaxHP_INTERNAL(client,SoulHP[skill_lvl]);
                            War3_SetCSArmor(client,SoulArmor[skill_lvl]);                            
                        }
                    }
                }
            }
            War3_SetCSArmorHasHelmet(client,true);
            if(SoulsAbsorbed[client] == 0)
            {
                War3_ChatMessage( client,"%d/%d Dragon Souls absorbed.", SoulsAbsorbed[client],(2*skill_lvl));
            }
            else
            {
                War3_ChatMessage( client,"%d/%d Dragon Souls absorbed. You feel the power of Dragon in your veins.", SoulsAbsorbed[client],(2*skill_lvl));
            }
        }
    }
}


public PlayerDeathEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
    new victim = GetClientOfUserId( GetEventInt( event, "userid" ) );
    new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );
    
    if (ValidPlayer(victim) && ValidPlayer(attacker) && victim > 0 && attacker > 0)
    {
        new vteam = GetClientTeam( victim );
        new ateam = GetClientTeam( attacker );
        
        if( victim > 0 && attacker > 0 && attacker != victim && vteam != ateam)
        {
            new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_SOUL );
            if( War3_GetRace( attacker ) == thisRaceID && skill_level > 0 && GetRandomFloat( 0.0, 1.0 ) <= SoulAbsorbChance[skill_level] )
            {
                if(SoulsAbsorbed[attacker] < (2*skill_level))
                {
                    SoulsAbsorbed[attacker]++;
                    
                    PrintHintText( attacker, "You have absorbed a Dragon Soul." );
                    
                    EmitSoundToAll( SoulSnd, attacker );
                    
                    new Float:attacker_pos[3];
                    new Float:victim_pos[3];
                    
                    GetClientAbsOrigin( attacker, attacker_pos );
                    GetClientAbsOrigin( victim, victim_pos );
                    
                    attacker_pos[2] += 50;
                    victim_pos[2] -= 20;
                    
                    TE_SetupBeamRingPoint( victim_pos, 90.0, 150.0, SoulSprite1, SoulSprite1, 0, 0, 3.0, 100.0, 2.0, {  255, 150, 70, 100 }, 4, FBEAM_ISACTIVE );
                    TE_SendToAll();
                    
                    TE_SetupBeamRingPoint( attacker_pos, 90.0, 150.0, SoulSprite1, SoulSprite1, 0, 0, 3.0, 100.0, 2.0, {  255, 150, 70, 100 }, 4, FBEAM_ISACTIVE );
                    TE_SendToAll();
                    
                    TE_SetupBeamLaser(victim, attacker, BeamSprite, HaloSprite, 0, 8, 3.0, 50.0, 100.0, 0, 0.0, {255, 150, 70, 100}, 70);
                    TE_SendToAll();
                }
            }
        }
    }
}


/* *************************************** OnAbilityCommand (0.Whirlwind Sprint & 1.Ethereal Form) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)) // Whirlwind Sprint
    {
        new skill_level = War3_GetSkillLevel(client,thisRaceID,SKILL_WHIRLWIND);
        if(skill_level > 0)
        {            
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_WHIRLWIND,true))
            {
                new Float:startpos[3];
                new Float:endpos[3];
                new Float:localvector[3];
                new Float:velocity[3];
                
                GetClientAbsOrigin( client, startpos );
                War3_GetAimEndPoint( client, endpos );
                
                localvector[0] = endpos[0] - startpos[0];
                localvector[1] = endpos[1] - startpos[1];
                
                velocity[0] = localvector[0] * PushForce[skill_level];
                velocity[1] = localvector[1] * PushForce[skill_level];
                velocity[2] = 0.0;
                
                EmitSoundToAll(SprintSnd,client); // Shout
                PrintHintText(client, "WULD NAH KEST !!!");
                
                SetEntDataVector( client, m_vecBaseVelocity, velocity, true );    
                War3_CooldownMGR(client,15.0,thisRaceID,SKILL_WHIRLWIND,_,_);
            }
        }
        else
        {
            PrintHintText(client, "Level your Whirlwind Sprint first");
        }
    }
    
    if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client)) // Ethereal Form
    {
        new skill_level = War3_GetSkillLevel(client,thisRaceID,SKILL_ETHEREAL);
        if(skill_level > 0)
        {            
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_ETHEREAL,true))
            {
                new PlayerTeam = GetClientTeam(client);
                
                EmitSoundToAll(FormSnd,client); // Shout
                PrintHintText(client, "FEIM ZI GRON !!!");
                
                bFormActived[client] = true;                
                CreateTimer( FormTime[skill_level], StopForm, client );
                
                War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.30);
                if(PlayerTeam == 2) // TT
                {
                    W3SetPlayerColor(client,thisRaceID, 30,144,255,155); // czerwony                
                }
                else // CT
                {
                    W3SetPlayerColor(client,thisRaceID, 30,144,255,155); // niebieski
                }
                
                War3_CooldownMGR(client,25.0,thisRaceID,SKILL_ETHEREAL,_,_);
            }
        }
        else
        {
            PrintHintText(client, "Level your Ethereal Form first");
        }
    }
}

public Action:StopForm( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        bFormActived[client] = false;        
        W3ResetPlayerColor( client, thisRaceID );    
        War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
        PrintHintText( client, "Ethereal Form has ended" );
    }
}

public OnW3TakeDmgAllPre( victim, attacker, Float:damage )
{
    if( IS_PLAYER( victim ) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && attacker != victim )
    {
        new race_victim = War3_GetRace( victim );
        new skill_level = War3_GetSkillLevel( victim, thisRaceID, SKILL_ETHEREAL );
        
        new race_attacker = War3_GetRace( attacker );
        new skill_level2 = War3_GetSkillLevel( attacker, thisRaceID, SKILL_ETHEREAL );
        
        if( race_victim == thisRaceID && skill_level > 0 && bFormActived[victim] )
        {
            if( !W3HasImmunity( attacker, Immunity_Skills ) )
            {
                War3_DamageModPercent( 0.0 );
            }
            else
            {
                W3MsgEnemyHasImmunity( victim, true );
            }
        }
        if( race_attacker == thisRaceID && skill_level2 > 0 && bFormActived[attacker] )
        {
            War3_DamageModPercent( 0.0 );
        }
        
    }
}

/* *************************************** OnUltimateCommand (Unrelenting Force) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
    if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_FORCE );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_FORCE, true ) )
            {
                new Float:startpos[3];
                new Float:endpos[3];
                new Float:localvector[3];
                new Float:velocity[3];
                
                new Float:distance = ForceRange[ult_level];
                new AttackerTeam = GetClientTeam( client );
                
                GetClientAbsOrigin( client, startpos );
                War3_GetAimEndPoint( client, endpos );
                
                localvector[0] = endpos[0] - startpos[0];
                localvector[1] = endpos[1] - startpos[1];
                localvector[2] = endpos[2] - startpos[2];
                
                velocity[0] = localvector[0] * PushForce[ult_level];
                velocity[1] = localvector[1] * PushForce[ult_level];
                velocity[2] = localvector[2] * PushForce[ult_level];
                
                EmitSoundToAll(ForceSnd,client); // Shout
                PrintHintText(client, "FUS RO DAH !!!");
                
                for( new i = 1; i <= MaxClients; i++ )
                {
                    if( ValidPlayer( i, true ) && GetClientTeam( i ) != AttackerTeam && !W3HasImmunity( i, Immunity_Ultimates ) )
                    {
                        new Float:victimpos[3];
                        GetClientAbsOrigin( i, victimpos );
                        
                        if( GetVectorDistance( startpos, victimpos ) <= distance )
                        {
                            new Float:velocity2[3]; // Pierdolniecie    
                            velocity2[2] = 300.0;
                            SetEntDataVector( i, m_vecBaseVelocity, velocity2, true );
                            SetEntDataVector( i, m_vecBaseVelocity, velocity, true );    
                            PrintHintText(i, "FUS RO DAH !!!");
                            War3_DealDamage(i,ForceDmg[ult_level],client,DMG_BURN,"unrelentingforce",W3DMGORIGIN_SKILL);
                        }
                    }
                }
                War3_CooldownMGR(client,30.0,thisRaceID,ULT_FORCE,_,_);
            }
        }
        else
        {
            W3MsgUltNotLeveled( client );
        }
    }
}
