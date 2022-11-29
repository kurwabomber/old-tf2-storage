/*
 * ZERO STOCKS EFFECTS v1.0.0
 * AWSOME STOCKS THAT DO SHIT RIGHT!
 * www.IBISGaming.com
 */

#if defined _zerostocks_est_effects_included
  #endinput
#endif
#define _zerostocks_est_effects_included

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <cstrike>
#include <smlib>


/*
 * est_Effect_01 <player Filter> <delay> <position 'X,Y,Z'> <direction 'X,Y,Z'>
 * 
 * @param position		Location of Effect XYZ.
 * @param direction		Direction of Effect XYZ.
 * 
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock est_Effect_01(Float:position[3], Float:direction[3])
{
	TE_SetupArmorRicochet(position, direction);
	TE_SendToAll();
}

/* 
 * SAME AS ABOVE
 * est_Effect 1 <player Filter> <delay> <position 'X,Y,Z'> <direction 'X,Y,Z'>
 * 
 * @param position		Location of Effect XYZ.
 * @param direction		Direction of Effect XYZ.
 * 
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock est_Effect1(Float:position[3], Float:direction[3])
{
	TE_SetupArmorRicochet(position, direction);
	TE_SendToAll();
}

/* 
 * est_Effect_02 <player Filter> <delay> <model> <start ent> <start position 'X,Y,Z'> <end ent> <end position 'X,Y,Z'> <framerate> <life> <start width> <end width> <fade distance> <amplitude> <R> <G> <B> <A> <speed>
 * 
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
stock est_Effect_02(modelIndex, startEntity, Float:startposition[3], endEntity, Float:endposition[3], frameRate, Float:lifeF, Float:widthF, Float:endWidthF, fadeLength, Float:amplitudeF, colorArray[4], speed)
{
	BeamEntPoint(0, modelIndex, startEntity, startposition, endEntity, endposition, frameRate, lifeF, widthF, endWidthF, fadeLength, amplitudeF, colorArray, speed);
}

/* 
 * est_Effect_03 <player Filter> <delay> <model> <start ent> <end ent> <framerate> <life> <start width> <end width> <fade distance> <amplitude> <R> <G> <B> <A> <speed>
 * 
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
stock est_Effect_03(modelIndex, startEntity, endEntity, frameRate, Float:lifeF, Float:widthF, Float:endWidthF, fadeLength, Float:amplitudeF, colorArray[4], speed)
{
	BeamEnts(0, modelIndex, startEntity, endEntity, frameRate, lifeF, widthF, endWidthF, fadeLength, amplitudeF, colorArray, speed);
}

/*
 * est_Effect 3 <player Filter> <delay> <model> (start <X> <Y> <Z>) (end <X> <Y> <Z>) <life> <width> <end width> <Red> <Green> <Blue> <Alpha>
 * 
 * @param modelIndex					Precached model index.
 * @param Float:startposition[3]		Start position of the beam.
 * @param Float:endposition[3]			End position of the beam.
 * @param Float:lifeF					Time duration of the beam.
 * @param Float:widthF					Initial beam width.
 * @param Float:endWidthF				Final beam width.
 * @param colorArray[4]					Color array (r, g, b, a).
 * 
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock est_Effect3(modelIndex, Float:startposition[3], Float:endposition[3], Float:lifeF, Float:widthF, Float:endWidthF, colorArray[4])
{
	TE_SetupBeamPoints(startposition, endposition, modelIndex, 0, 0, 0, lifeF, widthF, endWidthF, 0, 0.0, colorArray, 0);
	TE_SendToAll();
}
/*
 * est_Effect_04 <player Filter> <delay> <model> <Follow ent> <life> <start width> <end width> <fade distance> <R> <G> <B> <A>
 * 
 * @param modelIndex			Precached model index.
 * @param entity				Entity index from where the beam starts (or follows).
 * @param Float:lifeF			Time duration of the beam.
 * @param Float:widthF			Initial beam width.
 * @param Float:endWidthF		Final beam width.
 * @param fadeLength			Fade distance of effect.
 * @param colorArray[4]			Color array (r, g, b, a).
 * 
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock est_Effect_04(modelIndex, entity, Float:lifeF, Float:widthF, Float:endWidthF, fadeLength, colorArray[4])
{
	TE_SetupBeamFollow(entity, modelIndex, 0, lifeF, widthF, endWidthF, fadeLength, colorArray);
	TE_SendToAll();
}

/*
 * est_Effect 4 <player Filter> <delay> <model> <userid> <life> <width> <end width> <time to fade> <Red> <Green> <Blue> <Alpha>
 * 
 * @param modelIndex			Precached model index.
 * @param entity				Entity index from where the beam starts (or follows).
 * @param Float:lifeF			Time duration of the beam.
 * @param Float:widthF			Initial beam width.
 * @param Float:endWidthF		Final beam width.
 * @param fadeLength			Fade distance of effect.
 * @param colorArray[4]			Color array (r, g, b, a).
 * 
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock est_Effect4(modelIndex, entity, Float:lifeF, Float:widthF, Float:endWidthF, fadeLength, colorArray[4])
{
	TE_SetupBeamFollow(entity, modelIndex, 0, lifeF, widthF, endWidthF, fadeLength, colorArray);
	TE_SendToAll();
}

/*
 * est_effect_05 <player Filter> <delay> <model> <start ent> <end ent> <framerate> <life> <start width> <end width> <fade distance> <amplitude> <R> <G> <B> <A> <speed>
 * 
 * @param modelIndex			Precached model index.
 * @param startEntity			Entity index from where the beam starts.
 * @param endEntity				Entity index from where the beam ends.
 * @param frameRate				FPS.
 * @param Float:lifeF			Time duration of the beam.
 * @param Float:widthF			Initial beam width.
 * @param Float:endWidthF		Final beam width.
 * @param fadeLength			Fade distance of effect.
 * @param colorArray[4]			Color array (r, g, b, a).
 * @param speed					speed of effect.
 * 
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock est_Effect_05(modelIndex, startEntity, endEntity, frameRate, Float:lifeF, Float:widthF, Float:endWidthF, FadeLength, Float:amplitudeF, colorArray[4], speed)
{
	TE_SetupBeamLaser(startEntity, endEntity, modelIndex, 0, 0, frameRate, lifeF, widthF, endWidthF, fadeLength, amplitudeF, colorArray, speed);
	TE_SendToAll();
}

/*
 * est_Effect_06 <player Filter> <delay> <model> <start position 'X,Y,Z'> <end position 'X,Y,Z'> <framerate> <life> <start width> <end width> <fade distance> <amplitude> <R> <G> <B> <A> <speed>
 * 
 * @param modelIndex					Precached model index.
 * @param Float:startposition[3]		Start position of the beam.
 * @param Float:endposition[3]			End position of the beam.
 * @param frameRate						FPS.
 * @param Float:lifeF					Time duration of the beam.
 * @param Float:widthF					Initial beam width.
 * @param Float:endWidthF				Final beam width.
 * @param fadeLength					Fade distance of effect.
 * @param Float:amplitudeF				Amplitude of effect.
 * @param colorArray[4]					Color array (r, g, b, a).
 * @param speed							speed of effect.
 * 
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock est_Effect_06(modelIndex, Float:startposition[3], Float:endposition[3], frameRate, Float:lifeF, Float:widthF, Float:endWidthF, FadeLength, Float:amplitudeF, colorArray[4], speed)
{
	TE_SetupBeamPoints(startposition, endposition, modelIndex, 0, 0, frameRate, lifeF, widthF, endWidthF, FadeLength, amplitudeF, colorArray, speed);
	TE_SendToAll();
}

/* 
 * est_Effect_07 <player Filter> <delay> <model> <start ent> <end ent> <framerate> <life> <width> <spread> <amplitude> <R> <G> <B> <A> <speed>
 * 
 * NOTE THAT SPREAD IS IGNORED
 *
 * @param modelIndex					index of model.
 * @param startEntity					Ent to start effect at.
 * @param endEntity						Ent to end effect at.
 * @param frameRate						fps.
 * @param Float:lifeF					length of effect duration.
 * @param Float:widthF					Starting width.
 * @param fadeLength					fade distance of effect.
 * @param Float:amplitudeF				amplitude of beam.
 * @param colorArray[4]					colors of effect RGBA.
 * @param speed							speed of effect.
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock est_Effect_07(modelIndex, startEntity, endEntity, frameRate, Float:lifeF, Float:widthF, fadeLength, Float:amplitudeF, colorArray[4], speed)
{
	BeamRing(0, modelIndex, startEntity, endEntity, frameRate, lifeF, widthF, widthF, fadeLength, amplitudeF, colorArray, speed);
}

/* 
 * est_Effect 7 <player Filter> <delay> <model> <x> <y> <z> <scale> <framerate>
 * 
 * NOTE THAT MODEL IS IGNORED
 *
 * @param modelIndex			index of model.
 * @param Float:origin[3]		Origin of effect XYZ.
 * @param Float:scaleF			Size of effect.
 * @param frameRate				FPS of effect.
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock est_Effect7(modelIndex, Float:origin[3], Float:scaleF, frameRate)
{
	TE_SetupSmoke(origin, modelIndex, scaleF, frameRate);
	TE_SendToAll();
}

/* 
 * est_Effect_08 <player Filter> <delay> <model> <center 'X,Y,Z'> <Start Radius> <End Radius> <framerate> <life> <width> <spread> <amplitude> <R> <G> <B> <A> <speed> <flags>
 * 
 * NOTE THAT SPREAD IS IGNORED
 *
 * @param modelIndex					index of model.
 * @param Float:center[3]				Center of Ring.
 * @param startRadius					Radius to start effect at.
 * @param endRadius						Radius to end effect at.
 * @param frameRate						fps.
 * @param Float:lifeF					length of effect duration.
 * @param Float:widthF					Width.
 * @param fadeLength					fade distance of effect.
 * @param Float:amplitudeF				amplitude of beam.
 * @param colorArray[4]					colors of effect RGBA.
 * @param speed							speed of effect.
 * @param flags							Effect Flags.
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock est_Effect_08(modelIndex, Float:center[3], startRadius, endRadius, frameRate, Float:lifeF, Float:widthF, fadeLength, Float:amplitudeF, colorArray[4], speed, flags)
{
	BeamRingPoint(0, modelIndex, center, startRadius, endRadius, frameRate, lifeF, widthF, widthF, fadeLength, amplitudeF, colorArray, speed, flags);
}

/* 
 * est_Effect_09 <player Filter> <delay> <model> <points> <rgPoints 'X,Y,Z'>
 * 
 * NOTE THAT MODEL IS IGNORED
 *
 * @param points						Number of points.
 * @param Float:effectVector1[3]		rgPoints (X,Y,Z).
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock est_Effect_09(points, Float:effectVector1[3])
{
	BeamSpline(points, effectVector1);
}

/*
 * est_Effect_10 <player Filter> <delay> <origin 'X,Y,Z'> <direction 'X,Y,Z'> <R> <G> <B> <A> <Size>
 * 
 * @param position				Location of Effect XYZ.
 * @param direction				Direction of Effect XYZ.
 * @param colorArray[4]			colors of effect RGBA.
 * @param size					size of effect.
 * 
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock est_Effect_10(Float:position[3], Float:direction[3], colorArray[4], size)
{
	TE_SetupBloodSprite(position, direction, colorArray, size, 0, 0);
	TE_SendToAll();
}

/* 
 * est_Effect 10 <player Filter> <delay> <model> <x> <y> <z> <start radius> <end radius> <life> <width> <spread> <amplitude> <Red> <Green> <Blue> <Alpha> <speed>
 * 
 * NOTE THAT SPREAD IS IGNORED
 *
 * @param modelIndex					index of model.
 * @param Float:center[3]				Center of Ring.
 * @param startRadius					Radius to start effect at.
 * @param endRadius						Radius to end effect at.
 * @param Float:lifeF					length of effect duration.
 * @param Float:widthF					Width.
 * @param fadeLength					fade distance of effect.
 * @param Float:amplitudeF				amplitude of beam.
 * @param colorArray[4]					colors of effect RGBA.
 * @param speed							speed of effect.
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock est_Effect10(modelIndex, Float:center[3], Float:startRadius, Float:endRadius, Float:lifeF, Float:widthF, fadeLength, Float:amplitudeF, colorArray[4], speed)
{
	BeamRingPoint(0, modelIndex, center, startRadius, endRadius, 0, lifeF, widthF, widthF, fadeLength, amplitudeF, colorArray, speed, 0);
}

/*
 * est_Effect_11 <player Filter> <delay> <origin 'X,Y,Z'> <direction 'X,Y,Z'> <R> <G> <B> <A> <Amount>
 * 
 * @param Float:origin[3]			Origin of effect.
 * @param Float:direction[3]		Direction of effect.
 * @param colorArray[4]				Color of effect RBGA.
 * @param amount					Amount of streams.
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock est_Effect_11(Float:origin[3], Float:direction[3], colorArray[4], amount)
{
	BloodStream(origin, direction, colorArray, amount);
}

/*
 * est_Effect 11 <player Filter> <delay> <model> <x> <y> <z> <life> <size> <brightness>
 * 
 * @param modelIndex				index of model.
 * @param Float:origin[3]			Origin of effect.
 * @param Float:lifeF				Length of effect duration.
 * @param Float:sizeF				Size of effect.
 * @param brightness				Brightness of effect.
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock est_Effect11(modelIndex, Float:origin[3], Float:lifeF, Float:sizeF, brightness)
{
	TE_SetupGlowSprite(origin, modelIndex, lifeF, sizeF, brightness);
	TE_SendToAll();
}

/*
 * est_Effect_12 <player Filter> <delay> <model> <origin 'X,Y,Z'> <angle 'Pitch,Yaw,Roll'> <Size 'X,Y,Z'> <Velocity 'X,Y,Z'> <Randomization> <count> <time> <flags>
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
stock est_Effect_12(modelIndex, Float:origin[3], Float:angle[3], Float:size[3], Float:velocity[3], ran, count, Float:time, flags)
{
	BreakModel(modelIndex, origin[3], angle[3], size[3], velocity, ran, count, time, flags);
}

/*
 * est_Effect_13 <player Filter> <delay> <decal> <origin 'X,Y,Z'> <target entity index>
 * 
 * @param modelIndex			Decal to use.
 * @param Float:origin[3]		Origin of effect.
 * @param target				Target ent. 0 for world
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock est_Effect_13(modelIndex, Float:origin[3], target)
{
	Decal(modelIndex, origin, target);
}

/*
 * est_Effect_14 <player Filter> <delay> <model> <Min 'X,Y,Z'> <Max 'X,Y,Z'> <heigth> <count> <speed>
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
stock est_Effect_14(modelIndex, Float:min[3], Float:max[3], Float:heightF, count, Float:speedF)
{
	Bubbles(modelIndex, min, max, heightF, count, speedF);
}

/*
 * est_Effect_18 <player Filter> <delay> <Position 'X,Y,Z'> <R> <G> <B> <exponent> <radius> <time> <decay>
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
stock est_Effect_18(Float:origin[3], colorArray[3], exponent, Float:fRadius, Float:fTime, Float:fDecay)
{
	DynamicLight(origin, colorArray, exponent, fRadius, fTime, fDecay);
}

/*
 * est_Effect_24 <player Filter> <delay> <model> <Position 'X,Y,Z'> <reversed>
 * 
 * @param modelIndex			index of model.
 * @param Float:origin[3]		Origin of effect XYZ.
 * @param nReversed				Reversed?
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock est_Effect_24(modelIndex, Float:origin[3], nReversed)
{
	DynamicLight(origin, modelIndex, nReversed);
}

/*
 * est_Effect_32 <Player Filter> <Delay> <Position "X Y Z"> <Magnitude> <Trail Length> <Direction "X Y Z">
 * 
 * @param Float:origin[3]		Origin of effect XYZ.
 * @param Magnitude				Sparks size.
 * @param TrailLength			Trail lenght of the sparks.
 * @param Float:dir[3]			Direction of the sparks.
 *
 * Requires TE_SendToAll() or TE_Send() or TE_SendToClient() to render
 */
stock est_Effect_32(Float:origin[3], Magnitude, TrailLength, Float:dir[3])
{
	TE_SetupSparks(origin, dir, Magnitude, TrailLength);
	TE_SendToAll();
}

