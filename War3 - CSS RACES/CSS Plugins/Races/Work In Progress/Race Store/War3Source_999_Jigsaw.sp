#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>
#include "W3SIncs/War3Source_Interface"  

   
new thisRaceID;
new SKILL_CUBE, SKILL_RAZOR, SKILL_FURNACE, SKILL_CAROUSEL, SKILL_BLADETABLE, ULT_BEARTRAP;
  
  
/* ********** Traps ********** */
enum ACTIVETRAP{
        None,
        Cube,
        RazorWire,
        Furnace,
		Carousel,
		BladeTable,
		ReverseBeartrap,
}

new ACTIVETRAP:CurrentTrap[MAXPLAYERS];

new bool:bIsUsed[6][MAXPLAYERS];
new FragCounter[MAXPLAYERS];
new IsTrapped[MAXPLAYERS];
new TrappedBy[MAXPLAYERS];
new TrapDelayer[MAXPLAYERS];


// Instructions
new InstructionCounter[MAXPLAYERS];
new Instructions[MAXPLAYERS];


// Cube
new CubeDMG[] = {0,2,3,4,5};
new Float:CubeRange[] = {0.0, 150.0, 300.0, 450.0, 600.0};


// Razor Wire
new Float:RazorDMG[]={0.0, 0.09, 0.1, 0.111, 0.125};
new Float:RazorRange[] = {0.0, 150.0, 300.0, 450.0, 600.0};
new Float:lastLocation[MAXPLAYERS][3];


// Furnace Trap
new Float:FurnaceRange[] = {0.0, 150.0, 300.0, 450.0, 600.0};


// Carousel
new CarouselDMG[] = {0,20,30,40,50};


// Blade Table
new BladeTableDMG[] = {0,2,3,4,5};
new BladeTableSacrificeDMG[] = {0,20,30,40,50};
new Float:BladeTableRange[] = {0.0, 150.0, 300.0, 450.0, 600.0};


// Reverse Beartrap
new Float:BeartrapTime[] = {0.0, 30.0, 25.0, 20.0, 15.0};


//GetRandomPlayer
new VictimsT[MAXPLAYERS][MAXPLAYERS];


//Model
new String:JigsawModel[]="models/player/kuristaja/saw/jigsaw/jigsaw.mdl";
new String:JigsawModelCT[]="models/player/kuristaja/saw/jigsaw/jigsaw_ct.mdl";
new Handle:DLandPrecacheCvar = INVALID_HANDLE;


// Soundy
new String:Resp1Snd[]="war3source/jigsaw/resp1.mp3";
new String:Resp2Snd[]="war3source/jigsaw/resp2.mp3";
new String:LaughSnd[]="war3source/jigsaw/laugh.mp3";
new String:LiveOrDieSnd[]="war3source/jigsaw/liveordie.mp3";
new String:WinSnd[]="war3source/jigsaw/win.mp3";
new String:GameOverSnd[]="war3source/jigsaw/gameover.mp3";
new String:SacrificeSnd[]="war3source/jigsaw/sacrifice.mp3";
new String:BeartrapSnd[]="war3source/jigsaw/beartrap.mp3";
new String:BloodSnd[]="war3source/jigsaw/blood.mp3";
new String:CarouselSnd[]="war3source/jigsaw/carousel.mp3";
new String:RazorSnd[]="war3source/jigsaw/razorwire.mp3";


