class X2DownloadableContentInfo_DualWieldMelee extends X2DownloadableContentInfo config (DualWieldMelee);

struct SocketReplacementInfo
{
	var name TorsoName;
	var string SocketMeshString;
	var bool Female;
};

var config array<SocketReplacementInfo> SocketReplacements;

var config bool bHideSheaths;
var config bool bLog;

var config array<name> PatchMeleeAbilityBlackList;

static event OnPostTemplatesCreated()
{
	PatchMeleeWeaponTemplates();
}

static function MatineeGetPawnFromSaveData(XComUnitPawn UnitPawn, XComGameState_Unit UnitState, XComGameState SearchState)
{
	class'ShellMapMatinee'.static.PatchAllLoadedMatinees(UnitPawn, UnitState, SearchState);
}

static function UpdateWeaponAttachments(out array<WeaponAttachment> Attachments, XComGameState_Item ItemState)
{
	local XComGameState_Unit UnitState;
	local XComUnitPawn Pawn;
	local int i;
	local name NewSocket;
	local SkeletalMeshSocket Socket;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ItemState.OwnerStateObject.ObjectID));
	Pawn = XGUnit(UnitState.GetVisualizer()).GetPawn();

	if(!HasDualMeleeEquipped(UnitState))
	{
		return;
	}

	if(IsPrimaryMeleeWeaponTemplate(ItemState))
	{
		NewSocket = 'LeftSheath';
	}

	if(IsSecondaryMeleeWeaponTemplate(ItemState))
	{
		NewSocket = 'RightSheath';
	}

	if (NewSocket != '')
	{
		for (i = Attachments.Length; i >= 0; i--)
		{
			if (Attachments[i].AttachToPawn && Attachments[i].AttachSocket == 'Sheath')
			{
				Attachments[i].AttachSocket = NewSocket;
				Socket = Pawn.Mesh.GetSocketByName(NewSocket);
				if (Socket != none && NewSocket == 'LeftSheath')
				{
					Socket.RelativeLocation.X = 8.862213;
					Socket.RelativeLocation.Y = -13.456569;
					Socket.RelativeLocation.Z = 10.925175;

					Socket.RelativeRotation.Roll = int(90 * DegToUnrRot);
					Socket.RelativeRotation.Pitch = int(0 * DegToUnrRot);
					Socket.RelativeRotation.Yaw = int(40 * DegToUnrRot);
				}

				if (Socket != none && NewSocket == 'RightSheath')
				{
					Socket.RelativeLocation.X = 8.862213;
					Socket.RelativeLocation.Y = -13.456569;
					Socket.RelativeLocation.Z = -9.677606;

					Socket.RelativeRotation.Roll = int(90 * DegToUnrRot);
					Socket.RelativeRotation.Pitch = int(0 * DegToUnrRot);
					Socket.RelativeRotation.Yaw = int(40 * DegToUnrRot);
				}

				`LOG(GetFuncName() @ UnitState.GetFullName() @ Pawn @ ItemState.GetMyTemplateName() @ Attachments[i].AttachMeshName @ NewSocket, default.bLog, 'DualWieldMelee');
			}
		}
	}
}

static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{
	local int Index;

	// Associate all melee abilities with the primary weapon if dual melee weapons are equipped
	if (UnitState.IsSoldier() && HasDualMeleeEquipped(UnitState))
	{
		for(Index = 0; Index <= SetupData.Length; Index++)
		{
			if (SetupData[Index].Template != none && SetupData[Index].Template.IsMelee() &&  class'X2Ability_DualWieldMelee'.default.ABILITIES_DO_NOT_TRIGGER_SECONDARY_SLASH.Find(SetupData[Index].TemplateName) == INDEX_NONE)
			{
				SetupData[Index].SourceWeaponRef = UnitState.GetPrimaryWeapon().GetReference();
				`LOG(GetFuncName() @ UnitState.GetFullName() @ "setting" @ SetupData[Index].TemplateName @ "to" @ UnitState.GetPrimaryWeapon().GetMyTemplateName(), default.bLog, 'DualWieldMelee');
			}
		}
	}
}

