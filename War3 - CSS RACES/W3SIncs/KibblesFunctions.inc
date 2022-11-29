/** Double-include prevention */
#if defined _kibbles_included_
  #endinput
#endif
#define _kibbles_included_

/**
 *
 * @param clientOne  Client ID for the first player
 * @param clientTwo  Client ID for the second player
 * @return           Bool value, true if same team
 */
stock bool:SameTeam(any:clientOne, any:clientTwo)
{
    if (GetClientTeam(clientOne) == GetClientTeam(clientTwo))
    {
        return true;
    }
    return false;
}
 
 /**
 *
 * @param clientOne  Client ID for the first player
 * @param clientTwo  Client ID for the second player
 * @return           Bool value, true if same race
 */
stock bool:SameRace(any:clientOne, any:clientTwo)
{
    if (War3_GetRace(playerOne) == War3_GetRace(playerTwo))
    {
        return true;
    }
    return false;
}
 
 /**
 * Checks a given position to see if a player will get stuck by teleporting.
 *
 * @param client  Client ID of player to be teleported
 * @param newPos  Position vector
 * @return        Bool value, true if safe position
 */
stock bool:SafeTeleportLocation(any:client, Float:newPos[3])
{
    new Float:emptyPos[3] = {0.0,0.0,0.0};

    new Float:mins[3];
    new Float:maxs[3];
    GetClientMins(client,mins);
    GetClientMaxs(client,maxs);
    
    new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};//,27,-27,30,-30,33,-33,40,-40}; //for human it needs to be smaller
    new absincarraysize=sizeof(absincarray);
    
    new limit=5000;
    for(new x=0;x<absincarraysize;x++){
        if(limit>0){
            for(new y=0;y<=x;y++){
                if(limit>0){
                    for(new z=0;z<=y;z++){
                        new Float:pos[3]={0.0,0.0,0.0};
                        AddVectors(pos,newPos,pos);
                        pos[0]+=float(absincarray[x]);
                        pos[1]+=float(absincarray[y]);
                        pos[2]+=float(absincarray[z]);
                        
                        TR_TraceHullFilter(pos,pos,mins,maxs,MASK_SOLID,CanHitThis,client);
                        //new ent;
                        if(!TR_DidHit(_))
                        {
                            AddVectors(emptyPos,pos,emptyPos); ///set this gloval variable
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
    
    if(GetVectorLength(emptyPos)<1.0)
    {
        return false;
        //it returned 0 0 0, no empty position found
    }
    return true;
}

stock bool:CanHitThis(entityhit, mask, any:data)
{
    if(entityhit == data )
    {
        return false; // Don't allow self to be hit, skip this result
    }
    return true; // It didn't hit itself
}

/**
 * Returns a directional vector based on where the client is looking.
 *
 * @param client  Client ID of player
 * @param vec     Vector array to store result in
 * @param scale   Scale to apply to the vector. Default 1.0 for a unit vector
 * @return        Bool value, true if vector has non-zero magnitude
 */
 
stock bool:GetDirVecFromEyes(any:client, Float:vec[3], Float:scale=1.0)
{
    new Float:angle[3];
    GetClientEyeAngles(client,angle);
    GetAngleVectors(angle, vec, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(vec, vec);
    ScaleVector(vec, scale);
    if (GetVectorLength(vec) == 0.0)
    {
        return false;
    }
    return true;
}
 

 /**
 * Returns a location vector based on where the client is looking.
 *
 * @param client      Client ID of player to be teleported
 * @param vec         Vector array to store result in
 * @param distance    Maximum distance from eyes. Leave default for infinite
 * @return            Bool value, true if completed successfully
 */
 new ClientTracer;
 
 stock bool:GetAimLocationFromEyes(any:client, Float:vec[3], Float:distance=9999.0)
 {
    new Float:angle[3];
    GetClientEyeAngles(client,angle);
    new Float:endpos[3];
    new Float:startpos[3];
    GetClientEyePosition(client,startpos);
    new Float:dir[3];
    GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(dir, distance);
    AddVectors(startpos, dir, endpos);
    TR_TraceRayFilter(startpos,endpos,MASK_ALL,RayType_EndPoint,AimTargetNoClientFilter);
    TR_GetEndPosition(endpos);
    
    return true;
}

public bool:AimTargetNoClientFilter(entity, mask)
{
    return !(entity==ClientTracer);
}

 /**
 * Checks if a player has leveled a skill.
 *
 * @param client                     Client ID of player to be teleported
 * @param raceID                     Race ID from War3Source
 * @param skillID                    SkillID from War3Source
 * @param printMessageIfNotLeveled   Bool value, prints message if true, defaults to false
 * @return                           Bool value, true if skill has been leveled
 */
bool:W3IsSkillLeveled(client, raceID, skillID, bool:printMessageIfNotLeveled=false)
{
    if (War3_GetSkillLevel(client, raceID, skillID) > 0)
    {
        return true;
    }
    if (printMessageIfNotLeveled)
    {
        PrintHintText(client, "Level this skill first");
    }
    return false;
}