public Plugin:myinfo = 
{
        name = "War3Source Race - Jigsaw",
        author = "M.A.C.A.B.R.A",
        description = "The Jigsaw race for War3Source.",
        version = "1.0.6",
		url = "http://strefagier.com.pl/"
}; 
 
 
public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Jigsaw","jigsaw");
	
	SKILL_CUBE=War3_AddRaceSkill(thisRaceID,"Cube","Traps your enemy into a Cube and drowns him. Target needs 1 frag to escape.",false,4);
	SKILL_RAZOR=War3_AddRaceSkill(thisRaceID,"Razor Wire","Entwines your enemy with razor wire. Target needs 1 frag to escape.",false,4);
	SKILL_FURNACE=War3_AddRaceSkill(thisRaceID,"Furnace","Burns your enemy. Target needs 2 frags to escape.",false,4);
	SKILL_CAROUSEL=War3_AddRaceSkill(thisRaceID,"Carousel","Shots your enemy with a shotgun.",false,4);
	SKILL_BLADETABLE=War3_AddRaceSkill(thisRaceID,"Blade Table","Damages your enemy. Target needs self-sacrifice or 2 frags to escape.",false,4);
	ULT_BEARTRAP=War3_AddRaceSkill(thisRaceID,"Reverse Beartrap (death)","Traps your enemy in Reverse Beartrap. Target needs 2 frags or 1 TK to escape.",true,4); 
    
	War3_CreateRaceEnd(thisRaceID);
}
 
 
public OnMapStart()
{
	// Soundy
	War3_PrecacheSound(Resp1Snd);
	War3_PrecacheSound(Resp2Snd);
	War3_PrecacheSound(LaughSnd);
	War3_PrecacheSound(LiveOrDieSnd);
	War3_PrecacheSound(WinSnd);
	War3_PrecacheSound(GameOverSnd);
	War3_PrecacheSound(SacrificeSnd);
	War3_PrecacheSound(BeartrapSnd);
	War3_PrecacheSound(BloodSnd);
	War3_PrecacheSound(CarouselSnd);
	War3_PrecacheSound(RazorSnd);
	
	//Model
	if(GetConVarBool(DLandPrecacheCvar))
	{
		AddFileToDownloadsTable(JigsawModel);
		AddFileToDownloadsTable("models/player/kuristaja/saw/jigsaw/jigsaw.dx80.vtx");
		AddFileToDownloadsTable("models/player/kuristaja/saw/jigsaw/jigsaw.dx90.vtx");
		AddFileToDownloadsTable("models/player/kuristaja/saw/jigsaw/jigsaw.sw.vtx");
		AddFileToDownloadsTable("models/player/kuristaja/saw/jigsaw/jigsaw.vvd");
		AddFileToDownloadsTable("models/player/kuristaja/saw/jigsaw/jigsaw.mdl");
		AddFileToDownloadsTable("models/player/kuristaja/saw/jigsaw/jigsaw.phy");
		
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw_normal.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw_eyes.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw_eyes.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw_hair.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw_hair.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw_hair_normal.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw_holster.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw_holster.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw_holster_normal.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw_shoes_red.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw_shoes.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw_shoes_normal.vtf");
		
		AddFileToDownloadsTable(JigsawModelCT);
		AddFileToDownloadsTable("models/player/kuristaja/saw/jigsaw/jigsaw_ct.dx80.vtx");
		AddFileToDownloadsTable("models/player/kuristaja/saw/jigsaw/jigsaw_ct.dx90.vtx");
		AddFileToDownloadsTable("models/player/kuristaja/saw/jigsaw/jigsaw_ct.sw.vtx");
		AddFileToDownloadsTable("models/player/kuristaja/saw/jigsaw/jigsaw_ct.vvd");
		AddFileToDownloadsTable("models/player/kuristaja/saw/jigsaw/jigsaw_ct.mdl");
		AddFileToDownloadsTable("models/player/kuristaja/saw/jigsaw/jigsaw_ct.phy");
		
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw_ct.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw_ct.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw_eyes_ct.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw_eyes_ct.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw_shoes_blue.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/saw/jigsaw/jigsaw_shoes_ct.vmt");
	}
	PrecacheModel( JigsawModel );
	PrecacheModel( JigsawModelCT );
}


public OnPluginStart()
{
	CreateTimer(0.1,CalcTrap,_,TIMER_REPEAT);
	HookEvent( "player_death", PlayerDeathEvent );
	HookEvent("round_end",RoundOverEvent);
	HookEvent("round_start", RoundStartEvent);
	DLandPrecacheCvar = CreateConVar("war3_jigsaw_downloadprecache","1","Wymuszenie Pobrania modelu");
}

/* **************** OnRaceChanged **************** */
public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace == thisRaceID )
	{
		if(ValidPlayer(client,true))
		{
			/* ******** Models ******** */
			if(GetClientTeam(client)==3) // CT
			{
				SetEntityModel(client, JigsawModelCT);
			}
			if(GetClientTeam(client)==2) // TT
			{
				SetEntityModel(client, JigsawModel);
			}
		}
	}
	else
	{
		W3ResetAllBuffRace(client, thisRaceID);
		W3ResetPlayerColor(client, thisRaceID);
	}
}
 
