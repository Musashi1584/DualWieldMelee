class X2Ability_DualWieldMelee extends X2Ability config(DualWieldMelee);

var config float DUALWEAPON_DAMAGE_MULTIPLIER_PRIMARY;
var config float DUALWEAPON_DAMAGE_MULTIPLIER_SECONDARY;

var config bool SHOW_DUAL_WIELD_MELEE_FLYOVER;
var config array<name> ABILITIES_DO_NOT_TRIGGER_SECONDARY_SLASH;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(BladestormAttackDualMelee());
	Templates.AddItem(DualMeleeDamageModifer());
	Templates.AddItem(DualSlashSecondary());
	Templates.AddItem(DualWhirlwhindStrike());
	Templates.AddItem(DualSwordThrustAnimSet());

	return Templates;
}

static function X2AbilityTemplate BladestormAttackDualMelee()
{
	local X2AbilityTemplate			Template;

	Template = class'X2Ability_RangerAbilitySet'.static.BladestormAttack('BladestormAttackDualMelee');
	Template.CustomFireAnim = 'FF_MeleeA';
	Template.CustomFireKillAnim = 'FF_MeleeA';
	Template.CustomMovingFireAnim = 'FF_MeleeA';
	Template.CustomMovingFireKillAnim = 'FF_MeleeA';
	Template.CustomMovingTurnLeftFireAnim = 'FF_MeleeA';
	Template.CustomMovingTurnLeftFireKillAnim = 'FF_MeleeA';
	Template.CustomMovingTurnRightFireAnim = 'FF_MeleeA';
	Template.CustomMovingTurnRightFireKillAnim= 'FF_MeleeA';

	Template.OverrideAbilities.AddItem('BladestormAttack');

	Template.AbilityShooterConditions.AddItem(new class'X2Condition_DualMelee');

	Template.DefaultSourceItemSlot = eInvSlot_PrimaryWeapon;

	return Template;
}