static function WeaponInitialized(XGWeapon WeaponArchetype, XComWeapon Weapon, optional XComGameState_Item ItemState=none)
{
	local X2WeaponTemplate WeaponTemplate;
	local XComGameState_Unit UnitState;

	if (ItemState == none)
	{
		return;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ItemState.OwnerStateObject.ObjectID));
	WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());

	if(HasDualMeleeEquipped(UnitState))
	{
		`LOG(default.Class.Name @ GetFuncName() @ UnitState.GetFullName() @ "HasDualMeleeEquipped", default.bLog, 'DualWieldMelee');

		if(IsPrimaryMeleeWeaponTemplate(ItemState))
		{
			Weapon.DefaultSocket = 'R_Hand';
			`LOG(default.Class.Name @ GetFuncName() @ "Patching socket to R_Hand", default.bLog, 'DualWieldMelee');

			// Patching the sequence name from FF_MeleeA to FF_Melee to support random sets via prefixes A,B,C etc
			Weapon.WeaponFireAnimSequenceName = 'FF_Melee';
			Weapon.WeaponFireKillAnimSequenceName = 'FF_MeleeKill';
		}

		if(IsSecondaryMeleeWeaponTemplate(ItemState))
		{
			Weapon.DefaultSocket = 'L_Hand';
			`LOG(default.Class.Name @ GetFuncName() @ "Patching socket to L_Hand", default.bLog, 'DualWieldMelee');
		}

		if(WeaponTemplate.iRange == 0 && WeaponTemplate.WeaponCat != 'lightsaber')
		{
			Weapon.CustomUnitPawnAnimsets.Length = 0;
			Weapon.CustomUnitPawnAnimsetsFemale.Length = 0;
			Weapon.CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("DualSword.Anims.AS_Sword")));
			`LOG(default.Class.Name @ GetFuncName() @ "Adding DualSword.Anims.AS_Sword", default.bLog, 'DualWieldMelee');
		}
	}
}

static function string DLCAppendSockets(XComUnitPawn Pawn)
{
	//local SocketReplacementInfo SocketReplacement;
	//local name TorsoName;
	//local bool bIsFemale;
	//local string DefaultString, ReturnString;
	local XComHumanPawn HumanPawn;
	local XComGameState_Unit UnitState;

	//`LOG("DLCAppendSockets" @ Pawn, default.bLog, 'DualWieldMelee');

	HumanPawn = XComHumanPawn(Pawn);
	if (HumanPawn == none) { return ""; }

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(HumanPawn.ObjectID));

	if (HasDualMeleeEquipped(UnitState))
	{
		return "DualSword.Meshes.SM_Head_And_Sockets_M";
	}
	

	return "";
}

