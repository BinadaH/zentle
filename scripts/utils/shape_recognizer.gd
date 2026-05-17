class_name ShapeRecognizer

enum SHAPES{
	CIRCLE,
	RECTANGLE,
	ELLIPSE,
	SEGMENT,
	SCRATCH,
	NONE
}

class ShapeRecognizerResult:
	var points: PackedVector2Array
	var recognized: bool
	var shape: SHAPES
	var center: Vector2
	var bounding_box: Rect2
	
	func _init(points: PackedVector2Array, recognized: bool, shape: SHAPES, bounding_box = Rect2(), center: Vector2 = Vector2()):
		self.points = points
		self.recognized = recognized
		self.shape = shape
		self.center = center
		self.bounding_box = bounding_box

func is_scratch(points: PackedVector2Array, length: float) -> ShapeRecognizerResult:
	var result = ShapeRecognizerResult.new(points, false, SHAPES.SCRATCH)
	if points.size() < 10 || length == 0: return result
	
	var rect = EditorFuncs.get_points_rect(points)
	result.bounding_box = rect
	result.recognized = length / (rect.size.x + rect.size.y) > 3.5
	return result

func get_shape(points: PackedVector2Array, checking_iter: int = 1) -> ShapeRecognizerResult:
	var result = ShapeRecognizerResult.new(points, false, SHAPES.NONE)
	if points.size() < 2: return result
	
	var snap_threshold = 25.0
	if is_closed(points, checking_iter):
		var area = get_area(points)
		var length = get_length(points)
		var bounding_box = EditorFuncs.get_points_rect(points)
		var bounding_area = bounding_box.get_area()
		if bounding_area == 0: return result
		
		var snapped_pos = EditorFuncs.get_grid_pos(bounding_box.position)
		var snapped_end = EditorFuncs.get_grid_pos(bounding_box.end)
		
		if bounding_box.position.distance_to(snapped_pos) < snap_threshold:
			bounding_box.position = snapped_pos
		if bounding_box.end.distance_to(snapped_end) < snap_threshold:
			bounding_box.end = snapped_end
		
		result.center = bounding_box.get_center()
		result.bounding_box = bounding_box
		
		var avg_corner_dist = get_corners_distance_score(points, bounding_box)
		var threshold = bounding_box.size.length() * 0.1 * checking_iter
		if avg_corner_dist < threshold:
			#RECT
			if abs(area / bounding_area - 1) < 0.15:
				result.points = get_rect_points(bounding_box)
				result.recognized = true
				result.shape = SHAPES.RECTANGLE
				return result
		else:
			#OVAL / CIRCLE
			var half_dims = bounding_box.size / 2
			var a_ellipse = PI * half_dims.x * half_dims.y
			
			if abs(area / a_ellipse - 1) < 0.2:
				var center = bounding_box.get_center()
				if abs(half_dims.x / half_dims.y - 1) < 0.2:
					result.points = get_ellipse_points(center, half_dims.x, half_dims.x)
					result.shape = SHAPES.CIRCLE
				else:
					result.points = get_ellipse_points(center, half_dims.x, half_dims.y)
					result.shape = SHAPES.ELLIPSE
				result.recognized = true
				return result
	else:
		if check_for_segment(points, checking_iter):
			var start = points[0]
			var end = points[points.size() - 1]
			
			var s_start = EditorFuncs.get_grid_pos(start, EditorOptions.shape_snap_tolerance)
			var s_end = EditorFuncs.get_grid_pos(end, EditorOptions.shape_snap_tolerance)
			
			if start.distance_to(s_start) < snap_threshold: start = s_start
			if end.distance_to(s_end) < snap_threshold: end = s_end
			
			result.points = PackedVector2Array([start, end])
			result.recognized = true
			result.shape = SHAPES.SEGMENT
			return result
	
	return result
	
func get_corners_distance_score(points: PackedVector2Array, rect: Rect2) -> float:
	var corners = [
		rect.position,                               # Top-Left
		Vector2(rect.end.x, rect.position.y),        # Top-Right
		rect.end,                                    # Bottom-Right
		Vector2(rect.position.x, rect.end.y)         # Bottom-Left
	]
	
	var total_min_distance = 0.0
	
	for corner in corners:
		var min_dist_for_this_corner = INF
		for p in points:
			var d = corner.distance_to(p)
			if d < min_dist_for_this_corner:
				min_dist_for_this_corner = d
		
		total_min_distance += min_dist_for_this_corner
		
	return total_min_distance / 4.0
	
func is_closed(points: PackedVector2Array, checking_iter: int):
	return beg_end_dist(points) < 25 * checking_iter

func get_rect_points(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([ rect.position, 
											Vector2(rect.end.x, rect.position.y),
											rect.end,
											Vector2(rect.position.x, rect.end.y),
											rect.position
											])
											
func get_ellipse_points(center: Vector2, a: float, b: float, resolution: int = 64) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(resolution + 1):
		var angle = i * TAU / resolution
		
		var x = center.x + a * cos(angle)
		var y = center.y + b * sin(angle)
		
		points.append(Vector2(x, y))
		
	return points

func calc_centroid(points: PackedVector2Array):
	var c = Vector2()
	for point in points:
		c += point
		
	c /= points.size()
	return c

	
func check_for_segment(points: PackedVector2Array, checking_iter: int) -> bool:
	return beg_end_dist(points) / get_length(points) > pow(0.98, checking_iter)

func beg_end_dist(points: PackedVector2Array):
	return (points[0] - points[points.size() - 1]).length()

func get_length(points: PackedVector2Array):
	var length = 0
	for i in range(points.size() - 1):
		length += (points[i] - points[i + 1]).length()
		
	return length

func get_area(points: PackedVector2Array) -> float:
	var n = points.size()
	if n < 3:
		return 0.0
	
	var area = 0.0
	
	for i in range(n):
		var p1 = points[i]
		var p2 = points[(i + 1) % n]
		
		area += (p1.x * p2.y) - (p2.x * p1.y)
	
	return abs(area) * 0.5
