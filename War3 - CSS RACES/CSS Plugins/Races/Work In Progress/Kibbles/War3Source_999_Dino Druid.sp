#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/RemyFunctions"

public Plugin:myinfo = 
{
    name = "War3Source Race - Dino Druid",
    author = "ABGar",
    description = "The Dino Druid race for War3Source.",
    version = "1.0",
    url = "http://sevensinsgaming.com"
}

new thisRaceID;

new SKILL_TRIC, SKILL_RAPT, SKILL_PTERAN, SKILL_GILIM;

enum FORM
{
    FORM_NONE=0,
    FORM_TRIC,
    FORM_RAPT,
    FORM_PTERAN,
    FORM_GILIM,
    CURRENT_FORM
}
new FormTracker[MAXPLAYERSCUSTOM][FORM];
new NumChangesPerForm=1;
new String:FormSound[]="npc/antlion_guard/angry1.wav";
new String:CDSound[]="war3source/ability_refresh.mp3";
new Float:MenuAvailableTime[MAXPLAYERSCUSTOM];
new bool:MenuInCooldown[MAXPLAYERSCUSTOM];

// SKILL_TRIC
new NewHealth[MAXPLAYERSCUSTOM];
new TrikeHealth[]={0,40,55,70,85,100};
new Float:ThornsDamage[]={0.0,0.06,0.06,0.06,0.06,0.06};//numbers changed to those requested
new Float:TrikeDamageReduce[]={1.0,0.96,0.92,0.88,0.84,0.8};

// SKILL_RAPT
new Float:RaptorSpeed[]={1.0,1.1,1.2,1.3,1.4,1.5};
new Float:RaptorInvis[]={1.0,0.8,0.675,0.55,0.425,0.3};//numbers changed to those requested

// SKILL_PTERAN
new bool:bFlying[MAXPLAYERSCUSTOM];
new String:bNormalModel[MAXPLAYERSCUSTOM];
new Float:CritMultiplier=1.5;
new Float:CritChance[]={0.0,0.1,0.2,0.3,0.4,0.5};
new Float:PteranodonVamp[]={0.0,0.1,0.125,0.15,0.175,0.2};//numbers changed to those requested
new String:PteranSound[]="npc/headcrab/attack2.wav";

// SKILL_GILIM
new g_iOrigRace[MAXPLAYERSCUSTOM];
new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity;
new Float:SkillLongJump[]={0.0,0.25,0.375,0.5,0.75,1.0};
new Float:GilimAttackSpeed[]={1.0,1.25,1.325,1.4,1.475,1.5};//numbers changed to those requested
new String:summon_sound[]="war3source/archmage/summon.wav";

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Dino Druid [PRIVATE]","dinodruid");
    SKILL_TRIC = War3_AddRaceSkill(thisRaceID,"Triceratops Form","Increased health, reduced damage taken, and thorns aura",false,5);
    SKILL_RAPT = War3_AddRaceSkill(thisRaceID,"Raptor Form","Speed and Inivisibility",false,5);
    SKILL_PTERAN = War3_AddRaceSkill(thisRaceID,"Pteranodon Form","Flight, vampiric aura, and critical strike",false,5);
    SKILL_GILIM = War3_AddRaceSkill(thisRaceID,"Giliminus Form","Long jump, respawn ally, and bonus attack speed (+ultimate)",false,5);
    War3_CreateRaceEnd(thisRaceID);
}


public OnRaceChanged(client,oldrace,newrace)
{
    if(newrace != thisRaceID)
    {
        War3_WeaponRestrictTo(client,thisRaceID,"");
        W3ResetAllBuffRace(client,thisRaceID);
        SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
        HUD_Add(GetClientUserId(client), "");//Use a definite removal function, so that AddHUD can be generalized to the race's forms
    }
    else
    {
        if (ValidPlayer(client,true))
        {
            InitPassiveSkills(client);
        }
    }
}

