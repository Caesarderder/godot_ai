class_name TemplateSignalSource
extends Node

signal requested(amount: int)


func request(amount: int) -> void:
    if amount > 0:
        requested.emit(amount)