/* **************** OnWar3EventSpawn **************** */
public OnWar3EventSpawn(client)
{    
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		/* ******** Models ******** */
		if(GetClientTeam(client)==3) // CT
		{
			SetEntityModel(client, JigsawModelCT);
		}
		if(GetClientTeam(client)==2) // TT
		{
			SetEntityModel(client, JigsawModel);
		}
		
		/* ******** Sounds ******** */
		new resp = (GetRandomInt(1,2));
		if(resp == 1)
		{
			EmitSoundToAll(Resp1Snd,client);
		}
		if(resp == 2)
		{
			EmitSoundToAll(Resp2Snd,client);
		}
		
		IsTrapped[client] = 0;
		TrappedBy[client] = 0;
		TrapDelayer[client] = 0;
		FragCounter[client] = 0;
		Instructions[client] = 0;
		InstructionCounter[client] = 0;
		
		for(new skill=0; skill<5; skill++)
		{
			bIsUsed[skill][client] = false;
		}
		
		/* ******** How To Play ******** */
		for(new i=1;i<=MaxClients;i++)
		{
			if(War3_GetRace(i)==thisRaceID)
			{
				InstructionCounter[i] = 0;
				Instructions[i] = 1;
				CreateTimer( 0.1, Instruction, i);
				CreateTimer( 1.9, Instruction, i,TIMER_REPEAT);
			}
		}
	}
}
	

/* **************** RoundStartEvent **************** */
public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		IsTrapped[i] = 0;
		TrappedBy[i] = 0;
		TrapDelayer[i] = 0;
		FragCounter[i] = 0;
		Instructions[i] = 0;
		InstructionCounter[i] = 0;
		
		if(War3_GetRace(i)==thisRaceID)
		{
			Instructions[i] = 1;
		}
		
		for(new skill=0; skill<5; skill++)
		{
			bIsUsed[skill][i] = false;
		}
	}
}


/* **************** RoundOverEvent **************** */
public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		IsTrapped[i] = 0;
		TrappedBy[i] = 0;
		TrapDelayer[i] = 0;
		FragCounter[i] = 0;
		Instructions[i] = 0;
		InstructionCounter[i] = 0;
	}
}


/* *************************************** PlayerDeathEvent *************************************** */
public PlayerDeathEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new victim = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );
	
	new vteam = GetClientTeam( victim );
	new ateam = GetClientTeam( attacker );
	
	if( victim > 0 && attacker > 0 && attacker != victim)
	{
		if(vteam != ateam)
		{
			if(IsTrapped[attacker] != 0)
			{
				FragCounter[attacker]++;
			}
			
			if(War3_GetRace(victim) == thisRaceID && War3_GetSkillLevel(victim,thisRaceID,ULT_BEARTRAP) > 0 && !W3HasImmunity(attacker, Immunity_Ultimates))
			{
				IsTrapped[attacker] = 6; // attacker in beartrap ^^	
				TrappedBy[attacker] = victim;
				InstructionCounter[attacker] = 0;
				Instructions[attacker] = 6;
				CreateTimer( 0.1, Instruction, attacker);
				CreateTimer( 1.9, Instruction, attacker,TIMER_REPEAT);
				EmitSoundToAll(BeartrapSnd,attacker);
			}
		}
		else
		{
			if(IsTrapped[attacker] == 6) // Reverse Beartrap
			{
				IsTrapped[attacker] = 0; // free
				EmitSoundToAll(WinSnd,attacker);
			}			
		}
		
		if(IsTrapped[victim] == 1 || IsTrapped[victim] == 2 || IsTrapped[victim] == 3 || IsTrapped[victim] == 5 || IsTrapped[victim] == 6) // if trapped and die
		{
			IsTrapped[victim] = 0; // free
			Instructions[victim] = 0; // reset
			
			new death = (GetRandomInt(1,2));
			if(death == 1)
			{
				EmitSoundToAll(LaughSnd,victim);
			}
			if(death == 2)
			{
				EmitSoundToAll(GameOverSnd,victim);
			}
		}
	}
}

