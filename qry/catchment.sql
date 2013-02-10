/* delta catchment, returns GeoJSON polygon
 *
 * this is the patched catchment function in which
 * the delta is now passed as argument and the
 * signature is similar to the shortest path functions
 *
 * please use a delta large enough (e.g. based on the max. duration)
 *
 * see: https://github.com/daniel-j-h/pgrouting/blob/driving-distance-delta/extra/driving_distance/sql/routing_dd_wrappers.sql#L121
 */
select
  ST_AsGeoJSON(the_geom)
from
  driving_distance_delta(
    'rushhours_delta',
    find_nearest_node_within_distance( /* resolve start lat,long to id */
      'POINT(8.382654 49.011134)',
      0.1,
      'rushhours_delta'
    ),
    0.01667, /* 1 minute (in hours) */
    0.1, /* bounding box with 0.1 degree around the start */
    false,
    false
  );
