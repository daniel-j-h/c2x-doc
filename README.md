c2x
===

root
----

* Setup.md - basic import / environment setup
* Notes.md - random notes and pitfalls


cfg
---

* rushhours.config - osm2po rush hour import config
* offhours.config - osm2po off hours import config


qry
---

* shortestPath.sql - astar is not faster (we have to get more data into memory), so use dijkstra
* catchment.sql - lat/long and cost, returns polygon