/* *************************************** CalcTrap *************************************** */
public Action:CalcTrap(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i,true))
		{
			switch(IsTrapped[i])
			{
				/* **************** Cube **************** */
				case 1: // Cube
				{
					if(FragCounter[i] != 1)
					{
						TrapDelayer[i]++;
						if(TrapDelayer[i] == 10)
						{
							new skill_cube = War3_GetSkillLevel(TrappedBy[i],thisRaceID,SKILL_CUBE);
							
							if(GetClientHealth(i) > CubeDMG[skill_cube])
							{
								War3_DecreaseHP(i, CubeDMG[skill_cube]);
							}
							else
							{
								War3_DealDamage(i,CubeDMG[skill_cube],TrappedBy[i],_,"cube",_,W3DMGTYPE_TRUEDMG);
								
								IsTrapped[i] = 0; // free
								Instructions[i] = 0; // reset
								
								new death = (GetRandomInt(1,2));
								if(death == 1)
								{
									EmitSoundToAll(LaughSnd,i);
								}
								if(death == 2)
								{
									EmitSoundToAll(GameOverSnd,i);
								}
							}
							TrapDelayer[i] = 0;
						}						
					}
					else // if amount of kills reached
					{
						IsTrapped[i] = 0; // free
						FragCounter[i] = 0; // reset
						TrapDelayer[i] = 0; // reset
						Instructions[i] = 0; // reset
						EmitSoundToAll(WinSnd,i); // sound
						PrintHintText(i, "You've escaped from the Trap");
					}
				}
				
				/* **************** Razor Wire **************** */
				case 2: // Razor Wire
				{
					if(FragCounter[i] != 1)
					{
						new Float:origin[3];
						new Float:distance;
						
						GetClientAbsOrigin(i,origin);
						distance = GetVectorDistance(origin,lastLocation[i]);
						
						new skill_razor = War3_GetSkillLevel(TrappedBy[i],thisRaceID,SKILL_RAZOR);
						
						new damage = RoundFloat(FloatMul(distance,RazorDMG[skill_razor]));
						
						if(GetClientHealth(i) > damage)
						{
							War3_DecreaseHP(i, damage);
						}
						else
						{
							War3_DealDamage(i,damage,TrappedBy[i],_,"bladetable",_,W3DMGTYPE_TRUEDMG);
								
							IsTrapped[i] = 0; // free
							Instructions[i] = 0; // reset
								
							new death = (GetRandomInt(1,2));
							if(death == 1)
							{
								EmitSoundToAll(LaughSnd,i);
							}
							if(death == 2)
							{
								EmitSoundToAll(GameOverSnd,i);
							}
						}
						
						lastLocation[i][0]=origin[0];
						lastLocation[i][1]=origin[1];
						lastLocation[i][2]=origin[2];						
					}
					else // if amount of kills reached
					{
						IsTrapped[i] = 0; // free
						FragCounter[i] = 0; // reset
						TrapDelayer[i] = 0; // reset
						Instructions[i] = 0; // reset
						EmitSoundToAll(WinSnd,i); // sound
						PrintHintText(i, "You've escaped from the Trap");
					}
				}
				
				/* **************** Furnace **************** */
				case 3: // Furnace
				{
					if(FragCounter[i] != 2)
					{
						TrapDelayer[i]++;
						if(TrapDelayer[i] == 10)
						{
							if( ValidPlayer(i, true))
							{
								IgniteEntity( i, 1.0);		
								TrapDelayer[i] =0;
							}
							else
							{
								IsTrapped[i] = 0; // free
								Instructions[i] = 0; // reset
								
								new death = (GetRandomInt(1,2));
								if(death == 1)
								{
									EmitSoundToAll(LaughSnd,i);
								}
								if(death == 2)
								{
									EmitSoundToAll(GameOverSnd,i);
								}
								
							}
						}
					}
					else // if amount of kills reached
					{
						IsTrapped[i] = 0; // free
						FragCounter[i] = 0; // reset
						TrapDelayer[i] = 0; // reset
						Instructions[i] = 0; // reset
						EmitSoundToAll(WinSnd,i); // sound
						PrintHintText(i, "You've escaped from the Trap");
					}
				}
				
				/* **************** Blade Table **************** */
				case 5: // Blade Table
				{
					if(FragCounter[i] != 2)
					{
						TrapDelayer[i]++;
						if(TrapDelayer[i] == 10)
						{
							new skill_bladetable = War3_GetSkillLevel(TrappedBy[i],thisRaceID,SKILL_BLADETABLE);
							
							if(GetClientHealth(i) > BladeTableDMG[skill_bladetable])
							{
								War3_DecreaseHP(i, BladeTableDMG[skill_bladetable]);
							}
							else
							{
								War3_DealDamage(i,BladeTableDMG[skill_bladetable],TrappedBy[i],_,"bladetable",_,W3DMGTYPE_TRUEDMG);
								
								IsTrapped[i] = 0; // free
								Instructions[i] = 0; // reset
								
								new death = (GetRandomInt(1,2));
								if(death == 1)
								{
									EmitSoundToAll(LaughSnd,i);
								}
								if(death == 2)
								{
									EmitSoundToAll(GameOverSnd,i);
								}
							}							
							TrapDelayer[i] =0;
						}
						
					}
					else // if amount of kills reached
					{
						IsTrapped[i] = 0; // free
						FragCounter[i] = 0; // reset
						TrapDelayer[i] = 0; // reset
						Instructions[i] = 0; // reset
						EmitSoundToAll(WinSnd,i); // sound
						PrintHintText(i, "You've escaped from the Trap");
					}
				}
				
				/* **************** Reverse Beartrap **************** */
				case 6: // Reverse Beartrap
				{
					if(FragCounter[i] != 2)
					{
						TrapDelayer[i]++;
						
						if(TrapDelayer[i] == 10*BeartrapTime[War3_GetSkillLevel(TrappedBy[i],thisRaceID,ULT_BEARTRAP)])
						{
							War3_DealDamage(i,99999,TrappedBy[i],_,"beartrap",_,W3DMGTYPE_TRUEDMG);
							
							IsTrapped[i] = 0; // free
							Instructions[i] = 0; // reset
								
							new death = (GetRandomInt(1,2));
							if(death == 1)
							{
								EmitSoundToAll(LaughSnd,i);
							}
							if(death == 2)
							{
								EmitSoundToAll(GameOverSnd,i);
							}
						}								
					}
					else // if amount of kills reached
					{
						IsTrapped[i] = 0; // free
						TrapDelayer[i] = 0; // reset
						Instructions[i] = 0; // reset
						EmitSoundToAll(WinSnd,i); // sound
						PrintHintText(i, "You've escaped from the Trap");
					}
				}
			}
		}
	}	
}



