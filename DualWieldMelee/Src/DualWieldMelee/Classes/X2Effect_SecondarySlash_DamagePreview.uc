class X2Effect_SecondarySlash_DamagePreview extends X2Effect;

//	This is a dummy effect with a sole purpose of adding the Secondary Slash damage into Damage Preview of abilities that are valid for Secondary Slash
//	This effect is attached to eligible abilities in this mod's OnPostTemplateCreated event.

simulated function GetDamagePreview(StateObjectReference TargetRef, XComGameState_Ability AbilityState, bool bAsPrimaryTarget, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	local XComGameState_Unit	AbilityOwner;
	local XComGameState_Ability SecondarySlash_AbilityState;
	local XComGameStateHistory	History;

	History = `XCOMHISTORY;
	AbilityOwner = XComGameState_Unit(History.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
	if (AbilityOwner != none)
	{
		SecondarySlash_AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityOwner.FindAbility('DualSlashSecondary').ObjectID));
		if (SecondarySlash_AbilityState != none)
		{
			SecondarySlash_AbilityState.GetDamagePreview(TargetRef, MinDamagePreview, MaxDamagePreview, AllowsShield);
		}
	}
}