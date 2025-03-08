class MorphHuntComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;

var PostProcessChain blackScreen;
var array< PostProcessChain > oldPPChains;
var float blackScreenTimer;
var bool isBlackScreen;

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
	}
}

simulated event Tick( float delta )
{
	if(IsZero(gMe.Velocity))
	{
		if(!isBlackScreen && !gMe.IsTimerActive(NameOf( StartBlackScreen ), self))
		{
			gMe.SetTimer( blackScreenTimer, false, NameOf( StartBlackScreen ), self);
		}
	}
	else
	{
		if(gMe.IsTimerActive(NameOf( StartBlackScreen ), self))
		{
			gMe.ClearTimer(NameOf( StartBlackScreen ), self);
		}
		if(isBlackScreen)
		{
			StopBlackScreen();
		}
	}
}

function StartBlackScreen()
{
	local int i;
	local GGLocalPlayer goatPlayer;

	//myMut.WorldInfo.Game.Broadcast(myMut, "Black Filter");
	goatPlayer = gMe.GetLocalPlayerGoat();

	for( i = 0; i < goatPlayer.PlayerPostProcessChains.Length; ++i )
	{
		oldPPChains.AddItem( goatPlayer.PlayerPostProcessChains[ i ] );
	}

	goatPlayer.RemoveAllPostProcessingChains();

	if( goatPlayer.InsertPostProcessingChain( blackScreen, 0, false ) )
	{
		goatPlayer.TouchPlayerPostProcessChain();
	}
	isBlackScreen=true;
}

function StopBlackScreen()
{
	local int i;
	local GGLocalPlayer goatPlayer;

	//myMut.WorldInfo.Game.Broadcast(myMut, "No Filter");
	goatPlayer = gMe.GetLocalPlayerGoat();
	goatPlayer.RemoveAllPostProcessingChains();

	for( i = 0; i < oldPPChains.Length; ++i )
	{
		goatPlayer.InsertPostProcessingChain( oldPPChains[ i ], -1, false );
	}
	oldPPChains.Length=0;
	isBlackScreen=false;
}

defaultproperties
{
	Begin Object class=UberPostProcessEffect Name=UPPE1
		EffectName=BlackScreen
		SceneShadows=(X=1, Y=1, Z=1)
	End Object

	Begin Object class=PostProcessChain Name=PPC1
		Effects.Add(UPPE1)
	End Object
	blackScreen=PPC1

	blackScreenTimer=5.f
}