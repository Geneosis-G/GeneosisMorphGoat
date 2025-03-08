class MorphGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;
var Actor tkItem;
var GGNpc tkNpc;
var AnimNodeSlot oldAnimNodeSlot;
var AnimTree oldAnimTree;
var ParticleSystem morphParticleTemplate;
var bool isMorphed;
var float myHeight;
var float itemHeight;
var rotator customRot;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		gMe.bCanBeBaseForPawns=true;
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if( newKey == 'Y' || newKey == 'XboxTypeS_LeftThumbStick' || newKey == 'U')
		{
			DoMorph();
		}

		if(localInput.IsKeyIsPressed("RightMouseButton", string( newKey ))|| newKey == 'XboxTypeS_LeftTrigger')
		{
			if(myMut.WorldInfo.Game.GameSpeed < 1.0f || myMut.WorldInfo.bPlayersOnly)
			{
				if(isMorphed)
				{
					RotateItem();
				}
			}
		}
	}
}

/**
 * Main loop
 */
simulated event Tick( float delta )
{
	myHeight=gMe.GetCollisionHeight();
	//myMut.WorldInfo.Game.Broadcast(myMut, "Tick " $ deltaTime);

	if(isMorphed)
	{
		//Cancel morph if you go ragdoll
		if(gMe.mIsRagdoll)
		{
			UnmorphMe();
		}
		//Cancel morph if object is destroyed
		else if(tkItem == none || tkItem.bPendingDelete)
		{
			UnmorphMe();
		}
		//Cancel morph if object is broken
		else if(GGKActor(tkItem) != none && GGKActor(tkItem).mSpawnedApexActor != none)
		{
			UnmorphMe();
		}
		//Cancel morph if object exploded
		else if(GGExplosiveActorAbstract(tkItem) != none && GGExplosiveActorAbstract(tkItem).mIsExploding && GGExplosiveActorAbstract(tkItem).mShouldShutdownAfterExplosion)
		{
			UnmorphMe();
		}
		else
		{
			//Fix NPC ragdoll
			if(tkNpc != none && tkNpc.mIsRagdoll)
			{
				tkNpc.StandUp();
			}

			//Fix position
			CorrectMorphItemPosAndRot();
		}
	}
}

function rotator GetGlobalRotation(rotator BaseRotation, rotator LocalRotation)
{
	local vector X, Y, Z;

	GetAxes(LocalRotation, X, Y, Z);
	return OrthoRotation(X >> BaseRotation, Y >> BaseRotation, Z >> BaseRotation);
}

function RotateItem()
{
	customRot.Yaw-=16384;
	if(customRot.Yaw < 0)
	{
		customRot.Yaw=49152;
	}
	CorrectMorphItemPosAndRot();
}

/**
 * Activate Morph
 */
function DoMorph()
{
	//myMut.WorldInfo.Game.Broadcast(myMut, "morph(" $ isMorphed $ ")");

	if(!isMorphed)
	{
		MorphMe();
	}
	else
	{
		UnmorphMe();
	}
}

/*
 * Try to take the first item aligned with the goat or the item you are licking
 */
function MorphMe()
{
	local Actor hitActor;
	local bool baseOk;

	//Take licked item
	hitActor=gMe.mGrabbedItem;
	if(isMorphed || hitActor == none || gMe.mIsRagdoll)
		return;

	//If actor based, we take the base instead
	baseOk=false;
	while(hitActor.Base != none && !baseOk)
	{
		if(GGGoat(hitActor.Base) != gMe)
		{
			if(GGKActor(hitActor.Base) != none
			|| GGNpc(hitActor.Base) != none
			|| GGInterpActor(hitActor.Base) != none
			|| GGSVehicle(hitActor.Base) != none
			|| GGGoat(hitActor.Base) != none
			|| GGKAsset(hitActor.Base) != none)
			{
				hitActor=hitActor.Base;
			}
			else
			{
				baseOk=true;
			}
		}
		else
		{
			baseOk=true;
		}
	}

	//Can't morph into interpactors, goats or KAssets
	if(GGInterpActor(hitActor) != none || GGGoat(hitActor) != none || GGKAsset(hitActor) != none)
		return;

	//Grab the actor
	gMe.DropGrabbedItem();
	tkItem=hitActor;
	tkNpc=GGNpc(tkItem);
	if(tkNpc != none)
	{
		tkNpc.StandUp();
		itemHeight=tkNpc.GetCollisionHeight();
		SetMorphedPhysics(tkNpc, true);
		oldAnimNodeSlot=tkNpc.mAnimNodeSlot;
		tkNpc.mAnimNodeSlot=none;
		oldAnimTree=tkNpc.mesh.AnimTreeTemplate;
		tkNpc.mesh.SetAnimTreeTemplate(none);
	}
	tkItem.SetPhysics(PHYS_None);
	tkItem.SetHardAttach(true);
	gMe.mActorsToIgnoreBlockingBy.AddItem( tkItem );
	CorrectMorphItemPosAndRot();
	gMe.SetHidden(true);
	isMorphed=true;
	tkItem.WorldInfo.MyEmitterPool.SpawnEmitter(morphParticleTemplate, tkItem.Location,, tkItem);
}

