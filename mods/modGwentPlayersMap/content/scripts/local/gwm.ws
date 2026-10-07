// Gwent Players Map
// Shows Gwent players on the world map and greys out the ones already beaten.
//
// Every pin comes from gwm_data.ws and is judged by one of:
//   tag   merchant: facts the game writes on the first win (see MerchantBeaten)
//   card  quest player: the unique card is in the inventory
//   none  anyone else: fact gwm_won_<pinId>, written by this mod after a win next to the pin
// Merchants also get gwm_won_<pinId> when beaten next to their NPC, in case another mod
// changes the game's reward facts.
//
// Map file (content/blob0.bundle): a modified panel_worldmap.redswf with the card icons
// (GwentPlayer / GwentPlayerDisabled) and a "Gwent" map filter for those pin types.

function GwmVersion() : string
{
	return "1.0.4";
}

struct GwmPin
{
	var id    : int;
	var world : string;
	var x     : float;
	var y     : float;
	var role  : string;
	var tag   : name;
	var card  : name;
}

class GwmData
{
	public var pins : array< GwmPin >;

	// Frame labels added to the world map pin sprite (modified panel_worldmap.redswf in content/blob0.bundle).
	public var iconNormal   : string;	default iconNormal   = "GwentPlayer";
	public var iconDefeated : string;	default iconDefeated = "GwentPlayerDisabled";

	private var cardIconsChecked : bool;
	private var cardIconsLoaded  : bool;

	public function Init()
	{
		pins.Clear();
		GwmLoadData( this );
	}

	// The marker file ships in the same bundle as the card icons: if it can be loaded, so was the map file.
	// Only reported by the "Debug info" option.
	public function CardIconsLoaded() : bool
	{
		var marker : C2dArray;

		if ( !cardIconsChecked )
		{
			marker = LoadCSV( "gameplay\gui_new\swf\worldmap\gwm_card_icons.csv" );
			if ( marker )
			{
				cardIconsLoaded = true;
			}
			cardIconsChecked = true;
		}
		return cardIconsLoaded;
	}

	public function AddPin( id : int, world : string, x : float, y : float, role : string, tag : name, card : name )
	{
		var pin : GwmPin;

		pin.id = id;
		pin.world = world;
		pin.x = x;
		pin.y = y;
		pin.role = role;
		pin.tag = tag;
		pin.card = card;
		pins.PushBack( pin );
	}

	// Facts written by GiveMerchantRandomGwintCardToPlayerQuest and friends on the first win.
	public function MerchantBeaten( tag : name ) : bool
	{
		var s : string = NameToString( tag );

		if ( FactsQuerySum( "merchant_card_" + s + "_card_already_given" ) > 0
			|| FactsQuerySum( s + "_gwent_given" ) > 0 )
		{
			return true;
		}
		// The game's quest data passes this tag with a trailing space.
		if ( tag == 'novigrad_poor_district_nowhere_01' )
		{
			return FactsQuerySum( "merchant_card_" + s + " _card_already_given" ) > 0;
		}
		return false;
	}

	public function IsDefeated( idx : int ) : bool
	{
		if ( IsNameValid( pins[ idx ].tag ) && MerchantBeaten( pins[ idx ].tag ) )
		{
			return true;
		}
		if ( IsNameValid( pins[ idx ].card ) && thePlayer.inv.HasItem( pins[ idx ].card ) )
		{
			return true;
		}
		return FactsQuerySum( "gwm_won_" + pins[ idx ].id ) > 0;
	}

	// Nearest pin to pos within maxDist metres, or -1.
	public function FindNearest( world : string, pos : Vector, maxDist : float ) : int
	{
		var i, best : int;
		var dx, dy, d, bestDist : float;

		best = -1;
		bestDist = maxDist * maxDist;
		for ( i = 0; i < pins.Size(); i += 1 )
		{
			if ( pins[ i ].world != world )
			{
				continue;
			}
			dx = pins[ i ].x - pos.X;
			dy = pins[ i ].y - pos.Y;
			d = dx * dx + dy * dy;
			if ( d < bestDist )
			{
				bestDist = d;
				best = i;
			}
		}
		return best;
	}

