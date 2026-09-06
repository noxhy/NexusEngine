@icon("res://addons/at-icons/node/file_cog.svg")

extends Resource
class_name SongDifficultyData
## Resource containing the paths to files necessary for a chart. Used by [Song] to define difficulty file locations

## The path to a [Chart] resource.
@export_file("*.res",'*.tres','*.json') var chart: String = ''
@export_group("Optional")
## Optional path to a unique scene to be used in this for this song. if empty, the [Song]'s [member Song.scene] will be used.
@export_file("*.tscn","*.scn") var scene: String = ''
## Optional path to a [ChartEvents] resource.
@export_file("*.tres", "*.res") var events: String = ''