/* *************************************** OnAbilityCommand *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	new skill_cube = War3_GetSkillLevel(client,thisRaceID,SKILL_CUBE);
	new skill_razor = War3_GetSkillLevel(client,thisRaceID,SKILL_RAZOR);
	new skill_furnace = War3_GetSkillLevel(client,thisRaceID,SKILL_FURNACE);
	new skill_carousel = War3_GetSkillLevel(client,thisRaceID,SKILL_CAROUSEL);
	new skill_bladetable = War3_GetSkillLevel(client,thisRaceID,SKILL_BLADETABLE);
	
	
	/* *************************************** ABILITY 1 *************************************** */
	if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client))
	{              
        if((skill_cube==0)&&(skill_razor==0)&&(skill_furnace==0)&&(skill_carousel==0)&&(skill_bladetable==0))
        {
            PrintHintText(client, "You have no traps yet!");
        }
        else
        {
			new Handle:menu = CreateMenu(SelectTrap);
			SetMenuTitle(menu, "Which trap would you like to use?");
			if(skill_cube>0 && bIsUsed[0][client] == false)
            {
                AddMenuItem(menu, "cube", "Cube");
            }
			if(skill_razor>0 && bIsUsed[1][client] == false)
            {
                AddMenuItem(menu, "razorwire", "Razor Wire");
            }
			if(skill_furnace>0 && bIsUsed[2][client] == false)
            {
                AddMenuItem(menu, "furnace", "Furnace");
            }
			if(skill_carousel>0 && bIsUsed[3][client] == false)
			{
				AddMenuItem(menu, "carousel", "Carousel");
			}
			if(skill_bladetable>0 && bIsUsed[4][client] == false)
            {
                AddMenuItem(menu, "bladetable", "Blade Table");
            }
			SetMenuExitButton(menu, false);
			DisplayMenu(menu, client, 20);
        }
    }
	
	/* *************************************** ABILITY *************************************** */
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)) 
	{
		switch(CurrentTrap[client])
		{
			case(Cube):
			{
				CubeTrap(client,skill_cube);		
			}
			case(RazorWire):
			{
				RazorWireTrap(client,skill_razor);					
			}
			case(Furnace):
			{
				FurnaceTrap(client,skill_furnace);		
			}
			case(Carousel):
			{
				CarouselTrap(client,skill_carousel);		
			}
			case(BladeTable):
			
			{
				BladeTableTrap(client,skill_bladetable);		
			}
		}	
	}
}
 
