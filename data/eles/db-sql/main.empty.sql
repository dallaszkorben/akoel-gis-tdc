--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: tdc; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE tdc IS '3 Dimensional Cadastre';


--
-- Name: main; Type: SCHEMA; Schema: -; Owner: tdc
--

CREATE SCHEMA main;


ALTER SCHEMA main OWNER TO tdc;

--
-- Name: SCHEMA main; Type: COMMENT; Schema: -; Owner: tdc
--

COMMENT ON SCHEMA main IS 'Itt helyezkednek el a saját
-Tábláim
-Függvényeim
-Triggereim';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = main, pg_catalog;

--
-- Name: geod_position; Type: TYPE; Schema: main; Owner: tdc
--

CREATE TYPE geod_position AS (
	x double precision,
	y double precision,
	h double precision
);


ALTER TYPE main.geod_position OWNER TO tdc;

SET search_path = public, pg_catalog;

--
-- Name: geometry; Type: SHELL TYPE; Schema: public; Owner: postgres
--

CREATE TYPE geometry;


--
-- Name: geometry_analyze(internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_analyze(internal) RETURNS boolean
    LANGUAGE c STRICT
    AS '$libdir/postgis-2.0', 'geometry_analyze_2d';


ALTER FUNCTION public.geometry_analyze(internal) OWNER TO postgres;

--
-- Name: geometry_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_in(cstring) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_in';


ALTER FUNCTION public.geometry_in(cstring) OWNER TO postgres;

--
-- Name: geometry_out(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_out(geometry) RETURNS cstring
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_out';


ALTER FUNCTION public.geometry_out(geometry) OWNER TO postgres;

--
-- Name: geometry_recv(internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_recv(internal) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_recv';


ALTER FUNCTION public.geometry_recv(internal) OWNER TO postgres;

--
-- Name: geometry_send(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_send(geometry) RETURNS bytea
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_send';


ALTER FUNCTION public.geometry_send(geometry) OWNER TO postgres;

--
-- Name: geometry_typmod_in(cstring[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_typmod_in(cstring[]) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geometry_typmod_in';


ALTER FUNCTION public.geometry_typmod_in(cstring[]) OWNER TO postgres;

--
-- Name: geometry_typmod_out(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_typmod_out(integer) RETURNS cstring
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'postgis_typmod_out';


ALTER FUNCTION public.geometry_typmod_out(integer) OWNER TO postgres;

--
-- Name: geometry; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE geometry (
    INTERNALLENGTH = variable,
    INPUT = geometry_in,
    OUTPUT = geometry_out,
    RECEIVE = geometry_recv,
    SEND = geometry_send,
    TYPMOD_IN = geometry_typmod_in,
    TYPMOD_OUT = geometry_typmod_out,
    ANALYZE = geometry_analyze,
    DELIMITER = ':',
    ALIGNMENT = double,
    STORAGE = main
);


ALTER TYPE public.geometry OWNER TO postgres;

--
-- Name: TYPE geometry; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TYPE geometry IS 'postgis type: Planar spatial data type.';


SET search_path = main, pg_catalog;

--
-- Name: identify_building; Type: TYPE; Schema: main; Owner: tdc
--

CREATE TYPE identify_building AS (
	immovable_type integer,
	identify_geom public.geometry,
	identify_name text,
	identify_nid bigint,
	identify_settlement text,
	identify_hrsz text,
	identify_levels integer,
	identify_registered_area numeric(12,1),
	identify_measured_area numeric(12,1)
);


ALTER TYPE main.identify_building OWNER TO tdc;

--
-- Name: identify_building_individual_unit; Type: TYPE; Schema: main; Owner: tdc
--

CREATE TYPE identify_building_individual_unit AS (
	immovable_type integer,
	identify_geom public.geometry,
	identify_name text,
	identify_nid bigint,
	identify_level numeric(4,1),
	identify_settlement text,
	identify_hrsz text,
	identify_registered_area numeric(12,1),
	identify_measured_area numeric(12,1)
);


ALTER TYPE main.identify_building_individual_unit OWNER TO tdc;

--
-- Name: identify_parcel; Type: TYPE; Schema: main; Owner: tdc
--

CREATE TYPE identify_parcel AS (
	immovable_type integer,
	identify_geom public.geometry,
	identify_name text,
	identify_nid bigint,
	identify_settlement text,
	identify_hrsz text,
	identify_registered_area numeric(12,1),
	identify_measured_area numeric(12,1)
);


ALTER TYPE main.identify_parcel OWNER TO tdc;

--
-- Name: identify_point; Type: TYPE; Schema: main; Owner: tdc
--

CREATE TYPE identify_point AS (
	identify_geom public.geometry,
	identify_name text,
	identify_nid bigint,
	identify_point_name text,
	identify_point_description text,
	identify_point_quality integer,
	identify_point_measured_date date,
	identify_point_dimension integer,
	identify_point_x numeric(8,2),
	identify_point_y numeric(8,2),
	identify_point_h numeric(8,2)
);


ALTER TYPE main.identify_point OWNER TO tdc;

--
-- Name: query_owner; Type: TYPE; Schema: main; Owner: tdc
--

CREATE TYPE query_owner AS (
	found_projection bigint,
	owner_name text,
	owner_share text,
	owner_contract_date date
);


ALTER TYPE main.query_owner OWNER TO tdc;

--
-- Name: query_point; Type: TYPE; Schema: main; Owner: tdc
--

CREATE TYPE query_point AS (
	found_projection bigint,
	point_name text,
	point_description text,
	point_quality integer,
	point_measured_date date,
	point_x numeric(8,2),
	point_y numeric(8,2),
	point_h numeric(8,2)
);


ALTER TYPE main.query_point OWNER TO tdc;

--
-- Name: query_x3d; Type: TYPE; Schema: main; Owner: tdc
--

CREATE TYPE query_x3d AS (
	query_base_nid bigint,
	query_base_name text,
	query_base_geom public.geometry,
	query_object_name text,
	query_object_nid bigint,
	query_object_title text,
	query_object_selected boolean,
	query_object_x3d text
);


ALTER TYPE main.query_x3d OWNER TO tdc;

--
-- Name: view_building; Type: TYPE; Schema: main; Owner: tdc
--

CREATE TYPE view_building AS (
	view_geom public.geometry,
	view_nid bigint,
	view_hrsz_eoi text,
	view_angle numeric(4,2)
);


ALTER TYPE main.view_building OWNER TO tdc;

--
-- Name: view_building_individual_unit; Type: TYPE; Schema: main; Owner: tdc
--

CREATE TYPE view_building_individual_unit AS (
	view_geom public.geometry,
	view_nid bigint
);


ALTER TYPE main.view_building_individual_unit OWNER TO tdc;

--
-- Name: view_parcel; Type: TYPE; Schema: main; Owner: tdc
--

CREATE TYPE view_parcel AS (
	view_geom public.geometry,
	view_nid bigint,
	view_hrsz text,
	view_angle numeric(4,2)
);


ALTER TYPE main.view_parcel OWNER TO tdc;

--
-- Name: view_point; Type: TYPE; Schema: main; Owner: tdc
--

CREATE TYPE view_point AS (
	view_geom public.geometry,
	view_name text,
	view_nid bigint
);


ALTER TYPE main.view_point OWNER TO tdc;

SET search_path = public, pg_catalog;

--
-- Name: box2d; Type: SHELL TYPE; Schema: public; Owner: postgres
--

CREATE TYPE box2d;


--
-- Name: box2d_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2d_in(cstring) RETURNS box2d
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX2D_in';


ALTER FUNCTION public.box2d_in(cstring) OWNER TO postgres;

--
-- Name: box2d_out(box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2d_out(box2d) RETURNS cstring
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX2D_out';


ALTER FUNCTION public.box2d_out(box2d) OWNER TO postgres;

--
-- Name: box2d; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE box2d (
    INTERNALLENGTH = 65,
    INPUT = box2d_in,
    OUTPUT = box2d_out,
    ALIGNMENT = int4,
    STORAGE = plain
);


ALTER TYPE public.box2d OWNER TO postgres;

--
-- Name: TYPE box2d; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TYPE box2d IS 'postgis type: A box composed of x min, ymin, xmax, ymax. Often used to return the 2d enclosing box of a geometry.';


--
-- Name: box2df; Type: SHELL TYPE; Schema: public; Owner: postgres
--

CREATE TYPE box2df;


--
-- Name: box2df_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2df_in(cstring) RETURNS box2df
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'box2df_in';


ALTER FUNCTION public.box2df_in(cstring) OWNER TO postgres;

--
-- Name: box2df_out(box2df); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2df_out(box2df) RETURNS cstring
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'box2df_out';


ALTER FUNCTION public.box2df_out(box2df) OWNER TO postgres;

--
-- Name: box2df; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE box2df (
    INTERNALLENGTH = 16,
    INPUT = box2df_in,
    OUTPUT = box2df_out,
    ALIGNMENT = double,
    STORAGE = plain
);


ALTER TYPE public.box2df OWNER TO postgres;

--
-- Name: box3d; Type: SHELL TYPE; Schema: public; Owner: postgres
--

CREATE TYPE box3d;


--
-- Name: box3d_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box3d_in(cstring) RETURNS box3d
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX3D_in';


ALTER FUNCTION public.box3d_in(cstring) OWNER TO postgres;

--
-- Name: box3d_out(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box3d_out(box3d) RETURNS cstring
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX3D_out';


ALTER FUNCTION public.box3d_out(box3d) OWNER TO postgres;

--
-- Name: box3d; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE box3d (
    INTERNALLENGTH = 52,
    INPUT = box3d_in,
    OUTPUT = box3d_out,
    ALIGNMENT = double,
    STORAGE = plain
);


ALTER TYPE public.box3d OWNER TO postgres;

--
-- Name: TYPE box3d; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TYPE box3d IS 'postgis type: A box composed of x min, ymin, zmin, xmax, ymax, zmax. Often used to return the 3d extent of a geometry or collection of geometries.';


--
-- Name: geography; Type: SHELL TYPE; Schema: public; Owner: postgres
--

CREATE TYPE geography;


--
-- Name: geography_analyze(internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_analyze(internal) RETURNS boolean
    LANGUAGE c STRICT
    AS '$libdir/postgis-2.0', 'geography_analyze';


ALTER FUNCTION public.geography_analyze(internal) OWNER TO postgres;

--
-- Name: geography_in(cstring, oid, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_in(cstring, oid, integer) RETURNS geography
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_in';


ALTER FUNCTION public.geography_in(cstring, oid, integer) OWNER TO postgres;

--
-- Name: geography_out(geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_out(geography) RETURNS cstring
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_out';


ALTER FUNCTION public.geography_out(geography) OWNER TO postgres;

--
-- Name: geography_recv(internal, oid, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_recv(internal, oid, integer) RETURNS geography
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_recv';


ALTER FUNCTION public.geography_recv(internal, oid, integer) OWNER TO postgres;

--
-- Name: geography_send(geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_send(geography) RETURNS bytea
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_send';


ALTER FUNCTION public.geography_send(geography) OWNER TO postgres;

--
-- Name: geography_typmod_in(cstring[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_typmod_in(cstring[]) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_typmod_in';


ALTER FUNCTION public.geography_typmod_in(cstring[]) OWNER TO postgres;

--
-- Name: geography_typmod_out(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_typmod_out(integer) RETURNS cstring
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'postgis_typmod_out';


ALTER FUNCTION public.geography_typmod_out(integer) OWNER TO postgres;

--
-- Name: geography; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE geography (
    INTERNALLENGTH = variable,
    INPUT = geography_in,
    OUTPUT = geography_out,
    RECEIVE = geography_recv,
    SEND = geography_send,
    TYPMOD_IN = geography_typmod_in,
    TYPMOD_OUT = geography_typmod_out,
    ANALYZE = geography_analyze,
    DELIMITER = ':',
    ALIGNMENT = double,
    STORAGE = main
);


ALTER TYPE public.geography OWNER TO postgres;

--
-- Name: TYPE geography; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TYPE geography IS 'postgis type: Ellipsoidal spatial data type.';


--
-- Name: geometry_dump; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE geometry_dump AS (
	path integer[],
	geom geometry
);


ALTER TYPE public.geometry_dump OWNER TO postgres;

--
-- Name: TYPE geometry_dump; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TYPE geometry_dump IS 'postgis type: A spatial datatype with two fields - geom (holding a geometry object) and path[] (a 1-d array holding the position of the geometry within the dumped object.)';


--
-- Name: gidx; Type: SHELL TYPE; Schema: public; Owner: postgres
--

CREATE TYPE gidx;


--
-- Name: gidx_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION gidx_in(cstring) RETURNS gidx
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'gidx_in';


ALTER FUNCTION public.gidx_in(cstring) OWNER TO postgres;

--
-- Name: gidx_out(gidx); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION gidx_out(gidx) RETURNS cstring
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'gidx_out';


ALTER FUNCTION public.gidx_out(gidx) OWNER TO postgres;

--
-- Name: gidx; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE gidx (
    INTERNALLENGTH = variable,
    INPUT = gidx_in,
    OUTPUT = gidx_out,
    ALIGNMENT = double,
    STORAGE = plain
);


ALTER TYPE public.gidx OWNER TO postgres;

--
-- Name: pgis_abs; Type: SHELL TYPE; Schema: public; Owner: postgres
--

CREATE TYPE pgis_abs;


--
-- Name: pgis_abs_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION pgis_abs_in(cstring) RETURNS pgis_abs
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'pgis_abs_in';


ALTER FUNCTION public.pgis_abs_in(cstring) OWNER TO postgres;

--
-- Name: pgis_abs_out(pgis_abs); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION pgis_abs_out(pgis_abs) RETURNS cstring
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'pgis_abs_out';


ALTER FUNCTION public.pgis_abs_out(pgis_abs) OWNER TO postgres;

--
-- Name: pgis_abs; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE pgis_abs (
    INTERNALLENGTH = 8,
    INPUT = pgis_abs_in,
    OUTPUT = pgis_abs_out,
    ALIGNMENT = double,
    STORAGE = plain
);


ALTER TYPE public.pgis_abs OWNER TO postgres;

--
-- Name: spheroid; Type: SHELL TYPE; Schema: public; Owner: postgres
--

CREATE TYPE spheroid;


--
-- Name: spheroid_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION spheroid_in(cstring) RETURNS spheroid
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'ellipsoid_in';


ALTER FUNCTION public.spheroid_in(cstring) OWNER TO postgres;

--
-- Name: spheroid_out(spheroid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION spheroid_out(spheroid) RETURNS cstring
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'ellipsoid_out';


ALTER FUNCTION public.spheroid_out(spheroid) OWNER TO postgres;

--
-- Name: spheroid; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE spheroid (
    INTERNALLENGTH = 65,
    INPUT = spheroid_in,
    OUTPUT = spheroid_out,
    ALIGNMENT = double,
    STORAGE = plain
);


ALTER TYPE public.spheroid OWNER TO postgres;

--
-- Name: valid_detail; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE valid_detail AS (
	valid boolean,
	reason character varying,
	location geometry
);


ALTER TYPE public.valid_detail OWNER TO postgres;

SET search_path = main, pg_catalog;

--
-- Name: hrsz_concat(integer, integer); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION hrsz_concat(hrsz_main integer, hrsz_fraction integer) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$DECLARE
  output text;
BEGIN
  output := hrsz_main::text||CASE (hrsz_fraction IS NULL) WHEN TRUE THEN $$ $$ ELSE $$/$$ || hrsz_fraction::text END;
  return output;
END;
$_$;


ALTER FUNCTION main.hrsz_concat(hrsz_main integer, hrsz_fraction integer) OWNER TO tdc;

--
-- Name: FUNCTION hrsz_concat(hrsz_main integer, hrsz_fraction integer); Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON FUNCTION hrsz_concat(hrsz_main integer, hrsz_fraction integer) IS 'A paraméterként megkapott helyrajzi szám fő értékét és alátörését string-gé alakítja. Azért kell, mert az alátörés lehet NULL is, akkor viszont összehasonlítás esetén nem az igazat adja vissza';


--
-- Name: identify_building(); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION identify_building() RETURNS SETOF identify_building
    LANGUAGE plpgsql
    AS $$

DECLARE
  object_name text = 'im_building';
  immovable_type_1 integer = 1;
  immovable_type_2 integer = 2;
  immovable_type_3 integer = 3;
  immovable_type_4 integer = 4;
  output main.identify_building%rowtype;
BEGIN


  ---------------------
  -- 1. Foldreszlet ---
  ---------------------
  --
  -- Van tulajdonjog az im_parcel-en, de nincs az im_parcel-nek kapcsolata im_building-gel
  --
  -- Természetesen ilyen nem lehet, hiszen definició szerint nincs a földrészleten épület :)
  --

  --------------------------------
  --2. Foldreszlet az epulettel --
  --------------------------------
  --
  -- Van tualjdonjog az im_parcel-en, van im_building kapcsolata, de az im_building-en nincsen tulajdonjog
  --
  FOR output IN
    SELECT DISTINCT
      immovable_type_2 AS immovable_type,
      face.geom AS identify_geom,
      object_name AS identify_name, 
      building.nid AS identify_nid,   
  
      building.im_settlement AS identify_settlement,
      main.hrsz_concat(building.hrsz_main, building.hrsz_fraction ) AS identify_hrsz,
      levels_for_building.levels AS identify_levels,
      building.area AS selected_identify_area,
      levels_for_building.area AS identify_measured_area
    FROM 
       main.im_parcel parcel, 
       main.rt_right r, 
       main.im_building building,
       main.tp_face face,
      (SELECT
        building.nid AS building_nid,
        count( building_levels.im_levels ) AS levels,
        sum( st_area( face.geom ) ) AS area
      FROM
        main.im_building building,
        main.im_building_levels building_levels,
        main.tp_face face
      WHERE
        building.nid=building_levels.im_building AND
        face.gid=building_levels.projection
      GROUP BY building.nid) AS levels_for_building
    WHERE
      face.gid=building.projection AND
      building.nid=levels_for_building.building_nid AND
      parcel.nid=r.im_parcel AND 
      r.rt_type=1 AND
      building.im_settlement=parcel.im_settlement AND 
      main.hrsz_concat(building.hrsz_main, building.hrsz_fraction)=main.hrsz_concat(parcel.hrsz_main,parcel.hrsz_fraction) AND
      building.nid NOT IN (SELECT coalesce(im_building, -1) FROM main.rt_right WHERE rt_type=1 ) 
 LOOP
    RETURN NEXT output;
  END LOOP;


  ----------------------------------------
  -- 3. Foldreszlet kulonallo epulettel --
  ----------------------------------------
  --
  -- Van tulajdonjog az im_parcel-en, es van egy masik tulajdonjog a hozza kapcsolodo buildin-en is
  --
  FOR output IN
    SELECT DISTINCT
      immovable_type_3 AS immovable_type,
      face.geom AS identify_geom,
      object_name AS identify_name, 
      building.nid AS identify_nid,

      building.im_settlement AS identify_settlement,
      main.hrsz_concat(building.hrsz_main, building.hrsz_fraction )||'/'||building.hrsz_eoi AS identify_hrsz,
      levels_for_building.levels AS identify_levels,
      building.area AS identify_registered_area,
      levels_for_building.area AS identify_measured_area
    FROM 
      main.im_parcel parcel, 
      main.rt_right r, 
      main.im_building building,
      main.tp_face face,
      (SELECT
        building.nid AS building_nid,
        count( building_levels.im_levels ) AS levels,
        sum( st_area( face.geom ) ) AS area
      FROM
        main.im_building building,
        main.im_building_levels building_levels,
        main.tp_face face
      WHERE
        building.nid=building_levels.im_building AND
        face.gid=building_levels.projection
      GROUP BY building.nid) AS levels_for_building
    WHERE
       face.gid=building.projection AND
       building.nid=levels_for_building.building_nid AND
       parcel.nid=r.im_parcel AND 
       r.rt_type=1 AND
       building.im_settlement=parcel.im_settlement AND 
       main.hrsz_concat(building.hrsz_main, building.hrsz_fraction)=main.hrsz_concat(parcel.hrsz_main,parcel.hrsz_fraction) AND
       building.nid IN (SELECT im_building FROM main.rt_right r WHERE r.rt_type=1) LOOP
    RETURN NEXT output;
  END LOOP;

------------------
-- 4. Tarsashaz --
------------------
--
-- Van im_building az im_parcel-en es tartozik hozza im_building_individual_unit
--
  FOR output IN
    SELECT DISTINCT
      immovable_type_4 AS immovable_type,
      face.geom AS identify_geom,
      object_name AS identify_name, 
      building.nid AS identify_nid,

      building.im_settlement AS identify_settlement,
      main.hrsz_concat(building.hrsz_main, building.hrsz_fraction ) AS identify_hrsz,
      levels_for_building.levels AS identify_levels,
      building.area AS identify_registered_area,
      levels_for_building.area AS identify_measured_area
    FROM 
      main.im_parcel parcel, 
      main.im_building building, 
      main.im_building_individual_unit indunit, 
      main.rt_right r,
      main.tp_face face,
      (SELECT
        building.nid AS building_nid,
        count( building_levels.im_levels ) AS levels,
        sum( st_area( face.geom ) ) AS area
      FROM
        main.im_building building,
        main.im_building_levels building_levels,
        main.tp_face face
      WHERE
        building.nid=building_levels.im_building AND
        face.gid=building_levels.projection
      GROUP BY building.nid) AS levels_for_building
    WHERE 
      face.gid=building.projection AND
      building.nid=levels_for_building.building_nid AND
      building.im_settlement=parcel.im_settlement AND 
      main.hrsz_concat(building.hrsz_main, building.hrsz_fraction)=main.hrsz_concat(parcel.hrsz_main,parcel.hrsz_fraction) AND
      building.nid=indunit.im_building AND
      indunit.nid=r.im_building_individual_unit AND
      r.rt_type=1 LOOP
    RETURN NEXT output;
  END LOOP;

  RETURN;
END;


$$;


ALTER FUNCTION main.identify_building() OWNER TO tdc;

--
-- Name: identify_building_individual_unit(); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION identify_building_individual_unit() RETURNS SETOF identify_building_individual_unit
    LANGUAGE plpgsql
    AS $$

DECLARE
  object_name text = 'im_building_individual_unit';
  immovable_type_1 integer = 1;
  immovable_type_2 integer = 2;
  immovable_type_3 integer = 3;
  immovable_type_4 integer = 4;
  output main.identify_building_individual_unit%rowtype;
BEGIN

  FOR output IN
    SELECT DISTINCT
      immovable_type_4 AS immovable_type,
      face.geom AS identify_geom,
      object_name AS identify__name, 
      indunit.nid AS identify_nid,
      indunitlevel.im_levels AS identify_level,
      building.im_settlement AS identify_settlement,
      main.hrsz_concat(building.hrsz_main, building.hrsz_fraction)||'/'||building.hrsz_eoi||'/'||indunit.hrsz_unit AS identify_hrsz,
      summary.sum_registered_area AS identify_registered_area,
      summary.sum_measured_area AS identify_measured_area
    FROM 
      main.im_building building, 
      main.im_building_individual_unit indunit, 
      main.im_building_individual_unit_level indunitlevel,
      main.tp_face face,
      (SELECT
        indunit.im_building im_building, 
        indunit.hrsz_unit hrsz_unit, 
        sum(st_area(face.geom)) sum_measured_area, 
        sum(unitlevel.area) sum_registered_area 
      FROM 
        main.im_building_individual_unit_level unitlevel, 
        main.im_building_individual_unit indunit,
        main.tp_face face
      WHERE 
        unitlevel.im_building=indunit.im_building AND
        unitlevel.hrsz_unit=indunit.hrsz_unit AND
        unitlevel.projection=face.gid
      GROUP BY indunit.im_building, indunit.hrsz_unit
      ) as summary
    WHERE
      summary.im_building=indunit.im_building AND
      summary.hrsz_unit=indunit.hrsz_unit AND
      building.nid=indunit.im_building AND
      indunit.im_building=indunitlevel.im_building AND
      indunit.hrsz_unit=indunitlevel.hrsz_unit AND
      indunitlevel.projection=face.gid

    LOOP
    RETURN NEXT output;
  END LOOP;

  RETURN;
END;

$$;


ALTER FUNCTION main.identify_building_individual_unit() OWNER TO tdc;

--
-- Name: identify_parcel(); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION identify_parcel() RETURNS SETOF identify_parcel
    LANGUAGE plpgsql
    AS $$

DECLARE
  object_name text = 'im_parcel';
  immovable_type_1 integer = 1;
  immovable_type_2 integer = 2;
  immovable_type_3 integer = 3;
  immovable_type_4 integer = 4;
  output main.identify_parcel%rowtype;
BEGIN


  ---------------------
  -- 1. Foldreszlet ---
  ---------------------
  --
  -- Van tulajdonjog az im_parcel-en, de nincs az im_parcel-nek kapcsolata im_building-gel
  --
  FOR output IN
    SELECT DISTINCT
      immovable_type_1 AS immovable_type,
      face.geom AS identify_geom,
      object_name AS identify_name, 
      parcel.nid AS identify_nid,
      parcel.im_settlement AS identify_settlement,
      main.hrsz_concat(parcel.hrsz_main, parcel.hrsz_fraction) AS identify_hrsz,
      parcel.area AS identify_registered_area,
      st_area(face.geom) AS identify_measured_area
    FROM 
      main.im_parcel parcel, 
      main.rt_right r,
      main.tp_face face
    WHERE 
       parcel.nid=r.im_parcel AND      
       r.rt_type=1 AND 
       face.gid=parcel.projection AND
       coalesce(parcel.im_settlement,'')||main.hrsz_concat(parcel.hrsz_main,parcel.hrsz_fraction) NOT IN (SELECT coalesce(im_settlement,'')||main.hrsz_concat(hrsz_main,hrsz_fraction) FROM main.im_building) 
    LOOP
    RETURN NEXT output;
  END LOOP;


  --------------------------------
  --2. Foldreszlet az epulettel --
  --------------------------------
  --
  -- Van tualjdonjog az im_parcel-en, van im_building kapcsolata, de az im_building-en nincsen tulajdonjog
  --
  FOR output IN
     SELECT DISTINCT
      immovable_type_2 AS immovable_type,
      face.geom AS identify_geom,
      object_name AS identify_name,
      parcel.nid AS identify_nid,      
      parcel.im_settlement AS identify_settlement,
      main.hrsz_concat(parcel.hrsz_main, parcel.hrsz_fraction) AS identify_hrsz,
      parcel.area AS identify_registered_area,
      st_area(face.geom) AS identify_measured_area
    FROM 
      main.im_parcel parcel, 
      main.rt_right r, 
      main.im_building building,
      main.tp_face face
    WHERE 
      parcel.nid=r.im_parcel AND 
      face.gid=parcel.projection AND
      r.rt_type=1 AND
      building.im_settlement=parcel.im_settlement AND 
      main.hrsz_concat(building.hrsz_main, building.hrsz_fraction)=main.hrsz_concat(parcel.hrsz_main,parcel.hrsz_fraction) AND
      building.nid NOT IN (SELECT coalesce(im_building, -1) FROM main.rt_right WHERE rt_type=1 ) 
    LOOP
    RETURN NEXT output;
  END LOOP;


  ----------------------------------------
  -- 3. Foldreszlet kulonallo epulettel --
  ----------------------------------------
  --
  -- Van tulajdonjog az im_parcel-en, es van egy masik tulajdonjog a hozza kapcsolodo buildin-en is
  --
  FOR output IN
    SELECT DISTINCT
      immovable_type_3 AS immovable_type,
      face.geom AS identify_geom,
      object_name AS identify_name, 
      parcel.nid AS identify_nid,
      parcel.im_settlement AS identify_settlement,
      main.hrsz_concat(parcel.hrsz_main, parcel.hrsz_fraction) AS identify_hrsz,
      parcel.area AS identify_registered_area,
      st_area(face.geom) AS identify_measured_area

    FROM 
      main.im_parcel parcel, 
      main.rt_right r, 
      main.im_building building,
      main.tp_face face
    WHERE 
       parcel.nid=r.im_parcel AND 
       face.gid=parcel.projection AND
       r.rt_type=1 AND
       building.im_settlement=parcel.im_settlement AND 
       main.hrsz_concat(building.hrsz_main, building.hrsz_fraction)=main.hrsz_concat(parcel.hrsz_main,parcel.hrsz_fraction) AND
       building.nid IN (SELECT im_building FROM main.rt_right r WHERE r.rt_type=1) 
    LOOP
    RETURN NEXT output;
  END LOOP;

------------------
-- 4. Tarsashaz --
------------------
--
-- Van im_building az im_parcel-en es tartozik hozza im_building_individual_unit
--
  FOR output IN
    SELECT DISTINCT
      immovable_type_4 AS immovable_type,
      face.geom AS identify_geom,
      object_name AS identify_name, 
      parcel.nid AS identify_nid,
      parcel.im_settlement AS identify_settlement,
      main.hrsz_concat(parcel.hrsz_main, parcel.hrsz_fraction) AS identify_hrsz,
      parcel.area AS identify_registered_area,
      st_area(face.geom) AS identify_measured_area
    FROM 
      main.im_parcel parcel, 
      main.im_building building, 
      main.im_building_individual_unit indunit, 
      main.rt_right r,
      main.tp_face face
    WHERE 
      face.gid=parcel.projection AND
      building.im_settlement=parcel.im_settlement AND 
      main.hrsz_concat(building.hrsz_main, building.hrsz_fraction)=main.hrsz_concat(parcel.hrsz_main,parcel.hrsz_fraction) AND
      building.nid=indunit.im_building AND
      indunit.nid=r.im_building_individual_unit AND
      r.rt_type=1 
    LOOP
    RETURN NEXT output;
  END LOOP;

  RETURN;
END; 

$$;


ALTER FUNCTION main.identify_parcel() OWNER TO tdc;

--
-- Name: FUNCTION identify_parcel(); Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON FUNCTION identify_parcel() IS 'Visszaadja az összes ingatlan típusba tartozó földrészlet adatait a következő formátumban:
selected_projection => a földrészlet vetületét ábrázoló polygon azonosítója a tp_face táblában
selected_name       => "im_parcel"
selected_id         => A földrészlet nid azonosítója (im_parcel táblában)
immovable_type      => 1, 2, 3 vagy 4. Föggően hogy az adott földrészleten van-e épület és az milyen kapcsolatban áll a földrészlettel';


--
-- Name: identify_point(); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION identify_point() RETURNS SETOF identify_point
    LANGUAGE plpgsql
    AS $$
DECLARE
  output main.identify_point%rowtype;
  selected_name text = 'sv_survey_point';
BEGIN

  FOR output in

    SELECT DISTINCT
      node.geom AS identify_geom,
      selected_name AS identify_name,
      surveypoint.nid AS identify_nid,
      surveypoint.name AS identify_point_name,
      surveypoint.description AS identify_point_description,
      point.quality AS identify_point_quality,
      document.date AS identify_point_measured_date,
      point.dimension AS identify_point_dimension,
      point.x AS identify_point_x,
      point.y AS identify_point_y,
      point.h AS identify_point_h
    FROM 
      main.im_building building,
      main.tp_face face,
      main.tp_node node,
      main.sv_survey_point surveypoint,
      main.sv_point point,
      main.sv_survey_document document,
      (
      SELECT 
        node.gid AS node_gid, 
        max(document.date) AS date
      FROM
        main.tp_node node,
        main.sv_survey_point surveypoint,
        main.sv_point point,
        main.sv_survey_document document
      WHERE
        node.gid=surveypoint.nid AND
        point.sv_survey_point=surveypoint.nid AND
        point.sv_survey_document=document.nid AND
        document.date<=current_date
      GROUP BY node.gid
      ) lastpoint
    WHERE
      building.projection=face.gid AND
      ARRAY[node.gid] <@ face.nodelist AND
      surveypoint.nid=node.gid AND
      point.sv_survey_point=surveypoint.nid AND
      point.sv_survey_document=document.nid AND
      lastpoint.date=document.date AND
      lastpoint.node_gid=node.gid

    UNION

    SELECT DISTINCT
      node.geom AS identify_geom,
      selected_name AS identify_name,
      surveypoint.nid AS identify_nid,
      surveypoint.name AS identify_point_name,
      surveypoint.description AS identify_point_description,
      point.quality AS identify_point_quality,
      document.date AS identify_point_measured_date,
      point.dimension AS identify_point_dimension,
      point.x AS identify_point_x,
      point.y AS identify_point_y,
      point.h AS identify_point_h
    FROM 
      main.im_parcel parcel,
      main.tp_face face,
      main.tp_node node,
      main.sv_survey_point surveypoint,
      main.sv_point point,
      main.sv_survey_document document,
      (
      SELECT 
        node.gid AS node_gid, 
        max(document.date) AS date
      FROM
        main.tp_node node,
        main.sv_survey_point surveypoint,
        main.sv_point point,
        main.sv_survey_document document
      WHERE
        node.gid=surveypoint.nid AND
        point.sv_survey_point=surveypoint.nid AND
        point.sv_survey_document=document.nid AND
        document.date<=current_date
      GROUP BY node.gid
      ) lastpoint
    WHERE
      parcel.projection=face.gid AND
      ARRAY[node.gid] <@ face.nodelist AND
      surveypoint.nid=node.gid AND
      point.sv_survey_point=surveypoint.nid AND
      point.sv_survey_document=document.nid AND
      lastpoint.date=document.date AND
      lastpoint.node_gid=node.gid

    LOOP
    RETURN NEXT output;
  END LOOP;
  RETURN;
END;

$$;


ALTER FUNCTION main.identify_point() OWNER TO tdc;

--
-- Name: query_object_points_building(bigint); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION query_object_points_building(selected_nid bigint) RETURNS SETOF query_point
    LANGUAGE plpgsql
    AS $$

DECLARE
  output main.query_point%rowtype;
BEGIN

  FOR output IN    
    SELECT DISTINCT
      building.projection AS found_projection,
      surveypoint.name AS point_name,
      surveypoint.description AS point_description,
      point.quality AS point_quality,
      document.date AS point_measured_date,
      point.x AS point_x,
      point.y AS point_y,
      point.h AS point_h
    FROM 
      main.im_building building,
      main.tp_volume volume,
      main.tp_face face,
      main.tp_node node,
      main.sv_survey_point surveypoint,
      main.sv_point point,
      main.sv_survey_document document,
      (
      SELECT node.gid AS node_gid, max(document.date) AS date
      FROM
        main.tp_node node,
        main.sv_survey_point surveypoint,
        main.sv_point point,
        main.sv_survey_document document
      WHERE
        node.gid=surveypoint.nid AND
        point.sv_survey_point=surveypoint.nid AND
        point.sv_survey_document=document.nid AND
        document.date<=current_date
      GROUP BY node.gid
      ) lastpoint
    WHERE
      selected_nid=building.nid AND
      building.model=volume.gid AND
      ARRAY[face.gid] <@ volume.facelist AND
      ARRAY[node.gid] <@ face.nodelist AND
      surveypoint.nid=node.gid AND
      point.sv_survey_point=surveypoint.nid AND
      point.sv_survey_document=document.nid AND
      lastpoint.date=document.date AND
      lastpoint.node_gid=node.gid
    ORDER BY point_name
    LOOP
    RETURN NEXT output;
  END LOOP;

  RETURN;
END;

$$;


ALTER FUNCTION main.query_object_points_building(selected_nid bigint) OWNER TO tdc;

--
-- Name: query_object_points_building_individual_unit(bigint, numeric); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION query_object_points_building_individual_unit(selected_nid bigint, visible_building_level numeric) RETURNS SETOF query_point
    LANGUAGE plpgsql
    AS $$

DECLARE
  output main.query_point%rowtype;
BEGIN

  FOR output IN    
    SELECT DISTINCT
      unitlevel.projection AS found_projection,
      surveypoint.name AS point_name,
      surveypoint.description AS point_description,
      point.quality AS point_quality,
      document.date AS point_measured_date,
      point.x AS point_x,
      point.y AS point_y,
      point.h AS point_h
    FROM 
      main.im_building_individual_unit indunit, 
      main.im_building_individual_unit_level unitlevel,
      main.tp_volume volume,
      main.tp_face face,
      main.tp_node node,
      main.sv_survey_point surveypoint,
      main.sv_point point,
      main.sv_survey_document document,
      (
      SELECT node.gid AS node_gid, max(document.date) AS date
      FROM
        main.tp_node node,
        main.sv_survey_point surveypoint,
        main.sv_point point,
        main.sv_survey_document document
      WHERE
        node.gid=surveypoint.nid AND
        point.sv_survey_point=surveypoint.nid AND
        point.sv_survey_document=document.nid AND
        document.date<=current_date
      GROUP BY node.gid
      ) lastpoint
    WHERE
      indunit.nid=selected_nid AND
      unitlevel.im_levels=visible_building_level AND
      unitlevel.im_building=indunit.im_building AND
      unitlevel.hrsz_unit=indunit.hrsz_unit AND
      indunit.model=volume.gid AND
      ARRAY[face.gid] <@ volume.facelist AND
      ARRAY[node.gid] <@ face.nodelist AND
      surveypoint.nid=node.gid AND
      point.sv_survey_point=surveypoint.nid AND
      point.sv_survey_document=document.nid AND
      lastpoint.date=document.date AND
      lastpoint.node_gid=node.gid
    ORDER BY point_name
    LOOP
    RETURN NEXT output;
  END LOOP;

  RETURN;
END;


$$;


ALTER FUNCTION main.query_object_points_building_individual_unit(selected_nid bigint, visible_building_level numeric) OWNER TO tdc;

--
-- Name: query_owner_building(integer, bigint); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION query_owner_building(immovable_type integer, selected_nid bigint) RETURNS SETOF query_owner
    LANGUAGE plpgsql
    AS $$

DECLARE
  output main.query_owner%rowtype;
BEGIN

---------------------
  -- 1. Foldreszlet ---
  ---------------------
  --
  -- Van tulajdonjog az im_parcel-en, de nincs az im_parcel-nek kapcsolata im_building-gel
  --
  --------------------------------
  --2. Foldreszlet az epulettel --
  --------------------------------
  --
  -- Van tualjdonjog az im_parcel-en, van im_building kapcsolata, de az im_building-en nincsen tulajdonjog
  --
  IF( immovable_type = 1 OR immovable_type = 2 ) THEN
    
    FOR output IN

      SELECT DISTINCT
        building.projection AS selected_projection,      
        person.name AS owner_name,
        r.share_numerator||'/'||r.share_denominator AS owner_share,
        document.date AS owner_contract_date
      FROM 
        main.im_parcel parcel, 
        main.rt_right r,
        main.rt_legal_document document,
        main.pn_person person,
        main.im_building building
      WHERE 
        building.nid=selected_nid AND
        building.im_settlement=parcel.im_settlement AND
        main.hrsz_concat(building.hrsz_main, building.hrsz_fraction)=main.hrsz_concat(parcel.hrsz_main,parcel.hrsz_fraction) AND
        parcel.nid=r.im_parcel AND      
        r.rt_type=1 AND 
        r.pn_person=person.nid AND
        r.rt_legal_document=document.nid
      LOOP
      RETURN NEXT output;
    END LOOP;


  ----------------------------------------
  -- 3. Foldreszlet kulonallo epulettel --
  ----------------------------------------
  --
  -- Van tulajdonjog az im_parcel-en, es van egy masik tulajdonjog a hozza kapcsolodo buildin-en is
  --
  ELSIF( immovable_type = 3 ) THEN
    
    FOR output IN

      SELECT DISTINCT
        building.projection AS selected_projection,      
        person.name AS owner_name,
        r.share_numerator||'/'||r.share_denominator AS owner_share,
        document.date AS owner_contract_date
      FROM 
        main.rt_right r,
        main.rt_legal_document document,
        main.pn_person person,
        main.im_building building
      WHERE
        building.nid=selected_nid AND
        building.nid=r.im_building AND      
        r.rt_type=1 AND 
        r.pn_person=person.nid AND
        r.rt_legal_document=document.nid
      LOOP
      RETURN NEXT output;
    END LOOP;

  ------------------
  -- 4. Tarsashaz --
  ------------------
  --
  -- Van im_building az im_parcel-en es tartozik hozza im_building_individual_unit
  --
  ELSIF ( immovable_type = 4 ) THEN

    FOR output IN

      SELECT DISTINCT
        building.projection AS selected_projection,      
        person.name AS owner_name,
        indunit.share_numerator||'/'||building.share_denominator||' ('||r.share_numerator||'/'||r.share_denominator||')' AS owner_share,
        document.date AS owner_contract_date,
        indunit.hrsz_unit  
      FROM        
        main.im_building building,
        main.im_building_individual_unit indunit, 
        main.rt_right r,
        main.rt_legal_document document,
        main.pn_person person
    WHERE
        building.nid=selected_nid AND
        building.nid=indunit.im_building AND
        r.rt_legal_document=document.nid AND
        r.pn_person=person.nid AND
        r.im_building_individual_unit=indunit.nid
    ORDER BY indunit.hrsz_unit
      LOOP
      RETURN NEXT output;
    END LOOP;
  END IF;

  RETURN;
END; 

$$;


ALTER FUNCTION main.query_owner_building(immovable_type integer, selected_nid bigint) OWNER TO tdc;

--
-- Name: query_owner_building_individual_unit(bigint, numeric); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION query_owner_building_individual_unit(selected_nid bigint, visible_building_level numeric) RETURNS SETOF query_owner
    LANGUAGE plpgsql
    AS $$

DECLARE
  output main.query_owner%rowtype;
BEGIN

  FOR output IN
    SELECT DISTINCT
      unitlevel.projection AS found_projection,
      person.name AS owner_name,
      r.share_numerator||'/'||r.share_denominator AS owner_share, 
      document.date AS owner_contract_date      
    FROM 
      main.im_building_individual_unit indunit, 
      main.rt_right r,
      main.rt_legal_document document,
      main.pn_person person,
      main.im_building_individual_unit_level unitlevel
    WHERE
      indunit.nid=selected_nid AND
      unitlevel.im_levels=visible_building_level AND
      r.rt_legal_document=document.nid AND
      r.pn_person=person.nid AND
      r.im_building_individual_unit=indunit.nid AND
      unitlevel.im_building=indunit.im_building AND
      unitlevel.hrsz_unit=indunit.hrsz_unit
    LOOP
    RETURN NEXT output;
  END LOOP;

  RETURN;
END;

$$;


ALTER FUNCTION main.query_owner_building_individual_unit(selected_nid bigint, visible_building_level numeric) OWNER TO tdc;

--
-- Name: query_owner_parcel(integer, bigint); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION query_owner_parcel(immovable_type integer, selected_nid bigint) RETURNS SETOF query_owner
    LANGUAGE plpgsql
    AS $$

DECLARE
  output main.query_owner%rowtype;
BEGIN


  ---------------------
  -- 1. Foldreszlet ---
  ---------------------
  --
  -- Van tulajdonjog az im_parcel-en, de nincs az im_parcel-nek kapcsolata im_building-gel
  --
  --------------------------------
  --2. Foldreszlet az epulettel --
  --------------------------------
  --
  -- Van tualjdonjog az im_parcel-en, van im_building kapcsolata, de az im_building-en nincsen tulajdonjog
  --

  ----------------------------------------
  -- 3. Foldreszlet kulonallo epulettel --
  ----------------------------------------
  --
  -- Van tulajdonjog az im_parcel-en, es van egy masik tulajdonjog a hozza kapcsolodo buildin-en is
  --
  IF( immovable_type = 1 OR immovable_type = 2 OR immovable_type = 3 ) THEN
    
    FOR output IN

      SELECT DISTINCT
        parcel.projection AS selected_projection,      
        person.name AS owner_name,
        r.share_numerator||'/'||r.share_denominator AS owner_share,
        document.date AS owner_contract_date
      FROM 
        main.im_parcel parcel, 
        main.rt_right r,
        main.rt_legal_document document,
        main.pn_person person,
        main.tp_face face
      WHERE 
        parcel.nid=selected_nid AND
        parcel.nid=r.im_parcel AND      
        r.rt_type=1 AND 
        r.pn_person=person.nid AND
        r.rt_legal_document=document.nid

      LOOP
      RETURN NEXT output;
    END LOOP;

  ------------------
  -- 4. Tarsashaz --
  ------------------
  --
  -- Van im_building az im_parcel-en es tartozik hozza im_building_individual_unit
  --
  ELSIF ( immovable_type = 4 ) THEN

    FOR output IN

      SELECT DISTINCT
        parcel.projection AS selected_projection,      
        person.name AS owner_name,
        indunit.share_numerator||'/'||building.share_denominator||' ('||r.share_numerator||'/'||r.share_denominator||')' AS owner_share,
        document.date AS owner_contract_date,
        indunit.hrsz_unit  
      FROM
        main.im_parcel parcel,
        main.im_building building,
        main.im_building_individual_unit indunit, 
        main.rt_right r,
        main.rt_legal_document document,
        main.pn_person person
    WHERE
        parcel.nid=selected_nid AND
        building.im_settlement=parcel.im_settlement AND
        main.hrsz_concat(building.hrsz_main, building.hrsz_fraction)=main.hrsz_concat(parcel.hrsz_main,parcel.hrsz_fraction) AND
        building.nid=indunit.im_building AND
        r.rt_legal_document=document.nid AND
        r.pn_person=person.nid AND
        r.im_building_individual_unit=indunit.nid
    ORDER BY indunit.hrsz_unit
      LOOP
      RETURN NEXT output;
    END LOOP;
  END IF;

  RETURN;
END; 

$$;


ALTER FUNCTION main.query_owner_parcel(immovable_type integer, selected_nid bigint) OWNER TO tdc;

--
-- Name: query_point_building(bigint); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION query_point_building(selected_nid bigint) RETURNS SETOF query_point
    LANGUAGE plpgsql
    AS $$

DECLARE
  output main.query_point%rowtype;
BEGIN

  FOR output IN    
    SELECT DISTINCT
      building.projection AS found_projection,
      surveypoint.name AS point_name,
      surveypoint.description AS point_description,
      point.quality AS point_quality,
      document.date AS point_measured_date,
      point.x AS point_x,
      point.y AS point_y,
      point.h AS point_h
    FROM 
      main.im_building building,
      main.tp_volume volume,
      main.tp_face face,
      main.tp_node node,
      main.sv_survey_point surveypoint,
      main.sv_point point,
      main.sv_survey_document document,
      (
      SELECT node.gid AS node_gid, max(document.date) AS date
      FROM
        main.tp_node node,
        main.sv_survey_point surveypoint,
        main.sv_point point,
        main.sv_survey_document document
      WHERE
        node.gid=surveypoint.nid AND
        point.sv_survey_point=surveypoint.nid AND
        point.sv_survey_document=document.nid AND
        document.date<=current_date
      GROUP BY node.gid
      ) lastpoint
    WHERE
      selected_nid=building.nid AND
      building.projection=face.gid AND
      ARRAY[face.gid] <@ volume.facelist AND
      ARRAY[node.gid] <@ face.nodelist AND
      surveypoint.nid=node.gid AND
      point.sv_survey_point=surveypoint.nid AND
      point.sv_survey_document=document.nid AND
      lastpoint.date=document.date AND
      lastpoint.node_gid=node.gid
    ORDER BY point_name
    LOOP
    RETURN NEXT output;
  END LOOP;

  RETURN;
END;

$$;


ALTER FUNCTION main.query_point_building(selected_nid bigint) OWNER TO tdc;

--
-- Name: query_point_building_individual_unit(bigint, numeric); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION query_point_building_individual_unit(selected_individual_unit_nid bigint, visible_building_level numeric) RETURNS SETOF query_point
    LANGUAGE plpgsql
    AS $$
DECLARE
  output main.query_point%rowtype;
BEGIN

  FOR output IN    
    SELECT DISTINCT
      unitlevel.projection AS found_projection,
      surveypoint.name AS point_name,
      surveypoint.description AS point_description,
      point.quality AS point_quality,
      document.date AS point_measured_date,
      point.x AS point_x,
      point.y AS point_y,
      point.h AS point_h
    FROM 
      main.im_building_individual_unit indunit, 
      main.im_building_individual_unit_level unitlevel,
      main.tp_volume volume,
      main.tp_face face,
      main.tp_node node,
      main.sv_survey_point surveypoint,
      main.sv_point point,
      main.sv_survey_document document,
      (
      SELECT node.gid AS node_gid, max(document.date) AS date
      FROM
        main.tp_node node,
        main.sv_survey_point surveypoint,
        main.sv_point point,
        main.sv_survey_document document
      WHERE
        node.gid=surveypoint.nid AND
        point.sv_survey_point=surveypoint.nid AND
        point.sv_survey_document=document.nid AND
        document.date<=current_date
      GROUP BY node.gid
      ) lastpoint
    WHERE
      indunit.nid=selected_individual_unit_nid AND
      unitlevel.im_levels=visible_building_level AND
      unitlevel.im_building=indunit.im_building AND
      unitlevel.hrsz_unit=indunit.hrsz_unit AND
      indunit.model=volume.gid AND
      ARRAY[face.gid] <@ volume.facelist AND
      ARRAY[node.gid] <@ face.nodelist AND
      surveypoint.nid=node.gid AND
      point.sv_survey_point=surveypoint.nid AND
      point.sv_survey_document=document.nid AND
      lastpoint.date=document.date AND
      lastpoint.node_gid=node.gid
    ORDER BY point_name
    LOOP
    RETURN NEXT output;
  END LOOP;

  RETURN;
END;
$$;


ALTER FUNCTION main.query_point_building_individual_unit(selected_individual_unit_nid bigint, visible_building_level numeric) OWNER TO tdc;

--
-- Name: query_point_parcel(bigint); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION query_point_parcel(selected_nid bigint) RETURNS SETOF query_point
    LANGUAGE plpgsql
    AS $$

DECLARE
  output main.query_point%rowtype;
BEGIN

  FOR output IN    
    SELECT DISTINCT
      parcel.projection AS found_projection,
      surveypoint.name AS point_name,
      surveypoint.description AS point_description,
      point.quality AS point_quality,
      document.date AS point_measured_date,
      point.x AS point_x,
      point.y AS point_y,
      point.h AS point_h
    FROM 
      main.im_parcel parcel,
      main.tp_volume volume,
      main.tp_face face,
      main.tp_node node,
      main.sv_survey_point surveypoint,
      main.sv_point point,
      main.sv_survey_document document,
      (
      SELECT node.gid AS node_gid, max(document.date) AS date
      FROM
        main.tp_node node,
        main.sv_survey_point surveypoint,
        main.sv_point point,
        main.sv_survey_document document
      WHERE
        node.gid=surveypoint.nid AND
        point.sv_survey_point=surveypoint.nid AND
        point.sv_survey_document=document.nid AND
        document.date<=current_date
      GROUP BY node.gid
      ) lastpoint
    WHERE
      selected_nid=parcel.nid AND
      parcel.projection=face.gid AND
      ARRAY[face.gid] <@ volume.facelist AND
      ARRAY[node.gid] <@ face.nodelist AND
      surveypoint.nid=node.gid AND
      point.sv_survey_point=surveypoint.nid AND
      point.sv_survey_document=document.nid AND
      lastpoint.date=document.date AND
      lastpoint.node_gid=node.gid
    ORDER BY point_name
    LOOP
    RETURN NEXT output;
  END LOOP;

  RETURN;
END;

$$;


ALTER FUNCTION main.query_point_parcel(selected_nid bigint) OWNER TO tdc;

--
-- Name: query_projection_points_building(bigint); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION query_projection_points_building(selected_nid bigint) RETURNS SETOF query_point
    LANGUAGE plpgsql
    AS $$

DECLARE
  output main.query_point%rowtype;
BEGIN

  FOR output IN    
    SELECT DISTINCT
      building.projection AS found_projection,
      surveypoint.name AS point_name,
      surveypoint.description AS point_description,
      point.quality AS point_quality,
      document.date AS point_measured_date,
      point.x AS point_x,
      point.y AS point_y,
      point.h AS point_h
    FROM 
      main.im_building building,
      main.tp_face face,
      main.tp_node node,
      main.sv_survey_point surveypoint,
      main.sv_point point,
      main.sv_survey_document document,
      (
      SELECT node.gid AS node_gid, max(document.date) AS date
      FROM
        main.tp_node node,
        main.sv_survey_point surveypoint,
        main.sv_point point,
        main.sv_survey_document document
      WHERE
        node.gid=surveypoint.nid AND
        point.sv_survey_point=surveypoint.nid AND
        point.sv_survey_document=document.nid AND
        document.date<=current_date
      GROUP BY node.gid
      ) lastpoint
    WHERE
      selected_nid=building.nid AND
      building.projection=face.gid AND
      ARRAY[node.gid] <@ face.nodelist AND
      surveypoint.nid=node.gid AND
      point.sv_survey_point=surveypoint.nid AND
      point.sv_survey_document=document.nid AND
      lastpoint.date=document.date AND
      lastpoint.node_gid=node.gid
    ORDER BY point_name
    LOOP
    RETURN NEXT output;
  END LOOP;

  RETURN;
END;

$$;


ALTER FUNCTION main.query_projection_points_building(selected_nid bigint) OWNER TO tdc;

--
-- Name: query_projection_points_parcel(bigint); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION query_projection_points_parcel(selected_nid bigint) RETURNS SETOF query_point
    LANGUAGE plpgsql
    AS $$

DECLARE
  output main.query_point%rowtype;
BEGIN

  FOR output IN    
    SELECT DISTINCT
      parcel.projection AS found_projection,
      surveypoint.name AS point_name,
      surveypoint.description AS point_description,
      point.quality AS point_quality,
      document.date AS point_measured_date,
      point.x AS point_x,
      point.y AS point_y,
      point.h AS point_h
    FROM 
      main.im_parcel parcel,
      main.tp_face face,
      main.tp_node node,
      main.sv_survey_point surveypoint,
      main.sv_point point,
      main.sv_survey_document document,
      (
      SELECT 
        node.gid AS node_gid, 
        max(document.date) AS date
      FROM
        main.tp_node node,
        main.sv_survey_point surveypoint,
        main.sv_point point,
        main.sv_survey_document document
      WHERE
        node.gid=surveypoint.nid AND
        point.sv_survey_point=surveypoint.nid AND
        point.sv_survey_document=document.nid AND
        document.date<=current_date
      GROUP BY node.gid
      ) lastpoint
    WHERE
      selected_nid=parcel.nid AND
      parcel.projection=face.gid AND
      ARRAY[node.gid] <@ face.nodelist AND
      surveypoint.nid=node.gid AND
      point.sv_survey_point=surveypoint.nid AND
      point.sv_survey_document=document.nid AND
      lastpoint.date=document.date AND
      lastpoint.node_gid=node.gid
    ORDER BY point_name
    LOOP
    RETURN NEXT output;
  END LOOP;

  RETURN;
END;


$$;


ALTER FUNCTION main.query_projection_points_parcel(selected_nid bigint) OWNER TO tdc;

--
-- Name: query_x3d(integer, text, bigint, numeric, numeric); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION query_x3d(immovable_type integer, selected_name text, selected_nid bigint, selected_x numeric, selected_y numeric) RETURNS SETOF query_x3d
    LANGUAGE plpgsql
    AS $$

DECLARE
  output main.query_x3d%rowtype;
  name_parcel text = 'im_parcel';
  name_building text = 'im_building';
  name_building_individual_unit text = 'im_building_individual_unit';
  name_point text = 'sv_survey_point';

  parcel_list bigint[];
  building_list bigint[];

--  geometry geometry = ST_GeomFromText( 'POLYGON( ( ' || selected_x-1 || ' ' || selected_y-1 || ', ' || selected_x+1 || ' ' || selected_y-1 || ', ' || selected_x+1 || ' ' || selected_y+1 || ', ' || selected_x-1 || ' ' || selected_y+1 || ', ' || selected_x-1 || ' ' || selected_y-1 || ') )' );

geometry geometry = ST_GeomFromText( 'POINT( ' || selected_x || ' ' || selected_y || ')', -1 );


BEGIN

  -------------------------------------------------------------------------------
  --                                                                           --
  -- Ebben a szekcióban attól függően, hogy milyen objektumot választottam ki, --
  -- Mindegyikhez megkeresem az összes geometriailag kapcsolódó parcellát      --
  -- és az ezekhez a parcellákhoz kapcsolódó épületeket, aluljárókat           --
  --                                                                           --
  -------------------------------------------------------------------------------

  ----------------------------
  -- Ha parcellát választottam
  ----------------------------
  IF ( selected_name=name_parcel ) THEN

    -- Garantáltan 1 parcellát találok
    parcel_list = ARRAY[ selected_nid ];

    -- Akár több épület is lehet a parcellán
    SELECT INTO building_list 
      array_agg( building.nid )
    FROM
      main.im_building building,
      main.im_parcel parcel,
      main.tp_face building_projection,
      main.tp_face parcel_projection
    WHERE
      parcel.nid = selected_nid AND
      building_projection.gid=building.projection AND
      parcel_projection.gid=parcel.projection AND
      st_contains(parcel_projection.geom, building_projection.geom);      

  ---------------------------
  -- Ha épületet választottam
  ---------------------------
  ELSIF( selected_name=name_building ) THEN

    -- Akár több parcella is érintett lehet a kiválasztott épülettel kapcsolatban
    SELECT INTO parcel_list 
      array_agg( parcel.nid )
    FROM
      main.im_building building,
      main.im_parcel parcel,
      main.tp_face building_projection,
      main.tp_face parcel_projection
    WHERE
      building.nid = selected_nid AND
      building_projection.gid=building.projection AND
      parcel_projection.gid=parcel.projection AND
      st_contains(parcel_projection.geom, building_projection.geom);  

    --A több vagy csak 1 parcellához pedig megkeresem az összes épületet    
    SELECT INTO building_list 
      array_agg( building.nid )
    FROM
      main.im_building building,
      main.im_parcel parcel,
      main.tp_face building_projection,
      main.tp_face parcel_projection
    WHERE
      ARRAY[parcel.nid] <@ parcel_list AND
      building_projection.gid=building.projection AND
      parcel_projection.gid=parcel.projection AND
      st_contains(parcel_projection.geom, building_projection.geom); 

  -----------------------------
  -- Ha egy lakást választottam
  -----------------------------
  ELSIF( selected_name=name_building_individual_unit ) THEN

    --Azonosítom a házat, de ez csak az első lépés, mert lehet azonos telken több ház is
    SELECT INTO building_list
      array_agg( building.nid )
    FROM
      main.im_building building,
      main.im_building_individual_unit indunit
    WHERE
      indunit.nid=selected_nid AND
      indunit.im_building=building.nid;

    --A házhoz azonosítom a telkeket
    SELECT INTO parcel_list 
      array_agg( parcel.nid )
    FROM
      main.im_building building,
      main.im_parcel parcel,
      main.tp_face building_projection,
      main.tp_face parcel_projection
    WHERE
      ARRAY[building.nid] <@ building_list  AND --persze itt a building_list csak 1 elemü
      building_projection.gid=building.projection AND
      parcel_projection.gid=parcel.projection AND
      st_contains(parcel_projection.geom, building_projection.geom);  
 
    --Most mar a parcellához azonosíthatom az összes épületet
    SELECT INTO building_list 
      array_agg( building.nid )
    FROM
      main.im_building building,
      main.im_parcel parcel,
      main.tp_face building_projection,
      main.tp_face parcel_projection
    WHERE
      ARRAY[parcel.nid] <@ parcel_list AND
      building_projection.gid=building.projection AND
      parcel_projection.gid=parcel.projection AND
      st_contains(parcel_projection.geom, building_projection.geom); 

  END IF;


  -------------------------------------------------------------------------------
  --                                                                           --
  -- Most rendelkezésemre áll az összes azonosító                              --
  --                                                                           --
  -------------------------------------------------------------------------------


  FOR output IN
    ---------------
    -- Parcellák --
    ---------------
    SELECT DISTINCT
      selected_nid AS query_base_nid,
      selected_name AS query_base_name,
      geometry AS query_base_geom,
      name_parcel AS query_object_name,
      parcel.nid AS query_object_nid,      
      main.hrsz_concat(parcel.hrsz_main,parcel.hrsz_fraction) AS query_object_title,
      CASE WHEN selected_name=name_parcel AND selected_nid=parcel.nid THEN TRUE ELSE FALSE END AS query_object_selected,
      ST_asx3d(volume.geom) AS query_object_x3d
    FROM
      main.im_parcel parcel,
      main.tp_volume volume
    WHERE
      parcel.model=volume.gid AND
      ARRAY[parcel.nid] <@ parcel_list

    UNION
    -----------------------------------
    -- Parcellákhoz tartozó pontok  --
    -----------------------------------
    SELECT DISTINCT
      selected_nid AS query_base_nid,
      selected_name AS query_base_name,
      geometry AS query_base_geom,
      name_point AS query_object_name,
      point.nid AS query_object_nid,      
      point.name  AS x3d_id,
      FALSE as query_object_selected,
      ST_X(node.geom) ||' ' || ST_Y(node.geom) || ' ' || ST_Z(node.geom)  AS query_object_x3d
    FROM
      main.im_parcel parcel,
      main.tp_volume volume,
      main.tp_face face,
      main.tp_node node,
      main.sv_survey_point point
    WHERE
      ARRAY[parcel.nid] <@ parcel_list AND
      parcel.projection=face.gid AND
      ARRAY[node.gid] <@ face.nodelist AND
      node.gid=point.nid

    UNION
    --------------
    -- Épületek --
    --------------  
    SELECT
      selected_nid AS query_base_nid,
      selected_name AS query_base_name,
      geometry AS query_base_geom,
--face.geom AS query_base_geom,
      name_building AS query_object_name,
      building.nid AS query_object_nid,      
      main.hrsz_concat(building.hrsz_main,building.hrsz_fraction) || CASE WHEN immovable_type=3 THEN '/'||building.hrsz_eoi ELSE '' END  AS x3d_id,
      CASE WHEN selected_name=name_building AND selected_nid=building.nid THEN TRUE ELSE FALSE END AS query_object_selected,
      ST_asx3d(volume.geom) AS query_object_x3d
    FROM
      main.im_building building,      
      main.tp_volume volume,
main.tp_face face
    WHERE
face.gid=building.projection AND
       building.model=volume.gid AND
       ARRAY[building.nid] <@ building_list
  
    UNION
    ----------------------
    -- Épületek pontjai --
    ----------------------
    SELECT
      selected_nid AS query_base_nid,
      selected_name AS query_base_name,
      geometry AS query_base_geom,
      name_point AS query_object_name,
      point.nid AS query_object_nid,      
      point.name  AS x3d_id,
      FALSE as query_object_selected,
      ST_X(node.geom) ||' ' || ST_Y(node.geom) || ' ' || ST_Z(node.geom)  AS query_object_x3d
    FROM
      main.im_building building,            
       main.tp_volume volume,
      main.tp_face face,
      main.tp_node node,
      main.sv_survey_point point
    WHERE
      ARRAY[building.nid] <@ building_list AND
      building.model=volume.gid AND
      ARRAY[face.gid] <@ volume.facelist AND
      ARRAY[node.gid] <@ face.nodelist AND
      node.gid=point.nid

    UNION

    ----------------------------------------------------------------
    -- Building parcellájához tartozó épületek individual unitjai --
    ----------------------------------------------------------------
    SELECT
      selected_nid AS query_base_nid,
      selected_name AS query_base_name,
      geometry AS query_base_geom,
      name_building_individual_unit AS query_object_name,
      indunit.nid AS query_object_nid,      
      main.hrsz_concat(building.hrsz_main,building.hrsz_fraction) || building.hrsz_eoi || '/' || indunit.hrsz_unit  AS x3d_id,
      CASE WHEN selected_name=name_building_individual_unit AND selected_nid=indunit.nid THEN TRUE ELSE FALSE END AS query_object_selected,
      ST_asx3d(volume.geom) AS query_object_x3d
    FROM
      main.im_building building,      
      main.tp_volume volume,
      main.im_building_individual_unit indunit
    WHERE
      ARRAY[building.nid] <@ building_list AND
      building.nid=indunit.im_building AND
      indunit.model=volume.gid

    LOOP
    RETURN NEXT output;
  END LOOP;   


 
  RETURN; 
END;
$$;


ALTER FUNCTION main.query_x3d(immovable_type integer, selected_name text, selected_nid bigint, selected_x numeric, selected_y numeric) OWNER TO tdc;

--
-- Name: sv_point_after(); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION sv_point_after() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$DECLARE
  nodegid bigint = NULL;
  spnid bigint = NULL;
BEGIN

  --
  -- Ha a sv_point-ban valtozas tortent, akkor a valtozast atvezeti a tp_node-ba.
  -- Ha az uj sv_point-hoz nem volt meg tp_node, akkor azt letrehozza
  --

  --Ha megvaltoztatok torlok vagy beszurok egy tp_point_3d-t
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' OR TG_OP='DELETE' ) THEN

    --Ha ujat rogzitek vagy regit modositok
    IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN

      --Akkor megnezi, hogy az uj sv_point-hoz van-e tp_node
      SELECT n.gid INTO nodegid FROM tp_node AS n, sv_survey_point AS sp, sv_point as p WHERE NEW.nid=p.nid AND p.sv_survey_point=sp.nid AND sp.nid=n.gid;

      --Ha van
      IF( nodegid IS NOT NULL ) THEN

        --Akkor update-elem, hogy aktivaljam a TRIGGER-et
        UPDATE tp_node SET gid=gid WHERE gid=nodegid; 
  
      --Nincs
      ELSE 

        --Megkeresi a ponthoz tartozo survey point-ot
        SELECT sp.nid INTO spnid FROM sv_survey_point AS sp WHERE sp.nid=NEW.sv_survey_point;

        --Letre hozok egy uj tp_node-ot
        INSERT INTO tp_node (gid) VALUES ( spnid );

      END IF;

    END IF;

    --Ha torlok vagy modositok
    IF(TG_OP='UPDATE' OR TG_OP='DELETE') THEN

      --Akkor frissitem a regi sv_point-hoz tartozo tp_node-ot. Es igy a tp_node triggerei aktivalodnak
      UPDATE tp_node AS n SET gid=gid from sv_survey_point AS sp WHERE OLD.sv_survey_point=sp.nid AND n.gid=sp.nid;

    END IF;

  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION main.sv_point_after() OWNER TO tdc;

--
-- Name: sv_point_before(); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION sv_point_before() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  pointnid bigint = NULL;
BEGIN

  --
  -- A dimenzio es az adatok konzisztenciajat vizsgalom
  --


  --Ha megvaltoztatok vagy beszurok egy sv_point-ot
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN

    --Ha 3 dimenzionak definialtam a pontot, de csak 2 koordinatat adtam meg
    IF(NEW.dimension = 3 AND NEW.h IS NULL) THEN
      RAISE EXCEPTION 'Hiányzik a H koordináta';
      RETURN NULL;

    --Ha 2 dimenzionak definialtam, akkor a H dimenzio erteke 0 lesz
    ELSIF(NEW.dimension = 2) THEN
      NEW.h := 0.0;

    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION main.sv_point_before() OWNER TO tdc;

--
-- Name: tp_face_after(); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION tp_face_after() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$DECLARE
  volume tp_volume%rowtype;
  facenumber integer;
  face_list bigint[];
BEGIN
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN
    
    --Csak azert hogy aktivalodjon a tp_volume trigger-e. Azok a volume-k amik tartalmazzak ezt a face-t
    UPDATE tp_volume AS v set facelist=facelist WHERE ARRAY[NEW.gid] <@ v.facelist;

  ELSIF(TG_OP='DELETE') THEN

    SELECT * INTO volume FROM tp_volume AS v WHERE ARRAY[OLD.gid] <@ v.facelist;

    IF FOUND THEN

      RAISE EXCEPTION 'Nem törölhetem ki a tp_face.gid: % Face-t mert van legalabb 1 tp_volume.gid: % Volume, ami tartalmazza. Facelist: %', OLD.gid, volume.gid, volume.facelist;

    END IF;

    -- Meg kell nezni, hogy a face-t tartalmazza-e egy masik face mint hole-t
    SELECT INTO face_list array_agg(f.gid) FROM tp_face AS f WHERE ARRAY[OLD.gid] <@ f.holelist;

    IF face_list IS NOT NULL THEN

      RAISE EXCEPTION 'Nem törölhetem ki a tp_face-t: % Face-t mert a következő tp_face-ek tartalmazzák a holelist mezőjükben: %', OLD.gid, face_list;


    END IF;


  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION main.tp_face_after() OWNER TO tdc;

--
-- Name: tp_face_before(); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION tp_face_before() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$DECLARE
  result boolean;

  pointlisttext_start text = '(';
  pointlisttext_end text = ')';
  pointlisttext text = '';
  pointlisttext_close text = '';

  isfirstpoint boolean = true;

  geomtext_start text = 'POLYGON(';
  geomtext text = '';
  geomtext_end text = ')';

  solidfacetext text = '';
  holefacetext text = '';

  position geod_position%rowtype;

  actualnode_gid bigint;
  actualface_gid bigint;
  nodel bigint[];

BEGIN
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN

    -- --------------------------------------------
    -- Eloszor a POLYGON felderitese es elkeszitese 
    -- --------------------------------------------

    select count(1)=array_upper(NEW.nodelist,1) INTO result FROM tp_node AS n WHERE ARRAY[n.gid] <@ NEW.nodelist;

    --Nem megfelelo meretu a lista
    if( NOT result  ) THEN
        RAISE EXCEPTION 'Nem vegrehajthato a tp_face INSERT/UPDATE. Rossz a nodelist lista: %', NEW.nodelist;
    END IF;

    isfirstpoint = true;
    pointlisttext = '';
    pointlisttext_close = '';

    --Vegig a csomopontokon
    FOREACH actualnode_gid IN ARRAY NEW.nodelist LOOP

      --csomopontok koordinatainak kideritese
      SELECT p.x, p.y, p.h INTO position FROM sv_survey_point AS sp, sv_point AS p, sv_survey_document AS sd, tp_node AS n WHERE n.gid=actualnode_gid AND n.gid=sp.nid AND p.sv_survey_point=sp.nid AND p.sv_survey_document=sd.nid AND sd.date<=current_date ORDER BY sd.date DESC LIMIT 1;   
      
      --Veszem a kovetkezo pontot
      pointlisttext = pointlisttext || position.x || ' ' || position.y || ' ' || position.h || ',';

      IF isfirstpoint THEN

        --Zarnom kell a poligont az elso ponttal
        pointlisttext_close = position.x || ' ' || position.y || ' ' || position.h;

      END IF;

      isfirstpoint=false;

    END LOOP;

    -- Itt rendelkezesemre all a polygon feluletet leiro koordinatasorozat (x1 y1 z1, ... x1 y1 z1) formaban
    solidfacetext = pointlisttext_start || pointlisttext || pointlisttext_close || pointlisttext_end;

    -- -------------------------------------------
    -- Majd a lyukak felderitese es elkeszitese 
    -- -------------------------------------------
    select count(1)=array_upper(NEW.holelist,1) INTO result FROM tp_face AS f WHERE ARRAY[f.gid] <@ NEW.holelist AND f.gid != NEW.gid;

    --Nem megfelelo meretu a lista
    if( NOT result  ) THEN
        RAISE EXCEPTION 'Nem vegrehajthato a tp_face INSERT/UPDATE. Rossz a holelist lista: %', NEW.holelist;
    END IF;

--raise exception 'hello %', coalesce( NEW.holelist, '{}' );

    --Vegig a lyukakat leiro feluleteken
    FOREACH actualface_gid IN ARRAY coalesce( NEW.holelist, '{}' ) LOOP

      --Elkerem az aktualis lyuk nodelist-jet 
      SELECT f.nodelist INTO nodel FROM tp_face AS f WHERE f.gid=actualface_gid;

      isfirstpoint = true;
      pointlisttext = '';
      pointlisttext_close = '';

      --Vegig a csomopontokon
      FOREACH actualnode_gid IN ARRAY nodel LOOP

        --csomopontok koordinatainak kideritese
        SELECT p.x, p.y, p.h INTO position FROM sv_survey_point AS sp, sv_point AS p, sv_survey_document AS sd, tp_node AS n WHERE n.gid=actualnode_gid AND n.gid=sp.nid AND p.sv_survey_point=sp.nid AND p.sv_survey_document=sd.nid AND sd.date<=current_date ORDER BY sd.date DESC LIMIT 1;   
-----      
        --Veszem a kovetkezo pontot
        pointlisttext = pointlisttext || position.x || ' ' || position.y || ' ' || position.h || ',';

        IF isfirstpoint THEN

          --Zarnom kell a poligont az elso ponttal
          pointlisttext_close = position.x || ' ' || position.y || ' ' || position.h;

        END IF;

        isfirstpoint=false;

      --Vege a csomopontnak
      END LOOP;

      holefacetext = holefacetext || ', ' || pointlisttext_start || pointlisttext || pointlisttext_close || pointlisttext_end;

    END LOOP;

    --Most irom at a geometriat az uj ertekekre
    geomtext = geomtext_start || solidfacetext || holefacetext || geomtext_end;

--raise exception 'hello %', geomtext;

    NEW.geom := public.ST_GeomFromText( geomtext, -1 ); 

  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION main.tp_face_before() OWNER TO tdc;

--
-- Name: tp_node_after(); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION tp_node_after() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$DECLARE
  face tp_face%rowtype;

  polygon_list bigint[];
  polygon_gid bigint;

  hole_list bigint[];
  hole_gid bigint;
BEGIN

  --
  -- Update-lem  a tp_face-t hogy aktivalodjon a tirggere es atvezesse a valtozasokat amiket itt vegeztem
  -- Torlest nem engedek, ha ez a node szerepel a tp_face-ben
  --

  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN
    
    -- Csak azert hogy aktivalodjon a tp_face trigger-e. Azok a face-ek amik tartalmazzak ezt a node-ot
    --UPDATE tp_face AS f set nodelist=nodelist WHERE ARRAY[NEW.gid] <@ f.nodelist;

    -- Osszegyujtom azokat a tp_face-eket melyekben a POLYGON zart felulet hasznalje azt a pontot
    SELECT INTO polygon_list array_agg(f.gid) FROM tp_face AS f WHERE ARRAY[NEW.gid] <@ f.nodelist;

    FOREACH polygon_gid IN ARRAY coalesce( polygon_list, '{}' ) LOOP
 
      --Ezeket update-lem
      UPDATE tp_face SET gid=gid WHERE gid=polygon_gid;

      -- Osszegyujtom azokat a tp_face-eket melyekneka holelist-je tartalmazza ezt a polygont
      SELECT INTO hole_list array_agg(f.gid) FROM tp_face AS f WHERE ARRAY[polygon_gid] <@ f.holelist;
      FOREACH hole_gid IN ARRAY coalesce( hole_list, '{}' ) LOOP

        UPDATE tp_face SET gid=gid WHERE gid=hole_gid;

      END LOOP;

    END LOOP;

  ELSIF(TG_OP='DELETE') THEN

    --Megnezem, hogy a torlendo tp_node szerepel-e a tp_face-ben
    SELECT * INTO face FROM tp_face AS f WHERE ARRAY[OLD.gid] <@ f.nodelist;

    --Ha igen
    IF FOUND THEN

      --Akokr nem engedem torolni
      RAISE EXCEPTION 'Nem törölhetem ki a csomópontot mert van legalabb 1 Face ami tartalmazza. gid: %, nodelist: %', OLD.gid, face.nodelist;

    END IF;

    RETURN OLD;

  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION main.tp_node_after() OWNER TO tdc;

--
-- Name: tp_node_before(); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION tp_node_before() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$DECLARE
  geomtext text = 'POINT(';
  geomtextend text = ')';
  position geod_position%rowtype;
BEGIN

  --
  -- Azt vizsgalom, hogy a megadott NODE ervenyes lehet-e
  --

  --Uj vagy modositas eseten
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN

    --Megkeresem uj tp_node-boz tartozo datum szerinti legutolso aktualis pont kooridinatait
    SELECT p.x, p.y, p.h INTO position FROM sv_point AS p, sv_survey_point AS sp, sv_survey_document AS sd WHERE NEW.gid=sp.nid AND sp.nid=p.sv_survey_point AND p.sv_survey_document=sd.nid AND sd.date<=current_date ORDER BY sd.date DESC LIMIT 1;   

    --Ha rendben van
    IF( position.x IS NOT NULL AND position.y IS NOT NULL AND position.h IS NOT NULL) THEN
      
      -- akkor a node geometriajat aktualizalja
      geomtext := geomtext || position.x || ' ' || position.y || ' ' || position.h || geomtextend;
      NEW.geom := public.ST_GeomFromText( geomtext, -1 );
    ELSE

      RAISE EXCEPTION 'Nem végrehajtható művelet. Ha végrehajtanám a % müveletetet, akkor nem letezne a tp_node-hoz sv_point.', TG_OP;

    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION main.tp_node_before() OWNER TO tdc;

--
-- Name: tp_volume_before(); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION tp_volume_before() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$DECLARE
  result boolean;
  
  pointlisttext text = '';
  pointlisttext_start text = '((';
  pointlisttext_end text = '))';
  pointlisttext_close text = '';

  facelisttext text = '';

  geomtext_start text = 'POLYHEDRALSURFACE(';
  geomtext_end text = ')';
  geomtext text = '';

  position geod_position%rowtype;
  isfirstnode boolean;
  isfirstface boolean = true;
  actualface bigint;
  actualnode bigint;
  ndlist bigint[];

BEGIN

  --Ha modositom, vagy ujat szurok be
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN

    --akkor megnezem, hogy a lista helyes-e. Letezo face-ek szerepelnek-e benne megfelelo szamban
    select count(1)=array_upper(NEW.facelist,1) INTO result FROM tp_face AS f WHERE ARRAY[f.gid] <@ NEW.facelist;

   --Ha nem megfelelo meretu a lista
    if( NOT result  ) THEN

        --akkor nem vegrehajthato a muvelet
        RAISE EXCEPTION 'Nem vegrehajthato a tp_volume INSERT/UPDATE. Rossz a lista: %', NEW.facelist;

    END IF;



    --Vegig a face-eken
    FOREACH actualface IN ARRAY NEW.facelist LOOP

      --A face csomopontjainak osszegyujtese
      SELECT f.nodelist INTO ndlist FROM tp_face as f WHERE f.gid=actualface;

      --valtozok elokeszitese a face osszeallitasahoz csomopontok alapjan
      isfirstnode=true;
      pointlisttext = '';
      pointlisttext_close = '';

      --Vegig a face csomopontjain
      FOREACH actualnode IN ARRAY ndlist LOOP

        --csomopontok koordinatainak kideritese
        SELECT p.x, p.y, p.h INTO position FROM sv_survey_point AS sp, sv_point AS p, sv_survey_document AS sd, tp_node AS n WHERE n.gid=actualnode AND n.gid=sp.nid AND p.sv_survey_point=sp.nid AND p.sv_survey_document=sd.nid AND sd.date<=current_date ORDER BY sd.date DESC LIMIT 1;   
      
        --Veszem a kovetkezo pontot
        pointlisttext = pointlisttext || position.x || ' ' || position.y || ' ' || position.h || ',';

        IF isfirstnode THEN

          --Zarnom kell a poligont az elso ponttal
          pointlisttext_close = position.x || ' ' || position.y || ' ' || position.h;

          --jelzem, hogy a kovetkezo pont mar nem az elso lesz
          isfirstnode=false;

        END IF;

      END LOOP;  --csomopont gyujto ciklus zarasa

      --Itt rendelkezesemre all egy (x1 y1 z1, x2 y2 z2, ... ) formatumu string
      pointlisttext = pointlisttext_start || pointlisttext || pointlisttext_close || pointlisttext_end;

      --Ha ez az elso face
      IF isfirstface THEN

        --akkor jelzem, hogy a kovetkezo mar nem az elso
        isfirstface=false;

      --Ha mar volt face
      ELSE

        --akkor az elejere kell egy vesszo
        facelisttext = facelisttext || ', ';

      END IF;

      facelisttext = facelisttext || pointlisttext;

    END LOOP;   --face gyujto ciklus zarasa

    geomtext = geomtext_start || facelisttext || geomtext_end;

    NEW.geom := public.ST_GeomFromText( geomtext, -1 );
   
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION main.tp_volume_before() OWNER TO tdc;

--
-- Name: view_building(); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION view_building() RETURNS SETOF view_building
    LANGUAGE plpgsql
    AS $$
DECLARE
  output main.view_building%rowtype;
BEGIN

  FOR output in
    SELECT 
      face.geom AS view_geom,  
      building.nid AS view_nid,
      building.hrsz_eoi AS view_hrsz_eoi, 
      building.title_angle AS view_angle 
    FROM 
      main.im_building AS building, 
      main.tp_face AS face 
    WHERE 
      building.projection=face.gid
    LOOP
    RETURN NEXT output;
  END LOOP;
  RETURN;
END;

$$;


ALTER FUNCTION main.view_building() OWNER TO tdc;

--
-- Name: view_building_individual_unit(numeric); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION view_building_individual_unit(visible_building_level numeric) RETURNS SETOF view_building_individual_unit
    LANGUAGE plpgsql
    AS $$
DECLARE
  output main.view_building_individual_unit%rowtype;
BEGIN

  FOR output in

    SELECT 
      face.geom AS view_geom, 
      unit.nid AS view_nid
    FROM 
      main.im_building_individual_unit unit, 
      main.im_building_individual_unit_level unitlevel, 
      main.tp_face face 
    WHERE 
      unitlevel.im_levels=visible_building_level AND
      unit.im_building=unitlevel.im_building AND 
      unit.hrsz_unit=unitlevel.hrsz_unit AND 
      unitlevel.projection=face.gid
    LOOP
    RETURN NEXT output;
  END LOOP;
  RETURN;
END;

$$;


ALTER FUNCTION main.view_building_individual_unit(visible_building_level numeric) OWNER TO tdc;

--
-- Name: view_parcel(); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION view_parcel() RETURNS SETOF view_parcel
    LANGUAGE plpgsql
    AS $$
DECLARE
  output main.view_parcel%rowtype;
BEGIN

  FOR output in
    SELECT 
      face.geom AS view_geom, 
      parcel.nid AS veiw_nid, 
      main.hrsz_concat(parcel.hrsz_main, parcel.hrsz_fraction ) AS view_hrsz, 
      parcel.title_angle AS view_angle
    FROM 
      main.im_parcel AS parcel, 
      main.tp_face AS face 
    WHERE 
      parcel.projection=face.gid

    LOOP
    RETURN NEXT output;
  END LOOP;
  RETURN;
END;

$$;


ALTER FUNCTION main.view_parcel() OWNER TO tdc;

--
-- Name: view_point(); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION view_point() RETURNS SETOF view_point
    LANGUAGE plpgsql
    AS $$
DECLARE
  output main.view_point%rowtype;
BEGIN

  FOR output in
    SELECT
      node.geom AS view_geom,
      surveypoint.name AS view_name,
      surveypoint.nid AS view_nid
    FROM
      main.im_building building,
      main.tp_face face,
      main.tp_node node,
      main.sv_survey_point surveypoint
    WHERE
      building.projection=face.gid AND     
      ARRAY[node.gid] <@ face.nodelist AND
      surveypoint.nid=node.gid
    UNION
    SELECT DISTINCT
      node.geom AS view_geom,
      surveypoint.name AS view_name,
      surveypoint.nid AS view_nid
    FROM 
      main.im_parcel parcel,
      main.tp_face face,
      main.tp_node node,
      main.sv_survey_point surveypoint
    WHERE
      parcel.projection=face.gid AND     
      ARRAY[node.gid] <@ face.nodelist AND
      surveypoint.nid=node.gid
    LOOP
    RETURN NEXT output;
  END LOOP;
  RETURN;
END;

$$;


ALTER FUNCTION main.view_point() OWNER TO tdc;

SET search_path = public, pg_catalog;

--
-- Name: _st_3ddfullywithin(geometry, geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_3ddfullywithin(geom1 geometry, geom2 geometry, double precision) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'LWGEOM_dfullywithin3d';


ALTER FUNCTION public._st_3ddfullywithin(geom1 geometry, geom2 geometry, double precision) OWNER TO postgres;

--
-- Name: _st_3ddwithin(geometry, geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_3ddwithin(geom1 geometry, geom2 geometry, double precision) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'LWGEOM_dwithin3d';


ALTER FUNCTION public._st_3ddwithin(geom1 geometry, geom2 geometry, double precision) OWNER TO postgres;

--
-- Name: _st_asgeojson(integer, geometry, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_asgeojson(integer, geometry, integer, integer) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_asGeoJson';


ALTER FUNCTION public._st_asgeojson(integer, geometry, integer, integer) OWNER TO postgres;

--
-- Name: _st_asgeojson(integer, geography, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_asgeojson(integer, geography, integer, integer) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_as_geojson';


ALTER FUNCTION public._st_asgeojson(integer, geography, integer, integer) OWNER TO postgres;

--
-- Name: _st_asgml(integer, geometry, integer, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_asgml(integer, geometry, integer, integer, text) RETURNS text
    LANGUAGE c IMMUTABLE
    AS '$libdir/postgis-2.0', 'LWGEOM_asGML';


ALTER FUNCTION public._st_asgml(integer, geometry, integer, integer, text) OWNER TO postgres;

--
-- Name: _st_asgml(integer, geography, integer, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_asgml(integer, geography, integer, integer, text) RETURNS text
    LANGUAGE c IMMUTABLE
    AS '$libdir/postgis-2.0', 'geography_as_gml';


ALTER FUNCTION public._st_asgml(integer, geography, integer, integer, text) OWNER TO postgres;

--
-- Name: _st_askml(integer, geometry, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_askml(integer, geometry, integer, text) RETURNS text
    LANGUAGE c IMMUTABLE
    AS '$libdir/postgis-2.0', 'LWGEOM_asKML';


ALTER FUNCTION public._st_askml(integer, geometry, integer, text) OWNER TO postgres;

--
-- Name: _st_askml(integer, geography, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_askml(integer, geography, integer, text) RETURNS text
    LANGUAGE c IMMUTABLE
    AS '$libdir/postgis-2.0', 'geography_as_kml';


ALTER FUNCTION public._st_askml(integer, geography, integer, text) OWNER TO postgres;

--
-- Name: _st_asx3d(integer, geometry, integer, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_asx3d(integer, geometry, integer, integer, text) RETURNS text
    LANGUAGE c IMMUTABLE
    AS '$libdir/postgis-2.0', 'LWGEOM_asX3D';


ALTER FUNCTION public._st_asx3d(integer, geometry, integer, integer, text) OWNER TO postgres;

--
-- Name: _st_bestsrid(geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_bestsrid(geography) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT _ST_BestSRID($1,$1)$_$;


ALTER FUNCTION public._st_bestsrid(geography) OWNER TO postgres;

--
-- Name: _st_bestsrid(geography, geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_bestsrid(geography, geography) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_bestsrid';


ALTER FUNCTION public._st_bestsrid(geography, geography) OWNER TO postgres;

--
-- Name: _st_buffer(geometry, double precision, cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_buffer(geometry, double precision, cstring) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'buffer';


ALTER FUNCTION public._st_buffer(geometry, double precision, cstring) OWNER TO postgres;

--
-- Name: _st_concavehull(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_concavehull(param_inputgeom geometry) RETURNS geometry
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
	DECLARE     
	vexhull GEOMETRY;
	var_resultgeom geometry;
	var_inputgeom geometry;
	vexring GEOMETRY;
	cavering GEOMETRY;
	cavept geometry[];
	seglength double precision;
	var_tempgeom geometry;
	scale_factor integer := 1;
	i integer;
	
	BEGIN

		-- First compute the ConvexHull of the geometry
		vexhull := ST_ConvexHull(param_inputgeom);
		var_inputgeom := param_inputgeom;
		--A point really has no concave hull
		IF ST_GeometryType(vexhull) = 'ST_Point' OR ST_GeometryType(vexHull) = 'ST_LineString' THEN
			RETURN vexhull;
		END IF;

		-- convert the hull perimeter to a linestring so we can manipulate individual points
		vexring := CASE WHEN ST_GeometryType(vexhull) = 'ST_LineString' THEN vexhull ELSE ST_ExteriorRing(vexhull) END;
		IF abs(ST_X(ST_PointN(vexring,1))) < 1 THEN --scale the geometry to prevent stupid precision errors - not sure it works so make low for now
			scale_factor := 100;
			vexring := ST_Scale(vexring, scale_factor,scale_factor);
			var_inputgeom := ST_Scale(var_inputgeom, scale_factor, scale_factor);
			--RAISE NOTICE 'Scaling';
		END IF;
		seglength := ST_Length(vexring)/least(ST_NPoints(vexring)*2,1000) ;

		vexring := ST_Segmentize(vexring, seglength);
		-- find the point on the original geom that is closest to each point of the convex hull and make a new linestring out of it.
		cavering := ST_Collect(
			ARRAY(

				SELECT 
					ST_ClosestPoint(var_inputgeom, pt ) As the_geom
					FROM (
						SELECT  ST_PointN(vexring, n ) As pt, n
							FROM 
							generate_series(1, ST_NPoints(vexring) ) As n
						) As pt
				
				)
			)
		; 
		

		var_resultgeom := ST_MakeLine(geom) 
			FROM ST_Dump(cavering) As foo;

		IF ST_IsSimple(var_resultgeom) THEN
			var_resultgeom := ST_MakePolygon(var_resultgeom);
			--RAISE NOTICE 'is Simple: %', var_resultgeom;
		ELSE 
			--RAISE NOTICE 'is not Simple: %', var_resultgeom;
			var_resultgeom := ST_ConvexHull(var_resultgeom);
		END IF;
		
		IF scale_factor > 1 THEN -- scale the result back
			var_resultgeom := ST_Scale(var_resultgeom, 1/scale_factor, 1/scale_factor);
		END IF;
		RETURN var_resultgeom;
	
	END;
$$;


ALTER FUNCTION public._st_concavehull(param_inputgeom geometry) OWNER TO postgres;

--
-- Name: _st_contains(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_contains(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'contains';


ALTER FUNCTION public._st_contains(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: _st_containsproperly(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_containsproperly(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'containsproperly';


ALTER FUNCTION public._st_containsproperly(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: _st_coveredby(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_coveredby(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'coveredby';


ALTER FUNCTION public._st_coveredby(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: _st_covers(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_covers(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'covers';


ALTER FUNCTION public._st_covers(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: _st_covers(geography, geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_covers(geography, geography) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'geography_covers';


ALTER FUNCTION public._st_covers(geography, geography) OWNER TO postgres;

--
-- Name: _st_crosses(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_crosses(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'crosses';


ALTER FUNCTION public._st_crosses(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: _st_dfullywithin(geometry, geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_dfullywithin(geom1 geometry, geom2 geometry, double precision) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_dfullywithin';


ALTER FUNCTION public._st_dfullywithin(geom1 geometry, geom2 geometry, double precision) OWNER TO postgres;

--
-- Name: _st_distance(geography, geography, double precision, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_distance(geography, geography, double precision, boolean) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'geography_distance';


ALTER FUNCTION public._st_distance(geography, geography, double precision, boolean) OWNER TO postgres;

--
-- Name: _st_dumppoints(geometry, integer[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_dumppoints(the_geom geometry, cur_path integer[]) RETURNS SETOF geometry_dump
    LANGUAGE plpgsql
    AS $$
DECLARE
  tmp geometry_dump;
  tmp2 geometry_dump;
  nb_points integer;
  nb_geom integer;
  i integer;
  j integer;
  g geometry;
  
BEGIN
  
  -- RAISE DEBUG '%,%', cur_path, ST_GeometryType(the_geom);

  -- Special case collections : iterate and return the DumpPoints of the geometries

  IF (ST_IsCollection(the_geom)) THEN
 
    i = 1;
    FOR tmp2 IN SELECT (ST_Dump(the_geom)).* LOOP

      FOR tmp IN SELECT * FROM _ST_DumpPoints(tmp2.geom, cur_path || tmp2.path) LOOP
	    RETURN NEXT tmp;
      END LOOP;
      i = i + 1;
      
    END LOOP;

    RETURN;
  END IF;
  

  -- Special case (POLYGON) : return the points of the rings of a polygon
  IF (ST_GeometryType(the_geom) = 'ST_Polygon') THEN

    FOR tmp IN SELECT * FROM _ST_DumpPoints(ST_ExteriorRing(the_geom), cur_path || ARRAY[1]) LOOP
      RETURN NEXT tmp;
    END LOOP;
    
    j := ST_NumInteriorRings(the_geom);
    FOR i IN 1..j LOOP
        FOR tmp IN SELECT * FROM _ST_DumpPoints(ST_InteriorRingN(the_geom, i), cur_path || ARRAY[i+1]) LOOP
          RETURN NEXT tmp;
        END LOOP;
    END LOOP;
    
    RETURN;
  END IF;

  -- Special case (TRIANGLE) : return the points of the external rings of a TRIANGLE
  IF (ST_GeometryType(the_geom) = 'ST_Triangle') THEN

    FOR tmp IN SELECT * FROM _ST_DumpPoints(ST_ExteriorRing(the_geom), cur_path || ARRAY[1]) LOOP
      RETURN NEXT tmp;
    END LOOP;
    
    RETURN;
  END IF;

    
  -- Special case (POINT) : return the point
  IF (ST_GeometryType(the_geom) = 'ST_Point') THEN

    tmp.path = cur_path || ARRAY[1];
    tmp.geom = the_geom;

    RETURN NEXT tmp;
    RETURN;

  END IF;


  -- Use ST_NumPoints rather than ST_NPoints to have a NULL value if the_geom isn't
  -- a LINESTRING, CIRCULARSTRING.
  SELECT ST_NumPoints(the_geom) INTO nb_points;

  -- This should never happen
  IF (nb_points IS NULL) THEN
    RAISE EXCEPTION 'Unexpected error while dumping geometry %', ST_AsText(the_geom);
  END IF;

  FOR i IN 1..nb_points LOOP
    tmp.path = cur_path || ARRAY[i];
    tmp.geom := ST_PointN(the_geom, i);
    RETURN NEXT tmp;
  END LOOP;
   
END
$$;


ALTER FUNCTION public._st_dumppoints(the_geom geometry, cur_path integer[]) OWNER TO postgres;

--
-- Name: _st_dwithin(geometry, geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_dwithin(geom1 geometry, geom2 geometry, double precision) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'LWGEOM_dwithin';


ALTER FUNCTION public._st_dwithin(geom1 geometry, geom2 geometry, double precision) OWNER TO postgres;

--
-- Name: _st_dwithin(geography, geography, double precision, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_dwithin(geography, geography, double precision, boolean) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'geography_dwithin';


ALTER FUNCTION public._st_dwithin(geography, geography, double precision, boolean) OWNER TO postgres;

--
-- Name: _st_equals(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_equals(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'ST_Equals';


ALTER FUNCTION public._st_equals(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: _st_expand(geography, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_expand(geography, double precision) RETURNS geography
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_expand';


ALTER FUNCTION public._st_expand(geography, double precision) OWNER TO postgres;

--
-- Name: _st_geomfromgml(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_geomfromgml(text, integer) RETURNS geometry
    LANGUAGE c IMMUTABLE
    AS '$libdir/postgis-2.0', 'geom_from_gml';


ALTER FUNCTION public._st_geomfromgml(text, integer) OWNER TO postgres;

--
-- Name: _st_intersects(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_intersects(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'intersects';


ALTER FUNCTION public._st_intersects(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: _st_linecrossingdirection(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_linecrossingdirection(geom1 geometry, geom2 geometry) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'ST_LineCrossingDirection';


ALTER FUNCTION public._st_linecrossingdirection(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: _st_longestline(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_longestline(geom1 geometry, geom2 geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_longestline2d';


ALTER FUNCTION public._st_longestline(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: _st_maxdistance(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_maxdistance(geom1 geometry, geom2 geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_maxdistance2d_linestring';


ALTER FUNCTION public._st_maxdistance(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: _st_orderingequals(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_orderingequals(geometrya geometry, geometryb geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'LWGEOM_same';


ALTER FUNCTION public._st_orderingequals(geometrya geometry, geometryb geometry) OWNER TO postgres;

--
-- Name: _st_overlaps(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_overlaps(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'overlaps';


ALTER FUNCTION public._st_overlaps(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: _st_pointoutside(geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_pointoutside(geography) RETURNS geography
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_point_outside';


ALTER FUNCTION public._st_pointoutside(geography) OWNER TO postgres;

--
-- Name: _st_touches(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_touches(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'touches';


ALTER FUNCTION public._st_touches(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: _st_within(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_within(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT _ST_Contains($2,$1)$_$;


ALTER FUNCTION public._st_within(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: addauth(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION addauth(text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$ 
DECLARE
	lockid alias for $1;
	okay boolean;
	myrec record;
BEGIN
	-- check to see if table exists
	--  if not, CREATE TEMP TABLE mylock (transid xid, lockcode text)
	okay := 'f';
	FOR myrec IN SELECT * FROM pg_class WHERE relname = 'temp_lock_have_table' LOOP
		okay := 't';
	END LOOP; 
	IF (okay <> 't') THEN 
		CREATE TEMP TABLE temp_lock_have_table (transid xid, lockcode text);
			-- this will only work from pgsql7.4 up
			-- ON COMMIT DELETE ROWS;
	END IF;

	--  INSERT INTO mylock VALUES ( $1)
--	EXECUTE 'INSERT INTO temp_lock_have_table VALUES ( '||
--		quote_literal(getTransactionID()) || ',' ||
--		quote_literal(lockid) ||')';

	INSERT INTO temp_lock_have_table VALUES (getTransactionID(), lockid);

	RETURN true::boolean;
END;
$_$;


ALTER FUNCTION public.addauth(text) OWNER TO postgres;

--
-- Name: FUNCTION addauth(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION addauth(text) IS 'args: auth_token - Add an authorization token to be used in current transaction.';


--
-- Name: addgeometrycolumn(character varying, character varying, integer, character varying, integer, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean DEFAULT true) RETURNS text
    LANGUAGE plpgsql STRICT
    AS $_$
DECLARE
	ret  text;
BEGIN
	SELECT AddGeometryColumn('','',$1,$2,$3,$4,$5, $6) into ret;
	RETURN ret;
END;
$_$;


ALTER FUNCTION public.addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) OWNER TO postgres;

--
-- Name: FUNCTION addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) IS 'args: table_name, column_name, srid, type, dimension, use_typmod=true - Adds a geometry column to an existing table of attributes. By default uses type modifier to define rather than constraints. Pass in false for use_typmod to get old check constraint based behavior';


--
-- Name: addgeometrycolumn(character varying, character varying, character varying, integer, character varying, integer, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean DEFAULT true) RETURNS text
    LANGUAGE plpgsql STABLE STRICT
    AS $_$
DECLARE
	ret  text;
BEGIN
	SELECT AddGeometryColumn('',$1,$2,$3,$4,$5,$6,$7) into ret;
	RETURN ret;
END;
$_$;


ALTER FUNCTION public.addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) OWNER TO postgres;

--
-- Name: FUNCTION addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) IS 'args: schema_name, table_name, column_name, srid, type, dimension, use_typmod=true - Adds a geometry column to an existing table of attributes. By default uses type modifier to define rather than constraints. Pass in false for use_typmod to get old check constraint based behavior';


--
-- Name: addgeometrycolumn(character varying, character varying, character varying, character varying, integer, character varying, integer, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean DEFAULT true) RETURNS text
    LANGUAGE plpgsql STRICT
    AS $$
DECLARE
	rec RECORD;
	sr varchar;
	real_schema name;
	sql text;
	new_srid integer;

BEGIN

	-- Verify geometry type
	IF (postgis_type_name(new_type,new_dim) IS NULL )
	THEN
		RAISE EXCEPTION 'Invalid type name "%(%)" - valid ones are:
	POINT, MULTIPOINT,
	LINESTRING, MULTILINESTRING,
	POLYGON, MULTIPOLYGON,
	CIRCULARSTRING, COMPOUNDCURVE, MULTICURVE,
	CURVEPOLYGON, MULTISURFACE,
	GEOMETRY, GEOMETRYCOLLECTION,
	POINTM, MULTIPOINTM,
	LINESTRINGM, MULTILINESTRINGM,
	POLYGONM, MULTIPOLYGONM,
	CIRCULARSTRINGM, COMPOUNDCURVEM, MULTICURVEM
	CURVEPOLYGONM, MULTISURFACEM, TRIANGLE, TRIANGLEM,
	POLYHEDRALSURFACE, POLYHEDRALSURFACEM, TIN, TINM
	or GEOMETRYCOLLECTIONM', new_type, new_dim;
		RETURN 'fail';
	END IF;


	-- Verify dimension
	IF ( (new_dim >4) OR (new_dim <2) ) THEN
		RAISE EXCEPTION 'invalid dimension';
		RETURN 'fail';
	END IF;

	IF ( (new_type LIKE '%M') AND (new_dim!=3) ) THEN
		RAISE EXCEPTION 'TypeM needs 3 dimensions';
		RETURN 'fail';
	END IF;


	-- Verify SRID
	IF ( new_srid_in > 0 ) THEN
		IF new_srid_in > 998999 THEN
			RAISE EXCEPTION 'AddGeometryColumn() - SRID must be <= %', 998999;
		END IF;
		new_srid := new_srid_in;
		SELECT SRID INTO sr FROM spatial_ref_sys WHERE SRID = new_srid;
		IF NOT FOUND THEN
			RAISE EXCEPTION 'AddGeometryColumn() - invalid SRID';
			RETURN 'fail';
		END IF;
	ELSE
		new_srid := ST_SRID('POINT EMPTY'::geometry);
		IF ( new_srid_in != new_srid ) THEN
			RAISE NOTICE 'SRID value % converted to the officially unknown SRID value %', new_srid_in, new_srid;
		END IF;
	END IF;


	-- Verify schema
	IF ( schema_name IS NOT NULL AND schema_name != '' ) THEN
		sql := 'SELECT nspname FROM pg_namespace ' ||
			'WHERE text(nspname) = ' || quote_literal(schema_name) ||
			'LIMIT 1';
		RAISE DEBUG '%', sql;
		EXECUTE sql INTO real_schema;

		IF ( real_schema IS NULL ) THEN
			RAISE EXCEPTION 'Schema % is not a valid schemaname', quote_literal(schema_name);
			RETURN 'fail';
		END IF;
	END IF;

	IF ( real_schema IS NULL ) THEN
		RAISE DEBUG 'Detecting schema';
		sql := 'SELECT n.nspname AS schemaname ' ||
			'FROM pg_catalog.pg_class c ' ||
			  'JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace ' ||
			'WHERE c.relkind = ' || quote_literal('r') ||
			' AND n.nspname NOT IN (' || quote_literal('pg_catalog') || ', ' || quote_literal('pg_toast') || ')' ||
			' AND pg_catalog.pg_table_is_visible(c.oid)' ||
			' AND c.relname = ' || quote_literal(table_name);
		RAISE DEBUG '%', sql;
		EXECUTE sql INTO real_schema;

		IF ( real_schema IS NULL ) THEN
			RAISE EXCEPTION 'Table % does not occur in the search_path', quote_literal(table_name);
			RETURN 'fail';
		END IF;
	END IF;


	-- Add geometry column to table
	IF use_typmod THEN
	     sql := 'ALTER TABLE ' ||
            quote_ident(real_schema) || '.' || quote_ident(table_name)
            || ' ADD COLUMN ' || quote_ident(column_name) ||
            ' geometry(' || postgis_type_name(new_type, new_dim) || ', ' || new_srid::text || ')';
        RAISE DEBUG '%', sql;
	ELSE
        sql := 'ALTER TABLE ' ||
            quote_ident(real_schema) || '.' || quote_ident(table_name)
            || ' ADD COLUMN ' || quote_ident(column_name) ||
            ' geometry ';
        RAISE DEBUG '%', sql;
    END IF;
	EXECUTE sql;

	IF NOT use_typmod THEN
        -- Add table CHECKs
        sql := 'ALTER TABLE ' ||
            quote_ident(real_schema) || '.' || quote_ident(table_name)
            || ' ADD CONSTRAINT '
            || quote_ident('enforce_srid_' || column_name)
            || ' CHECK (st_srid(' || quote_ident(column_name) ||
            ') = ' || new_srid::text || ')' ;
        RAISE DEBUG '%', sql;
        EXECUTE sql;
    
        sql := 'ALTER TABLE ' ||
            quote_ident(real_schema) || '.' || quote_ident(table_name)
            || ' ADD CONSTRAINT '
            || quote_ident('enforce_dims_' || column_name)
            || ' CHECK (st_ndims(' || quote_ident(column_name) ||
            ') = ' || new_dim::text || ')' ;
        RAISE DEBUG '%', sql;
        EXECUTE sql;
    
        IF ( NOT (new_type = 'GEOMETRY')) THEN
            sql := 'ALTER TABLE ' ||
                quote_ident(real_schema) || '.' || quote_ident(table_name) || ' ADD CONSTRAINT ' ||
                quote_ident('enforce_geotype_' || column_name) ||
                ' CHECK (GeometryType(' ||
                quote_ident(column_name) || ')=' ||
                quote_literal(new_type) || ' OR (' ||
                quote_ident(column_name) || ') is null)';
            RAISE DEBUG '%', sql;
            EXECUTE sql;
        END IF;
    END IF;

	RETURN
		real_schema || '.' ||
		table_name || '.' || column_name ||
		' SRID:' || new_srid::text ||
		' TYPE:' || new_type ||
		' DIMS:' || new_dim::text || ' ';
END;
$$;


ALTER FUNCTION public.addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean) OWNER TO postgres;

--
-- Name: FUNCTION addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean) IS 'args: catalog_name, schema_name, table_name, column_name, srid, type, dimension, use_typmod=true - Adds a geometry column to an existing table of attributes. By default uses type modifier to define rather than constraints. Pass in false for use_typmod to get old check constraint based behavior';


--
-- Name: asbinary(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION asbinary(geometry) RETURNS bytea
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_asBinary';


ALTER FUNCTION public.asbinary(geometry) OWNER TO postgres;

--
-- Name: asbinary(geometry, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION asbinary(geometry, text) RETURNS bytea
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_asBinary';


ALTER FUNCTION public.asbinary(geometry, text) OWNER TO postgres;

--
-- Name: astext(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION astext(geometry) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_asText';


ALTER FUNCTION public.astext(geometry) OWNER TO postgres;

--
-- Name: box(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box(geometry) RETURNS box
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_to_BOX';


ALTER FUNCTION public.box(geometry) OWNER TO postgres;

--
-- Name: box(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box(box3d) RETURNS box
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX3D_to_BOX';


ALTER FUNCTION public.box(box3d) OWNER TO postgres;

--
-- Name: box2d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2d(geometry) RETURNS box2d
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_to_BOX2D';


ALTER FUNCTION public.box2d(geometry) OWNER TO postgres;

--
-- Name: FUNCTION box2d(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION box2d(geometry) IS 'args: geomA - Returns a BOX2D representing the maximum extents of the geometry.';


--
-- Name: box2d(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2d(box3d) RETURNS box2d
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX3D_to_BOX2D';


ALTER FUNCTION public.box2d(box3d) OWNER TO postgres;

--
-- Name: box3d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box3d(geometry) RETURNS box3d
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_to_BOX3D';


ALTER FUNCTION public.box3d(geometry) OWNER TO postgres;

--
-- Name: FUNCTION box3d(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION box3d(geometry) IS 'args: geomA - Returns a BOX3D representing the maximum extents of the geometry.';


--
-- Name: box3d(box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box3d(box2d) RETURNS box3d
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX2D_to_BOX3D';


ALTER FUNCTION public.box3d(box2d) OWNER TO postgres;

--
-- Name: box3dtobox(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box3dtobox(box3d) RETURNS box
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT box($1)$_$;


ALTER FUNCTION public.box3dtobox(box3d) OWNER TO postgres;

--
-- Name: bytea(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION bytea(geometry) RETURNS bytea
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_to_bytea';


ALTER FUNCTION public.bytea(geometry) OWNER TO postgres;

--
-- Name: bytea(geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION bytea(geography) RETURNS bytea
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_to_bytea';


ALTER FUNCTION public.bytea(geography) OWNER TO postgres;

--
-- Name: checkauth(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION checkauth(text, text) RETURNS integer
    LANGUAGE sql
    AS $_$ SELECT CheckAuth('', $1, $2) $_$;


ALTER FUNCTION public.checkauth(text, text) OWNER TO postgres;

--
-- Name: FUNCTION checkauth(text, text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION checkauth(text, text) IS 'args: a_table_name, a_key_column_name - Creates trigger on a table to prevent/allow updates and deletes of rows based on authorization token.';


--
-- Name: checkauth(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION checkauth(text, text, text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$ 
DECLARE
	schema text;
BEGIN
	IF NOT LongTransactionsEnabled() THEN
		RAISE EXCEPTION 'Long transaction support disabled, use EnableLongTransaction() to enable.';
	END IF;

	if ( $1 != '' ) THEN
		schema = $1;
	ELSE
		SELECT current_schema() into schema;
	END IF;

	-- TODO: check for an already existing trigger ?

	EXECUTE 'CREATE TRIGGER check_auth BEFORE UPDATE OR DELETE ON ' 
		|| quote_ident(schema) || '.' || quote_ident($2)
		||' FOR EACH ROW EXECUTE PROCEDURE CheckAuthTrigger('
		|| quote_literal($3) || ')';

	RETURN 0;
END;
$_$;


ALTER FUNCTION public.checkauth(text, text, text) OWNER TO postgres;

--
-- Name: FUNCTION checkauth(text, text, text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION checkauth(text, text, text) IS 'args: a_schema_name, a_table_name, a_key_column_name - Creates trigger on a table to prevent/allow updates and deletes of rows based on authorization token.';


--
-- Name: checkauthtrigger(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION checkauthtrigger() RETURNS trigger
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'check_authorization';


ALTER FUNCTION public.checkauthtrigger() OWNER TO postgres;

--
-- Name: disablelongtransactions(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION disablelongtransactions() RETURNS text
    LANGUAGE plpgsql
    AS $$ 
DECLARE
	rec RECORD;

BEGIN

	--
	-- Drop all triggers applied by CheckAuth()
	--
	FOR rec IN
		SELECT c.relname, t.tgname, t.tgargs FROM pg_trigger t, pg_class c, pg_proc p
		WHERE p.proname = 'checkauthtrigger' and t.tgfoid = p.oid and t.tgrelid = c.oid
	LOOP
		EXECUTE 'DROP TRIGGER ' || quote_ident(rec.tgname) ||
			' ON ' || quote_ident(rec.relname);
	END LOOP;

	--
	-- Drop the authorization_table table
	--
	FOR rec IN SELECT * FROM pg_class WHERE relname = 'authorization_table' LOOP
		DROP TABLE authorization_table;
	END LOOP;

	--
	-- Drop the authorized_tables view
	--
	FOR rec IN SELECT * FROM pg_class WHERE relname = 'authorized_tables' LOOP
		DROP VIEW authorized_tables;
	END LOOP;

	RETURN 'Long transactions support disabled';
END;
$$;


ALTER FUNCTION public.disablelongtransactions() OWNER TO postgres;

--
-- Name: FUNCTION disablelongtransactions(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION disablelongtransactions() IS 'Disable long transaction support. This function removes the long transaction support metadata tables, and drops all triggers attached to lock-checked tables.';


--
-- Name: dropgeometrycolumn(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION dropgeometrycolumn(table_name character varying, column_name character varying) RETURNS text
    LANGUAGE plpgsql STRICT
    AS $_$
DECLARE
	ret text;
BEGIN
	SELECT DropGeometryColumn('','',$1,$2) into ret;
	RETURN ret;
END;
$_$;


ALTER FUNCTION public.dropgeometrycolumn(table_name character varying, column_name character varying) OWNER TO postgres;

--
-- Name: FUNCTION dropgeometrycolumn(table_name character varying, column_name character varying); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION dropgeometrycolumn(table_name character varying, column_name character varying) IS 'args: table_name, column_name - Removes a geometry column from a spatial table.';


--
-- Name: dropgeometrycolumn(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying) RETURNS text
    LANGUAGE plpgsql STRICT
    AS $_$
DECLARE
	ret text;
BEGIN
	SELECT DropGeometryColumn('',$1,$2,$3) into ret;
	RETURN ret;
END;
$_$;


ALTER FUNCTION public.dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying) OWNER TO postgres;

--
-- Name: FUNCTION dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying) IS 'args: schema_name, table_name, column_name - Removes a geometry column from a spatial table.';


--
-- Name: dropgeometrycolumn(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying) RETURNS text
    LANGUAGE plpgsql STRICT
    AS $$
DECLARE
	myrec RECORD;
	okay boolean;
	real_schema name;

BEGIN


	-- Find, check or fix schema_name
	IF ( schema_name != '' ) THEN
		okay = false;

		FOR myrec IN SELECT nspname FROM pg_namespace WHERE text(nspname) = schema_name LOOP
			okay := true;
		END LOOP;

		IF ( okay <>  true ) THEN
			RAISE NOTICE 'Invalid schema name - using current_schema()';
			SELECT current_schema() into real_schema;
		ELSE
			real_schema = schema_name;
		END IF;
	ELSE
		SELECT current_schema() into real_schema;
	END IF;

	-- Find out if the column is in the geometry_columns table
	okay = false;
	FOR myrec IN SELECT * from geometry_columns where f_table_schema = text(real_schema) and f_table_name = table_name and f_geometry_column = column_name LOOP
		okay := true;
	END LOOP;
	IF (okay <> true) THEN
		RAISE EXCEPTION 'column not found in geometry_columns table';
		RETURN false;
	END IF;

	-- Remove table column
	EXECUTE 'ALTER TABLE ' || quote_ident(real_schema) || '.' ||
		quote_ident(table_name) || ' DROP COLUMN ' ||
		quote_ident(column_name);

	RETURN real_schema || '.' || table_name || '.' || column_name ||' effectively removed.';

END;
$$;


ALTER FUNCTION public.dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying) OWNER TO postgres;

--
-- Name: FUNCTION dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying) IS 'args: catalog_name, schema_name, table_name, column_name - Removes a geometry column from a spatial table.';


--
-- Name: dropgeometrytable(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION dropgeometrytable(table_name character varying) RETURNS text
    LANGUAGE sql STRICT
    AS $_$ SELECT DropGeometryTable('','',$1) $_$;


ALTER FUNCTION public.dropgeometrytable(table_name character varying) OWNER TO postgres;

--
-- Name: FUNCTION dropgeometrytable(table_name character varying); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION dropgeometrytable(table_name character varying) IS 'args: table_name - Drops a table and all its references in geometry_columns.';


--
-- Name: dropgeometrytable(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION dropgeometrytable(schema_name character varying, table_name character varying) RETURNS text
    LANGUAGE sql STRICT
    AS $_$ SELECT DropGeometryTable('',$1,$2) $_$;


ALTER FUNCTION public.dropgeometrytable(schema_name character varying, table_name character varying) OWNER TO postgres;

--
-- Name: FUNCTION dropgeometrytable(schema_name character varying, table_name character varying); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION dropgeometrytable(schema_name character varying, table_name character varying) IS 'args: schema_name, table_name - Drops a table and all its references in geometry_columns.';


--
-- Name: dropgeometrytable(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying) RETURNS text
    LANGUAGE plpgsql STRICT
    AS $$
DECLARE
	real_schema name;

BEGIN

	IF ( schema_name = '' ) THEN
		SELECT current_schema() into real_schema;
	ELSE
		real_schema = schema_name;
	END IF;

	-- TODO: Should we warn if table doesn't exist probably instead just saying dropped
	-- Remove table
	EXECUTE 'DROP TABLE IF EXISTS '
		|| quote_ident(real_schema) || '.' ||
		quote_ident(table_name) || ' RESTRICT';

	RETURN
		real_schema || '.' ||
		table_name ||' dropped.';

END;
$$;


ALTER FUNCTION public.dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying) OWNER TO postgres;

--
-- Name: FUNCTION dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying) IS 'args: catalog_name, schema_name, table_name - Drops a table and all its references in geometry_columns.';


--
-- Name: enablelongtransactions(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION enablelongtransactions() RETURNS text
    LANGUAGE plpgsql
    AS $$ 
DECLARE
	"query" text;
	exists bool;
	rec RECORD;

BEGIN

	exists = 'f';
	FOR rec IN SELECT * FROM pg_class WHERE relname = 'authorization_table'
	LOOP
		exists = 't';
	END LOOP;

	IF NOT exists
	THEN
		"query" = 'CREATE TABLE authorization_table (
			toid oid, -- table oid
			rid text, -- row id
			expires timestamp,
			authid text
		)';
		EXECUTE "query";
	END IF;

	exists = 'f';
	FOR rec IN SELECT * FROM pg_class WHERE relname = 'authorized_tables'
	LOOP
		exists = 't';
	END LOOP;

	IF NOT exists THEN
		"query" = 'CREATE VIEW authorized_tables AS ' ||
			'SELECT ' ||
			'n.nspname as schema, ' ||
			'c.relname as table, trim(' ||
			quote_literal(chr(92) || '000') ||
			' from t.tgargs) as id_column ' ||
			'FROM pg_trigger t, pg_class c, pg_proc p ' ||
			', pg_namespace n ' ||
			'WHERE p.proname = ' || quote_literal('checkauthtrigger') ||
			' AND c.relnamespace = n.oid' ||
			' AND t.tgfoid = p.oid and t.tgrelid = c.oid';
		EXECUTE "query";
	END IF;

	RETURN 'Long transactions support enabled';
END;
$$;


ALTER FUNCTION public.enablelongtransactions() OWNER TO postgres;

--
-- Name: FUNCTION enablelongtransactions(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION enablelongtransactions() IS 'Enable long transaction support. This function creates the required metadata tables, needs to be called once before using the other functions in this section. Calling it twice is harmless.';


--
-- Name: equals(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION equals(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'ST_Equals';


ALTER FUNCTION public.equals(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: estimated_extent(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION estimated_extent(text, text) RETURNS box2d
    LANGUAGE c IMMUTABLE STRICT SECURITY DEFINER
    AS '$libdir/postgis-2.0', 'geometry_estimated_extent';


ALTER FUNCTION public.estimated_extent(text, text) OWNER TO postgres;

--
-- Name: estimated_extent(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION estimated_extent(text, text, text) RETURNS box2d
    LANGUAGE c IMMUTABLE STRICT SECURITY DEFINER
    AS '$libdir/postgis-2.0', 'geometry_estimated_extent';


ALTER FUNCTION public.estimated_extent(text, text, text) OWNER TO postgres;

--
-- Name: find_srid(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION find_srid(character varying, character varying, character varying) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $_$
DECLARE
	schem text;
	tabl text;
	sr int4;
BEGIN
	IF $1 IS NULL THEN
	  RAISE EXCEPTION 'find_srid() - schema is NULL!';
	END IF;
	IF $2 IS NULL THEN
	  RAISE EXCEPTION 'find_srid() - table name is NULL!';
	END IF;
	IF $3 IS NULL THEN
	  RAISE EXCEPTION 'find_srid() - column name is NULL!';
	END IF;
	schem = $1;
	tabl = $2;
-- if the table contains a . and the schema is empty
-- split the table into a schema and a table
-- otherwise drop through to default behavior
	IF ( schem = '' and tabl LIKE '%.%' ) THEN
	 schem = substr(tabl,1,strpos(tabl,'.')-1);
	 tabl = substr(tabl,length(schem)+2);
	ELSE
	 schem = schem || '%';
	END IF;

	select SRID into sr from geometry_columns where f_table_schema like schem and f_table_name = tabl and f_geometry_column = $3;
	IF NOT FOUND THEN
	   RAISE EXCEPTION 'find_srid() - couldnt find the corresponding SRID - is the geometry registered in the GEOMETRY_COLUMNS table?  Is there an uppercase/lowercase missmatch?';
	END IF;
	return sr;
END;
$_$;


ALTER FUNCTION public.find_srid(character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: FUNCTION find_srid(character varying, character varying, character varying); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION find_srid(character varying, character varying, character varying) IS 'args: a_schema_name, a_table_name, a_geomfield_name - The syntax is find_srid(<db/schema>, <table>, <column>) and the function returns the integer SRID of the specified column by searching through the GEOMETRY_COLUMNS table.';


--
-- Name: geography(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography(bytea) RETURNS geography
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_from_bytea';


ALTER FUNCTION public.geography(bytea) OWNER TO postgres;

--
-- Name: geography(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography(geometry) RETURNS geography
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_from_geometry';


ALTER FUNCTION public.geography(geometry) OWNER TO postgres;

--
-- Name: geography(geography, integer, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography(geography, integer, boolean) RETURNS geography
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_enforce_typmod';


ALTER FUNCTION public.geography(geography, integer, boolean) OWNER TO postgres;

--
-- Name: geography_cmp(geography, geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_cmp(geography, geography) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_cmp';


ALTER FUNCTION public.geography_cmp(geography, geography) OWNER TO postgres;

--
-- Name: geography_eq(geography, geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_eq(geography, geography) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_eq';


ALTER FUNCTION public.geography_eq(geography, geography) OWNER TO postgres;

--
-- Name: geography_ge(geography, geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_ge(geography, geography) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_ge';


ALTER FUNCTION public.geography_ge(geography, geography) OWNER TO postgres;

--
-- Name: geography_gist_compress(internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_gist_compress(internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_compress';


ALTER FUNCTION public.geography_gist_compress(internal) OWNER TO postgres;

--
-- Name: geography_gist_consistent(internal, geography, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_gist_consistent(internal, geography, integer) RETURNS boolean
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_consistent';


ALTER FUNCTION public.geography_gist_consistent(internal, geography, integer) OWNER TO postgres;

--
-- Name: geography_gist_decompress(internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_gist_decompress(internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_decompress';


ALTER FUNCTION public.geography_gist_decompress(internal) OWNER TO postgres;

--
-- Name: geography_gist_join_selectivity(internal, oid, internal, smallint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_gist_join_selectivity(internal, oid, internal, smallint) RETURNS double precision
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'geography_gist_selectivity';


ALTER FUNCTION public.geography_gist_join_selectivity(internal, oid, internal, smallint) OWNER TO postgres;

--
-- Name: geography_gist_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_gist_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_penalty';


ALTER FUNCTION public.geography_gist_penalty(internal, internal, internal) OWNER TO postgres;

--
-- Name: geography_gist_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_gist_picksplit(internal, internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_picksplit';


ALTER FUNCTION public.geography_gist_picksplit(internal, internal) OWNER TO postgres;

--
-- Name: geography_gist_same(box2d, box2d, internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_gist_same(box2d, box2d, internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_same';


ALTER FUNCTION public.geography_gist_same(box2d, box2d, internal) OWNER TO postgres;

--
-- Name: geography_gist_selectivity(internal, oid, internal, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_gist_selectivity(internal, oid, internal, integer) RETURNS double precision
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'geography_gist_selectivity';


ALTER FUNCTION public.geography_gist_selectivity(internal, oid, internal, integer) OWNER TO postgres;

--
-- Name: geography_gist_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_gist_union(bytea, internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_union';


ALTER FUNCTION public.geography_gist_union(bytea, internal) OWNER TO postgres;

--
-- Name: geography_gt(geography, geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_gt(geography, geography) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_gt';


ALTER FUNCTION public.geography_gt(geography, geography) OWNER TO postgres;

--
-- Name: geography_le(geography, geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_le(geography, geography) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_le';


ALTER FUNCTION public.geography_le(geography, geography) OWNER TO postgres;

--
-- Name: geography_lt(geography, geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_lt(geography, geography) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_lt';


ALTER FUNCTION public.geography_lt(geography, geography) OWNER TO postgres;

--
-- Name: geography_overlaps(geography, geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geography_overlaps(geography, geography) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'gserialized_overlaps';


ALTER FUNCTION public.geography_overlaps(geography, geography) OWNER TO postgres;

--
-- Name: geometry(box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry(box2d) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX2D_to_LWGEOM';


ALTER FUNCTION public.geometry(box2d) OWNER TO postgres;

--
-- Name: geometry(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry(box3d) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX3D_to_LWGEOM';


ALTER FUNCTION public.geometry(box3d) OWNER TO postgres;

--
-- Name: geometry(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry(text) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'parse_WKT_lwgeom';


ALTER FUNCTION public.geometry(text) OWNER TO postgres;

--
-- Name: geometry(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry(bytea) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_from_bytea';


ALTER FUNCTION public.geometry(bytea) OWNER TO postgres;

--
-- Name: geometry(geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry(geography) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geometry_from_geography';


ALTER FUNCTION public.geometry(geography) OWNER TO postgres;

--
-- Name: geometry(geometry, integer, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry(geometry, integer, boolean) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geometry_enforce_typmod';


ALTER FUNCTION public.geometry(geometry, integer, boolean) OWNER TO postgres;

--
-- Name: geometry_above(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_above(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'gserialized_above_2d';


ALTER FUNCTION public.geometry_above(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_below(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_below(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'gserialized_below_2d';


ALTER FUNCTION public.geometry_below(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_cmp(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_cmp(geom1 geometry, geom2 geometry) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'lwgeom_cmp';


ALTER FUNCTION public.geometry_cmp(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_contains(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_contains(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'gserialized_contains_2d';


ALTER FUNCTION public.geometry_contains(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_distance_box(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_distance_box(geom1 geometry, geom2 geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'gserialized_distance_box_2d';


ALTER FUNCTION public.geometry_distance_box(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_distance_centroid(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_distance_centroid(geom1 geometry, geom2 geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'gserialized_distance_centroid_2d';


ALTER FUNCTION public.geometry_distance_centroid(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_eq(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_eq(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'lwgeom_eq';


ALTER FUNCTION public.geometry_eq(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_ge(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_ge(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'lwgeom_ge';


ALTER FUNCTION public.geometry_ge(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_gist_compress_2d(internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gist_compress_2d(internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_compress_2d';


ALTER FUNCTION public.geometry_gist_compress_2d(internal) OWNER TO postgres;

--
-- Name: geometry_gist_compress_nd(internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gist_compress_nd(internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_compress';


ALTER FUNCTION public.geometry_gist_compress_nd(internal) OWNER TO postgres;

--
-- Name: geometry_gist_consistent_2d(internal, geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gist_consistent_2d(internal, geometry, integer) RETURNS boolean
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_consistent_2d';


ALTER FUNCTION public.geometry_gist_consistent_2d(internal, geometry, integer) OWNER TO postgres;

--
-- Name: geometry_gist_consistent_nd(internal, geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gist_consistent_nd(internal, geometry, integer) RETURNS boolean
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_consistent';


ALTER FUNCTION public.geometry_gist_consistent_nd(internal, geometry, integer) OWNER TO postgres;

--
-- Name: geometry_gist_decompress_2d(internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gist_decompress_2d(internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_decompress_2d';


ALTER FUNCTION public.geometry_gist_decompress_2d(internal) OWNER TO postgres;

--
-- Name: geometry_gist_decompress_nd(internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gist_decompress_nd(internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_decompress';


ALTER FUNCTION public.geometry_gist_decompress_nd(internal) OWNER TO postgres;

--
-- Name: geometry_gist_distance_2d(internal, geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gist_distance_2d(internal, geometry, integer) RETURNS double precision
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_distance_2d';


ALTER FUNCTION public.geometry_gist_distance_2d(internal, geometry, integer) OWNER TO postgres;

--
-- Name: geometry_gist_joinsel_2d(internal, oid, internal, smallint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gist_joinsel_2d(internal, oid, internal, smallint) RETURNS double precision
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'geometry_gist_joinsel_2d';


ALTER FUNCTION public.geometry_gist_joinsel_2d(internal, oid, internal, smallint) OWNER TO postgres;

--
-- Name: geometry_gist_penalty_2d(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gist_penalty_2d(internal, internal, internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_penalty_2d';


ALTER FUNCTION public.geometry_gist_penalty_2d(internal, internal, internal) OWNER TO postgres;

--
-- Name: geometry_gist_penalty_nd(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gist_penalty_nd(internal, internal, internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_penalty';


ALTER FUNCTION public.geometry_gist_penalty_nd(internal, internal, internal) OWNER TO postgres;

--
-- Name: geometry_gist_picksplit_2d(internal, internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gist_picksplit_2d(internal, internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_picksplit_2d';


ALTER FUNCTION public.geometry_gist_picksplit_2d(internal, internal) OWNER TO postgres;

--
-- Name: geometry_gist_picksplit_nd(internal, internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gist_picksplit_nd(internal, internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_picksplit';


ALTER FUNCTION public.geometry_gist_picksplit_nd(internal, internal) OWNER TO postgres;

--
-- Name: geometry_gist_same_2d(geometry, geometry, internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gist_same_2d(geom1 geometry, geom2 geometry, internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_same_2d';


ALTER FUNCTION public.geometry_gist_same_2d(geom1 geometry, geom2 geometry, internal) OWNER TO postgres;

--
-- Name: geometry_gist_same_nd(geometry, geometry, internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gist_same_nd(geometry, geometry, internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_same';


ALTER FUNCTION public.geometry_gist_same_nd(geometry, geometry, internal) OWNER TO postgres;

--
-- Name: geometry_gist_sel_2d(internal, oid, internal, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gist_sel_2d(internal, oid, internal, integer) RETURNS double precision
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'geometry_gist_sel_2d';


ALTER FUNCTION public.geometry_gist_sel_2d(internal, oid, internal, integer) OWNER TO postgres;

--
-- Name: geometry_gist_union_2d(bytea, internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gist_union_2d(bytea, internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_union_2d';


ALTER FUNCTION public.geometry_gist_union_2d(bytea, internal) OWNER TO postgres;

--
-- Name: geometry_gist_union_nd(bytea, internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gist_union_nd(bytea, internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'gserialized_gist_union';


ALTER FUNCTION public.geometry_gist_union_nd(bytea, internal) OWNER TO postgres;

--
-- Name: geometry_gt(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gt(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'lwgeom_gt';


ALTER FUNCTION public.geometry_gt(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_le(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_le(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'lwgeom_le';


ALTER FUNCTION public.geometry_le(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_left(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_left(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'gserialized_left_2d';


ALTER FUNCTION public.geometry_left(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_lt(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_lt(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'lwgeom_lt';


ALTER FUNCTION public.geometry_lt(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_overabove(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_overabove(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'gserialized_overabove_2d';


ALTER FUNCTION public.geometry_overabove(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_overbelow(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_overbelow(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'gserialized_overbelow_2d';


ALTER FUNCTION public.geometry_overbelow(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_overlaps(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_overlaps(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'gserialized_overlaps_2d';


ALTER FUNCTION public.geometry_overlaps(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_overlaps_nd(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_overlaps_nd(geometry, geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'gserialized_overlaps';


ALTER FUNCTION public.geometry_overlaps_nd(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_overleft(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_overleft(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'gserialized_overleft_2d';


ALTER FUNCTION public.geometry_overleft(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_overright(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_overright(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'gserialized_overright_2d';


ALTER FUNCTION public.geometry_overright(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_right(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_right(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'gserialized_right_2d';


ALTER FUNCTION public.geometry_right(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_same(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_same(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'gserialized_same_2d';


ALTER FUNCTION public.geometry_same(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometry_within(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_within(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'gserialized_within_2d';


ALTER FUNCTION public.geometry_within(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: geometrytype(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometrytype(geometry) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_getTYPE';


ALTER FUNCTION public.geometrytype(geometry) OWNER TO postgres;

--
-- Name: FUNCTION geometrytype(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION geometrytype(geometry) IS 'args: geomA - Returns the type of the geometry as a string. Eg: LINESTRING, POLYGON, MULTIPOINT, etc.';


--
-- Name: geometrytype(geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometrytype(geography) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_getTYPE';


ALTER FUNCTION public.geometrytype(geography) OWNER TO postgres;

--
-- Name: geomfromewkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geomfromewkb(bytea) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOMFromWKB';


ALTER FUNCTION public.geomfromewkb(bytea) OWNER TO postgres;

--
-- Name: geomfromewkt(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geomfromewkt(text) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'parse_WKT_lwgeom';


ALTER FUNCTION public.geomfromewkt(text) OWNER TO postgres;

--
-- Name: geomfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geomfromtext(text) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_GeomFromText($1)$_$;


ALTER FUNCTION public.geomfromtext(text) OWNER TO postgres;

--
-- Name: geomfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geomfromtext(text, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_GeomFromText($1, $2)$_$;


ALTER FUNCTION public.geomfromtext(text, integer) OWNER TO postgres;

--
-- Name: get_proj4_from_srid(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_proj4_from_srid(integer) RETURNS text
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $_$
BEGIN
	RETURN proj4text::text FROM spatial_ref_sys WHERE srid= $1;
END;
$_$;


ALTER FUNCTION public.get_proj4_from_srid(integer) OWNER TO postgres;

--
-- Name: gettransactionid(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION gettransactionid() RETURNS xid
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'getTransactionID';


ALTER FUNCTION public.gettransactionid() OWNER TO postgres;

--
-- Name: lockrow(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION lockrow(text, text, text) RETURNS integer
    LANGUAGE sql STRICT
    AS $_$ SELECT LockRow(current_schema(), $1, $2, $3, now()::timestamp+'1:00'); $_$;


ALTER FUNCTION public.lockrow(text, text, text) OWNER TO postgres;

--
-- Name: FUNCTION lockrow(text, text, text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION lockrow(text, text, text) IS 'args: a_table_name, a_row_key, an_auth_token - Set lock/authorization for specific row in table';


--
-- Name: lockrow(text, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION lockrow(text, text, text, text) RETURNS integer
    LANGUAGE sql STRICT
    AS $_$ SELECT LockRow($1, $2, $3, $4, now()::timestamp+'1:00'); $_$;


ALTER FUNCTION public.lockrow(text, text, text, text) OWNER TO postgres;

--
-- Name: lockrow(text, text, text, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION lockrow(text, text, text, timestamp without time zone) RETURNS integer
    LANGUAGE sql STRICT
    AS $_$ SELECT LockRow(current_schema(), $1, $2, $3, $4); $_$;


ALTER FUNCTION public.lockrow(text, text, text, timestamp without time zone) OWNER TO postgres;

--
-- Name: FUNCTION lockrow(text, text, text, timestamp without time zone); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION lockrow(text, text, text, timestamp without time zone) IS 'args: a_table_name, a_row_key, an_auth_token, expire_dt - Set lock/authorization for specific row in table';


--
-- Name: lockrow(text, text, text, text, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION lockrow(text, text, text, text, timestamp without time zone) RETURNS integer
    LANGUAGE plpgsql STRICT
    AS $_$ 
DECLARE
	myschema alias for $1;
	mytable alias for $2;
	myrid   alias for $3;
	authid alias for $4;
	expires alias for $5;
	ret int;
	mytoid oid;
	myrec RECORD;
	
BEGIN

	IF NOT LongTransactionsEnabled() THEN
		RAISE EXCEPTION 'Long transaction support disabled, use EnableLongTransaction() to enable.';
	END IF;

	EXECUTE 'DELETE FROM authorization_table WHERE expires < now()'; 

	SELECT c.oid INTO mytoid FROM pg_class c, pg_namespace n
		WHERE c.relname = mytable
		AND c.relnamespace = n.oid
		AND n.nspname = myschema;

	-- RAISE NOTICE 'toid: %', mytoid;

	FOR myrec IN SELECT * FROM authorization_table WHERE 
		toid = mytoid AND rid = myrid
	LOOP
		IF myrec.authid != authid THEN
			RETURN 0;
		ELSE
			RETURN 1;
		END IF;
	END LOOP;

	EXECUTE 'INSERT INTO authorization_table VALUES ('||
		quote_literal(mytoid::text)||','||quote_literal(myrid)||
		','||quote_literal(expires::text)||
		','||quote_literal(authid) ||')';

	GET DIAGNOSTICS ret = ROW_COUNT;

	RETURN ret;
END;
$_$;


ALTER FUNCTION public.lockrow(text, text, text, text, timestamp without time zone) OWNER TO postgres;

--
-- Name: FUNCTION lockrow(text, text, text, text, timestamp without time zone); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION lockrow(text, text, text, text, timestamp without time zone) IS 'args: a_schema_name, a_table_name, a_row_key, an_auth_token, expire_dt - Set lock/authorization for specific row in table';


--
-- Name: longtransactionsenabled(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION longtransactionsenabled() RETURNS boolean
    LANGUAGE plpgsql
    AS $$ 
DECLARE
	rec RECORD;
BEGIN
	FOR rec IN SELECT oid FROM pg_class WHERE relname = 'authorized_tables'
	LOOP
		return 't';
	END LOOP;
	return 'f';
END;
$$;


ALTER FUNCTION public.longtransactionsenabled() OWNER TO postgres;

--
-- Name: ndims(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ndims(geometry) RETURNS smallint
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_ndims';


ALTER FUNCTION public.ndims(geometry) OWNER TO postgres;

--
-- Name: pgis_geometry_accum_finalfn(pgis_abs); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION pgis_geometry_accum_finalfn(pgis_abs) RETURNS geometry[]
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'pgis_geometry_accum_finalfn';


ALTER FUNCTION public.pgis_geometry_accum_finalfn(pgis_abs) OWNER TO postgres;

--
-- Name: pgis_geometry_accum_transfn(pgis_abs, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION pgis_geometry_accum_transfn(pgis_abs, geometry) RETURNS pgis_abs
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'pgis_geometry_accum_transfn';


ALTER FUNCTION public.pgis_geometry_accum_transfn(pgis_abs, geometry) OWNER TO postgres;

--
-- Name: pgis_geometry_collect_finalfn(pgis_abs); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION pgis_geometry_collect_finalfn(pgis_abs) RETURNS geometry
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'pgis_geometry_collect_finalfn';


ALTER FUNCTION public.pgis_geometry_collect_finalfn(pgis_abs) OWNER TO postgres;

--
-- Name: pgis_geometry_makeline_finalfn(pgis_abs); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION pgis_geometry_makeline_finalfn(pgis_abs) RETURNS geometry
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'pgis_geometry_makeline_finalfn';


ALTER FUNCTION public.pgis_geometry_makeline_finalfn(pgis_abs) OWNER TO postgres;

--
-- Name: pgis_geometry_polygonize_finalfn(pgis_abs); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION pgis_geometry_polygonize_finalfn(pgis_abs) RETURNS geometry
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'pgis_geometry_polygonize_finalfn';


ALTER FUNCTION public.pgis_geometry_polygonize_finalfn(pgis_abs) OWNER TO postgres;

--
-- Name: pgis_geometry_union_finalfn(pgis_abs); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION pgis_geometry_union_finalfn(pgis_abs) RETURNS geometry
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'pgis_geometry_union_finalfn';


ALTER FUNCTION public.pgis_geometry_union_finalfn(pgis_abs) OWNER TO postgres;

--
-- Name: populate_geometry_columns(boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION populate_geometry_columns(use_typmod boolean DEFAULT true) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
	inserted    integer;
	oldcount    integer;
	probed      integer;
	stale       integer;
	gcs         RECORD;
	gc          RECORD;
	gsrid       integer;
	gndims      integer;
	gtype       text;
	query       text;
	gc_is_valid boolean;

BEGIN
	SELECT count(*) INTO oldcount FROM geometry_columns;
	inserted := 0;

	-- Count the number of geometry columns in all tables and views
	SELECT count(DISTINCT c.oid) INTO probed
	FROM pg_class c,
		 pg_attribute a,
		 pg_type t,
		 pg_namespace n
	WHERE (c.relkind = 'r' OR c.relkind = 'v')
		AND t.typname = 'geometry'
		AND a.attisdropped = false
		AND a.atttypid = t.oid
		AND a.attrelid = c.oid
		AND c.relnamespace = n.oid
		AND n.nspname NOT ILIKE 'pg_temp%' AND c.relname != 'raster_columns' ;

	-- Iterate through all non-dropped geometry columns
	RAISE DEBUG 'Processing Tables.....';

	FOR gcs IN
	SELECT DISTINCT ON (c.oid) c.oid, n.nspname, c.relname
		FROM pg_class c,
			 pg_attribute a,
			 pg_type t,
			 pg_namespace n
		WHERE c.relkind = 'r'
		AND t.typname = 'geometry'
		AND a.attisdropped = false
		AND a.atttypid = t.oid
		AND a.attrelid = c.oid
		AND c.relnamespace = n.oid
		AND n.nspname NOT ILIKE 'pg_temp%' AND c.relname != 'raster_columns' 
	LOOP

		inserted := inserted + populate_geometry_columns(gcs.oid, use_typmod);
	END LOOP;

	IF oldcount > inserted THEN
	    stale = oldcount-inserted;
	ELSE
	    stale = 0;
	END IF;

	RETURN 'probed:' ||probed|| ' inserted:'||inserted;
END

$$;


ALTER FUNCTION public.populate_geometry_columns(use_typmod boolean) OWNER TO postgres;

--
-- Name: FUNCTION populate_geometry_columns(use_typmod boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION populate_geometry_columns(use_typmod boolean) IS 'args: use_typmod=true - Ensures geometry columns are defined with type modifiers or have appropriate spatial constraints This ensures they will be registered correctly in geometry_columns view. By default will convert all geometry columns with no type modifier to ones with type modifiers. To get old behavior set use_typmod=false';


--
-- Name: populate_geometry_columns(oid, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION populate_geometry_columns(tbl_oid oid, use_typmod boolean DEFAULT true) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	gcs         RECORD;
	gc          RECORD;
	gc_old      RECORD;
	gsrid       integer;
	gndims      integer;
	gtype       text;
	query       text;
	gc_is_valid boolean;
	inserted    integer;
	constraint_successful boolean := false;

BEGIN
	inserted := 0;

	-- Iterate through all geometry columns in this table
	FOR gcs IN
	SELECT n.nspname, c.relname, a.attname
		FROM pg_class c,
			 pg_attribute a,
			 pg_type t,
			 pg_namespace n
		WHERE c.relkind = 'r'
		AND t.typname = 'geometry'
		AND a.attisdropped = false
		AND a.atttypid = t.oid
		AND a.attrelid = c.oid
		AND c.relnamespace = n.oid
		AND n.nspname NOT ILIKE 'pg_temp%'
		AND c.oid = tbl_oid
	LOOP

        RAISE DEBUG 'Processing table %.%.%', gcs.nspname, gcs.relname, gcs.attname;
    
        gc_is_valid := true;
        -- Find the srid, coord_dimension, and type of current geometry
        -- in geometry_columns -- which is now a view
        
        SELECT type, srid, coord_dimension INTO gc_old 
            FROM geometry_columns 
            WHERE f_table_schema = gcs.nspname AND f_table_name = gcs.relname AND f_geometry_column = gcs.attname; 
            
        IF upper(gc_old.type) = 'GEOMETRY' THEN
        -- This is an unconstrained geometry we need to do something
        -- We need to figure out what to set the type by inspecting the data
            EXECUTE 'SELECT st_srid(' || quote_ident(gcs.attname) || ') As srid, GeometryType(' || quote_ident(gcs.attname) || ') As type, ST_NDims(' || quote_ident(gcs.attname) || ') As dims ' ||
                     ' FROM ONLY ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) || 
                     ' WHERE ' || quote_ident(gcs.attname) || ' IS NOT NULL LIMIT 1;'
                INTO gc;
            IF gc IS NULL THEN -- there is no data so we can not determine geometry type
            	RAISE WARNING 'No data in table %.%, so no information to determine geometry type and srid', gcs.nspname, gcs.relname;
            	RETURN 0;
            END IF;
            gsrid := gc.srid; gtype := gc.type; gndims := gc.dims;
            	
            IF use_typmod THEN
                BEGIN
                    EXECUTE 'ALTER TABLE ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) || ' ALTER COLUMN ' || quote_ident(gcs.attname) || 
                        ' TYPE geometry(' || postgis_type_name(gtype, gndims, true) || ', ' || gsrid::text  || ') ';
                    inserted := inserted + 1;
                EXCEPTION
                        WHEN invalid_parameter_value THEN
                        RAISE WARNING 'Could not convert ''%'' in ''%.%'' to use typmod with srid %, type: % ', quote_ident(gcs.attname), quote_ident(gcs.nspname), quote_ident(gcs.relname), gsrid, postgis_type_name(gtype, gndims, true);
                            gc_is_valid := false;
                END;
                
            ELSE
                -- Try to apply srid check to column
            	constraint_successful = false;
                IF (gsrid > 0 AND postgis_constraint_srid(gcs.nspname, gcs.relname,gcs.attname) IS NULL ) THEN
                    BEGIN
                        EXECUTE 'ALTER TABLE ONLY ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) || 
                                 ' ADD CONSTRAINT ' || quote_ident('enforce_srid_' || gcs.attname) || 
                                 ' CHECK (st_srid(' || quote_ident(gcs.attname) || ') = ' || gsrid || ')';
                        constraint_successful := true;
                    EXCEPTION
                        WHEN check_violation THEN
                            RAISE WARNING 'Not inserting ''%'' in ''%.%'' into geometry_columns: could not apply constraint CHECK (st_srid(%) = %)', quote_ident(gcs.attname), quote_ident(gcs.nspname), quote_ident(gcs.relname), quote_ident(gcs.attname), gsrid;
                            gc_is_valid := false;
                    END;
                END IF;
                
                -- Try to apply ndims check to column
                IF (gndims IS NOT NULL AND postgis_constraint_dims(gcs.nspname, gcs.relname,gcs.attname) IS NULL ) THEN
                    BEGIN
                        EXECUTE 'ALTER TABLE ONLY ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) || '
                                 ADD CONSTRAINT ' || quote_ident('enforce_dims_' || gcs.attname) || '
                                 CHECK (st_ndims(' || quote_ident(gcs.attname) || ') = '||gndims||')';
                        constraint_successful := true;
                    EXCEPTION
                        WHEN check_violation THEN
                            RAISE WARNING 'Not inserting ''%'' in ''%.%'' into geometry_columns: could not apply constraint CHECK (st_ndims(%) = %)', quote_ident(gcs.attname), quote_ident(gcs.nspname), quote_ident(gcs.relname), quote_ident(gcs.attname), gndims;
                            gc_is_valid := false;
                    END;
                END IF;
    
                -- Try to apply geometrytype check to column
                IF (gtype IS NOT NULL AND postgis_constraint_type(gcs.nspname, gcs.relname,gcs.attname) IS NULL ) THEN
                    BEGIN
                        EXECUTE 'ALTER TABLE ONLY ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) || '
                        ADD CONSTRAINT ' || quote_ident('enforce_geotype_' || gcs.attname) || '
                        CHECK ((geometrytype(' || quote_ident(gcs.attname) || ') = ' || quote_literal(gtype) || ') OR (' || quote_ident(gcs.attname) || ' IS NULL))';
                        constraint_successful := true;
                    EXCEPTION
                        WHEN check_violation THEN
                            -- No geometry check can be applied. This column contains a number of geometry types.
                            RAISE WARNING 'Could not add geometry type check (%) to table column: %.%.%', gtype, quote_ident(gcs.nspname),quote_ident(gcs.relname),quote_ident(gcs.attname);
                    END;
                END IF;
                 --only count if we were successful in applying at least one constraint
                IF constraint_successful THEN
                	inserted := inserted + 1;
                END IF;
            END IF;	        
	    END IF;

	END LOOP;

	RETURN inserted;
END

$$;


ALTER FUNCTION public.populate_geometry_columns(tbl_oid oid, use_typmod boolean) OWNER TO postgres;

--
-- Name: FUNCTION populate_geometry_columns(tbl_oid oid, use_typmod boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION populate_geometry_columns(tbl_oid oid, use_typmod boolean) IS 'args: relation_oid, use_typmod=true - Ensures geometry columns are defined with type modifiers or have appropriate spatial constraints This ensures they will be registered correctly in geometry_columns view. By default will convert all geometry columns with no type modifier to ones with type modifiers. To get old behavior set use_typmod=false';


--
-- Name: postgis_addbbox(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_addbbox(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_addBBOX';


ALTER FUNCTION public.postgis_addbbox(geometry) OWNER TO postgres;

--
-- Name: FUNCTION postgis_addbbox(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION postgis_addbbox(geometry) IS 'args: geomA - Add bounding box to the geometry.';


--
-- Name: postgis_cache_bbox(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_cache_bbox() RETURNS trigger
    LANGUAGE c
    AS '$libdir/postgis-2.0', 'cache_bbox';


ALTER FUNCTION public.postgis_cache_bbox() OWNER TO postgres;

--
-- Name: postgis_constraint_dims(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text) RETURNS integer
    LANGUAGE sql STABLE STRICT
    AS $_$
SELECT  replace(split_part(s.consrc, ' = ', 2), ')', '')::integer
		 FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s
		 WHERE n.nspname = $1
		 AND c.relname = $2
		 AND a.attname = $3
		 AND a.attrelid = c.oid
		 AND s.connamespace = n.oid
		 AND s.conrelid = c.oid
		 AND a.attnum = ANY (s.conkey)
		 AND s.consrc LIKE '%ndims(% = %';
$_$;


ALTER FUNCTION public.postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text) OWNER TO postgres;

--
-- Name: postgis_constraint_srid(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text) RETURNS integer
    LANGUAGE sql STABLE STRICT
    AS $_$
SELECT replace(replace(split_part(s.consrc, ' = ', 2), ')', ''), '(', '')::integer
		 FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s
		 WHERE n.nspname = $1
		 AND c.relname = $2
		 AND a.attname = $3
		 AND a.attrelid = c.oid
		 AND s.connamespace = n.oid
		 AND s.conrelid = c.oid
		 AND a.attnum = ANY (s.conkey)
		 AND s.consrc LIKE '%srid(% = %';
$_$;


ALTER FUNCTION public.postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text) OWNER TO postgres;

--
-- Name: postgis_constraint_type(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_constraint_type(geomschema text, geomtable text, geomcolumn text) RETURNS character varying
    LANGUAGE sql STABLE STRICT
    AS $_$
SELECT  replace(split_part(s.consrc, '''', 2), ')', '')::varchar		
		 FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s
		 WHERE n.nspname = $1
		 AND c.relname = $2
		 AND a.attname = $3
		 AND a.attrelid = c.oid
		 AND s.connamespace = n.oid
		 AND s.conrelid = c.oid
		 AND a.attnum = ANY (s.conkey)
		 AND s.consrc LIKE '%geometrytype(% = %';
$_$;


ALTER FUNCTION public.postgis_constraint_type(geomschema text, geomtable text, geomcolumn text) OWNER TO postgres;

--
-- Name: postgis_dropbbox(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_dropbbox(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_dropBBOX';


ALTER FUNCTION public.postgis_dropbbox(geometry) OWNER TO postgres;

--
-- Name: FUNCTION postgis_dropbbox(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION postgis_dropbbox(geometry) IS 'args: geomA - Drop the bounding box cache from the geometry.';


--
-- Name: postgis_full_version(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_full_version() RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
	libver text;
	svnver text;
	projver text;
	geosver text;
	gdalver text;
	libxmlver text;
	dbproc text;
	relproc text;
	fullver text;
	rast_lib_ver text;
	rast_scr_ver text;
	topo_scr_ver text;
	json_lib_ver text;
BEGIN
	SELECT postgis_lib_version() INTO libver;
	SELECT postgis_proj_version() INTO projver;
	SELECT postgis_geos_version() INTO geosver;
	SELECT postgis_libjson_version() INTO json_lib_ver;
	BEGIN
		SELECT postgis_gdal_version() INTO gdalver;
	EXCEPTION
		WHEN undefined_function THEN
			gdalver := NULL;
			RAISE NOTICE 'Function postgis_gdal_version() not found.  Is raster support enabled and rtpostgis.sql installed?';
	END;
	SELECT postgis_libxml_version() INTO libxmlver;
	SELECT postgis_scripts_installed() INTO dbproc;
	SELECT postgis_scripts_released() INTO relproc;
	select postgis_svn_version() INTO svnver;
	BEGIN
		SELECT postgis_topology_scripts_installed() INTO topo_scr_ver;
	EXCEPTION
		WHEN undefined_function THEN
			topo_scr_ver := NULL;
			RAISE NOTICE 'Function postgis_topology_scripts_installed() not found. Is topology support enabled and topology.sql installed?';
	END;

	BEGIN
		SELECT postgis_raster_scripts_installed() INTO rast_scr_ver;
	EXCEPTION
		WHEN undefined_function THEN
			rast_scr_ver := NULL;
			RAISE NOTICE 'Function postgis_raster_scripts_installed() not found. Is raster support enabled and rtpostgis.sql installed?';
	END;

	BEGIN
		SELECT postgis_raster_lib_version() INTO rast_lib_ver;
	EXCEPTION
		WHEN undefined_function THEN
			rast_lib_ver := NULL;
			RAISE NOTICE 'Function postgis_raster_lib_version() not found. Is raster support enabled and rtpostgis.sql installed?';
	END;

	fullver = 'POSTGIS="' || libver;

	IF  svnver IS NOT NULL THEN
		fullver = fullver || ' r' || svnver;
	END IF;

	fullver = fullver || '"';

	IF  geosver IS NOT NULL THEN
		fullver = fullver || ' GEOS="' || geosver || '"';
	END IF;

	IF  projver IS NOT NULL THEN
		fullver = fullver || ' PROJ="' || projver || '"';
	END IF;

	IF  gdalver IS NOT NULL THEN
		fullver = fullver || ' GDAL="' || gdalver || '"';
	END IF;

	IF  libxmlver IS NOT NULL THEN
		fullver = fullver || ' LIBXML="' || libxmlver || '"';
	END IF;

	IF json_lib_ver IS NOT NULL THEN
		fullver = fullver || ' LIBJSON="' || json_lib_ver || '"';
	END IF;

	-- fullver = fullver || ' DBPROC="' || dbproc || '"';
	-- fullver = fullver || ' RELPROC="' || relproc || '"';

	IF dbproc != relproc THEN
		fullver = fullver || ' (core procs from "' || dbproc || '" need upgrade)';
	END IF;

	IF topo_scr_ver IS NOT NULL THEN
		fullver = fullver || ' TOPOLOGY';
		IF topo_scr_ver != relproc THEN
			fullver = fullver || ' (topology procs from "' || topo_scr_ver || '" need upgrade)';
		END IF;
	END IF;

	IF rast_lib_ver IS NOT NULL THEN
		fullver = fullver || ' RASTER';
		IF rast_lib_ver != relproc THEN
			fullver = fullver || ' (raster lib from "' || rast_lib_ver || '" need upgrade)';
		END IF;
	END IF;

	IF rast_scr_ver IS NOT NULL AND rast_scr_ver != relproc THEN
		fullver = fullver || ' (raster procs from "' || rast_scr_ver || '" need upgrade)';
	END IF;

	RETURN fullver;
END
$$;


ALTER FUNCTION public.postgis_full_version() OWNER TO postgres;

--
-- Name: FUNCTION postgis_full_version(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION postgis_full_version() IS 'Reports full postgis version and build configuration infos.';


--
-- Name: postgis_geos_version(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_geos_version() RETURNS text
    LANGUAGE c IMMUTABLE
    AS '$libdir/postgis-2.0', 'postgis_geos_version';


ALTER FUNCTION public.postgis_geos_version() OWNER TO postgres;

--
-- Name: FUNCTION postgis_geos_version(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION postgis_geos_version() IS 'Returns the version number of the GEOS library.';


--
-- Name: postgis_getbbox(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_getbbox(geometry) RETURNS box2d
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_to_BOX2D';


ALTER FUNCTION public.postgis_getbbox(geometry) OWNER TO postgres;

--
-- Name: postgis_hasbbox(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_hasbbox(geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_hasBBOX';


ALTER FUNCTION public.postgis_hasbbox(geometry) OWNER TO postgres;

--
-- Name: FUNCTION postgis_hasbbox(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION postgis_hasbbox(geometry) IS 'args: geomA - Returns TRUE if the bbox of this geometry is cached, FALSE otherwise.';


--
-- Name: postgis_lib_build_date(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_lib_build_date() RETURNS text
    LANGUAGE c IMMUTABLE
    AS '$libdir/postgis-2.0', 'postgis_lib_build_date';


ALTER FUNCTION public.postgis_lib_build_date() OWNER TO postgres;

--
-- Name: FUNCTION postgis_lib_build_date(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION postgis_lib_build_date() IS 'Returns build date of the PostGIS library.';


--
-- Name: postgis_lib_version(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_lib_version() RETURNS text
    LANGUAGE c IMMUTABLE
    AS '$libdir/postgis-2.0', 'postgis_lib_version';


ALTER FUNCTION public.postgis_lib_version() OWNER TO postgres;

--
-- Name: FUNCTION postgis_lib_version(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION postgis_lib_version() IS 'Returns the version number of the PostGIS library.';


--
-- Name: postgis_libjson_version(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_libjson_version() RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'postgis_libjson_version';


ALTER FUNCTION public.postgis_libjson_version() OWNER TO postgres;

--
-- Name: postgis_libxml_version(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_libxml_version() RETURNS text
    LANGUAGE c IMMUTABLE
    AS '$libdir/postgis-2.0', 'postgis_libxml_version';


ALTER FUNCTION public.postgis_libxml_version() OWNER TO postgres;

--
-- Name: FUNCTION postgis_libxml_version(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION postgis_libxml_version() IS 'Returns the version number of the libxml2 library.';


--
-- Name: postgis_noop(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_noop(geometry) RETURNS geometry
    LANGUAGE c STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_noop';


ALTER FUNCTION public.postgis_noop(geometry) OWNER TO postgres;

--
-- Name: postgis_proj_version(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_proj_version() RETURNS text
    LANGUAGE c IMMUTABLE
    AS '$libdir/postgis-2.0', 'postgis_proj_version';


ALTER FUNCTION public.postgis_proj_version() OWNER TO postgres;

--
-- Name: FUNCTION postgis_proj_version(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION postgis_proj_version() IS 'Returns the version number of the PROJ4 library.';


--
-- Name: postgis_scripts_build_date(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_scripts_build_date() RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$SELECT '2012-09-07 00:07:39'::text AS version$$;


ALTER FUNCTION public.postgis_scripts_build_date() OWNER TO postgres;

--
-- Name: FUNCTION postgis_scripts_build_date(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION postgis_scripts_build_date() IS 'Returns build date of the PostGIS scripts.';


--
-- Name: postgis_scripts_installed(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_scripts_installed() RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$ SELECT '2.0.1'::text || ' r' || 9979::text AS version $$;


ALTER FUNCTION public.postgis_scripts_installed() OWNER TO postgres;

--
-- Name: FUNCTION postgis_scripts_installed(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION postgis_scripts_installed() IS 'Returns version of the postgis scripts installed in this database.';


--
-- Name: postgis_scripts_released(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_scripts_released() RETURNS text
    LANGUAGE c IMMUTABLE
    AS '$libdir/postgis-2.0', 'postgis_scripts_released';


ALTER FUNCTION public.postgis_scripts_released() OWNER TO postgres;

--
-- Name: FUNCTION postgis_scripts_released(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION postgis_scripts_released() IS 'Returns the version number of the postgis.sql script released with the installed postgis lib.';


--
-- Name: postgis_svn_version(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_svn_version() RETURNS text
    LANGUAGE c IMMUTABLE
    AS '$libdir/postgis-2.0', 'postgis_svn_version';


ALTER FUNCTION public.postgis_svn_version() OWNER TO postgres;

--
-- Name: postgis_transform_geometry(geometry, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_transform_geometry(geometry, text, text, integer) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'transform_geom';


ALTER FUNCTION public.postgis_transform_geometry(geometry, text, text, integer) OWNER TO postgres;

--
-- Name: postgis_type_name(character varying, integer, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean DEFAULT true) RETURNS character varying
    LANGUAGE sql IMMUTABLE STRICT COST 200
    AS $_$
 SELECT CASE WHEN $3 THEN new_name ELSE old_name END As geomname
 	FROM 
 	( VALUES
 		 ('GEOMETRY', 'Geometry', 2) ,
 		 	('GEOMETRY', 'GeometryZ', 3) ,
 		 	('GEOMETRY', 'GeometryZM', 4) ,
			('GEOMETRYCOLLECTION', 'GeometryCollection', 2) ,
			('GEOMETRYCOLLECTION', 'GeometryCollectionZ', 3) ,
			('GEOMETRYCOLLECTIONM', 'GeometryCollectionM', 3) ,
			('GEOMETRYCOLLECTION', 'GeometryCollectionZM', 4) ,
			
			('POINT', 'Point',2) ,
			('POINTM','PointM',3) ,
			('POINT', 'PointZ',3) ,
			('POINT', 'PointZM',4) ,
			
			('MULTIPOINT','MultiPoint',2) ,
			('MULTIPOINT','MultiPointZ',3) ,
			('MULTIPOINTM','MultiPointM',3) ,
			('MULTIPOINT','MultiPointZM',4) ,
			
			('POLYGON', 'Polygon',2) ,
			('POLYGON', 'PolygonZ',3) ,
			('POLYGONM', 'PolygonM',3) ,
			('POLYGON', 'PolygonZM',4) ,
			
			('MULTIPOLYGON', 'MultiPolygon',2) ,
			('MULTIPOLYGON', 'MultiPolygonZ',3) ,
			('MULTIPOLYGONM', 'MultiPolygonM',3) ,
			('MULTIPOLYGON', 'MultiPolygonZM',4) ,
			
			('MULTILINESTRING', 'MultiLineString',2) ,
			('MULTILINESTRING', 'MultiLineStringZ',3) ,
			('MULTILINESTRINGM', 'MultiLineStringM',3) ,
			('MULTILINESTRING', 'MultiLineStringZM',4) ,
			
			('LINESTRING', 'LineString',2) ,
			('LINESTRING', 'LineStringZ',3) ,
			('LINESTRINGM', 'LineStringM',3) ,
			('LINESTRING', 'LineStringZM',4) ,
			
			('CIRCULARSTRING', 'CircularString',2) ,
			('CIRCULARSTRING', 'CircularStringZ',3) ,
			('CIRCULARSTRINGM', 'CircularStringM',3) ,
			('CIRCULARSTRING', 'CircularStringZM',4) ,
			
			('COMPOUNDCURVE', 'CompoundCurve',2) ,
			('COMPOUNDCURVE', 'CompoundCurveZ',3) ,
			('COMPOUNDCURVEM', 'CompoundCurveM',3) ,
			('COMPOUNDCURVE', 'CompoundCurveZM',4) ,
			
			('CURVEPOLYGON', 'CurvePolygon',2) ,
			('CURVEPOLYGON', 'CurvePolygonZ',3) ,
			('CURVEPOLYGONM', 'CurvePolygonM',3) ,
			('CURVEPOLYGON', 'CurvePolygonZM',4) ,
			
			('MULTICURVE', 'MultiCurve',2 ) ,
			('MULTICURVE', 'MultiCurveZ',3 ) ,
			('MULTICURVEM', 'MultiCurveM',3 ) ,
			('MULTICURVE', 'MultiCurveZM',4 ) ,
			
			('MULTISURFACE', 'MultiSurface', 2) ,
			('MULTISURFACE', 'MultiSurfaceZ', 3) ,
			('MULTISURFACEM', 'MultiSurfaceM', 3) ,
			('MULTISURFACE', 'MultiSurfaceZM', 4) ,
			
			('POLYHEDRALSURFACE', 'PolyhedralSurface',2) ,
			('POLYHEDRALSURFACE', 'PolyhedralSurfaceZ',3) ,
			('POLYHEDRALSURFACEM', 'PolyhedralSurfaceM',3) ,
			('POLYHEDRALSURFACE', 'PolyhedralSurfaceZM',4) ,
			
			('TRIANGLE', 'Triangle',2) ,
			('TRIANGLE', 'TriangleZ',3) ,
			('TRIANGLEM', 'TriangleM',3) ,
			('TRIANGLE', 'TriangleZM',4) ,

			('TIN', 'Tin', 2),
			('TIN', 'TinZ', 3),
			('TIN', 'TinM', 3),
			('TIN', 'TinZM', 4) )
			 As g(old_name, new_name, coord_dimension)
		WHERE (upper(old_name) = upper($1) OR upper(new_name) = upper($1))
			AND coord_dimension = $2;
$_$;


ALTER FUNCTION public.postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean) OWNER TO postgres;

--
-- Name: postgis_typmod_dims(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_typmod_dims(integer) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'postgis_typmod_dims';


ALTER FUNCTION public.postgis_typmod_dims(integer) OWNER TO postgres;

--
-- Name: postgis_typmod_srid(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_typmod_srid(integer) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'postgis_typmod_srid';


ALTER FUNCTION public.postgis_typmod_srid(integer) OWNER TO postgres;

--
-- Name: postgis_typmod_type(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_typmod_type(integer) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'postgis_typmod_type';


ALTER FUNCTION public.postgis_typmod_type(integer) OWNER TO postgres;

--
-- Name: postgis_version(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_version() RETURNS text
    LANGUAGE c IMMUTABLE
    AS '$libdir/postgis-2.0', 'postgis_version';


ALTER FUNCTION public.postgis_version() OWNER TO postgres;

--
-- Name: FUNCTION postgis_version(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION postgis_version() IS 'Returns PostGIS version number and compile-time options.';


--
-- Name: setsrid(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION setsrid(geometry, integer) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_set_srid';


ALTER FUNCTION public.setsrid(geometry, integer) OWNER TO postgres;

--
-- Name: srid(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION srid(geometry) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_get_srid';


ALTER FUNCTION public.srid(geometry) OWNER TO postgres;

--
-- Name: st_3dclosestpoint(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_3dclosestpoint(geom1 geometry, geom2 geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'LWGEOM_closestpoint3d';


ALTER FUNCTION public.st_3dclosestpoint(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_3dclosestpoint(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_3dclosestpoint(geom1 geometry, geom2 geometry) IS 'args: g1, g2 - Returns the 3-dimensional point on g1 that is closest to g2. This is the first point of the 3D shortest line.';


--
-- Name: st_3ddfullywithin(geometry, geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_3ddfullywithin(geom1 geometry, geom2 geometry, double precision) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && ST_Expand($2,$3) AND $2 && ST_Expand($1,$3) AND _ST_3DDFullyWithin($1, $2, $3)$_$;


ALTER FUNCTION public.st_3ddfullywithin(geom1 geometry, geom2 geometry, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_3ddfullywithin(geom1 geometry, geom2 geometry, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_3ddfullywithin(geom1 geometry, geom2 geometry, double precision) IS 'args: g1, g2, distance - Returns true if all of the 3D geometries are within the specified distance of one another.';


--
-- Name: st_3ddistance(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_3ddistance(geom1 geometry, geom2 geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'LWGEOM_mindistance3d';


ALTER FUNCTION public.st_3ddistance(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_3ddistance(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_3ddistance(geom1 geometry, geom2 geometry) IS 'args: g1, g2 - For geometry type Returns the 3-dimensional cartesian minimum distance (based on spatial ref) between two geometries in projected units.';


--
-- Name: st_3ddwithin(geometry, geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_3ddwithin(geom1 geometry, geom2 geometry, double precision) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && ST_Expand($2,$3) AND $2 && ST_Expand($1,$3) AND _ST_3DDWithin($1, $2, $3)$_$;


ALTER FUNCTION public.st_3ddwithin(geom1 geometry, geom2 geometry, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_3ddwithin(geom1 geometry, geom2 geometry, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_3ddwithin(geom1 geometry, geom2 geometry, double precision) IS 'args: g1, g2, distance_of_srid - For 3d (z) geometry type Returns true if two geometries 3d distance is within number of units.';


--
-- Name: st_3dintersects(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_3dintersects(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && $2 AND _ST_3DDWithin($1, $2, 0.0)$_$;


ALTER FUNCTION public.st_3dintersects(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_3dintersects(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_3dintersects(geom1 geometry, geom2 geometry) IS 'args: geomA, geomB - Returns TRUE if the Geometries "spatially intersect" in 3d - only for points and linestrings';


--
-- Name: st_3dlength(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_3dlength(geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_length_linestring';


ALTER FUNCTION public.st_3dlength(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_3dlength(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_3dlength(geometry) IS 'args: a_3dlinestring - Returns the 3-dimensional or 2-dimensional length of the geometry if it is a linestring or multi-linestring.';


--
-- Name: st_3dlength_spheroid(geometry, spheroid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_3dlength_spheroid(geometry, spheroid) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'LWGEOM_length_ellipsoid_linestring';


ALTER FUNCTION public.st_3dlength_spheroid(geometry, spheroid) OWNER TO postgres;

--
-- Name: FUNCTION st_3dlength_spheroid(geometry, spheroid); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_3dlength_spheroid(geometry, spheroid) IS 'args: a_linestring, a_spheroid - Calculates the length of a geometry on an ellipsoid, taking the elevation into account. This is just an alias for ST_Length_Spheroid.';


--
-- Name: st_3dlongestline(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_3dlongestline(geom1 geometry, geom2 geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'LWGEOM_longestline3d';


ALTER FUNCTION public.st_3dlongestline(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_3dlongestline(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_3dlongestline(geom1 geometry, geom2 geometry) IS 'args: g1, g2 - Returns the 3-dimensional longest line between two geometries';


--
-- Name: st_3dmakebox(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_3dmakebox(geom1 geometry, geom2 geometry) RETURNS box3d
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX3D_construct';


ALTER FUNCTION public.st_3dmakebox(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_3dmakebox(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_3dmakebox(geom1 geometry, geom2 geometry) IS 'args: point3DLowLeftBottom, point3DUpRightTop - Creates a BOX3D defined by the given 3d point geometries.';


--
-- Name: st_3dmaxdistance(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_3dmaxdistance(geom1 geometry, geom2 geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'LWGEOM_maxdistance3d';


ALTER FUNCTION public.st_3dmaxdistance(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_3dmaxdistance(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_3dmaxdistance(geom1 geometry, geom2 geometry) IS 'args: g1, g2 - For geometry type Returns the 3-dimensional cartesian maximum distance (based on spatial ref) between two geometries in projected units.';


--
-- Name: st_3dperimeter(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_3dperimeter(geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_perimeter_poly';


ALTER FUNCTION public.st_3dperimeter(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_3dperimeter(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_3dperimeter(geometry) IS 'args: geomA - Returns the 3-dimensional perimeter of the geometry, if it is a polygon or multi-polygon.';


--
-- Name: st_3dshortestline(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_3dshortestline(geom1 geometry, geom2 geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'LWGEOM_shortestline3d';


ALTER FUNCTION public.st_3dshortestline(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_3dshortestline(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_3dshortestline(geom1 geometry, geom2 geometry) IS 'args: g1, g2 - Returns the 3-dimensional shortest line between two geometries';


--
-- Name: st_addmeasure(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_addmeasure(geometry, double precision, double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'ST_AddMeasure';


ALTER FUNCTION public.st_addmeasure(geometry, double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_addmeasure(geometry, double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_addmeasure(geometry, double precision, double precision) IS 'args: geom_mline, measure_start, measure_end - Return a derived geometry with measure elements linearly interpolated between the start and end points. If the geometry has no measure dimension, one is added. If the geometry has a measure dimension, it is over-written with new values. Only LINESTRINGS and MULTILINESTRINGS are supported.';


--
-- Name: st_addpoint(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_addpoint(geom1 geometry, geom2 geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_addpoint';


ALTER FUNCTION public.st_addpoint(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_addpoint(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_addpoint(geom1 geometry, geom2 geometry) IS 'args: linestring, point - Adds a point to a LineString before point <position> (0-based index).';


--
-- Name: st_addpoint(geometry, geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_addpoint(geom1 geometry, geom2 geometry, integer) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_addpoint';


ALTER FUNCTION public.st_addpoint(geom1 geometry, geom2 geometry, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_addpoint(geom1 geometry, geom2 geometry, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_addpoint(geom1 geometry, geom2 geometry, integer) IS 'args: linestring, point, position - Adds a point to a LineString before point <position> (0-based index).';


--
-- Name: st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_Affine($1,  $2, $3, 0,  $4, $5, 0,  0, 0, 1,  $6, $7, 0)$_$;


ALTER FUNCTION public.st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision) IS 'args: geomA, a, b, d, e, xoff, yoff - Applies a 3d affine transformation to the geometry to do things like translate, rotate, scale in one step.';


--
-- Name: st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_affine';


ALTER FUNCTION public.st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) IS 'args: geomA, a, b, c, d, e, f, g, h, i, xoff, yoff, zoff - Applies a 3d affine transformation to the geometry to do things like translate, rotate, scale in one step.';


--
-- Name: st_area(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_area(geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_area_polygon';


ALTER FUNCTION public.st_area(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_area(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_area(geometry) IS 'args: g1 - Returns the area of the surface if it is a polygon or multi-polygon. For "geometry" type area is in SRID units. For "geography" area is in square meters.';


--
-- Name: st_area(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_area(text) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT ST_Area($1::geometry);  $_$;


ALTER FUNCTION public.st_area(text) OWNER TO postgres;

--
-- Name: st_area(geography, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_area(geog geography, use_spheroid boolean DEFAULT true) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'geography_area';


ALTER FUNCTION public.st_area(geog geography, use_spheroid boolean) OWNER TO postgres;

--
-- Name: FUNCTION st_area(geog geography, use_spheroid boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_area(geog geography, use_spheroid boolean) IS 'args: geog, use_spheroid=true - Returns the area of the surface if it is a polygon or multi-polygon. For "geometry" type area is in SRID units. For "geography" area is in square meters.';


--
-- Name: st_area2d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_area2d(geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_area_polygon';


ALTER FUNCTION public.st_area2d(geometry) OWNER TO postgres;

--
-- Name: st_asbinary(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asbinary(geometry) RETURNS bytea
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_asBinary';


ALTER FUNCTION public.st_asbinary(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_asbinary(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_asbinary(geometry) IS 'args: g1 - Return the Well-Known Binary (WKB) representation of the geometry/geography without SRID meta data.';


--
-- Name: st_asbinary(geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asbinary(geography) RETURNS bytea
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_asBinary';


ALTER FUNCTION public.st_asbinary(geography) OWNER TO postgres;

--
-- Name: FUNCTION st_asbinary(geography); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_asbinary(geography) IS 'args: g1 - Return the Well-Known Binary (WKB) representation of the geometry/geography without SRID meta data.';


--
-- Name: st_asbinary(geometry, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asbinary(geometry, text) RETURNS bytea
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_asBinary';


ALTER FUNCTION public.st_asbinary(geometry, text) OWNER TO postgres;

--
-- Name: FUNCTION st_asbinary(geometry, text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_asbinary(geometry, text) IS 'args: g1, NDR_or_XDR - Return the Well-Known Binary (WKB) representation of the geometry/geography without SRID meta data.';


--
-- Name: st_asbinary(geography, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asbinary(geography, text) RETURNS bytea
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT ST_AsBinary($1::geometry, $2);  $_$;


ALTER FUNCTION public.st_asbinary(geography, text) OWNER TO postgres;

--
-- Name: FUNCTION st_asbinary(geography, text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_asbinary(geography, text) IS 'args: g1, NDR_or_XDR - Return the Well-Known Binary (WKB) representation of the geometry/geography without SRID meta data.';


--
-- Name: st_asewkb(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asewkb(geometry) RETURNS bytea
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'WKBFromLWGEOM';


ALTER FUNCTION public.st_asewkb(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_asewkb(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_asewkb(geometry) IS 'args: g1 - Return the Well-Known Binary (WKB) representation of the geometry with SRID meta data.';


--
-- Name: st_asewkb(geometry, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asewkb(geometry, text) RETURNS bytea
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'WKBFromLWGEOM';


ALTER FUNCTION public.st_asewkb(geometry, text) OWNER TO postgres;

--
-- Name: FUNCTION st_asewkb(geometry, text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_asewkb(geometry, text) IS 'args: g1, NDR_or_XDR - Return the Well-Known Binary (WKB) representation of the geometry with SRID meta data.';


--
-- Name: st_asewkt(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asewkt(geometry) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_asEWKT';


ALTER FUNCTION public.st_asewkt(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_asewkt(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_asewkt(geometry) IS 'args: g1 - Return the Well-Known Text (WKT) representation of the geometry with SRID meta data.';


--
-- Name: st_asewkt(geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asewkt(geography) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_asEWKT';


ALTER FUNCTION public.st_asewkt(geography) OWNER TO postgres;

--
-- Name: FUNCTION st_asewkt(geography); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_asewkt(geography) IS 'args: g1 - Return the Well-Known Text (WKT) representation of the geometry with SRID meta data.';


--
-- Name: st_asewkt(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asewkt(text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT ST_AsEWKT($1::geometry);  $_$;


ALTER FUNCTION public.st_asewkt(text) OWNER TO postgres;

--
-- Name: st_asgeojson(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asgeojson(text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT _ST_AsGeoJson(1, $1::geometry,15,0);  $_$;


ALTER FUNCTION public.st_asgeojson(text) OWNER TO postgres;

--
-- Name: st_asgeojson(geometry, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asgeojson(geom geometry, maxdecimaldigits integer DEFAULT 15, options integer DEFAULT 0) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT _ST_AsGeoJson(1, $1, $2, $3); $_$;


ALTER FUNCTION public.st_asgeojson(geom geometry, maxdecimaldigits integer, options integer) OWNER TO postgres;

--
-- Name: FUNCTION st_asgeojson(geom geometry, maxdecimaldigits integer, options integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_asgeojson(geom geometry, maxdecimaldigits integer, options integer) IS 'args: geom, maxdecimaldigits=15, options=0 - Return the geometry as a GeoJSON element.';


--
-- Name: st_asgeojson(geography, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asgeojson(geog geography, maxdecimaldigits integer DEFAULT 15, options integer DEFAULT 0) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT _ST_AsGeoJson(1, $1, $2, $3); $_$;


ALTER FUNCTION public.st_asgeojson(geog geography, maxdecimaldigits integer, options integer) OWNER TO postgres;

--
-- Name: FUNCTION st_asgeojson(geog geography, maxdecimaldigits integer, options integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_asgeojson(geog geography, maxdecimaldigits integer, options integer) IS 'args: geog, maxdecimaldigits=15, options=0 - Return the geometry as a GeoJSON element.';


--
-- Name: st_asgeojson(integer, geometry, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asgeojson(gj_version integer, geom geometry, maxdecimaldigits integer DEFAULT 15, options integer DEFAULT 0) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT _ST_AsGeoJson($1, $2, $3, $4); $_$;


ALTER FUNCTION public.st_asgeojson(gj_version integer, geom geometry, maxdecimaldigits integer, options integer) OWNER TO postgres;

--
-- Name: FUNCTION st_asgeojson(gj_version integer, geom geometry, maxdecimaldigits integer, options integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_asgeojson(gj_version integer, geom geometry, maxdecimaldigits integer, options integer) IS 'args: gj_version, geom, maxdecimaldigits=15, options=0 - Return the geometry as a GeoJSON element.';


--
-- Name: st_asgeojson(integer, geography, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asgeojson(gj_version integer, geog geography, maxdecimaldigits integer DEFAULT 15, options integer DEFAULT 0) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT _ST_AsGeoJson($1, $2, $3, $4); $_$;


ALTER FUNCTION public.st_asgeojson(gj_version integer, geog geography, maxdecimaldigits integer, options integer) OWNER TO postgres;

--
-- Name: FUNCTION st_asgeojson(gj_version integer, geog geography, maxdecimaldigits integer, options integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_asgeojson(gj_version integer, geog geography, maxdecimaldigits integer, options integer) IS 'args: gj_version, geog, maxdecimaldigits=15, options=0 - Return the geometry as a GeoJSON element.';


--
-- Name: st_asgml(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asgml(text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT _ST_AsGML(2,$1::geometry,15,0, NULL);  $_$;


ALTER FUNCTION public.st_asgml(text) OWNER TO postgres;

--
-- Name: st_asgml(geometry, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asgml(geom geometry, maxdecimaldigits integer DEFAULT 15, options integer DEFAULT 0) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT _ST_AsGML(2, $1, $2, $3, null); $_$;


ALTER FUNCTION public.st_asgml(geom geometry, maxdecimaldigits integer, options integer) OWNER TO postgres;

--
-- Name: FUNCTION st_asgml(geom geometry, maxdecimaldigits integer, options integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_asgml(geom geometry, maxdecimaldigits integer, options integer) IS 'args: geom, maxdecimaldigits=15, options=0 - Return the geometry as a GML version 2 or 3 element.';


--
-- Name: st_asgml(geography, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asgml(geog geography, maxdecimaldigits integer DEFAULT 15, options integer DEFAULT 0) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT _ST_AsGML(2, $1, $2, $3, null)$_$;


ALTER FUNCTION public.st_asgml(geog geography, maxdecimaldigits integer, options integer) OWNER TO postgres;

--
-- Name: FUNCTION st_asgml(geog geography, maxdecimaldigits integer, options integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_asgml(geog geography, maxdecimaldigits integer, options integer) IS 'args: geog, maxdecimaldigits=15, options=0 - Return the geometry as a GML version 2 or 3 element.';


--
-- Name: st_asgml(integer, geometry, integer, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asgml(version integer, geom geometry, maxdecimaldigits integer DEFAULT 15, options integer DEFAULT 0, nprefix text DEFAULT NULL::text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$ SELECT _ST_AsGML($1, $2, $3, $4,$5); $_$;


ALTER FUNCTION public.st_asgml(version integer, geom geometry, maxdecimaldigits integer, options integer, nprefix text) OWNER TO postgres;

--
-- Name: FUNCTION st_asgml(version integer, geom geometry, maxdecimaldigits integer, options integer, nprefix text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_asgml(version integer, geom geometry, maxdecimaldigits integer, options integer, nprefix text) IS 'args: version, geom, maxdecimaldigits=15, options=0, nprefix=null - Return the geometry as a GML version 2 or 3 element.';


--
-- Name: st_asgml(integer, geography, integer, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asgml(version integer, geog geography, maxdecimaldigits integer DEFAULT 15, options integer DEFAULT 0, nprefix text DEFAULT NULL::text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$ SELECT _ST_AsGML($1, $2, $3, $4, $5);$_$;


ALTER FUNCTION public.st_asgml(version integer, geog geography, maxdecimaldigits integer, options integer, nprefix text) OWNER TO postgres;

--
-- Name: FUNCTION st_asgml(version integer, geog geography, maxdecimaldigits integer, options integer, nprefix text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_asgml(version integer, geog geography, maxdecimaldigits integer, options integer, nprefix text) IS 'args: version, geog, maxdecimaldigits=15, options=0, nprefix=null - Return the geometry as a GML version 2 or 3 element.';


--
-- Name: st_ashexewkb(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_ashexewkb(geometry) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_asHEXEWKB';


ALTER FUNCTION public.st_ashexewkb(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_ashexewkb(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_ashexewkb(geometry) IS 'args: g1 - Returns a Geometry in HEXEWKB format (as text) using either little-endian (NDR) or big-endian (XDR) encoding.';


--
-- Name: st_ashexewkb(geometry, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_ashexewkb(geometry, text) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_asHEXEWKB';


ALTER FUNCTION public.st_ashexewkb(geometry, text) OWNER TO postgres;

--
-- Name: FUNCTION st_ashexewkb(geometry, text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_ashexewkb(geometry, text) IS 'args: g1, NDRorXDR - Returns a Geometry in HEXEWKB format (as text) using either little-endian (NDR) or big-endian (XDR) encoding.';


--
-- Name: st_askml(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_askml(text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT _ST_AsKML(2, $1::geometry, 15, null);  $_$;


ALTER FUNCTION public.st_askml(text) OWNER TO postgres;

--
-- Name: st_askml(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_askml(geom geometry, maxdecimaldigits integer DEFAULT 15) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT _ST_AsKML(2, ST_Transform($1,4326), $2, null); $_$;


ALTER FUNCTION public.st_askml(geom geometry, maxdecimaldigits integer) OWNER TO postgres;

--
-- Name: FUNCTION st_askml(geom geometry, maxdecimaldigits integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_askml(geom geometry, maxdecimaldigits integer) IS 'args: geom, maxdecimaldigits=15 - Return the geometry as a KML element. Several variants. Default version=2, default precision=15';


--
-- Name: st_askml(geography, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_askml(geog geography, maxdecimaldigits integer DEFAULT 15) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT _ST_AsKML(2, $1, $2, null)$_$;


ALTER FUNCTION public.st_askml(geog geography, maxdecimaldigits integer) OWNER TO postgres;

--
-- Name: FUNCTION st_askml(geog geography, maxdecimaldigits integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_askml(geog geography, maxdecimaldigits integer) IS 'args: geog, maxdecimaldigits=15 - Return the geometry as a KML element. Several variants. Default version=2, default precision=15';


--
-- Name: st_askml(integer, geometry, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_askml(version integer, geom geometry, maxdecimaldigits integer DEFAULT 15, nprefix text DEFAULT NULL::text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$ SELECT _ST_AsKML($1, ST_Transform($2,4326), $3, $4); $_$;


ALTER FUNCTION public.st_askml(version integer, geom geometry, maxdecimaldigits integer, nprefix text) OWNER TO postgres;

--
-- Name: FUNCTION st_askml(version integer, geom geometry, maxdecimaldigits integer, nprefix text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_askml(version integer, geom geometry, maxdecimaldigits integer, nprefix text) IS 'args: version, geom, maxdecimaldigits=15, nprefix=NULL - Return the geometry as a KML element. Several variants. Default version=2, default precision=15';


--
-- Name: st_askml(integer, geography, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_askml(version integer, geog geography, maxdecimaldigits integer DEFAULT 15, nprefix text DEFAULT NULL::text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT _ST_AsKML($1, $2, $3, $4)$_$;


ALTER FUNCTION public.st_askml(version integer, geog geography, maxdecimaldigits integer, nprefix text) OWNER TO postgres;

--
-- Name: FUNCTION st_askml(version integer, geog geography, maxdecimaldigits integer, nprefix text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_askml(version integer, geog geography, maxdecimaldigits integer, nprefix text) IS 'args: version, geog, maxdecimaldigits=15, nprefix=NULL - Return the geometry as a KML element. Several variants. Default version=2, default precision=15';


--
-- Name: st_aslatlontext(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_aslatlontext(geometry) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT ST_AsLatLonText($1, '') $_$;


ALTER FUNCTION public.st_aslatlontext(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_aslatlontext(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_aslatlontext(geometry) IS 'args: pt - Return the Degrees, Minutes, Seconds representation of the given point.';


--
-- Name: st_aslatlontext(geometry, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_aslatlontext(geometry, text) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_to_latlon';


ALTER FUNCTION public.st_aslatlontext(geometry, text) OWNER TO postgres;

--
-- Name: FUNCTION st_aslatlontext(geometry, text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_aslatlontext(geometry, text) IS 'args: pt, format - Return the Degrees, Minutes, Seconds representation of the given point.';


--
-- Name: st_assvg(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_assvg(text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT ST_AsSVG($1::geometry,0,15);  $_$;


ALTER FUNCTION public.st_assvg(text) OWNER TO postgres;

--
-- Name: st_assvg(geometry, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_assvg(geom geometry, rel integer DEFAULT 0, maxdecimaldigits integer DEFAULT 15) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_asSVG';


ALTER FUNCTION public.st_assvg(geom geometry, rel integer, maxdecimaldigits integer) OWNER TO postgres;

--
-- Name: FUNCTION st_assvg(geom geometry, rel integer, maxdecimaldigits integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_assvg(geom geometry, rel integer, maxdecimaldigits integer) IS 'args: geom, rel=0, maxdecimaldigits=15 - Returns a Geometry in SVG path data given a geometry or geography object.';


--
-- Name: st_assvg(geography, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_assvg(geog geography, rel integer DEFAULT 0, maxdecimaldigits integer DEFAULT 15) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_as_svg';


ALTER FUNCTION public.st_assvg(geog geography, rel integer, maxdecimaldigits integer) OWNER TO postgres;

--
-- Name: FUNCTION st_assvg(geog geography, rel integer, maxdecimaldigits integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_assvg(geog geography, rel integer, maxdecimaldigits integer) IS 'args: geog, rel=0, maxdecimaldigits=15 - Returns a Geometry in SVG path data given a geometry or geography object.';


--
-- Name: st_astext(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_astext(geometry) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_asText';


ALTER FUNCTION public.st_astext(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_astext(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_astext(geometry) IS 'args: g1 - Return the Well-Known Text (WKT) representation of the geometry/geography without SRID metadata.';


--
-- Name: st_astext(geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_astext(geography) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_asText';


ALTER FUNCTION public.st_astext(geography) OWNER TO postgres;

--
-- Name: FUNCTION st_astext(geography); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_astext(geography) IS 'args: g1 - Return the Well-Known Text (WKT) representation of the geometry/geography without SRID metadata.';


--
-- Name: st_astext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_astext(text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT ST_AsText($1::geometry);  $_$;


ALTER FUNCTION public.st_astext(text) OWNER TO postgres;

--
-- Name: st_asx3d(geometry, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asx3d(geom geometry, maxdecimaldigits integer DEFAULT 15, options integer DEFAULT 0) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT _ST_AsX3D(3,$1,$2,$3,'');$_$;


ALTER FUNCTION public.st_asx3d(geom geometry, maxdecimaldigits integer, options integer) OWNER TO postgres;

--
-- Name: FUNCTION st_asx3d(geom geometry, maxdecimaldigits integer, options integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_asx3d(geom geometry, maxdecimaldigits integer, options integer) IS 'args: g1, maxdecimaldigits=15, options=0 - Returns a Geometry in X3D xml node element format: ISO-IEC-19776-1.2-X3DEncodings-XML';


--
-- Name: st_azimuth(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_azimuth(geom1 geometry, geom2 geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_azimuth';


ALTER FUNCTION public.st_azimuth(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_azimuth(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_azimuth(geom1 geometry, geom2 geometry) IS 'args: pointA, pointB - Returns the angle in radians from the horizontal of the vector defined by pointA and pointB. Angle is computed clockwise from down-to-up: on the clock: 12=0; 3=PI/2; 6=PI; 9=3PI/2.';


--
-- Name: st_azimuth(geography, geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_azimuth(geog1 geography, geog2 geography) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'geography_azimuth';


ALTER FUNCTION public.st_azimuth(geog1 geography, geog2 geography) OWNER TO postgres;

--
-- Name: FUNCTION st_azimuth(geog1 geography, geog2 geography); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_azimuth(geog1 geography, geog2 geography) IS 'args: pointA, pointB - Returns the angle in radians from the horizontal of the vector defined by pointA and pointB. Angle is computed clockwise from down-to-up: on the clock: 12=0; 3=PI/2; 6=PI; 9=3PI/2.';


--
-- Name: st_bdmpolyfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_bdmpolyfromtext(text, integer) RETURNS geometry
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $_$
DECLARE
	geomtext alias for $1;
	srid alias for $2;
	mline geometry;
	geom geometry;
BEGIN
	mline := ST_MultiLineStringFromText(geomtext, srid);

	IF mline IS NULL
	THEN
		RAISE EXCEPTION 'Input is not a MultiLinestring';
	END IF;

	geom := ST_Multi(ST_BuildArea(mline));

	RETURN geom;
END;
$_$;


ALTER FUNCTION public.st_bdmpolyfromtext(text, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_bdmpolyfromtext(text, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_bdmpolyfromtext(text, integer) IS 'args: WKT, srid - Construct a MultiPolygon given an arbitrary collection of closed linestrings as a MultiLineString text representation Well-Known text representation.';


--
-- Name: st_bdpolyfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_bdpolyfromtext(text, integer) RETURNS geometry
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $_$
DECLARE
	geomtext alias for $1;
	srid alias for $2;
	mline geometry;
	geom geometry;
BEGIN
	mline := ST_MultiLineStringFromText(geomtext, srid);

	IF mline IS NULL
	THEN
		RAISE EXCEPTION 'Input is not a MultiLinestring';
	END IF;

	geom := ST_BuildArea(mline);

	IF GeometryType(geom) != 'POLYGON'
	THEN
		RAISE EXCEPTION 'Input returns more then a single polygon, try using BdMPolyFromText instead';
	END IF;

	RETURN geom;
END;
$_$;


ALTER FUNCTION public.st_bdpolyfromtext(text, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_bdpolyfromtext(text, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_bdpolyfromtext(text, integer) IS 'args: WKT, srid - Construct a Polygon given an arbitrary collection of closed linestrings as a MultiLineString Well-Known text representation.';


--
-- Name: st_boundary(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_boundary(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'boundary';


ALTER FUNCTION public.st_boundary(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_boundary(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_boundary(geometry) IS 'args: geomA - Returns the closure of the combinatorial boundary of this Geometry.';


--
-- Name: st_buffer(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_buffer(geometry, double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'buffer';


ALTER FUNCTION public.st_buffer(geometry, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_buffer(geometry, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_buffer(geometry, double precision) IS 'args: g1, radius_of_buffer - (T) For geometry: Returns a geometry that represents all points whose distance from this Geometry is less than or equal to distance. Calculations are in the Spatial Reference System of this Geometry. For geography: Uses a planar transform wrapper. Introduced in 1.5 support for different end cap and mitre settings to control shape. buffer_style options: quad_segs=#,endcap=round|flat|square,join=round|mitre|bevel,mitre_limit=#.#';


--
-- Name: st_buffer(geography, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_buffer(geography, double precision) RETURNS geography
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT geography(ST_Transform(ST_Buffer(ST_Transform(geometry($1), _ST_BestSRID($1)), $2), 4326))$_$;


ALTER FUNCTION public.st_buffer(geography, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_buffer(geography, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_buffer(geography, double precision) IS 'args: g1, radius_of_buffer_in_meters - (T) For geometry: Returns a geometry that represents all points whose distance from this Geometry is less than or equal to distance. Calculations are in the Spatial Reference System of this Geometry. For geography: Uses a planar transform wrapper. Introduced in 1.5 support for different end cap and mitre settings to control shape. buffer_style options: quad_segs=#,endcap=round|flat|square,join=round|mitre|bevel,mitre_limit=#.#';


--
-- Name: st_buffer(text, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_buffer(text, double precision) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT ST_Buffer($1::geometry, $2);  $_$;


ALTER FUNCTION public.st_buffer(text, double precision) OWNER TO postgres;

--
-- Name: st_buffer(geometry, double precision, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_buffer(geometry, double precision, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT _ST_Buffer($1, $2,
		CAST('quad_segs='||CAST($3 AS text) as cstring))
	   $_$;


ALTER FUNCTION public.st_buffer(geometry, double precision, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_buffer(geometry, double precision, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_buffer(geometry, double precision, integer) IS 'args: g1, radius_of_buffer, num_seg_quarter_circle - (T) For geometry: Returns a geometry that represents all points whose distance from this Geometry is less than or equal to distance. Calculations are in the Spatial Reference System of this Geometry. For geography: Uses a planar transform wrapper. Introduced in 1.5 support for different end cap and mitre settings to control shape. buffer_style options: quad_segs=#,endcap=round|flat|square,join=round|mitre|bevel,mitre_limit=#.#';


--
-- Name: st_buffer(geometry, double precision, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_buffer(geometry, double precision, text) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT _ST_Buffer($1, $2,
		CAST( regexp_replace($3, '^[0123456789]+$',
			'quad_segs='||$3) AS cstring)
		)
	   $_$;


ALTER FUNCTION public.st_buffer(geometry, double precision, text) OWNER TO postgres;

--
-- Name: FUNCTION st_buffer(geometry, double precision, text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_buffer(geometry, double precision, text) IS 'args: g1, radius_of_buffer, buffer_style_parameters - (T) For geometry: Returns a geometry that represents all points whose distance from this Geometry is less than or equal to distance. Calculations are in the Spatial Reference System of this Geometry. For geography: Uses a planar transform wrapper. Introduced in 1.5 support for different end cap and mitre settings to control shape. buffer_style options: quad_segs=#,endcap=round|flat|square,join=round|mitre|bevel,mitre_limit=#.#';


--
-- Name: st_buildarea(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_buildarea(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'ST_BuildArea';


ALTER FUNCTION public.st_buildarea(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_buildarea(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_buildarea(geometry) IS 'args: A - Creates an areal geometry formed by the constituent linework of given geometry';


--
-- Name: st_centroid(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_centroid(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'centroid';


ALTER FUNCTION public.st_centroid(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_centroid(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_centroid(geometry) IS 'args: g1 - Returns the geometric center of a geometry.';


--
-- Name: st_cleangeometry(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_cleangeometry(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'ST_CleanGeometry';


ALTER FUNCTION public.st_cleangeometry(geometry) OWNER TO postgres;

--
-- Name: st_closestpoint(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_closestpoint(geom1 geometry, geom2 geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_closestpoint';


ALTER FUNCTION public.st_closestpoint(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_closestpoint(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_closestpoint(geom1 geometry, geom2 geometry) IS 'args: g1, g2 - Returns the 2-dimensional point on g1 that is closest to g2. This is the first point of the shortest line.';


--
-- Name: st_collect(geometry[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_collect(geometry[]) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_collect_garray';


ALTER FUNCTION public.st_collect(geometry[]) OWNER TO postgres;

--
-- Name: FUNCTION st_collect(geometry[]); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_collect(geometry[]) IS 'args: g1_array - Return a specified ST_Geometry value from a collection of other geometries.';


--
-- Name: st_collect(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_collect(geom1 geometry, geom2 geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE
    AS '$libdir/postgis-2.0', 'LWGEOM_collect';


ALTER FUNCTION public.st_collect(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_collect(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_collect(geom1 geometry, geom2 geometry) IS 'args: g1, g2 - Return a specified ST_Geometry value from a collection of other geometries.';


--
-- Name: st_collectionextract(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_collectionextract(geometry, integer) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'ST_CollectionExtract';


ALTER FUNCTION public.st_collectionextract(geometry, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_collectionextract(geometry, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_collectionextract(geometry, integer) IS 'args: collection, type - Given a (multi)geometry, returns a (multi)geometry consisting only of elements of the specified type.';


--
-- Name: st_collectionhomogenize(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_collectionhomogenize(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'ST_CollectionHomogenize';


ALTER FUNCTION public.st_collectionhomogenize(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_collectionhomogenize(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_collectionhomogenize(geometry) IS 'args: collection - Given a geometry collection, returns the "simplest" representation of the contents.';


--
-- Name: st_combine_bbox(box2d, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_combine_bbox(box2d, geometry) RETURNS box2d
    LANGUAGE c IMMUTABLE
    AS '$libdir/postgis-2.0', 'BOX2D_combine';


ALTER FUNCTION public.st_combine_bbox(box2d, geometry) OWNER TO postgres;

--
-- Name: st_combine_bbox(box3d, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_combine_bbox(box3d, geometry) RETURNS box3d
    LANGUAGE c IMMUTABLE
    AS '$libdir/postgis-2.0', 'BOX3D_combine';


ALTER FUNCTION public.st_combine_bbox(box3d, geometry) OWNER TO postgres;

--
-- Name: st_concavehull(geometry, double precision, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_concavehull(param_geom geometry, param_pctconvex double precision, param_allow_holes boolean DEFAULT false) RETURNS geometry
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
	DECLARE
		var_convhull geometry := ST_ConvexHull(param_geom);
		var_param_geom geometry := param_geom;
		var_initarea float := ST_Area(var_convhull);
		var_newarea float := var_initarea;
		var_div integer := 6; 
		var_tempgeom geometry;
		var_tempgeom2 geometry;
		var_cent geometry;
		var_geoms geometry[4]; 
		var_enline geometry;
		var_resultgeom geometry;
		var_atempgeoms geometry[];
		var_buf float := 1; 
	BEGIN
		-- We start with convex hull as our base
		var_resultgeom := var_convhull;
		
		IF param_pctconvex = 1 THEN
			return var_resultgeom;
		ELSIF ST_GeometryType(var_param_geom) = 'ST_Polygon' THEN -- it is as concave as it is going to get
			IF param_allow_holes THEN -- leave the holes
				RETURN var_param_geom;
			ELSE -- remove the holes
				var_resultgeom := ST_MakePolygon(ST_ExteriorRing(var_param_geom));
				RETURN var_resultgeom;
			END IF;
		END IF;
		IF ST_Dimension(var_resultgeom) > 1 AND param_pctconvex BETWEEN 0 and 0.98 THEN
		-- get linestring that forms envelope of geometry
			var_enline := ST_Boundary(ST_Envelope(var_param_geom));
			var_buf := ST_Length(var_enline)/1000.0;
			IF ST_GeometryType(var_param_geom) = 'ST_MultiPoint' AND ST_NumGeometries(var_param_geom) BETWEEN 4 and 200 THEN
			-- we make polygons out of points since they are easier to cave in. 
			-- Note we limit to between 4 and 200 points because this process is slow and gets quadratically slow
				var_buf := sqrt(ST_Area(var_convhull)*0.8/(ST_NumGeometries(var_param_geom)*ST_NumGeometries(var_param_geom)));
				var_atempgeoms := ARRAY(SELECT geom FROM ST_DumpPoints(var_param_geom));
				-- 5 and 10 and just fudge factors
				var_tempgeom := ST_Union(ARRAY(SELECT geom
						FROM (
						-- fuse near neighbors together
						SELECT DISTINCT ON (i) i,  ST_Distance(var_atempgeoms[i],var_atempgeoms[j]), ST_Buffer(ST_MakeLine(var_atempgeoms[i], var_atempgeoms[j]) , var_buf*5, 'quad_segs=3') As geom
								FROM generate_series(1,array_upper(var_atempgeoms, 1)) As i
									INNER JOIN generate_series(1,array_upper(var_atempgeoms, 1)) As j 
										ON (
								 NOT ST_Intersects(var_atempgeoms[i],var_atempgeoms[j])
									AND ST_DWithin(var_atempgeoms[i],var_atempgeoms[j], var_buf*10)
									)
								UNION ALL
						-- catch the ones with no near neighbors
								SELECT i, 0, ST_Buffer(var_atempgeoms[i] , var_buf*10, 'quad_segs=3') As geom
								FROM generate_series(1,array_upper(var_atempgeoms, 1)) As i
									LEFT JOIN generate_series(ceiling(array_upper(var_atempgeoms,1)/2)::integer,array_upper(var_atempgeoms, 1)) As j 
										ON (
								 NOT ST_Intersects(var_atempgeoms[i],var_atempgeoms[j])
									AND ST_DWithin(var_atempgeoms[i],var_atempgeoms[j], var_buf*10) 
									)
									WHERE j IS NULL
								ORDER BY 1, 2
							) As foo	) );
				IF ST_IsValid(var_tempgeom) AND ST_GeometryType(var_tempgeom) = 'ST_Polygon' THEN
					var_tempgeom := ST_Intersection(var_tempgeom, var_convhull);
					IF param_allow_holes THEN
						var_param_geom := var_tempgeom;
					ELSE
						var_param_geom := ST_MakePolygon(ST_ExteriorRing(var_tempgeom));
					END IF;
					return var_param_geom;
				ELSIF ST_IsValid(var_tempgeom) THEN
					var_param_geom := ST_Intersection(var_tempgeom, var_convhull);	
				END IF;
			END IF;

			IF ST_GeometryType(var_param_geom) = 'ST_Polygon' THEN
				IF NOT param_allow_holes THEN
					var_param_geom := ST_MakePolygon(ST_ExteriorRing(var_param_geom));
				END IF;
				return var_param_geom;
			END IF;
            var_cent := ST_Centroid(var_param_geom);
            IF (ST_XMax(var_enline) - ST_XMin(var_enline) ) > var_buf AND (ST_YMax(var_enline) - ST_YMin(var_enline) ) > var_buf THEN
                    IF ST_Dwithin(ST_Centroid(var_convhull) , ST_Centroid(ST_Envelope(var_param_geom)), var_buf/2) THEN
                -- If the geometric dimension is > 1 and the object is symettric (cutting at centroid will not work -- offset a bit)
                        var_cent := ST_Translate(var_cent, (ST_XMax(var_enline) - ST_XMin(var_enline))/1000,  (ST_YMAX(var_enline) - ST_YMin(var_enline))/1000);
                    ELSE
                        -- uses closest point on geometry to centroid. I can't explain why we are doing this
                        var_cent := ST_ClosestPoint(var_param_geom,var_cent);
                    END IF;
                    IF ST_DWithin(var_cent, var_enline,var_buf) THEN
                        var_cent := ST_centroid(ST_Envelope(var_param_geom));
                    END IF;
                    -- break envelope into 4 triangles about the centroid of the geometry and returned the clipped geometry in each quadrant
                    FOR i in 1 .. 4 LOOP
                       var_geoms[i] := ST_MakePolygon(ST_MakeLine(ARRAY[ST_PointN(var_enline,i), ST_PointN(var_enline,i+1), var_cent, ST_PointN(var_enline,i)]));
                       var_geoms[i] := ST_Intersection(var_param_geom, ST_Buffer(var_geoms[i],var_buf));
                       IF ST_IsValid(var_geoms[i]) THEN 
                            
                       ELSE
                            var_geoms[i] := ST_BuildArea(ST_MakeLine(ARRAY[ST_PointN(var_enline,i), ST_PointN(var_enline,i+1), var_cent, ST_PointN(var_enline,i)]));
                       END IF; 
                    END LOOP;
                    var_tempgeom := ST_Union(ARRAY[ST_ConvexHull(var_geoms[1]), ST_ConvexHull(var_geoms[2]) , ST_ConvexHull(var_geoms[3]), ST_ConvexHull(var_geoms[4])]); 
                    --RAISE NOTICE 'Curr vex % ', ST_AsText(var_tempgeom);
                    IF ST_Area(var_tempgeom) <= var_newarea AND ST_IsValid(var_tempgeom)  THEN --AND ST_GeometryType(var_tempgeom) ILIKE '%Polygon'
                        
                        var_tempgeom := ST_Buffer(ST_ConcaveHull(var_geoms[1],least(param_pctconvex + param_pctconvex/var_div),true),var_buf, 'quad_segs=2');
                        FOR i IN 1 .. 4 LOOP
                            var_geoms[i] := ST_Buffer(ST_ConcaveHull(var_geoms[i],least(param_pctconvex + param_pctconvex/var_div),true), var_buf, 'quad_segs=2');
                            IF ST_IsValid(var_geoms[i]) Then
                                var_tempgeom := ST_Union(var_tempgeom, var_geoms[i]);
                            ELSE
                                RAISE NOTICE 'Not valid % %', i, ST_AsText(var_tempgeom);
                                var_tempgeom := ST_Union(var_tempgeom, ST_ConvexHull(var_geoms[i]));
                            END IF; 
                        END LOOP;

                        --RAISE NOTICE 'Curr concave % ', ST_AsText(var_tempgeom);
                        IF ST_IsValid(var_tempgeom) THEN
                            var_resultgeom := var_tempgeom;
                        END IF;
                        var_newarea := ST_Area(var_resultgeom);
                    ELSIF ST_IsValid(var_tempgeom) THEN
                        var_resultgeom := var_tempgeom;
                    END IF;

                    IF ST_NumGeometries(var_resultgeom) > 1  THEN
                        var_tempgeom := _ST_ConcaveHull(var_resultgeom);
                        IF ST_IsValid(var_tempgeom) AND ST_GeometryType(var_tempgeom) ILIKE 'ST_Polygon' THEN
                            var_resultgeom := var_tempgeom;
                        ELSE
                            var_resultgeom := ST_Buffer(var_tempgeom,var_buf, 'quad_segs=2');
                        END IF;
                    END IF;
                    IF param_allow_holes = false THEN 
                    -- only keep exterior ring since we do not want holes
                        var_resultgeom := ST_MakePolygon(ST_ExteriorRing(var_resultgeom));
                    END IF;
                ELSE
                    var_resultgeom := ST_Buffer(var_resultgeom,var_buf);
                END IF;
                var_resultgeom := ST_Intersection(var_resultgeom, ST_ConvexHull(var_param_geom));
            ELSE
                -- dimensions are too small to cut
                var_resultgeom := _ST_ConcaveHull(var_param_geom);
            END IF;
            RETURN var_resultgeom;
	END;
$$;


ALTER FUNCTION public.st_concavehull(param_geom geometry, param_pctconvex double precision, param_allow_holes boolean) OWNER TO postgres;

--
-- Name: FUNCTION st_concavehull(param_geom geometry, param_pctconvex double precision, param_allow_holes boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_concavehull(param_geom geometry, param_pctconvex double precision, param_allow_holes boolean) IS 'args: geomA, target_percent, allow_holes=false - The concave hull of a geometry represents a possibly concave geometry that encloses all geometries within the set. You can think of it as shrink wrapping.';


--
-- Name: st_contains(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_contains(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && $2 AND _ST_Contains($1,$2)$_$;


ALTER FUNCTION public.st_contains(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_contains(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_contains(geom1 geometry, geom2 geometry) IS 'args: geomA, geomB - Returns true if and only if no points of B lie in the exterior of A, and at least one point of the interior of B lies in the interior of A.';


--
-- Name: st_containsproperly(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_containsproperly(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && $2 AND _ST_ContainsProperly($1,$2)$_$;


ALTER FUNCTION public.st_containsproperly(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_containsproperly(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_containsproperly(geom1 geometry, geom2 geometry) IS 'args: geomA, geomB - Returns true if B intersects the interior of A but not the boundary (or exterior). A does not contain properly itself, but does contain itself.';


--
-- Name: st_convexhull(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_convexhull(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'convexhull';


ALTER FUNCTION public.st_convexhull(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_convexhull(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_convexhull(geometry) IS 'args: geomA - The convex hull of a geometry represents the minimum convex geometry that encloses all geometries within the set.';


--
-- Name: st_coorddim(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_coorddim(geometry geometry) RETURNS smallint
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_ndims';


ALTER FUNCTION public.st_coorddim(geometry geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_coorddim(geometry geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_coorddim(geometry geometry) IS 'args: geomA - Return the coordinate dimension of the ST_Geometry value.';


--
-- Name: st_coveredby(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_coveredby(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && $2 AND _ST_CoveredBy($1,$2)$_$;


ALTER FUNCTION public.st_coveredby(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_coveredby(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_coveredby(geom1 geometry, geom2 geometry) IS 'args: geomA, geomB - Returns 1 (TRUE) if no point in Geometry/Geography A is outside Geometry/Geography B';


--
-- Name: st_coveredby(geography, geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_coveredby(geography, geography) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && $2 AND _ST_Covers($2, $1)$_$;


ALTER FUNCTION public.st_coveredby(geography, geography) OWNER TO postgres;

--
-- Name: FUNCTION st_coveredby(geography, geography); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_coveredby(geography, geography) IS 'args: geogA, geogB - Returns 1 (TRUE) if no point in Geometry/Geography A is outside Geometry/Geography B';


--
-- Name: st_coveredby(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_coveredby(text, text) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$ SELECT ST_CoveredBy($1::geometry, $2::geometry);  $_$;


ALTER FUNCTION public.st_coveredby(text, text) OWNER TO postgres;

--
-- Name: st_covers(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_covers(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && $2 AND _ST_Covers($1,$2)$_$;


ALTER FUNCTION public.st_covers(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_covers(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_covers(geom1 geometry, geom2 geometry) IS 'args: geomA, geomB - Returns 1 (TRUE) if no point in Geometry B is outside Geometry A';


--
-- Name: st_covers(geography, geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_covers(geography, geography) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && $2 AND _ST_Covers($1, $2)$_$;


ALTER FUNCTION public.st_covers(geography, geography) OWNER TO postgres;

--
-- Name: FUNCTION st_covers(geography, geography); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_covers(geography, geography) IS 'args: geogpolyA, geogpointB - Returns 1 (TRUE) if no point in Geometry B is outside Geometry A';


--
-- Name: st_covers(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_covers(text, text) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$ SELECT ST_Covers($1::geometry, $2::geometry);  $_$;


ALTER FUNCTION public.st_covers(text, text) OWNER TO postgres;

--
-- Name: st_crosses(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_crosses(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && $2 AND _ST_Crosses($1,$2)$_$;


ALTER FUNCTION public.st_crosses(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_crosses(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_crosses(geom1 geometry, geom2 geometry) IS 'args: g1, g2 - Returns TRUE if the supplied geometries have some, but not all, interior points in common.';


--
-- Name: st_curvetoline(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_curvetoline(geometry) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_CurveToLine($1, 32)$_$;


ALTER FUNCTION public.st_curvetoline(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_curvetoline(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_curvetoline(geometry) IS 'args: curveGeom - Converts a CIRCULARSTRING/CURVEDPOLYGON to a LINESTRING/POLYGON';


--
-- Name: st_curvetoline(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_curvetoline(geometry, integer) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_curve_segmentize';


ALTER FUNCTION public.st_curvetoline(geometry, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_curvetoline(geometry, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_curvetoline(geometry, integer) IS 'args: curveGeom, segments_per_qtr_circle - Converts a CIRCULARSTRING/CURVEDPOLYGON to a LINESTRING/POLYGON';


--
-- Name: st_dfullywithin(geometry, geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_dfullywithin(geom1 geometry, geom2 geometry, double precision) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && ST_Expand($2,$3) AND $2 && ST_Expand($1,$3) AND _ST_DFullyWithin(ST_ConvexHull($1), ST_ConvexHull($2), $3)$_$;


ALTER FUNCTION public.st_dfullywithin(geom1 geometry, geom2 geometry, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_dfullywithin(geom1 geometry, geom2 geometry, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_dfullywithin(geom1 geometry, geom2 geometry, double precision) IS 'args: g1, g2, distance - Returns true if all of the geometries are within the specified distance of one another';


--
-- Name: st_difference(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_difference(geom1 geometry, geom2 geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'difference';


ALTER FUNCTION public.st_difference(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_difference(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_difference(geom1 geometry, geom2 geometry) IS 'args: geomA, geomB - Returns a geometry that represents that part of geometry A that does not intersect with geometry B.';


--
-- Name: st_dimension(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_dimension(geometry) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_dimension';


ALTER FUNCTION public.st_dimension(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_dimension(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_dimension(geometry) IS 'args: g - The inherent dimension of this Geometry object, which must be less than or equal to the coordinate dimension.';


--
-- Name: st_disjoint(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_disjoint(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'disjoint';


ALTER FUNCTION public.st_disjoint(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_disjoint(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_disjoint(geom1 geometry, geom2 geometry) IS 'args: A, B - Returns TRUE if the Geometries do not "spatially intersect" - if they do not share any space together.';


--
-- Name: st_distance(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_distance(geom1 geometry, geom2 geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'LWGEOM_mindistance2d';


ALTER FUNCTION public.st_distance(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_distance(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_distance(geom1 geometry, geom2 geometry) IS 'args: g1, g2 - For geometry type Returns the 2-dimensional cartesian minimum distance (based on spatial ref) between two geometries in projected units. For geography type defaults to return spheroidal minimum distance between two geographies in meters.';


--
-- Name: st_distance(geography, geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_distance(geography, geography) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT _ST_Distance($1, $2, 0.0, true)$_$;


ALTER FUNCTION public.st_distance(geography, geography) OWNER TO postgres;

--
-- Name: FUNCTION st_distance(geography, geography); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_distance(geography, geography) IS 'args: gg1, gg2 - For geometry type Returns the 2-dimensional cartesian minimum distance (based on spatial ref) between two geometries in projected units. For geography type defaults to return spheroidal minimum distance between two geographies in meters.';


--
-- Name: st_distance(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_distance(text, text) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT ST_Distance($1::geometry, $2::geometry);  $_$;


ALTER FUNCTION public.st_distance(text, text) OWNER TO postgres;

--
-- Name: st_distance(geography, geography, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_distance(geography, geography, boolean) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT _ST_Distance($1, $2, 0.0, $3)$_$;


ALTER FUNCTION public.st_distance(geography, geography, boolean) OWNER TO postgres;

--
-- Name: FUNCTION st_distance(geography, geography, boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_distance(geography, geography, boolean) IS 'args: gg1, gg2, use_spheroid - For geometry type Returns the 2-dimensional cartesian minimum distance (based on spatial ref) between two geometries in projected units. For geography type defaults to return spheroidal minimum distance between two geographies in meters.';


--
-- Name: st_distance_sphere(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_distance_sphere(geom1 geometry, geom2 geometry) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT COST 300
    AS $_$
	select st_distance(geography($1),geography($2),false)
	$_$;


ALTER FUNCTION public.st_distance_sphere(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_distance_sphere(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_distance_sphere(geom1 geometry, geom2 geometry) IS 'args: geomlonlatA, geomlonlatB - Returns minimum distance in meters between two lon/lat geometries. Uses a spherical earth and radius of 6370986 meters. Faster than ST_Distance_Spheroid , but less accurate. PostGIS versions prior to 1.5 only implemented for points.';


--
-- Name: st_distance_spheroid(geometry, geometry, spheroid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_distance_spheroid(geom1 geometry, geom2 geometry, spheroid) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'LWGEOM_distance_ellipsoid';


ALTER FUNCTION public.st_distance_spheroid(geom1 geometry, geom2 geometry, spheroid) OWNER TO postgres;

--
-- Name: FUNCTION st_distance_spheroid(geom1 geometry, geom2 geometry, spheroid); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_distance_spheroid(geom1 geometry, geom2 geometry, spheroid) IS 'args: geomlonlatA, geomlonlatB, measurement_spheroid - Returns the minimum distance between two lon/lat geometries given a particular spheroid. PostGIS versions prior to 1.5 only support points.';


--
-- Name: st_dump(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_dump(geometry) RETURNS SETOF geometry_dump
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_dump';


ALTER FUNCTION public.st_dump(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_dump(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_dump(geometry) IS 'args: g1 - Returns a set of geometry_dump (geom,path) rows, that make up a geometry g1.';


--
-- Name: st_dumppoints(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_dumppoints(geometry) RETURNS SETOF geometry_dump
    LANGUAGE sql STRICT
    AS $_$
  SELECT * FROM _ST_DumpPoints($1, NULL);
$_$;


ALTER FUNCTION public.st_dumppoints(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_dumppoints(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_dumppoints(geometry) IS 'args: geom - Returns a set of geometry_dump (geom,path) rows of all points that make up a geometry.';


--
-- Name: st_dumprings(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_dumprings(geometry) RETURNS SETOF geometry_dump
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_dump_rings';


ALTER FUNCTION public.st_dumprings(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_dumprings(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_dumprings(geometry) IS 'args: a_polygon - Returns a set of geometry_dump rows, representing the exterior and interior rings of a polygon.';


--
-- Name: st_dwithin(geometry, geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_dwithin(geom1 geometry, geom2 geometry, double precision) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && ST_Expand($2,$3) AND $2 && ST_Expand($1,$3) AND _ST_DWithin($1, $2, $3)$_$;


ALTER FUNCTION public.st_dwithin(geom1 geometry, geom2 geometry, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_dwithin(geom1 geometry, geom2 geometry, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_dwithin(geom1 geometry, geom2 geometry, double precision) IS 'args: g1, g2, distance_of_srid - Returns true if the geometries are within the specified distance of one another. For geometry units are in those of spatial reference and For geography units are in meters and measurement is defaulted to use_spheroid=true (measure around spheroid), for faster check, use_spheroid=false to measure along sphere.';


--
-- Name: st_dwithin(geography, geography, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_dwithin(geography, geography, double precision) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && _ST_Expand($2,$3) AND $2 && _ST_Expand($1,$3) AND _ST_DWithin($1, $2, $3, true)$_$;


ALTER FUNCTION public.st_dwithin(geography, geography, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_dwithin(geography, geography, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_dwithin(geography, geography, double precision) IS 'args: gg1, gg2, distance_meters - Returns true if the geometries are within the specified distance of one another. For geometry units are in those of spatial reference and For geography units are in meters and measurement is defaulted to use_spheroid=true (measure around spheroid), for faster check, use_spheroid=false to measure along sphere.';


--
-- Name: st_dwithin(text, text, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_dwithin(text, text, double precision) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$ SELECT ST_DWithin($1::geometry, $2::geometry, $3);  $_$;


ALTER FUNCTION public.st_dwithin(text, text, double precision) OWNER TO postgres;

--
-- Name: st_dwithin(geography, geography, double precision, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_dwithin(geography, geography, double precision, boolean) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && _ST_Expand($2,$3) AND $2 && _ST_Expand($1,$3) AND _ST_DWithin($1, $2, $3, $4)$_$;


ALTER FUNCTION public.st_dwithin(geography, geography, double precision, boolean) OWNER TO postgres;

--
-- Name: FUNCTION st_dwithin(geography, geography, double precision, boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_dwithin(geography, geography, double precision, boolean) IS 'args: gg1, gg2, distance_meters, use_spheroid - Returns true if the geometries are within the specified distance of one another. For geometry units are in those of spatial reference and For geography units are in meters and measurement is defaulted to use_spheroid=true (measure around spheroid), for faster check, use_spheroid=false to measure along sphere.';


--
-- Name: st_endpoint(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_endpoint(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_endpoint_linestring';


ALTER FUNCTION public.st_endpoint(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_endpoint(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_endpoint(geometry) IS 'args: g - Returns the last point of a LINESTRING geometry as a POINT.';


--
-- Name: st_envelope(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_envelope(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_envelope';


ALTER FUNCTION public.st_envelope(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_envelope(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_envelope(geometry) IS 'args: g1 - Returns a geometry representing the double precision (float8) bounding box of the supplied geometry.';


--
-- Name: st_equals(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_equals(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 ~= $2 AND _ST_Equals($1,$2)$_$;


ALTER FUNCTION public.st_equals(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_equals(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_equals(geom1 geometry, geom2 geometry) IS 'args: A, B - Returns true if the given geometries represent the same geometry. Directionality is ignored.';


--
-- Name: st_estimated_extent(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_estimated_extent(text, text) RETURNS box2d
    LANGUAGE c IMMUTABLE STRICT SECURITY DEFINER
    AS '$libdir/postgis-2.0', 'geometry_estimated_extent';


ALTER FUNCTION public.st_estimated_extent(text, text) OWNER TO postgres;

--
-- Name: FUNCTION st_estimated_extent(text, text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_estimated_extent(text, text) IS 'args: table_name, geocolumn_name - Return the estimated extent of the given spatial table. The estimated is taken from the geometry columns statistics. The current schema will be used if not specified.';


--
-- Name: st_estimated_extent(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_estimated_extent(text, text, text) RETURNS box2d
    LANGUAGE c IMMUTABLE STRICT SECURITY DEFINER
    AS '$libdir/postgis-2.0', 'geometry_estimated_extent';


ALTER FUNCTION public.st_estimated_extent(text, text, text) OWNER TO postgres;

--
-- Name: FUNCTION st_estimated_extent(text, text, text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_estimated_extent(text, text, text) IS 'args: schema_name, table_name, geocolumn_name - Return the estimated extent of the given spatial table. The estimated is taken from the geometry columns statistics. The current schema will be used if not specified.';


--
-- Name: st_expand(box2d, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_expand(box2d, double precision) RETURNS box2d
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX2D_expand';


ALTER FUNCTION public.st_expand(box2d, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_expand(box2d, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_expand(box2d, double precision) IS 'args: g1, units_to_expand - Returns bounding box expanded in all directions from the bounding box of the input geometry. Uses double-precision';


--
-- Name: st_expand(box3d, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_expand(box3d, double precision) RETURNS box3d
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX3D_expand';


ALTER FUNCTION public.st_expand(box3d, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_expand(box3d, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_expand(box3d, double precision) IS 'args: g1, units_to_expand - Returns bounding box expanded in all directions from the bounding box of the input geometry. Uses double-precision';


--
-- Name: st_expand(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_expand(geometry, double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_expand';


ALTER FUNCTION public.st_expand(geometry, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_expand(geometry, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_expand(geometry, double precision) IS 'args: g1, units_to_expand - Returns bounding box expanded in all directions from the bounding box of the input geometry. Uses double-precision';


--
-- Name: st_exteriorring(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_exteriorring(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_exteriorring_polygon';


ALTER FUNCTION public.st_exteriorring(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_exteriorring(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_exteriorring(geometry) IS 'args: a_polygon - Returns a line string representing the exterior ring of the POLYGON geometry. Return NULL if the geometry is not a polygon. Will not work with MULTIPOLYGON';


--
-- Name: st_find_extent(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_find_extent(text, text) RETURNS box2d
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $_$
DECLARE
	tablename alias for $1;
	columnname alias for $2;
	myrec RECORD;

BEGIN
	FOR myrec IN EXECUTE 'SELECT ST_Extent("' || columnname || '") As extent FROM "' || tablename || '"' LOOP
		return myrec.extent;
	END LOOP;
END;
$_$;


ALTER FUNCTION public.st_find_extent(text, text) OWNER TO postgres;

--
-- Name: st_find_extent(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_find_extent(text, text, text) RETURNS box2d
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $_$
DECLARE
	schemaname alias for $1;
	tablename alias for $2;
	columnname alias for $3;
	myrec RECORD;

BEGIN
	FOR myrec IN EXECUTE 'SELECT ST_Extent("' || columnname || '") As extent FROM "' || schemaname || '"."' || tablename || '"' LOOP
		return myrec.extent;
	END LOOP;
END;
$_$;


ALTER FUNCTION public.st_find_extent(text, text, text) OWNER TO postgres;

--
-- Name: st_flipcoordinates(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_flipcoordinates(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'ST_FlipCoordinates';


ALTER FUNCTION public.st_flipcoordinates(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_flipcoordinates(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_flipcoordinates(geometry) IS 'args: geom - Returns a version of the given geometry with X and Y axis flipped. Useful for people who have built latitude/longitude features and need to fix them.';


--
-- Name: st_force_2d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_force_2d(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_force_2d';


ALTER FUNCTION public.st_force_2d(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_force_2d(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_force_2d(geometry) IS 'args: geomA - Forces the geometries into a "2-dimensional mode" so that all output representations will only have the X and Y coordinates.';


--
-- Name: st_force_3d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_force_3d(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_force_3dz';


ALTER FUNCTION public.st_force_3d(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_force_3d(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_force_3d(geometry) IS 'args: geomA - Forces the geometries into XYZ mode. This is an alias for ST_Force_3DZ.';


--
-- Name: st_force_3dm(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_force_3dm(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_force_3dm';


ALTER FUNCTION public.st_force_3dm(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_force_3dm(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_force_3dm(geometry) IS 'args: geomA - Forces the geometries into XYM mode.';


--
-- Name: st_force_3dz(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_force_3dz(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_force_3dz';


ALTER FUNCTION public.st_force_3dz(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_force_3dz(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_force_3dz(geometry) IS 'args: geomA - Forces the geometries into XYZ mode. This is a synonym for ST_Force_3D.';


--
-- Name: st_force_4d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_force_4d(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_force_4d';


ALTER FUNCTION public.st_force_4d(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_force_4d(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_force_4d(geometry) IS 'args: geomA - Forces the geometries into XYZM mode.';


--
-- Name: st_force_collection(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_force_collection(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_force_collection';


ALTER FUNCTION public.st_force_collection(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_force_collection(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_force_collection(geometry) IS 'args: geomA - Converts the geometry into a GEOMETRYCOLLECTION.';


--
-- Name: st_forcerhr(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_forcerhr(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_force_clockwise_poly';


ALTER FUNCTION public.st_forcerhr(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_forcerhr(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_forcerhr(geometry) IS 'args: g - Forces the orientation of the vertices in a polygon to follow the Right-Hand-Rule.';


--
-- Name: st_geogfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geogfromtext(text) RETURNS geography
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_from_text';


ALTER FUNCTION public.st_geogfromtext(text) OWNER TO postgres;

--
-- Name: FUNCTION st_geogfromtext(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geogfromtext(text) IS 'args: EWKT - Return a specified geography value from Well-Known Text representation or extended (WKT).';


--
-- Name: st_geogfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geogfromwkb(bytea) RETURNS geography
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_from_binary';


ALTER FUNCTION public.st_geogfromwkb(bytea) OWNER TO postgres;

--
-- Name: FUNCTION st_geogfromwkb(bytea); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geogfromwkb(bytea) IS 'args: geom - Creates a geography instance from a Well-Known Binary geometry representation (WKB) or extended Well Known Binary (EWKB).';


--
-- Name: st_geographyfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geographyfromtext(text) RETURNS geography
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geography_from_text';


ALTER FUNCTION public.st_geographyfromtext(text) OWNER TO postgres;

--
-- Name: FUNCTION st_geographyfromtext(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geographyfromtext(text) IS 'args: EWKT - Return a specified geography value from Well-Known Text representation or extended (WKT).';


--
-- Name: st_geohash(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geohash(geom geometry, maxchars integer DEFAULT 0) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'ST_GeoHash';


ALTER FUNCTION public.st_geohash(geom geometry, maxchars integer) OWNER TO postgres;

--
-- Name: FUNCTION st_geohash(geom geometry, maxchars integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geohash(geom geometry, maxchars integer) IS 'args: geom, maxchars=full_precision_of_point - Return a GeoHash representation (geohash.org) of the geometry.';


--
-- Name: st_geomcollfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomcollfromtext(text) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE
	WHEN geometrytype(ST_GeomFromText($1)) = 'GEOMETRYCOLLECTION'
	THEN ST_GeomFromText($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_geomcollfromtext(text) OWNER TO postgres;

--
-- Name: FUNCTION st_geomcollfromtext(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geomcollfromtext(text) IS 'args: WKT - Makes a collection Geometry from collection WKT with the given SRID. If SRID is not give, it defaults to -1.';


--
-- Name: st_geomcollfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomcollfromtext(text, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE
	WHEN geometrytype(ST_GeomFromText($1, $2)) = 'GEOMETRYCOLLECTION'
	THEN ST_GeomFromText($1,$2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_geomcollfromtext(text, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_geomcollfromtext(text, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geomcollfromtext(text, integer) IS 'args: WKT, srid - Makes a collection Geometry from collection WKT with the given SRID. If SRID is not give, it defaults to -1.';


--
-- Name: st_geomcollfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomcollfromwkb(bytea) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE
	WHEN geometrytype(ST_GeomFromWKB($1)) = 'GEOMETRYCOLLECTION'
	THEN ST_GeomFromWKB($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_geomcollfromwkb(bytea) OWNER TO postgres;

--
-- Name: st_geomcollfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomcollfromwkb(bytea, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE
	WHEN geometrytype(ST_GeomFromWKB($1, $2)) = 'GEOMETRYCOLLECTION'
	THEN ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_geomcollfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_geometryfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometryfromtext(text) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_from_text';


ALTER FUNCTION public.st_geometryfromtext(text) OWNER TO postgres;

--
-- Name: FUNCTION st_geometryfromtext(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geometryfromtext(text) IS 'args: WKT - Return a specified ST_Geometry value from Well-Known Text representation (WKT). This is an alias name for ST_GeomFromText';


--
-- Name: st_geometryfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometryfromtext(text, integer) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_from_text';


ALTER FUNCTION public.st_geometryfromtext(text, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_geometryfromtext(text, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geometryfromtext(text, integer) IS 'args: WKT, srid - Return a specified ST_Geometry value from Well-Known Text representation (WKT). This is an alias name for ST_GeomFromText';


--
-- Name: st_geometryn(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometryn(geometry, integer) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_geometryn_collection';


ALTER FUNCTION public.st_geometryn(geometry, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_geometryn(geometry, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geometryn(geometry, integer) IS 'args: geomA, n - Return the 1-based Nth geometry if the geometry is a GEOMETRYCOLLECTION, (MULTI)POINT, (MULTI)LINESTRING, MULTICURVE or (MULTI)POLYGON, POLYHEDRALSURFACE Otherwise, return NULL.';


--
-- Name: st_geometrytype(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometrytype(geometry) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geometry_geometrytype';


ALTER FUNCTION public.st_geometrytype(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_geometrytype(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geometrytype(geometry) IS 'args: g1 - Return the geometry type of the ST_Geometry value.';


--
-- Name: st_geomfromewkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomfromewkb(bytea) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOMFromWKB';


ALTER FUNCTION public.st_geomfromewkb(bytea) OWNER TO postgres;

--
-- Name: FUNCTION st_geomfromewkb(bytea); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geomfromewkb(bytea) IS 'args: EWKB - Return a specified ST_Geometry value from Extended Well-Known Binary representation (EWKB).';


--
-- Name: st_geomfromewkt(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomfromewkt(text) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'parse_WKT_lwgeom';


ALTER FUNCTION public.st_geomfromewkt(text) OWNER TO postgres;

--
-- Name: FUNCTION st_geomfromewkt(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geomfromewkt(text) IS 'args: EWKT - Return a specified ST_Geometry value from Extended Well-Known Text representation (EWKT).';


--
-- Name: st_geomfromgeojson(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomfromgeojson(text) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geom_from_geojson';


ALTER FUNCTION public.st_geomfromgeojson(text) OWNER TO postgres;

--
-- Name: FUNCTION st_geomfromgeojson(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geomfromgeojson(text) IS 'args: geomjson - Takes as input a geojson representation of a geometry and outputs a PostGIS geometry object';


--
-- Name: st_geomfromgml(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomfromgml(text) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT _ST_GeomFromGML($1, 0)$_$;


ALTER FUNCTION public.st_geomfromgml(text) OWNER TO postgres;

--
-- Name: FUNCTION st_geomfromgml(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geomfromgml(text) IS 'args: geomgml - Takes as input GML representation of geometry and outputs a PostGIS geometry object';


--
-- Name: st_geomfromgml(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomfromgml(text, integer) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geom_from_gml';


ALTER FUNCTION public.st_geomfromgml(text, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_geomfromgml(text, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geomfromgml(text, integer) IS 'args: geomgml, srid - Takes as input GML representation of geometry and outputs a PostGIS geometry object';


--
-- Name: st_geomfromkml(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomfromkml(text) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geom_from_kml';


ALTER FUNCTION public.st_geomfromkml(text) OWNER TO postgres;

--
-- Name: FUNCTION st_geomfromkml(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geomfromkml(text) IS 'args: geomkml - Takes as input KML representation of geometry and outputs a PostGIS geometry object';


--
-- Name: st_geomfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomfromtext(text) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_from_text';


ALTER FUNCTION public.st_geomfromtext(text) OWNER TO postgres;

--
-- Name: FUNCTION st_geomfromtext(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geomfromtext(text) IS 'args: WKT - Return a specified ST_Geometry value from Well-Known Text representation (WKT).';


--
-- Name: st_geomfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomfromtext(text, integer) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_from_text';


ALTER FUNCTION public.st_geomfromtext(text, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_geomfromtext(text, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geomfromtext(text, integer) IS 'args: WKT, srid - Return a specified ST_Geometry value from Well-Known Text representation (WKT).';


--
-- Name: st_geomfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomfromwkb(bytea) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_from_WKB';


ALTER FUNCTION public.st_geomfromwkb(bytea) OWNER TO postgres;

--
-- Name: FUNCTION st_geomfromwkb(bytea); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geomfromwkb(bytea) IS 'args: geom - Makes a geometry from WKB with the given SRID';


--
-- Name: st_geomfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomfromwkb(bytea, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_SetSRID(ST_GeomFromWKB($1), $2)$_$;


ALTER FUNCTION public.st_geomfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_geomfromwkb(bytea, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_geomfromwkb(bytea, integer) IS 'args: geom, srid - Makes a geometry from WKB with the given SRID';


--
-- Name: st_gmltosql(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_gmltosql(text) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT _ST_GeomFromGML($1, 0)$_$;


ALTER FUNCTION public.st_gmltosql(text) OWNER TO postgres;

--
-- Name: FUNCTION st_gmltosql(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_gmltosql(text) IS 'args: geomgml - Return a specified ST_Geometry value from GML representation. This is an alias name for ST_GeomFromGML';


--
-- Name: st_gmltosql(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_gmltosql(text, integer) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geom_from_gml';


ALTER FUNCTION public.st_gmltosql(text, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_gmltosql(text, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_gmltosql(text, integer) IS 'args: geomgml, srid - Return a specified ST_Geometry value from GML representation. This is an alias name for ST_GeomFromGML';


--
-- Name: st_hasarc(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_hasarc(geometry geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_has_arc';


ALTER FUNCTION public.st_hasarc(geometry geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_hasarc(geometry geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_hasarc(geometry geometry) IS 'args: geomA - Returns true if a geometry or geometry collection contains a circular string';


--
-- Name: st_hausdorffdistance(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_hausdorffdistance(geom1 geometry, geom2 geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'hausdorffdistance';


ALTER FUNCTION public.st_hausdorffdistance(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_hausdorffdistance(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_hausdorffdistance(geom1 geometry, geom2 geometry) IS 'args: g1, g2 - Returns the Hausdorff distance between two geometries. Basically a measure of how similar or dissimilar 2 geometries are. Units are in the units of the spatial reference system of the geometries.';


--
-- Name: st_hausdorffdistance(geometry, geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_hausdorffdistance(geom1 geometry, geom2 geometry, double precision) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'hausdorffdistancedensify';


ALTER FUNCTION public.st_hausdorffdistance(geom1 geometry, geom2 geometry, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_hausdorffdistance(geom1 geometry, geom2 geometry, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_hausdorffdistance(geom1 geometry, geom2 geometry, double precision) IS 'args: g1, g2, densifyFrac - Returns the Hausdorff distance between two geometries. Basically a measure of how similar or dissimilar 2 geometries are. Units are in the units of the spatial reference system of the geometries.';


--
-- Name: st_interiorringn(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_interiorringn(geometry, integer) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_interiorringn_polygon';


ALTER FUNCTION public.st_interiorringn(geometry, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_interiorringn(geometry, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_interiorringn(geometry, integer) IS 'args: a_polygon, n - Return the Nth interior linestring ring of the polygon geometry. Return NULL if the geometry is not a polygon or the given N is out of range.';


--
-- Name: st_interpolatepoint(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_interpolatepoint(line geometry, point geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'ST_InterpolatePoint';


ALTER FUNCTION public.st_interpolatepoint(line geometry, point geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_interpolatepoint(line geometry, point geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_interpolatepoint(line geometry, point geometry) IS 'args: line, point - Return the value of the measure dimension of a geometry at the point closed to the provided point.';


--
-- Name: st_intersection(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_intersection(geom1 geometry, geom2 geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'intersection';


ALTER FUNCTION public.st_intersection(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_intersection(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_intersection(geom1 geometry, geom2 geometry) IS 'args: geomA, geomB - (T) Returns a geometry that represents the shared portion of geomA and geomB. The geography implementation does a transform to geometry to do the intersection and then transform back to WGS84.';


--
-- Name: st_intersection(geography, geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_intersection(geography, geography) RETURNS geography
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT geography(ST_Transform(ST_Intersection(ST_Transform(geometry($1), _ST_BestSRID($1, $2)), ST_Transform(geometry($2), _ST_BestSRID($1, $2))), 4326))$_$;


ALTER FUNCTION public.st_intersection(geography, geography) OWNER TO postgres;

--
-- Name: FUNCTION st_intersection(geography, geography); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_intersection(geography, geography) IS 'args: geogA, geogB - (T) Returns a geometry that represents the shared portion of geomA and geomB. The geography implementation does a transform to geometry to do the intersection and then transform back to WGS84.';


--
-- Name: st_intersection(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_intersection(text, text) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT ST_Intersection($1::geometry, $2::geometry);  $_$;


ALTER FUNCTION public.st_intersection(text, text) OWNER TO postgres;

--
-- Name: st_intersects(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_intersects(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && $2 AND _ST_Intersects($1,$2)$_$;


ALTER FUNCTION public.st_intersects(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_intersects(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_intersects(geom1 geometry, geom2 geometry) IS 'args: geomA, geomB - Returns TRUE if the Geometries/Geography "spatially intersect in 2D" - (share any portion of space) and FALSE if they dont (they are Disjoint). For geography -- tolerance is 0.00001 meters (so any points that close are considered to intersect)';


--
-- Name: st_intersects(geography, geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_intersects(geography, geography) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && $2 AND _ST_Distance($1, $2, 0.0, false) < 0.00001$_$;


ALTER FUNCTION public.st_intersects(geography, geography) OWNER TO postgres;

--
-- Name: FUNCTION st_intersects(geography, geography); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_intersects(geography, geography) IS 'args: geogA, geogB - Returns TRUE if the Geometries/Geography "spatially intersect in 2D" - (share any portion of space) and FALSE if they dont (they are Disjoint). For geography -- tolerance is 0.00001 meters (so any points that close are considered to intersect)';


--
-- Name: st_intersects(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_intersects(text, text) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$ SELECT ST_Intersects($1::geometry, $2::geometry);  $_$;


ALTER FUNCTION public.st_intersects(text, text) OWNER TO postgres;

--
-- Name: st_isclosed(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_isclosed(geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_isclosed';


ALTER FUNCTION public.st_isclosed(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_isclosed(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_isclosed(geometry) IS 'args: g - Returns TRUE if the LINESTRINGs start and end points are coincident. For Polyhedral surface is closed (volumetric).';


--
-- Name: st_iscollection(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_iscollection(geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'ST_IsCollection';


ALTER FUNCTION public.st_iscollection(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_iscollection(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_iscollection(geometry) IS 'args: g - Returns TRUE if the argument is a collection (MULTI*, GEOMETRYCOLLECTION, ...)';


--
-- Name: st_isempty(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_isempty(geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_isempty';


ALTER FUNCTION public.st_isempty(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_isempty(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_isempty(geometry) IS 'args: geomA - Returns true if this Geometry is an empty geometrycollection, polygon, point etc.';


--
-- Name: st_isring(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_isring(geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'isring';


ALTER FUNCTION public.st_isring(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_isring(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_isring(geometry) IS 'args: g - Returns TRUE if this LINESTRING is both closed and simple.';


--
-- Name: st_issimple(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_issimple(geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'issimple';


ALTER FUNCTION public.st_issimple(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_issimple(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_issimple(geometry) IS 'args: geomA - Returns (TRUE) if this Geometry has no anomalous geometric points, such as self intersection or self tangency.';


--
-- Name: st_isvalid(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_isvalid(geometry) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'isvalid';


ALTER FUNCTION public.st_isvalid(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_isvalid(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_isvalid(geometry) IS 'args: g - Returns true if the ST_Geometry is well formed.';


--
-- Name: st_isvalid(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_isvalid(geometry, integer) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT (ST_isValidDetail($1, $2)).valid$_$;


ALTER FUNCTION public.st_isvalid(geometry, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_isvalid(geometry, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_isvalid(geometry, integer) IS 'args: g, flags - Returns true if the ST_Geometry is well formed.';


--
-- Name: st_isvaliddetail(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_isvaliddetail(geometry) RETURNS valid_detail
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'isvaliddetail';


ALTER FUNCTION public.st_isvaliddetail(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_isvaliddetail(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_isvaliddetail(geometry) IS 'args: geom - Returns a valid_detail (valid,reason,location) row stating if a geometry is valid or not and if not valid, a reason why and a location where.';


--
-- Name: st_isvaliddetail(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_isvaliddetail(geometry, integer) RETURNS valid_detail
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'isvaliddetail';


ALTER FUNCTION public.st_isvaliddetail(geometry, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_isvaliddetail(geometry, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_isvaliddetail(geometry, integer) IS 'args: geom, flags - Returns a valid_detail (valid,reason,location) row stating if a geometry is valid or not and if not valid, a reason why and a location where.';


--
-- Name: st_isvalidreason(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_isvalidreason(geometry) RETURNS text
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'isvalidreason';


ALTER FUNCTION public.st_isvalidreason(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_isvalidreason(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_isvalidreason(geometry) IS 'args: geomA - Returns text stating if a geometry is valid or not and if not valid, a reason why.';


--
-- Name: st_isvalidreason(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_isvalidreason(geometry, integer) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
SELECT CASE WHEN valid THEN 'Valid Geometry' ELSE reason END FROM (
	SELECT (ST_isValidDetail($1, $2)).*
) foo
	$_$;


ALTER FUNCTION public.st_isvalidreason(geometry, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_isvalidreason(geometry, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_isvalidreason(geometry, integer) IS 'args: geomA, flags - Returns text stating if a geometry is valid or not and if not valid, a reason why.';


--
-- Name: st_length(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_length(geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_length2d_linestring';


ALTER FUNCTION public.st_length(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_length(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_length(geometry) IS 'args: a_2dlinestring - Returns the 2d length of the geometry if it is a linestring or multilinestring. geometry are in units of spatial reference and geography are in meters (default spheroid)';


--
-- Name: st_length(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_length(text) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT ST_Length($1::geometry);  $_$;


ALTER FUNCTION public.st_length(text) OWNER TO postgres;

--
-- Name: st_length(geography, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_length(geog geography, use_spheroid boolean DEFAULT true) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'geography_length';


ALTER FUNCTION public.st_length(geog geography, use_spheroid boolean) OWNER TO postgres;

--
-- Name: FUNCTION st_length(geog geography, use_spheroid boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_length(geog geography, use_spheroid boolean) IS 'args: geog, use_spheroid=true - Returns the 2d length of the geometry if it is a linestring or multilinestring. geometry are in units of spatial reference and geography are in meters (default spheroid)';


--
-- Name: st_length2d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_length2d(geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_length2d_linestring';


ALTER FUNCTION public.st_length2d(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_length2d(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_length2d(geometry) IS 'args: a_2dlinestring - Returns the 2-dimensional length of the geometry if it is a linestring or multi-linestring. This is an alias for ST_Length';


--
-- Name: st_length2d_spheroid(geometry, spheroid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_length2d_spheroid(geometry, spheroid) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'LWGEOM_length2d_ellipsoid';


ALTER FUNCTION public.st_length2d_spheroid(geometry, spheroid) OWNER TO postgres;

--
-- Name: FUNCTION st_length2d_spheroid(geometry, spheroid); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_length2d_spheroid(geometry, spheroid) IS 'args: a_linestring, a_spheroid - Calculates the 2D length of a linestring/multilinestring on an ellipsoid. This is useful if the coordinates of the geometry are in longitude/latitude and a length is desired without reprojection.';


--
-- Name: st_length_spheroid(geometry, spheroid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_length_spheroid(geometry, spheroid) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'LWGEOM_length_ellipsoid_linestring';


ALTER FUNCTION public.st_length_spheroid(geometry, spheroid) OWNER TO postgres;

--
-- Name: FUNCTION st_length_spheroid(geometry, spheroid); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_length_spheroid(geometry, spheroid) IS 'args: a_linestring, a_spheroid - Calculates the 2D or 3D length of a linestring/multilinestring on an ellipsoid. This is useful if the coordinates of the geometry are in longitude/latitude and a length is desired without reprojection.';


--
-- Name: st_line_interpolate_point(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_line_interpolate_point(geometry, double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_line_interpolate_point';


ALTER FUNCTION public.st_line_interpolate_point(geometry, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_line_interpolate_point(geometry, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_line_interpolate_point(geometry, double precision) IS 'args: a_linestring, a_fraction - Returns a point interpolated along a line. Second argument is a float8 between 0 and 1 representing fraction of total length of linestring the point has to be located.';


--
-- Name: st_line_locate_point(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_line_locate_point(geom1 geometry, geom2 geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_line_locate_point';


ALTER FUNCTION public.st_line_locate_point(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_line_locate_point(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_line_locate_point(geom1 geometry, geom2 geometry) IS 'args: a_linestring, a_point - Returns a float between 0 and 1 representing the location of the closest point on LineString to the given Point, as a fraction of total 2d line length.';


--
-- Name: st_line_substring(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_line_substring(geometry, double precision, double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_line_substring';


ALTER FUNCTION public.st_line_substring(geometry, double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_line_substring(geometry, double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_line_substring(geometry, double precision, double precision) IS 'args: a_linestring, startfraction, endfraction - Return a linestring being a substring of the input one starting and ending at the given fractions of total 2d length. Second and third arguments are float8 values between 0 and 1.';


--
-- Name: st_linecrossingdirection(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linecrossingdirection(geom1 geometry, geom2 geometry) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $_$ SELECT CASE WHEN NOT $1 && $2 THEN 0 ELSE _ST_LineCrossingDirection($1,$2) END $_$;


ALTER FUNCTION public.st_linecrossingdirection(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_linecrossingdirection(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_linecrossingdirection(geom1 geometry, geom2 geometry) IS 'args: linestringA, linestringB - Given 2 linestrings, returns a number between -3 and 3 denoting what kind of crossing behavior. 0 is no crossing.';


--
-- Name: st_linefrommultipoint(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linefrommultipoint(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_line_from_mpoint';


ALTER FUNCTION public.st_linefrommultipoint(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_linefrommultipoint(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_linefrommultipoint(geometry) IS 'args: aMultiPoint - Creates a LineString from a MultiPoint geometry.';


--
-- Name: st_linefromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linefromtext(text) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromText($1)) = 'LINESTRING'
	THEN ST_GeomFromText($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_linefromtext(text) OWNER TO postgres;

--
-- Name: FUNCTION st_linefromtext(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_linefromtext(text) IS 'args: WKT - Makes a Geometry from WKT representation with the given SRID. If SRID is not given, it defaults to -1.';


--
-- Name: st_linefromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linefromtext(text, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromText($1, $2)) = 'LINESTRING'
	THEN ST_GeomFromText($1,$2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_linefromtext(text, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_linefromtext(text, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_linefromtext(text, integer) IS 'args: WKT, srid - Makes a Geometry from WKT representation with the given SRID. If SRID is not given, it defaults to -1.';


--
-- Name: st_linefromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linefromwkb(bytea) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1)) = 'LINESTRING'
	THEN ST_GeomFromWKB($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_linefromwkb(bytea) OWNER TO postgres;

--
-- Name: FUNCTION st_linefromwkb(bytea); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_linefromwkb(bytea) IS 'args: WKB - Makes a LINESTRING from WKB with the given SRID';


--
-- Name: st_linefromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linefromwkb(bytea, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1, $2)) = 'LINESTRING'
	THEN ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_linefromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_linefromwkb(bytea, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_linefromwkb(bytea, integer) IS 'args: WKB, srid - Makes a LINESTRING from WKB with the given SRID';


--
-- Name: st_linemerge(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linemerge(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'linemerge';


ALTER FUNCTION public.st_linemerge(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_linemerge(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_linemerge(geometry) IS 'args: amultilinestring - Returns a (set of) LineString(s) formed by sewing together a MULTILINESTRING.';


--
-- Name: st_linestringfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linestringfromwkb(bytea) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1)) = 'LINESTRING'
	THEN ST_GeomFromWKB($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_linestringfromwkb(bytea) OWNER TO postgres;

--
-- Name: FUNCTION st_linestringfromwkb(bytea); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_linestringfromwkb(bytea) IS 'args: WKB - Makes a geometry from WKB with the given SRID.';


--
-- Name: st_linestringfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linestringfromwkb(bytea, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1, $2)) = 'LINESTRING'
	THEN ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_linestringfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_linestringfromwkb(bytea, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_linestringfromwkb(bytea, integer) IS 'args: WKB, srid - Makes a geometry from WKB with the given SRID.';


--
-- Name: st_linetocurve(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linetocurve(geometry geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_line_desegmentize';


ALTER FUNCTION public.st_linetocurve(geometry geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_linetocurve(geometry geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_linetocurve(geometry geometry) IS 'args: geomANoncircular - Converts a LINESTRING/POLYGON to a CIRCULARSTRING, CURVED POLYGON';


--
-- Name: st_locate_along_measure(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_locate_along_measure(geometry, double precision) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ SELECT ST_locate_between_measures($1, $2, $2) $_$;


ALTER FUNCTION public.st_locate_along_measure(geometry, double precision) OWNER TO postgres;

--
-- Name: st_locate_between_measures(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_locate_between_measures(geometry, double precision, double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_locate_between_m';


ALTER FUNCTION public.st_locate_between_measures(geometry, double precision, double precision) OWNER TO postgres;

--
-- Name: st_locatealong(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_locatealong(geometry geometry, measure double precision, leftrightoffset double precision DEFAULT 0.0) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'ST_LocateAlong';


ALTER FUNCTION public.st_locatealong(geometry geometry, measure double precision, leftrightoffset double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_locatealong(geometry geometry, measure double precision, leftrightoffset double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_locatealong(geometry geometry, measure double precision, leftrightoffset double precision) IS 'args: ageom_with_measure, a_measure, offset - Return a derived geometry collection value with elements that match the specified measure. Polygonal elements are not supported.';


--
-- Name: st_locatebetween(geometry, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_locatebetween(geometry geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision DEFAULT 0.0) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'ST_LocateBetween';


ALTER FUNCTION public.st_locatebetween(geometry geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_locatebetween(geometry geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_locatebetween(geometry geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision) IS 'args: geomA, measure_start, measure_end, offset - Return a derived geometry collection value with elements that match the specified range of measures inclusively. Polygonal elements are not supported.';


--
-- Name: st_locatebetweenelevations(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_locatebetweenelevations(geometry geometry, fromelevation double precision, toelevation double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'ST_LocateBetweenElevations';


ALTER FUNCTION public.st_locatebetweenelevations(geometry geometry, fromelevation double precision, toelevation double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_locatebetweenelevations(geometry geometry, fromelevation double precision, toelevation double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_locatebetweenelevations(geometry geometry, fromelevation double precision, toelevation double precision) IS 'args: geom_mline, elevation_start, elevation_end - Return a derived geometry (collection) value with elements that intersect the specified range of elevations inclusively. Only 3D, 4D LINESTRINGS and MULTILINESTRINGS are supported.';


--
-- Name: st_longestline(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_longestline(geom1 geometry, geom2 geometry) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT _ST_LongestLine(ST_ConvexHull($1), ST_ConvexHull($2))$_$;


ALTER FUNCTION public.st_longestline(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_longestline(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_longestline(geom1 geometry, geom2 geometry) IS 'args: g1, g2 - Returns the 2-dimensional longest line points of two geometries. The function will only return the first longest line if more than one, that the function finds. The line returned will always start in g1 and end in g2. The length of the line this function returns will always be the same as st_maxdistance returns for g1 and g2.';


--
-- Name: st_m(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_m(geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_m_point';


ALTER FUNCTION public.st_m(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_m(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_m(geometry) IS 'args: a_point - Return the M coordinate of the point, or NULL if not available. Input must be a point.';


--
-- Name: st_makebox2d(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makebox2d(geom1 geometry, geom2 geometry) RETURNS box2d
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX2D_construct';


ALTER FUNCTION public.st_makebox2d(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_makebox2d(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_makebox2d(geom1 geometry, geom2 geometry) IS 'args: pointLowLeft, pointUpRight - Creates a BOX2D defined by the given point geometries.';


--
-- Name: st_makeenvelope(double precision, double precision, double precision, double precision, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makeenvelope(double precision, double precision, double precision, double precision, integer DEFAULT 0) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'ST_MakeEnvelope';


ALTER FUNCTION public.st_makeenvelope(double precision, double precision, double precision, double precision, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_makeenvelope(double precision, double precision, double precision, double precision, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_makeenvelope(double precision, double precision, double precision, double precision, integer) IS 'args: xmin, ymin, xmax, ymax, srid=unknown - Creates a rectangular Polygon formed from the given minimums and maximums. Input values must be in SRS specified by the SRID.';


--
-- Name: st_makeline(geometry[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makeline(geometry[]) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_makeline_garray';


ALTER FUNCTION public.st_makeline(geometry[]) OWNER TO postgres;

--
-- Name: FUNCTION st_makeline(geometry[]); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_makeline(geometry[]) IS 'args: geoms_array - Creates a Linestring from point or line geometries.';


--
-- Name: st_makeline(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makeline(geom1 geometry, geom2 geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_makeline';


ALTER FUNCTION public.st_makeline(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_makeline(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_makeline(geom1 geometry, geom2 geometry) IS 'args: geom1, geom2 - Creates a Linestring from point or line geometries.';


--
-- Name: st_makepoint(double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makepoint(double precision, double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_makepoint';


ALTER FUNCTION public.st_makepoint(double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_makepoint(double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_makepoint(double precision, double precision) IS 'args: x, y - Creates a 2D,3DZ or 4D point geometry.';


--
-- Name: st_makepoint(double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makepoint(double precision, double precision, double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_makepoint';


ALTER FUNCTION public.st_makepoint(double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_makepoint(double precision, double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_makepoint(double precision, double precision, double precision) IS 'args: x, y, z - Creates a 2D,3DZ or 4D point geometry.';


--
-- Name: st_makepoint(double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makepoint(double precision, double precision, double precision, double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_makepoint';


ALTER FUNCTION public.st_makepoint(double precision, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_makepoint(double precision, double precision, double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_makepoint(double precision, double precision, double precision, double precision) IS 'args: x, y, z, m - Creates a 2D,3DZ or 4D point geometry.';


--
-- Name: st_makepointm(double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makepointm(double precision, double precision, double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_makepoint3dm';


ALTER FUNCTION public.st_makepointm(double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_makepointm(double precision, double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_makepointm(double precision, double precision, double precision) IS 'args: x, y, m - Creates a point geometry with an x y and m coordinate.';


--
-- Name: st_makepolygon(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makepolygon(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_makepoly';


ALTER FUNCTION public.st_makepolygon(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_makepolygon(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_makepolygon(geometry) IS 'args: linestring - Creates a Polygon formed by the given shell. Input geometries must be closed LINESTRINGS.';


--
-- Name: st_makepolygon(geometry, geometry[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makepolygon(geometry, geometry[]) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_makepoly';


ALTER FUNCTION public.st_makepolygon(geometry, geometry[]) OWNER TO postgres;

--
-- Name: FUNCTION st_makepolygon(geometry, geometry[]); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_makepolygon(geometry, geometry[]) IS 'args: outerlinestring, interiorlinestrings - Creates a Polygon formed by the given shell. Input geometries must be closed LINESTRINGS.';


--
-- Name: st_makevalid(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makevalid(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'ST_MakeValid';


ALTER FUNCTION public.st_makevalid(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_makevalid(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_makevalid(geometry) IS 'args: input - Attempts to make an invalid geometry valid w/out loosing vertices.';


--
-- Name: st_maxdistance(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_maxdistance(geom1 geometry, geom2 geometry) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT _ST_MaxDistance(ST_ConvexHull($1), ST_ConvexHull($2))$_$;


ALTER FUNCTION public.st_maxdistance(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_maxdistance(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_maxdistance(geom1 geometry, geom2 geometry) IS 'args: g1, g2 - Returns the 2-dimensional largest distance between two geometries in projected units.';


--
-- Name: st_mem_size(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mem_size(geometry) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_mem_size';


ALTER FUNCTION public.st_mem_size(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_mem_size(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_mem_size(geometry) IS 'args: geomA - Returns the amount of space (in bytes) the geometry takes.';


--
-- Name: st_minimumboundingcircle(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_minimumboundingcircle(inputgeom geometry, segs_per_quarter integer DEFAULT 48) RETURNS geometry
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
	DECLARE
	hull GEOMETRY;
	ring GEOMETRY;
	center GEOMETRY;
	radius DOUBLE PRECISION;
	dist DOUBLE PRECISION;
	d DOUBLE PRECISION;
	idx1 integer;
	idx2 integer;
	l1 GEOMETRY;
	l2 GEOMETRY;
	p1 GEOMETRY;
	p2 GEOMETRY;
	a1 DOUBLE PRECISION;
	a2 DOUBLE PRECISION;


	BEGIN

	-- First compute the ConvexHull of the geometry
	hull = ST_ConvexHull(inputgeom);
	--A point really has no MBC
	IF ST_GeometryType(hull) = 'ST_Point' THEN
		RETURN hull;
	END IF;
	-- convert the hull perimeter to a linestring so we can manipulate individual points
	--If its already a linestring force it to a closed linestring
	ring = CASE WHEN ST_GeometryType(hull) = 'ST_LineString' THEN ST_AddPoint(hull, ST_StartPoint(hull)) ELSE ST_ExteriorRing(hull) END;

	dist = 0;
	-- Brute Force - check every pair
	FOR i in 1 .. (ST_NumPoints(ring)-2)
		LOOP
			FOR j in i .. (ST_NumPoints(ring)-1)
				LOOP
				d = ST_Distance(ST_PointN(ring,i),ST_PointN(ring,j));
				-- Check the distance and update if larger
				IF (d > dist) THEN
					dist = d;
					idx1 = i;
					idx2 = j;
				END IF;
			END LOOP;
		END LOOP;

	-- We now have the diameter of the convex hull.  The following line returns it if desired.
	-- RETURN ST_MakeLine(ST_PointN(ring,idx1),ST_PointN(ring,idx2));

	-- Now for the Minimum Bounding Circle.  Since we know the two points furthest from each
	-- other, the MBC must go through those two points. Start with those points as a diameter of a circle.

	-- The radius is half the distance between them and the center is midway between them
	radius = ST_Distance(ST_PointN(ring,idx1),ST_PointN(ring,idx2)) / 2.0;
	center = ST_Line_interpolate_point(ST_MakeLine(ST_PointN(ring,idx1),ST_PointN(ring,idx2)),0.5);

	-- Loop through each vertex and check if the distance from the center to the point
	-- is greater than the current radius.
	FOR k in 1 .. (ST_NumPoints(ring)-1)
		LOOP
		IF(k <> idx1 and k <> idx2) THEN
			dist = ST_Distance(center,ST_PointN(ring,k));
			IF (dist > radius) THEN
				-- We have to expand the circle.  The new circle must pass trhough
				-- three points - the two original diameters and this point.

				-- Draw a line from the first diameter to this point
				l1 = ST_Makeline(ST_PointN(ring,idx1),ST_PointN(ring,k));
				-- Compute the midpoint
				p1 = ST_line_interpolate_point(l1,0.5);
				-- Rotate the line 90 degrees around the midpoint (perpendicular bisector)
				l1 = ST_Rotate(l1,pi()/2,p1);
				--  Compute the azimuth of the bisector
				a1 = ST_Azimuth(ST_PointN(l1,1),ST_PointN(l1,2));
				--  Extend the line in each direction the new computed distance to insure they will intersect
				l1 = ST_AddPoint(l1,ST_Makepoint(ST_X(ST_PointN(l1,2))+sin(a1)*dist,ST_Y(ST_PointN(l1,2))+cos(a1)*dist),-1);
				l1 = ST_AddPoint(l1,ST_Makepoint(ST_X(ST_PointN(l1,1))-sin(a1)*dist,ST_Y(ST_PointN(l1,1))-cos(a1)*dist),0);

				-- Repeat for the line from the point to the other diameter point
				l2 = ST_Makeline(ST_PointN(ring,idx2),ST_PointN(ring,k));
				p2 = ST_Line_interpolate_point(l2,0.5);
				l2 = ST_Rotate(l2,pi()/2,p2);
				a2 = ST_Azimuth(ST_PointN(l2,1),ST_PointN(l2,2));
				l2 = ST_AddPoint(l2,ST_Makepoint(ST_X(ST_PointN(l2,2))+sin(a2)*dist,ST_Y(ST_PointN(l2,2))+cos(a2)*dist),-1);
				l2 = ST_AddPoint(l2,ST_Makepoint(ST_X(ST_PointN(l2,1))-sin(a2)*dist,ST_Y(ST_PointN(l2,1))-cos(a2)*dist),0);

				-- The new center is the intersection of the two bisectors
				center = ST_Intersection(l1,l2);
				-- The new radius is the distance to any of the three points
				radius = ST_Distance(center,ST_PointN(ring,idx1));
			END IF;
		END IF;
		END LOOP;
	--DONE!!  Return the MBC via the buffer command
	RETURN ST_Buffer(center,radius,segs_per_quarter);

	END;
$$;


ALTER FUNCTION public.st_minimumboundingcircle(inputgeom geometry, segs_per_quarter integer) OWNER TO postgres;

--
-- Name: FUNCTION st_minimumboundingcircle(inputgeom geometry, segs_per_quarter integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_minimumboundingcircle(inputgeom geometry, segs_per_quarter integer) IS 'args: geomA, num_segs_per_qt_circ=48 - Returns the smallest circle polygon that can fully contain a geometry. Default uses 48 segments per quarter circle.';


--
-- Name: st_mlinefromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mlinefromtext(text) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromText($1)) = 'MULTILINESTRING'
	THEN ST_GeomFromText($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_mlinefromtext(text) OWNER TO postgres;

--
-- Name: FUNCTION st_mlinefromtext(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_mlinefromtext(text) IS 'args: WKT - Return a specified ST_MultiLineString value from WKT representation.';


--
-- Name: st_mlinefromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mlinefromtext(text, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE
	WHEN geometrytype(ST_GeomFromText($1, $2)) = 'MULTILINESTRING'
	THEN ST_GeomFromText($1,$2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_mlinefromtext(text, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_mlinefromtext(text, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_mlinefromtext(text, integer) IS 'args: WKT, srid - Return a specified ST_MultiLineString value from WKT representation.';


--
-- Name: st_mlinefromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mlinefromwkb(bytea) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1)) = 'MULTILINESTRING'
	THEN ST_GeomFromWKB($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_mlinefromwkb(bytea) OWNER TO postgres;

--
-- Name: st_mlinefromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mlinefromwkb(bytea, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1, $2)) = 'MULTILINESTRING'
	THEN ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_mlinefromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_mpointfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mpointfromtext(text) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromText($1)) = 'MULTIPOINT'
	THEN ST_GeomFromText($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_mpointfromtext(text) OWNER TO postgres;

--
-- Name: FUNCTION st_mpointfromtext(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_mpointfromtext(text) IS 'args: WKT - Makes a Geometry from WKT with the given SRID. If SRID is not give, it defaults to -1.';


--
-- Name: st_mpointfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mpointfromtext(text, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromText($1, $2)) = 'MULTIPOINT'
	THEN ST_GeomFromText($1, $2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_mpointfromtext(text, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_mpointfromtext(text, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_mpointfromtext(text, integer) IS 'args: WKT, srid - Makes a Geometry from WKT with the given SRID. If SRID is not give, it defaults to -1.';


--
-- Name: st_mpointfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mpointfromwkb(bytea) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1)) = 'MULTIPOINT'
	THEN ST_GeomFromWKB($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_mpointfromwkb(bytea) OWNER TO postgres;

--
-- Name: st_mpointfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mpointfromwkb(bytea, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1, $2)) = 'MULTIPOINT'
	THEN ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_mpointfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_mpolyfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mpolyfromtext(text) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromText($1)) = 'MULTIPOLYGON'
	THEN ST_GeomFromText($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_mpolyfromtext(text) OWNER TO postgres;

--
-- Name: FUNCTION st_mpolyfromtext(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_mpolyfromtext(text) IS 'args: WKT - Makes a MultiPolygon Geometry from WKT with the given SRID. If SRID is not give, it defaults to -1.';


--
-- Name: st_mpolyfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mpolyfromtext(text, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromText($1, $2)) = 'MULTIPOLYGON'
	THEN ST_GeomFromText($1,$2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_mpolyfromtext(text, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_mpolyfromtext(text, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_mpolyfromtext(text, integer) IS 'args: WKT, srid - Makes a MultiPolygon Geometry from WKT with the given SRID. If SRID is not give, it defaults to -1.';


--
-- Name: st_mpolyfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mpolyfromwkb(bytea) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1)) = 'MULTIPOLYGON'
	THEN ST_GeomFromWKB($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_mpolyfromwkb(bytea) OWNER TO postgres;

--
-- Name: st_mpolyfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mpolyfromwkb(bytea, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1, $2)) = 'MULTIPOLYGON'
	THEN ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_mpolyfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_multi(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multi(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_force_multi';


ALTER FUNCTION public.st_multi(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_multi(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_multi(geometry) IS 'args: g1 - Returns the geometry as a MULTI* geometry. If the geometry is already a MULTI*, it is returned unchanged.';


--
-- Name: st_multilinefromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multilinefromwkb(bytea) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1)) = 'MULTILINESTRING'
	THEN ST_GeomFromWKB($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_multilinefromwkb(bytea) OWNER TO postgres;

--
-- Name: st_multilinestringfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multilinestringfromtext(text) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_MLineFromText($1)$_$;


ALTER FUNCTION public.st_multilinestringfromtext(text) OWNER TO postgres;

--
-- Name: st_multilinestringfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multilinestringfromtext(text, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_MLineFromText($1, $2)$_$;


ALTER FUNCTION public.st_multilinestringfromtext(text, integer) OWNER TO postgres;

--
-- Name: st_multipointfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multipointfromtext(text) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_MPointFromText($1)$_$;


ALTER FUNCTION public.st_multipointfromtext(text) OWNER TO postgres;

--
-- Name: st_multipointfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multipointfromwkb(bytea) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1)) = 'MULTIPOINT'
	THEN ST_GeomFromWKB($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_multipointfromwkb(bytea) OWNER TO postgres;

--
-- Name: st_multipointfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multipointfromwkb(bytea, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1,$2)) = 'MULTIPOINT'
	THEN ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_multipointfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_multipolyfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multipolyfromwkb(bytea) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1)) = 'MULTIPOLYGON'
	THEN ST_GeomFromWKB($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_multipolyfromwkb(bytea) OWNER TO postgres;

--
-- Name: st_multipolyfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multipolyfromwkb(bytea, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1, $2)) = 'MULTIPOLYGON'
	THEN ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_multipolyfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_multipolygonfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multipolygonfromtext(text) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_MPolyFromText($1)$_$;


ALTER FUNCTION public.st_multipolygonfromtext(text) OWNER TO postgres;

--
-- Name: st_multipolygonfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multipolygonfromtext(text, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_MPolyFromText($1, $2)$_$;


ALTER FUNCTION public.st_multipolygonfromtext(text, integer) OWNER TO postgres;

--
-- Name: st_ndims(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_ndims(geometry) RETURNS smallint
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_ndims';


ALTER FUNCTION public.st_ndims(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_ndims(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_ndims(geometry) IS 'args: g1 - Returns coordinate dimension of the geometry as a small int. Values are: 2,3 or 4.';


--
-- Name: st_node(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_node(g geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'ST_Node';


ALTER FUNCTION public.st_node(g geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_node(g geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_node(g geometry) IS 'args: geom - Node a set of linestrings.';


--
-- Name: st_npoints(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_npoints(geometry) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_npoints';


ALTER FUNCTION public.st_npoints(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_npoints(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_npoints(geometry) IS 'args: g1 - Return the number of points (vertexes) in a geometry.';


--
-- Name: st_nrings(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_nrings(geometry) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_nrings';


ALTER FUNCTION public.st_nrings(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_nrings(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_nrings(geometry) IS 'args: geomA - If the geometry is a polygon or multi-polygon returns the number of rings.';


--
-- Name: st_numgeometries(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_numgeometries(geometry) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_numgeometries_collection';


ALTER FUNCTION public.st_numgeometries(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_numgeometries(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_numgeometries(geometry) IS 'args: geom - If geometry is a GEOMETRYCOLLECTION (or MULTI*) return the number of geometries, for single geometries will return 1, otherwise return NULL.';


--
-- Name: st_numinteriorring(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_numinteriorring(geometry) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_numinteriorrings_polygon';


ALTER FUNCTION public.st_numinteriorring(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_numinteriorring(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_numinteriorring(geometry) IS 'args: a_polygon - Return the number of interior rings of the first polygon in the geometry. Synonym to ST_NumInteriorRings.';


--
-- Name: st_numinteriorrings(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_numinteriorrings(geometry) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_numinteriorrings_polygon';


ALTER FUNCTION public.st_numinteriorrings(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_numinteriorrings(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_numinteriorrings(geometry) IS 'args: a_polygon - Return the number of interior rings of the first polygon in the geometry. This will work with both POLYGON and MULTIPOLYGON types but only looks at the first polygon. Return NULL if there is no polygon in the geometry.';


--
-- Name: st_numpatches(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_numpatches(geometry) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN ST_GeometryType($1) = 'ST_PolyhedralSurface'
	THEN ST_NumGeometries($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_numpatches(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_numpatches(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_numpatches(geometry) IS 'args: g1 - Return the number of faces on a Polyhedral Surface. Will return null for non-polyhedral geometries.';


--
-- Name: st_numpoints(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_numpoints(geometry) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_numpoints_linestring';


ALTER FUNCTION public.st_numpoints(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_numpoints(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_numpoints(geometry) IS 'args: g1 - Return the number of points in an ST_LineString or ST_CircularString value.';


--
-- Name: st_offsetcurve(geometry, double precision, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_offsetcurve(line geometry, distance double precision, params text DEFAULT ''::text) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'ST_OffsetCurve';


ALTER FUNCTION public.st_offsetcurve(line geometry, distance double precision, params text) OWNER TO postgres;

--
-- Name: FUNCTION st_offsetcurve(line geometry, distance double precision, params text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_offsetcurve(line geometry, distance double precision, params text) IS 'args: line, signed_distance, style_parameters='' - Return an offset line at a given distance and side from an input line. Useful for computing parallel lines about a center line';


--
-- Name: st_orderingequals(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_orderingequals(geometrya geometry, geometryb geometry) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ 
	SELECT $1 ~= $2 AND _ST_OrderingEquals($1, $2)
	$_$;


ALTER FUNCTION public.st_orderingequals(geometrya geometry, geometryb geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_orderingequals(geometrya geometry, geometryb geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_orderingequals(geometrya geometry, geometryb geometry) IS 'args: A, B - Returns true if the given geometries represent the same geometry and points are in the same directional order.';


--
-- Name: st_overlaps(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_overlaps(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && $2 AND _ST_Overlaps($1,$2)$_$;


ALTER FUNCTION public.st_overlaps(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_overlaps(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_overlaps(geom1 geometry, geom2 geometry) IS 'args: A, B - Returns TRUE if the Geometries share space, are of the same dimension, but are not completely contained by each other.';


--
-- Name: st_patchn(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_patchn(geometry, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN ST_GeometryType($1) = 'ST_PolyhedralSurface'
	THEN ST_GeometryN($1, $2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_patchn(geometry, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_patchn(geometry, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_patchn(geometry, integer) IS 'args: geomA, n - Return the 1-based Nth geometry (face) if the geometry is a POLYHEDRALSURFACE, POLYHEDRALSURFACEM. Otherwise, return NULL.';


--
-- Name: st_perimeter(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_perimeter(geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_perimeter2d_poly';


ALTER FUNCTION public.st_perimeter(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_perimeter(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_perimeter(geometry) IS 'args: g1 - Return the length measurement of the boundary of an ST_Surface or ST_MultiSurface geometry or geography. (Polygon, Multipolygon). geometry measurement is in units of spatial reference and geography is in meters.';


--
-- Name: st_perimeter(geography, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_perimeter(geog geography, use_spheroid boolean DEFAULT true) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'geography_perimeter';


ALTER FUNCTION public.st_perimeter(geog geography, use_spheroid boolean) OWNER TO postgres;

--
-- Name: FUNCTION st_perimeter(geog geography, use_spheroid boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_perimeter(geog geography, use_spheroid boolean) IS 'args: geog, use_spheroid=true - Return the length measurement of the boundary of an ST_Surface or ST_MultiSurface geometry or geography. (Polygon, Multipolygon). geometry measurement is in units of spatial reference and geography is in meters.';


--
-- Name: st_perimeter2d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_perimeter2d(geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_perimeter2d_poly';


ALTER FUNCTION public.st_perimeter2d(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_perimeter2d(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_perimeter2d(geometry) IS 'args: geomA - Returns the 2-dimensional perimeter of the geometry, if it is a polygon or multi-polygon. This is currently an alias for ST_Perimeter.';


--
-- Name: st_point(double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_point(double precision, double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_makepoint';


ALTER FUNCTION public.st_point(double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_point(double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_point(double precision, double precision) IS 'args: x_lon, y_lat - Returns an ST_Point with the given coordinate values. OGC alias for ST_MakePoint.';


--
-- Name: st_point_inside_circle(geometry, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_point_inside_circle(geometry, double precision, double precision, double precision) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_inside_circle_point';


ALTER FUNCTION public.st_point_inside_circle(geometry, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_point_inside_circle(geometry, double precision, double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_point_inside_circle(geometry, double precision, double precision, double precision) IS 'args: a_point, center_x, center_y, radius - Is the point geometry insert circle defined by center_x, center_y, radius';


--
-- Name: st_pointfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_pointfromtext(text) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromText($1)) = 'POINT'
	THEN ST_GeomFromText($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_pointfromtext(text) OWNER TO postgres;

--
-- Name: FUNCTION st_pointfromtext(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_pointfromtext(text) IS 'args: WKT - Makes a point Geometry from WKT with the given SRID. If SRID is not given, it defaults to unknown.';


--
-- Name: st_pointfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_pointfromtext(text, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromText($1, $2)) = 'POINT'
	THEN ST_GeomFromText($1, $2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_pointfromtext(text, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_pointfromtext(text, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_pointfromtext(text, integer) IS 'args: WKT, srid - Makes a point Geometry from WKT with the given SRID. If SRID is not given, it defaults to unknown.';


--
-- Name: st_pointfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_pointfromwkb(bytea) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1)) = 'POINT'
	THEN ST_GeomFromWKB($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_pointfromwkb(bytea) OWNER TO postgres;

--
-- Name: st_pointfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_pointfromwkb(bytea, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1, $2)) = 'POINT'
	THEN ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_pointfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_pointn(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_pointn(geometry, integer) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_pointn_linestring';


ALTER FUNCTION public.st_pointn(geometry, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_pointn(geometry, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_pointn(geometry, integer) IS 'args: a_linestring, n - Return the Nth point in the first linestring or circular linestring in the geometry. Return NULL if there is no linestring in the geometry.';


--
-- Name: st_pointonsurface(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_pointonsurface(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'pointonsurface';


ALTER FUNCTION public.st_pointonsurface(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_pointonsurface(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_pointonsurface(geometry) IS 'args: g1 - Returns a POINT guaranteed to lie on the surface.';


--
-- Name: st_polyfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polyfromtext(text) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromText($1)) = 'POLYGON'
	THEN ST_GeomFromText($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_polyfromtext(text) OWNER TO postgres;

--
-- Name: st_polyfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polyfromtext(text, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromText($1, $2)) = 'POLYGON'
	THEN ST_GeomFromText($1, $2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_polyfromtext(text, integer) OWNER TO postgres;

--
-- Name: st_polyfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polyfromwkb(bytea) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1)) = 'POLYGON'
	THEN ST_GeomFromWKB($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_polyfromwkb(bytea) OWNER TO postgres;

--
-- Name: st_polyfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polyfromwkb(bytea, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1, $2)) = 'POLYGON'
	THEN ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_polyfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_polygon(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polygon(geometry, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ 
	SELECT ST_SetSRID(ST_MakePolygon($1), $2)
	$_$;


ALTER FUNCTION public.st_polygon(geometry, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_polygon(geometry, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_polygon(geometry, integer) IS 'args: aLineString, srid - Returns a polygon built from the specified linestring and SRID.';


--
-- Name: st_polygonfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polygonfromtext(text) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_PolyFromText($1)$_$;


ALTER FUNCTION public.st_polygonfromtext(text) OWNER TO postgres;

--
-- Name: FUNCTION st_polygonfromtext(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_polygonfromtext(text) IS 'args: WKT - Makes a Geometry from WKT with the given SRID. If SRID is not give, it defaults to -1.';


--
-- Name: st_polygonfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polygonfromtext(text, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_PolyFromText($1, $2)$_$;


ALTER FUNCTION public.st_polygonfromtext(text, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_polygonfromtext(text, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_polygonfromtext(text, integer) IS 'args: WKT, srid - Makes a Geometry from WKT with the given SRID. If SRID is not give, it defaults to -1.';


--
-- Name: st_polygonfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polygonfromwkb(bytea) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1)) = 'POLYGON'
	THEN ST_GeomFromWKB($1)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_polygonfromwkb(bytea) OWNER TO postgres;

--
-- Name: st_polygonfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polygonfromwkb(bytea, integer) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
	SELECT CASE WHEN geometrytype(ST_GeomFromWKB($1,$2)) = 'POLYGON'
	THEN ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$_$;


ALTER FUNCTION public.st_polygonfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_polygonize(geometry[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polygonize(geometry[]) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'polygonize_garray';


ALTER FUNCTION public.st_polygonize(geometry[]) OWNER TO postgres;

--
-- Name: FUNCTION st_polygonize(geometry[]); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_polygonize(geometry[]) IS 'args: geom_array - Aggregate. Creates a GeometryCollection containing possible polygons formed from the constituent linework of a set of geometries.';


--
-- Name: st_project(geography, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_project(geog geography, distance double precision, azimuth double precision) RETURNS geography
    LANGUAGE c IMMUTABLE COST 100
    AS '$libdir/postgis-2.0', 'geography_project';


ALTER FUNCTION public.st_project(geog geography, distance double precision, azimuth double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_project(geog geography, distance double precision, azimuth double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_project(geog geography, distance double precision, azimuth double precision) IS 'args: g1, distance, azimuth - Returns a POINT projected from a start point using a bearing and distance.';


--
-- Name: st_relate(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_relate(geom1 geometry, geom2 geometry) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'relate_full';


ALTER FUNCTION public.st_relate(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_relate(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_relate(geom1 geometry, geom2 geometry) IS 'args: geomA, geomB - Returns true if this Geometry is spatially related to anotherGeometry, by testing for intersections between the Interior, Boundary and Exterior of the two geometries as specified by the values in the intersectionMatrixPattern. If no intersectionMatrixPattern is passed in, then returns the maximum intersectionMatrixPattern that relates the 2 geometries.';


--
-- Name: st_relate(geometry, geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_relate(geom1 geometry, geom2 geometry, integer) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'relate_full';


ALTER FUNCTION public.st_relate(geom1 geometry, geom2 geometry, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_relate(geom1 geometry, geom2 geometry, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_relate(geom1 geometry, geom2 geometry, integer) IS 'args: geomA, geomB, BoundaryNodeRule - Returns true if this Geometry is spatially related to anotherGeometry, by testing for intersections between the Interior, Boundary and Exterior of the two geometries as specified by the values in the intersectionMatrixPattern. If no intersectionMatrixPattern is passed in, then returns the maximum intersectionMatrixPattern that relates the 2 geometries.';


--
-- Name: st_relate(geometry, geometry, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_relate(geom1 geometry, geom2 geometry, text) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'relate_pattern';


ALTER FUNCTION public.st_relate(geom1 geometry, geom2 geometry, text) OWNER TO postgres;

--
-- Name: FUNCTION st_relate(geom1 geometry, geom2 geometry, text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_relate(geom1 geometry, geom2 geometry, text) IS 'args: geomA, geomB, intersectionMatrixPattern - Returns true if this Geometry is spatially related to anotherGeometry, by testing for intersections between the Interior, Boundary and Exterior of the two geometries as specified by the values in the intersectionMatrixPattern. If no intersectionMatrixPattern is passed in, then returns the maximum intersectionMatrixPattern that relates the 2 geometries.';


--
-- Name: st_relatematch(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_relatematch(text, text) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'ST_RelateMatch';


ALTER FUNCTION public.st_relatematch(text, text) OWNER TO postgres;

--
-- Name: FUNCTION st_relatematch(text, text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_relatematch(text, text) IS 'args: intersectionMatrix, intersectionMatrixPattern - Returns true if intersectionMattrixPattern1 implies intersectionMatrixPattern2';


--
-- Name: st_removepoint(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_removepoint(geometry, integer) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_removepoint';


ALTER FUNCTION public.st_removepoint(geometry, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_removepoint(geometry, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_removepoint(geometry, integer) IS 'args: linestring, offset - Removes point from a linestring. Offset is 0-based.';


--
-- Name: st_removerepeatedpoints(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_removerepeatedpoints(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'ST_RemoveRepeatedPoints';


ALTER FUNCTION public.st_removerepeatedpoints(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_removerepeatedpoints(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_removerepeatedpoints(geometry) IS 'args: geom - Returns a version of the given geometry with duplicated points removed.';


--
-- Name: st_reverse(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_reverse(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_reverse';


ALTER FUNCTION public.st_reverse(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_reverse(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_reverse(geometry) IS 'args: g1 - Returns the geometry with vertex order reversed.';


--
-- Name: st_rotate(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_rotate(geometry, double precision) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_Affine($1,  cos($2), -sin($2), 0,  sin($2), cos($2), 0,  0, 0, 1,  0, 0, 0)$_$;


ALTER FUNCTION public.st_rotate(geometry, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_rotate(geometry, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_rotate(geometry, double precision) IS 'args: geomA, rotRadians - Rotate a geometry rotRadians counter-clockwise about an origin.';


--
-- Name: st_rotate(geometry, double precision, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_rotate(geometry, double precision, geometry) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_Affine($1,  cos($2), -sin($2), 0,  sin($2),  cos($2), 0, 0, 0, 1, ST_X($3) - cos($2) * ST_X($3) + sin($2) * ST_Y($3), ST_Y($3) - sin($2) * ST_X($3) - cos($2) * ST_Y($3), 0)$_$;


ALTER FUNCTION public.st_rotate(geometry, double precision, geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_rotate(geometry, double precision, geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_rotate(geometry, double precision, geometry) IS 'args: geomA, rotRadians, pointOrigin - Rotate a geometry rotRadians counter-clockwise about an origin.';


--
-- Name: st_rotate(geometry, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_rotate(geometry, double precision, double precision, double precision) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_Affine($1,  cos($2), -sin($2), 0,  sin($2),  cos($2), 0, 0, 0, 1,	$3 - cos($2) * $3 + sin($2) * $4, $4 - sin($2) * $3 - cos($2) * $4, 0)$_$;


ALTER FUNCTION public.st_rotate(geometry, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_rotate(geometry, double precision, double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_rotate(geometry, double precision, double precision, double precision) IS 'args: geomA, rotRadians, x0, y0 - Rotate a geometry rotRadians counter-clockwise about an origin.';


--
-- Name: st_rotatex(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_rotatex(geometry, double precision) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_Affine($1, 1, 0, 0, 0, cos($2), -sin($2), 0, sin($2), cos($2), 0, 0, 0)$_$;


ALTER FUNCTION public.st_rotatex(geometry, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_rotatex(geometry, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_rotatex(geometry, double precision) IS 'args: geomA, rotRadians - Rotate a geometry rotRadians about the X axis.';


--
-- Name: st_rotatey(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_rotatey(geometry, double precision) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_Affine($1,  cos($2), 0, sin($2),  0, 1, 0,  -sin($2), 0, cos($2), 0,  0, 0)$_$;


ALTER FUNCTION public.st_rotatey(geometry, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_rotatey(geometry, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_rotatey(geometry, double precision) IS 'args: geomA, rotRadians - Rotate a geometry rotRadians about the Y axis.';


--
-- Name: st_rotatez(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_rotatez(geometry, double precision) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_Rotate($1, $2)$_$;


ALTER FUNCTION public.st_rotatez(geometry, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_rotatez(geometry, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_rotatez(geometry, double precision) IS 'args: geomA, rotRadians - Rotate a geometry rotRadians about the Z axis.';


--
-- Name: st_scale(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_scale(geometry, double precision, double precision) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_Scale($1, $2, $3, 1)$_$;


ALTER FUNCTION public.st_scale(geometry, double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_scale(geometry, double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_scale(geometry, double precision, double precision) IS 'args: geomA, XFactor, YFactor - Scales the geometry to a new size by multiplying the ordinates with the parameters. Ie: ST_Scale(geom, Xfactor, Yfactor, Zfactor).';


--
-- Name: st_scale(geometry, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_scale(geometry, double precision, double precision, double precision) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_Affine($1,  $2, 0, 0,  0, $3, 0,  0, 0, $4,  0, 0, 0)$_$;


ALTER FUNCTION public.st_scale(geometry, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_scale(geometry, double precision, double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_scale(geometry, double precision, double precision, double precision) IS 'args: geomA, XFactor, YFactor, ZFactor - Scales the geometry to a new size by multiplying the ordinates with the parameters. Ie: ST_Scale(geom, Xfactor, Yfactor, Zfactor).';


--
-- Name: st_segmentize(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_segmentize(geometry, double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_segmentize2d';


ALTER FUNCTION public.st_segmentize(geometry, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_segmentize(geometry, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_segmentize(geometry, double precision) IS 'args: geomA, max_length - Return a modified geometry having no segment longer than the given distance. Distance computation is performed in 2d only.';


--
-- Name: st_setpoint(geometry, integer, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_setpoint(geometry, integer, geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_setpoint_linestring';


ALTER FUNCTION public.st_setpoint(geometry, integer, geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_setpoint(geometry, integer, geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_setpoint(geometry, integer, geometry) IS 'args: linestring, zerobasedposition, point - Replace point N of linestring with given point. Index is 0-based.';


--
-- Name: st_setsrid(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_setsrid(geometry, integer) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_set_srid';


ALTER FUNCTION public.st_setsrid(geometry, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_setsrid(geometry, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_setsrid(geometry, integer) IS 'args: geom, srid - Sets the SRID on a geometry to a particular integer value.';


--
-- Name: st_sharedpaths(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_sharedpaths(geom1 geometry, geom2 geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'ST_SharedPaths';


ALTER FUNCTION public.st_sharedpaths(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_sharedpaths(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_sharedpaths(geom1 geometry, geom2 geometry) IS 'args: lineal1, lineal2 - Returns a collection containing paths shared by the two input linestrings/multilinestrings.';


--
-- Name: st_shift_longitude(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_shift_longitude(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_longitude_shift';


ALTER FUNCTION public.st_shift_longitude(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_shift_longitude(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_shift_longitude(geometry) IS 'args: geomA - Reads every point/vertex in every component of every feature in a geometry, and if the longitude coordinate is <0, adds 360 to it. The result would be a 0-360 version of the data to be plotted in a 180 centric map';


--
-- Name: st_shortestline(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_shortestline(geom1 geometry, geom2 geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_shortestline2d';


ALTER FUNCTION public.st_shortestline(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_shortestline(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_shortestline(geom1 geometry, geom2 geometry) IS 'args: g1, g2 - Returns the 2-dimensional shortest line between two geometries';


--
-- Name: st_simplify(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_simplify(geometry, double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_simplify2d';


ALTER FUNCTION public.st_simplify(geometry, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_simplify(geometry, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_simplify(geometry, double precision) IS 'args: geomA, tolerance - Returns a "simplified" version of the given geometry using the Douglas-Peucker algorithm.';


--
-- Name: st_simplifypreservetopology(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_simplifypreservetopology(geometry, double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'topologypreservesimplify';


ALTER FUNCTION public.st_simplifypreservetopology(geometry, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_simplifypreservetopology(geometry, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_simplifypreservetopology(geometry, double precision) IS 'args: geomA, tolerance - Returns a "simplified" version of the given geometry using the Douglas-Peucker algorithm. Will avoid creating derived geometries (polygons in particular) that are invalid.';


--
-- Name: st_snap(geometry, geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_snap(geom1 geometry, geom2 geometry, double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'ST_Snap';


ALTER FUNCTION public.st_snap(geom1 geometry, geom2 geometry, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_snap(geom1 geometry, geom2 geometry, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_snap(geom1 geometry, geom2 geometry, double precision) IS 'args: input, reference, tolerance - Snap segments and vertices of input geometry to vertices of a reference geometry.';


--
-- Name: st_snaptogrid(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_snaptogrid(geometry, double precision) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_SnapToGrid($1, 0, 0, $2, $2)$_$;


ALTER FUNCTION public.st_snaptogrid(geometry, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_snaptogrid(geometry, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_snaptogrid(geometry, double precision) IS 'args: geomA, size - Snap all points of the input geometry to a regular grid.';


--
-- Name: st_snaptogrid(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_snaptogrid(geometry, double precision, double precision) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_SnapToGrid($1, 0, 0, $2, $3)$_$;


ALTER FUNCTION public.st_snaptogrid(geometry, double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_snaptogrid(geometry, double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_snaptogrid(geometry, double precision, double precision) IS 'args: geomA, sizeX, sizeY - Snap all points of the input geometry to a regular grid.';


--
-- Name: st_snaptogrid(geometry, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_snaptogrid(geometry, double precision, double precision, double precision, double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_snaptogrid';


ALTER FUNCTION public.st_snaptogrid(geometry, double precision, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_snaptogrid(geometry, double precision, double precision, double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_snaptogrid(geometry, double precision, double precision, double precision, double precision) IS 'args: geomA, originX, originY, sizeX, sizeY - Snap all points of the input geometry to a regular grid.';


--
-- Name: st_snaptogrid(geometry, geometry, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_snaptogrid(geom1 geometry, geom2 geometry, double precision, double precision, double precision, double precision) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_snaptogrid_pointoff';


ALTER FUNCTION public.st_snaptogrid(geom1 geometry, geom2 geometry, double precision, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_snaptogrid(geom1 geometry, geom2 geometry, double precision, double precision, double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_snaptogrid(geom1 geometry, geom2 geometry, double precision, double precision, double precision, double precision) IS 'args: geomA, pointOrigin, sizeX, sizeY, sizeZ, sizeM - Snap all points of the input geometry to a regular grid.';


--
-- Name: st_split(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_split(geom1 geometry, geom2 geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT COST 100
    AS '$libdir/postgis-2.0', 'ST_Split';


ALTER FUNCTION public.st_split(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_split(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_split(geom1 geometry, geom2 geometry) IS 'args: input, blade - Returns a collection of geometries resulting by splitting a geometry.';


--
-- Name: st_srid(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_srid(geometry) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_get_srid';


ALTER FUNCTION public.st_srid(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_srid(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_srid(geometry) IS 'args: g1 - Returns the spatial reference identifier for the ST_Geometry as defined in spatial_ref_sys table.';


--
-- Name: st_startpoint(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_startpoint(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_startpoint_linestring';


ALTER FUNCTION public.st_startpoint(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_startpoint(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_startpoint(geometry) IS 'args: geomA - Returns the first point of a LINESTRING geometry as a POINT.';


--
-- Name: st_summary(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_summary(geometry) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_summary';


ALTER FUNCTION public.st_summary(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_summary(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_summary(geometry) IS 'args: g - Returns a text summary of the contents of the geometry.';


--
-- Name: st_summary(geography); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_summary(geography) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_summary';


ALTER FUNCTION public.st_summary(geography) OWNER TO postgres;

--
-- Name: FUNCTION st_summary(geography); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_summary(geography) IS 'args: g - Returns a text summary of the contents of the geometry.';


--
-- Name: st_symdifference(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_symdifference(geom1 geometry, geom2 geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'symdifference';


ALTER FUNCTION public.st_symdifference(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_symdifference(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_symdifference(geom1 geometry, geom2 geometry) IS 'args: geomA, geomB - Returns a geometry that represents the portions of A and B that do not intersect. It is called a symmetric difference because ST_SymDifference(A,B) = ST_SymDifference(B,A).';


--
-- Name: st_symmetricdifference(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_symmetricdifference(geom1 geometry, geom2 geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'symdifference';


ALTER FUNCTION public.st_symmetricdifference(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: st_touches(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_touches(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && $2 AND _ST_Touches($1,$2)$_$;


ALTER FUNCTION public.st_touches(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_touches(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_touches(geom1 geometry, geom2 geometry) IS 'args: g1, g2 - Returns TRUE if the geometries have at least one point in common, but their interiors do not intersect.';


--
-- Name: st_transform(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_transform(geometry, integer) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'transform';


ALTER FUNCTION public.st_transform(geometry, integer) OWNER TO postgres;

--
-- Name: FUNCTION st_transform(geometry, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_transform(geometry, integer) IS 'args: g1, srid - Returns a new geometry with its coordinates transformed to the SRID referenced by the integer parameter.';


--
-- Name: st_translate(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_translate(geometry, double precision, double precision) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_Translate($1, $2, $3, 0)$_$;


ALTER FUNCTION public.st_translate(geometry, double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_translate(geometry, double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_translate(geometry, double precision, double precision) IS 'args: g1, deltax, deltay - Translates the geometry to a new location using the numeric parameters as offsets. Ie: ST_Translate(geom, X, Y) or ST_Translate(geom, X, Y,Z).';


--
-- Name: st_translate(geometry, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_translate(geometry, double precision, double precision, double precision) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_Affine($1, 1, 0, 0, 0, 1, 0, 0, 0, 1, $2, $3, $4)$_$;


ALTER FUNCTION public.st_translate(geometry, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_translate(geometry, double precision, double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_translate(geometry, double precision, double precision, double precision) IS 'args: g1, deltax, deltay, deltaz - Translates the geometry to a new location using the numeric parameters as offsets. Ie: ST_Translate(geom, X, Y) or ST_Translate(geom, X, Y,Z).';


--
-- Name: st_transscale(geometry, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_transscale(geometry, double precision, double precision, double precision, double precision) RETURNS geometry
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_Affine($1,  $4, 0, 0,  0, $5, 0,
		0, 0, 1,  $2 * $4, $3 * $5, 0)$_$;


ALTER FUNCTION public.st_transscale(geometry, double precision, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_transscale(geometry, double precision, double precision, double precision, double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_transscale(geometry, double precision, double precision, double precision, double precision) IS 'args: geomA, deltaX, deltaY, XFactor, YFactor - Translates the geometry using the deltaX and deltaY args, then scales it using the XFactor, YFactor args, working in 2D only.';


--
-- Name: st_unaryunion(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_unaryunion(geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'ST_UnaryUnion';


ALTER FUNCTION public.st_unaryunion(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_unaryunion(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_unaryunion(geometry) IS 'args: geom - Like ST_Union, but working at the geometry component level.';


--
-- Name: st_union(geometry[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_union(geometry[]) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'pgis_union_geometry_array';


ALTER FUNCTION public.st_union(geometry[]) OWNER TO postgres;

--
-- Name: FUNCTION st_union(geometry[]); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_union(geometry[]) IS 'args: g1_array - Returns a geometry that represents the point set union of the Geometries.';


--
-- Name: st_union(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_union(geom1 geometry, geom2 geometry) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'geomunion';


ALTER FUNCTION public.st_union(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_union(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_union(geom1 geometry, geom2 geometry) IS 'args: g1, g2 - Returns a geometry that represents the point set union of the Geometries.';


--
-- Name: st_within(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_within(geom1 geometry, geom2 geometry) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT $1 && $2 AND _ST_Contains($2,$1)$_$;


ALTER FUNCTION public.st_within(geom1 geometry, geom2 geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_within(geom1 geometry, geom2 geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_within(geom1 geometry, geom2 geometry) IS 'args: A, B - Returns true if the geometry A is completely inside geometry B';


--
-- Name: st_wkbtosql(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_wkbtosql(wkb bytea) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_from_WKB';


ALTER FUNCTION public.st_wkbtosql(wkb bytea) OWNER TO postgres;

--
-- Name: FUNCTION st_wkbtosql(wkb bytea); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_wkbtosql(wkb bytea) IS 'args: WKB - Return a specified ST_Geometry value from Well-Known Binary representation (WKB). This is an alias name for ST_GeomFromWKB that takes no srid';


--
-- Name: st_wkttosql(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_wkttosql(text) RETURNS geometry
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_from_text';


ALTER FUNCTION public.st_wkttosql(text) OWNER TO postgres;

--
-- Name: FUNCTION st_wkttosql(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_wkttosql(text) IS 'args: WKT - Return a specified ST_Geometry value from Well-Known Text representation (WKT). This is an alias name for ST_GeomFromText';


--
-- Name: st_x(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_x(geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_x_point';


ALTER FUNCTION public.st_x(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_x(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_x(geometry) IS 'args: a_point - Return the X coordinate of the point, or NULL if not available. Input must be a point.';


--
-- Name: st_xmax(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_xmax(box3d) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX3D_xmax';


ALTER FUNCTION public.st_xmax(box3d) OWNER TO postgres;

--
-- Name: FUNCTION st_xmax(box3d); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_xmax(box3d) IS 'args: aGeomorBox2DorBox3D - Returns X maxima of a bounding box 2d or 3d or a geometry.';


--
-- Name: st_xmin(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_xmin(box3d) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX3D_xmin';


ALTER FUNCTION public.st_xmin(box3d) OWNER TO postgres;

--
-- Name: FUNCTION st_xmin(box3d); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_xmin(box3d) IS 'args: aGeomorBox2DorBox3D - Returns X minima of a bounding box 2d or 3d or a geometry.';


--
-- Name: st_y(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_y(geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_y_point';


ALTER FUNCTION public.st_y(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_y(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_y(geometry) IS 'args: a_point - Return the Y coordinate of the point, or NULL if not available. Input must be a point.';


--
-- Name: st_ymax(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_ymax(box3d) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX3D_ymax';


ALTER FUNCTION public.st_ymax(box3d) OWNER TO postgres;

--
-- Name: FUNCTION st_ymax(box3d); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_ymax(box3d) IS 'args: aGeomorBox2DorBox3D - Returns Y maxima of a bounding box 2d or 3d or a geometry.';


--
-- Name: st_ymin(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_ymin(box3d) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX3D_ymin';


ALTER FUNCTION public.st_ymin(box3d) OWNER TO postgres;

--
-- Name: FUNCTION st_ymin(box3d); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_ymin(box3d) IS 'args: aGeomorBox2DorBox3D - Returns Y minima of a bounding box 2d or 3d or a geometry.';


--
-- Name: st_z(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_z(geometry) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_z_point';


ALTER FUNCTION public.st_z(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_z(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_z(geometry) IS 'args: a_point - Return the Z coordinate of the point, or NULL if not available. Input must be a point.';


--
-- Name: st_zmax(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_zmax(box3d) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX3D_zmax';


ALTER FUNCTION public.st_zmax(box3d) OWNER TO postgres;

--
-- Name: FUNCTION st_zmax(box3d); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_zmax(box3d) IS 'args: aGeomorBox2DorBox3D - Returns Z minima of a bounding box 2d or 3d or a geometry.';


--
-- Name: st_zmflag(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_zmflag(geometry) RETURNS smallint
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_zmflag';


ALTER FUNCTION public.st_zmflag(geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_zmflag(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_zmflag(geometry) IS 'args: geomA - Returns ZM (dimension semantic) flag of the geometries as a small int. Values are: 0=2d, 1=3dm, 2=3dz, 3=4d.';


--
-- Name: st_zmin(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_zmin(box3d) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'BOX3D_zmin';


ALTER FUNCTION public.st_zmin(box3d) OWNER TO postgres;

--
-- Name: FUNCTION st_zmin(box3d); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION st_zmin(box3d) IS 'args: aGeomorBox2DorBox3D - Returns Z minima of a bounding box 2d or 3d or a geometry.';


--
-- Name: text(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION text(geometry) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/postgis-2.0', 'LWGEOM_to_text';


ALTER FUNCTION public.text(geometry) OWNER TO postgres;

--
-- Name: unlockrows(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION unlockrows(text) RETURNS integer
    LANGUAGE plpgsql STRICT
    AS $_$ 
DECLARE
	ret int;
BEGIN

	IF NOT LongTransactionsEnabled() THEN
		RAISE EXCEPTION 'Long transaction support disabled, use EnableLongTransaction() to enable.';
	END IF;

	EXECUTE 'DELETE FROM authorization_table where authid = ' ||
		quote_literal($1);

	GET DIAGNOSTICS ret = ROW_COUNT;

	RETURN ret;
END;
$_$;


ALTER FUNCTION public.unlockrows(text) OWNER TO postgres;

--
-- Name: FUNCTION unlockrows(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION unlockrows(text) IS 'args: auth_token - Remove all locks held by specified authorization id. Returns the number of locks released.';


--
-- Name: updategeometrysrid(character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION updategeometrysrid(character varying, character varying, integer) RETURNS text
    LANGUAGE plpgsql STRICT
    AS $_$
DECLARE
	ret  text;
BEGIN
	SELECT UpdateGeometrySRID('','',$1,$2,$3) into ret;
	RETURN ret;
END;
$_$;


ALTER FUNCTION public.updategeometrysrid(character varying, character varying, integer) OWNER TO postgres;

--
-- Name: FUNCTION updategeometrysrid(character varying, character varying, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION updategeometrysrid(character varying, character varying, integer) IS 'args: table_name, column_name, srid - Updates the SRID of all features in a geometry column, geometry_columns metadata and srid table constraint';


--
-- Name: updategeometrysrid(character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION updategeometrysrid(character varying, character varying, character varying, integer) RETURNS text
    LANGUAGE plpgsql STRICT
    AS $_$
DECLARE
	ret  text;
BEGIN
	SELECT UpdateGeometrySRID('',$1,$2,$3,$4) into ret;
	RETURN ret;
END;
$_$;


ALTER FUNCTION public.updategeometrysrid(character varying, character varying, character varying, integer) OWNER TO postgres;

--
-- Name: FUNCTION updategeometrysrid(character varying, character varying, character varying, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION updategeometrysrid(character varying, character varying, character varying, integer) IS 'args: schema_name, table_name, column_name, srid - Updates the SRID of all features in a geometry column, geometry_columns metadata and srid table constraint';


--
-- Name: updategeometrysrid(character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer) RETURNS text
    LANGUAGE plpgsql STRICT
    AS $$
DECLARE
	myrec RECORD;
	okay boolean;
	cname varchar;
	real_schema name;
	unknown_srid integer;
	new_srid integer := new_srid_in;

BEGIN


	-- Find, check or fix schema_name
	IF ( schema_name != '' ) THEN
		okay = false;

		FOR myrec IN SELECT nspname FROM pg_namespace WHERE text(nspname) = schema_name LOOP
			okay := true;
		END LOOP;

		IF ( okay <> true ) THEN
			RAISE EXCEPTION 'Invalid schema name';
		ELSE
			real_schema = schema_name;
		END IF;
	ELSE
		SELECT INTO real_schema current_schema()::text;
	END IF;

	-- Ensure that column_name is in geometry_columns
	okay = false;
	FOR myrec IN SELECT type, coord_dimension FROM geometry_columns WHERE f_table_schema = text(real_schema) and f_table_name = table_name and f_geometry_column = column_name LOOP
		okay := true;
	END LOOP;
	IF (NOT okay) THEN
		RAISE EXCEPTION 'column not found in geometry_columns table';
		RETURN false;
	END IF;

	-- Ensure that new_srid is valid
	IF ( new_srid > 0 ) THEN
		IF ( SELECT count(*) = 0 from spatial_ref_sys where srid = new_srid ) THEN
			RAISE EXCEPTION 'invalid SRID: % not found in spatial_ref_sys', new_srid;
			RETURN false;
		END IF;
	ELSE
		unknown_srid := ST_SRID('POINT EMPTY'::geometry);
		IF ( new_srid != unknown_srid ) THEN
			new_srid := unknown_srid;
			RAISE NOTICE 'SRID value % converted to the officially unknown SRID value %', new_srid_in, new_srid;
		END IF;
	END IF;

	IF postgis_constraint_srid(schema_name, table_name, column_name) IS NOT NULL THEN 
	-- srid was enforced with constraints before, keep it that way.
        -- Make up constraint name
        cname = 'enforce_srid_'  || column_name;
    
        -- Drop enforce_srid constraint
        EXECUTE 'ALTER TABLE ' || quote_ident(real_schema) ||
            '.' || quote_ident(table_name) ||
            ' DROP constraint ' || quote_ident(cname);
    
        -- Update geometries SRID
        EXECUTE 'UPDATE ' || quote_ident(real_schema) ||
            '.' || quote_ident(table_name) ||
            ' SET ' || quote_ident(column_name) ||
            ' = ST_SetSRID(' || quote_ident(column_name) ||
            ', ' || new_srid::text || ')';
            
        -- Reset enforce_srid constraint
        EXECUTE 'ALTER TABLE ' || quote_ident(real_schema) ||
            '.' || quote_ident(table_name) ||
            ' ADD constraint ' || quote_ident(cname) ||
            ' CHECK (st_srid(' || quote_ident(column_name) ||
            ') = ' || new_srid::text || ')';
    ELSE 
        -- We will use typmod to enforce if no srid constraints
        -- We are using postgis_type_name to lookup the new name 
        -- (in case Paul changes his mind and flips geometry_columns to return old upper case name) 
        EXECUTE 'ALTER TABLE ' || quote_ident(real_schema) || '.' || quote_ident(table_name) || 
        ' ALTER COLUMN ' || quote_ident(column_name) || ' TYPE  geometry(' || postgis_type_name(myrec.type, myrec.coord_dimension, true) || ', ' || new_srid::text || ') USING ST_SetSRID(' || quote_ident(column_name) || ',' || new_srid::text || ');' ;
    END IF;

	RETURN real_schema || '.' || table_name || '.' || column_name ||' SRID changed to ' || new_srid::text;

END;
$$;


ALTER FUNCTION public.updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer) OWNER TO postgres;

--
-- Name: FUNCTION updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer) IS 'args: catalog_name, schema_name, table_name, column_name, srid - Updates the SRID of all features in a geometry column, geometry_columns metadata and srid table constraint';


--
-- Name: st_3dextent(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE st_3dextent(geometry) (
    SFUNC = public.st_combine_bbox,
    STYPE = box3d
);


ALTER AGGREGATE public.st_3dextent(geometry) OWNER TO postgres;

--
-- Name: AGGREGATE st_3dextent(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON AGGREGATE st_3dextent(geometry) IS 'args: geomfield - an aggregate function that returns the box3D bounding box that bounds rows of geometries.';


--
-- Name: st_accum(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE st_accum(geometry) (
    SFUNC = pgis_geometry_accum_transfn,
    STYPE = pgis_abs,
    FINALFUNC = pgis_geometry_accum_finalfn
);


ALTER AGGREGATE public.st_accum(geometry) OWNER TO postgres;

--
-- Name: AGGREGATE st_accum(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON AGGREGATE st_accum(geometry) IS 'args: geomfield - Aggregate. Constructs an array of geometries.';


--
-- Name: st_collect(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE st_collect(geometry) (
    SFUNC = pgis_geometry_accum_transfn,
    STYPE = pgis_abs,
    FINALFUNC = pgis_geometry_collect_finalfn
);


ALTER AGGREGATE public.st_collect(geometry) OWNER TO postgres;

--
-- Name: AGGREGATE st_collect(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON AGGREGATE st_collect(geometry) IS 'args: g1field - Return a specified ST_Geometry value from a collection of other geometries.';


--
-- Name: st_extent(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE st_extent(geometry) (
    SFUNC = public.st_combine_bbox,
    STYPE = box3d,
    FINALFUNC = public.box2d
);


ALTER AGGREGATE public.st_extent(geometry) OWNER TO postgres;

--
-- Name: AGGREGATE st_extent(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON AGGREGATE st_extent(geometry) IS 'args: geomfield - an aggregate function that returns the bounding box that bounds rows of geometries.';


--
-- Name: st_makeline(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE st_makeline(geometry) (
    SFUNC = pgis_geometry_accum_transfn,
    STYPE = pgis_abs,
    FINALFUNC = pgis_geometry_makeline_finalfn
);


ALTER AGGREGATE public.st_makeline(geometry) OWNER TO postgres;

--
-- Name: AGGREGATE st_makeline(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON AGGREGATE st_makeline(geometry) IS 'args: geoms - Creates a Linestring from point or line geometries.';


--
-- Name: st_memcollect(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE st_memcollect(geometry) (
    SFUNC = public.st_collect,
    STYPE = geometry
);


ALTER AGGREGATE public.st_memcollect(geometry) OWNER TO postgres;

--
-- Name: st_memunion(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE st_memunion(geometry) (
    SFUNC = public.st_union,
    STYPE = geometry
);


ALTER AGGREGATE public.st_memunion(geometry) OWNER TO postgres;

--
-- Name: AGGREGATE st_memunion(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON AGGREGATE st_memunion(geometry) IS 'args: geomfield - Same as ST_Union, only memory-friendly (uses less memory and more processor time).';


--
-- Name: st_polygonize(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE st_polygonize(geometry) (
    SFUNC = pgis_geometry_accum_transfn,
    STYPE = pgis_abs,
    FINALFUNC = pgis_geometry_polygonize_finalfn
);


ALTER AGGREGATE public.st_polygonize(geometry) OWNER TO postgres;

--
-- Name: AGGREGATE st_polygonize(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON AGGREGATE st_polygonize(geometry) IS 'args: geomfield - Aggregate. Creates a GeometryCollection containing possible polygons formed from the constituent linework of a set of geometries.';


--
-- Name: st_union(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE st_union(geometry) (
    SFUNC = pgis_geometry_accum_transfn,
    STYPE = pgis_abs,
    FINALFUNC = pgis_geometry_union_finalfn
);


ALTER AGGREGATE public.st_union(geometry) OWNER TO postgres;

--
-- Name: AGGREGATE st_union(geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON AGGREGATE st_union(geometry) IS 'args: g1field - Returns a geometry that represents the point set union of the Geometries.';


--
-- Name: &&; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR && (
    PROCEDURE = geometry_overlaps,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = &&,
    RESTRICT = geometry_gist_sel_2d,
    JOIN = geometry_gist_joinsel_2d
);


ALTER OPERATOR public.&& (geometry, geometry) OWNER TO postgres;

--
-- Name: &&; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR && (
    PROCEDURE = geography_overlaps,
    LEFTARG = geography,
    RIGHTARG = geography,
    COMMUTATOR = &&,
    RESTRICT = geography_gist_selectivity,
    JOIN = geography_gist_join_selectivity
);


ALTER OPERATOR public.&& (geography, geography) OWNER TO postgres;

--
-- Name: &&&; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR &&& (
    PROCEDURE = geometry_overlaps_nd,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = &&&,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.&&& (geometry, geometry) OWNER TO postgres;

--
-- Name: &<; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR &< (
    PROCEDURE = geometry_overleft,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = &>,
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


ALTER OPERATOR public.&< (geometry, geometry) OWNER TO postgres;

--
-- Name: &<|; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR &<| (
    PROCEDURE = geometry_overbelow,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = |&>,
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


ALTER OPERATOR public.&<| (geometry, geometry) OWNER TO postgres;

--
-- Name: &>; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR &> (
    PROCEDURE = geometry_overright,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = &<,
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


ALTER OPERATOR public.&> (geometry, geometry) OWNER TO postgres;

--
-- Name: <; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR < (
    PROCEDURE = geometry_lt,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = >,
    NEGATOR = >=,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.< (geometry, geometry) OWNER TO postgres;

--
-- Name: <; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR < (
    PROCEDURE = geography_lt,
    LEFTARG = geography,
    RIGHTARG = geography,
    COMMUTATOR = >,
    NEGATOR = >=,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.< (geography, geography) OWNER TO postgres;

--
-- Name: <#>; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR <#> (
    PROCEDURE = geometry_distance_box,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = <#>
);


ALTER OPERATOR public.<#> (geometry, geometry) OWNER TO postgres;

--
-- Name: <->; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR <-> (
    PROCEDURE = geometry_distance_centroid,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = <->
);


ALTER OPERATOR public.<-> (geometry, geometry) OWNER TO postgres;

--
-- Name: <<; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR << (
    PROCEDURE = geometry_left,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = >>,
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


ALTER OPERATOR public.<< (geometry, geometry) OWNER TO postgres;

--
-- Name: <<|; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR <<| (
    PROCEDURE = geometry_below,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = |>>,
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


ALTER OPERATOR public.<<| (geometry, geometry) OWNER TO postgres;

--
-- Name: <=; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR <= (
    PROCEDURE = geometry_le,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = >=,
    NEGATOR = >,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.<= (geometry, geometry) OWNER TO postgres;

--
-- Name: <=; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR <= (
    PROCEDURE = geography_le,
    LEFTARG = geography,
    RIGHTARG = geography,
    COMMUTATOR = >=,
    NEGATOR = >,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.<= (geography, geography) OWNER TO postgres;

--
-- Name: =; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR = (
    PROCEDURE = geometry_eq,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = =,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.= (geometry, geometry) OWNER TO postgres;

--
-- Name: =; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR = (
    PROCEDURE = geography_eq,
    LEFTARG = geography,
    RIGHTARG = geography,
    COMMUTATOR = =,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.= (geography, geography) OWNER TO postgres;

--
-- Name: >; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR > (
    PROCEDURE = geometry_gt,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = <,
    NEGATOR = <=,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.> (geometry, geometry) OWNER TO postgres;

--
-- Name: >; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR > (
    PROCEDURE = geography_gt,
    LEFTARG = geography,
    RIGHTARG = geography,
    COMMUTATOR = <,
    NEGATOR = <=,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.> (geography, geography) OWNER TO postgres;

--
-- Name: >=; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR >= (
    PROCEDURE = geometry_ge,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = <=,
    NEGATOR = <,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.>= (geometry, geometry) OWNER TO postgres;

--
-- Name: >=; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR >= (
    PROCEDURE = geography_ge,
    LEFTARG = geography,
    RIGHTARG = geography,
    COMMUTATOR = <=,
    NEGATOR = <,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.>= (geography, geography) OWNER TO postgres;

--
-- Name: >>; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR >> (
    PROCEDURE = geometry_right,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = <<,
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


ALTER OPERATOR public.>> (geometry, geometry) OWNER TO postgres;

--
-- Name: @; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR @ (
    PROCEDURE = geometry_within,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = ~,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.@ (geometry, geometry) OWNER TO postgres;

--
-- Name: |&>; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR |&> (
    PROCEDURE = geometry_overabove,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = &<|,
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


ALTER OPERATOR public.|&> (geometry, geometry) OWNER TO postgres;

--
-- Name: |>>; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR |>> (
    PROCEDURE = geometry_above,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = <<|,
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


ALTER OPERATOR public.|>> (geometry, geometry) OWNER TO postgres;

--
-- Name: ~; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR ~ (
    PROCEDURE = geometry_contains,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = @,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.~ (geometry, geometry) OWNER TO postgres;

--
-- Name: ~=; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR ~= (
    PROCEDURE = geometry_same,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.~= (geometry, geometry) OWNER TO postgres;

--
-- Name: btree_geography_ops; Type: OPERATOR CLASS; Schema: public; Owner: postgres
--

CREATE OPERATOR CLASS btree_geography_ops
    DEFAULT FOR TYPE geography USING btree AS
    OPERATOR 1 <(geography,geography) ,
    OPERATOR 2 <=(geography,geography) ,
    OPERATOR 3 =(geography,geography) ,
    OPERATOR 4 >=(geography,geography) ,
    OPERATOR 5 >(geography,geography) ,
    FUNCTION 1 geography_cmp(geography,geography);


ALTER OPERATOR CLASS public.btree_geography_ops USING btree OWNER TO postgres;

--
-- Name: btree_geometry_ops; Type: OPERATOR CLASS; Schema: public; Owner: postgres
--

CREATE OPERATOR CLASS btree_geometry_ops
    DEFAULT FOR TYPE geometry USING btree AS
    OPERATOR 1 <(geometry,geometry) ,
    OPERATOR 2 <=(geometry,geometry) ,
    OPERATOR 3 =(geometry,geometry) ,
    OPERATOR 4 >=(geometry,geometry) ,
    OPERATOR 5 >(geometry,geometry) ,
    FUNCTION 1 geometry_cmp(geometry,geometry);


ALTER OPERATOR CLASS public.btree_geometry_ops USING btree OWNER TO postgres;

--
-- Name: gist_geography_ops; Type: OPERATOR CLASS; Schema: public; Owner: postgres
--

CREATE OPERATOR CLASS gist_geography_ops
    DEFAULT FOR TYPE geography USING gist AS
    STORAGE gidx ,
    OPERATOR 3 &&(geography,geography) ,
    FUNCTION 1 geography_gist_consistent(internal,geography,integer) ,
    FUNCTION 2 geography_gist_union(bytea,internal) ,
    FUNCTION 3 geography_gist_compress(internal) ,
    FUNCTION 4 geography_gist_decompress(internal) ,
    FUNCTION 5 geography_gist_penalty(internal,internal,internal) ,
    FUNCTION 6 geography_gist_picksplit(internal,internal) ,
    FUNCTION 7 geography_gist_same(box2d,box2d,internal);


ALTER OPERATOR CLASS public.gist_geography_ops USING gist OWNER TO postgres;

--
-- Name: gist_geometry_ops_2d; Type: OPERATOR CLASS; Schema: public; Owner: postgres
--

CREATE OPERATOR CLASS gist_geometry_ops_2d
    DEFAULT FOR TYPE geometry USING gist AS
    STORAGE box2df ,
    OPERATOR 1 <<(geometry,geometry) ,
    OPERATOR 2 &<(geometry,geometry) ,
    OPERATOR 3 &&(geometry,geometry) ,
    OPERATOR 4 &>(geometry,geometry) ,
    OPERATOR 5 >>(geometry,geometry) ,
    OPERATOR 6 ~=(geometry,geometry) ,
    OPERATOR 7 ~(geometry,geometry) ,
    OPERATOR 8 @(geometry,geometry) ,
    OPERATOR 9 &<|(geometry,geometry) ,
    OPERATOR 10 <<|(geometry,geometry) ,
    OPERATOR 11 |>>(geometry,geometry) ,
    OPERATOR 12 |&>(geometry,geometry) ,
    OPERATOR 13 <->(geometry,geometry) FOR ORDER BY pg_catalog.float_ops ,
    OPERATOR 14 <#>(geometry,geometry) FOR ORDER BY pg_catalog.float_ops ,
    FUNCTION 1 geometry_gist_consistent_2d(internal,geometry,integer) ,
    FUNCTION 2 geometry_gist_union_2d(bytea,internal) ,
    FUNCTION 3 geometry_gist_compress_2d(internal) ,
    FUNCTION 4 geometry_gist_decompress_2d(internal) ,
    FUNCTION 5 geometry_gist_penalty_2d(internal,internal,internal) ,
    FUNCTION 6 geometry_gist_picksplit_2d(internal,internal) ,
    FUNCTION 7 geometry_gist_same_2d(geometry,geometry,internal) ,
    FUNCTION 8 geometry_gist_distance_2d(internal,geometry,integer);


ALTER OPERATOR CLASS public.gist_geometry_ops_2d USING gist OWNER TO postgres;

--
-- Name: gist_geometry_ops_nd; Type: OPERATOR CLASS; Schema: public; Owner: postgres
--

CREATE OPERATOR CLASS gist_geometry_ops_nd
    FOR TYPE geometry USING gist AS
    STORAGE gidx ,
    OPERATOR 3 &&&(geometry,geometry) ,
    FUNCTION 1 geometry_gist_consistent_nd(internal,geometry,integer) ,
    FUNCTION 2 geometry_gist_union_nd(bytea,internal) ,
    FUNCTION 3 geometry_gist_compress_nd(internal) ,
    FUNCTION 4 geometry_gist_decompress_nd(internal) ,
    FUNCTION 5 geometry_gist_penalty_nd(internal,internal,internal) ,
    FUNCTION 6 geometry_gist_picksplit_nd(internal,internal) ,
    FUNCTION 7 geometry_gist_same_nd(geometry,geometry,internal);


ALTER OPERATOR CLASS public.gist_geometry_ops_nd USING gist OWNER TO postgres;

SET search_path = pg_catalog;

--
-- Name: CAST (public.box2d AS public.box3d); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.box2d AS public.box3d) WITH FUNCTION public.box3d(public.box2d) AS IMPLICIT;


--
-- Name: CAST (public.box2d AS public.geometry); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.box2d AS public.geometry) WITH FUNCTION public.geometry(public.box2d) AS IMPLICIT;


--
-- Name: CAST (public.box3d AS box); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.box3d AS box) WITH FUNCTION public.box(public.box3d) AS IMPLICIT;


--
-- Name: CAST (public.box3d AS public.box2d); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.box3d AS public.box2d) WITH FUNCTION public.box2d(public.box3d) AS IMPLICIT;


--
-- Name: CAST (public.box3d AS public.geometry); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.box3d AS public.geometry) WITH FUNCTION public.geometry(public.box3d) AS IMPLICIT;


--
-- Name: CAST (bytea AS public.geography); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (bytea AS public.geography) WITH FUNCTION public.geography(bytea) AS IMPLICIT;


--
-- Name: CAST (bytea AS public.geometry); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (bytea AS public.geometry) WITH FUNCTION public.geometry(bytea) AS IMPLICIT;


--
-- Name: CAST (public.geography AS bytea); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.geography AS bytea) WITH FUNCTION public.bytea(public.geography) AS IMPLICIT;


--
-- Name: CAST (public.geography AS public.geography); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.geography AS public.geography) WITH FUNCTION public.geography(public.geography, integer, boolean) AS IMPLICIT;


--
-- Name: CAST (public.geography AS public.geometry); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.geography AS public.geometry) WITH FUNCTION public.geometry(public.geography);


--
-- Name: CAST (public.geometry AS box); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.geometry AS box) WITH FUNCTION public.box(public.geometry) AS IMPLICIT;


--
-- Name: CAST (public.geometry AS public.box2d); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.geometry AS public.box2d) WITH FUNCTION public.box2d(public.geometry) AS IMPLICIT;


--
-- Name: CAST (public.geometry AS public.box3d); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.geometry AS public.box3d) WITH FUNCTION public.box3d(public.geometry) AS IMPLICIT;


--
-- Name: CAST (public.geometry AS bytea); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.geometry AS bytea) WITH FUNCTION public.bytea(public.geometry) AS IMPLICIT;


--
-- Name: CAST (public.geometry AS public.geography); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.geometry AS public.geography) WITH FUNCTION public.geography(public.geometry) AS IMPLICIT;


--
-- Name: CAST (public.geometry AS public.geometry); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.geometry AS public.geometry) WITH FUNCTION public.geometry(public.geometry, integer, boolean) AS IMPLICIT;


--
-- Name: CAST (public.geometry AS text); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.geometry AS text) WITH FUNCTION public.text(public.geometry) AS IMPLICIT;


--
-- Name: CAST (text AS public.geometry); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (text AS public.geometry) WITH FUNCTION public.geometry(text) AS IMPLICIT;


SET search_path = main, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: im_building; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_building (
    nid bigint NOT NULL,
    area integer,
    volume integer,
    hrsz_eoi text,
    projection bigint NOT NULL,
    model bigint,
    im_settlement text NOT NULL,
    hrsz_main integer NOT NULL,
    hrsz_fraction integer,
    title_angle numeric(4,2),
    share_denominator integer
);


ALTER TABLE main.im_building OWNER TO tdc;

--
-- Name: TABLE im_building; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_building IS 'Az épületeket reprezentáló tábla';


--
-- Name: im_building_individual_unit; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_building_individual_unit (
    nid bigint NOT NULL,
    im_building bigint NOT NULL,
    hrsz_unit integer NOT NULL,
    model bigint,
    share_numerator integer NOT NULL
);


ALTER TABLE main.im_building_individual_unit OWNER TO tdc;

--
-- Name: TABLE im_building_individual_unit; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_building_individual_unit IS 'A társasházakban elhelyezkedő önállóan forgalomképes ingatlanok, lakások, üzlethelyiségek';


--
-- Name: im_building_individual_unit_level; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_building_individual_unit_level (
    im_building bigint NOT NULL,
    hrsz_unit integer NOT NULL,
    projection bigint,
    im_levels numeric(4,2) NOT NULL,
    area numeric(12,1),
    volume numeric(12,1)
);


ALTER TABLE main.im_building_individual_unit_level OWNER TO tdc;

--
-- Name: TABLE im_building_individual_unit_level; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_building_individual_unit_level IS 'Társasházban található önálóan forgalomképes helyiségek szintjeit határozza meg. (mivel egy helyiség akár több szinten is elhelyezkedhet)';


--
-- Name: im_building_individual_unit_nid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE im_building_individual_unit_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.im_building_individual_unit_nid_seq OWNER TO tdc;

--
-- Name: im_building_individual_unit_nid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE im_building_individual_unit_nid_seq OWNED BY im_building_individual_unit.nid;


--
-- Name: im_building_level_unit; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_building_level_unit (
    im_building bigint NOT NULL,
    im_levels bigint NOT NULL,
    area numeric(12,1),
    volume numeric(12,1),
    model bigint
);


ALTER TABLE main.im_building_level_unit OWNER TO tdc;

--
-- Name: TABLE im_building_level_unit; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_building_level_unit IS 'Egy szintet képvisel egy családi háznál';


--
-- Name: im_building_level_unig_volume_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE im_building_level_unig_volume_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.im_building_level_unig_volume_seq OWNER TO tdc;

--
-- Name: im_building_level_unig_volume_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE im_building_level_unig_volume_seq OWNED BY im_building_level_unit.volume;


--
-- Name: im_building_levels; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_building_levels (
    im_building bigint NOT NULL,
    im_levels bigint NOT NULL,
    projection bigint NOT NULL
);


ALTER TABLE main.im_building_levels OWNER TO tdc;

--
-- Name: TABLE im_building_levels; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_building_levels IS 'Egy adott épületen belül előforduló szintek';


--
-- Name: im_building_nid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE im_building_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.im_building_nid_seq OWNER TO tdc;

--
-- Name: im_building_nid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE im_building_nid_seq OWNED BY im_building.nid;


--
-- Name: im_building_shared_unit; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_building_shared_unit (
    im_building bigint NOT NULL,
    name text NOT NULL,
    model bigint
);


ALTER TABLE main.im_building_shared_unit OWNER TO tdc;

--
-- Name: TABLE im_building_shared_unit; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_building_shared_unit IS 'A társasházak közös helyiségei';


--
-- Name: im_levels; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_levels (
    name text NOT NULL,
    nid numeric(4,1) NOT NULL
);


ALTER TABLE main.im_levels OWNER TO tdc;

--
-- Name: TABLE im_levels; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_levels IS 'Az összes előforduló szint megnevezése az épületekben';


--
-- Name: im_levels_nid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE im_levels_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.im_levels_nid_seq OWNER TO tdc;

--
-- Name: im_levels_nid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE im_levels_nid_seq OWNED BY im_levels.nid;


--
-- Name: im_parcel; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_parcel (
    nid bigint NOT NULL,
    area numeric(12,1) NOT NULL,
    im_settlement text NOT NULL,
    hrsz_main integer NOT NULL,
    hrsz_fraction integer,
    projection bigint NOT NULL,
    model bigint,
    title_angle numeric(4,2) DEFAULT 0
);


ALTER TABLE main.im_parcel OWNER TO tdc;

--
-- Name: TABLE im_parcel; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_parcel IS 'Ez az ugynevezett földrészlet.
Az im_parcel-ek topologiát alkotnak';


--
-- Name: COLUMN im_parcel.title_angle; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON COLUMN im_parcel.title_angle IS 'A helyrajziszám dőlésszöge';


--
-- Name: im_settlement; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_settlement (
    name text NOT NULL
);


ALTER TABLE main.im_settlement OWNER TO tdc;

--
-- Name: TABLE im_settlement; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_settlement IS 'Magyarorszag településeinek neve';


--
-- Name: im_shared_unit_level; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_shared_unit_level (
    im_building bigint NOT NULL,
    im_levels text NOT NULL,
    shared_unit_name text NOT NULL,
    projection bigint
);


ALTER TABLE main.im_shared_unit_level OWNER TO tdc;

--
-- Name: TABLE im_shared_unit_level; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_shared_unit_level IS 'Társasházakban a közös helyiségek, fő épületszerkezeti elemek szintjeit határozza meg. (mivel a közös helyiségek akár több szinten is elhelyezkedhetnek)';


--
-- Name: im_underpass; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass (
    nid bigint NOT NULL,
    volume integer,
    area integer,
    hrsz_settlement text NOT NULL,
    hrsz_main integer NOT NULL,
    hrsz_parcial integer,
    projection bigint NOT NULL,
    model bigint
);


ALTER TABLE main.im_underpass OWNER TO tdc;

--
-- Name: TABLE im_underpass; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_underpass IS 'Aluljárók tábla.
EÖI tehát település+fő/alátört helyrajzi szám az azonosítója.
Rendelkeznie kell vetülettel és lehetőség szerint 3D modellel is';


--
-- Name: im_underpass_block; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass_block (
    nid bigint NOT NULL,
    hrsz_eoi text NOT NULL,
    im_underpass bigint NOT NULL
);


ALTER TABLE main.im_underpass_block OWNER TO tdc;

--
-- Name: TABLE im_underpass_block; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_underpass_block IS 'Ezek az objektumok foglaljak egybe az aluljáróban található üzleteket. Tulajdonképpen analógok a Building-gel társasház esetén';


--
-- Name: im_underpass_individual_unit; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass_individual_unit (
    nid bigint NOT NULL,
    im_underpass_block bigint NOT NULL,
    hrsz_unit integer NOT NULL,
    area numeric(12,1),
    volume numeric(12,1)
);


ALTER TABLE main.im_underpass_individual_unit OWNER TO tdc;

--
-- Name: TABLE im_underpass_individual_unit; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_underpass_individual_unit IS 'Ezek az ingatlantípusok az aluljárókban lévő üzletek. 
EÖI';


SET default_with_oids = true;

--
-- Name: im_underpass_individual_unit_level; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass_individual_unit_level (
    im_underpass_block bigint NOT NULL,
    hrsz_unit integer NOT NULL,
    im_levels numeric(4,1) NOT NULL,
    area integer,
    volume integer,
    projection bigint
);


ALTER TABLE main.im_underpass_individual_unit_level OWNER TO tdc;

--
-- Name: TABLE im_underpass_individual_unit_level; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_underpass_individual_unit_level IS 'Aluljárókban található üzlethelyiségek egy szintjét reprezentálja (mivel egy üzlet akár több szinten is elhelyezkedhet)';


--
-- Name: im_underpass_individual_unit_nid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE im_underpass_individual_unit_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.im_underpass_individual_unit_nid_seq OWNER TO tdc;

--
-- Name: im_underpass_individual_unit_nid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE im_underpass_individual_unit_nid_seq OWNED BY im_underpass_individual_unit.nid;


SET default_with_oids = false;

--
-- Name: im_underpass_levels; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass_levels (
    im_underpass_block bigint NOT NULL,
    im_levels numeric(4,1) NOT NULL,
    projection bigint
);


ALTER TABLE main.im_underpass_levels OWNER TO tdc;

--
-- Name: TABLE im_underpass_levels; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_underpass_levels IS 'Egy adott aluljáróban előforduló szintek felsorolása';


--
-- Name: im_underpass_shared_unit; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass_shared_unit (
    im_underpass_block bigint NOT NULL,
    name text NOT NULL
);


ALTER TABLE main.im_underpass_shared_unit OWNER TO tdc;

--
-- Name: TABLE im_underpass_shared_unit; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_underpass_shared_unit IS 'Ez az egység reprezentálja az aluljáróban lévő üzletek közös részét -ami mindenkihez tartozik és közösen fizetik a fenntartási költségeit';


--
-- Name: pn_person; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE pn_person (
    nid bigint NOT NULL,
    name text NOT NULL
);


ALTER TABLE main.pn_person OWNER TO tdc;

--
-- Name: TABLE pn_person; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE pn_person IS 'Ez a személyeket tartalmazó tábla. Ide tartoznak természtes és jogi személyek is';


--
-- Name: rt_legal_document; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE rt_legal_document (
    nid bigint NOT NULL,
    content text NOT NULL,
    date date NOT NULL,
    sale_price numeric(12,2)
);


ALTER TABLE main.rt_legal_document OWNER TO tdc;

--
-- Name: TABLE rt_legal_document; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE rt_legal_document IS 'Azon dokumentumok, melyek alapján egy személy valamilyen jogi kapcsolatba került egy ingatlannal';


--
-- Name: rt_legal_document_nid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE rt_legal_document_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.rt_legal_document_nid_seq OWNER TO tdc;

--
-- Name: rt_legal_document_nid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE rt_legal_document_nid_seq OWNED BY rt_legal_document.nid;


--
-- Name: rt_right; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE rt_right (
    pn_person bigint NOT NULL,
    rt_legal_document bigint NOT NULL,
    im_parcel bigint,
    im_building bigint,
    im_building_individual_unit bigint,
    im_underpass_individual_unit bigint,
    im_underpass bigint,
    share_numerator integer,
    share_denominator integer,
    rt_type bigint NOT NULL
);


ALTER TABLE main.rt_right OWNER TO tdc;

--
-- Name: TABLE rt_right; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE rt_right IS 'Jogok. Ez a tábla köti össze a személyt egy ingatlannal valamilyen jogi dokumentum alapján. ';


--
-- Name: rt_type; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE rt_type (
    name text NOT NULL,
    nid bigint NOT NULL
);


ALTER TABLE main.rt_type OWNER TO tdc;

--
-- Name: TABLE rt_type; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE rt_type IS 'Itt szerepelnek azok a jogok, melyek alapján egy személy kapcsolatba kerülhet egy ingatlannal';


--
-- Name: sv_point; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE sv_point (
    nid bigint NOT NULL,
    sv_survey_point bigint NOT NULL,
    sv_survey_document bigint NOT NULL,
    x numeric(8,2) NOT NULL,
    y numeric(8,2) NOT NULL,
    h numeric(8,2),
    dimension integer DEFAULT 3 NOT NULL,
    quality integer,
    CONSTRAINT sv_point_check_dimension CHECK ((dimension = ANY (ARRAY[2, 3])))
);


ALTER TABLE main.sv_point OWNER TO tdc;

--
-- Name: TABLE sv_point; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE sv_point IS 'Mért pont. Lehet 2 és 3 dimenziós is';


--
-- Name: sv_point_nid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE sv_point_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.sv_point_nid_seq OWNER TO tdc;

--
-- Name: sv_point_nid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE sv_point_nid_seq OWNED BY sv_point.nid;


--
-- Name: sv_survey_document; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE sv_survey_document (
    nid bigint NOT NULL,
    date date DEFAULT ('now'::text)::date NOT NULL,
    data text
);


ALTER TABLE main.sv_survey_document OWNER TO tdc;

--
-- Name: TABLE sv_survey_document; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE sv_survey_document IS 'Mérési jegyzőkönyv a felmért pontok számára';


--
-- Name: sv_survey_document_nid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE sv_survey_document_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.sv_survey_document_nid_seq OWNER TO tdc;

--
-- Name: sv_survey_document_nid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE sv_survey_document_nid_seq OWNED BY sv_survey_document.nid;


--
-- Name: sv_survey_point; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE sv_survey_point (
    nid bigint NOT NULL,
    description text,
    name text NOT NULL
);


ALTER TABLE main.sv_survey_point OWNER TO tdc;

--
-- Name: TABLE sv_survey_point; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE sv_survey_point IS 'Mérési pont azonosítása és leírása';


--
-- Name: sv_survey_point_nid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE sv_survey_point_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.sv_survey_point_nid_seq OWNER TO tdc;

--
-- Name: sv_survey_point_nid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE sv_survey_point_nid_seq OWNED BY sv_survey_point.nid;


SET default_with_oids = true;

--
-- Name: tp_face; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE tp_face (
    gid bigint NOT NULL,
    nodelist bigint[] NOT NULL,
    geom public.geometry(PolygonZ),
    holelist bigint[],
    note text
);


ALTER TABLE main.tp_face OWNER TO tdc;

--
-- Name: TABLE tp_face; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE tp_face IS 'Felület. Pontjait a tp_node elemei alkotják';


--
-- Name: tp_face_gid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE tp_face_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.tp_face_gid_seq OWNER TO tdc;

--
-- Name: tp_face_gid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE tp_face_gid_seq OWNED BY tp_face.gid;


--
-- Name: tp_node; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE tp_node (
    gid bigint NOT NULL,
    geom public.geometry(PointZ),
    note text
);


ALTER TABLE main.tp_node OWNER TO tdc;

--
-- Name: TABLE tp_node; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE tp_node IS 'Csomópont. Egy sv_survey_point-ot azonosít. Van geometriája, mely mindig a dátum szerinti aktuális sv_point adatait tartalmazza.';


--
-- Name: tp_node_gid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE tp_node_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.tp_node_gid_seq OWNER TO tdc;

--
-- Name: tp_node_gid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE tp_node_gid_seq OWNED BY tp_node.gid;


--
-- Name: tp_volume; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE tp_volume (
    gid bigint NOT NULL,
    facelist bigint[] NOT NULL,
    note text,
    geom public.geometry(PolyhedralSurfaceZ)
);


ALTER TABLE main.tp_volume OWNER TO tdc;

--
-- Name: TABLE tp_volume; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE tp_volume IS '3D-s térfogati elem. tp_face-ek írják le';


--
-- Name: tp_volume_gid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE tp_volume_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.tp_volume_gid_seq OWNER TO tdc;

--
-- Name: tp_volume_gid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE tp_volume_gid_seq OWNED BY tp_volume.gid;


SET search_path = public, pg_catalog;

--
-- Name: geography_columns; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW geography_columns AS
    SELECT current_database() AS f_table_catalog, n.nspname AS f_table_schema, c.relname AS f_table_name, a.attname AS f_geography_column, postgis_typmod_dims(a.atttypmod) AS coord_dimension, postgis_typmod_srid(a.atttypmod) AS srid, postgis_typmod_type(a.atttypmod) AS type FROM pg_class c, pg_attribute a, pg_type t, pg_namespace n WHERE (((((((t.typname = 'geography'::name) AND (a.attisdropped = false)) AND (a.atttypid = t.oid)) AND (a.attrelid = c.oid)) AND (c.relnamespace = n.oid)) AND (NOT pg_is_other_temp_schema(c.relnamespace))) AND has_table_privilege(c.oid, 'SELECT'::text));


ALTER TABLE public.geography_columns OWNER TO postgres;

--
-- Name: geometry_columns; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW geometry_columns AS
    SELECT (current_database())::character varying(256) AS f_table_catalog, (n.nspname)::character varying(256) AS f_table_schema, (c.relname)::character varying(256) AS f_table_name, (a.attname)::character varying(256) AS f_geometry_column, COALESCE(NULLIF(postgis_typmod_dims(a.atttypmod), 2), postgis_constraint_dims((n.nspname)::text, (c.relname)::text, (a.attname)::text), 2) AS coord_dimension, COALESCE(NULLIF(postgis_typmod_srid(a.atttypmod), 0), postgis_constraint_srid((n.nspname)::text, (c.relname)::text, (a.attname)::text), 0) AS srid, (replace(replace(COALESCE(NULLIF(upper(postgis_typmod_type(a.atttypmod)), 'GEOMETRY'::text), (postgis_constraint_type((n.nspname)::text, (c.relname)::text, (a.attname)::text))::text, 'GEOMETRY'::text), 'ZM'::text, ''::text), 'Z'::text, ''::text))::character varying(30) AS type FROM pg_class c, pg_attribute a, pg_type t, pg_namespace n WHERE (((((((((t.typname = 'geometry'::name) AND (a.attisdropped = false)) AND (a.atttypid = t.oid)) AND (a.attrelid = c.oid)) AND (c.relnamespace = n.oid)) AND ((c.relkind = 'r'::"char") OR (c.relkind = 'v'::"char"))) AND (NOT pg_is_other_temp_schema(c.relnamespace))) AND (NOT ((n.nspname = 'public'::name) AND (c.relname = 'raster_columns'::name)))) AND has_table_privilege(c.oid, 'SELECT'::text));


ALTER TABLE public.geometry_columns OWNER TO postgres;

SET default_with_oids = false;

--
-- Name: spatial_ref_sys; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE spatial_ref_sys (
    srid integer NOT NULL,
    auth_name character varying(256),
    auth_srid integer,
    srtext character varying(2048),
    proj4text character varying(2048),
    CONSTRAINT spatial_ref_sys_srid_check CHECK (((srid > 0) AND (srid <= 998999)))
);


ALTER TABLE public.spatial_ref_sys OWNER TO postgres;

SET search_path = main, pg_catalog;

--
-- Name: nid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building ALTER COLUMN nid SET DEFAULT nextval('im_building_nid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_individual_unit ALTER COLUMN nid SET DEFAULT nextval('im_building_individual_unit_nid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_individual_unit ALTER COLUMN nid SET DEFAULT nextval('im_underpass_individual_unit_nid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY rt_legal_document ALTER COLUMN nid SET DEFAULT nextval('rt_legal_document_nid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY sv_point ALTER COLUMN nid SET DEFAULT nextval('sv_point_nid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY sv_survey_document ALTER COLUMN nid SET DEFAULT nextval('sv_survey_document_nid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY tp_face ALTER COLUMN gid SET DEFAULT nextval('tp_face_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY tp_volume ALTER COLUMN gid SET DEFAULT nextval('tp_volume_gid_seq'::regclass);


--
-- Name: Tableim_building_individual_unit_level_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building_individual_unit_level
    ADD CONSTRAINT "Tableim_building_individual_unit_level_pkey" PRIMARY KEY (im_building, hrsz_unit, im_levels);


--
-- Name: im_building_individual_unit_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building_individual_unit
    ADD CONSTRAINT im_building_individual_unit_pkey PRIMARY KEY (nid);


--
-- Name: im_building_individual_unit_unique_im_building_hrsz_unit; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building_individual_unit
    ADD CONSTRAINT im_building_individual_unit_unique_im_building_hrsz_unit UNIQUE (im_building, hrsz_unit);


--
-- Name: im_building_level_unit_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building_level_unit
    ADD CONSTRAINT im_building_level_unit_pkey PRIMARY KEY (im_building, im_levels);


--
-- Name: im_building_levels_fkey_im_building_im_levels; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building_levels
    ADD CONSTRAINT im_building_levels_fkey_im_building_im_levels PRIMARY KEY (im_building, im_levels);


--
-- Name: im_building_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building
    ADD CONSTRAINT im_building_pkey PRIMARY KEY (nid);


--
-- Name: im_building_shared_unit_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building_shared_unit
    ADD CONSTRAINT im_building_shared_unit_pkey PRIMARY KEY (im_building, name);


--
-- Name: im_building_unique_im_settlement_hrsz_main_hrsz_fraction; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building
    ADD CONSTRAINT im_building_unique_im_settlement_hrsz_main_hrsz_fraction UNIQUE (im_settlement, hrsz_main, hrsz_fraction);


--
-- Name: im_building_unique_model; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building
    ADD CONSTRAINT im_building_unique_model UNIQUE (model);


--
-- Name: im_building_unique_projection; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building
    ADD CONSTRAINT im_building_unique_projection UNIQUE (projection);


--
-- Name: im_levels_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_levels
    ADD CONSTRAINT im_levels_pkey PRIMARY KEY (nid);


--
-- Name: im_levels_unique_name; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_levels
    ADD CONSTRAINT im_levels_unique_name UNIQUE (name);


--
-- Name: im_parcel_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_pkey PRIMARY KEY (nid);


--
-- Name: im_parcel_unique_hrsz_settlement_hrsz_main_hrsz_partial; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_unique_hrsz_settlement_hrsz_main_hrsz_partial UNIQUE (im_settlement, hrsz_main, hrsz_fraction);


--
-- Name: im_parcel_unique_model; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_unique_model UNIQUE (model);


--
-- Name: im_parcel_unique_projection; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_unique_projection UNIQUE (projection);


--
-- Name: im_settlement_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_settlement
    ADD CONSTRAINT im_settlement_pkey PRIMARY KEY (name);


--
-- Name: im_shared_unit_level_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_shared_unit_level
    ADD CONSTRAINT im_shared_unit_level_pkey PRIMARY KEY (im_building, im_levels, shared_unit_name);


--
-- Name: im_underpass_individual_unit_level_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_individual_unit_level
    ADD CONSTRAINT im_underpass_individual_unit_level_pkey PRIMARY KEY (im_underpass_block);


--
-- Name: im_underpass_individual_unit_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_individual_unit
    ADD CONSTRAINT im_underpass_individual_unit_pkey PRIMARY KEY (nid);


--
-- Name: im_underpass_individual_unit_unique_im_underpass_unit_hrsz_unit; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_individual_unit
    ADD CONSTRAINT im_underpass_individual_unit_unique_im_underpass_unit_hrsz_unit UNIQUE (im_underpass_block, hrsz_unit);


--
-- Name: im_underpass_levels_pkey_im_underpass_block_im_levels; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_levels
    ADD CONSTRAINT im_underpass_levels_pkey_im_underpass_block_im_levels PRIMARY KEY (im_underpass_block, im_levels);


--
-- Name: im_underpass_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_pkey PRIMARY KEY (nid);


--
-- Name: im_underpass_shared_unit_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_shared_unit
    ADD CONSTRAINT im_underpass_shared_unit_pkey PRIMARY KEY (im_underpass_block);


--
-- Name: im_underpass_shared_unit_unique_im_underpass_unit_name; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_shared_unit
    ADD CONSTRAINT im_underpass_shared_unit_unique_im_underpass_unit_name UNIQUE (im_underpass_block, name);


--
-- Name: im_underpass_unigue_projection; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_unigue_projection UNIQUE (projection);


--
-- Name: im_underpass_unique_hrsz_settlement_hrsz_main_hrsz_parcial; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_unique_hrsz_settlement_hrsz_main_hrsz_parcial UNIQUE (hrsz_settlement, hrsz_main, hrsz_parcial);


--
-- Name: im_underpass_unique_model; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_unique_model UNIQUE (model);


--
-- Name: im_underpass_unit_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_block
    ADD CONSTRAINT im_underpass_unit_pkey PRIMARY KEY (nid);


--
-- Name: im_underpass_unit_unique_im_underpass_hrsz_eoi; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_block
    ADD CONSTRAINT im_underpass_unit_unique_im_underpass_hrsz_eoi UNIQUE (im_underpass, hrsz_eoi);


--
-- Name: pn_person_name_key; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY pn_person
    ADD CONSTRAINT pn_person_name_key UNIQUE (name);


--
-- Name: pn_person_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY pn_person
    ADD CONSTRAINT pn_person_pkey PRIMARY KEY (nid);


--
-- Name: rt_legal_document_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY rt_legal_document
    ADD CONSTRAINT rt_legal_document_pkey PRIMARY KEY (nid);


--
-- Name: rt_type_pkey_nid; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY rt_type
    ADD CONSTRAINT rt_type_pkey_nid PRIMARY KEY (nid);


--
-- Name: rt_type_unique_name; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY rt_type
    ADD CONSTRAINT rt_type_unique_name UNIQUE (name);


--
-- Name: sv_point_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY sv_point
    ADD CONSTRAINT sv_point_pkey PRIMARY KEY (nid);


--
-- Name: sv_point_unique_sv_survey_point_sv_survey_document; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY sv_point
    ADD CONSTRAINT sv_point_unique_sv_survey_point_sv_survey_document UNIQUE (sv_survey_point, sv_survey_document);


--
-- Name: sv_survey_document_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY sv_survey_document
    ADD CONSTRAINT sv_survey_document_pkey PRIMARY KEY (nid);


--
-- Name: sv_survey_point_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY sv_survey_point
    ADD CONSTRAINT sv_survey_point_pkey PRIMARY KEY (nid);


--
-- Name: tp_face_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_face
    ADD CONSTRAINT tp_face_pkey PRIMARY KEY (gid);


--
-- Name: tp_face_unique_nodelist; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_face
    ADD CONSTRAINT tp_face_unique_nodelist UNIQUE (nodelist);


--
-- Name: tp_node_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_node
    ADD CONSTRAINT tp_node_pkey PRIMARY KEY (gid);


--
-- Name: tp_volume_facelist_key; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_volume
    ADD CONSTRAINT tp_volume_facelist_key UNIQUE (facelist);


--
-- Name: tp_volume_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_volume
    ADD CONSTRAINT tp_volume_pkey PRIMARY KEY (gid);


SET search_path = public, pg_catalog;

--
-- Name: spatial_ref_sys_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY spatial_ref_sys
    ADD CONSTRAINT spatial_ref_sys_pkey PRIMARY KEY (srid);


SET search_path = main, pg_catalog;

--
-- Name: tp_face_idx_holelist; Type: INDEX; Schema: main; Owner: tdc; Tablespace: 
--

CREATE INDEX tp_face_idx_holelist ON tp_face USING gin (holelist);


--
-- Name: tp_face_idx_nodelist; Type: INDEX; Schema: main; Owner: tdc; Tablespace: 
--

CREATE INDEX tp_face_idx_nodelist ON tp_face USING gin (nodelist);


--
-- Name: tp_volume_idx_facelist; Type: INDEX; Schema: main; Owner: tdc; Tablespace: 
--

CREATE INDEX tp_volume_idx_facelist ON tp_volume USING gin (facelist);


SET search_path = public, pg_catalog;

--
-- Name: geometry_columns_delete; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE geometry_columns_delete AS ON DELETE TO geometry_columns DO INSTEAD NOTHING;


--
-- Name: geometry_columns_insert; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE geometry_columns_insert AS ON INSERT TO geometry_columns DO INSTEAD NOTHING;


--
-- Name: geometry_columns_update; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE geometry_columns_update AS ON UPDATE TO geometry_columns DO INSTEAD NOTHING;


SET search_path = main, pg_catalog;

--
-- Name: sv_point_after_trigger; Type: TRIGGER; Schema: main; Owner: tdc
--

CREATE TRIGGER sv_point_after_trigger AFTER INSERT OR DELETE OR UPDATE ON sv_point FOR EACH ROW EXECUTE PROCEDURE sv_point_after();


--
-- Name: sv_point_before_trigger; Type: TRIGGER; Schema: main; Owner: tdc
--

CREATE TRIGGER sv_point_before_trigger BEFORE INSERT OR UPDATE ON sv_point FOR EACH ROW EXECUTE PROCEDURE sv_point_before();


--
-- Name: tp_face_after_trigger; Type: TRIGGER; Schema: main; Owner: tdc
--

CREATE TRIGGER tp_face_after_trigger AFTER INSERT OR DELETE OR UPDATE ON tp_face FOR EACH ROW EXECUTE PROCEDURE tp_face_after();


--
-- Name: tp_face_before_trigger; Type: TRIGGER; Schema: main; Owner: tdc
--

CREATE TRIGGER tp_face_before_trigger BEFORE INSERT OR UPDATE ON tp_face FOR EACH ROW EXECUTE PROCEDURE tp_face_before();


--
-- Name: tp_node_after_trigger; Type: TRIGGER; Schema: main; Owner: tdc
--

CREATE TRIGGER tp_node_after_trigger BEFORE INSERT OR DELETE OR UPDATE ON tp_node FOR EACH ROW EXECUTE PROCEDURE tp_node_after();


--
-- Name: tp_node_before_trigger; Type: TRIGGER; Schema: main; Owner: tdc
--

CREATE TRIGGER tp_node_before_trigger BEFORE INSERT OR UPDATE ON tp_node FOR EACH ROW EXECUTE PROCEDURE tp_node_before();


--
-- Name: tp_volume_before_trigger; Type: TRIGGER; Schema: main; Owner: tdc
--

CREATE TRIGGER tp_volume_before_trigger BEFORE INSERT OR UPDATE ON tp_volume FOR EACH ROW EXECUTE PROCEDURE tp_volume_before();


--
-- Name: Tableim_building_individual_unit_level_fkey_im_levles; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_individual_unit_level
    ADD CONSTRAINT "Tableim_building_individual_unit_level_fkey_im_levles" FOREIGN KEY (im_levels) REFERENCES im_levels(nid);


--
-- Name: Tableim_building_level_unit_fkey_im_building_im_levels; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_level_unit
    ADD CONSTRAINT "Tableim_building_level_unit_fkey_im_building_im_levels" FOREIGN KEY (im_building, im_levels) REFERENCES im_building_levels(im_building, im_levels);


--
-- Name: im_building_individual_unit_fkey_im_building; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_individual_unit
    ADD CONSTRAINT im_building_individual_unit_fkey_im_building FOREIGN KEY (im_building) REFERENCES im_building(nid);


--
-- Name: im_building_individual_unit_fkey_model; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_individual_unit
    ADD CONSTRAINT im_building_individual_unit_fkey_model FOREIGN KEY (model) REFERENCES tp_volume(gid);


--
-- Name: im_building_individual_unit_level_fkey_projection; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_individual_unit_level
    ADD CONSTRAINT im_building_individual_unit_level_fkey_projection FOREIGN KEY (projection) REFERENCES tp_face(gid);


--
-- Name: im_building_level_unit_fkey_im_building; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_level_unit
    ADD CONSTRAINT im_building_level_unit_fkey_im_building FOREIGN KEY (im_building) REFERENCES im_building(nid);


--
-- Name: im_building_level_unit_fkey_model; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_level_unit
    ADD CONSTRAINT im_building_level_unit_fkey_model FOREIGN KEY (model) REFERENCES tp_volume(gid);


--
-- Name: im_building_levels_fkey_im_building; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_levels
    ADD CONSTRAINT im_building_levels_fkey_im_building FOREIGN KEY (im_building) REFERENCES im_building(nid);


--
-- Name: im_building_levles_fkey_im_levles; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_levels
    ADD CONSTRAINT im_building_levles_fkey_im_levles FOREIGN KEY (im_levels) REFERENCES im_levels(nid);


--
-- Name: im_building_levles_fkey_projection; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_levels
    ADD CONSTRAINT im_building_levles_fkey_projection FOREIGN KEY (projection) REFERENCES tp_face(gid);


--
-- Name: im_building_shared_unit_fkey_im_building; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_shared_unit
    ADD CONSTRAINT im_building_shared_unit_fkey_im_building FOREIGN KEY (im_building) REFERENCES im_building(nid);


--
-- Name: im_individual_unit_level_fkey_im_building_hrsz_unit; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_individual_unit_level
    ADD CONSTRAINT im_individual_unit_level_fkey_im_building_hrsz_unit FOREIGN KEY (im_building, hrsz_unit) REFERENCES im_building_individual_unit(im_building, hrsz_unit);


--
-- Name: im_parcel_fkey_settlement; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_fkey_settlement FOREIGN KEY (im_settlement) REFERENCES im_settlement(name);


--
-- Name: im_shared_unit_level_fkey_im_building_name; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_shared_unit_level
    ADD CONSTRAINT im_shared_unit_level_fkey_im_building_name FOREIGN KEY (im_building, shared_unit_name) REFERENCES im_building_shared_unit(im_building, name);


--
-- Name: im_underpass_fkey_settlement; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_fkey_settlement FOREIGN KEY (hrsz_settlement) REFERENCES im_settlement(name);


--
-- Name: im_underpass_individual_unit_fkey_im_underpass_unit; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_individual_unit
    ADD CONSTRAINT im_underpass_individual_unit_fkey_im_underpass_unit FOREIGN KEY (im_underpass_block) REFERENCES im_underpass_block(nid);


--
-- Name: im_underpass_individual_unit_level_fkey_im_underpass_leveles; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_individual_unit_level
    ADD CONSTRAINT im_underpass_individual_unit_level_fkey_im_underpass_leveles FOREIGN KEY (im_underpass_block, im_levels) REFERENCES im_underpass_levels(im_underpass_block, im_levels);


--
-- Name: im_underpass_individual_unit_level_fkey_projection; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_individual_unit_level
    ADD CONSTRAINT im_underpass_individual_unit_level_fkey_projection FOREIGN KEY (projection) REFERENCES tp_face(gid);


--
-- Name: im_underpass_levels_fkey_im_underpass_block; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_levels
    ADD CONSTRAINT im_underpass_levels_fkey_im_underpass_block FOREIGN KEY (im_underpass_block) REFERENCES im_underpass_block(nid);


--
-- Name: im_underpass_levels_fkey_projection; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_levels
    ADD CONSTRAINT im_underpass_levels_fkey_projection FOREIGN KEY (projection) REFERENCES tp_face(gid);


--
-- Name: im_underpass_shared_unit_fkey_im_underpass_unit; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_shared_unit
    ADD CONSTRAINT im_underpass_shared_unit_fkey_im_underpass_unit FOREIGN KEY (im_underpass_block) REFERENCES im_underpass_block(nid);


--
-- Name: im_underpass_unit_fkey_im_underpass; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_block
    ADD CONSTRAINT im_underpass_unit_fkey_im_underpass FOREIGN KEY (im_underpass) REFERENCES im_underpass(nid);


--
-- Name: rt_right_fkey_im_building; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_im_building FOREIGN KEY (im_building) REFERENCES im_building(nid);


--
-- Name: rt_right_fkey_im_building_individual_unit; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_im_building_individual_unit FOREIGN KEY (im_building_individual_unit) REFERENCES im_building_individual_unit(nid);


--
-- Name: rt_right_fkey_im_parcel; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_im_parcel FOREIGN KEY (im_parcel) REFERENCES im_parcel(nid);


--
-- Name: rt_right_fkey_im_underpass; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_im_underpass FOREIGN KEY (im_underpass) REFERENCES im_underpass(nid);


--
-- Name: rt_right_fkey_im_underpass_individual_unit; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_im_underpass_individual_unit FOREIGN KEY (im_underpass_individual_unit) REFERENCES im_underpass_individual_unit(nid);


--
-- Name: rt_right_fkey_pn_person; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_pn_person FOREIGN KEY (pn_person) REFERENCES pn_person(nid);


--
-- Name: rt_right_fkey_rt_legal_document; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_rt_legal_document FOREIGN KEY (rt_legal_document) REFERENCES rt_legal_document(nid);


--
-- Name: rt_right_fkey_rt_type; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_rt_type FOREIGN KEY (rt_type) REFERENCES rt_type(nid);


--
-- Name: sv_point_fkey_sv_survey_document; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY sv_point
    ADD CONSTRAINT sv_point_fkey_sv_survey_document FOREIGN KEY (sv_survey_document) REFERENCES sv_survey_document(nid);


--
-- Name: sv_point_fkey_sv_survey_point; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY sv_point
    ADD CONSTRAINT sv_point_fkey_sv_survey_point FOREIGN KEY (sv_survey_point) REFERENCES sv_survey_point(nid);


--
-- Name: tp_node_fkey_sv_survey_point; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY tp_node
    ADD CONSTRAINT tp_node_fkey_sv_survey_point FOREIGN KEY (gid) REFERENCES sv_survey_point(nid);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO PUBLIC;


SET search_path = public, pg_catalog;

--
-- Name: geometry_columns; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE geometry_columns FROM PUBLIC;
REVOKE ALL ON TABLE geometry_columns FROM postgres;
GRANT ALL ON TABLE geometry_columns TO postgres;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE geometry_columns TO PUBLIC;


--
-- Name: spatial_ref_sys; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE spatial_ref_sys FROM PUBLIC;
REVOKE ALL ON TABLE spatial_ref_sys FROM postgres;
GRANT ALL ON TABLE spatial_ref_sys TO postgres;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE spatial_ref_sys TO PUBLIC;


--
-- PostgreSQL database dump complete
--


