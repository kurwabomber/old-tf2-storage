/*
 * ZERO STOCKS EFFECTS v1.0.0
 * AWSOME STOCKS THAT DO SHIT RIGHT!
 * www.IBISGaming.com
 */

#if defined _zerostocks_effects_included
  #endinput
#endif
#define _zerostocks_effects_included

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <cstrike>
#include <smlib>

#define PI 3.1415926535897932384626433832795

new BeamSpriteCircle;
new HaloSpriteCircle;
/*
 * Required to use Circle
 */
stock OnMapStart_Circle()
{
	BeamSpriteCircle = PrecacheModel("materials/sprites/laser.vmt", true);
	HaloSpriteCircle = PrecacheModel("materials/sprites/halo01.vmt", true);
}
	
/*
 * Required for TE_SetupWorldDecal return .vmt value must be used as input for index in TE_SetupWorldDecal
 * 
 * @param filename		Location of Decal.
 * @return				Ent.
 */
stock OnMapStart_PrecacheDecal(const String:filename[])
{
    new String:tmpPath[PLATFORM_MAX_PATH];
    new result = 0;
    result = PrecacheDecal(filename, true);
    Format(tmpPath,sizeof(tmpPath),"%s",filename);
    AddFileToDownloadsTable(tmpPath);
    return result;
}

/*
 * Creates a Temp Ent Decal for use with normal TE_ functions
 * NOTE TE_Send based command MUST FOLLOW
 * 
 * @param Float:vecOrigin[3]		Location to place Decal.
 * @param index						Ent to use must have been a .vmt file.
 */
stock TE_SetupWorldDecal(const Float:vecOrigin[3], index)
{    
	TE_Start("World Decal");
	TE_WriteVector("m_vecOrigin",vecOrigin);
	TE_WriteNum("m_nIndex",index);
}

/*
 * CREATE SMOKE
 * 
 * @param client				Player to target.
 * @param Float:fLifetime		Length of effect.
 * @param Float:ReletivePos[3]	Reletive position of Entity XYZ.
 * @param Float:fAng[3]			Angles (P Y R).
 * @param Float:BaseSpread		Radius of Effect.
 * @param Float:StartSize		Size of the smoke particles when they're first emitted.
 * @param Float:EndSize			Size of the smoke particles at the point they fade out completely. 
 * @param Float:Twist			The amount, in degrees per second, that the smoke particles twist around the origin. 
 * @param String:material		Material of the smoke particles emitted by this stack.
 * @param String:renderclr		Color RBG.
 * @param String:SpreadSpeed	Set the amount of random spread in the velocity of the smoke particles after they're spawned.
 * @param String:JetLength		Set the length of the smoke trail. 
 * @param String:Speed			Set the speed at which the smoke particles move after they're spawned.
 * @param String:Rate			Set the rate at which to emit smoke particles (particles per second).
 * @param bool:parentent		Should it be attached to a player?
 * @return						Ent on success, -1 otherwise.
 */
stock CreateSmoke(const client,Float:fLifetime,Float:ReletivePos[3],Float:fAng[3],Float:BaseSpread,Float:StartSize,Float:EndSize,Float:Twist,String:material[],String:renderclr[],String:SpreadSpeed[],String:JetLength[],String:Speed[],String:Rate[],bool:parentent)
{
	new particle = CreateEntityByName("env_smokestack");
	if(IsValidEdict(particle) && IsClientInGame(client))
	{
		decl String:Name[32], Float:fPos[3];
		Format(Name, sizeof(Name), "W3S_particles_%i", client);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
		fPos[0] += ReletivePos[0];
		fPos[1] += ReletivePos[1];
		fPos[2] += ReletivePos[2];
		// Set Key Values
		DispatchKeyValueVector(particle, "Origin", fPos);
		DispatchKeyValueVector(particle, "Angles", fAng);
		DispatchKeyValueFloat(particle, "BaseSpread", BaseSpread);
		DispatchKeyValueFloat(particle, "StartSize", StartSize);
		DispatchKeyValueFloat(particle, "EndSize", EndSize);
		DispatchKeyValueFloat(particle, "Twist", Twist);
		
		DispatchKeyValue(particle, "Name", Name);
		DispatchKeyValue(particle, "SmokeMaterial", material);
		DispatchKeyValue(particle, "RenderColor", renderclr);
		DispatchKeyValue(particle, "SpreadSpeed", SpreadSpeed);
		DispatchKeyValue(particle, "RenderAmt", "255");
		DispatchKeyValue(particle, "JetLength", JetLength);
		DispatchKeyValue(particle, "RenderMode", "0");
		DispatchKeyValue(particle, "Initial", "0");
		DispatchKeyValue(particle, "Speed", Speed);
		DispatchKeyValue(particle, "Rate", Rate);
		DispatchSpawn(particle);
		
		// Set Entity Inputs
		if(parentent)
		{
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", client, particle, 0);
		}
		AcceptEntityInput(particle, "TurnOn");
		CreateTimer(fLifetime, RemoveParticle, particle);
		return particle;
	}
	else
	{
		LogError("Failed to create entity env_smokestack!");
	}
	return -1;
}