/* *************************************** SelectTrap *************************************** */
public SelectTrap(Handle:menu, MenuAction:action, client, param2)
{
    if (action == MenuAction_Select)
    {
        new String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        if(StrEqual(info,"cube"))
        {
            if(CurrentTrap[client] != Cube)
            {
                CurrentTrap[client] = Cube;
            }
        }
        else if(StrEqual(info,"razorwire"))
        {
            if(CurrentTrap[client] != RazorWire)
            {
                CurrentTrap[client] = RazorWire;
            }
        }
        else if(StrEqual(info,"furnace"))
        {
			if(CurrentTrap[client] != Furnace)
            {
                CurrentTrap[client] = Furnace;
            }
        }
		else if(StrEqual(info,"carousel"))
        {
            if(CurrentTrap[client] != Carousel)
            {
                CurrentTrap[client] = Carousel;
            }
        }
		else if(StrEqual(info,"bladetable"))
        {
            if(CurrentTrap[client] != BladeTable)
            {
                CurrentTrap[client] = BladeTable;
            }
        }
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}


/* *************************************** CubeTrap *************************************** */
CubeTrap(any:client, any: skill)
{
	if(!Silenced(client))
	{
		if(bIsUsed[0][client] == false)
		{
			new cubeTarget = War3_GetTargetInViewCone(client,CubeRange[skill],false);
			
			if(ValidPlayer(cubeTarget,true) && !W3HasImmunity(cubeTarget,Immunity_Skills) && IsTrapped[cubeTarget] == 0)
			{
				new String:NameVictim[64];
				GetClientName( cubeTarget, NameVictim, 64 );
				
				InstructionCounter[cubeTarget] = 0;
				Instructions[cubeTarget] = 2;
				CreateTimer( 0.1, Instruction, cubeTarget);
				CreateTimer( 1.9, Instruction, cubeTarget,TIMER_REPEAT);
				PrintHintText(client, "You trapped %s into a Cube",NameVictim);
				
				EmitSoundToAll(LiveOrDieSnd,cubeTarget);
				
				bIsUsed[0][client] = true;
				IsTrapped[cubeTarget] = 1;
				TrappedBy[cubeTarget] = client;
			}
			else
			{
				PrintHintText(client, "No Target Found");
			}
		}
		else
		{
			PrintHintText(client, "You've already used this trap");			
		}
	}
}

/* *************************************** RazorWireTrap *************************************** */
RazorWireTrap(any:client, any: skill)
{
	if(!Silenced(client))
	{
		if(bIsUsed[1][client] == false)
		{
			new razorTarget = War3_GetTargetInViewCone(client,RazorRange[skill],false);
			
			if(ValidPlayer(razorTarget,true) && !W3HasImmunity(razorTarget,Immunity_Skills) && IsTrapped[razorTarget] == 0)
			{
				new String:NameVictim[64];
				GetClientName( razorTarget, NameVictim, 64 );
				
				InstructionCounter[razorTarget] = 0;
				Instructions[razorTarget] = 3;
				CreateTimer( 0.1, Instruction, razorTarget);
				CreateTimer( 1.9, Instruction, razorTarget,TIMER_REPEAT);
				PrintHintText(client, "You trapped %s into a Razor Wire",NameVictim);
				
				EmitSoundToAll(RazorSnd,razorTarget);
				
				GetClientAbsOrigin(razorTarget,lastLocation[razorTarget]);
				bIsUsed[1][client] = true;
				IsTrapped[razorTarget] = 2;
				TrappedBy[razorTarget] = client;
			}
			else
			{
				PrintHintText(client, "No Target Found");
			}
		}
		else
		{
			PrintHintText(client, "You've already used this trap");			
		}
	}
}


/* *************************************** FurnaceTrap *************************************** */
FurnaceTrap(any:client, any: skill)
{
	if(!Silenced(client))
	{
		if(bIsUsed[2][client] == false)
		{
			new furnaceTarget = War3_GetTargetInViewCone(client,FurnaceRange[skill],false);
			
			if(ValidPlayer(furnaceTarget,true) && !W3HasImmunity(furnaceTarget,Immunity_Skills) && IsTrapped[furnaceTarget] == 0)
			{
				new String:NameVictim[64];
				GetClientName( furnaceTarget, NameVictim, 64 );
				
				InstructionCounter[furnaceTarget] = 0;
				Instructions[furnaceTarget] = 4;
				CreateTimer( 0.1, Instruction, furnaceTarget);
				CreateTimer( 1.9, Instruction, furnaceTarget,TIMER_REPEAT);
				PrintHintText(client, "You trapped %s into a Furnace Trap",NameVictim);
				
				EmitSoundToAll(LiveOrDieSnd,furnaceTarget);
				
				bIsUsed[2][client] = true;
				IsTrapped[furnaceTarget] = 3;
				TrappedBy[furnaceTarget] = client;
			}
			else
			{
				PrintHintText(client, "No Target Found");
			}
		}
		else
		{
			PrintHintText(client, "You've already used this trap");			
		}
	}
}

/* *************************************** CarouselTrap *************************************** */
CarouselTrap(any:client, any: skill)
{
	if(!Silenced(client))
	{
		if(bIsUsed[3][client] == false)
		{
			new carouselTarget = GetRandomPlayer(client);
			
			if(carouselTarget > 0 && ValidPlayer(carouselTarget,true) && !W3HasImmunity(carouselTarget,Immunity_Skills))
			{
				
				new damage = CarouselDMG[skill];
				TrappedBy[carouselTarget] = client;
				
				if(GetClientHealth(carouselTarget) < damage)
				{
					new death = (GetRandomInt(1,2));
					if(death == 1)
					{
						EmitSoundToAll(LaughSnd,carouselTarget);
					}
					if(death == 2)
					{
						EmitSoundToAll(GameOverSnd,carouselTarget);
					}				
				}		
				
				War3_DealDamage(carouselTarget,damage,TrappedBy[carouselTarget],_,"carousel",_,W3DMGTYPE_TRUEDMG);
				EmitSoundToAll(CarouselSnd,carouselTarget);	
				
				new String:NameVictim[64];
				GetClientName( carouselTarget, NameVictim, 64 );
				
				PrintHintText(client, "You trapped %s into a Carousel",NameVictim);
				PrintHintText(carouselTarget, "You've been trapped into a Carousel and shot with a shotgun!");
				
				
				bIsUsed[3][client] = true;
				IsTrapped[carouselTarget] = 0;
			}
			else
			{
				PrintHintText(client, "No Target Found");
			}
		}
		else
		{
			PrintHintText(client, "You've already used this trap");			
		}
	}
}

/* **************** GetRandomPlayer **************** */
public GetRandomPlayer(any: client)
{
	new victims = 0;
	new jigsawTeam = GetClientTeam( client );
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( ValidPlayer( i, true ) && GetClientTeam( i ) != jigsawTeam && !W3HasImmunity( i, Immunity_Skills ) && IsTrapped[i] == 0)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				VictimsT[client][victims] = i;
				victims++;
			}
		}
	}
	
	if(victims == 0)
	{
		return 0;
	}
	else
	{
		new target = GetRandomInt(0,(victims-1));
		return VictimsT[client][target];		
	}
}


