c2x
===

This document shows how to import the germany.osm data into a routable database.


Requirements
------------

* [PostgreSQL](http://www.postgresql.org/) (version 9.1)
* [PostGIS](http://www.postgis.org/) (version 2+)
* [pgRouting](http://pgrouting.org/) (version: latest with patches from my branch)
* [osm2po](http://osm2po.de/) (requires java) (version 4.5.25 and 4.6.9)

Notes:

* PostgeSQL: Use the [StackBuilder - also called OneClickInstaller](http://www.postgresql.org/download/windows/). This allows you to select PostGIS 2 and the C# driver during the installation.
* pgrouting: use the latest [community mingw 64bit build](https://github.com/sanak/pgrouting4w). Also, see the delta function compatibility topic below.

Info: Set your PATH variable or call programs (e.g. createdb, psql, java) by absolute paths.


Database setup
--------------

Note: Please read 'Delta-function compatibility' below and use my postgis-compat branch if you need the functionality.

PostgreSQL server runs on localhost:5000, admin user is postgres here.  
Please pay attention to the order in which you run the commands.


    createdb -p 5000 -U postgres de_de
    psql -p 5000 -U postgres -d de_de -c "CREATE EXTENSION postgis;"

    psql -p 5000 -U postgres -d de_de -f pgrouting\routing_core.sql
    psql -p 5000 -U postgres -d de_de -f pgrouting\routing_core_wrappers.sql
    psql -p 5000 -U postgres -d de_de -f pgrouting\routing_topology.sql

    psql -p 5000 -U postgres -d de_de -f pgrouting\matching.sql
    psql -p 5000 -U postgres -d de_de -f pgrouting\routing_dd.sql
    psql -p 5000 -U postgres -d de_de -f pgrouting\routing_dd_wrappers.sql
    psql -p 5000 -U postgres -d de_de -f pgrouting\routing_tsp.sql
    psql -p 5000 -U postgres -d de_de -f pgrouting\routing_tsp_wrappers.sql


[more information](http://workshop.pgrouting.org/chapters/installation.html)


Delta-function compatibility
----------------------------

In order to use routing functions with a bounding box for performace reasons, we have to

* patch pgrouting to use recent PostGIS functions (ST prefix change)
* alias specific table columns (id vs gid, geom_way vs the_geom, cost vs length)

All pgrouting functions are updated to use recent PostGIS functions in my pgRouting fork at Github.  
Grab the *.sql files and use them in the database setup step above.

* [postgis-compat](https://github.com/daniel-j-h/pgrouting/tree/postgis-compat) for recent PostGIS ST prefix functions
* [driving-distance-delta](https://github.com/daniel-j-h/pgrouting/tree/driving-distance-delta) for driving_distance_delta

In order to adapt the table layout, we create a compatibility view:

    CREATE VIEW rushhours_delta (gid, osm_id, osm_name, osm_source_id, osm_target_id, clazz, flags, source, target, km, kmh, cost, reverse_cost, x1, y1, x2, y2, the_geom, length) AS SELECT id, osm_id, osm_name, osm_source_id, osm_target_id, clazz, flags, source, target, km, kmh, cost, reverse_cost, x1, y1, x2, y2, geom_way, cost FROM rushhours;

We create a complete aliased mapping here, so we do not have to join back with the rushhours table.
If you do not need the osm_ metadata columns, feel free to delete them.


Import .osm data
----------------

Download the [.osm data snapshot](http://download.geofabrik.de/openstreetmap/) or specify the url (osm2po is able to download the file)

    java -Xmx1000m -jar osm2po-4.5.25\osm2po-core-4.5.25-signed.jar prefix=rushhours config=rushhours.config cmd=tjsp germany.osm.pbf

* Parses and filters an OSM-Input file
* Joins Nodes, Ways and Relations
* Transforms and creates the topology
* Starts each configured postprocess. (By default it outputs postGIS-SQLs.)

Note: processing germany.osm.pbf took nearly 15 minutes.


Do not forget to import the processed data to your database; this should take another 15 minutes:

    psql -p 5000 -U postgres -d de_de -q -f rushhours\rushhours_2po_4pgr.sql


Now you should probably tell postgres to clean-up your mess:

    psql -p 5000 -U postgres -d de_de -c "VACUUM ANALYZE;"

Last, to simplify our queries, we cut off the "_2po_4pgr":

    ALTER TABLE rushhours_2po_4pgr RENAME TO rushhours;

And we are good to go.


Encapsulation
-------------

You probably want to [create a read only user](http://www.postgresql.org/docs/9.1/static/sql-createuser.html) for your database:

    CREATE USER osmreader WITH PASSWORD 'MyPassword';
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO osmreader;


Fuzzy String Matching
---------------------

If we want to provide suggestions based on an incorrect street query from the user, we have to load the [fuzzystrmatch](http://www.postgresql.org/docs/9.1/static/fuzzystrmatch.html) extension.

* Make sure fuzzystrmatch is available: [pg_available_extensions](http://www.postgresql.org/docs/9.1/static/view-pg-available-extensions.html)
* [Or compile it from source](http://www.postgresql.org/docs/9.1/static/contrib.html)

Now we're able to [load the extension](http://www.postgresql.org/docs/9.1/static/sql-createextension.html):

    CREATE EXTENSION fuzzystrmatch;


We use the default Levenshtein function, for now. See the [documentation](http://www.postgresql.org/docs/9.1/static/fuzzystrmatch.html#AEN134381) for more details.

A query could now look like this:

    select distinct(osm_name) as street, levenshtein(osm_name, 'Caiserstrase') as dist from de_bw_2po_4pgr order by dist asc limit 5;
        street     | dist
    ---------------+------
    Kaiserstrasse  |    2
    Kaiserstraße   |    3
    Gaiserstraße   |    3
    Kaisterstrasse |    3
    Wasserstraße   |    4

Note that we do only have the street names - but not the corresponding city names.


Performance Tweakings
---------------------

The type GIST index uses only the bounding boxes of the geom; therefore it's space efficient while providing good performance benefits at the same time:

    CREATE INDEX idx_rushhours_2po_4pgr_geom_way ON rushhours_2po_4pgr USING GIST (geom_way);

Type B-tree indices:

    CREATE INDEX idx_rushhours_2po_4pgr_cost ON rushhours_2po_4pgr USING BTREE (cost);


Consider indexing osm_name with soundex from fuzzystrmatch, in order to pre-filter results for the Leveshtein algorithm.
