extends VBoxContainer

var pickup_notification_base = preload("res://Scenes/pickup_notification.tscn")

func _on_player_pickup(item: Item, amount: int):
	var current_notifications = get_children()
	for notif in current_notifications:
		if notif.item.item_name == item.item_name:
			notif.initialize(notif.item, notif.item.amount + amount)
			return
	add_new_notification(item, amount)

func add_new_notification(item, amount):
	var pickup_notification = pickup_notification_base.instantiate()
	add_child(pickup_notification)
	pickup_notification.initialize(item, amount)

