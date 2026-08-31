@abstract
class_name BaseGenerator
extends RefCounted

## Defines the common interface implemented by all procedural map generators
## used by the testing environment.
##
## Concrete generators provide their algorithm name and generate a map
## from the configuration supplied by the test runner.


## Returns the name used to identify the generation algorithm.
@abstract
func get_algorithm_name() -> String


## Generates a map using the provided test configuration.
##
## The returned Dictionary contains the generated map data and any
## generator-specific information required by the testing environment.
@abstract
func generate_map(config: Dictionary) -> Dictionary
