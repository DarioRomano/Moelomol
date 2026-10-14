# Playtest: the web preview on GitHub Pages

1. **Build:** the latest `main`, at <https://darioromano.github.io/Moelomol/>,
   once Settings > Pages > Source is "GitHub Actions" and the "Web preview"
   workflow has run (Actions > Web preview > Run workflow, if it ran before
   the setting changed).
2. **Setup:** a desktop browser (note which: Chrome, Firefox, Safari, Edge),
   keyboard; a controller for check 5 if one is at hand.

## Checks

1. The page loads and the title screen appears. Note roughly how long it took.
   Result:
2. The title shows no Quit button (a web page cannot quit). Result:
3. New game starts at the farm; walking with W A S D works after clicking into
   the page. Result:
4. Sleep in the bed (it saves), reload the page: Continue is offered and
   resumes at the bed. (Browser saves were never designed for; a fail here is
   expected information, not a bug to fix now.) Result:
5. A controller moves the player and presses menu buttons. Result:
6. Pixels look crisp, not blurred, at the browser's normal size and in
   fullscreen. Result:

## Report back

Write results on the Result lines; the engineer turns failures into notes or
open questions.
