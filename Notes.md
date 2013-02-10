c2x
===

Random notes and pitfalls.


pgRouting
---------

* Use the delta functions; everything else does not scale well
* Yes the documentation sucks; do yourself a favor and read the sql files at extra/*/sql/*.sql and core/sql/*.sql


Database columns
----------------

* cost: duration in HOURS. Kind of strange, I know. DEAL WITH IT
* length: this is simply an alias for cost, since some pgrouting functions need it


Levenshtein
-----------

* "ß" and "ss" not the same
* The street names are kind of ambiguous (no city information)
* Query time gets worse with your data
