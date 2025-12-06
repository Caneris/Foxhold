class_name CostData
extends Resource

@export var base_costs : Dictionary = {
    "House": 50,
    "Tower": 100,
    "Wall": 75,
    "Heal": 30,
    "House_Upgrade": 80,
    "Knight_Foxling": 120,
    "Collector_Foxling": 90,
    "Upgrade_Wall": 60,
    "Destroy_Wall": 20,
    "Repair_Wall": 40
}

@export var inflation_rate : float = 0.15

func get_inflated_cost(item_name: String, wave: int) -> int:
    var multiplier = (1.0 + inflation_rate) ** (wave - 1)
    return roundi(base_costs[item_name] * multiplier)
