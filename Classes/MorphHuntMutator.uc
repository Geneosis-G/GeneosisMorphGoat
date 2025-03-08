class MorphHuntMutator extends GGMutator;

var array<MorphHuntComponent> mMorphHuntComponents;

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;
	local MorphHuntComponent morphComp;

	super.ModifyPlayer( other );

	goat = GGGoat( other );
	if( goat != none )
	{

		morphComp=MorphHuntComponent(GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).FindMutatorComponent(class'MorphHuntComponent', goat.mCachedSlotNr));
		if(morphComp != none && mMorphHuntComponents.Find(morphComp) == INDEX_NONE)
		{
			mMorphHuntComponents.AddItem(morphComp);
		}
	}
}

simulated event Tick( float delta )
{
	local MorphHuntComponent mhc;

	foreach mMorphHuntComponents(mhc)
	{
		mhc.Tick( delta );
	}
	super.Tick( delta );
}

DefaultProperties
{
	mMutatorComponentClass=class'MorphHuntComponent'
}