static function PatchMeleeWeaponTemplates()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> DifficultyVariants;
	local array<name> TemplateNames;
	local name TemplateName, AbilityName;
	local X2DataTemplate ItemTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local X2AbilityTemplate Ability;
	local X2DataTemplate AbilityDataTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2Effect_SecondarySlash_DamagePreview	DamagePreviewEffect;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	ItemTemplateManager.GetTemplateNames(TemplateNames);

	DamagePreviewEffect = new class'X2Effect_SecondarySlash_DamagePreview';
	DamagePreviewEffect.TargetConditions.AddItem(new class'X2Condition_DualMelee');

	foreach AbilityTemplateManager.IterateTemplates (AbilityDataTemplate, none)
	{
		Ability = X2AbilityTemplate(AbilityDataTemplate);
		if (Ability != none && Ability.IsMelee() && default.PatchMeleeAbilityBlackList.Find(Ability.DataName) == INDEX_NONE)
		{
			// Prevent inception
			if ( class'X2Ability_DualWieldMelee'.default.ABILITIES_DO_NOT_TRIGGER_SECONDARY_SLASH.Find(Ability.DataName) == INDEX_NONE)
			{
				Ability.PostActivationEvents.AddItem('DualSlashSecondary');

				Ability.bUniqueSource = true;
				Ability.AddTargetEffect(DamagePreviewEffect);
				//`Log(Ability.DataName @ "adding PostActivationEvents DualSlashSecondary", default.bLog, 'DualWieldMelee');
			}
		}

		if (Ability.DataName == 'Bladestorm')
		{
			Ability.AdditionalAbilities.AddItem('BladestormAttackDualMelee');
		}

		//if (Ability != none && Ability.bIsPassive)
		//{
		//	foreach Ability.AbilityTargetEffects(TargetEffect)
		//	{
		//		if (X2Effect_DualWeaponDamagePenalty(TargetEffect) == none)
		//		{
		//			TargetEffect.TargetConditions.AddItem(new class'X2Condition_NotSecondSlash');
		//		}
		//	}
		//}
	}

	foreach TemplateNames(TemplateName)
	{
		ItemTemplateManager.FindDataTemplateAllDifficulties(TemplateName, DifficultyVariants);
		// Iterate over all variants
		
		foreach DifficultyVariants(ItemTemplate)
		{
			WeaponTemplate = X2WeaponTemplate(ItemTemplate);

			if (WeaponTemplate == none)
				continue;

			if (IsMeleeWeaponTemplate(WeaponTemplate))
			{
				foreach WeaponTemplate.Abilities (AbilityName)
				{
					Ability = AbilityTemplateManager.FindAbilityTemplate(AbilityName);
					if (Ability != none && Ability.IsMelee())
					{
						Ability.bUniqueSource = true;
						//`Log(Ability.DataName $ ".bUniqueSource = true", default.bLog, 'DualWieldMelee');
					}
				}

				WeaponTemplate.Abilities.AddItem('DualMeleeDamageModifer');
			}
		}
	}
}

///
// Missing animations
// HL_PsiSustainStartA
// HL_Psi_MindControlledA
// HL_Shadowbind_Target
// HL_Shadowbind_TargetShadow
// HL_VoidConduitTarget_End
// HL_VoidConduitTarget_Loop
// HL_VoidConduitTarget_Start
// FF_SkulljackedLoopA
// FF_SkulljackedMissA
// FF_SkulljackedStartA
// FF_SkulljackedStopA
// FF_SkulljackerLoopA
// FF_SkulljackerMissA
// FF_SkulljackerStartA
// FF_SkulljackerStopA
// HL_BindHurtFrontA
static function UpdateAnimations(out array<AnimSet> CustomAnimSets, XComGameState_Unit UnitState, XComUnitPawn Pawn)
{
	if(!UnitState.IsSoldier())
	{
		return;
	}

	if (HasDualMeleeEquipped(UnitState))
	{
		CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("DualSword.Anims.AS_Soldier")));
	}
}



static function bool IsPrimaryMeleeWeaponTemplate(XComGameState_Item ItemState)
{
	local X2WeaponTemplate WeaponTemplate;

	WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());

	return WeaponTemplate != none &&
		ItemState.InventorySlot == eInvSlot_PrimaryWeapon && 
		IsMeleeWeaponTemplate(WeaponTemplate);
}

static function bool IsSecondaryMeleeWeaponTemplate(XComGameState_Item ItemState)
{
	local X2WeaponTemplate WeaponTemplate;

	WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());

	return WeaponTemplate != none &&
		ItemState.InventorySlot == eInvSlot_SecondaryWeapon && 
		IsMeleeWeaponTemplate(WeaponTemplate);
}

static function bool HasDualMeleeEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	if (UnitState == none || !UnitState.IsSoldier())
	{
		return false;
	}

	return IsPrimaryMeleeWeaponTemplate(UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState)) &&
		IsSecondaryMeleeWeaponTemplate(UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, CheckGameState));
}

static function bool IsMeleeWeaponTemplate(X2WeaponTemplate WeaponTemplate)
{
	return WeaponTemplate != none && WeaponTemplate.iRange == 0 &&
		class'X2Data_DualWieldMelee'.default.MeleeCategories.Find(WeaponTemplate.WeaponCat) != INDEX_NONE;
}


