extends RefCounted
class_name TransitionMetrics


var graph_builder := TransitionGraphBuilder.new()


func calculate(map_data: Dictionary) -> Dictionary:
	var transition_graph: Dictionary = graph_builder.build(map_data)

	var nodes: Array = transition_graph.get("nodes", [])
	var edges: Array = transition_graph.get("edges", [])

	var node_count: int = nodes.size()
	var edge_count: int = edges.size()

	var room_node_count: int = 0
	var open_area_node_count: int = 0
	var junction_node_count: int = 0
	var corridor_terminal_node_count: int = 0
	var special_node_count: int = 0
	var other_node_count: int = 0

	var room_dead_end_count: int = 0
	var open_area_dead_end_count: int = 0
	var semantic_dead_end_count: int = 0
	var corridor_terminal_dead_end_count: int = 0

	var total_node_degree: int = 0

	for node_value in nodes:
		var node: Dictionary = node_value
		var node_type: String = str(node.get("type", "unknown"))
		var degree: int = int(node.get("degree", 0))

		total_node_degree += degree

		match node_type:
			"room":
				room_node_count += 1

				if degree == 1:
					room_dead_end_count += 1
					semantic_dead_end_count += 1

			"open_area":
				open_area_node_count += 1

				if degree == 1:
					open_area_dead_end_count += 1
					semantic_dead_end_count += 1

			"junction":
				junction_node_count += 1

			"corridor_terminal":
				corridor_terminal_node_count += 1

				if degree == 1:
					corridor_terminal_dead_end_count += 1

			"special":
				special_node_count += 1

				if degree == 1:
					semantic_dead_end_count += 1

			_:
				other_node_count += 1

	var total_edge_length: int = 0
	var max_edge_length: int = 0

	var corridor_edge_count: int = 0
	var direct_connection_edge_count: int = 0

	for edge_value in edges:
		var edge: Dictionary = edge_value
		var length: int = int(edge.get("length", 0))
		var edge_type: String = str(edge.get("type", ""))

		total_edge_length += length
		max_edge_length = max(max_edge_length, length)

		match edge_type:
			"corridor":
				corridor_edge_count += 1
			"direct_connection":
				direct_connection_edge_count += 1

	var component_count: int = _count_graph_components(nodes, edges)

	var cycle_count: int = 0
	if node_count > 0:
		cycle_count = edge_count - node_count + component_count
		cycle_count = max(0, cycle_count)

	return {
		"transition_node_count": node_count,
		"transition_edge_count": edge_count,
		"transition_component_count": component_count,

		"transition_room_node_count": room_node_count,
		"transition_open_area_node_count": open_area_node_count,
		"transition_junction_node_count": junction_node_count,
		"transition_corridor_terminal_node_count": corridor_terminal_node_count,
		"transition_special_node_count": special_node_count,
		"transition_other_node_count": other_node_count,

		"transition_corridor_edge_count": corridor_edge_count,
		"transition_direct_connection_edge_count": direct_connection_edge_count,

		"transition_room_dead_end_count": room_dead_end_count,
		"transition_open_area_dead_end_count": open_area_dead_end_count,
		"transition_semantic_dead_end_count": semantic_dead_end_count,
		"transition_corridor_terminal_dead_end_count": corridor_terminal_dead_end_count,

		"transition_average_node_degree": _safe_divide(
			float(total_node_degree),
			float(max(1, node_count))
		),

		"transition_total_corridor_length": total_edge_length,
		"transition_average_corridor_length": _safe_divide(
			float(total_edge_length),
			float(max(1, edge_count))
		),
		"transition_max_corridor_length": max_edge_length,

		"transition_cycle_count": cycle_count,
		"transition_cycle_density": _safe_divide(
			float(cycle_count),
			float(max(1, node_count))
		)
	}


func _count_graph_components(nodes: Array, edges: Array) -> int:
	if nodes.is_empty():
		return 0

	var adjacency := {}

	for node_value in nodes:
		var node: Dictionary = node_value
		var node_id: int = int(node.get("id", -1))

		if node_id < 0:
			continue

		adjacency[node_id] = []

	for edge_value in edges:
		var edge: Dictionary = edge_value
		var from_id: int = int(edge.get("from", -1))
		var to_id: int = int(edge.get("to", -1))

		if not adjacency.has(from_id):
			continue

		if not adjacency.has(to_id):
			continue

		adjacency[from_id].append(to_id)

		if to_id != from_id:
			adjacency[to_id].append(from_id)

	var visited := {}
	var components: int = 0

	for node_id_value in adjacency.keys():
		var node_id: int = int(node_id_value)

		if visited.has(node_id):
			continue

		components += 1

		var queue: Array[int] = [node_id]
		var head: int = 0
		visited[node_id] = true

		while head < queue.size():
			var current: int = queue[head]
			head += 1

			var neighbors: Array = adjacency.get(current, [])

			for neighbor_value in neighbors:
				var neighbor: int = int(neighbor_value)

				if visited.has(neighbor):
					continue

				visited[neighbor] = true
				queue.append(neighbor)

	return components


func _safe_divide(a: float, b: float) -> float:
	if b == 0.0:
		return 0.0

	return a / b
