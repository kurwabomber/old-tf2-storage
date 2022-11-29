/**
* File: War3Source_999_TimeWaster.sp
* Description: Time Waster race for War3Source.
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
    
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"
    
public Plugin:myinfo = 
{
    name = "War3Source Race - Time Waster",
    author = "Remy Lebeau",
    description = "Time Waster race for War3Source",
    version = "1.1",
    url = "http://sevensinsgaming.com"
};


new thisRaceID;
new SKILL_SPEED, SKILL_VAMP, SKILL_BASH, SKILL_THORNS, SKILL_DMG, SKILL_GAMBLE, ULT_BOAST;
new TeleBeam,HaloSprite,TPBeamSprite;


new Float:UnholySpeed[5]={1.0,1.05,1.10,1.15,1.20};
new Float:BashChance[5]={0.0,0.04,0.06,0.08,0.10};
new Float:ThornsReturnDamage[5]={0.0,0.03,0.05,0.07,0.09};
new Float:BonusDamage[5]={0.0,0.03,0.045,0.06,0.075};
//new Float:EvadeChance[5]={0.0,0.02,0.05,0.07,0.10};
new BonusGold[5]={0,1,2,3,4};
new Float:VampirePercent[5]={0.0,0.04,0.07,0.11,0.15};
new TrailLevelSave[MAXPLAYERS];
new levels_check[MAXPLAYERS];
new MenuSelectNumber;



/*#define RGBA_COLOR_BLACK_2    {255,30,30,255}
#define RGBA_COLOR_GOLD_2        {255,215,0,255}
#define RGBA_COLOR_VIOLET_2    {238,130,238,255}
#define RGBA_COLOR_MAROON_2    {128,0,0,255}
#define RGBA_COLOR_PINK_2        {255,20,147,255}*/


#define RGBA_COLOR_WHITE_2    {255,255,255,255}
#define RGBA_COLOR_YELLOW_2    {255,255,0,255}
#define RGBA_COLOR_ORANGE_2    {255,69,0,255}
#define RGBA_COLOR_RED_2        {255,0,0,255}
#define RGBA_COLOR_PURPLE_2    {128,0,128,255}
#define RGBA_COLOR_BLUE_2        {0,0,255,255}
#define RGBA_COLOR_SKYBLUE_2    {135,206,25,255}
#define RGBA_COLOR_GREEN_2    {0,255,0,255}
#define RGBA_COLOR_CYAN_2        {255,0,255,255}

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("TimeWaster","timewaster");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Eventually you speed up.","Get extra speed every 50 levels (max 200)",false,200);
    SKILL_VAMP=War3_AddRaceSkill(thisRaceID,"Get some HP back.  Eventually.","Gain some HP back from attacks.",false,200);
    SKILL_BASH=War3_AddRaceSkill(thisRaceID,"Eventually you bash people.","Increase your chance to bash every 50 levels (max 200)",false,200);
    SKILL_THORNS=War3_AddRaceSkill(thisRaceID,"Eventually you return damage.","Increase your return damage every 50 levels (max 200)",false,200);
    //SKILL_EVADE=War3_AddRaceSkill(thisRaceID,"Maybe someday you'll dodge bullets.","Increase your evasion every 50 levels (max 200)",false,200);
    SKILL_GAMBLE=War3_AddRaceSkill(thisRaceID,"Maybe someday you'll win big.","Increase the amount of bonus gold you have a chance of getting on kill (max 200)",false,200);
    SKILL_DMG=War3_AddRaceSkill(thisRaceID,"Eventually you do extra damage","Do extra bonus damage every 50 levels (max 200)",false,200);
//    SKILL_TRAIL=War3_AddRaceSkill(thisRaceID,"Now THIS is for the Pros.","Purely cosmetic trail that changes colour with level (every 100 levels) .\n  Only comes into effect when ALL other skills are maxed. (max 900)",false,900);
    ULT_BOAST=War3_AddRaceSkill(thisRaceID,"Boast","When you die - let your killer know what level you are (passive) \n After you max ALL OTHER abilities, you will get a cosmetic trail that changes / 100 levels",true,900);
    
    
    War3_CreateRaceEnd(thisRaceID);
}


