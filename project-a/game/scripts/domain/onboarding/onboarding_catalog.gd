class_name OnboardingCatalog
extends RefCounted

const OnboardingDefinitionCatalogScript := preload(
	"res://game/scripts/content/onboarding_definition_catalog.gd"
)
const CATALOG_VERSION: int = 4


static func count() -> int:
	return OnboardingDefinitionCatalogScript.count()


static func task_at(index: int) -> Dictionary:
	return OnboardingDefinitionCatalogScript.task_view_at(index)


static func task_by_id(task_id: String) -> Dictionary:
	return OnboardingDefinitionCatalogScript.task_view(task_id)
