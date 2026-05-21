class_name PointCloudRecognition

const NUM_POINTS = 64
var saved_samples = {
	
}

func is_letter_saved(letter):
	return saved_samples.has(letter)
func is_string_saved(string):
	for c in string.split(""):
		if !is_letter_saved(c): return false
	return true
	
func save_points_to_image(points: PackedVector2Array, file_path: String):
	var img = Image.create_empty(100, 100, false, Image.FORMAT_RGB8)
	img.fill(Color.WHITE)
	for p in points:
		img.set_pixelv((p + Vector2(0.5, 0.5)) * 100, Color.BLACK)
	var f = FileAccess.open(file_path, FileAccess.WRITE)
	f.store_buffer(img.save_png_to_buffer())
	f.close()

func save_sample(letter: String, strokes: Array[PackedVector2Array]):
	var normalized = normalize(strokes)
	var shear1 = apply_shear(normalized, 0.25)
	var shear2 = apply_shear(normalized, -0.25)
	var scale1 = apply_scale(normalized, Vector2(0.5, 1))
	var scale2 = apply_scale(normalized, Vector2(1, 0.5))
	
	saved_samples[letter] = [normalized, shear1, shear2, scale1, scale2]

func get_prediction(strokes: Array[PackedVector2Array]):
	var normalized_points = normalize(strokes)
	var r = EditorFuncs.get_points_rect(normalized_points)
	var best_match = "?"
	var min_distance = INF
	
	var curr_dist = INF
	for sample_c in saved_samples:
		curr_dist = INF
		for sample_points in saved_samples[sample_c]:
			var dist = greedy_cloud_match(sample_points, normalized_points)
			if dist < min_distance:
				min_distance = dist
				best_match = sample_c
			if dist < curr_dist:
				curr_dist = dist
			
	return best_match
	
func greedy_cloud_match(cloud1: PackedVector2Array, cloud2: PackedVector2Array):
	var matched: Array[bool] = []
	matched.resize(NUM_POINTS)
	matched.fill(false)
	
	var sum = 0
	for a in range(NUM_POINTS):
		var min_dist = INF
		var min_indx = -1
		for b in range(NUM_POINTS):
			if !matched[b]:
				var dist = cloud1[a].distance_squared_to(cloud2[b])
				if dist < min_dist:
					min_dist = dist
					min_indx = b
					
		if min_indx != -1:
			matched[min_indx] = true
			sum += sqrt(min_dist)
	
	return sum / NUM_POINTS

func normalize(strokes: Array[PackedVector2Array]):
	var resampled = resample(strokes)
	var centroid = get_centroid(resampled)
	var scale = EditorFuncs.get_points_rect(resampled).size
	for p_i in range(resampled.size()):
		resampled[p_i] -= centroid
		resampled[p_i] /= max(scale.x, scale.y)
	
	return resampled

func resample(strokes: Array[PackedVector2Array]):
	var resampled_points = PackedVector2Array()
	var total_length = 0
	for stroke in strokes:
		total_length += get_stroke_length(stroke)
	
	var interval = total_length / NUM_POINTS
	var accumulated_distance = 0
	
	resampled_points.append(strokes[0][0])
	for stroke in strokes:
		if stroke.size() < 2: continue
		var p_i = 1
		while p_i < stroke.size():
			var p1 = stroke[p_i - 1]
			var p2 = stroke[p_i]
			var dist = p1.distance_to(p2)
			if accumulated_distance + dist >= interval:
				var t = (interval - accumulated_distance) / dist
				var p = p1.lerp(p2, t)
				resampled_points.append(p)
				
				stroke.insert(p_i, p)
				accumulated_distance = 0
			else:
				accumulated_distance += dist
			p_i += 1
	
	while resampled_points.size() < NUM_POINTS:
		var last_point = strokes[strokes.size() - 1][strokes[strokes.size() - 1].size() - 1]
		resampled_points.append(last_point)
	if resampled_points.size() > NUM_POINTS:
		resampled_points = resampled_points.slice(0, NUM_POINTS)
	
	return resampled_points
			
func get_stroke_length(stroke: PackedVector2Array) -> float:
	var l = 0
	for p_i in range(stroke.size() - 1):
		l += stroke[p_i].distance_to(stroke[p_i + 1])
	return l

func get_centroid(points: PackedVector2Array):
	var c = Vector2()
	for point in points:
		c += point
		
	c /= points.size()
	return c
	
func apply_shear(cloud: PackedVector2Array, amount: float) -> PackedVector2Array:
	var result = PackedVector2Array()
	for p in cloud:
		var x = p.x + p.y * amount
		result.append(Vector2(x, p.y))
	return result

func apply_scale(cloud: PackedVector2Array, scale: Vector2) -> PackedVector2Array:
	var result = PackedVector2Array()
	for p in cloud:
		result.append(p * scale)
	return result