/*
 * CREATE SPRITE
 * 
 * @param iClient				Player to target.
 * @param String:sprite			Path to VMT File.
 * @param Float:vOrigin[3]		Location of Sprite.
 * @param Float:fAng[3]			Angles (P Y R).
 * @param Float:Scale			Size of Sprite.
 * @param String:fps			Render Speed.
 * @param Float:fLifetime		Life of Sprite. 
 */
stock CreateSprite(iClient, String:sprite[], Float:vOrigin[3], Float:fAng[3], Float:Scale, String:fps[], Float:fLifetime) 
{ 
    new String:szTemp[64];  
    Format(szTemp, sizeof(szTemp), "client%i", iClient); 
    DispatchKeyValue(iClient, "targetname", szTemp); 
	
    new ent = CreateEntityByName("env_sprite_oriented"); 
    if (IsValidEdict(ent)) 
    { 
		new String:StrEntityName[64]; Format(StrEntityName, sizeof(StrEntityName), "ent_sprite_oriented_%i", ent); 
		DispatchKeyValue(ent, "model", sprite); 
		DispatchKeyValue(ent, "classname", "env_sprite_oriented");
		DispatchKeyValue(ent, "spawnflags", "1");
		DispatchKeyValueFloat(ent, "scale", Scale);
		DispatchKeyValue(ent, "rendermode", "1");
		DispatchKeyValue(ent, "rendercolor", "255 255 255");
		DispatchKeyValue(ent, "framerate", fps);
		DispatchKeyValueVector(ent, "Angles", fAng);
		DispatchSpawn(ent);
		
		TeleportEntity(ent, vOrigin, fAng, NULL_VECTOR); 
		
		CreateTimer(fLifetime, RemoveParticle, ent);
    } 
}