	// Merchant whose NPC stands next to the player (the opponent of the match just played), or -1.
	private function MerchantPinNextToPlayer( world : string ) : int
	{
		var i : int;
		var npc : CNewNPC;
		var playerPos : Vector = thePlayer.GetWorldPosition();

		for ( i = 0; i < pins.Size(); i += 1 )
		{
			if ( pins[ i ].world != world || !IsNameValid( pins[ i ].tag ) )
			{
				continue;
			}
			npc = theGame.GetNPCByTag( pins[ i ].tag );
			if ( npc && VecDistanceSquared2D( npc.GetWorldPosition(), playerPos ) < 6 * 6 )
			{
				return i;
			}
		}
		return -1;
	}

	private function MarkWon( idx : int )
	{
		if ( FactsQuerySum( "gwm_won_" + pins[ idx ].id ) == 0 )
		{
			FactsAdd( "gwm_won_" + pins[ idx ].id, 1, -1 );
			theGame.GetGuiManager().ShowNotification( "Gwent: " + pins[ idx ].role + " beaten. Marked on the map." );
		}
	}

	// Called on every won match. The game's own records stay the main source; this keeps
	// the map right when another mod changes how Gwent rewards are given (e.g. Gwent overhauls).
	public function OnGwentWon()
	{
		var idx : int;
		var world : string = GwmCurrentWorldKey();

		if ( world == "" )
		{
			return;
		}

		// A merchant standing right next to the player was the opponent.
		idx = MerchantPinNextToPlayer( world );
		if ( idx >= 0 )
		{
			MarkWon( idx );
			return;
		}

		// Anyone else without a game record: the closest pin, with a short radius so quest
		// matches (tournaments, parties) away from fixed players do not mark anyone.
		idx = FindNearest( world, thePlayer.GetWorldPosition(), 15 );
		if ( idx >= 0 && !IsNameValid( pins[ idx ].tag ) && !IsNameValid( pins[ idx ].card ) )
		{
			MarkWon( idx );
		}
	}
}

@addField( CR4Game ) var gwmData : GwmData;

// theGame is const outside its class, so the field is created from a CR4Game method.
@addMethod( CR4Game ) function GwmGetOrCreateData() : GwmData
{
	if ( !gwmData )
	{
		gwmData = new GwmData in this;
		gwmData.Init();
		GwmInitConfig();
	}
	return gwmData;
}

function GwmGetData() : GwmData
{
	return theGame.GwmGetOrCreateData();
}

// Settings from Options > Mods > Gwent Players Map (bin\config\r4game\user_config_matrix\pc\modGwentPlayersMap.xml).
// Unset vars read as "", so defaults are written once; if the menu file is not
// installed the writes are no-ops and the code defaults below still apply.
function GwmInitConfig()
{
	var config : CInGameConfigWrapper = theGame.GetInGameConfigWrapper();
	var changed : bool;

	if ( config.GetVarValue( 'GwentPlayersMap', 'GwmShowPins' ) == "" )
	{
		config.SetVarValue( 'GwentPlayersMap', 'GwmShowPins', "true" );
		changed = true;
	}
	if ( config.GetVarValue( 'GwentPlayersMap', 'GwmShowDefeated' ) == "" )
	{
		config.SetVarValue( 'GwentPlayersMap', 'GwmShowDefeated', "true" );
		changed = true;
	}
	if ( config.GetVarValue( 'GwentPlayersMap', 'GwmIconPlacement' ) == "" )
	{
		config.SetVarValue( 'GwentPlayersMap', 'GwmIconPlacement', "0" );
		changed = true;
	}
	if ( config.GetVarValue( 'GwentPlayersMap', 'GwmDebug' ) == "" )
	{
		config.SetVarValue( 'GwentPlayersMap', 'GwmDebug', "false" );
		changed = true;
	}
	if ( changed )
	{
		theGame.SaveUserSettings();
	}
}

function GwmConfigBool( varName : name, defaultValue : bool ) : bool
{
	var value : string = theGame.GetInGameConfigWrapper().GetVarValue( 'GwentPlayersMap', varName );

	if ( value == "" )
	{
		return defaultValue;
	}
	// The game stores toggles as "true"/"false" or as "1"/"0" depending on how they were set.
	value = StrLower( value );
	return value == "true" || value == "1";
}

// 0 = next to the merchant icon, 1 = replace it, 2 = on top of it.
function GwmIconPlacement() : int
{
	var value : string = theGame.GetInGameConfigWrapper().GetVarValue( 'GwentPlayersMap', 'GwmIconPlacement' );

	if ( value == "" )
	{
		return 0;
	}
	return StringToInt( value );
}

