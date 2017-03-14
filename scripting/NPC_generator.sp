/*  SM NPC Generator
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <npc_generator>

new gLeaderOffset;
new gCollisionOffset;
new Handle:kv = INVALID_HANDLE;

//#define DEBUG 1

#include "NPCs/BaseNPC.sp"
#include "NPCs/zombie.sp"
#include "NPCs/dog.sp"
#include "NPCs/barney.sp"
#include "NPCs/antlionguard.sp"
#include "NPCs/gman.sp"
#include "NPCs/headcrab.sp"


public Plugin:myinfo =
{
	name = "SM NPC Generator",
	author = "Franc1sco Steam: franug",
	description = "NPCs in CSS",
	version = "b0.1",
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	CreateConVar("sm_NPCGenerator", "b0.1", "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	gLeaderOffset = FindSendPropOffs("CHostage", "m_leader");
	
	HookEvent("hostage_hurt", OnHostageHurt, EventHookMode_Pre);
	HookEvent("hostage_follows", OnHostageFollows, EventHookMode_Pre);
	HookEvent("hostage_stops_following", OnHostageStopsFollowing, EventHookMode_Pre);
	HookEvent("hostage_killed", OnHostageKilled, EventHookMode_Pre);
	
	// Hook hostage-sound
	AddNormalSoundHook(NormalSHook:BaseNPC_HookHostageSound);
	
	gCollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup"); 
}

public OnMapStart()
{
	InitBaseNPC();
	InitZombie();
	InitDog();
	InitBarney();
	InitAntlionGuard();
	InitGMan();
	InitHeadCrab();
	
	kv = CreateKeyValues("NPCGenerator");
	decl String:file[256];
	BuildPath(Path_SM, file, sizeof(file), "configs/npcgenerator.cfg");
	if (!FileToKeyValues(kv, file))
	{
		CloseHandle(kv);
		
		LogError("%s NOT loaded! You NEED that file!", file);
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("NPC_CreateZombie", Native_Zombie);
	CreateNative("NPC_CreateDog", Native_Dog);
	CreateNative("NPC_CreateBarney", Native_Barney);
	CreateNative("NPC_CreateAntlionguard", Native_Atlionguard);
	CreateNative("NPC_CreateGman", Native_Gman);
	CreateNative("NPC_CreateHeadcrab", Native_Headcrab);
    
	return APLRes_Success;
}

public Native_Zombie(Handle:plugin, argc)
{    
	decl Float:posicion[3];
	GetNativeArray(1, posicion, 3);
	Zombie_Spawn(posicion);
	
}

public Native_Dog(Handle:plugin, argc)
{    
	decl Float:posicion[3];
	GetNativeArray(1, posicion, 3);
	Dog_Spawn(posicion);
	
}

public Native_Barney(Handle:plugin, argc)
{    
	decl Float:posicion[3];
	GetNativeArray(1, posicion, 3);
	Barney_Spawn(posicion);
	
}

public Native_Atlionguard(Handle:plugin, argc)
{    
	decl Float:posicion[3];
	GetNativeArray(1, posicion, 3);
	AntLionGuard_Spawn(posicion);
	
}

public Native_Gman(Handle:plugin, argc)
{    
	decl Float:posicion[3];
	GetNativeArray(1, posicion, 3);
	GMan_Spawn(posicion);
	
}

public Native_Headcrab(Handle:plugin, argc)
{    
	decl Float:posicion[3];
	GetNativeArray(1, posicion, 3);
	HeadCrab_Spawn(posicion);
	
}