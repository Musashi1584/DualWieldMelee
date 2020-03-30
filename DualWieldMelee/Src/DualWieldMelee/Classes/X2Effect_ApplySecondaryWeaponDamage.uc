class X2Effect_ApplySecondaryWeaponDamage extends X2Effect_ApplyWeaponDamage;

simulated function GetDamagePreview(StateObjectReference TargetRef, XComGameState_Ability AbilityState, bool bAsPrimaryTarget, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	local int /*DamageAmount, */Index, BonusDamageToRemove;
	//local XComGameStateHistory History;
	//local XComGameState_Unit kSourceUnit;
	//local XComGameState_Effect DualWeaponDamagePenaltyEffect;

	super.GetDamagePreview(TargetRef, AbilityState, bAsPrimaryTarget, MinDamagePreview, MaxDamagePreview, AllowsShield);

	//History = `XCOMHISTORY;
	//kSourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));

	//DualWeaponDamagePenaltyEffect = kSourceUnit.GetUnitAffectedByEffectState('DualWeaponDamagePenalty');

	//`LOG(default.Class @ GetFuncName() @ MinDamagePreview.BonusDamageInfo.Length,, 'DualWieldMelee');

	for (Index = MinDamagePreview.BonusDamageInfo.Length - 1; Index >= 0; Index--)
	{
		//`LOG(default.Class @ GetFuncName() @ MinDamagePreview.BonusDamageInfo[Index].SourceEffectRef.SourceTemplateName,, 'DualWieldMelee');
		if (MinDamagePreview.BonusDamageInfo[Index].SourceEffectRef.SourceTemplateName != 'DualMeleeDamageModifer')
		{
			BonusDamageToRemove += MinDamagePreview.BonusDamageInfo[Index].Value;
			MinDamagePreview.BonusDamageInfo.Remove(Index, 1);
		}
	}
	MinDamagePreview.Damage -= BonusDamageToRemove;

	BonusDamageToRemove = 0;
	for (Index = MaxDamagePreview.BonusDamageInfo.Length - 1; Index >= 0; Index--)
	{
		//`LOG(default.Class @ GetFuncName() @ MaxDamagePreview.BonusDamageInfo[Index].SourceEffectRef.SourceTemplateName,, 'DualWieldMelee');
		if (MaxDamagePreview.BonusDamageInfo[Index].SourceEffectRef.SourceTemplateName != 'DualMeleeDamageModifer')
		{
			BonusDamageToRemove += MaxDamagePreview.BonusDamageInfo[Index].Value;
			MinDamagePreview.BonusDamageInfo.Remove(Index, 1);
		}
	}

	MaxDamagePreview.Damage -= BonusDamageToRemove;
}

simulated function int CalculateDamageAmount(const out EffectAppliedData ApplyEffectParameters, out int ArmorMitigation, out int NewRupture, out int NewShred, out array<Name> AppliedDamageTypes, out int bAmmoIgnoresShields, out int bFullyImmune, out array<DamageModifierInfo> SpecialDamageMessages, optional XComGameState NewGameState)
{
	local int DamageAmount, Index, BonusDamageToRemove;
	local XComGameStateHistory History;
	local XComGameState_Unit kSourceUnit;
	local XComGameState_Effect DualWeaponDamagePenaltyEffect;

	DamageAmount = super.CalculateDamageAmount(ApplyEffectParameters, ArmorMitigation, NewRupture, NewShred, AppliedDamageTypes, bAmmoIgnoresShields, bFullyImmune, SpecialDamageMessages, NewGameState);

	History = `XCOMHISTORY;
	kSourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	DualWeaponDamagePenaltyEffect = kSourceUnit.GetUnitAffectedByEffectState('DualWeaponDamagePenalty');

	//`LOG(default.Class @ GetFuncName() @ SpecialDamageMessages.Length, class'X2DownloadableContentInfo_DualWieldMelee'.default.bLog, 'DualWieldMelee');

	for (Index = SpecialDamageMessages.Length - 1; Index >= 0; Index--)
	{
		//`LOG(default.Class @ GetFuncName() @ DualWeaponDamagePenaltyEffect.ObjectID @ SpecialDamageMessages[Index].SourceID, class'X2DownloadableContentInfo_DualWieldMelee'.default.bLog, 'DualWieldMelee');
		if (DualWeaponDamagePenaltyEffect.ObjectID != SpecialDamageMessages[Index].SourceID)
		{
			BonusDamageToRemove += SpecialDamageMessages[Index].Value;
			SpecialDamageMessages.Remove(Index, 1);
		}
	}
	DamageAmount -= BonusDamageToRemove;
	return DamageAmount;
}