public OnWar3EventSpawn(client)
{
    if(War3_GetRace(client)==thisRaceID)
    {
        InitPassiveSkills(client);
    }
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=0; i<MaxClients; i++)
	{
		if (ValidPlayer(i, true))
		{
			if (War3_GetRace(i)==thisRaceID)
			{
				InitPassiveSkills(i);//Needed for when players survive a rounds
			}
		}
	}
}

public InitPassiveSkills(client)
{
    W3ResetAllBuffRace(client,thisRaceID);
    SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
    War3_SetBuff(client,bFlyMode,thisRaceID,false);
    bFlying[client]=false;
    ResetForms(client);
    War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
    FormMenu(client);
    AddHud(client);
    MenuAvailableTime[client]=GetGameTime();
    MenuInCooldown[client]=false;
}

public OnMapStart() 
{
    War3_PrecacheSound(FormSound);
    War3_PrecacheSound(summon_sound);
    War3_PrecacheSound(PteranSound);
    War3_PrecacheSound(CDSound);
    PrecacheModel("models/crow.mdl", true);//oops! You forgot this :)
}

public OnPluginStart()
{
    HookEvent("player_jump",PlayerJumpEvent);
    HookEvent("round_end", OnRoundEnd);
    HookEvent("round_start", Event_RoundStart);
    m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
    m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
    m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
    CreateTimer(0.1,MenuCooldownTimer,_,TIMER_REPEAT);
}

public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client=GetClientOfUserId(GetEventInt(event,"userid"));
    if(War3_GetRace(client)==thisRaceID && GetCurrentForm(client)==FORM_GILIM)
    {
        new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_GILIM);
        if(skilllevel>0)
        {
            new Float:velocity[3]={0.0,0.0,0.0};
            velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
            velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
            velocity[0]*=SkillLongJump[skilllevel];
            velocity[1]*=SkillLongJump[skilllevel];
            SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
        }
    }
}


public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
    {
        if(IsMenuAvailable(client))
        {
            if (!Silenced(client))
            {
                FormMenu(client);
            }
        }
        else
        {
            W3Hint(client,HINT_LOWEST,1.0,"Change Form isn't ready yet - %.1f seconds remaining",GetMenuCooldownRemaining(client));
        }
    }
}
public Action:MenuCooldownTimer(Handle:timer)
{
    for (new i=0; i<=MaxClients; i++)
    {
        if (War3_GetRace(i)==thisRaceID && IsMenuAvailable(i) && MenuInCooldown[i])//MenuInCooldown is used to avoid constantly playing the sound to people, but NOT to track availability!
        {
            MenuInCooldown[i]=false;
            PrintHintText(i,"Change Form is now ready");
            EmitSoundToAll(CDSound,i);
        }
    }
}
static SetMenuCooldown(client, Float:cooldown)
{
    MenuAvailableTime[client]=GetGameTime()+cooldown;
    MenuInCooldown[client]=(cooldown>0.0) ? true : false;
}
static Float:GetMenuCooldownRemaining(client)
{
    return (MenuAvailableTime[client]-GetGameTime());
}
static bool:IsMenuAvailable(client)
{
    return (GetGameTime()>=MenuAvailableTime[client]) ? true : false;
}

