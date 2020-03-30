class X2Effect_DualWeaponDamagePenalty extends X2Effect_Persistent;

var float DamageMultiplierPrimary;
var float DamageMultiplierSecondary;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState) 
{
	local X2Effect_ApplyWeaponDamage DamageEffect;
	local int DamageModifier;

	if (CurrentDamage == 0)
		return 0;

	if (!AbilityState.GetMyTemplate().IsMelee())
		return 0;

	// only limit this when actually applying damage (not previewing)
	if( NewGameState != none )
	{
		//	only add the bonus damage when the damage effect is applying the weapon's base damage
		DamageEffect = X2Effect_ApplyWeaponDamage(class'X2Effect'.static.GetX2Effect(AppliedData.EffectRef));
		if( DamageEffect == none || DamageEffect.bIgnoreBaseDamage )
		{
			return 0;
		}
	}

	//`Log(default.Class @ GetFuncName() @ AbilityState.GetMyTemplateName() @ AppliedData.AbilityResultContext.HitResult @ AbilityState.SourceWeapon.ObjectID @ EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID, class'X2DownloadableContentInfo_DualWieldMelee'.default.bLog, 'DualWieldMelee');

	if(AbilityState.GetMyTemplateName() != 'DualSlashSecondary' &&
	  (AppliedData.AbilityResultContext.HitResult == eHit_Success || AppliedData.AbilityResultContext.HitResult == eHit_Crit || AppliedData.AbilityResultContext.HitResult == eHit_Graze))
	{
		DamageModifier = (CurrentDamage - int(CurrentDamage * DamageMultiplierPrimary))* -1;
		`Log(default.Class @ GetFuncName() @ AbilityState.GetMyTemplateName() @ AppliedData.AbilityResultContext.HitResult @ CurrentDamage @ "-"  @ DamageModifier @ "=" @ (CurrentDamage + DamageModifier), class'X2DownloadableContentInfo_DualWieldMelee'.default.bLog, 'DualWieldMelee');
		
		return DamageModifier;
	}

	if(AbilityState.GetMyTemplateName() == 'DualSlashSecondary' &&
	  (AppliedData.AbilityResultContext.HitResult == eHit_Success || AppliedData.AbilityResultContext.HitResult == eHit_Crit || AppliedData.AbilityResultContext.HitResult == eHit_Graze))
	{
		DamageModifier = (CurrentDamage - int(CurrentDamage * DamageMultiplierSecondary))* -1;
		`Log(default.Class @ GetFuncName() @ AbilityState.GetMyTemplateName() @ AppliedData.AbilityResultContext.HitResult @ CurrentDamage @ "-"  @ DamageModifier @ "=" @ (CurrentDamage + DamageModifier), class'X2DownloadableContentInfo_DualWieldMelee'.default.bLog, 'DualWieldMelee');
		
		return DamageModifier;
	}

	return 0; 
}

defaultproperties
{
	EffectName = "DualWeaponDamagePenalty"
}