stock CreateFire(const client,String:firesize[],String:health[],String:fireattack[],String:firetype[],String:flags[],Float:damagescale,Float:fLifetime){
	new fire = CreateEntityByName("env_fire");
	if(IsValidEdict(fire) && IsClientInGame(client))
	{
		decl String:Name[32], Float:fPos[3];
		Format(Name, sizeof(Name), "W3S_fire_%i", client);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
		DispatchKeyValueFloat(fire, "damagescale", damagescale);

		DispatchKeyValue(fire, "Name", Name);
		DispatchKeyValue(fire, "health", health);
		DispatchKeyValue(fire, "fireattack", fireattack);
		DispatchKeyValue(fire, "firetype", firetype);
		DispatchKeyValue(fire, "flags", flags);
		DispatchKeyValue(fire, "firesize", firesize);
		DispatchSpawn(fire);
		ActivateEntity(fire);
		TeleportEntity(fire, fPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(fire, "StartFire");
		CreateTimer(fLifetime, RemoveParticle, fire);
		return fire;
	}
	else
	{
		LogError("Failed to create entity env_fire!");
	}
	return -1;
}

stock CreateTesla(const client,Float:flifetime_min,Float:flifetime_max,Float:thick_min,Float:thick_max,Float:interval_min,Float:interval_max,Float:radiustesla,String:beamcount_min[],String:beamcount_max[],String:ColorTesla[],String:sound[],String:beammodel[],bool:spark){

	new point_tesla = CreateEntityByName("point_tesla");
	if(IsValidEdict(point_tesla) && IsClientInGame(client))
	{

		decl String:Name[32], Float:fPos[3];
		Format(Name, sizeof(Name), "W3S_tesla_%i", client);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
		fPos[2]+=42.0;
		DispatchKeyValueFloat(point_tesla, "lifetime_min", flifetime_min);
		DispatchKeyValueFloat(point_tesla, "lifetime_min", flifetime_max);
		DispatchKeyValueFloat(point_tesla, "thick_min", thick_min);
		DispatchKeyValueFloat(point_tesla, "thick_max", thick_max);
		DispatchKeyValueFloat(point_tesla, "interval_min", interval_min);
		DispatchKeyValueFloat(point_tesla, "interval_max", interval_max);
		DispatchKeyValueFloat(point_tesla, "m_flRadius", radiustesla);
		DispatchKeyValue(point_tesla, "m_Color", ColorTesla);
		
		DispatchKeyValue(point_tesla, "Name", Name);
		DispatchKeyValue(point_tesla, "beamcount_min", beamcount_min);
		DispatchKeyValue(point_tesla, "beamcount_max", beamcount_max);
		DispatchKeyValue(point_tesla, "m_SoundName", sound);
		DispatchKeyValue(point_tesla, "texture", beammodel);
		DispatchSpawn(point_tesla);		
		ActivateEntity(point_tesla);
	//	Entity_ClearSolidFlags(point_tesla);
	//	decl Float:fAngles[3];
	//	GetClientEyeAngles(client, fAngles);
	//	new ax = 0;
	//	fAngles[0]=0.0,fAngles[2]=0.0;
	//	if(fAngles[1]<135 && fAngles[1]>45) {
	//	ax = 1;
	//	}
	//	else if(fAngles[1]>-135 && fAngles[1]<-45) {
	//	ax = 1;
	//	}
	//	fPos[2]-=30.0;
		TeleportEntity(point_tesla, fPos, NULL_VECTOR, NULL_VECTOR);	
		AcceptEntityInput(point_tesla, "TurnOn");
		if(spark)
		AcceptEntityInput(point_tesla, "DoSpark");

		CreateTimer(flifetime_max+0.2, RemoveParticle, point_tesla);
		return point_tesla;	
	}
	else
	{

		LogError("Failed to create entity point_tesla!");
	}
	return -1;
}

/*
 * REMOVE PARTICLE ENT
 * 
 * @param particle		Ent to remove.
 */
public Action:RemoveParticle(Handle:timer, any:particle)
{
	if(IsValidEdict(particle))
	{
		AcceptEntityInput(particle, "Deactivate");
		AcceptEntityInput(particle, "Kill");
	}
}


/*
 * Beam Ent Point
 * 
 * @param haloIndex						Set to 0 as default.
 * @param modelIndex					index of model.
 * @param startEntity					Ent to start effect at.
 * @param Float:startposition[3]		Reletive position to ENT.
 * @param endEntity						Ent to end effect at.
 * @param Float:endposition[3]			Reletive position to ENT.
 * @param frameRate						fps.
 * @param Float:lifeF					length of effect duration.
 * @param Float:widthF					Starting width.
 * @param Float:endWidthF				Ending width.
 * @param fadeLength					fade distance of effect.
 * @param Float:amplitudeF				amplitude of beam.
 * @param colorArray[4]					colors of effect RGBA.
 * @param speed							speed of effect.
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock BeamEntPoint(haloIndex, modelIndex, startEntity, Float:startposition[3], endEntity, Float:endposition[3], frameRate, Float:lifeF, Float:widthF, Float:endWidthF, fadeLength, Float:amplitudeF, colorArray[4], speed)
{
	TE_Start("BeamEntPoint");
	TE_WriteNum("m_nHaloIndex", haloIndex);
	TE_WriteNum("m_nModelIndex", modelIndex);
	TE_WriteNum("m_nStartFrame", 0);
	TE_WriteNum("m_nFrameRate", frameRate);
	TE_WriteFloat("m_fLife", lifeF);
	TE_WriteFloat("m_fWidth", widthF);
	TE_WriteFloat("m_fEndWidth", endWidthF);
	TE_WriteNum("m_nFadeLength", fadeLength);
	TE_WriteFloat("m_fAmplitude", amplitudeF);
	TE_WriteNum("m_nSpeed", speed);
	TE_WriteNum("r", colorArray[0]);
	TE_WriteNum("g", colorArray[1]);
	TE_WriteNum("b", colorArray[2]);
	TE_WriteNum("a", colorArray[3]);
	TE_WriteNum("m_nStartEntity", startEntity);
	TE_WriteNum("m_nEndEntity", endEntity);
	TE_WriteVector("m_vecStartPoint", startposition);
	TE_WriteVector("m_vecEndPoint", endposition);
	TE_SendToAll();
}

/*
 * BeamEnts
 * 
 * @param haloIndex						Set to 0 as default.
 * @param modelIndex					index of model.
 * @param startEntity					Ent to start effect at.
 * @param endEntity						Ent to end effect at.
 * @param frameRate						fps.
 * @param Float:lifeF					length of effect duration.
 * @param Float:widthF					Starting width.
 * @param Float:endWidthF				Ending width.
 * @param fadeLength					fade distance of effect.
 * @param Float:amplitudeF				amplitude of beam.
 * @param colorArray[4]					colors of effect RGBA.
 * @param speed							speed of effect.
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock BeamEnts(haloIndex, modelIndex, startEntity, endEntity, frameRate, Float:lifeF, Float:widthF, Float:endWidthF, fadeLength, Float:amplitudeF, colorArray[4], speed)
{
    TE_Start("BeamEnts");
    TE_WriteNum("m_nHaloIndex", haloIndex);
    TE_WriteNum("m_nModelIndex", modelIndex);
    TE_WriteNum("m_nStartEntity", startEntity);
    TE_WriteNum("m_nEndEntity", endEntity);
    TE_WriteNum("m_nStartFrame", 0);
    TE_WriteNum("m_nFrameRate", frameRate);
    TE_WriteFloat("m_fLife", lifeF);
    TE_WriteFloat("m_fWidth", widthF);
    TE_WriteFloat("m_fEndWidth", endWidthF);
    TE_WriteNum("m_nFadeLength", fadeLength);
    TE_WriteFloat("m_fAmplitude", amplitudeF);
    TE_WriteNum("r", colorArray[0]);
	TE_WriteNum("g", colorArray[1]);
	TE_WriteNum("b", colorArray[2]);
	TE_WriteNum("a", colorArray[3]);
	TE_WriteNum("m_nSpeed", speed);
	TE_SendToAll();
}

/*
 * BeamRing
 * 
 * @param haloIndex						Set to 0 as default.
 * @param modelIndex					index of model.
 * @param startEntity					Ent to start effect at.
 * @param endEntity						Ent to end effect at.
 * @param frameRate						fps.
 * @param Float:lifeF					length of effect duration.
 * @param Float:widthF					Starting width.
 * @param Float:endWidthF				Ending width.
 * @param fadeLength					fade distance of effect.
 * @param Float:amplitudeF				amplitude of beam.
 * @param colorArray[4]					colors of effect RGBA.
 * @param speed							speed of effect.
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock BeamRing(haloIndex, modelIndex, startEntity, endEntity, frameRate, Float:lifeF, Float:widthF, Float:endWidthF, fadeLength, Float:amplitudeF, colorArray[4], speed)
{      
    TE_Start("BeamRing");
    TE_WriteNum("m_nModelIndex", modelIndex);
    TE_WriteNum("m_nHaloIndex", haloIndex);
    TE_WriteNum("m_nStartEntity", startEntity);
    TE_WriteNum("m_nEndEntity", endEntity);
    TE_WriteNum("m_nStartFrame", 0);
    TE_WriteNum("m_nFrameRate", frameRate);
    TE_WriteFloat("m_fLife", lifeF);
    TE_WriteFloat("m_fWidth", widthF);
    TE_WriteFloat("m_fEndWidth", endWidthF);
    TE_WriteNum("m_nFadeLength", fadeLength);
    TE_WriteFloat("m_fAmplitude", amplitudeF);
    TE_WriteNum("r", colorArray[0]);
	TE_WriteNum("g", colorArray[1]);
	TE_WriteNum("b", colorArray[2]);
	TE_WriteNum("a", colorArray[3]);
    TE_WriteNum("m_nSpeed", speed);
    TE_WriteNum("m_nFlags", 0);
    TE_SendToAll();
}

/*
 * BeamRing POINT
 * 
 * @param haloIndex						Set to 0 as default.
 * @param modelIndex					index of model.
 * @param Float:center[3]				Center of Ring.
 * @param startRadius					Radius to start effect at.
 * @param endRadius						Radius to end effect at.
 * @param frameRate						fps.
 * @param Float:lifeF					length of effect duration.
 * @param Float:widthF					Starting width.
 * @param Float:endWidthF				Ending width.
 * @param fadeLength					fade distance of effect.
 * @param Float:amplitudeF				amplitude of beam.
 * @param colorArray[4]					colors of effect RGBA.
 * @param speed							speed of effect.
 * @param flags							Effect Flags.
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock BeamRingPoint(haloIndex, modelIndex, Float:center[3], Float:startRadius, Float:endRadius, frameRate, Float:lifeF, Float:widthF, Float:endWidthF, fadeLength, Float:amplitudeF, colorArray[4], speed, flags)
{
	TE_Start("BeamRingPoint");
	TE_WriteVector("m_vecCenter", center);
	TE_WriteFloat("m_flStartRadius", startRadius);
	TE_WriteFloat("m_flEndRadius", endRadius);
	TE_WriteNum("m_nModelIndex", modelIndex);
	TE_WriteNum("m_nHaloIndex", haloIndex);
	TE_WriteNum("m_nStartFrame", 0);
	TE_WriteNum("m_nFrameRate", frameRate);
	TE_WriteFloat("m_fLife", lifeF);
	TE_WriteFloat("m_fWidth", widthF);
	TE_WriteFloat("m_fEndWidth", endWidthF);
	TE_WriteNum("m_nFadeLength", fadeLength);
	TE_WriteFloat("m_fAmplitude", amplitudeF);
	TE_WriteNum("r", colorArray[0]);
	TE_WriteNum("g", colorArray[1]);
	TE_WriteNum("b", colorArray[2]);
	TE_WriteNum("a", colorArray[3]);
	TE_WriteNum("m_nSpeed", speed);
	TE_WriteNum("m_nFlags", flags);
	TE_SendToAll();
}

/*
 * BeamSpline
 * 
 * @param points						Number of points.
 * @param Float:effectVector1[3]		rgPoints (X,Y,Z).
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock BeamSpline(points, Float:effectVector1[3])
{    
    TE_Start("BeamSpline");
    TE_WriteNum("m_nPoints", points);
    TE_WriteVector("m_vecPoints", effectVector1);
}

/*
 * Blood Stream
 * 
 * @param Float:origin[3]			Origin of effect.
 * @param Float:direction[3]		Direction of effect.
 * @param colorArray[4]				Color of effect RGBA.
 * @param amount					Amount of streams.
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock BloodStream(Float:origin[3], Float:direction[3], colorArray[4], amount)
{    
    TE_Start("Blood Stream");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteVector("m_vecDirection", direction);
    TE_WriteNum("r", colorArray[0]);
	TE_WriteNum("g", colorArray[1]);
	TE_WriteNum("b", colorArray[2]);
	TE_WriteNum("a", colorArray[3]);
    TE_WriteNum("m_nAmount", amount);
    TE_SendToAll();
}

/*
 * Break Model
 * 
 * @param modelIndex				index of model.
 * @param Float:origin[3]			Origin of effect XYZ.
 * @param Float:angle[3]			angle of effect PYR.
 * @param Float:size[3]				size of effect XYZ.
 * @param Float:velocity[3]			Velocity of effect XYZ.
 * @param ran						Randomization.
 * @param count						Amount of streams.
 * @param Float:time				Length of effect.
 * @param flags						Effect Flags.
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock BreakModel(modelIndex, Float:origin[3], Float:angle[3], Float:size[3], Float:velocity[3], ran, count, Float:time, flags)
{    
    TE_Start("Break Model");
    TE_WriteVector("m_vecOrigin", origin);
    TE_WriteFloat("m_angRotation[0]", angle[0]);
    TE_WriteFloat("m_angRotation[1]", angle[1]);
    TE_WriteFloat("m_angRotation[2]", angle[2]);
    TE_WriteVector("m_vecSize", size);
    TE_WriteVector("m_vecVelocity", velocity);
    TE_WriteNum("m_nModelIndex", modelIndex);
    TE_WriteNum("m_nRandomization", ran);
    TE_WriteNum("m_nCount", count);
    TE_WriteFloat("m_fTime", time);
    TE_WriteNum("m_nFlags", flags);
    TE_SendToAll();
}

/*
 * BSP Decal
 * 
 * @param modelIndex			Decal to use.
 * @param Float:origin[3]		Origin of effect.
 * @param target				Target ent. 0 for world
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock Decal(modelIndex, Float:origin[3], target)
{
    TE_Start("BSP Decal");
    TE_WriteVector("m_vecOrigin", origin);
    TE_WriteNum("m_nEntity", target);
    TE_WriteNum("m_nIndex", modelIndex);
    TE_SendToAll();
}

/*
 * Bubbles
 * 
 * @param modelIndex			index of model.
 * @param Float:min[3]			Min bubbles XYZ.
 * @param Float:max[3]			Max bubbles XYZ.
 * @param Float:heightF			Height of effect.
 * @param count					Amount of bubbles.
 * @param Float:speedF			Speed of bubbles.
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock Bubbles(modelIndex, Float:min[3], Float:max[3], Float:heightF, count, Float:speedF)
{
    TE_Start("Bubbles");
    TE_WriteVector("m_vecMins", min);
    TE_WriteVector("m_vecMaxs", max);
    TE_WriteFloat("m_fHeight", heightF);
    TE_WriteNum("m_nModelIndex", modelIndex);
    TE_WriteNum("m_nCount", count);
    TE_WriteFloat("m_fSpeed", speedF);
    TE_SendToAll();
}

/*
 * Dynamic Light
 * 
 * @param Float:origin[3]		Origin of effect XYZ.
 * @param colorArray[3]			Color of effect RGB.
 * @param exponent				exponent.
 * @param Float:fRadius			Radius of Effect.
 * @param Float:fTime			Length of Effect.
 * @param Float:fDecay			Rate of Decay.
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock DynamicLight(Float:origin[3], colorArray[3], exponent, Float:fRadius, Float:fTime, Float:fDecay)
{
    TE_Start("Dynamic Light");
    TE_WriteVector("m_vecOrigin", origin);
    TE_WriteNum("r", colorArray[0]);
	TE_WriteNum("g", colorArray[1]);
	TE_WriteNum("b", colorArray[2]);
    TE_WriteNum("exponent", exponent);
    TE_WriteFloat("m_fRadius", fRadius);
    TE_WriteFloat("m_fTime", fTime);
    TE_WriteFloat("m_fDecay", fDecay);
    TE_SendToAll();
}

/*
 * Large Funnel
 * 
 * @param Float:origin[3]		Origin of effect XYZ.
 * @param modelIndex			index of model.
 * @param nReversed				Reversed?
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock LargeFunnel(Float:origin[3], modelIndex, nReversed)
{
    TE_Start("Large Funnel");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteNum("m_nModelIndex", modelIndex);
    TE_WriteNum("m_nReversed", nReversed);
    TE_SendToAll();
}




















/*
 * DRAW A VERTICAL CIRCLE
 * 
 * NOTE MUST PLACE OnMapStart_Circle() in OnMapStart of program to use
 *
 * @param Float:vecLocation[3]		Location of circle.
 * @param Float:radius				Radius of circle.
 */
stock Circle(Float:vecLocation[3], Float:radius)
{
    new Float:angle=0.0, Float:x, Float:y;
    
    new Float:pos1[3];
    new Float:pos2[3];
        
    //Create the start position for the first part of the beam
    pos2[0] = vecLocation[0];
    pos2[1] = vecLocation[1] + radius;
    pos2[2] = vecLocation[2];
    
    while (angle <= 2 * PI)
    {            
        x = radius * Cosine(angle);
        y = radius * Sine(angle);
        
        pos1[0] = vecLocation[0];
        pos1[1] = vecLocation[1] + x;
        pos1[2] = vecLocation[2] + y;

        TE_SetupBeamPoints(pos1, pos2, BeamSpriteCircle, HaloSpriteCircle, 0, 0, 8.0, Float:5.0, Float:5.0, 5, 0.0, {255,255,255,255}, 3);
        TE_SendToAll();
        
        pos2[0] = pos1[0];
        pos2[1] = pos1[1];
        pos2[2] = pos1[2];
        
        angle += 0.7;
    }
} 
 