public FormMenu(client)
{
    if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
    {
        new Handle:menu = CreateMenu(ChangeFormMenu);
        SetMenuTitle(menu, "Select your form");
        AddMenuItem(menu, "trike", "Triceratops Form", (War3_GetSkillLevel(client,thisRaceID,SKILL_TRIC)>0 && IsFormAvailable(client, FORM_TRIC)) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        AddMenuItem(menu, "raptor", "Raptor Form", (War3_GetSkillLevel(client,thisRaceID,SKILL_RAPT)>0 && IsFormAvailable(client, FORM_RAPT)) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        AddMenuItem(menu, "pteranodon", "Pteranodon Form", (War3_GetSkillLevel(client,thisRaceID,SKILL_PTERAN)>0 && IsFormAvailable(client, FORM_PTERAN)) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        AddMenuItem(menu, "giliminus", "Giliminus Form", (War3_GetSkillLevel(client,thisRaceID,SKILL_GILIM)>0 && IsFormAvailable(client, FORM_GILIM)) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, client, 20);
    }
}

public ChangeFormMenu(Handle:menu, MenuAction:action, client, param2)
{
    if (action == MenuAction_Select)
    {
        new String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        
        new Handle:formData = CreateDataPack();//Using datapacks is a much better way to track multiple pieces of info in a timer, rather than global arrays.
        WritePackCell(formData, client);
        
        if(StrEqual(info,"trike"))
        {
            if(GetCurrentForm(client)==FORM_TRIC)//These checks shouldn't be needed any more, as the menus will be greyed out. There'll also be no need for availability checks as that's handled by the FormHandler interface.
            {
                PrintHintText(client,"You are already in TRICERATOPS form.  Pick again");
                FormMenu(client);
            }
            else
            {
                WritePackCell(formData, FORM_TRIC);
                PrintHintText(client,"You will change to TRICERATOPS form in 2 seconds");
                SetMenuCooldown(client,12.0);
            }
        }
        else if(StrEqual(info,"raptor"))
        {
            if(GetCurrentForm(client)==FORM_RAPT)
            {
                PrintHintText(client,"You are already in RAPTOR form.  Pick again");
                FormMenu(client);
            }
            else
            {
                WritePackCell(formData, FORM_RAPT);
                PrintHintText(client,"You will change to RAPTOR form in 2 seconds");
                SetMenuCooldown(client,12.0);
            }
        }
        else if(StrEqual(info,"pteranodon"))
        {
            if(GetCurrentForm(client)==FORM_PTERAN)
            {
                PrintHintText(client,"You are already in PTERANODON form.  Pick again");
                FormMenu(client);
            }
            else
            {
                WritePackCell(formData, FORM_PTERAN);
                PrintHintText(client,"You will change to PTERANODON form in 2 seconds");
                SetMenuCooldown(client,12.0);
            }
        }
        else if(StrEqual(info,"giliminus"))
        {
            if(GetCurrentForm(client)==FORM_GILIM)
            {
                PrintHintText(client,"You are already in GILIMINUS form.  Pick again");
                FormMenu(client);
            }
            else
            {
                WritePackCell(formData, FORM_GILIM);
                PrintHintText(client,"You will change to GILIMINUS form in 2 seconds");
                SetMenuCooldown(client,12.0);
            }
        }
        
        CreateTimer(2.0, ChangeForm, formData);
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public Action:ChangeForm(Handle:timer,Handle:formData)
{
    ResetPack(formData,false);//resets position to first cell
    new client = ReadPackCell(formData);
    new FORM:newForm = ReadPackCell(formData);
    new FORM:oldForm = GetCurrentForm(client);//Use this to check trike, rather than a global array
    CloseHandle(formData);
    
    if(bFlying[client])
        CreateTimer(0.1,returnform,client);
    EmitSoundToAll(FormSound,client);
    
    if(War3_GetRace(client)==thisRaceID)
    {
        new TrikeLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_TRIC);
        if(oldForm==FORM_TRIC)
        {
            new TempHealth=((GetClientHealth(client)*100)/(TrikeHealth[TrikeLevel]+100));//Use a percentage of their remaining Trike health
            SetEntityHealth(client,TempHealth);
            /*
            if((CurrentHealth-NewHealth[client])>0)
                SetEntityHealth(client,(CurrentHealth-NewHealth[client]));
            else
                SetEntityHealth(client,1);
            */
        }
        if(newForm==FORM_TRIC)
        {
            W3ResetAllBuffRace(client,thisRaceID);
            SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
            new TempHealth = GetClientHealth(client);
            NewHealth[client]=((TrikeHealth[TrikeLevel]*TempHealth)/100);
            SetEntityHealth(client,(TempHealth+NewHealth[client]));
        }
        if(newForm==FORM_RAPT)
        {
            new RaptorLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_RAPT);//There's no need to check every form's levels, every time
            W3ResetAllBuffRace(client,thisRaceID);
            SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
            War3_SetBuff(client,fMaxSpeed,thisRaceID,RaptorSpeed[RaptorLevel]);
            War3_SetBuff(client,fInvisibilitySkill,thisRaceID,RaptorInvis[RaptorLevel]);
        }
        if(newForm==FORM_PTERAN)
        {
            new PteranodonLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_PTERAN);
            W3ResetAllBuffRace(client,thisRaceID);
            SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
            War3_SetBuff(client,fVampirePercent,thisRaceID,PteranodonVamp[PteranodonLevel]);
        }
        if(newForm==FORM_GILIM)
        {
            new GilimLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_GILIM);
            W3ResetAllBuffRace(client,thisRaceID);
            SetEntPropFloat(client, Prop_Send, "m_flModelScale", 0.75);
            War3_SetBuff(client,fAttackSpeed,thisRaceID,GilimAttackSpeed[GilimLevel]);
        }
        
        ChangeCurrentForm(client, newForm);
        AddHud(client);
    }
}

public AddHud(client)
{
    if(ValidPlayer(client) && War3_GetRace(client) == thisRaceID)//There's no need to use the HUD for summons. The normal information will tell them they're a summon race
    {
        new String:HUD_Buffer[200];
        new String:buffer[50];
        
        if(GetCurrentForm(client)==FORM_NONE)
        {
            Format(buffer, sizeof(buffer), "");
            StrCat(HUD_Buffer, sizeof(HUD_Buffer), buffer);
        }        
        if(GetCurrentForm(client)==FORM_TRIC)
        {
            Format(buffer, sizeof(buffer), "\nTriceratops Form");
            StrCat(HUD_Buffer, sizeof(HUD_Buffer), buffer);
        }
        if(GetCurrentForm(client)==FORM_RAPT)
        {
            Format(buffer, sizeof(buffer), "\nRaptor Form");
            StrCat(HUD_Buffer, sizeof(HUD_Buffer), buffer);
        }
        if(GetCurrentForm(client)==FORM_PTERAN)
        {
            Format(buffer, sizeof(buffer), "\nPteranodon Form");
            StrCat(HUD_Buffer, sizeof(HUD_Buffer), buffer);
        }
        if(GetCurrentForm(client)==FORM_GILIM)
        {
            Format(buffer, sizeof(buffer), "\nGiliminus Form");
            StrCat(HUD_Buffer, sizeof(HUD_Buffer), buffer);
        }
        
        HUD_Add(GetClientUserId(client), HUD_Buffer);
    }
}

public OnWar3EventDeath(victim,attacker)
{
    if(bFlying[victim])
        CreateTimer(0.1,returnform,victim);
    new gilim=War3_GetRaceIDByShortname("giliminus");
    if(g_iOrigRace[victim]!=0 && War3_GetRace(victim)==gilim)
    {
        ChangeClientToOrigRace(victim);
    }
    if(War3_GetRace(victim)==thisRaceID)
    {
        ResetForms(victim);
        AddHud(victim);
    }
}

/* *************************************** (SKILL_TRIC) *************************************** */
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
    if(ValidPlayer(victim, true) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
    {
        if(War3_GetRace(victim)==thisRaceID)
        {
            if(GetCurrentForm(victim)==FORM_TRIC)
            {
                if(SkillFilter(victim))
                {
                    new TrikeLevel = War3_GetSkillLevel(victim,thisRaceID,SKILL_TRIC);
                    if(TrikeLevel>0)
                    {
                        new damage_i=RoundToFloor(damage*ThornsDamage[TrikeLevel]);
                        if(damage_i>0)
                        {
                            if(damage_i>40) damage_i=40;
                            War3_DealDamage(attacker,damage_i,victim,_,"thorns",_,W3DMGTYPE_PHYSICAL);
                            PrintToConsole(attacker,"Recieved -%d Thorns dmg",War3_GetWar3DamageDealt());
                            PrintToConsole(victim,"You reflected -%d Thorns damage",War3_GetWar3DamageDealt());
                            W3FlashScreen(attacker,RGBA_COLOR_RED);
                        }
                    }
                }
            }
        }
    }
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
    if(ValidPlayer(victim, true) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
    {
        if(War3_GetRace(victim)==thisRaceID)
        {
            if(GetCurrentForm(victim)==FORM_TRIC)
            {
                if(SkillFilter(victim))
                {
                    new TrikeLevel = War3_GetSkillLevel(victim,thisRaceID,SKILL_TRIC);
                    if(TrikeLevel>0)
                        War3_DamageModPercent(TrikeDamageReduce[TrikeLevel]);
                }
            }
        }
        if(War3_GetRace(attacker)==thisRaceID)
        {
            if(GetCurrentForm(attacker)==FORM_PTERAN)
            {
                new PteranodonLevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_PTERAN);
                if(PteranodonLevel>0)        
                {
                    if(W3Chance(CritChance[PteranodonLevel]))
                    {
                        War3_DamageModPercent(CritMultiplier);
                        PrintHintText(attacker,"CRITICAL STRIKE");
                        PrintHintText(victim,"CRITICAL STRIKE");
                    }
                }
            }
        }
    }
}

/* *************************************** (SKILL_PTERAN) *************************************** */
public Action:returnform(Handle:h, any:client)
{
    if(ValidPlayer(client) && bFlying[client])
    {
        bFlying[client]=false;
        War3_SetBuff(client,bFlyMode,thisRaceID,false);
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
        if (IsPlayerAlive(client))//Always reset buffs/weaponrestrictions
        {
            GivePlayerItem(client,"weapon_knife");
            SetEntityModel(client,bNormalModel[client]);
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && ValidPlayer(client,true))
    {
        new FORM:currentForm = GetCurrentForm(client);
        if(currentForm==FORM_NONE)
            PrintHintText(client,"Choose a form first");
        if(currentForm==FORM_TRIC || currentForm==FORM_RAPT)
            PrintHintText(client,"There is no ultimate in this form");
        if(currentForm==FORM_PTERAN)
        {
            new PteranodonLevel=War3_GetSkillLevel(client,race,SKILL_PTERAN);
            if(PteranodonLevel>0)        
            {
                if(SkillAvailable(client,thisRaceID,SKILL_PTERAN,true,true,true))
                {
                    War3_CooldownMGR(client,3.0,thisRaceID,SKILL_PTERAN,_,false);//cooldown up top :)
                    if(!bFlying[client])
                    {
                        GetClientModel(client,bNormalModel[client],256);
                        bFlying[client]=true;
                        War3_SetBuff(client,bFlyMode,thisRaceID,true);
                        SetEntityModel(client, "models/crow.mdl");
                        EmitSoundToAll(PteranSound,client);
                        new iWeapon = GetPlayerWeaponSlot(client, 2);  
                        if(IsValidEntity(iWeapon))
                        {
                            RemovePlayerItem(client, iWeapon);
                            AcceptEntityInput(iWeapon, "kill");
                        }
                        War3_WeaponRestrictTo(client,thisRaceID,"Pteranodon_Form");
                    }
                    else
                        CreateTimer(0.1,returnform,client);
                }
            }
            else
                W3MsgUltNotLeveled(client);
        }
/* *************************************** (SKILL_GILIM) *************************************** */
        if(currentForm==FORM_GILIM)
        {
            new GilimLevel=War3_GetSkillLevel(client,race,SKILL_GILIM);
            if(GilimLevel>0)        
            {
                if(SkillAvailable(client,thisRaceID,SKILL_GILIM,true,true,true))
                    RespawnAlly(client);
            }
            else
                W3MsgUltNotLeveled(client);
        }
    }
}

public RespawnAlly(client)
{
    new targets[MAXPLAYERS];
    new foundtargets;
    new client_team=GetClientTeam(client);//moved this here so it doesn't trigger more than is necessary
    for(new ally=1;ally<=MaxClients;ally++)
    {
        if(ValidPlayer(ally))
        {
            new ally_team=GetClientTeam(ally);
            if(War3_GetRace(ally)!=thisRaceID && !IsPlayerAlive(ally) && ally_team==client_team)
            {
                targets[foundtargets]=ally;
                foundtargets++;
            }
        }
    }
    new target;
    if(foundtargets>0)
    {
        target=targets[GetRandomInt(0, foundtargets-1)];
        if(target>0)
        {
            g_iOrigRace[target] = War3_GetRace(target);
            War3_CooldownMGR(client,30.0,thisRaceID,SKILL_GILIM,_,_);
            new Float:ang[3];
            new Float:pos[3];
            ChangeClientToGilim(target);
            GetClientEyeAngles(client,ang);
            GetClientAbsOrigin(client,pos);
            War3_SpawnPlayer(target);
            TeleportEntity(target,pos,ang,NULL_VECTOR);
            EmitSoundToAll(summon_sound,client);
            CreateTimer(3.0, Stop, client);
        }
    }
    else
        PrintHintText(client,"There are no allies that you can respawn");
}

public Action:Stop(Handle:timer,any:client)
{
    StopSound(client,SNDCHAN_AUTO,summon_sound);
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    for(new victim=1;victim<=MaxClients;victim++)
    if(ValidPlayer(victim,true))
    {
        new gilim=War3_GetRaceIDByShortname("giliminus");
        if(g_iOrigRace[victim] != 0 && War3_GetRace(victim)==gilim)
        {
            ChangeClientToOrigRace(victim);
        }
    }
}


//
// Summon helpers
//
static ChangeClientToGilim(client)
{
    new gilim=War3_GetRaceIDByShortname("giliminus");
    W3SetPlayerProp(client,RaceChosenTime,GetGameTime()); // Added to ensure players can access the hidden summon race
    W3SetPlayerProp(client,RaceSetByAdmin,true);          //
    War3_SetRace(client,gilim);
}

static ChangeClientToOrigRace(client)
{
    if(g_iOrigRace[client] != 0)
    {
        War3_SetRace(client,g_iOrigRace[client]);
        g_iOrigRace[client] = 0;
    }
}

//
// Form handlng
//
static ResetForms(client)
{
    FormTracker[client][FORM_TRIC] = NumChangesPerForm;
    FormTracker[client][FORM_RAPT] = NumChangesPerForm;
    FormTracker[client][FORM_PTERAN] = NumChangesPerForm;
    FormTracker[client][FORM_GILIM] = NumChangesPerForm;
    FormTracker[client][CURRENT_FORM] = _:FORM_NONE;
}

static FORM:GetCurrentForm(client)
{
    return FORM:FormTracker[client][CURRENT_FORM];
}

static bool:IsFormAvailable(client, FORM:form)
{
    return (FormTracker[client][form]>0 && GetCurrentForm(client)!=form) ? true : false;
}

static FORM:ChangeCurrentForm(client, FORM:newForm)
{
    new FORM:oldForm = FORM:FormTracker[client][CURRENT_FORM];
    if (FormTracker[client][newForm] > 0)
    {
        FormTracker[client][CURRENT_FORM] = _:newForm;
        if (oldForm != FORM_NONE)
        {
            FormTracker[client][newForm]--;
        }
    }
    return FORM:FormTracker[client][CURRENT_FORM];
}