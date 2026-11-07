class_name KettlebridgeMap
extends RefCounted
## Kettlebridge's accepted map (docs/design/area-kettlebridge.md; accepted by
## the lead 2026-11-07): one character per 2 x 2 tiles. Kept in code so
## exports carry it; a test checks it still matches the design doc's
## (docs/design/images/kettlebridge.txt).

## What blocks walking here: woods, buildings, rails and walls, the river,
## the island, the stalls, the rostrum, gravestones, the winch house, the
## barge. The raised bridge (`Y`) is the barrier, solid until lowered.
const SOLID: String = "tH#K~ihkR+Zn"
const BARRIER: String = "Y"

const ROWS: Array[String] = [
	"ttttttttttttttttttttttttttttttt==ttttttttttttttttttttttttttttttt",
	"t,v,v,,vv,vv,,hh,v,,,,,v,v,v,,,==vv,v,vv,,,,,,,,hh,,vv,,v,,v,,vt",
	"t,,,,,,,v,v,v,hh,,,,,vv,,,,,,,,==v,,,v,,v,,,,,v,hh,,,,,vv,v,,,vt",
	"t,v,vv,,,v,vv,hh,,,,,v,v,vv,,,,==1v,,,vv,,v,,v,v,,,,v,,,,,,v,vvt",
	"t,,,v,,,v,vvv,,,v,,,,,vv,,,,v,,==v,,,,,v,vvvv,,vhh,,,v,,v,,,,,,t",
	"t,,v,v,,v,,,,,hh,,,vv,,,,,,,,,v==,v,,,,,v,vvv,v,hh,,,,,vv,v,,v,t",
	"t,vv,,v,,,,v,vhh,,v,,,v,v,,v,v,==,vv,vv,v,vv,,,vhh,v,,,,,,,vvv,t",
	"tt.............................==.............................tt",
	"t.============================================================.t",
	"t.,,,,,,,,,,,,,,,,.==..HHHHHHH2==.HHHHHHH.==.KKKKKK.HHHHHHHHH.tt",
	"t.,###############.==..HHHHHHH.==.HHHHHHH.==.KKKKKK.HHHHHHHHH..t",
	"tt,#OOOOOOOOOOOOO#.==HH__________________.==.KKKKKK.HHHHHHHHH.tt",
	"tt,#OOOOOO7OOOOOO#.==HH4_________________.==CKKKKKK....E.......t",
	"tt,#OOOOOOOOOOOOO#.==HH__k__k__k__k__k___.==.KKKKKK............t",
	"t.,#OOOOOOOOOOOOO#.==.._____3____________.==qqqqqqqqqqqq#......t",
	"t.,#OOOOOORROOOOO.,==HH__________________.==q+q+q+q+q+qq#HHHH..t",
	"tt,#OOOOOOOOOOOOO.6==HH__k__k__k__k__k___.==qqqqqqqqqqqq#HHHH..t",
	"t.,#OOOOOOOOOOOOO#,==HH5_________________.==q+q+q+q+q+qq#HHHH..t",
	"t.,#OOOOOOOOOOOOO#,==HH___________G______.==qqqqqqDqqqqq#HHHH..t",
	"t.,#OOOOOOOOOOOOO#.==HHHHHHHHH.==.HHHHHHH.==q+q+q+q+q+qq#HHHH.tt",
	"t.,#OOOOOOOOOOOOO#.==HHHHHHHHH.==.HHHHHHH.==qqqqqqqqqqqq#HHHH..t",
	"tt,###############.==HHHHHHHHH.==.ZZ......==#####.#######......t",
	"tt==========F=================8==A==9=========B===============.t",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~YY~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~YY~~~~~~~~~~~nnnnnn~~~~~~~~~~~~~~",
	"~~~~~~~~~~iiii~~~~~~~~~~~~~~~~~YY~~~~~~~~~~~nnnnnn~~~~~~~~~~~~~~",
	"~~~~~~~~~~iiii~~~~~~~~~~~~~~~~~YY~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~YY~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~YY~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"tvvvvvv,v,v,,vvv,vvvvvvv,vvvvvv==vv,vvv,vvvvvvvv,,,,vvvv,vvvvvvt",
	"t,vvvvvvvvvvvvvv,,v,vvvvv,v,vvv==v,,,vvvvvvvvvvvvvvvv,vv,vvvvvvt",
	"tvvv,vvvvvvvvvvvv,vvv,,,vv,,vvv==,,,,vvvvvv,,vv,vvvvvvv,,vvv,,,t",
	"tv,v,vvvvv,vv,vvvv,vvvvvvvvvvvv==vv,vvvv,vvvvv,vvv,,vv,v,v,vvvvt",
	"t,vvvvvvv,vv,vv,v,vvvvvvv,,vvvv==,v,,vvv,,v,vvvvvvvvvv,vvvv,vvvt",
	"tvv,,v,v,,,v,vvvvvvvvvvvv,vvvvv==vvvvv,vv,vv,v,vvvvvvv,v,vvvvvvt",
	"ttttttttttttttttttttttttttttttt==ttttttttttttttttttttttttttttttt",
]
