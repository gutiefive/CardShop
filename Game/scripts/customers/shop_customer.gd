class_name ShopCustomer
extends CharacterBody3D
## Waypoints follow the generated shop's clear aisles; no external navigation service.
enum State { TO_SHELF, BROWSING, TO_QUEUE, WAITING, LEAVING }
var state: State = State.TO_SHELF
var customer_id: int
var shelf: ShelfStockInteractable
var retail: RetailDirector
var route: Array[Vector3] = []
var browse_remaining: float = 1.5
var speed: float = 2.0
var status_label: Label3D

func walk(points: Array[Vector3], next_state: State) -> void:
	route = points.duplicate()
	state = next_state

func _physics_process(delta: float) -> void:
	if state == State.BROWSING:
		browse_remaining -= delta
		if browse_remaining <= 0:
			retail.finish_browsing(self)
	elif not route.is_empty():
		var offset := route[0] - global_position
		offset.y = 0
		if offset.length() < 0.08:
			route.pop_front()
			if route.is_empty():
				if state == State.TO_SHELF:
					state = State.BROWSING
				elif state == State.TO_QUEUE:
					state = State.WAITING
				elif state == State.LEAVING:
					retail.customer_left(self)
					return
			velocity.x = 0
			velocity.z = 0
		else:
			var travel := offset.normalized() * minf(speed,offset.length()/delta)
			velocity.x = travel.x
			velocity.z = travel.z
	else:
		velocity.x = 0
		velocity.z = 0
	velocity.y = -0.5 if is_on_floor() else velocity.y-20*delta
	move_and_slide()
	if status_label:
		status_label.text = ["Browsing aisle","Choosing a product","Going to checkout","Ready for checkout","Thank you!"][state]