public OnPluginStart()
{
    CreateTimer(3.0, CreateTrail,_,TIMER_REPEAT);
    RegConsoleCmd("twmenu", Command_AddSkillLevels, "Adds 50 levels to a selected menu number");
}

public Action:Command_AddSkillLevels(client, args)
{
	if (args < 1)
	{
		PrintToConsole(client, "Usage: twmenu <menu number> <number of levels>");
		return Plugin_Handled;
	}
	char MenuNumberString[32];			GetCmdArg(1,MenuNumberString,sizeof(MenuNumberString));
	char LevelNumberString[32];			GetCmdArg(2,LevelNumberString,sizeof(LevelNumberString));
	new MenuNumber = StringToInt(MenuNumberString);
	new LevelNumber = StringToInt(LevelNumberString);
	MenuSelectNumber=0;
	DoLevels(client,MenuNumber,LevelNumber);
	return Plugin_Handled;
}

public DoLevels(client,MenuNumber,LevelNumber)
{
	if(War3_GetRace(client)==thisRaceID && MenuSelectNumber<LevelNumber)
	{
		FakeClientCommand(client,"menuselect %i",MenuNumber);
		MenuSelectNumber++;
		DoLevels(client,MenuNumber,LevelNumber);
	}
}



public OnMapStart()
{
    if(GAMECSGO){
    
        TeleBeam=War3_PrecacheBeamSprite();
    }
    else
    {
    
        TeleBeam=PrecacheModel("materials/sprites/tp_beam001.vmt");
    }

    HaloSprite=War3_PrecacheHaloSprite();
//    PrecacheModel("models/player/slow/nanosuit/slow_nanosuit.mdl", true);
    TPBeamSprite = PrecacheModel( "sprites/tp_beam001.vmt" );


}
    

/***************************************************************************
*
*
*                PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/

public InitPassiveSkills(client)
{
    if(War3_GetRace(client)==thisRaceID)
    {
        new skilllevel_unholy=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
        new Float:speed=UnholySpeed[RoundToFloor(skilllevel_unholy/50.0)];
        War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
        
        
        new skilllevel_bash=War3_GetSkillLevel(client,thisRaceID,SKILL_BASH);
        new Float:bash=BashChance[RoundToFloor(skilllevel_bash/50.0)];
        War3_SetBuff(client,fBashChance,thisRaceID,bash);
        
        new skilllevel_dmg=War3_GetSkillLevel(client,thisRaceID,SKILL_DMG);
        new Float:bndmg=BonusDamage[RoundToFloor(skilllevel_dmg/50.0)];
        War3_SetBuff( client, fDamageModifier, thisRaceID, bndmg  );
        
        
       /* new skilllevel_evade=War3_GetSkillLevel(client,thisRaceID,SKILL_EVADE);
        new Float:evade=EvadeChance[RoundToFloor(skilllevel_evade/50.0)];
        War3_SetBuff( client, fDodgeChance, thisRaceID, evade  );*/
        
        
        new skilllevel_vamp=War3_GetSkillLevel(client,thisRaceID,SKILL_VAMP);
        new Float:vamp=VampirePercent[RoundToFloor(skilllevel_vamp/50.0)];
        War3_SetBuff( client, fVampirePercent, thisRaceID, vamp  );

        
        new skilllevel_thorns=War3_GetSkillLevel(client,thisRaceID,SKILL_THORNS);
        new skilllevel_gamble=War3_GetSkillLevel(client,thisRaceID,SKILL_GAMBLE);
        
        levels_check[client] = skilllevel_vamp+skilllevel_unholy+skilllevel_bash+skilllevel_thorns+skilllevel_gamble+skilllevel_dmg;
                
        TrailLevelSave[client] = 0;
        //PrintToChat(client, "AT SPAWN: Levels check = |%d|", levels_check);

        if (levels_check[client] == 1200)
        {
            new skilllevel_trail = War3_GetSkillLevel( client, thisRaceID, ULT_BOAST );
            TrailLevelSave[client] = RoundToFloor(skilllevel_trail/100.0);
           // PrintToChat(client, "Inside levels check, TrailLevelSave[client] = |%d|", TrailLevelSave[client]);
        }
        

    }
}