/* *************************************** BladeTableTrap *************************************** */
BladeTableTrap(any:client, any: skill)
{
	if(!Silenced(client))
	{
		if(bIsUsed[4][client] == false)
		{
			new bladetableTarget = War3_GetTargetInViewCone(client,BladeTableRange[skill],false);
			
			if(ValidPlayer(bladetableTarget,true) && !W3HasImmunity(bladetableTarget,Immunity_Skills) && IsTrapped[bladetableTarget] == 0)
			{
				IsTrapped[bladetableTarget] = 5;
				TrappedBy[bladetableTarget] = client;
				
				new String:NameVictim[64];
				GetClientName( bladetableTarget, NameVictim, 64 );
				
				PrintHintText(client, "You've trapped %s into a Blade table",NameVictim);
				PrintHintText(bladetableTarget, "You've been trapped into a Blade table");
				EmitSoundToAll(SacrificeSnd,bladetableTarget);
				
				new Handle:menu2 = CreateMenu(SelectDeath);
				SetMenuTitle(menu2, "Make your choice:");
				AddMenuItem(menu2, "game", "Play the Game");
				AddMenuItem(menu2, "sacrifice", "Sacrifice a part of your body");
				SetMenuExitButton(menu2, false);
				DisplayMenu(menu2, bladetableTarget, 20);
				
				bIsUsed[4][client] = true;
			}
			else
			{
				PrintHintText(client, "No Target Found");
			}
		}
		else
		{
			PrintHintText(client, "You've already used this trap");			
		}
	}
}

