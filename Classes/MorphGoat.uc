class MorphGoat extends GGMutator;

var array<MorphGoatComponent> mMorphGoatComponents;

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;
	local MorphGoatComponent morphComp;

	super.ModifyPlayer( other );

	goat = GGGoat( other );
	if( goat != none )
	{
		morphComp=MorphGoatComponent(GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).FindMutatorComponent(class'MorphGoatComponent', goat.mCachedSlotNr));
		if(morphComp != none && mMorphGoatComponents.Find(morphComp) == INDEX_NONE)
		{
			mMorphGoatComponents.AddItem(morphComp);
		}
	}
}

simulated event Tick( float delta )
{
	local int i;

	for( i = 0; i < mMorphGoatComponents.Length; i++ )
	{
		mMorphGoatComponents[ i ].Tick( delta );
	}
	super.Tick( delta );
}

DefaultProperties
{
	mMutatorComponentClass=class'MorphGoatComponent'
}