static function X2AbilityTemplate DualMeleeDamageModifer()
{
	local X2AbilityTemplate						Template;
	local X2Effect_DualWeaponDamagePenalty		DamageEffect;

	// Icon Properties
	`CREATE_X2ABILITY_TEMPLATE(Template, 'DualMeleeDamageModifer');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_momentum";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bHideOnClassUnlock = false;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Bonus Damage with swords
	DamageEffect = new class'X2Effect_DualWeaponDamagePenalty';
	DamageEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, false);
	DamageEffect.DamageMultiplierPrimary = default.DUALWEAPON_DAMAGE_MULTIPLIER_PRIMARY;
	DamageEffect.DamageMultiplierSecondary = default.DUALWEAPON_DAMAGE_MULTIPLIER_SECONDARY;
	DamageEffect.bDisplayInSpecialDamageMessageUI = default.SHOW_DUAL_WIELD_MELEE_FLYOVER;
	DamageEffect.BuildPersistentEffect(1, true, false, false);
	Template.AddTargetEffect(DamageEffect);

	Template.AbilityShooterConditions.AddItem(new class'X2Condition_DualMelee');

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.bShowActivation = false;
	Template.bUniqueSource = true;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate DualSlashSecondary()
{
	local X2AbilityTemplate							Template;
	local X2AbilityTrigger_EventListener			AbilityTrigger;
	local X2Effect_ApplySecondaryWeaponDamage		DamageEffect;

	Template = class'X2Ability_RangerAbilitySet'.static.AddSwordSliceAbility('DualSlashSecondary');
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.bDisplayInUITacticalText = false;

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.AbilityTriggers.Length = 0;

	Template.AbilityShooterConditions.AddItem(new class'X2Condition_DualMelee');

	AbilityTrigger = new class'X2AbilityTrigger_EventListener';
	AbilityTrigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	AbilityTrigger.ListenerData.EventID = 'AbilityActivated';
	AbilityTrigger.ListenerData.Filter = eFilter_Unit;
	AbilityTrigger.ListenerData.EventFn = AbilityTriggerEventListener_DualSlashSecondary;
	Template.AbilityTriggers.AddItem(AbilityTrigger);

	Template.AbilityTargetEffects.Length = 0;
	DamageEffect = new class'X2Effect_ApplySecondaryWeaponDamage';
	Template.AddTargetEffect(DamageEffect);

	Template.AbilityTargetStyle = default.SimpleSingleMeleeTarget;
	Template.TargetingMethod = none;
	Template.bSkipFireAction = false;	//	Fire Action will be neutered by MergeVis
	Template.MergeVisualizationFn = MergeVisualization;

	Template.AbilityCosts.Length = 0;

	Template.DefaultSourceItemSlot = eInvSlot_SecondaryWeapon;
	Template.bUniqueSource = true;
	Template.bSkipExitCoverWhenFiring  = true;
	
	return Template;
}



static function EventListenerReturn AbilityTriggerEventListener_DualSlashSecondary(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameStateContext_Ability  AbilityContext;
	local XComGameState_Unit            SourceUnit;
	local XComGameState_Ability         TriggeringAbilityState;
	local XComGameState_Ability         SecondarySlashAbilityState;
	local XComGameState_Item			SourceWeapon;

	SourceUnit = XComGameState_Unit(EventSource);
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	TriggeringAbilityState = XComGameState_Ability(EventData);
	SecondarySlashAbilityState = XComGameState_Ability(CallbackData);

	if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt || TriggeringAbilityState == none || SourceUnit == none || AbilityContext == none || SecondarySlashAbilityState == none)
	{
		return ELR_NoInterrupt;
	}
	
	//	Includes DualSlashSecondary to prevent inception.
	if (default.ABILITIES_DO_NOT_TRIGGER_SECONDARY_SLASH.Find(TriggeringAbilityState.GetMyTemplateName()) != INDEX_NONE)
	{
		return ELR_NoInterrupt;
	}

	`LOG("Secondary Slash on: " @ SecondarySlashAbilityState.GetSourceWeapon().GetMyTemplateName() @ SecondarySlashAbilityState.GetSourceWeapon().InventorySlot @ "triggered by:" @ SourceUnit.GetFullName(), class'X2DownloadableContentInfo_DualWieldMelee'.default.bLog, 'DualWieldMelee');

	//	Exit Listener if the Triggering Ability is not attached to a primary melee weapon, or it's not a melee ability.
	SourceWeapon = TriggeringAbilityState.GetSourceWeapon();
	if (SourceWeapon != none)
	{
		if (!class'X2DownloadableContentInfo_DualWieldMelee'.static.IsPrimaryMeleeWeaponTemplate(SourceWeapon) || !TriggeringAbilityState.IsMeleeAbility())
		{
			return ELR_NoInterrupt;
		}
	}
	
	//	If you're still not satisfied with above heurestic and want to use your method of marking which abilities should trigger Dual Slash Secondary.
	//	The 'DualSlashSecondary' itself is not used for that purpose, however.
	//if(TriggeringAbilityState.GetMyTemplate().PostActivationEvents.Find('DualSlashSecondary') == INDEX_NONE)
	//{
	//	return ELR_NoInterrupt;
	//}

	//  Activate Second Rapid Fire Shot against the same target the Triggering Ability was activated.
	if (SecondarySlashAbilityState.AbilityTriggerAgainstSingleTarget(AbilityContext.InputContext.PrimaryTarget, false, GameState.HistoryIndex))
	{
		//  Secondary Slash has activated successfully.
		
		`LOG("Secondary Slash on: " @ SecondarySlashAbilityState.GetSourceWeapon().GetMyTemplateName() @ SecondarySlashAbilityState.GetSourceWeapon().InventorySlot @ "triggered by:" @ SourceUnit.GetFullName() @ "using ability: " @ TriggeringAbilityState.GetMyTemplateName() @ "at Index: " @ GameState.HistoryIndex, class'X2DownloadableContentInfo_DualWieldMelee'.default.bLog, 'DualWieldMelee');
	}
	else 
	{
		`LOG("Warning: Secondary Slash FAILED on: " @ SecondarySlashAbilityState.GetSourceWeapon().GetMyTemplateName() @ SecondarySlashAbilityState.GetSourceWeapon().InventorySlot @ "triggered by:" @ SourceUnit.GetFullName() @ "using ability: " @ TriggeringAbilityState.GetMyTemplateName() @ "at Index: " @ GameState.HistoryIndex, class'X2DownloadableContentInfo_DualWieldMelee'.default.bLog, 'DualWieldMelee');
		//  Secondary Slash has failed to activate.
	}

	return ELR_NoInterrupt;
}

