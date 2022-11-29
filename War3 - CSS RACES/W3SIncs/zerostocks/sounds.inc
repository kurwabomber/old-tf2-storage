/*
 * ZERO STOCKS SOUNDS v1.0.0
 * AWSOME STOCKS THAT DO SHIT RIGHT!
 * www.IBISGaming.com
 */

#if defined _zerostocks_sounds_included
  #endinput
#endif
#define _zerostocks_sounds_included

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <cstrike>
#include <smlib>

/*
 * SOUNDS
 */
new String:UltBlockSound[] = "common/wpn_denyselect.wav";

/*
 * Required to use UltBlockSound
 */
stock OnMapStart_UltBlockSound()
{
	War3_PrecacheSound( UltBlockSound );
}

/*
 * EMIT ULT BLOCK SOUND
 * 
 * NOTE REQUIRES OnMapStart_UltBlockSound() in OnMapStart()
 *
 */
stock ULTBLOCKSOUND(any:client)
{
	EmitSoundToClient(client, UltBlockSound);
}
 