// Map data is per world: Velen and Novigrad share one, Toussaint is "bob".
function GwmWorldKey( path : string ) : string
{
	path = StrLower( path );
	if ( StrContains( path, "winter" ) )
	{
		return "";
	}
	if ( StrContains( path, "novigrad" ) )
	{
		return "novigrad";
	}
	if ( StrContains( path, "skellige" ) )
	{
		return "skellige";
	}
	if ( StrContains( path, "prolog_village" ) )
	{
		return "prolog_village";
	}
	if ( StrContains( path, "bob" ) )
	{
		return "bob";
	}
	return "";
}

function GwmCurrentWorldKey() : string
{
	return GwmWorldKey( theGame.GetWorld().GetDepotPath() );
}

// Vanilla map pin types that mark a shop or service NPC.
function GwmIsShopPinType( type : name ) : bool
{
	return type == 'Shopkeeper' || type == 'Blacksmith' || type == 'Armorer' || type == 'Innkeeper'
		|| type == 'Herbalist' || type == 'Alchemic' || type == 'Enchanter' || type == 'Hairdresser'
		|| type == 'Prostitute' || type == 'WineMerchant' || type == 'DyeMerchant' || type == 'Cammerlengo'
		|| type == 'Archmaster' || type == 'BoatBuilder';
}

// Distance in metres the card is moved east of the merchant icon in "next to" mode
// (about one icon width at the usual city zoom).
function GwmSideOffset() : float
{
	return 18;
}

@wrapMethod( CR4Player ) function SetGwintMinigameState( minigameState : EMinigameState )
{
	var wasWon : bool = GetGwintMinigameState() == EMS_End_PlayerWon;

	wrappedMethod( minigameState );

	// The gwent menu and quest scenes can both report the same result.
	if ( minigameState == EMS_End_PlayerWon && !wasWon )
	{
		GwmGetData().OnGwentWon();
	}
}