// BuildTree vis of the current ability
// VisualizationTree vis of the original ability
function MergeVisualization(X2Action BuildTree, out X2Action VisualizationTree)
{
	local XComGameStateVisualizationMgr		VisMgr;
	local X2Action_MarkerNamed				MarkerNamed, JoinMarker, SecondJoin, FireReplace;
	local array<X2Action>					arrActions;
	local X2Action							Action, FirstFireAction, SecondFireAction, SpacerAction;
	local int i;
	local VisualizationActionMetadata		ActionMetadata;
	local XComGameStateContext_Ability		FirstAbilityContext, SecondAbilityContext;
	local StateObjectReference				Target;
	local int HistoryIndexDelta;

	VisMgr = `XCOMVISUALIZATIONMGR;

	//	##### Acquire Context for both this Primary and Secondary Slashes, as well as their Fire Actions.
	SecondFireAction = VisMgr.GetNodeOfType(BuildTree, class'X2Action_Fire');
	SecondAbilityContext = XComGameStateContext_Ability(BuildTree.StateChangeContext);
	Target = SecondAbilityContext.InputContext.PrimaryTarget;
	
	//	Acquire all Fire Actions that belong to the unit activating Dual Secondary Slash.
	VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_Fire', arrActions, , SecondAbilityContext.InputContext.SourceObject.ObjectID, true);
	`LOG("MergeVisualization for: " @ SecondAbilityContext.InputContext.AbilityTemplateName @ "Activated at History Index: " @ SecondAbilityContext.DesiredVisualizationBlockIndex @ "found Fire Actions: " @ arrActions.Length,, 'DualWieldMelee');

	//	If there is only one Fire Action present in the Viz Tree, that's *likely* because all other Fire Actions (including the one belonging to the ability that triggered this instance of Secondary Slash) 
	//	have already been neutered by other Merge Vis functions, because they're not intended to visualize.
	if (arrActions.Length == 1 && arrActions[0].StateChangeContext.AssociatedState.HistoryIndex <= SecondAbilityContext.DesiredVisualizationBlockIndex)
	{
		//	So we just use whatever Fire Action is present there, provided it is older or same age as Fire Action of the Secondary Slash. Otherwise, something has gone very wrong.
		FirstFireAction = arrActions[0];
		FirstAbilityContext = XComGameStateContext_Ability(arrActions[0].StateChangeContext);
	}
	else
	{
		//	If there are multiple Fire Actions, because of multiple abiliy activations or something like that, try to find the Fire Action with the same History Index as the fire action of the Secondary Slash
		//	which we set when we trigger the Secondary Slash in the Event Listener.
		foreach arrActions(Action)
		{	
			`LOG("Found Fire Action with index: " @ Action.StateChangeContext.AssociatedState.HistoryIndex,, 'DualWieldMelee');
			//	Locate Fire Action with the History Index that was assigned to the Context when DualSlashSecondary was triggered.
			if (Action.StateChangeContext.AssociatedState.HistoryIndex == SecondAbilityContext.DesiredVisualizationBlockIndex) 
			{
				FirstFireAction = Action;
				FirstAbilityContext = XComGameStateContext_Ability(Action.StateChangeContext);

				`LOG("History Index match found! Triggering Ability: " @ FirstAbilityContext.InputContext.AbilityTemplateName @ "No Primary Target in this Fire Action?" @ X2Action_Fire(Action).PrimaryTargetID == 0,, 'DualWieldMelee');

				//	An ability can potentially have multiple Fire Actions with the same History Index, so we also check that this Fire Action has been activated against the same target as DualSlashSecondary.
				//  Mr. Nice: if the PrimaryTargetID is zero, then just use the context primary instead
				if (SecondAbilityContext.InputContext.PrimaryTarget.ObjectID == (X2Action_Fire(Action).PrimaryTargetID == 0 ? XComGameStateContext_Ability(Action.StateChangeContext).InputContext.PrimaryTarget.ObjectID : X2Action_Fire(Action).PrimaryTargetID))
				{
					//	Found Fire Action with correct History Index and correct Target.
					`LOG("Found Fire Action with correct History Index and correct Target.",, 'DualWieldMelee');
					break;
				}
			}
		}
	}

	//	First attempt to acquire Fire Action has failed. This can happen if the triggering ability doesn't have a Fire Action, e.g. if it was already neutered by that ability's Merge Vis,
	//	and there are more than one Fire Actions in the Viz tree due to multiple ability activations, so it wouldn't be right to settle for just any Fire Action. We have to find the Fire Action that is 
	//	older than Secondary Slash's Fire Action, but still the closest to it.
	if (FirstFireAction == none)
	{
		`LOG("First attempt to acquire Fire Action has failed.",, 'DualWieldMelee');

		//	Cycle through Fire Actions once again.
		foreach arrActions(Action)
		{
			//	This Fire Action is older or same age as the Secondary Slash's Fire Action
			if (Action.StateChangeContext.AssociatedState.HistoryIndex <= SecondAbilityContext.DesiredVisualizationBlockIndex &&
			HistoryIndexDelta < SecondAbilityContext.DesiredVisualizationBlockIndex - Action.StateChangeContext.AssociatedState.HistoryIndex)
			{	//	and the difference in History Indices is larger than for the Fire Action that we have found previously, if any

				FirstFireAction = Action;
				FirstAbilityContext = XComGameStateContext_Ability(Action.StateChangeContext);
				HistoryIndexDelta = SecondAbilityContext.DesiredVisualizationBlockIndex - Action.StateChangeContext.AssociatedState.HistoryIndex;

				`LOG("Settled for Fire Action with History Index: " @ Action.StateChangeContext.AssociatedState.HistoryIndex @ "Delta: " @ HistoryIndexDelta,, 'DualWieldMelee');
				//	No break on purpose! We want the cycle to sift through all Fire Actions in the tree.
			}
		}
	}
	
	//	Final failsafe.
	//Mr. Nice: If this happens who knows what's going on? Just keep VisMgr happy with the most generic merge...
	if (FirstFireAction == none || SecondFireAction == none)
	{
		`log("Dual Wielded Melee merge visualization failed!" @ FirstFireAction == none @ SecondFireAction == none,, 'DualWieldMelee');
		XComGameStateContext_Ability(BuildTree.StateChangeContext).SuperMergeIntoVisualizationTree(BuildTree, VisualizationTree);
		return;
	}
	//	##### -------------------

	//	#### Acquire Join Markers
	VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_MarkerNamed', arrActions, , , true);
	for (i = 0; i < arrActions.Length; ++i)
	{
		MarkerNamed = X2Action_MarkerNamed(arrActions[i]);
		if (MarkerNamed.MarkerName == 'Join' && MarkerNamed.StateChangeContext.AssociatedState.HistoryIndex == SecondAbilityContext.DesiredVisualizationBlockIndex)
		{
			JoinMarker = MarkerNamed;
			break;
		}
	}

	`assert(JoinMarker != none);
	
	VisMgr.GetNodesOfType(BuildTree, class'X2Action_MarkerNamed', arrActions, , , true);
	for (i = 0; i < arrActions.Length; ++i)
	{
		MarkerNamed = X2Action_MarkerNamed(arrActions[i]);
		if (MarkerNamed.MarkerName == 'Join')
		{
			SecondJoin = MarkerNamed;
		}
	}
	//	##### -------------------

	//Mr. Nice: If Second hit misses, animate first hit. Otherwise animate second hit.
	//Means that if we kill on the second shot, we correctly get the death anim
	//Well, that was the theory, but hiding hits is hard, and if you hide the first one, you don't get the projectile blood.

	if(!X2Action_Fire(FirstFireAction).bWasHit) // requires unprivating: var /*private*/ ProtectedWrite bool bWasHit; in X2Action_Fire
	{
		VisMgr.GetNodesOfType(BuildTree, class'X2Action_ApplyWeaponDamageToUnit', arrActions,, Target.ObjectID);
		foreach arrActions(Action)
		{
			if(Action.ParentActions[0] == SecondFireAction)
			{
				X2Action_ApplyWeaponDamageToUnit(Action).bPlayDamageAnim = false;
			}
		}
	}
	else
	{
		VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_ApplyWeaponDamageToUnit', arrActions,, Target.ObjectID);
		if (IsContextMiss(FirstAbilityContext))
		{
			foreach arrActions(Action)
			{
				if(Action.ParentActions[0] == FirstFireAction)
				{
					X2Action_ApplyWeaponDamageToUnit(Action).bPlayDamageAnim = false;
				}
			}
		}
		
		//Mr. Nice: This makes sure you can see the counter attack, whether the second shot kills them or not
		else if(FirstAbilityContext.ResultContext.HitResult == eHit_CounterAttack)
		{
			foreach arrActions(Action)
			{
				if (Action.ParentActions[0] == FirstFireAction)
				{
					if(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Target.ObjectID,, SecondAbilityContext.AssociatedState.HistoryIndex)).IsDead())
					{
						//Mr. Nice: If the second hit kills, stil want to show the counter animation before the unit animates its death
						SpacerAction = Action;
					}
					else
					{
						//Mr. Nice: If the second hit does not kill, want the counter animation, not the flinch animation, to get priority
						//Spacer both keeps the sets of damageotunit's from being siblings if both miss,
						//and helpfully makes sure you see the counter anim, not the flinch anim when you have a counter & hit result
						ActionMetaData = FirstFireAction.Metadata;
						SpacerAction = class'X2Action_ApplyDamageSpacer'.static.AddToVisualizationTree(ActionMetadata, FirstAbilityContext,, FirstFireAction);
						VisMgr.DisconnectAction(Action);
						VisMgr.ConnectAction(Action, VisualizationTree,, SpacerAction);
						SpacerAction = FirstFireAction;
					}
					break;
				}
			}
		}
	}

	//If the second shot has a join created, then just slot it in above the first shots join
	if (SecondJoin != none)
	{
		VisMgr.ConnectAction(SecondJoin, VisualizationTree,,, JoinMarker.ParentActions);
		VisMgr.ConnectAction(JoinMarker, BuildTree,, SecondJoin);
	}
	//If the second shot does not have a join, then connect the leaf nodes to the first shots join
	else
	{
		VisMgr.GetAllLeafNodes(BuildTree, arrActions);
		VisMgr.ConnectAction(JoinMarker,BuildTree,,, arrActions);
	}
	//Mr. Nice, ok, want to connect children of secondfireaction, to firstfireaction
	arrActions = SecondFireAction.ChildActions;
	//If first hit was countered, then the attachment point for second hit applydamagetounit will have been set
	//Otherwise, create a new SpacerAction for them
	if (SpacerAction == none)
	{
		ActionMetaData = SecondFireAction.Metadata;
		SpacerAction = class'X2Action_ApplyDamageSpacer'.static.AddToVisualizationTree(ActionMetadata, SecondAbilityContext,, FirstFireAction);
	}

	foreach arrActions(Action)
	{
		VisMgr.ConnectAction(Action, VisualizationTree,, X2Action_ApplyWeaponDamageToUnit(Action) != none ? SpacerAction : FirstFireAction);
	}
	//For correct counter attack animations, need to be able to trace from BuildTree down to the second shots apply damages, without
	//encountering the first shot's applydamages. So swap out the SecondFireAction for a marker, just to keep BuildTree traceable.
	FireReplace = X2Action_MarkerNamed(class'X2Action'.static.CreateVisualizationActionClass(class'X2Action_MarkerNamed', SecondAbilityContext));
	FireReplace.SetName("DualSlashSecondary_FireActionStub");	//	Please don't change the Marker Name, other mods may rely on this.
	VisMgr.ReplaceNode(FireReplace, SecondFireAction);	

	//Mr. Nice we have swapped out the SecondFireAction,
	//So can destroy it now without "stranding" any other actions
	VisMgr.DestroyAction(SecondFireAction);
}

//Mr. Nice: Just AbilityContext.IsResultContextHit() isn't good enough, since Unload multitargets
//The primary target, so have to check the multitarget results too
//Also, for animation purposes we want to treat a counterattack result as a hit, not miss
static function bool IsContextMiss(XComGameStateContext_Ability AbilityContext)
{
	local int MultiIndex;

	if (AbilityContext.IsResultContextHit() || AbilityContext.ResultContext.HitResult==eHit_CounterAttack)
	{
		return false;
	}
		
	for (MultiIndex = 0; MultiIndex < AbilityContext.InputContext.MultiTargets.Length; ++MultiIndex)
	{
		if (AbilityContext.IsResultContextMultiHit(MultiIndex))
		{
			return false;
		}
	}
	return true;
}


static function X2AbilityTemplate DualWhirlwhindStrike()
{
	local X2AbilityTemplate					Template;
	local X2AbilityCost_ActionPoints		ActionPointCost;
	local X2AbilityCost_Focus				FocusCost;

	Template = class'X2Ability_RangerAbilitySet'.static.AddSwordSliceAbility('DualWhirlwhindStrike');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_chryssalid_slash";

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 0;
	ActionPointCost.bAddWeaponTypicalCost = true;
	ActionPointCost.bConsumeAllPoints = false;
	Template.AbilityCosts.Length = 0;
	Template.AbilityCosts.AddItem(ActionPointCost);

	FocusCost = new class'X2AbilityCost_Focus';
	FocusCost.FocusAmount = 1;
	Template.AbilityCosts.AddItem(FocusCost);

	Template.OverrideAbilities.AddItem('WhirlwindFirstStrike');
	Template.PostActivationEvents.AddItem('DualSlashSecondary');
	Template.AbilityShooterConditions.AddItem(new class'X2Condition_DualMelee');

	Template.CustomFireAnim = 'FF_MeleeWhirlwindA';
	Template.CustomFireKillAnim = 'FF_MeleeWhirlwindA';
	Template.CustomMovingFireAnim = 'FF_MeleeWhirlwindA';
	Template.CustomMovingFireKillAnim = 'FF_MeleeWhirlwindA';
	Template.CustomMovingTurnLeftFireAnim = 'FF_MeleeWhirlwindA';
	Template.CustomMovingTurnLeftFireKillAnim = 'FF_MeleeWhirlwindA';
	Template.CustomMovingTurnRightFireAnim = 'FF_MeleeWhirlwindA';
	Template.CustomMovingTurnRightFireKillAnim = 'FF_MeleeWhirlwindA';

	return Template;
}

static function X2AbilityTemplate DualSwordThrustAnimSet()
{
	local X2AbilityTemplate                 Template;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'DualSwordThrustAnimSet');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_item_nanofibervest";

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTargetConditions.AddItem(new class'X2Condition_DualMelee');

	Template.OverrideAbilities.AddItem('SwordThrustAnimSet');

	return Template;
}