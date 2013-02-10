/* delta dijkstra route from start to end, returns GeoJSON */
select
  gid,
  ST_Length(the_geom) as length,
  ST_AsGeoJSON(the_geom) as geojson
from
  dijkstra_sp_delta_directed(
    'rushhours_delta',
    find_nearest_node_within_distance('POINT(8.382654 49.011134)', 0.1, 'rushhours_delta'), /* resolve start lat,long to id */
    find_nearest_node_within_distance('POINT(8.482654 49.111134)', 0.1, 'rushhours_delta'), /* resolve end lat,long to id */
    0.1,
    false,
    false
  );
