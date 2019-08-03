 *dev does the complete roguelike toutorial

### repo clone

    git clone --recursive https://github.com/gim913/roguelike-complete-tutorial.git

If you forgot to pass `--recursive`:

    git submodule update --init

### Table of contents

   * [Week 1](#week-1)
      * [World architecture](#world-architecture)
   * [Week 2](#week-2)
   * [Week 3](#week-3)
   * [Week 4](#week-4)
   * [Week 5](#week-5)
   * [Week 6](#week-6)
   * [Week 7](#week-7)

### Week 1

I'll be using [love2d](https://love2d.org).
I'm using vscode with [love2d support extension](https://marketplace.visualstudio.com/items?itemName=pixelbyte-studios.pixelbyte-love2d)

Nice part is love2d already does basic game loop.

More problematic part is that to keep UI nice and responsive when doing some longer operations
(i.e. level generation) some nice tricks will be needed (read: state-machines everywhere)

I'm passing rng everywhere, reason is pretty obvious - determinism / repeatability.

I don't have exact idea what roguelike it will be, but there are two things I want:
 * instead of ascending/descending, player will be going from bottom to top (like in shoot'em ups)
 * mechanics *might* be similar to posession, where player needs to switch to new characters
   to progress - not sure about this one yet

some random ideas moved to todo.md

#### World architecture

Few globally accessible lists:
 * entities - all entities (players, NPCs, possibly others), one entity per cell
 * elements - some world objects, that player can interact with
 * map object - that most likely will **only** include terrain/walls,
   level generator will prepare that object, once it's done generating

(not sure about items yet, they might be elements)

Both elements and entities have position and they can occupy same cell.

### Week 2

Week 2, part 2 deals with render, map and Entity - I got most of that done.
I mentioned map will contain only tile info, blocking elements will
be separately inside elements so time to do this.

Part 3 deals with generating a dungeon. In my case this will be houses generation.
I'm not sure yet if I should do some fancy procedural generator or rather just use some
templates as mentioned in map prefabs.

I spent some time doing tiles beautification. It doesn't work perfectly, but it's pretty neat.
I got river and a bridge.

Now it would probably make sense not to let player allow walking on the river,
but I'll have to redo how data kept by map is kept (separate property 'passable' from tileId)

### Week 3

I'm a bit behind the schedule when it comes to world generation.

things done:
 * allow to enter the house by adding element:setPassable()
 * spawn some dummies
 * FOV + LOS
 * bumping onto enemies, giving some dummy damage, die()
 * fog of war


### Week 4

Last week went pretty good. There are small issues with entities display, that I need to check.
Plan for this week:
 * add in-game debug console - srsly, I need to see what's happening, logging things on a console is less than optimal
 * add a-star - plan the path towards goal
 * add mouse support (want to let the player entity to use a-star)
 * enemy movement
  * use a-star (go towards player or nearby location)
  * queue actions - wild idea action queue items replacement - i.e. in the middle of move, but if hit by player, could replace action with strike-back (and proper action points progress) - not sure if good idea
 * add "scenes" / scene-manager - to handle initial menu -> game transition + keyboard, display etc.
 * some basic in-game UI:
  * inventory
  * modal/non-modal dialogs - not sure if needed
  * "voice" messages

### Week 5

Week 4 went pretty nicely and I feel it was pretty productive.
Week 4 as outlined in tutorial was using composition, right now I somewhat ignored that part,
so it's not super beauty, but it shouldn't be hard to change it later

This week I have super limited time, so probably things will get delayed by one week.

Very short plan is to:
 * add ability to eXamine with a keyboard
 * add some dumb inventory (for all entities, reason is there will be enemies with non-empty inventory),
 * generate lot of items as elements (really super dumb, polishing will come much later)
 * let the player pick up items

### Week 6

Due to lack of time, I'm a bit behind.

Still want to do bit more around Part 8 and Part 9 of tutorial.

Need to modify keyboard handling but can postpone it till later.

### Week 7

Last week had to throw away whole imgui, it wasn't wisest decision to use it.
I also changed a lot regarding keyboard handling.

I have some crude inventory / equipment management:
 * grab
 * move from inv to equipment
 * drop
 * select active weapon - there's UI hint, but doesn't actually change anything yet

Added some 'modals'.

Working on throwing items, so I think I'm somewhere around part 9.

Got throwing and movement animation

