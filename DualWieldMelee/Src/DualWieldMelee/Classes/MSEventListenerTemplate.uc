class MSEventListenerTemplate extends X2EventListenerTemplate;

// Hack in here to start the actor as early as possible in tactical game
function RegisterForEvents()
{
	`XCOMGAME.Spawn(class'DualWieldMelee.DropShipMatinee_Actor');
}