extends Node

@onready var interactor: TemplateInteractor = $Interactor
@onready var low: TemplateInteractable = $LowPriority
@onready var high: TemplateInteractable = $HighPriority


func _ready() -> void:
    interactor.add_candidate(low)
    interactor.add_candidate(high)
