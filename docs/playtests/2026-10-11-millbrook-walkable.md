# Playtest: Millbrook, walkable

**For:** the project lead. **Why:** the map, the rosters and the camera rules
are tested, but how it feels to walk, explore and fight there can only be
judged by playing.

**Build:** the PR build of `millbrook-walkable`. From the title, F2 until
Millbrook, or launch with `--start-scene millbrook`. F8 jumps to dusk or
dawn; F9 speeds time up; F6 makes creatures passive; F7 changes the second
weapon (the bow is not otherwise in Millbrook yet).

**Setup:** machine, screen (size and shape), controller or keyboard.

## Checks

Write a short note for each: fine / problem (what).

1. **The camera (ADR-0015):** walking, attacking and dodging, does the
   camera feel steady? Does the small dead zone stop it twitching? Does it
   ever lag behind enough to bother you? Result:
2. **The camera at the edges:** walk to each edge and corner. It should
   stop without showing past the map. Fine on your screen shape? Result:
3. **Finding your way:** without the map, can you find the green, the
   orchard, the wheat field (through its gap), the mill, the footbridge to
   the yard and the floodwater? Result:
4. **The encounter order:** going down the lane and around, does it feel
   like it teaches one thing at a time: a hedgehog, then mice, then rooks,
   toads, the mill's nest, then Grist? Too many creatures, too few? Result:
5. **Grist in the yard:** do the yard's props (sacks, millstones, wallow)
   work as they did in the arena, with the fence and the cottage around?
   Result:
6. **Night (F8):** does Millbrook feel different at night: the tint, the
   sight ring, the moths at the fungus and fireflies? Is 7 tiles of sight
   too little or too much? Result:
7. **Creatures appearing:** at dusk and dawn, do you ever see a creature
   pop in or out? (They should only change out of sight.) Result:
8. **Falling:** let something defeat you. Waking at the lane's top the next
   morning: does it feel like a fair cost? Result:
9. **Performance:** on your machines, any stutter while walking the map
   (F3 shows frame times)? Result:

## Report back

Notes per check. Layout or balance changes come back as a PR for your
approval.
