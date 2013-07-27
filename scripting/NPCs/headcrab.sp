/* 
	------------------------------------------------------------------------------------------
	EntControl::AntLion
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

public InitHeadCrab()
{
	PrecacheModel("models/headcrabclassic.mdl");
	PrecacheSound("npc/headcrab/attack2.wav");
	PrecacheSound("npc/headcrab/idle1.wav");
	PrecacheSound("npc/headcrab/pain2.wav");
}


/* 
	------------------------------------------------------------------------------------------
	HeadCrab_Spawn
	------------------------------------------------------------------------------------------
*/
public HeadCrab_Spawn(Float:position[3])
{
	// Spawn
	new monster = BaseNPC_Spawn(position, "models/headcrabclassic.mdl", HeadCrabSeekThink, "npc_headcrab", "Idle01");

	SDKHook(monster, SDKHook_OnTakeDamage, HeadCrabDamageHook);
	
	SetEntData(monster, gCollisionOffset, 2, 4, true);
}

/* 
	------------------------------------------------------------------------------------------
	HeadCrabSeekThink
	------------------------------------------------------------------------------------------
*/
public Action:HeadCrabSeekThink(Handle:timer, any:monsterRef)
{
	new monster = EntRefToEntIndex(monsterRef);
	if(IsValidEntity(monster))
	{
		new target;
		decl Float:vClientPosition[3], Float:vEntPosition[3], Float:vAngle[3];
		
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		
		new owner = BaseNPC_GetOwner(monster);
		if (owner) // Attached to client ?
		{
			if (IsPlayerAlive(owner))
			{
				PrintHintText(owner, "HEADCRAB ATTACHED TO YOU! Shoot it!");
				
				BaseNPC_SetAnimation(monster, "headcrabbedpost");
				
				BaseNPC_HurtPlayer(monster, owner, 10);
				
				BaseNPC_PlaySound(monster, "npc/headcrab/attack2.wav"); 
			}
			else
			{
				AcceptEntityInput(monster, "ClearParent");
	
				BaseNPC_SetOwner(monster, 0);
				
				SetEntityMoveType(monster, MOVETYPE_STEP);
				
				TeleportEntity(monster, NULL_VECTOR, NULL_FLOAT_VECTOR, NULL_FLOAT_VECTOR);
			}
		}
		else
		{
			if (target > 0)
			{
				GetClientEyePosition(target, vClientPosition);
		
				if (GetVectorDistance(vClientPosition, vEntPosition, false) < 200.0)
				{
					BaseNPC_PlaySound(monster, "npc/headcrab/attack2.wav", 1.0);
					
					MakeVectorFromPoints(vEntPosition, vClientPosition, vAngle);
					GetVectorAngles(vAngle, vAngle);
					
					TeleportEntity(monster, NULL_VECTOR, vAngle, NULL_VECTOR);
					
					BaseNPC_SetAnimation(monster, "canal5b_sewer_jump");
					
					new Handle:data = CreateDataPack();
					WritePackCell(data, EntIndexToEntRef(monster));
					WritePackCell(data, EntIndexToEntRef(target));
					CreateTimer(0.5, HeadCrabAttachToClient, data);
					
					// SetEntityMoveType(target, MOVETYPE_NONE);
				}
				else
				{
					BaseNPC_SetAnimation(monster, "Run1");
				}
			}
			else
			{
				EmitSoundToAll("npc/headcrab/idle1.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vEntPosition);
				BaseNPC_SetAnimation(monster, "Idle01", 0.0, 1.0);
			}
		}

		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	HeadCrabAttachToClient
	------------------------------------------------------------------------------------------
*/
public Action:HeadCrabAttachToClient(Handle:timer, Handle:data)
{
	ResetPack(data);
	new monster = EntRefToEntIndex(ReadPackCell(data));
	new target = EntRefToEntIndex(ReadPackCell(data));
	CloseHandle(data);
	
	if (!IsValidEntity(monster)) {
		return;
	}
	if (!IsValidEntity(target)) {
		return;
	}
	/*
	decl String:entIndex[32];
	IntToString(target, entIndex, sizeof(entIndex)-1);
	
	Format(entIndex, sizeof(entIndex), "Client%d", target);
	DispatchKeyValue(target, "targetname", entIndex);
	
	DispatchKeyValue(monster, "parentname", entIndex);
	*/
	
	SetVariantString("!activator");
	AcceptEntityInput(monster, "SetParent", target, monster, 0);
	
	switch (GetRandomInt(0, 5))
	{
		case 0:
			SetVariantString("primary");
		case 1:
			SetVariantString("grenade0");
		case 2:
			SetVariantString("grenade3");
		case 3:
			SetVariantString("pistol");
		case 4:
			SetVariantString("lfoot");
		case 5:
			SetVariantString("rfoot");
		default:
			LogError("HeadCrab:HeadCrabAttachToClient -> Wrong Random");
	}
	
	
	//SetVariantString("primary");
	AcceptEntityInput(monster, "SetParentAttachment", monster, monster, 0);
	
	BaseNPC_SetOwner(monster, target);
	
	//SetEntityMoveType(target, MOVETYPE_WALK);
}
/* 
	------------------------------------------------------------------------------------------
	HeadCrabDamageHook
	------------------------------------------------------------------------------------------
*/
public Action:HeadCrabDamageHook(monster, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (BaseNPC_Hurt(monster, attacker, RoundToZero(damage), "npc/headcrab/pain2.wav"))
	{
		SDKUnhook(monster, SDKHook_OnTakeDamage, HeadCrabDamageHook);

		BaseNPC_Death(monster, attacker);
	}
	
	return (Plugin_Handled);
}