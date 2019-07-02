## *dev does the complete roguelike toutorial

### repo clone

    git clone --recursive https://github.com/gim913/roguelike-complete-tutorial.git

If you forgot to pass `--recursive`:

    git submodule update --init

### Table of contents

   * [Week 1](#week-1)
      * [World architecture](#world-architecture)
   * [Week 2](#week-2)

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

some random ideas:
 * (remotely activated) traps, mines
 * granades

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
