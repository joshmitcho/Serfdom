# daynightcycle_ui.gd
extends Control

@onready var day_label: Label = %DayLabel
@onready var time_label: Label = %TimeLabel
@onready var money_label: Label = %MoneyLabel

var days_of_the_week = ["Mon. ", "Tue. ", "Wed. ", "Thu. ", "Fri. ", "Sat. ", "Sun. "]

func set_daytime(day: int, hour: int, minute: int) -> void:
	day_label.text = days_of_the_week[day % 7] + str(day + 1)
	time_label.text = _amfm_hour(hour) + ":" + _minute(minute) + " " + _am_pm(hour)

func set_money(new_value: int):
	money_label.text = str(new_value)

func _amfm_hour(hour: int) -> String:
	if hour == 0:
		return str(12)
	if hour > 12:
		return str(hour - 12)
	return str(hour)

func _minute(minute: int) -> String:
	if minute < 10:
		return "0" + str(minute)
	return str(minute)

func _am_pm(hour: int) -> String:
	if hour < 12:
		return "am"
	else:
		return "pm"
