asap issues:
 - when doing game:throw() pass which element to del, otherwise it might be "cleaning" existing elements ^^
   this will require returning index from elements._add()
 - pass absolute position when throwing...
 - make throwing work again when disable_animation = true

tech issues:
 - drop dumb args from astar handlers

random list of *things*
 - (remotely activated) traps, mines
 - granades
 - minimap - might be problematic when it comes to elements :/
 - swim ability - different speed in water and on ground
 - wild idea action queue items replacement - i.e. in the middle of move, but if hit by player, could replace action with strike-back (and proper action points progress) - not sure if good idea