/*
 * Unmorph the goat
 */
function UnmorphMe()
{
	local vector tkLocation;

	if(!isMorphed)
		return;

	if(tkNpc != none)
	{
		tkNpc.mesh.SetAnimTreeTemplate(oldAnimTree);
		tkNpc.mAnimNodeSlot=oldAnimNodeSlot;
		SetMorphedPhysics(tkNpc, false);
	}
	tkItem.SetHardAttach(false);
	tkItem.SetBase(none);

	gMe.mesh.GetSocketWorldLocationAndRotation('Demonic', tkLocation);
	if(IsZero(tkLocation))
	{
		tkLocation=gMe.Location + (Normal(vector(gMe.Rotation)) * (gMe.GetCollisionRadius() + 30.f));
	}
	tkItem.SetLocation(tkLocation);
	GetComponent(tkItem).SetRBPosition(tkLocation);

	gMe.mActorsToIgnoreBlockingBy.RemoveItem(tkItem);
	tkItem.SetPhysics(tkNpc!=none?PHYS_Falling:PHYS_RigidBody);
	tkItem=none;
	tkNpc=none;
	gMe.SetHidden(false);
	customRot=rot(0, 0, 0);
	isMorphed=false;
	gMe.WorldInfo.MyEmitterPool.SpawnEmitter(morphParticleTemplate, gMe.Location,, gMe);
}

function CorrectMorphItemPosAndRot()
{
	local vector newLoc;
	local rotator newRot;

	GetExpectedLocationAndRotation(newLoc, newRot);
	if((tkItem.Location == newLoc || GetComponent(tkItem).GetPosition() == newLoc)
	&& tkItem.Rotation == newRot)
		return;

	tkItem.SetLocation(newLoc);
	tkItem.SetRotation(newRot);
	if(tkNpc == none)
	{
		GetComponent(tkItem).SetRBPosition(tkItem.Location);
		GetComponent(tkItem).SetRBRotation(tkItem.Rotation);
	}
	tkItem.SetBase(gMe,, gMe.mesh, '');
}

function GetExpectedLocationAndRotation(out vector expectedLoc, out rotator expectedRot)
{
	if(tkNpc != none)
	{
		expectedLoc=gMe.Location + vect(0, 0, 1)*(itemHeight-myHeight);
		expectedRot=GetGlobalRotation(gMe.Rotation, customRot);//myMut.WorldInfo.Game.Broadcast(myMut, "tkNpc state=" $ tkNpc.GetStateName());
	}
	else
	{
		expectedLoc=gMe.Location + vect(0, 0, -1)*myHeight;
		expectedRot=GetGlobalRotation(gMe.Rotation, rot(0, -16384, 0) + customRot);
	}
}

function PrimitiveComponent GetComponent(Actor act)
{
	if(GGPawn(act) != none)
	{
		return GGPawn(act).mesh;
	}
	else
	{
		return act.CollisionComponent;
	}
}

function SetMorphedPhysics(GGNpc npc, bool activate)
{
	local GGAIController oldAIController;
	//myMut.WorldInfo.Game.Broadcast(myMut, "SetMorphedPhysics 0");
	tkNpc.mAnimNodeSlot.StopCustomAnim(0.f);
	tkNpc.mAnimNodeSlot.StopAnim();
	tkNpc.SetSoundEnabled( !activate );
	tkNpc.SetCollision(!activate, !activate);
	tkNpc.bCollideWorld = !activate;
	//tkNpc.SetPushesRigidBodies(!activate);myMut.WorldInfo.Game.Broadcast(myMut, "SetMorphedPhysics 6");
	tkNpc.bCanBeDamaged=!activate;
	tkNpc.bBlockActors=!activate;
	tkNpc.mesh.SetNotifyRigidBodyCollision( !activate );
	tkNpc.mesh.SetHasPhysicsAssetInstance( !activate );
	oldAIController=GGAIController(tkNpc.Controller);
	if(oldAIController != none)
	{
		oldAIController.EndAttack();
		oldAIController.StopAllScheduledMovement();
		oldAIController.GotoState('');
	}
}

defaultproperties
{
	morphParticleTemplate=ParticleSystem'Goat_Effects.Effects.Effects_Landing_01'
}