# Gwent Players Map

A small mod for **The Witcher 3: Wild Hunt (Remastered / Next Gen)** that puts every Gwent player you can
challenge on the world map: shopkeepers, blacksmiths, armorers, innkeepers, herbalists and the
other merchants who will play you for a card. The goal is simple: find who still has a card for
you, so you can grow your deck.

Players you have already beaten are drawn greyed out, the same way the game greys out places you
have cleared.

![Novigrad](screenshots/novigrad.jpg)

| Not beaten yet | Already beaten |
| --- | --- |
| ![Not beaten](screenshots/not-beaten.jpg) | ![Beaten](screenshots/beaten.jpg) |

## Features

- A card icon on the world map for each Gwent player: white while you can still win something,
  grey once you have beaten them.
- Hover a card to see who it is (for example "Gwent: Blacksmith") and whether they are beaten.
- Works with your current save: merchants you beat before installing the mod already show as
  beaten (see "How it works").
- Covers White Orchard, Velen, Novigrad, Oxenfurt, Skellige and Toussaint, including a few
  merchants added by Hearts of Stone and Blood and Wine.
- Options menu: hide the markers, hide the players already beaten (show only the ones left), and
  choose where the card goes relative to the merchant's own map icon.
- Everything is in English, in every game language.

## Requirements

- The Witcher 3: Wild Hunt, current version: the **Remastered edition** (also called Next Gen,
  patch 4.04 or newer). Remastered and Next Gen are the same branch of the game. The old 1.32
  version is **not** supported: the scripts use annotations (`@wrapMethod`, `@addMethod`,
  `@addField`) that 1.32 does not have.
- Tested on the Steam Remastered edition (DX12).

## Installation

1. Download `GwentPlayersMap.zip` from the
   [Releases page](https://github.com/mateusands/witcher3-gwent-players-map/releases/latest).
2. Extract it into your game folder (the folder that contains `bin` and `content`). It adds:

       mods\modGwentPlayersMap\                                         (the mod)
       bin\config\r4game\user_config_matrix\pc\modGwentPlayersMap.xml   (options menu)

3. Start the game. The scripts are compiled on the first start.

No game file is replaced on disk. The options menu file is optional: without it the mod works
with the default settings.

**The options menu does not show up?** Some setups only load the menu files listed in
`bin\config\r4game\user_config_matrix\pc\dx11filelist.txt` and `dx12filelist.txt`. If those
files exist in your game, add this line to both:

    modGwentPlayersMap.xml;

## Options

**Options > Mods > Gwent Players Map**

![Options](screenshots/options.jpg)

- **Show Gwent markers**: turns all the cards on the map on or off.
- **Show players already beaten**: turn it off to see only the players you still have to beat.
- **Icon placement**:
  - *Next to the merchant icon*: the card sits right next to the shop icon.
  - *Replace the merchant icon*: the shop icon is hidden and only the card is shown.
  - *On top of the merchant icon*: the card is drawn over the shop icon.

## How it works

**Where the players are.** The list of Gwent players comes from the interactive map at
[witcher3map.com](https://witcher3map.com) (its "Gwent Player" layer). Those positions were
converted to in-game coordinates and then checked against the game's own data: the position of
each merchant was read from the game's world files and used where available, and a few merchants
that the interactive map does not list were added.

**Who is beaten.**

- *Merchants* (shopkeepers, smiths, innkeepers...): the first time you beat one, the game itself
  records it in your save. The mod reads that record, so merchants beaten before you installed
  the mod are shown correctly too.
- *Quest players* (for example the Bloody Baron, Vimme Vivaldi, Stjepan in Oxenfurt, Olivier at
  the Kingfisher, the Inn at the Crossroads innkeeper, Gremist): the marker says "Card obtained"
  or "Card not obtained yet", based on whether their unique card is in your inventory.
- *Anyone else* (a handful of players the game keeps no record for): the mod marks them when you
  win a match right next to their marker, from the moment the mod is installed.

## Compatibility

- **Gwent overhauls (Gwent Redux and similar):** the markers work the same. Merchants beaten
  before installing this mod are detected through the game's own reward records; if an overhaul
  changes how rewards are given, those may not show as beaten. Every match you win against a
  merchant (standing right next to you) is also recorded by this mod, so new wins are always
  marked.
- **Script hooks:** `CR4MapMenu.UpdateEntityPins` (adds the cards to the world map) and
  `CR4Player.SetGwintMinigameState` (notices a won match), both through `@wrapMethod`, plus a
  field and a method added to `CR4Game`. No vanilla script file is replaced, so Script Merger is
  not needed.
- **Map mods:** any mod that replaces `panel_worldmap.redswf` conflicts with this one (see below).

## Troubleshooting

- **Nothing shows on the map:** check that the files ended up exactly at
  `<game>\mods\modGwentPlayersMap\content\scripts\local\gwm.ws` (a mod manager sometimes adds
  an extra folder level), and that the game shows no script compilation error on start.
  Also check *Options > Mods > Gwent Players Map > Show Gwent markers*.
- **Still not working:** open an issue or comment with your game version, how you installed the
  mod, any error message and your other mods.

## Known limitations

- **Not every player is on the map.** The list comes from the interactive map plus what could be
  matched in the game files. Some players may be missing, and a few markers may be a little off
  their exact spot. The focus is the merchants, blacksmiths, innkeepers and other fixed players
  who give you a card; one-off quest matches (tournaments, story scenes) are not marked.
- **Three markers have no game record:** Elsa (White Orchard innkeeper), an innkeeper in Larvik
  and the blacksmith in Fyresdal. They only turn grey when you beat them with the mod installed.
- **Conflicts with other map mods.** The mod ships a modified copy of the game file
  `gameplay\gui_new\swf\worldmap\panel_worldmap.redswf` (inside `blob0.bundle`) to add the card
  icon. Any other mod that replaces this same file is incompatible: only one of them will work.
- **Game updates.** A future patch that changes the world map may break the mod. If the map
  misbehaves after an update, uninstall the mod until there is a fix.
- **Limited testing.** Tested on the Steam Remastered edition (DX12), on Linux through Proton, in
  Brazilian Portuguese, with a small number of other mods. Keep backups of your saves.

## Uninstallation

Delete `mods\modGwentPlayersMap` and
`bin\config\r4game\user_config_matrix\pc\modGwentPlayersMap.xml` (and the
`modGwentPlayersMap.xml;` line, if you added it to `dx11filelist.txt`/`dx12filelist.txt`).

The mod only writes a few small facts to your save (for the "anyone else" players above), which
the game ignores once the mod is removed, so it can be uninstalled at any time.

## AI disclosure

This mod was made with an AI assistant (Claude, by Anthropic): the scripts, the data extraction
and the map icon were written by the AI, and the mod was tested in-game by the author.

## Credits

- Gwent player locations: [witcher3map.com](https://witcher3map.com) /
  [untamed0/witcher3map](https://github.com/untamed0/witcher3map) and its contributors.
- [Gwent Card Notification](https://www.nexusmods.com/witcher3/mods/13409) by funkyblackcat,
  used as a reference for the options menu, string files and bundle layout.
- The Witcher 3 and all its assets belong to CD PROJEKT RED.
