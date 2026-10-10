class_name FrameStats
extends RefCounted
## Rolling frame-time statistics over the last WINDOW frames, for the
## performance overlay (ADR-0007, Q16).

const WINDOW: int = 120
## ADR-0007: 120 fps on the minimum spec.
const BUDGET_MS: float = 1000.0 / 120.0

var _samples: PackedFloat64Array = PackedFloat64Array()
var _next: int = 0


func add(frame_ms: float) -> void:
	if _samples.size() < WINDOW:
		_samples.append(frame_ms)
	else:
		_samples[_next] = frame_ms
	_next = (_next + 1) % WINDOW


func count() -> int:
	return _samples.size()


func average_ms() -> float:
	if _samples.is_empty():
		return 0.0
	var total: float = 0.0
	for sample: float in _samples:
		total += sample
	return total / _samples.size()


func max_ms() -> float:
	var highest: float = 0.0
	for sample: float in _samples:
		highest = maxf(highest, sample)
	return highest


## Frames in the window that took longer than the 120 fps budget.
func over_budget() -> int:
	var over: int = 0
	for sample: float in _samples:
		if sample > BUDGET_MS:
			over += 1
	return over
