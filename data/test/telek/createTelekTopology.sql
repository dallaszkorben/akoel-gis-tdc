--
-- Pelda a topologia hsznalatara
-- valamint arra, hogy ez hogyan megjelenitheto a mapserver-rel
--

-- letrehoz egy topologia schema-t
select topology.CreateTopology('mytopology');

-- topologikus pontokat helyez el benne
select topology.ST_AddIsoNode( 'mytopology', 0, 'Point(645446.22  227900.57)' );
select topology.ST_AddIsoNode( 'mytopology', 0, 'Point(645543.58  227960.08)' );
select topology.ST_AddIsoNode( 'mytopology', 0, 'Point(645609.10  227854.38)' );
select topology.ST_AddIsoNode( 'mytopology', 0, 'Point(645512.35  227793.30)' );

-- topologikus eleket helyez el benne
select topology.ST_AddEdgeModFace( 'mytopology', 1, 2, 'LINESTRING(645446.22  227900.57, 645543.58  227960.08)');
select topology.ST_AddEdgeModFace( 'mytopology', 2, 3, 'LINESTRING(645543.58  227960.08, 645609.10  227854.38)');
select topology.ST_AddEdgeModFace( 'mytopology', 3, 4, 'LINESTRING(645609.10  227854.38, 645512.35  227793.30)');
select topology.ST_AddEdgeModFace( 'mytopology', 4, 1, 'LINESTRING(645512.35  227793.30, 645446.22  227900.57)');


-- keszit egy geometry tipusu mezot es fel is tolti
CREATE TABLE "public"."parcel" (gid serial PRIMARY KEY, "id" numeric(10,0)) with oids;
SELECT AddGeometryColumn('public','parcel','the_geom','-1','MULTIPOLYGON',2);
INSERT INTO "public"."parcel" ("id", "the_geom") values (1, st_geomfromtext('MULTIPOLYGON(((645446.35910954 227900.629326156,645543.575069452 227960.245729922,645609.421092384 227854.563141896,645512.278147368 227793.260921618,645446.35910954 227900.629326156)))', -1));
CREATE INDEX "parcel_the_geom_gist" ON "public"."parcel" using gist ("the_geom");

-- keszit egy topogeom tipusu mezot es fel is tolti
SELECT topology.AddTopoGeometryColumn( 'mytopology', 'public', 'parcel', 'topo_geom', 'POLYGON');
UPDATE public.parcel set topo_geom = topology.CreateTopoGeom( 'mytopology', 3, 1, '{{1,3}}') where gid = 1;

-- mivel a mapserver csak geometry tipusu mezoket kepes mejeleniteni,ezert kell csinalni egy 
-- view-t amiben a topogeom tipusu mezot atalakitottuk geometry tipusuve
-- fontos tudni, hogy a mapserver csak olyan tablat kepes megjeleniteni, aminek van oid mezoje
create view parcel_view as select oid, gid, id, the_geom, topo_geom::geometry from parcel

COMMIT;



DropGeometryTable( table )