class_name TemplateInteractor
extends Node

signal selection_changed(candidate: TemplateInteractable)
signal executed(candidate: TemplateInteractable)
signal canceled

var candidates: Array[TemplateInteractable] = []
var selected: TemplateInteractable


func add_candidate(candidate: TemplateInteractable) -> void:
    if candidate == null or candidate.offer == null or candidates.has(candidate):
        return
    candidates.append(candidate)
    _refresh_selection()


func remove_candidate(candidate: TemplateInteractable) -> void:
    candidates.erase(candidate)
    _refresh_selection()


func execute_selected() -> bool:
    if selected == null or not is_instance_valid(selected):
        return false
    selected.execute()
    executed.emit(selected)
    return true


func cancel() -> void:
    selected = null
    selection_changed.emit(null)
    canceled.emit()


func _refresh_selection() -> void:
    candidates = candidates.filter(func(candidate: TemplateInteractable) -> bool:
        return is_instance_valid(candidate) and candidate.offer != null
    )
    candidates.sort_custom(func(left: TemplateInteractable, right: TemplateInteractable) -> bool:
        if left.offer.priority == right.offer.priority:
            return String(left.offer.id) < String(right.offer.id)
        return left.offer.priority > right.offer.priority
    )
    var next: TemplateInteractable = candidates.front() if not candidates.is_empty() else null
    if next != selected:
        selected = next
        selection_changed.emit(selected)