/* **************** SelectDeath **************** */
public SelectDeath(Handle:menu2, MenuAction:action, client, param2)
{
    if (action == MenuAction_Select)
    {
        new String:info[32];
        GetMenuItem(menu2, param2, info, sizeof(info));
        if(StrEqual(info,"game"))
        {			
			InstructionCounter[client] = 0;
			Instructions[client] = 5;
			CreateTimer( 0.1, Instruction, client);
			CreateTimer( 1.9, Instruction, client,TIMER_REPEAT);
			EmitSoundToAll(BloodSnd,client);
        }
        else if(StrEqual(info,"sacrifice"))
        {
			new damage = BladeTableSacrificeDMG[War3_GetSkillLevel(TrappedBy[client],thisRaceID,SKILL_BLADETABLE)];
			IsTrapped[client] = 0;
			TrappedBy[client] = 0;
			
			if(GetClientHealth(client) < damage)
			{
				new death = (GetRandomInt(1,2));
				if(death == 1)
				{
					EmitSoundToAll(LaughSnd,client);
				}
				if(death == 2)
				{
					EmitSoundToAll(GameOverSnd,client);
				}				
			}
			
			War3_DealDamage(client,damage,TrappedBy[client],_,"bladetable",_,W3DMGTYPE_TRUEDMG);
			PrintHintText(TrappedBy[client], "Enemy sacrificed a part of himself.");
        }
	}
    else if (action == MenuAction_End)
    {
        CloseHandle(menu2);
    }
}

/* **************** Instruction **************** */
public Action:Instruction( Handle:timer, any:client )
{
	if( ValidPlayer( client, true) )
	{
		switch(Instructions[client])
		{
			case 1:
			{
				PrintCenterText(client, "        Press  -ability1-  to select trap\nThen press  -ability-  to use it on target"); // How To Play		
			}
			case 2:
			{
				PrintCenterText(client, "Kill an enemy 1 kill or die! Make your choice!"); // Cube				
			}
			case 3:
			{
				PrintCenterText(client, "Kill an enemy or die but DO NOT MOVE! Make your choice!"); // Razor Wire	
			}
			case 4:
			{
				PrintCenterText(client, "Kill 2 enemies or burn! Make your choice!"); // Furnace	
			}
			case 5:
			{
				PrintCenterText(client, "Kill 2 enemies or die! Make your choice!"); // Blade Table	
			}
			case 6:
			{
				PrintCenterText(client, "Kill 2 enemies or 1 teammate or die! Make your choice!"); // Reverse Beartrap
			}		
		}		
		
		InstructionCounter[client]++;
		if(InstructionCounter[client] >= 11)
		{
			InstructionCounter[client] = 0;
			Instructions[client] = 0;
			KillTimer(timer);
		}
	}
}