/** Double-include prevention */
#if defined _npcgenerator_included_
  #endinput
#endif
#define _npcgenerator_included_

/**
 * Create a NPC.
 *
 * @param position     Position when NPC will appear
 * @noreturn          
 */
native NPC_CreateZombie(Float:position[3]);

native NPC_CreateDog(Float:position[3]);

native NPC_CreateGman(Float:position[3]);

native NPC_CreateBarney(Float:position[3]);

native NPC_CreateAntlionguard(Float:position[3]);

native NPC_CreateHeadcrab(Float:position[3]);