@wrapMethod( CR4MapMenu ) function UpdateEntityPins( out flashArray : CScriptedFlashArray ) : void
{
	var data          : GwmData;
	var mapManager    : CCommonMapManager;
	var worldPath     : string;
	var worldKey      : string;
	var instances     : array< SCommonMapPinInstance >;
	var shopPos       : array< Vector >;
	var shopIds       : array< int >;
	var hiddenIds     : array< int >;
	var i, j, k       : int;
	var placement     : int;
	var showDefeated  : bool;
	var pos           : Vector;
	var playerPos     : Vector;
	var obj           : CScriptedFlashObject;
	var defeated      : bool;
	var pinType       : string;
	var d, bestDist   : float;
	var showDebug     : bool;
	var added         : int;

	wrappedMethod( flashArray );

	showDebug = GwmConfigBool( 'GwmDebug', false );
	if ( !GwmConfigBool( 'GwmShowPins', true ) )
	{
		if ( showDebug )
		{
			GwmDebugNote( "markers are switched off in the options" );
		}
		return;
	}

	data = GwmGetData();
	mapManager = theGame.GetCommonMapManager();
	worldPath = mapManager.GetWorldPathFromAreaType( m_shownArea );
	worldKey = GwmWorldKey( worldPath );
	if ( worldKey == "" )
	{
		if ( showDebug )
		{
			GwmDebugNote( "no Gwent players on this map (" + worldPath + ")" );
		}
		return;
	}

	placement = GwmIconPlacement();
	showDefeated = GwmConfigBool( 'GwmShowDefeated', true );

	// Shop icons the vanilla map is showing, to line the cards up with (or hide them).
	if ( placement != 2 )
	{
		instances = mapManager.GetMapPinInstances( worldPath );
		for ( i = 0; i < instances.Size(); i += 1 )
		{
			if ( ( instances[ i ].isDiscovered || instances[ i ].isKnown ) && GwmIsShopPinType( instances[ i ].type ) )
			{
				shopPos.PushBack( instances[ i ].position );
				shopIds.PushBack( NameToFlashUInt( instances[ i ].tag ) );
			}
		}
	}

	playerPos = thePlayer.GetWorldPosition();
	for ( i = 0; i < data.pins.Size(); i += 1 )
	{
		if ( data.pins[ i ].world != worldKey )
		{
			continue;
		}

		defeated = data.IsDefeated( i );
		if ( defeated && !showDefeated )
		{
			continue;
		}
		if ( defeated )
		{
			pinType = data.iconDefeated;
		}
		else
		{
			pinType = data.iconNormal;
		}

		pos = Vector( data.pins[ i ].x, data.pins[ i ].y, 0 );

		// Merchant with a shop icon close by: stand next to it or take its place.
		j = -1;
		if ( IsNameValid( data.pins[ i ].tag ) )
		{
			bestDist = 30 * 30;
			for ( k = 0; k < shopPos.Size(); k += 1 )
			{
				d = VecDistanceSquared2D( pos, shopPos[ k ] );
				if ( d < bestDist )
				{
					bestDist = d;
					j = k;
				}
			}
		}
		if ( j >= 0 )
		{
			pos = shopPos[ j ];
			if ( placement == 0 )
			{
				pos.X += GwmSideOffset();
			}
			else if ( placement == 1 )
			{
				hiddenIds.PushBack( shopIds[ j ] );
			}
		}

		obj = GetMenuFlashValueStorage().CreateTempFlashObject( "red.game.witcher3.data.StaticMapPinData" );
		// Fixed offset keeps our ids away from the name hashes vanilla pins use.
		obj.SetMemberFlashUInt(   "id",            1196883968 + data.pins[ i ].id );
		obj.SetMemberFlashUInt(   "areaId",        NameToFlashUInt( m_shownArea ) );
		obj.SetMemberFlashUInt(   "journalAreaId", NameToFlashUInt( mapManager.GetJournalAreaByPosition( m_shownArea, pos ) ) );
		obj.SetMemberFlashNumber( "posX",          pos.X );
		obj.SetMemberFlashNumber( "posY",          pos.Y );
		obj.SetMemberFlashString( "type",          pinType );
		// The patched map file files "GwentPlayer" under its "Gwent" filter (and "Default").
		// One filtered type for beaten and not beaten keeps them in a single legend row.
		obj.SetMemberFlashString( "filteredType",  "GwentPlayer" );
		obj.SetMemberFlashNumber( "radius",        0 );
		obj.SetMemberFlashBool(   "isFastTravel",  false );
		obj.SetMemberFlashBool(   "isQuest",       false );
		obj.SetMemberFlashBool(   "isPlayer",      false );
		obj.SetMemberFlashBool(   "isUserPin",     false );
		if ( IsCurrentAreaShown() )
		{
			obj.SetMemberFlashNumber( "distance", VecDistanceSquared2D( playerPos, pos ) );
		}
		else
		{
			obj.SetMemberFlashNumber( "distance", 0 );
		}
		// The legend row takes its text from the label, so the label is the same for every card.
		obj.SetMemberFlashString( "label", "Gwent player" );
		obj.SetMemberFlashString( "description", data.pins[ i ].role + " - " + GwmStatusText( data.pins[ i ], defeated ) );
		flashArray.PushBackFlashObject( obj );
		added += 1;
	}

	// "Replace" mode: drop the vanilla shop icons the cards now stand for.
	if ( hiddenIds.Size() > 0 )
	{
		for ( i = flashArray.GetLength() - 1; i >= 0; i -= 1 )
		{
			obj = flashArray.GetElementFlashObject( i );
			if ( obj && hiddenIds.Contains( obj.GetMemberFlashUInt( "id" ) ) )
			{
				flashArray.RemoveElement( i );
			}
		}
	}

	if ( showDebug )
	{
		if ( data.CardIconsLoaded() )
		{
			GwmDebugNote( added + " markers on " + worldKey + ", map file loaded" );
		}
		else
		{
			GwmDebugNote( added + " markers on " + worldKey + ", MAP FILE NOT LOADED (cards are invisible)" );
		}
	}
}

// "Debug info" option: one line on screen each time the world map builds its markers.
function GwmDebugNote( text : string )
{
	theGame.GetGuiManager().ShowNotification( "Gwent Players Map " + GwmVersion() + ": " + text );
}

// Quest players are judged by their card, so say that; everyone else is beaten or not.
function GwmStatusText( pin : GwmPin, defeated : bool ) : string
{
	if ( IsNameValid( pin.card ) && !IsNameValid( pin.tag ) )
	{
		if ( defeated )
		{
			return "Card obtained.";
		}
		return "Card not obtained yet.";
	}
	if ( defeated )
	{
		return "Already beaten.";
	}
	return "Not beaten yet.";
}
