class_name MillbrookMap
extends RefCounted
## Millbrook's layout as accepted by the lead (2026-10-11): the map from
## docs/design/area-millbrook.md, one character per 2 x 2 tiles (AreaMap).
## Kept in code so exports carry it; tests check it still matches the design
## doc's map (docs/design/images/millbrook.txt).

const ROWS: Array[String] = [
	"ttttttttttttttttttttttttttt==ttttttttttttttttttttttttttt",
	"tt.tt.tt.tt..ttt.....tt..th=1httt.tt.tt.tt.t...ttttttttt",
	"tt........................h==h.....KKKK................t",
	"t............SSSS..........h==h....KKKK7.HH..e.e.e.....t",
	"tt.a.a.a.*...SSSS4..........h==h...KKKK..HH...........tt",
	"tt...........SSSS...........h==2...KKKK====...e.e.e...tt",
	"tt.a.*.a.a....=.............h==h...====...............tt",
	"tt............=............h==h...=............G.....~~~",
	"tt.a.a.a.a....=...........h==h..H=H..............~~~~~tt",
	"tt............=..HHH.......==...=HH.......~~~~~~~~~~...t",
	"tt.a.a.a.a....=..HHH.......==..=..........~~~~~~~~~~...t",
	"tt..PPP.......=......,,,,,,==,,,,,........~~~~~~~~~~..tt",
	"tt.aPPPC.a..=========,,,,,,==,,,,,..HHH...~~~~~~ii~~..tt",
	"tt...................,,,,3,==,,,,,..HHH...~~~~~E~~~~..tt",
	"t..a.a.a.*....ggg....,,,,,,==,,,,,...ggg..~~~~~~~~~~..tt",
	"tt...........5gggHHH.,,,,,,==,,,,,...ggg..~~~~~~~~~~..tt",
	"tt.*.a.a.a....gggHHH.,,,,,,==,,,,,.==.MMMM~~~~~~~~~~..tt",
	"t.............ggg..........==........=MMMMX............t",
	"t.............6c.......HHH.==........9MMMM~~..........tt",
	"t.hhhhh.hhhhh..........HHH.==s8.......=...~~.#########tt",
	"ttuuuuuyyyyyh..............==..........==bbb=#..HHH..#.t",
	"t.uuuuuyyyyyhw.w...wwww...w==..w..ww.w.w.~A..=..HHH..#tt",
	"ttuuuuuyyyyyhwwwwwwwwwwwwwwwwwwwwwwwwwww~~~~.#.....B.#tt",
	"t.uuuuuyyyyyhwwwwwwwwwwwwwwwwwwwwwwwwwwwww~~.#.......#tt",
	"ttuuuuuyDyyyhwwwwwwwwwwwwwwwwwwwwwwwwwwwww~~.#.......#tt",
	"ttuuuuuyyyyyhwwwwwwwwwwwwwwwwwwwwwwwwwwwww~~.#.......#tt",
	"ttuuuuuyyyyyhwwwwwwwwwwwwwwwwwwwwwwwwwwwww~~.#########.t",
	"ttuuuuuyyyyyhwwwwwwwwwwwwwwwwwwwwwwwwwwwww~~...........t",
	"t.uuuuuyyyyyhwwwwwwwwwwwwwwwwwwwwwwwwwwwww~~...........t",
	"tt..........h..wv.vvww.w.ww==wv.vwv.w.ww..~~..........tt",
	"t.tttt.t...tt.vvvvvvvvvvvvv==Fvvvvvvvvvvvv~~t..t.ttttttt",
	"ttttttttttttttttttttttttttt==ttttttttttttt~~tttttttttttt",
]