public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills(client);
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
    }
}

public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
        W3ResetAllBuffRace( client, thisRaceID );
        InitPassiveSkills(client);
    //    SetEntityModel(client, "models/player/slow/nanosuit/slow_nanosuit.mdl");
    }
}




/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/








/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/


public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(W3GetDamageIsBullet()&&ValidPlayer(victim,true)&&ValidPlayer(attacker,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
    {
        
        if(War3_GetRace(victim)==thisRaceID)
        {
            new skill_level=War3_GetSkillLevel(victim,thisRaceID,SKILL_THORNS);
            if(skill_level>49&&!Hexed(victim,false))
            {
                if(!W3HasImmunity(attacker,Immunity_Skills))
                {
                    new damage_i=RoundToFloor(damage*ThornsReturnDamage[RoundToFloor(skill_level/50.0)]);
                    if(damage_i>0)
                    {
                        if(damage_i>40) damage_i=40; // lets not be too unfair ;]
                        
                        if(GAMETF)    // Team Fortress 2 is stable with code below:
                        {
                            if(War3_DealDamage(attacker,damage_i,victim,_,"thorns",_,W3DMGTYPE_PHYSICAL))
                            {
                                decl Float:iVec[3];
                                decl Float:iVec2[3];
                                GetClientAbsOrigin(attacker, iVec);
                                GetClientAbsOrigin(victim, iVec2);
                                iVec[2]+=35.0, iVec2[2]+=40.0;
                                TE_SetupBeamPoints(iVec, iVec2, TeleBeam, TeleBeam, 0, 45, 0.4, 10.0, 10.0, 0, 0.5, {255,35,15,255}, 30);
                                TE_SendToAll();
                                iVec2[0]=iVec[0];
                                iVec2[1]=iVec[1];
                                iVec2[2]=80+iVec[2];
                                TE_SetupBubbles(iVec, iVec2, HaloSprite, 35.0,GetRandomInt(6,8),8.0);
                                TE_SendToAll();
                            }
                        }
                        else   // For CS Stuff or others:
                        {
                            War3_DealDamageDelayed(attacker,victim,damage_i,"thorns",0.1,true,SKILL_THORNS);
                            decl Float:iVec[3];
                            decl Float:iVec2[3];
                            GetClientAbsOrigin(attacker, iVec);
                            GetClientAbsOrigin(victim, iVec2);
                            iVec[2]+=35.0, iVec2[2]+=40.0;
                            TE_SetupBeamPoints(iVec, iVec2, TeleBeam, TeleBeam, 0, 45, 0.4, 10.0, 10.0, 0, 0.5, {255,35,15,255}, 30);
                            TE_SendToAll();
                            iVec2[0]=iVec[0];
                            iVec2[1]=iVec[1];
                            iVec2[2]=80+iVec[2];
                            TE_SetupBubbles(iVec, iVec2, HaloSprite, 35.0,GetRandomInt(6,8),8.0);
                            TE_SendToAll();
                        }
                    }
                }
            }
        }
    }

}


public OnWar3EventDeath(victim,attacker)
{    
    if(ValidPlayer(victim) && ValidPlayer(attacker))
    {
        new race=W3GetVar(DeathRace); //get  immediate variable, which indicates the race of the player when he died
        if(race==thisRaceID)
        {
            new ult_level=War3_GetSkillLevel(victim,race,ULT_BOAST);           
            if (ult_level)
            {
                new plevel = War3_GetLevel(victim, thisRaceID);
                CPrintToChat(attacker, "{red} You killed a TimeWaster who's level is |%d|",plevel);
            }
        }
        new race_attacker = War3_GetRace(attacker);
        if (race_attacker == thisRaceID)
        {
            new skill_level = RoundToFloor(War3_GetSkillLevel(attacker,thisRaceID,SKILL_GAMBLE) / 50.0);
            if(GetRandomFloat(0.0,1.0) < 0.1 && skill_level > 0)
            {
                W3FlashScreen( attacker, RGBA_COLOR_GREEN );
                W3GiveXPGold(attacker,XPAwardByGeneric,0,BonusGold[skill_level],"Gamble Pays off!");
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

public OnWar3Event(W3EVENT:event,client)
{
    if(event==OnPreGiveXPGold)
    {
        new originalxp = W3GetVar(EventArg2);
        new ModifiedXP = originalxp;
        //PrintToChat(client, "Normal XP |%d|",originalxp);
        if( originalxp > 1000 )
        {
            new difference = originalxp - 1000;
            difference = RoundToCeil(FloatDiv(float(difference),4.0));
            ModifiedXP = 1000 + difference;
        }
        W3SetVar(EventArg2,ModifiedXP);
        //PrintToChat(client, "Modified XP |%d|",ModifiedXP);
        
    }
}


public Action:CreateTrail(Handle:timer)
{
    for(new i = 1; i <= MaxClients; i++)
    {
        if(ValidPlayer(i,true) && War3_GetRace(i) == thisRaceID)
        {
            //new skilllevel_trail = War3_GetSkillLevel( i, thisRaceID, SKILL_TRAIL );
            if(TrailLevelSave[i])
            {
                new ent = Client_GetActiveWeapon(i);
                ent = IsValidEntity(ent) ? ent : i;
                switch(TrailLevelSave[i])
                {           
                    case 1:
                    {
                        TE_SetupBeamFollow( ent, TPBeamSprite, TPBeamSprite, 3.0, 3.0, 3.0, 30, RGBA_COLOR_WHITE_2 );
                        TE_SendToAll();
                    }
                    case 2:
                    {
                        TE_SetupBeamFollow( ent, TPBeamSprite, TPBeamSprite, 3.0, 3.0, 3.0, 30, RGBA_COLOR_YELLOW_2 );
                        TE_SendToAll();
                    }
                    case 3:
                    {
                        TE_SetupBeamFollow( ent, TPBeamSprite, TPBeamSprite, 3.0, 3.0, 3.0, 30, RGBA_COLOR_ORANGE_2 );
                        TE_SendToAll();
                    }
                    case 4:
                    {
                        TE_SetupBeamFollow( ent, TPBeamSprite, TPBeamSprite, 3.0, 3.0, 3.0, 30, RGBA_COLOR_RED_2 );
                        TE_SendToAll();
                    }
                    case 5:
                    {
                        TE_SetupBeamFollow( ent, TPBeamSprite, TPBeamSprite, 3.0, 3.0, 3.0, 30, RGBA_COLOR_PURPLE_2  );
                        TE_SendToAll();
                    }
                    case 6:
                    {
                        TE_SetupBeamFollow( ent, TPBeamSprite, TPBeamSprite, 3.0, 3.0, 3.0, 30, RGBA_COLOR_BLUE_2 );
                        TE_SendToAll();
                    }
                    case 7:
                    {
                        TE_SetupBeamFollow( ent, TPBeamSprite, TPBeamSprite, 3.0, 3.0, 3.0, 30, RGBA_COLOR_SKYBLUE_2 );
                        TE_SendToAll();
                    }
                    case 8:
                    {
                        TE_SetupBeamFollow( ent, TPBeamSprite, TPBeamSprite, 3.0, 3.0, 3.0, 30,  RGBA_COLOR_GREEN_2 );
                        TE_SendToAll();
                    }
                    case 9:
                    {
                        TE_SetupBeamFollow( ent, TPBeamSprite, TPBeamSprite, 3.0, 3.0, 3.0, 30,  RGBA_COLOR_CYAN_2  );
                        TE_SendToAll();
                    }
                    default:
                    {
                    }

                } 
            }

        }
    }    
}


public OnW3Denyable(W3DENY:event, client)
{
    if(event==DN_ShowLevelbank)
    {
        //PrintToChat(client, "levels check = |%d|", War3_GetLevel(client, thisRaceID));
        if( War3_GetRace( client ) == thisRaceID && ValidPlayer( client ) && (War3_GetLevel(client, thisRaceID) > 1200))
        {

            PrintToChat(client, "\x04Levelbank Denied! The last 900 levels on this race cannot be banked.  You have to work to level it up.");
            W3Deny();
        }
    }
}


