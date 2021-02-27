
for /R %f in (*.csv) do ogr2ogr -f "PostgreSQL" PG:"host=localhost port=5432 user=postgres password=mariana01 dbname=idaf schemas=sicar_07" "%f" -lco FID=id -oo AUTODETECT_TYPE=YES
for /R %f in (*.shp) do ogr2ogr -f "PostgreSQL" PG:"host=localhost port=5432 user=postgres password=mariana01 dbname=idaf schemas=sicar_07" "%f" -nlt PROMOTE_TO_MULTI -lco GEOMETRY_NAME=geom -lco precision=NO -lco FID=id

