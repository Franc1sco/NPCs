/* 
	------------------------------------------------------------------------------------------
	EntControl::BaseNPC
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

//#define DEBUG

//new gDebugBeam;
new gBlood1;
new gBloodDrop1;
new player; // Can be global ;)
new gNPCCount;
new gLastKilledNPC;

new fakeClient;

public InitBaseNPC()
{
	PrecacheModel("models/blackout.mdl");
	
	//gDebugBeam = PrecacheModel("materials/sprites/laser.vmt");
	gBlood1 = PrecacheModel("sprites/bloodspray.vmt");
	gBloodDrop1 = PrecacheModel("sprites/blood.vmt");
	
	
	#if defined DEBUG
		LogMessage("InitBaseNPC()");
	#endif
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_Spawn
	------------------------------------------------------------------------------------------
*/
stock BaseNPC_Spawn(Float:vEntPosition[3], String:model[128], Timer:func, String:classname[32] = "", String:idleAnimation[] = "idle")
{
	decl String:entIndex[6];
	new health;
	new Float:thinkrate, Float:friction;
	
	BaseNPC_LoadMonsterConfig(classname, thinkrate, friction, health);
	
	new monster = CreateEntityByName("hostage_entity");
	new monster_tmp = CreateEntityByName("prop_dynamic_ornament"); // prop_dynamic_ornament
	
	IntToString(monster_tmp, entIndex, sizeof(entIndex)-1);
	
	DispatchKeyValue(monster, "classname", classname);
	DispatchKeyValue(monster, "targetname", entIndex);
	DispatchKeyValue(monster, "disableshadows", "1");
	DispatchKeyValueFloat(monster, "friction", friction);
	DispatchSpawn(monster);
	
	SetEntProp(monster, Prop_Data, "m_iHealth", health);
	
	SetEntityModel(monster, "models/blackout.mdl");
	
	// Create the animated monster
	DispatchKeyValue(monster_tmp, "model", model);
	DispatchKeyValue(monster_tmp, "DefaultAnim", idleAnimation);
	DispatchKeyValue(monster_tmp, "spawnflags", "320");
	DispatchKeyValue(monster_tmp, "parent", entIndex);
	DispatchSpawn(monster_tmp);
	
	TeleportEntity(monster, vEntPosition, NULL_VECTOR, NULL_VECTOR);
	
	// Parent
	SetVariantString(entIndex);
	AcceptEntityInput(monster_tmp, "SetAttached");
	
	CreateTimer(thinkrate, func, monster, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.01, BaseNPC_Think, monster, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	SDKHook(monster, SDKHook_Touch, BaseNPC_Touch);
	
	gNPCCount++;
	
	#if defined DEBUG
		LogMessage("BaseNPC_Spawn(...,...,...,%s)::Spawn->NPCCount==%i", classname, gNPCCount);
	#endif
	
	return (monster);
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_SpawnByName
	------------------------------------------------------------------------------------------
*/
stock BaseNPC_SpawnByName(String:sNPCName[32], Float:vEntPosition[3])
{
	if (StrEqual(sNPCName, "npc_antlion"))
		AntLion_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_antlionguard"))
		AntLionGuard_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_barney"))
		Barney_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_gman"))
		GMan_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_headcrab"))
		HeadCrab_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_police"))
		Police_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_soldier"))
		Soldier_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_sentrygun"))
		Sentry_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_vortigaunt"))
		Vortigaunt_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_synth"))
		Synth_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_zombie"))
		Zombie_Spawn(vEntPosition);
	else
		Zombie_Spawn(vEntPosition);
}

stock RemoveEntity(entity, Float:time = 0.0)
{
	if (time == 0.0)
	{
		if(IsValidEntity(entity))
		{
			new String:edictname[32];
			GetEdictClassname(entity, edictname, 32);

			if (StrEqual(edictname, "player"))
				KickClient(entity); // HaHa =D
			else
				AcceptEntityInput(entity, "kill");
		}
	}
	else
	{
		CreateTimer(time, RemoveEntityTimer, entity, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:RemoveEntityTimer(Handle:Timer, any:entity)
{
	if(IsValidEntity(entity))
		AcceptEntityInput(entity, "kill"); // RemoveEdict(entity);
	
	return (Plugin_Stop);
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_IsNPC
	------------------------------------------------------------------------------------------
*/
stock bool:BaseNPC_IsNPC(monster)
{
	if (IsValidEdict(monster) && IsValidEntity(monster))
	{
		new String:edictname[32];
		GetEdictClassname(monster, edictname, 32);
		
		if (StrContains(edictname, "npc_") == 0)
			return (true);
	}
	
	return (false);
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_IsAlive
	------------------------------------------------------------------------------------------
*/
stock bool:BaseNPC_IsAlive(monster)
{
	return (GetEntProp(monster, Prop_Data, "m_iHealth") > 0);
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_GetTarget
	------------------------------------------------------------------------------------------
*/
stock BaseNPC_GetTarget(monster)
{
	return (GetEntDataEnt2(monster, gLeaderOffset));
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_Think
	------------------------------------------------------------------------------------------
*/
public Action:BaseNPC_Think(Handle:timer, any:monster)
{
	#if defined DEBUG
		LogMessage("BaseNPC_Think()::START");
	#endif
	if (BaseNPC_IsNPC(monster))
	{
		if (!BaseNPC_IsAlive(monster))
		{
			#if defined DEBUG
				LogMessage("BaseNPC_Think()::HARDSTOP");
			#endif
			
			BaseNPC_Death(monster);
			//RemoveEntity(monster);
			return (Plugin_Stop);
		}
		else
		{
			player = BaseNPC_GetTarget(monster);
			
			if (!player || !BaseNPC_CanSeeEachOther(monster, player))
			{
				new owner = BaseNPC_GetOwner(monster);
				if (owner == player) // Monster cannot go against his owner
					player = 0;
				
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
					{
						if(BaseNPC_CanSeeEachOther(monster, i))
						{
							if (i != owner)
							{
								SetEntDataEnt2(monster, gLeaderOffset, i);
							
								player = i;
							}
						}
					}
				}
			}
		}
	}
	else
	{
		#if defined DEBUG
			LogMessage("BaseNPC_Think()::TIMERSTOP");
		#endif
		
		return (Plugin_Stop);
	}
	
	#if defined DEBUG
		LogMessage("BaseNPC_Think()::REPEAT");
	#endif
	
	return (Plugin_Continue);
}

public bool:TraceEntityFilterWall(entity, contentsMask)
{
	return (entity == 1);
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_Touch
	------------------------------------------------------------------------------------------
*/
public Action:BaseNPC_Touch(entity, other)
{
	#if defined DEBUG
		LogMessage("BaseNPC_Touch()::START");
	#endif
	if (other)
	{
		new String:edictname[32];
		GetEdictClassname(other, edictname, 32);
		
		if (StrEqual("player", edictname))
		{
			#if defined DEBUG
				new String:sClientname[32];
				GetClientName(other, sClientname, 32);
				LogMessage("BaseNPC_Touch()::gLeaderOffset==%s", sClientname);
			#endif
			SetEntDataEnt2(entity, gLeaderOffset, other);
		}
	}

	#if defined DEBUG
		LogMessage("BaseNPC_Touch()::END");
	#endif
	
	return (Plugin_Continue);
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_Hurt
	------------------------------------------------------------------------------------------
*/
stock bool:BaseNPC_Hurt(monster, attacker, damage = 0, String:sound[32])
{
	#if defined DEBUG
		LogMessage("BaseNPC_Hurt()::");
		new String:sClientname[32], String:sEdictname[32];
		GetClientName(attacker, sClientname, 32);
		GetEdictClassname(monster, sEdictname, 32);
		LogMessage("monster==%s | gLeaderOffset==%s !!!", sEdictname, sClientname);
	#endif
	
	new health = GetEntProp(monster, Prop_Data, "m_iHealth") - damage;
	SetEntProp(monster, Prop_Data, "m_iHealth", health);
	
	new Float:vEntPosition[3], Float:vAngle[3];
	GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
	EmitSoundToAll(sound, monster, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vEntPosition);
	
	if (health <= 0)
	{
		#if defined DEBUG
			LogMessage("BaseNPC_Hurt()::END");
		#endif
		
		return (true);
	}

	decl String:tmp[32];
	GetEntPropString(monster, Prop_Data, "m_iName", tmp, sizeof(tmp));
	
	vEntPosition[2] += 70.0;
	
	vAngle[0] = GetRandomFloat(-10.0, 10.0);
	vAngle[1] = GetRandomFloat(-10.0, 10.0);
	vAngle[2] = GetRandomFloat(-10.0, 10.0);
	
	// Blood
	TE_SetupBloodSprite(vEntPosition, vAngle, {150, 150, 0, 255}, 5, gBlood1, gBloodDrop1);
	TE_SendToAll();
	TE_SetupBloodSprite(vEntPosition, vAngle, {150, 150, 0, 255}, 6, gBlood1, gBloodDrop1);
	TE_SendToAll();
	TE_SetupBloodSprite(vEntPosition, vAngle, {150, 100, 0, 255}, 7, gBlood1, gBloodDrop1);
	TE_SendToAll();
	TE_SetupBloodSprite(vEntPosition, vAngle, {150, 100, 0, 255}, 8, gBlood1, gBloodDrop1);
	TE_SendToAll();
	
	SetVariantString("BloodImpact");
	AcceptEntityInput(StringToInt(tmp), "DispatchEffect"); 
	
	SetVariantString("BloodImpact");
	AcceptEntityInput(StringToInt(tmp), "DispatchEffect"); 
	
	SetVariantString("BloodImpact");
	AcceptEntityInput(StringToInt(tmp), "DispatchEffect"); 
	
	SetVariantString("BloodImpact");
	AcceptEntityInput(StringToInt(tmp), "DispatchEffect"); 
	
	SetVariantString("BloodImpact");
	AcceptEntityInput(StringToInt(tmp), "DispatchEffect"); 
	
	new String:edictname[32];
	GetEdictClassname(attacker, edictname, 32);
	
	if (StrEqual(edictname, "player") && !GetEntDataEnt2(monster, gLeaderOffset))
		SetEntDataEnt2(monster, gLeaderOffset, attacker);
	
	#if defined DEBUG
		LogMessage("BaseNPC_Hurt()::END");
	#endif
	
	return (false);
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_Death
	------------------------------------------------------------------------------------------
*/
stock BaseNPC_Death(monster, attacker = 0, score = 1)
{
	#if defined DEBUG
		LogMessage("BaseNPC_Death()::START");
	#endif
	
	if (BaseNPC_IsNPC(monster) && monster != gLastKilledNPC)
	{ 
		//SetEntityMoveType(monster, MOVETYPE_VPHYSICS);
		
		//BaseNPC_Dissolve(monster);
		
		decl String:tmp[32];
		GetEntPropString(monster, Prop_Data, "m_iName", tmp, sizeof(tmp));
		new monster_tmp = StringToInt(tmp);
		AcceptEntityInput(monster_tmp, "BecomeRagdoll");
		RemoveEntity(monster, 1.0);
		
		gNPCCount--;
		gLastKilledNPC = monster;
		
		if (attacker && IsValidEntity(attacker) && IsValidEdict(attacker))
		{
			new String:monsterClassname[32], String:attackerClassname[32];
			GetEdictClassname(monster, monsterClassname, 32);
			GetEdictClassname(attacker, attackerClassname, 32);
			
			if (StrEqual(attackerClassname, "player") && IsClientConnected(attacker) && IsClientInGame(attacker))
			{
				SetEntProp(attacker, Prop_Data, "m_iFrags", GetClientFrags(attacker) + score);
				
				new money = GetEntProp(attacker, Prop_Send, "m_iAccount") + 1000 * score;
				if (money <= 16000)
					SetEntProp(attacker, Prop_Send, "m_iAccount", money);
				else
					SetEntProp(attacker, Prop_Send, "m_iAccount", 16000);
				
				decl String:playername[64];
				GetClientName(attacker, playername, 64);
				//SendKeyHintTextToAll("%s was killed by %s!\nAround %i NPC(s) left", monsterClassname, playername, gNPCCount);
			}
			/*else
			{
				if (monster == attacker)
					//SendKeyHintTextToAll("%s killed himself!\nAround %i NPC(s) left", monsterClassname, gNPCCount);
				else
					//SendKeyHintTextToAll("%s was killed by %s!\nAround %i NPC(s) left", monsterClassname, attackerClassname, gNPCCount);
			}*/
		}
	}
	#if defined DEBUG
	else
	{
		LogMessage("BaseNPC_Death()::'Is not NPC or was already killed'");
	}
	LogMessage("BaseNPC_Death()::STOP");
	#endif
	
	SDKUnhook(monster, SDKHook_Touch, BaseNPC_Touch);
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_SetAnimation
	------------------------------------------------------------------------------------------
*/
stock Action:BaseNPC_SetAnimation(monster, String:animation[32], Float:animtime = 0.0, Float:time = 0.0)
{
	#if defined DEBUG
		LogMessage("BaseNPC_SetAnimation()::START");
	#endif
	
	if (time == 0.0)
	{
		new String:edictname[32];
		GetEdictClassname(monster, edictname, 32);
		if (!IsValidEdict(monster) || !IsValidEntity(monster) || StrContains(edictname, "npc_") == -1)
		{
			LogError("LeGone-NPC-Bug");
			RemoveEntity(monster);
			return;
		}

		if (GetEntPropFloat(monster, Prop_Data, "m_flNextAttack") < GetGameTime())
		{
			decl String:tmp[32];
			GetEntPropString(monster, Prop_Data, "m_iName", tmp, sizeof(tmp));
			new monster_tmp = StringToInt(tmp);
		
			if (IsValidEdict(monster_tmp) && IsValidEntity(monster_tmp))
			{
				SetVariantString(animation);
				AcceptEntityInput(monster_tmp, "SetAnimation");
				
				BaseNPC_SetAnimationTime(monster, GetGameTime() + animtime);
			}
			else
			{
				LogMessage("BaseNPC_SetAnimation->monster_tmp==invalid?!Oo");
				RemoveEntity(monster);
			}
		}
	}
	else
	{
		new Handle:data = CreateDataPack();
		CreateTimer(time, BaseNPC_SetAnimation_Timer, data, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
		WritePackCell(data, monster);
		WritePackFloat(data, animtime);
		WritePackString(data, animation);
	}

	#if defined DEBUG
		LogMessage("BaseNPC_SetAnimation()::END");
	#endif
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_SetAnimation_Timer
	------------------------------------------------------------------------------------------
*/
public Action:BaseNPC_SetAnimation_Timer(Handle:timer, Handle:data)
{
	#if defined DEBUG
		LogMessage("BaseNPC_SetAnimation_Timer()::START");
	#endif
	ResetPack(data);
	
	new monster = ReadPackCell(data);
	new Float:animtime = ReadPackFloat(data);
	new String:animation[32];
	ReadPackString(data, animation, sizeof(animation));
	
	BaseNPC_SetAnimation(monster, animation, animtime);
	
	#if defined DEBUG
		LogMessage("BaseNPC_SetAnimation_Timer()::END");
	#endif
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_SetAnimationTime
	------------------------------------------------------------------------------------------
*/
stock Action:BaseNPC_SetAnimationTime(monster, Float:time = 0.0)
{
	#if defined DEBUG
		LogMessage("BaseNPC_SetAnimationTime(...)");
	#endif
	SetEntPropFloat(monster, Prop_Data, "m_flNextAttack", time);
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_GetOwner
	This will get the owner from the pedmode
	------------------------------------------------------------------------------------------
*/
stock BaseNPC_GetOwner(monster)
{
	return (GetEntProp(monster, Prop_Data, "m_iHammerID"));
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_SetOwner
	This will set the owner for the pedmode
	------------------------------------------------------------------------------------------
*/
stock BaseNPC_SetOwner(monster, owner)
{
	#if defined DEBUG
		LogMessage("BaseNPC_SetOwner(...)");
	#endif
	SetEntProp(monster, Prop_Data, "m_iHammerID", owner, 4);
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_CanSeeEachOther
	------------------------------------------------------------------------------------------
*/
stock bool:BaseNPC_CanSeeEachOther(monster, target, Float:distance = 0.0, Float:monsterheight = 50.0)
{
	if (IsValidEdict(target) && IsValidEntity(target) && IsClientConnected(target) && IsClientInGame(target) && IsPlayerAlive(target))
	{
		new Float:vMonsterPosition[3], Float:vTargetPosition[3];
		
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vMonsterPosition);
		vMonsterPosition[2] += monsterheight;
		
		GetClientEyePosition(target, vTargetPosition);
		
		if (distance == 0.0 || GetVectorDistance(vMonsterPosition, vTargetPosition, false) < distance)
		{
			new Handle:trace = TR_TraceRayFilterEx(vMonsterPosition, vTargetPosition, MASK_SOLID_BRUSHONLY, RayType_EndPoint, BaseNPC_TraceFilter);

			if(TR_DidHit(trace))
			{
				CloseHandle(trace);
				return (false);
			}
			
			CloseHandle(trace);

			return (true);
		}
	}
	return (false);
}

public bool:BaseNPC_TraceFilter(entity, contentsMask, any:data)
{
	//if( !entity || entity <= MaxClients || !IsValidEntity(entity) || entity == data) // dont let WORLD, or invalid entities be hit
	if(entity != data)
		return (false);

	return (true);
}

/* 
	------------------------------------------------------------------------------------------
	FindFirstTargetInRange
	------------------------------------------------------------------------------------------
*/
stock FindFirstTargetInRange(entity, Float:vAngle[3], Float:vEntPosition[3], Float:entHeight = 60.0)
{
	new Float:vClientPosition[3];
	
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vEntPosition);
	vEntPosition[2] += entHeight;
	
	new owner = BaseNPC_GetOwner(entity);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && owner != i)
		{
			GetClientEyePosition(i, vClientPosition);

			vClientPosition[2] -= 10.0;
			MakeVectorFromPoints(vEntPosition, vClientPosition, vAngle);
			vClientPosition[2] += 10.0;
			//NormalizeVector(vAngle, vAngle);
			GetVectorAngles(vAngle, vAngle);
			
			new Handle:trace = TR_TraceRayFilterEx(vEntPosition, vClientPosition, MASK_SHOT, RayType_EndPoint, TraceASDF, entity);
			if(!TR_DidHit(trace))
			{
				CloseHandle(trace);
				
				return (i);
			}
			CloseHandle(trace);
		}
	}
	
	return (-1);
}

/* 
	------------------------------------------------------------------------------------------
	IsTargetInRange
	------------------------------------------------------------------------------------------
*/
stock bool:IsTargetInRange(entity, client, Float:vAngle[3], Float:vEntPosition[3], Float:entHeight = 60.0)
{
	new Float:vClientPosition[3];
	
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vEntPosition);
	vEntPosition[2] += entHeight;
	if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{	
		GetClientEyePosition(client, vClientPosition);

		vClientPosition[2] -= 10.0;
		MakeVectorFromPoints(vEntPosition, vClientPosition, vAngle);
		vClientPosition[2] += 10.0;
		//NormalizeVector(vAngle, vAngle);
		GetVectorAngles(vAngle, vAngle);
		
		new Handle:trace = TR_TraceRayFilterEx(vEntPosition, vClientPosition, MASK_SHOT, RayType_EndPoint, TraceASDF, entity);
		if(!TR_DidHit(trace))
		{
			CloseHandle(trace);
			
			return (true);
		}
		
		CloseHandle(trace);
	}
	
	return (false);
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_Dissolve
	------------------------------------------------------------------------------------------
*/
public BaseNPC_Dissolve(monster)
{
	#if defined DEBUG
		LogMessage("BaseNPC_Dissolve(...)");
	#endif
	if (BaseNPC_IsNPC(monster))
	{
		decl String:tmp[32];
		GetEntPropString(monster, Prop_Data, "m_iName", tmp, sizeof(tmp));
		new monster_tmp = StringToInt(tmp);
		
		new ent = CreateEntityByName("env_entity_dissolver");
		if (ent > 0)
		{
			//DispatchKeyValue(ragdoll, "targetname", tmp);
			DispatchKeyValue(ent, "dissolvetype", "0");
			DispatchKeyValue(ent, "target", tmp);
			AcceptEntityInput(ent, "Dissolve");
			AcceptEntityInput(ent, "kill");
		}
		
		AcceptEntityInput(monster_tmp, "BecomeRagdoll");
		//AcceptEntityInput(monster, "Kill");
		
		RemoveEntity(monster, 10.0);
		//RemoveEntity(monster_tmp, 0.5);
	}
	#if defined DEBUG
	else
		LogMessage("BaseNPC_Dissolve(...)::BaseNPC_IsNPC(monster)==false");
	#endif
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_HurtPlayer
	------------------------------------------------------------------------------------------
*/
new Float:NULL_FLOAT_VECTOR[3] = {0.0, 0.0, 0.0};
stock BaseNPC_HurtPlayer(monster, target, damage, Float:range = 100.0, Float:vPunchangle[3] = NULL_FLOAT_VECTOR, Float:time = 0.0)
{
	if (time == 0.0)
	{
		#if defined DEBUG
			LogMessage("BaseNPC_HurtPlayer(...)::time==0.0");
		#endif
		if (BaseNPC_IsNPC(monster) && BaseNPC_IsAlive(monster) && target && IsValidEdict(target) && IsValidEntity(target) && IsClientConnected(target) && IsClientInGame(target) && IsPlayerAlive(target))
		{
			decl Float:vClientPosition[3], Float:vEntPosition[3];
			
			GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
			GetClientEyePosition(target, vClientPosition);
			
			if ((GetVectorDistance(vClientPosition, vEntPosition, false) < range) && BaseNPC_CanSeeEachOther(monster, target))
			{
				MakeDamage(fakeClient, target, damage, DMG_ACID, 1.0, NULL_FLOAT_VECTOR);
				
				if (vPunchangle[0] != 0.0 || vPunchangle[1] != 0.0 || vPunchangle[2] != 0.0 )
					SetEntPropVector(target, Prop_Send, "m_vecPunchAngle", vPunchangle);
			}
		}
	}
	else
	{
		#if defined DEBUG
			LogMessage("BaseNPC_HurtPlayer(...)::time==%f", time);
		#endif
		
		new Handle:data = CreateDataPack();
		CreateTimer(time, BaseNPC_HurtPlayer_Timer, data, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
		WritePackCell(data, monster);
		WritePackCell(data, target);
		WritePackCell(data, damage);
		WritePackFloat(data, range);
		WritePackFloat(data, vPunchangle[0]);
		WritePackFloat(data, vPunchangle[1]);
		WritePackFloat(data, vPunchangle[2]);
	}
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_HurtPlayer_Timer
	------------------------------------------------------------------------------------------
*/
public Action:BaseNPC_HurtPlayer_Timer(Handle:timer, Handle:data)
{
	ResetPack(data);
	new monster = ReadPackCell(data);
	new target = ReadPackCell(data);
	new damage = ReadPackCell(data);
	new Float:range = ReadPackFloat(data);
	
	new Float:vPunchangle[3];
	vPunchangle[0] = ReadPackFloat(data);
	vPunchangle[1] = ReadPackFloat(data);
	vPunchangle[2] = ReadPackFloat(data);
	
	BaseNPC_HurtPlayer(monster, target, damage, range, vPunchangle);
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_PlaySound
	------------------------------------------------------------------------------------------
*/
stock BaseNPC_PlaySound(monster, String:sound[], Float:time = 0.0)
{
	if (BaseNPC_IsNPC(monster))
	{
		if (time == 0.0)
		{
			#if defined DEBUG
				LogMessage("BaseNPC_PlaySound(...)::time==0.0");
			#endif
			
			new Float:vEntPosition[3];
			GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
			EmitSoundToAll(sound, 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vEntPosition);
		}
		else
		{
			#if defined DEBUG
				LogMessage("BaseNPC_PlaySound(...)::time==%f", time);
			#endif
			
			new Handle:data = CreateDataPack();
			CreateTimer(time, BaseNPC_PlaySound_Timer, data, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
			WritePackCell(data, monster);
			WritePackString(data, sound);
		}
	}
	#if defined DEBUG
	else
	LogMessage("BaseNPC_PlaySound(...)::BaseNPC_IsNPC(monster)==false");
	#endif
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_PlaySound_Timer
	------------------------------------------------------------------------------------------
*/
public Action:BaseNPC_PlaySound_Timer(Handle:timer, Handle:data)
{
	ResetPack(data);
	
	new monster = ReadPackCell(data);
	new String:sound[32];
	ReadPackString(data, sound, sizeof(sound));
	
	BaseNPC_PlaySound(monster, sound);
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_LoadMonsterConfig
	------------------------------------------------------------------------------------------
*/
stock BaseNPC_LoadMonsterConfig(String:monstername[32], &Float:thinkrate, &Float:friction, &health)
{
	if (!KvJumpToKey(kv, "NPCs") || !KvGotoFirstSubKey(kv, false))
	{
		LogError("Monster-Config not loaded!");
	}
	else
	{
		decl String:sectionName[32];
		do
		{
			KvGetSectionName(kv, sectionName, sizeof(sectionName));

			if (StrEqual(sectionName, monstername))
			{
				thinkrate = KvGetFloat(kv, "thinkrate", 2.0);
				health = KvGetNum(kv, "health", 100);
				friction = KvGetFloat(kv, "friction", 1.0);
				
				break;
			}
		} while (KvGotoNextKey(kv, false));

		KvRewind(kv);
	}
}

public Action:BaseNPC_HookHostageSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	new String:edictname[32];
	GetEdictClassname(entity, edictname, 32);
	if (StrContains(edictname, "npc_") != -1)
		return (Plugin_Stop);
	
	return (Plugin_Continue);
}

public Action:OnHostageHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	return (Plugin_Handled);
}

public Action:OnHostageFollows(Handle:event, const String:name[], bool:dontBroadcast)
{
	return (Plugin_Handled);
}

public Action:OnHostageStopsFollowing(Handle:event, const String:name[], bool:dontBroadcast)
{
	// new monster = GetEventInt(event, "hostage");
	
	return (Plugin_Handled);
}

public Action:OnHostageKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	return (Plugin_Handled);
}

stock bool:MakeDamage(client, target, damage, damagetype, Float:damageradius, const Float:attackposition[3], const String:weaponname[] = "", bool:kill=true)
{
	new pointhurt = CreateEntityByName("point_hurt");
	
	if(pointhurt != -1)
	{
		if(target != -1)
		{
			decl String:targetname[64];
			Format(targetname, 128, "%f%f", GetEngineTime(), GetRandomFloat());
			DispatchKeyValue(target, "TargetName", targetname);
			DispatchKeyValue(pointhurt, "DamageTarget", targetname);
		}
		else
			DispatchKeyValue(pointhurt, "DamageTarget", "");

		DispatchKeyValueVector(pointhurt, "Origin", attackposition);
		
		decl String:number[64];
		IntToString(damage, number, 64);
		DispatchKeyValue(pointhurt,"Damage", number);
		
		IntToString(damagetype, number, 64);
		DispatchKeyValue(pointhurt,"DamageType", number);
		
		DispatchKeyValueFloat(pointhurt, "DamageRadius", damageradius);
		
		if(!StrEqual(weaponname, "", false))
			DispatchKeyValue(pointhurt,"classname", weaponname);
		
		DispatchSpawn(pointhurt);
		
		if(client)
			AcceptEntityInput(pointhurt, "Hurt", client);
		else
			AcceptEntityInput(pointhurt, "Hurt", 0);
		
		if (kill)
			AcceptEntityInput(pointhurt, "Kill");
		
		return (true);
	}
	else
		return (false);
}