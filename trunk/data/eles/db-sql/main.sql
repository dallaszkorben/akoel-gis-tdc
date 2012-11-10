--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

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
  output main.identify_building_individual_unit%rowtype;
BEGIN

  FOR output IN
    SELECT DISTINCT
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
-- Name: query_x3d_building(integer, bigint); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION query_x3d_building(immovable_type integer, selected_nid bigint) RETURNS SETOF query_x3d
    LANGUAGE plpgsql
    AS $$

DECLARE
  output main.query_x3d%rowtype;
  name_parcel text = 'im_parcel';
  name_building text = 'im_building';
  name_building_individual_unit text = 'im_building_individual_unit';
  name_point text = 'sv_survey_point';


BEGIN

  --------------------------------------------------------------
  -- gemetria alapjan koti ossze a foldreszletet az epulettel --
  --------------------------------------------------------------
  CREATE TEMP TABLE parcel_building AS
  SELECT
      parcel.nid AS parcel,
      building.nid AS building
   FROM 
      main.im_building building,
      main.im_parcel parcel,
      main.tp_face building_projection,
      main.tp_face parcel_projection
   WHERE
      building.projection=building_projection.gid AND
      parcel.projection=parcel_projection.gid AND
      st_contains(parcel_projection.geom, building_projection.geom);
  




    -----------------------------------
    -- Épülethez tartozó Parcella(k) --
    -----------------------------------
    CREATE TEMP TABLE summary AS
    SELECT
      selected_nid AS query_base_nid,
      name_parcel AS query_object_name,
      parcel.nid AS query_object_nid,      
      main.hrsz_concat(parcel.hrsz_main,parcel.hrsz_fraction) AS query_object_title,
      FALSE AS query_object_selected,
      ST_asx3d(volume.geom) AS query_object_x3d
      
    FROM
      main.im_building building,      
      main.im_parcel parcel,
      main.tp_volume volume,
      parcel_building
    WHERE
      selected_nid=building.nid AND
      parcel_building.building=building.nid AND
      parcel.nid=parcel_building.parcel AND
      volume.gid=parcel.model
    UNION
    ---------------------------------------------
    -- Building parcellájához tartozó épületek --
    ---------------------------------------------  
    SELECT
      selected_nid AS query_base_nid,
      name_building AS query_object_name,
      building.nid AS query_object_nid,      
      main.hrsz_concat(building.hrsz_main,building.hrsz_fraction) || CASE WHEN immovable_type=3 THEN '/'||building.hrsz_eoi ELSE '' END  AS x3d_id,
      CASE WHEN building.nid=selected_nid THEN TRUE ELSE FALSE END AS query_object_selected,
      ST_asx3d(volume.geom) AS query_object_x3d
    FROM
      main.im_building building,      
      main.tp_volume volume,
      parcel_building con_for_building,
      parcel_building con_for_parcel
    WHERE
      con_for_building.building=selected_nid AND
      con_for_building.parcel=con_for_parcel.parcel AND
      con_for_parcel.building=building.nid AND
      building.model=volume.gid
    UNION
    -----------------------------------------------------
    -- Building parcellájához tartozó épületek pontjai --
    -----------------------------------------------------
    SELECT
      selected_nid AS query_base_nid,
      name_point AS query_object_name,
      point.nid AS query_object_nid,      
      point.name  AS x3d_id,
      FALSE as query_object_selected,
      ST_X(node.geom) ||' ' || ST_Y(node.geom) || ' ' || ST_Z(node.geom)  AS query_object_x3d
    FROM
      main.im_building building,      
      main.tp_volume volume,
      parcel_building con_for_building,
      parcel_building con_for_parcel,
      main.tp_face face,
      main.tp_node node,
      main.sv_survey_point point
    WHERE
      con_for_building.building=selected_nid AND
      con_for_building.parcel=con_for_parcel.parcel AND
      con_for_parcel.building=building.nid AND
      building.model=volume.gid AND
      ARRAY[face.gid] <@ volume.facelist AND
      ARRAY[node.gid] <@ face.nodelist AND
      node.gid=point.nid
    ;


  FOR output IN
    SELECT * FROM summary
  LOOP
      RETURN NEXT output;
  END LOOP;

 
  RETURN; 
END;
$$;


ALTER FUNCTION main.query_x3d_building(immovable_type integer, selected_nid bigint) OWNER TO tdc;

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
-- Name: im_building_individual_unit_nid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('im_building_individual_unit_nid_seq', 3, true);


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
-- Name: im_building_level_unig_volume_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('im_building_level_unig_volume_seq', 1, false);


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
-- Name: im_building_nid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('im_building_nid_seq', 1, false);


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
-- Name: im_levels_nid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('im_levels_nid_seq', 17, true);


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


--
-- Name: im_underpass_individual_unit_nid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('im_underpass_individual_unit_nid_seq', 1, false);


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
-- Name: rt_legal_document_nid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('rt_legal_document_nid_seq', 1, false);


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
-- Name: sv_point_nid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('sv_point_nid_seq', 2, true);


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
-- Name: sv_survey_document_nid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('sv_survey_document_nid_seq', 5, true);


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


--
-- Name: sv_survey_point_nid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('sv_survey_point_nid_seq', 20, true);


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
-- Name: tp_face_gid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('tp_face_gid_seq', 2, true);


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
-- Name: tp_node_gid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('tp_node_gid_seq', 22, true);


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


--
-- Name: tp_volume_gid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('tp_volume_gid_seq', 1, true);


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
-- Data for Name: im_building; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO im_building VALUES (2, 100, NULL, NULL, 57, 43, 'Budapest', 124, NULL, 30.00, NULL);
INSERT INTO im_building VALUES (5, 220, NULL, 'A', 104, 51, 'Budapest', 473, 1, 30.00, NULL);
INSERT INTO im_building VALUES (3, 58, NULL, NULL, 63, 44, 'Budapest', 124, NULL, 30.00, NULL);
INSERT INTO im_building VALUES (1, 322, NULL, '', 51, 40, 'Budapest', 211, 1, 30.00, NULL);
INSERT INTO im_building VALUES (4, 1050, NULL, 'A', 67, 45, 'Budapest', 210, 1, 30.00, 1000);


--
-- Data for Name: im_building_individual_unit; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO im_building_individual_unit VALUES (1, 4, 1, 46, 358);
INSERT INTO im_building_individual_unit VALUES (3, 4, 3, 48, 321);
INSERT INTO im_building_individual_unit VALUES (2, 4, 2, 47, 321);


--
-- Data for Name: im_building_individual_unit_level; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO im_building_individual_unit_level VALUES (4, 1, 74, 0.00, 338.0, NULL);
INSERT INTO im_building_individual_unit_level VALUES (4, 2, 81, 1.00, 186.0, 47.0);
INSERT INTO im_building_individual_unit_level VALUES (4, 3, 85, 1.00, 188.0, NULL);


--
-- Data for Name: im_building_level_unit; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO im_building_level_unit VALUES (1, 0, 149.0, NULL, 42);
INSERT INTO im_building_level_unit VALUES (1, 1, 149.0, NULL, 41);
INSERT INTO im_building_level_unit VALUES (3, 0, 58.0, NULL, 44);
INSERT INTO im_building_level_unit VALUES (2, 0, 58.0, NULL, 43);
INSERT INTO im_building_level_unit VALUES (5, 0, 135.0, NULL, 52);
INSERT INTO im_building_level_unit VALUES (5, 1, 130.0, NULL, 53);


--
-- Data for Name: im_building_levels; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO im_building_levels VALUES (1, 0, 34);
INSERT INTO im_building_levels VALUES (1, 1, 45);
INSERT INTO im_building_levels VALUES (2, 0, 57);
INSERT INTO im_building_levels VALUES (3, 0, 63);
INSERT INTO im_building_levels VALUES (4, 0, 118);
INSERT INTO im_building_levels VALUES (4, 1, 119);
INSERT INTO im_building_levels VALUES (5, 0, 110);
INSERT INTO im_building_levels VALUES (5, 1, 111);


--
-- Data for Name: im_building_shared_unit; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO im_building_shared_unit VALUES (4, 'Földszinti közös helyiségek', 49);
INSERT INTO im_building_shared_unit VALUES (4, 'Emeleti folyosó', 50);


--
-- Data for Name: im_levels; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO im_levels VALUES ('Földszint', 0.0);
INSERT INTO im_levels VALUES ('1. emelet', 1.0);
INSERT INTO im_levels VALUES ('3. emelet', 3.0);
INSERT INTO im_levels VALUES ('2. emelet', 2.0);
INSERT INTO im_levels VALUES ('4. emelet', 4.0);
INSERT INTO im_levels VALUES ('5. emelet', 5.0);
INSERT INTO im_levels VALUES ('6. emelet', 6.0);
INSERT INTO im_levels VALUES ('7. emelet', 7.0);
INSERT INTO im_levels VALUES ('8. emelet', 8.0);
INSERT INTO im_levels VALUES ('9. emelet', 9.0);
INSERT INTO im_levels VALUES ('10. emelet', 10.0);
INSERT INTO im_levels VALUES ('Magasföldszint', 0.5);
INSERT INTO im_levels VALUES ('-2. szint', -2.0);
INSERT INTO im_levels VALUES ('-1. szint', -1.0);


--
-- Data for Name: im_parcel; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO im_parcel VALUES (1, 1264.0, 'Budapest', 213, NULL, 14, 14, 30.00);
INSERT INTO im_parcel VALUES (2, 1285.0, 'Budapest', 212, NULL, 13, 13, 30.00);
INSERT INTO im_parcel VALUES (3, 1325.0, 'Budapest', 211, 1, 11, 11, 30.00);
INSERT INTO im_parcel VALUES (4, 1268.0, 'Budapest', 124, NULL, 2, 2, 30.00);
INSERT INTO im_parcel VALUES (5, 610.0, 'Budapest', 210, 1, 9, 9, 30.00);
INSERT INTO im_parcel VALUES (6, 1056.0, 'Budapest', 473, 1, 26, 26, 30.00);


--
-- Data for Name: im_settlement; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO im_settlement VALUES ('Budapest');


--
-- Data for Name: im_shared_unit_level; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO im_shared_unit_level VALUES (4, '0', 'Földszinti közös helyiségek', 97);
INSERT INTO im_shared_unit_level VALUES (4, '1', 'Emeleti folyosó', 91);


--
-- Data for Name: im_underpass; Type: TABLE DATA; Schema: main; Owner: tdc
--



--
-- Data for Name: im_underpass_block; Type: TABLE DATA; Schema: main; Owner: tdc
--



--
-- Data for Name: im_underpass_individual_unit; Type: TABLE DATA; Schema: main; Owner: tdc
--



--
-- Data for Name: im_underpass_individual_unit_level; Type: TABLE DATA; Schema: main; Owner: tdc
--



--
-- Data for Name: im_underpass_levels; Type: TABLE DATA; Schema: main; Owner: tdc
--



--
-- Data for Name: im_underpass_shared_unit; Type: TABLE DATA; Schema: main; Owner: tdc
--



--
-- Data for Name: pn_person; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO pn_person VALUES (1, 'Magyar Állam');
INSERT INTO pn_person VALUES (2, 'Kerületi önkormányzat');
INSERT INTO pn_person VALUES (3, 'Kovács János');
INSERT INTO pn_person VALUES (4, 'Kiss Tibor');
INSERT INTO pn_person VALUES (5, 'Nagy Tibor');
INSERT INTO pn_person VALUES (6, 'Tóth Béla');
INSERT INTO pn_person VALUES (7, 'Balogh János');
INSERT INTO pn_person VALUES (8, 'Nagy János');
INSERT INTO pn_person VALUES (9, 'Nagy Jánosné');
INSERT INTO pn_person VALUES (10, 'Varga Katalin');
INSERT INTO pn_person VALUES (11, 'Balogh Tihamér
');
INSERT INTO pn_person VALUES (12, 'Balogh Tihamérné');
INSERT INTO pn_person VALUES (13, 'Lovassy Péter');
INSERT INTO pn_person VALUES (14, 'Korda Béla');
INSERT INTO pn_person VALUES (15, 'Korda Béláné');
INSERT INTO pn_person VALUES (16, 'Korda József');
INSERT INTO pn_person VALUES (17, 'Tóbiás Zsigmond');
INSERT INTO pn_person VALUES (18, 'Gazdag Marianna');


--
-- Data for Name: rt_legal_document; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO rt_legal_document VALUES (1, 'Adás-vételi szerződés

Kovács János mint vevő...
...', '1980-03-04', 1000000.00);
INSERT INTO rt_legal_document VALUES (3, 'Adás-vételi szerződés

Vevő: Tóth Béla, Balogh János', '1993-12-04', 4300000.00);
INSERT INTO rt_legal_document VALUES (2, 'Adás-vételi szerződés

Mely létrejött Nagy Tibor és Kiss Tibor mint vevő ...', '1979-10-23', 1320000.00);
INSERT INTO rt_legal_document VALUES (4, 'Adás-vételi szerződés

Vevők: Nagy János, Nagy Jánosné, Varga Katalin', '2002-05-17', 8540000.00);
INSERT INTO rt_legal_document VALUES (5, 'Adás-vételi szerződés

Vevők: Balog Tihamér, Balog Tihamérné', '1984-03-15', 2500000.00);
INSERT INTO rt_legal_document VALUES (6, 'Adás-vételi szerződés

Vevők: Lovassy Péter', '2008-11-14', 3450000.00);
INSERT INTO rt_legal_document VALUES (7, 'Adás-vételi szerződés

Vevők: Korda Béla, Korda Béláné, Korda József', '2002-01-16', 2890000.00);
INSERT INTO rt_legal_document VALUES (8, 'Adás-vételi szerződés

Vevők: Tóbiás Zsigmond és Gazdag Marianna', '1999-09-13', 1400000.00);
INSERT INTO rt_legal_document VALUES (9, 'Kisajátítás az Állam részére', '1949-06-03', 0.00);


--
-- Data for Name: rt_right; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO rt_right VALUES (3, 1, 1, NULL, NULL, NULL, NULL, 1, 1, 1);
INSERT INTO rt_right VALUES (4, 2, 2, NULL, NULL, NULL, NULL, 1, 2, 1);
INSERT INTO rt_right VALUES (5, 2, 2, NULL, NULL, NULL, NULL, 1, 2, 1);
INSERT INTO rt_right VALUES (6, 3, 3, NULL, NULL, NULL, NULL, 1, 2, 1);
INSERT INTO rt_right VALUES (7, 3, 3, NULL, NULL, NULL, NULL, 1, 2, 1);
INSERT INTO rt_right VALUES (9, 4, 4, NULL, NULL, NULL, NULL, 2, 6, 1);
INSERT INTO rt_right VALUES (10, 4, 4, NULL, NULL, NULL, NULL, 1, 6, 1);
INSERT INTO rt_right VALUES (8, 4, 4, NULL, NULL, NULL, NULL, 3, 6, 1);
INSERT INTO rt_right VALUES (11, 5, NULL, NULL, 1, NULL, NULL, 1, 2, 1);
INSERT INTO rt_right VALUES (12, 5, NULL, NULL, 1, NULL, NULL, 1, 2, 1);
INSERT INTO rt_right VALUES (13, 6, NULL, NULL, 2, NULL, NULL, 1, 1, 1);
INSERT INTO rt_right VALUES (14, 7, NULL, NULL, 3, NULL, NULL, 1, 3, 1);
INSERT INTO rt_right VALUES (15, 7, NULL, NULL, 3, NULL, NULL, 1, 3, 1);
INSERT INTO rt_right VALUES (16, 7, NULL, NULL, 3, NULL, NULL, 1, 3, 1);
INSERT INTO rt_right VALUES (17, 8, NULL, 5, NULL, NULL, NULL, 1, 2, 1);
INSERT INTO rt_right VALUES (18, 8, NULL, 5, NULL, NULL, NULL, 1, 2, 1);
INSERT INTO rt_right VALUES (1, 9, 6, NULL, NULL, NULL, NULL, 1, 1, 1);


--
-- Data for Name: rt_type; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO rt_type VALUES ('Tulajdonjog', 1);
INSERT INTO rt_type VALUES ('Kezelői jog', 2);


--
-- Data for Name: sv_point; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO sv_point VALUES (57, 57, 1, 645534.66, 227926.73, 101.20, 3, 1);
INSERT INTO sv_point VALUES (54, 54, 1, 645471.90, 227916.06, 101.18, 3, 1);
INSERT INTO sv_point VALUES (1, 1, 1, 645415.99, 227907.82, 101.35, 3, 1);
INSERT INTO sv_point VALUES (2, 2, 1, 645393.58, 227894.87, 101.30, 3, 1);
INSERT INTO sv_point VALUES (3, 3, 1, 645388.42, 227902.87, 101.37, 3, 1);
INSERT INTO sv_point VALUES (4, 4, 1, 645382.45, 227912.26, 101.47, 3, 1);
INSERT INTO sv_point VALUES (5, 5, 1, 645405.13, 227925.69, 101.52, 3, 1);
INSERT INTO sv_point VALUES (6, 6, 1, 645392.30, 227946.23, 102.00, 3, 1);
INSERT INTO sv_point VALUES (7, 7, 1, 645361.32, 227927.08, 101.95, 3, 1);
INSERT INTO sv_point VALUES (8, 8, 1, 645347.19, 227918.95, 101.75, 3, 1);
INSERT INTO sv_point VALUES (9, 9, 1, 645358.91, 227898.19, 101.27, 3, 1);
INSERT INTO sv_point VALUES (10, 10, 1, 645374.75, 227974.91, 102.61, 3, 1);
INSERT INTO sv_point VALUES (11, 11, 1, 645344.79, 227956.34, 102.56, 3, 1);
INSERT INTO sv_point VALUES (12, 12, 1, 645368.90, 227879.87, 101.20, 3, 1);
INSERT INTO sv_point VALUES (13, 13, 1, 645363.86, 227889.01, 101.27, 3, 1);
INSERT INTO sv_point VALUES (14, 14, 1, 645332.38, 227857.64, 101.03, 3, 1);
INSERT INTO sv_point VALUES (15, 15, 1, 645322.10, 227875.13, 101.20, 3, 1);
INSERT INTO sv_point VALUES (16, 16, 1, 645309.53, 227896.26, 101.58, 3, 1);
INSERT INTO sv_point VALUES (17, 17, 1, 645333.93, 227909.96, 101.68, 3, 1);
INSERT INTO sv_point VALUES (18, 18, 1, 645316.54, 227939.65, 102.30, 3, 1);
INSERT INTO sv_point VALUES (19, 19, 1, 645292.57, 227925.10, 101.98, 3, 1);
INSERT INTO sv_point VALUES (20, 20, 1, 645434.87, 227919.23, 101.45, 3, 1);
INSERT INTO sv_point VALUES (21, 21, 1, 645422.90, 227939.17, 101.53, 3, 1);
INSERT INTO sv_point VALUES (22, 22, 1, 645446.22, 227952.49, 101.56, 3, 1);
INSERT INTO sv_point VALUES (23, 23, 1, 645457.56, 227933.18, 101.48, 3, 1);
INSERT INTO sv_point VALUES (25, 25, 1, 645511.06, 227965.28, 101.58, 3, 1);
INSERT INTO sv_point VALUES (26, 26, 1, 645408.88, 227961.85, 102.11, 3, 1);
INSERT INTO sv_point VALUES (27, 27, 1, 645450.93, 227987.59, 102.17, 3, 1);
INSERT INTO sv_point VALUES (28, 28, 1, 645487.31, 228009.41, 102.24, 3, 1);
INSERT INTO sv_point VALUES (29, 29, 1, 645464.20, 227963.62, 101.59, 3, 1);
INSERT INTO sv_point VALUES (30, 30, 1, 645401.28, 227973.89, 102.33, 3, 1);
INSERT INTO sv_point VALUES (31, 31, 1, 645479.18, 228020.97, 102.46, 3, 1);
INSERT INTO sv_point VALUES (32, 32, 1, 645394.01, 227985.02, 102.70, 3, 1);
INSERT INTO sv_point VALUES (33, 33, 1, 645471.90, 228033.38, 102.83, 3, 1);
INSERT INTO sv_point VALUES (34, 34, 1, 645427.05, 227889.75, 101.23, 3, 1);
INSERT INTO sv_point VALUES (35, 35, 1, 645435.42, 227876.15, 101.07, 3, 1);
INSERT INTO sv_point VALUES (36, 36, 1, 645424.50, 227869.94, 100.99, 3, 1);
INSERT INTO sv_point VALUES (37, 37, 1, 645416.80, 227883.53, 101.20, 3, 1);
INSERT INTO sv_point VALUES (38, 38, 1, 645393.18, 227849.68, 100.95, 3, 1);
INSERT INTO sv_point VALUES (39, 39, 1, 645384.00, 227863.73, 101.12, 3, 1);
INSERT INTO sv_point VALUES (40, 40, 1, 645352.21, 227824.95, 100.84, 3, 1);
INSERT INTO sv_point VALUES (41, 41, 1, 645343.50, 227839.23, 101.00, 3, 1);
INSERT INTO sv_point VALUES (42, 42, 1, 645444.51, 227861.27, 100.99, 3, 1);
INSERT INTO sv_point VALUES (43, 43, 1, 645409.87, 227840.03, 100.88, 3, 1);
INSERT INTO sv_point VALUES (44, 44, 1, 645401.71, 227835.29, 100.87, 3, 1);
INSERT INTO sv_point VALUES (45, 45, 1, 645360.93, 227810.74, 100.76, 3, 1);
INSERT INTO sv_point VALUES (46, 46, 1, 645457.35, 227840.52, 100.98, 3, 1);
INSERT INTO sv_point VALUES (47, 47, 1, 645422.71, 227818.63, 100.87, 3, 1);
INSERT INTO sv_point VALUES (48, 48, 1, 645374.13, 227789.95, 100.75, 3, 1);
INSERT INTO sv_point VALUES (49, 49, 1, 645465.91, 227826.18, 100.92, 3, 1);
INSERT INTO sv_point VALUES (50, 50, 1, 645382.73, 227775.01, 100.69, 3, 1);
INSERT INTO sv_point VALUES (51, 51, 1, 645415.95, 227864.44, 100.98, 3, 1);
INSERT INTO sv_point VALUES (52, 52, 1, 645424.84, 227849.22, 100.89, 3, 1);
INSERT INTO sv_point VALUES (53, 53, 1, 645445.97, 227901.19, 101.13, 3, 1);
INSERT INTO sv_point VALUES (55, 55, 1, 645483.08, 227896.34, 101.03, 3, 1);
INSERT INTO sv_point VALUES (56, 56, 1, 645458.31, 227880.85, 100.97, 3, 1);
INSERT INTO sv_point VALUES (58, 58, 1, 645503.03, 227908.09, 101.10, 3, 1);
INSERT INTO sv_point VALUES (59, 59, 1, 645513.52, 227890.65, 101.04, 3, 1);
INSERT INTO sv_point VALUES (60, 60, 1, 645468.69, 227864.06, 100.91, 3, 1);
INSERT INTO sv_point VALUES (61, 61, 1, 645544.31, 227911.40, 101.10, 3, 1);
INSERT INTO sv_point VALUES (62, 62, 1, 645519.92, 227880.80, 101.01, 3, 1);
INSERT INTO sv_point VALUES (63, 63, 1, 645474.90, 227854.21, 100.88, 3, 1);
INSERT INTO sv_point VALUES (64, 64, 1, 645552.02, 227900.27, 101.07, 3, 1);
INSERT INTO sv_point VALUES (65, 65, 1, 645485.60, 227836.66, 100.82, 3, 1);
INSERT INTO sv_point VALUES (66, 66, 1, 645561.63, 227882.87, 100.02, 3, 1);
INSERT INTO sv_point VALUES (67, 67, 1, 645521.34, 227947.30, 101.38, 3, 1);
INSERT INTO sv_point VALUES (69, 69, 2, 645437.20, 227955.63, 101.59, 3, 2);
INSERT INTO sv_point VALUES (72, 72, 2, 645426.98, 227949.64, 108.50, 3, 2);
INSERT INTO sv_point VALUES (71, 71, 2, 645419.43, 227961.90, 102.11, 3, 2);
INSERT INTO sv_point VALUES (70, 70, 2, 645429.95, 227968.33, 102.17, 3, 2);
INSERT INTO sv_point VALUES (77, 77, 2, 645436.79, 227956.07, 105.11, 3, 2);
INSERT INTO sv_point VALUES (78, 78, 2, 645429.72, 227967.50, 105.11, 3, 2);
INSERT INTO sv_point VALUES (79, 79, 2, 645420.21, 227961.70, 105.11, 3, 2);
INSERT INTO sv_point VALUES (76, 76, 2, 645427.16, 227950.39, 105.11, 3, 2);
INSERT INTO sv_point VALUES (80, 80, 2, 645388.63, 227938.68, 101.90, 3, 2);
INSERT INTO sv_point VALUES (81, 81, 2, 645379.97, 227933.54, 101.90, 3, 2);
INSERT INTO sv_point VALUES (83, 83, 2, 645396.66, 227926.16, 101.85, 3, 2);
INSERT INTO sv_point VALUES (84, 84, 2, 645359.01, 227921.36, 101.30, 3, 2);
INSERT INTO sv_point VALUES (85, 85, 2, 645366.36, 227925.28, 101.50, 3, 2);
INSERT INTO sv_point VALUES (86, 86, 2, 645369.69, 227919.22, 101.50, 3, 2);
INSERT INTO sv_point VALUES (87, 87, 2, 645362.52, 227915.10, 101.30, 3, 2);
INSERT INTO sv_point VALUES (88, 88, 2, 645388.63, 227938.68, 104.80, 3, 2);
INSERT INTO sv_point VALUES (89, 89, 2, 645379.97, 227933.54, 104.80, 3, 2);
INSERT INTO sv_point VALUES (90, 90, 2, 645387.78, 227920.91, 104.80, 3, 2);
INSERT INTO sv_point VALUES (82, 82, 2, 645387.78, 227920.91, 101.80, 3, 2);
INSERT INTO sv_point VALUES (68, 68, 2, 645426.98, 227949.64, 101.53, 3, 2);
INSERT INTO sv_point VALUES (73, 73, 2, 645437.20, 227955.63, 108.50, 3, 2);
INSERT INTO sv_point VALUES (24, 24, 1, 645500.58, 227983.31, 101.66, 3, 1);
INSERT INTO sv_point VALUES (74, 74, 2, 645429.95, 227968.33, 108.50, 3, 2);
INSERT INTO sv_point VALUES (75, 75, 2, 645419.43, 227961.90, 108.50, 3, 2);
INSERT INTO sv_point VALUES (91, 91, 2, 645396.66, 227926.16, 104.80, 3, 2);
INSERT INTO sv_point VALUES (92, 92, 2, 645359.01, 227921.36, 104.30, 3, 2);
INSERT INTO sv_point VALUES (93, 93, 2, 645366.36, 227925.28, 104.30, 3, 2);
INSERT INTO sv_point VALUES (94, 94, 2, 645369.69, 227919.22, 104.30, 3, 2);
INSERT INTO sv_point VALUES (95, 95, 2, 645362.52, 227915.10, 104.30, 3, 2);
INSERT INTO sv_point VALUES (96, 96, 3, 645435.19, 227920.04, 102.00, 3, 3);
INSERT INTO sv_point VALUES (97, 97, 3, 645423.81, 227939.00, 102.00, 3, 3);
INSERT INTO sv_point VALUES (98, 98, 3, 645446.04, 227951.73, 102.00, 3, 3);
INSERT INTO sv_point VALUES (115, 115, 3, 645446.04, 227951.73, 105.00, 3, 3);
INSERT INTO sv_point VALUES (116, 116, 3, 645446.04, 227951.73, 107.70, 3, 3);
INSERT INTO sv_point VALUES (107, 107, 3, 645423.81, 227939.00, 104.70, 3, 3);
INSERT INTO sv_point VALUES (114, 114, 3, 645423.81, 227939.00, 105.00, 3, 3);
INSERT INTO sv_point VALUES (117, 117, 3, 645423.81, 227939.00, 107.70, 3, 3);
INSERT INTO sv_point VALUES (106, 106, 3, 645435.19, 227920.04, 104.70, 3, 3);
INSERT INTO sv_point VALUES (113, 113, 3, 645435.19, 227920.04, 105.00, 3, 3);
INSERT INTO sv_point VALUES (122, 122, 3, 645435.19, 227920.04, 107.70, 3, 3);
INSERT INTO sv_point VALUES (111, 111, 3, 645456.82, 227933.36, 104.70, 3, 3);
INSERT INTO sv_point VALUES (112, 112, 3, 645456.82, 227933.36, 105.00, 3, 3);
INSERT INTO sv_point VALUES (123, 123, 3, 645456.82, 227933.36, 107.70, 3, 3);
INSERT INTO sv_point VALUES (109, 109, 3, 645448.28, 227928.10, 104.70, 3, 3);
INSERT INTO sv_point VALUES (108, 108, 3, 645437.33, 227946.76, 104.70, 3, 3);
INSERT INTO sv_point VALUES (102, 102, 3, 645427.56, 227932.75, 105.11, 3, 3);
INSERT INTO sv_point VALUES (118, 118, 3, 645427.56, 227932.75, 107.70, 3, 3);
INSERT INTO sv_point VALUES (103, 103, 3, 645431.20, 227926.70, 105.00, 3, 3);
INSERT INTO sv_point VALUES (121, 121, 3, 645431.20, 227926.70, 107.70, 3, 3);
INSERT INTO sv_point VALUES (104, 104, 3, 645449.71, 227945.47, 105.00, 3, 3);
INSERT INTO sv_point VALUES (119, 119, 3, 645449.71, 227945.47, 107.70, 3, 3);
INSERT INTO sv_point VALUES (105, 105, 3, 645453.26, 227939.43, 105.00, 3, 3);
INSERT INTO sv_point VALUES (120, 120, 3, 645453.26, 227939.43, 107.70, 3, 3);
INSERT INTO sv_point VALUES (99, 99, 3, 645456.82, 227933.36, 102.00, 3, 3);
INSERT INTO sv_point VALUES (100, 100, 3, 645448.28, 227928.10, 102.00, 3, 3);
INSERT INTO sv_point VALUES (101, 101, 3, 645437.33, 227946.76, 102.00, 3, 3);
INSERT INTO sv_point VALUES (124, 124, 2, 645434.87, 227919.23, 108.00, 3, 2);
INSERT INTO sv_point VALUES (125, 125, 3, 645457.56, 227933.18, 108.00, 3, 2);
INSERT INTO sv_point VALUES (126, 126, 3, 645446.22, 227952.49, 108.00, 3, 2);
INSERT INTO sv_point VALUES (127, 127, 2, 645422.90, 227939.17, 108.00, 3, 2);
INSERT INTO sv_point VALUES (110, 110, 3, 645446.04, 227951.73, 104.70, 3, 3);
INSERT INTO sv_point VALUES (128, 128, 2, 645465.04, 227880.13, 100.96, 3, 2);
INSERT INTO sv_point VALUES (129, 129, 2, 645473.62, 227885.50, 100.97, 3, 2);
INSERT INTO sv_point VALUES (130, 130, 2, 645480.57, 227874.13, 100.93, 3, 2);
INSERT INTO sv_point VALUES (136, 136, 3, 645465.70, 227880.00, 101.30, 3, 3);
INSERT INTO sv_point VALUES (140, 140, 3, 645465.70, 227880.00, 104.00, 3, 3);
INSERT INTO sv_point VALUES (144, 144, 3, 645465.70, 227880.00, 104.30, 3, 3);
INSERT INTO sv_point VALUES (148, 148, 3, 645465.70, 227880.00, 107.00, 3, 3);
INSERT INTO sv_point VALUES (137, 137, 3, 645471.97, 227869.47, 101.30, 3, 3);
INSERT INTO sv_point VALUES (141, 141, 3, 645471.97, 227869.47, 104.00, 3, 3);
INSERT INTO sv_point VALUES (145, 145, 3, 645471.97, 227869.47, 104.30, 3, 3);
INSERT INTO sv_point VALUES (149, 149, 3, 645471.97, 227869.47, 107.00, 3, 3);
INSERT INTO sv_point VALUES (138, 138, 3, 645479.91, 227874.27, 101.30, 3, 3);
INSERT INTO sv_point VALUES (142, 142, 3, 645479.91, 227874.27, 104.00, 3, 3);
INSERT INTO sv_point VALUES (146, 146, 3, 645479.91, 227874.27, 104.30, 3, 3);
INSERT INTO sv_point VALUES (150, 150, 3, 645479.91, 227874.27, 107.00, 3, 3);
INSERT INTO sv_point VALUES (139, 139, 3, 645473.44, 227884.84, 101.30, 3, 3);
INSERT INTO sv_point VALUES (143, 143, 3, 645473.44, 227884.84, 104.00, 3, 3);
INSERT INTO sv_point VALUES (147, 147, 3, 645473.44, 227884.84, 104.30, 3, 3);
INSERT INTO sv_point VALUES (151, 151, 3, 645473.44, 227884.84, 107.00, 3, 3);
INSERT INTO sv_point VALUES (132, 132, 2, 645465.04, 227880.13, 107.30, 3, 2);
INSERT INTO sv_point VALUES (133, 133, 2, 645473.62, 227885.50, 107.30, 3, 2);
INSERT INTO sv_point VALUES (134, 134, 2, 645480.57, 227874.13, 107.30, 3, 2);
INSERT INTO sv_point VALUES (135, 135, 2, 645471.78, 227868.81, 107.30, 3, 2);
INSERT INTO sv_point VALUES (131, 131, 2, 645471.78, 227868.81, 100.91, 3, 2);


--
-- Data for Name: sv_survey_document; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO sv_survey_document VALUES (1, '2012-10-23', 'Mérési jegyzőkönyv

1. földrészlet felmérés');
INSERT INTO sv_survey_document VALUES (2, '2012-10-23', 'Mérési jegyzőkönyv

Épület sarokpontok felmérése');
INSERT INTO sv_survey_document VALUES (3, '2012-10-30', 'Mérési jegyzőkönyv

Épületek belső felmérése');
INSERT INTO sv_survey_document VALUES (4, '2012-11-02', 'ez csak egy atmeneti dokumentum');


--
-- Data for Name: sv_survey_point; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO sv_survey_point VALUES (21, '210/1 és 211/1 hrsz-ú ingatlanok közös utcafronti sarokpontja és a 210/1 hrsz-ú ingatlanon található társasház NY-i alsó sarokpontja', '21');
INSERT INTO sv_survey_point VALUES (1, '123 hrsz-ú telek térre néző sarokpontja', '1');
INSERT INTO sv_survey_point VALUES (3, '122 és 123 hrsz-ú telkek közös épületsarokpontja', '3');
INSERT INTO sv_survey_point VALUES (4, '122 és 123 hrsz-ú telkek belső közös sarokpontja', '4');
INSERT INTO sv_survey_point VALUES (8, '124, 125, 127 hrsz-ú telkek közös sarokpontja', '8');
INSERT INTO sv_survey_point VALUES (9, '121,122, 124, 125 hrsz-ú telkek közös sarokpontja', '9');
INSERT INTO sv_survey_point VALUES (7, '124, 126, 127 hrsz-ú telkek közös sarokpontja', '7');
INSERT INTO sv_survey_point VALUES (10, '126 hrsz-ú telek tér felöli sarokpontja', '10');
INSERT INTO sv_survey_point VALUES (11, '126 és 127 hrsz-ú telkek közös utcafronti sarokpontja', '11');
INSERT INTO sv_survey_point VALUES (12, '121, 122 hrsz-ú telkek közös utcafronti sarokpontja', '12');
INSERT INTO sv_survey_point VALUES (13, '122 hrsz-ú telek 121 hrsz-ú telekkel szomszédos épületsarokpontja', '13');
INSERT INTO sv_survey_point VALUES (14, '121 hrsz-ú telek térre néző sarokpontja', '14');
INSERT INTO sv_survey_point VALUES (15, '121 és 125 hrsz-ú telkek közös utcafronti sarokpontja', '15');
INSERT INTO sv_survey_point VALUES (16, '125 és 126/1 hrsz-ú telkek közös utcafronti sarokpontja', '16');
INSERT INTO sv_survey_point VALUES (17, '125, 126/2, 126/3 hrsz-ú ingatlanok közös sarokpontja', '17');
INSERT INTO sv_survey_point VALUES (18, '126/2 és 126/3 hrsz-ú ingatlanok közös utcafronti sarokpontja', '18');
INSERT INTO sv_survey_point VALUES (19, '126/3 hrsz-ú ingatlan tér felöli sarokpontja', '19');
INSERT INTO sv_survey_point VALUES (22, '210/1, 210/2, 211/1 hrsz-ú ingatlanok közös sarokpontja', '22');
INSERT INTO sv_survey_point VALUES (25, '210/2 hrsz-ú ingatlan tér felüli sarokpontja', '25');
INSERT INTO sv_survey_point VALUES (28, '211/2 és 213 hrsz-ú ingatlanok közös utcafronti sarokpontja', '28');
INSERT INTO sv_survey_point VALUES (29, '210/2, 211/1, 211/2 hrsz-ú ingatlanok közös sarokpontja', '29');
INSERT INTO sv_survey_point VALUES (30, '212 és 213 hrsz-ú ingatlanok közös utcafronti sarokpontja', '30');
INSERT INTO sv_survey_point VALUES (31, '212 és 213 hrsz-ú ingatlanok közös utcafronti sarokpontja', '31');
INSERT INTO sv_survey_point VALUES (32, '213 hrsz-ú ingatlan tér felüli sarokpontja', '32');
INSERT INTO sv_survey_point VALUES (33, '213 hrsz-ú ingatlan tér felüli sarokpontja', '33');
INSERT INTO sv_survey_point VALUES (20, '210/1 hrsz-ú ingatlan tér felöli sarokpontja és a 210/1 hrsz-ú ingatlanon található társasház D-i alsó sarokpontja', '20');
INSERT INTO sv_survey_point VALUES (27, '211/1, 211/2, 212 hrsz-ú ingatlanok közös sarokpontja', '27');
INSERT INTO sv_survey_point VALUES (26, '211/1 és 212 hrsz-ú ingatlanok közös utcafronti sarokpontja', '26');
INSERT INTO sv_survey_point VALUES (34, '325/5 hrsz-ú ingatlan tér felöli sarokpontja', '34');
INSERT INTO sv_survey_point VALUES (35, '325/2, 325/5 hrsz-ú ingatlanok közös utcafronti sarokpontja', '35');
INSERT INTO sv_survey_point VALUES (36, '352/2, 352/4, 352/5 hrsz-ú ingatlanok közös sarokpontja', '36');
INSERT INTO sv_survey_point VALUES (37, '252/4, 252/5 hrsz-ú ingatlanok közös utcafronti sarokpontja', '37');
INSERT INTO sv_survey_point VALUES (39, '352/3, 352/4 hrsz-ú ingatlan közös utcafronti sarokpontja', '39');
INSERT INTO sv_survey_point VALUES (40, '352/1, 352/3 hrsz-ú ingatlan közös utcafronti sarokpontja', '40');
INSERT INTO sv_survey_point VALUES (41, '253/3 hrsz-ú ingatlan tér felöli sarokpontja', '41');
INSERT INTO sv_survey_point VALUES (42, '252/2, 251/2 hrsz-ú ingatlanok közös utcafronti sarokpontja', '42');
INSERT INTO sv_survey_point VALUES (43, '251/1, 251/2, 252/2 hrsz-ú ingatlanok közös sarokpontja', '43');
INSERT INTO sv_survey_point VALUES (44, '351/1, 351/2, 352/1 hrsz-ú ingatlanok közös sarokpontja', '44');
INSERT INTO sv_survey_point VALUES (45, '351/1, 352/1 hrsz-ú ingatlanok közös utcafronti sarokpontja', '45');
INSERT INTO sv_survey_point VALUES (46, '351/2, 350 hrsz-ú ingatlanok közös utcafronti sarokpontja', '46');
INSERT INTO sv_survey_point VALUES (47, '350, 351/1, 351/2 hrsz-ú ingatlanok közös sarokpontja', '47');
INSERT INTO sv_survey_point VALUES (2, '123 és 122 hrsz-ú telkek közös utcafronti sarokpontja', '2');
INSERT INTO sv_survey_point VALUES (5, '123 és 124 hrsz-ú telkek közös utcafronti sarokpontja', '5');
INSERT INTO sv_survey_point VALUES (6, '124 és a 126 hrsz-ú telkek közös utcafronti sarokpontja', '6');
INSERT INTO sv_survey_point VALUES (48, '350, 351/1 hrsz-ú ingatlanok közös utcafronti sarokpontja', '48');
INSERT INTO sv_survey_point VALUES (49, '350 hrsz-ú ingatlan térre néző sarokpontja', '49');
INSERT INTO sv_survey_point VALUES (50, '350 hrsz-ú ingatlan térre néző sarokpontja', '50');
INSERT INTO sv_survey_point VALUES (38, '352/1, 352/2, 352/3, 352/4 hrsz-ú ingatlanok közös sarokpontja', '38');
INSERT INTO sv_survey_point VALUES (51, '352/2 hrsz-on lévő épület sarokpontja és a 352/4 hrsz-ú ingatlan határpontja', '51');
INSERT INTO sv_survey_point VALUES (52, '352/2 hrsz-on lévő épület sarokpontja és a 351/2 hrsz-ú ingatlan határpontja', '52');
INSERT INTO sv_survey_point VALUES (53, '474/1 hrsz-ú ingatlan tér felüli sarokpontja', '53');
INSERT INTO sv_survey_point VALUES (54, '474/1, 474/2 hrsz-ú ingatlanok közös utcafronti sarokpontja', '54');
INSERT INTO sv_survey_point VALUES (55, '474/1, 474/2, 473/1 hrsz-ú ingatlanok közös sarokpontja', '55');
INSERT INTO sv_survey_point VALUES (56, '474/1, 473/1 hrsz-ú ingatlanok közös sarokpontja', '56');
INSERT INTO sv_survey_point VALUES (57, '474/2, 473/2 hrsz-ú ingatlanok közös utcafronti sarokpontja', '57');
INSERT INTO sv_survey_point VALUES (58, '474/2, 473/1, 373/2 hrsz-ú ingatlanok közös sarokpontja', '58');
INSERT INTO sv_survey_point VALUES (59, '473/1, 473/2, 472/1, 472/2 hrsz-ú ingatlanok közös sarokpontja', '59');
INSERT INTO sv_survey_point VALUES (60, '472/1, 473/1 hrsz-ú ingatlanok közös utcafronti sarokpontja', '60');
INSERT INTO sv_survey_point VALUES (23, '210/1 és 210/2 ingatlanok közös utcafronti sarokpontja és a 210/1 hrsz-ú ingatlanon található társasház K-i alsó sarokpontja', '23');
INSERT INTO sv_survey_point VALUES (24, '210/2 és 211/2 hrsz-ú ingatlanok közös utcafronti sarokpontja és a 210/1 hrsz-ú ingatlanon található társasház É-i alsó sarokpontja', '24');
INSERT INTO sv_survey_point VALUES (61, '472/2, 473/3 hrsz-ú ingatlanok közös utcafronti sarokpontja', '61');
INSERT INTO sv_survey_point VALUES (62, '472/, 472/2 hrsz-ú ingatlanok közös sarok- 471 hrsz-ú ingatlan közös határpontja', '62');
INSERT INTO sv_survey_point VALUES (63, '471, 472/1 hrsz-ú ingatlanok közös utcafronti sarokpontja', '63');
INSERT INTO sv_survey_point VALUES (64, '471, 472/2 hrsz-ú ingatlanok közös utcafronti sarokpontja', '64');
INSERT INTO sv_survey_point VALUES (65, '471 hrsz-ú ingatlan tér felöli sarokpontja', '65');
INSERT INTO sv_survey_point VALUES (66, '471 hrsz-ú ingatlan tér felöli sarokpontja', '66');
INSERT INTO sv_survey_point VALUES (67, '474/2 hrsz-ú ingatlan térre néző sarokpontja', '67');
INSERT INTO sv_survey_point VALUES (128, '473/1/A hrsz-ú önálló épület NY-i alsó sarokpontja', '128');
INSERT INTO sv_survey_point VALUES (129, '473/1/A hrsz-ú önálló épület É-i alsó sarokpontja', '129');
INSERT INTO sv_survey_point VALUES (75, '211/1 hrsz-ú épület NY-i felső sarokpontja', '75');
INSERT INTO sv_survey_point VALUES (74, '211/1 hrsz-ú épület É-i felső sarokpontja', '74');
INSERT INTO sv_survey_point VALUES (73, '211/1 hrsz-ú épület K-i felső sarokpontja', '73');
INSERT INTO sv_survey_point VALUES (72, '211/1 hrsz-ú épület D-i felső sarokpontja', '72');
INSERT INTO sv_survey_point VALUES (71, '211/1 hrsz-ú épület NY-i alsó sarokpontja', '71');
INSERT INTO sv_survey_point VALUES (70, '211/1 hrsz-ú épület É-i alsó sarokpontja', '70');
INSERT INTO sv_survey_point VALUES (69, '211/1 hrsz-ú épület K-i alsó sarokpontja', '69');
INSERT INTO sv_survey_point VALUES (68, '211/1 hrsz-ú épület D-i alsó sarokpontja', '68');
INSERT INTO sv_survey_point VALUES (76, '211/1 hrsz-ú épület D-i emeleti sarokpontja', '76');
INSERT INTO sv_survey_point VALUES (77, '211/1 hrsz-ú épület K-i emeleti sarokpontja', '77');
INSERT INTO sv_survey_point VALUES (78, '211/1 hrsz-ú épület É-i emeleti sarokpontja', '78');
INSERT INTO sv_survey_point VALUES (79, '211/1 hrsz-ú épület NY-i emeleti sarokpontja', '79');
INSERT INTO sv_survey_point VALUES (80, '124 hrsz-ú épület É-i sarokpontja', '80');
INSERT INTO sv_survey_point VALUES (81, '124 hrsz-ú épület NY-i sarokpontja', '81');
INSERT INTO sv_survey_point VALUES (82, '124 hrsz-ú épület D-i sarokpontja', '82');
INSERT INTO sv_survey_point VALUES (83, '124 hrsz-ú épület K-i sarokpontja', '83');
INSERT INTO sv_survey_point VALUES (85, '124 hrsz-ú Belső épület É-i sarokpontja', '85');
INSERT INTO sv_survey_point VALUES (84, '124 hrsz-ú Belső épület NY-i sarokpontja', '84');
INSERT INTO sv_survey_point VALUES (87, '124 hrsz-ú Belső épület D-i sarokpontja', '87');
INSERT INTO sv_survey_point VALUES (86, '124 hrsz-ú Belső épület K-i sarokpontja', '86');
INSERT INTO sv_survey_point VALUES (88, '124 hrsz-ú épület É-i tető sarokpontja', '88');
INSERT INTO sv_survey_point VALUES (89, '124 hrsz-ú épület NY-i tető sarokpontja', '89');
INSERT INTO sv_survey_point VALUES (90, '124 hrsz-ú épület D-i tető sarokpontja', '90');
INSERT INTO sv_survey_point VALUES (91, '124 hrsz-ú épület K-i tető sarokpontja', '91');
INSERT INTO sv_survey_point VALUES (92, '124 hrsz-ú Beslő épület NY-i tető sarokpontja', '92');
INSERT INTO sv_survey_point VALUES (93, '124 hrsz-ú Beslő épület É-i tető sarokpontja', '93');
INSERT INTO sv_survey_point VALUES (94, '124 hrsz-ú Beslő épület K-i tető sarokpontja', '94');
INSERT INTO sv_survey_point VALUES (95, '124 hrsz-ú Beslő épület D-i tető sarokpontja', '95');
INSERT INTO sv_survey_point VALUES (96, '210/1/A hrsz-ú társasház 1. lakásának D-i belső alsó sarokpontja', '96');
INSERT INTO sv_survey_point VALUES (97, '210/1/A hrsz-ú társasház 1. lakásának NY-i belső alsó sarokpontja', '97');
INSERT INTO sv_survey_point VALUES (98, '210/1/A hrsz-ú társasház alsó közös helyiségének É-i belső alsó sarokpontja', '98');
INSERT INTO sv_survey_point VALUES (99, '210/1/A hrsz-ú társasház alsó közös helyiségéne6k K-i belső alsó sarokpontja', '99');
INSERT INTO sv_survey_point VALUES (100, '210/1/A hrsz-ú társasház 1. lakásának K-i belső alsó sarokpontja', '100');
INSERT INTO sv_survey_point VALUES (101, '210/1/A hrsz-ú társasház 1. lakásának É-i belső alsó sarokpontja', '101');
INSERT INTO sv_survey_point VALUES (106, '210/1/A hrsz-ú társasház 1. lakásának D-i belső felső sarokpontja', '106');
INSERT INTO sv_survey_point VALUES (107, '210/1/A hrsz-ú társasház 1. lakásának NY-i belső felső sarokpontja', '107');
INSERT INTO sv_survey_point VALUES (108, '210/1/A hrsz-ú társasház 1. lakásának É-i belső felső sarokpontja', '108');
INSERT INTO sv_survey_point VALUES (109, '210/1/A hrsz-ú társasház 1. lakásának K-i belső felső sarokpontja', '109');
INSERT INTO sv_survey_point VALUES (110, '210/1/A hrsz-ú társasház alsó közös helyiség É-i belső felső sarokpontja', '110');
INSERT INTO sv_survey_point VALUES (111, '210/1/A hrsz-ú társasház alsó közös helyiség K-i belső felső sarokpontja', '111');
INSERT INTO sv_survey_point VALUES (112, '210/1/A hrsz-ú társasház 3. lakásának K-i belső alsó sarokpontja', '112');
INSERT INTO sv_survey_point VALUES (113, '210/1/A hrsz-ú társasház 3. lakásának D-i belső alsó sarokpontja', '113');
INSERT INTO sv_survey_point VALUES (103, '210/1/A hrsz-ú társasház 3. lakásának NY-i belső alsó sarokpontja', '103');
INSERT INTO sv_survey_point VALUES (105, '210/1/A hrsz-ú társasház 3. lakásának É-i belső alsó sarokpontja', '105');
INSERT INTO sv_survey_point VALUES (120, '210/1/A hrsz-ú társasház 3. lakásának É-i belső felső sarokpontja', '120');
INSERT INTO sv_survey_point VALUES (121, '210/1/A hrsz-ú társasház 3. lakásának NY-i belső felső sarokpontja', '121');
INSERT INTO sv_survey_point VALUES (122, '210/1/A hrsz-ú társasház 3. lakásának D-i belső felső sarokpontja', '122');
INSERT INTO sv_survey_point VALUES (123, '210/1/A hrsz-ú társasház 3. lakásának K-i belső felső sarokpontj', '123');
INSERT INTO sv_survey_point VALUES (102, '210/1/A hrsz-ú társasház 2.lakásának D-i belső alsó sarokpontja', '102');
INSERT INTO sv_survey_point VALUES (104, '210/1/A hrsz-ú társasház 2.lakásának K-i belső alsó sarokpontja', '104');
INSERT INTO sv_survey_point VALUES (115, '210/1/A hrsz-ú társasház 2.lakásának É-i belső alsó sarokpontja', '115');
INSERT INTO sv_survey_point VALUES (114, '210/1/A hrsz-ú társasház 2.lakásának NY-i belső alsó sarokpontja', '114');
INSERT INTO sv_survey_point VALUES (116, '210/1/A hrsz-ú társasház 2.lakásának É-i belső felső sarokpontja', '116');
INSERT INTO sv_survey_point VALUES (117, '210/1/A hrsz-ú társasház 2.lakásának NY-i belső felső sarokpontja', '117');
INSERT INTO sv_survey_point VALUES (118, '210/1/A hrsz-ú társasház 2.lakásának D-i belső felső sarokpontja', '118');
INSERT INTO sv_survey_point VALUES (119, '210/1/A hrsz-ú társasház 2.lakásának K-i belső felső sarokpontja', '119');
INSERT INTO sv_survey_point VALUES (124, '210/1/A hrsz-ú társasház D-i felső sarokpontja', '124');
INSERT INTO sv_survey_point VALUES (125, '210/1/A hrsz-ú társasház K-i felső sarokpontja', '125');
INSERT INTO sv_survey_point VALUES (126, '210/1/A hrsz-ú társasház É-i felső sarokpontja', '126');
INSERT INTO sv_survey_point VALUES (127, '210/1/A hrsz-ú társasház NY-i felső sarokpontja', '127');
INSERT INTO sv_survey_point VALUES (130, '473/1/A hrsz-ú önálló épület K-i alsó sarokpontja', '130');
INSERT INTO sv_survey_point VALUES (131, '473/1/A hrsz-ú önálló épület D-i alsó sarokpontja', '131');
INSERT INTO sv_survey_point VALUES (132, '473/1/A hrsz-ú önálló épület NY-i Felső sarokpontja', '132');
INSERT INTO sv_survey_point VALUES (133, '473/1/A hrsz-ú önálló épület É-i Felső sarokpontja', '133');
INSERT INTO sv_survey_point VALUES (134, '473/1/A hrsz-ú önálló épület K-i Felső sarokpontja', '134');
INSERT INTO sv_survey_point VALUES (135, '473/1/A hrsz-ú önálló épület D-i Felső sarokpontja', '135');
INSERT INTO sv_survey_point VALUES (136, '473/1/A hrsz-ú önálló épület alsó szintének NY-i belső alsó sarokpontja', '136');
INSERT INTO sv_survey_point VALUES (137, '473/1/A hrsz-ú önálló épület alsó szintének D-i belső alsó sarokpontja', '137');
INSERT INTO sv_survey_point VALUES (138, '473/1/A hrsz-ú önálló épület alsó szintének K-i belső alsó sarokpontja', '138');
INSERT INTO sv_survey_point VALUES (139, '473/1/A hrsz-ú önálló épület alsó szintének É-i belső alsó sarokpontja', '139');
INSERT INTO sv_survey_point VALUES (140, '473/1/A hrsz-ú önálló épület alsó szintének NY-i belső felső sarokpontja', '140');
INSERT INTO sv_survey_point VALUES (141, '473/1/A hrsz-ú önálló épület alsó szintének D-i belső felső sarokpontja', '141');
INSERT INTO sv_survey_point VALUES (142, '473/1/A hrsz-ú önálló épület alsó szintének K-i belső felső sarokpontja', '142');
INSERT INTO sv_survey_point VALUES (143, '473/1/A hrsz-ú önálló épület alsó szintének É-i belső felső sarokpontja', '143');
INSERT INTO sv_survey_point VALUES (144, '473/1/A hrsz-ú önálló épület felső szintének NY-i belső alsó sarokpontja', '144');
INSERT INTO sv_survey_point VALUES (145, '473/1/A hrsz-ú önálló épület felső szintének D-i belső alsó sarokpontja', '145');
INSERT INTO sv_survey_point VALUES (146, '473/1/A hrsz-ú önálló épület felső szintének K-i belső alsó sarokpontja', '146');
INSERT INTO sv_survey_point VALUES (147, '473/1/A hrsz-ú önálló épület felső szintének É-i belső alsó sarokpontja', '147');
INSERT INTO sv_survey_point VALUES (148, '473/1/A hrsz-ú önálló épület felső szintének NY-i belső felső sarokpontja', '148');
INSERT INTO sv_survey_point VALUES (149, '473/1/A hrsz-ú önálló épület felső szintének D-i belső felső sarokpontja', '149');
INSERT INTO sv_survey_point VALUES (150, '473/1/A hrsz-ú önálló épület felső szintének K-i belső felső sarokpontja', '150');
INSERT INTO sv_survey_point VALUES (151, '473/1/A hrsz-ú önálló épület felső szintének É-i belső felső sarokpontja', '151');


--
-- Data for Name: tp_face; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO tp_face VALUES (32, '{29,27,70,69}', '0103000080010000000500000066666666B0B223415C8FC2F5DCD30B41F6285C8FC2655940C3F528DC95B2234185EB51B89CD40B417B14AE47E18A5940666666E66BB223413D0AD7A302D40B417B14AE47E18A5940666666667AB22341A4703D0A9DD30B41F6285C8FC265594066666666B0B223415C8FC2F5DCD30B41F6285C8FC2655940', NULL, 'MODEL- PARCEL - NY-i negyed');
INSERT INTO tp_face VALUES (12, '{29,27,28,24}', '0103000080010000000500000066666666B0B223415C8FC2F5DCD30B41F6285C8FC2655940C3F528DC95B2234185EB51B89CD40B417B14AE47E18A5940EC51B89EDEB223417B14AE474BD50B418FC2F5285C8F59408FC2F528F9B22341AE47E17A7AD40B410AD7A3703D6A594066666666B0B223415C8FC2F5DCD30B41F6285C8FC2655940', NULL, 'VETÜLET- PARCEL - 211/2');
INSERT INTO tp_face VALUES (25, '{59,61,64,62}', '01030000800100000005000000A4703D0A13B323413333333395D10B41C3F5285C8F425940EC51B89E50B32341333333333BD20B416666666666465940A4703D0A60B323418FC2F528E2D10B4114AE47E17A445940713D0AD71FB323416666666646D10B41713D0AD7A3405940A4703D0A13B323413333333395D10B41C3F5285C8F425940', NULL, 'VETÜLET- PARCEL - 472/2');
INSERT INTO tp_face VALUES (24, '{60,59,62,63}', '0103000080010000000500000014AE4761B9B22341AE47E17AC0D00B410AD7A3703D3A5940A4703D0A13B323413333333395D10B41C3F5285C8F425940713D0AD71FB323416666666646D10B41713D0AD7A3405940CDCCCCCCC5B22341E17A14AE71D00B41B81E85EB5138594014AE4761B9B22341AE47E17AC0D00B410AD7A3703D3A5940', NULL, 'VETÜLET- PARCEL - 472/1');
INSERT INTO tp_face VALUES (23, '{63,62,64,66,65}', '01030000800100000006000000CDCCCCCCC5B22341E17A14AE71D00B41B81E85EB51385940713D0AD71FB323416666666646D10B41713D0AD7A3405940A4703D0A60B323418FC2F528E2D10B4114AE47E17A445940295C8F4273B323415C8FC2F556D10B41E17A14AE4701594033333333DBB223417B14AE47E5CF0B4114AE47E17A345940CDCCCCCCC5B22341E17A14AE71D00B41B81E85EB51385940', NULL, 'VETÜLET- PARCEL - 471');
INSERT INTO tp_face VALUES (22, '{40,41,39,38}', '01030000800100000005000000B81E856BD0B123419A99999987CF0B41F6285C8FC235594000000000BFB12341713D0AD7F9CF0B4100000000004059400000000010B22341713D0AD7BDD00B4148E17A14AE475940C3F5285C22B223410AD7A3704DD00B41CDCCCCCCCC3C5940B81E856BD0B123419A99999987CF0B41F6285C8FC2355940', NULL, 'VETÜLET- PARCEL - 352/3');
INSERT INTO tp_face VALUES (21, '{36,51,38,39,37}', '010300008001000000060000000000000061B2234152B81E85EFD00B418FC2F5285C3F5940666666E64FB2234152B81E85C3D00B411F85EB51B83E5940C3F5285C22B223410AD7A3704DD00B41CDCCCCCCCC3C59400000000010B22341713D0AD7BDD00B4148E17A14AE4759409A99999951B22341D7A3703D5CD10B41CDCCCCCCCC4C59400000000061B2234152B81E85EFD00B418FC2F5285C3F5940', NULL, 'VETÜLET- PARCEL - 352/4');
INSERT INTO tp_face VALUES (20, '{34,35,36,37}', '010300008001000000050000009A99991966B22341000000008ED10B411F85EB51B84E5940713D0AD776B223413333333321D10B4114AE47E17A4459400000000061B2234152B81E85EFD00B418FC2F5285C3F59409A99999951B22341D7A3703D5CD10B41CDCCCCCCCC4C59409A99991966B22341000000008ED10B411F85EB51B84E5940', NULL, 'VETÜLET- PARCEL - 352/5');
INSERT INTO tp_face VALUES (19, '{45,40,38,44}', '01030000800100000005000000C3F528DCE1B12341B81E85EB15CF0B41713D0AD7A3305940B81E856BD0B123419A99999987CF0B41F6285C8FC2355940C3F5285C22B223410AD7A3704DD00B41CDCCCCCCCC3C5940B81E856B33B223411F85EB51DACF0B4148E17A14AE375940C3F528DCE1B12341B81E85EB15CF0B41713D0AD7A3305940', NULL, 'VETÜLET- PARCEL - 352/1');
INSERT INTO tp_face VALUES (17, '{48,45,44,43,47}', '01030000800100000006000000295C8F42FCB123419A9999996FCE0B410000000000305940C3F528DCE1B12341B81E85EB15CF0B41713D0AD7A3305940B81E856B33B223411F85EB51DACF0B4148E17A14AE375940D7A370BD43B22341D7A3703D00D00B41B81E85EB51385940B81E856B5DB22341A4703D0A55CF0B4148E17A14AE375940295C8F42FCB123419A9999996FCE0B410000000000305940', NULL, 'VETÜLET- PARCEL - 351/1');
INSERT INTO tp_face VALUES (16, '{47,43,52,42,46}', '01030000800100000006000000B81E856B5DB22341A4703D0A55CF0B4148E17A14AE375940D7A370BD43B22341D7A3703D00D00B41B81E85EB51385940E17A14AE61B22341295C8FC249D00B41295C8FC2F538594052B81E0589B223418FC2F528AAD00B418FC2F5285C3F5940333333B3A2B223418FC2F52804D00B411F85EB51B83E5940B81E856B5DB22341A4703D0A55CF0B4148E17A14AE375940', NULL, 'VETÜLET- PARCEL - 351/2');
INSERT INTO tp_face VALUES (15, '{48,47,46,49,50}', '01030000800100000006000000295C8F42FCB123419A9999996FCE0B410000000000305940B81E856B5DB22341A4703D0A55CF0B4148E17A14AE375940333333B3A2B223418FC2F52804D00B411F85EB51B83E59401F85EBD1B3B223410AD7A37091CF0B417B14AE47E13A59405C8FC2750DB2234148E17A14F8CD0B415C8FC2F5282C5940295C8F42FCB123419A9999996FCE0B410000000000305940', NULL, 'VETÜLET- PARCEL - 350');
INSERT INTO tp_face VALUES (14, '{30,32,33,31}', '01030000800100000005000000F6285C8F32B22341EC51B81E2FD40B4185EB51B81E95594052B81E0524B223418FC2F52888D40B41CDCCCCCCCCAC5940CDCCCCCCBFB22341A4703D0A0BD60B4185EB51B81EB55940C3F5285CCEB22341295C8FC2A7D50B413D0AD7A3709D5940F6285C8F32B22341EC51B81E2FD40B4185EB51B81E955940', NULL, 'VETÜLET- PARCEL - 213');
INSERT INTO tp_face VALUES (13, '{26,30,31,28,27}', '01030000800100000006000000295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940F6285C8F32B22341EC51B81E2FD40B4185EB51B81E955940C3F5285CCEB22341295C8FC2A7D50B413D0AD7A3709D5940EC51B89EDEB223417B14AE474BD50B418FC2F5285C8F5940C3F528DC95B2234185EB51B89CD40B417B14AE47E18A5940295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940', NULL, 'VETÜLET- PARCEL - 212');
INSERT INTO tp_face VALUES (26, '{60,59,58,55,56}', '0103000080010000000600000014AE4761B9B22341AE47E17AC0D00B410AD7A3703D3A5940A4703D0A13B323413333333395D10B41C3F5285C8F425940F6285C0FFEB2234185EB51B820D20B4166666666664659408FC2F528D6B2234185EB51B8C2D10B4152B81E85EB415940EC51B89EA4B22341CDCCCCCC46D10B41AE47E17A143E594014AE4761B9B22341AE47E17AC0D00B410AD7A3703D3A5940', NULL, 'VETÜLET- PARCEL - 473/1');
INSERT INTO tp_face VALUES (9, '{21,20,23,22}', '01030000800100000005000000CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB615940D7A370BD75B22341713D0AD779D20B41CDCCCCCCCC5C5940EC51B81EA3B223410AD7A370E9D20B411F85EB51B85E59400AD7A3708CB22341B81E85EB83D30B41A4703D0AD7635940CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB615940', NULL, 'VETÜLET- PARCEL - 210/1');
INSERT INTO tp_face VALUES (11, '{21,22,29,27,26}', '01030000800100000006000000CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB6159400AD7A3708CB22341B81E85EB83D30B41A4703D0AD763594066666666B0B223415C8FC2F5DCD30B41F6285C8FC2655940C3F528DC95B2234185EB51B89CD40B417B14AE47E18A5940295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB615940', NULL, 'VETÜLET- PARCEL - 211/1');
INSERT INTO tp_face VALUES (8, '{16,19,18,17}', '01030000800100000005000000F6285C0F7BB1234148E17A14C2D10B4185EB51B81E6559403D0AD72359B12341CDCCCCCCA8D20B411F85EB51B87E594048E17A1489B12341333333331DD30B413333333333935940C3F528DCABB12341E17A14AE2FD20B41EC51B81E856B5940F6285C0F7BB1234148E17A14C2D10B4185EB51B81E655940', NULL, 'VETÜLET- PARCEL - 126/3');
INSERT INTO tp_face VALUES (7, '{17,18,11,7}', '01030000800100000005000000C3F528DCABB12341E17A14AE2FD20B41EC51B81E856B594048E17A1489B12341333333331DD30B41333333333393594048E17A94C1B1234185EB51B8A2D30B41A4703D0AD7A359403D0AD7A3E2B123413D0AD7A3B8D20B41CDCCCCCCCC7C5940C3F528DCABB12341E17A14AE2FD20B41EC51B81E856B5940', NULL, 'VETÜLET- PARCEL - 126/2');
INSERT INTO tp_face VALUES (6, '{15,16,17,8,9}', '010300008001000000060000003333333394B12341A4703D0A19D10B41CDCCCCCCCC4C5940F6285C0F7BB1234148E17A14C2D10B4185EB51B81E655940C3F528DCABB12341E17A14AE2FD20B41EC51B81E856B594014AE4761C6B123419A99999977D20B4100000000007059401F85EBD1DDB1234152B81E85D1D10B41E17A14AE475159403333333394B12341A4703D0A19D10B41CDCCCCCCCC4C5940', NULL, 'VETÜLET- PARCEL - 125');
INSERT INTO tp_face VALUES (5, '{14,15,9,13,12}', '01030000800100000006000000295C8FC2A8B12341EC51B81E8DD00B4152B81E85EB4159403333333394B12341A4703D0A19D10B41CDCCCCCCCC4C59401F85EBD1DDB1234152B81E85D1D10B41E17A14AE4751594085EB51B8E7B1234148E17A1488D10B41E17A14AE47515940CDCCCCCCF1B123415C8FC2F53ED10B41CDCCCCCCCC4C5940295C8FC2A8B12341EC51B81E8DD00B4152B81E85EB415940', NULL, 'VETÜLET- PARCEL - 121');
INSERT INTO tp_face VALUES (4, '{12,13,9,4,3,2}', '01030000800100000007000000CDCCCCCCF1B123415C8FC2F53ED10B41CDCCCCCCCC4C594085EB51B8E7B1234148E17A1488D10B41E17A14AE475159401F85EBD1DDB1234152B81E85D1D10B41E17A14AE47515940666666E60CB2234148E17A1442D20B41AE47E17A145E5940713D0AD718B223415C8FC2F5F6D10B4148E17A14AE5759408FC2F52823B223415C8FC2F5B6D10B413333333333535940CDCCCCCCF1B123415C8FC2F53ED10B41CDCCCCCCCC4C5940', NULL, 'VETÜLET- PARCEL - 122');
INSERT INTO tp_face VALUES (3, '{7,11,10,6}', '010300008001000000050000003D0AD7A3E2B123413D0AD7A3B8D20B41CDCCCCCCCC7C594048E17A94C1B1234185EB51B8A2D30B41A4703D0AD7A3594000000080FDB123417B14AE4737D40B41D7A3703D0AA759409A99999920B22341713D0AD751D30B4100000000008059403D0AD7A3E2B123413D0AD7A3B8D20B41CDCCCCCCCC7C5940', NULL, 'VETÜLET- PARCEL - 126/1');
INSERT INTO tp_face VALUES (1, '{1,2,3,4,5}', '01030000800100000006000000AE47E1FA4FB22341F6285C8F1ED20B4166666666665659408FC2F52823B223415C8FC2F5B6D10B413333333333535940713D0AD718B223415C8FC2F5F6D10B4148E17A14AE575940666666E60CB2234148E17A1442D20B41AE47E17A145E5940295C8F423AB2234152B81E85ADD20B41E17A14AE47615940AE47E1FA4FB22341F6285C8F1ED20B416666666666565940', NULL, 'VETÜLET- PARCEL - 123');
INSERT INTO tp_face VALUES (44, '{72,73,74,75}', '010300008001000000050000005C8FC2F565B22341EC51B81E6DD30B410000000000205B40666666667AB22341A4703D0A9DD30B410000000000205B40666666E66BB223413D0AD7A302D40B410000000000205B40C3F528DC56B2234133333333CFD30B410000000000205B405C8FC2F565B22341EC51B81E6DD30B410000000000205B40', NULL, 'MODEL- BUILDING - Emelet teteje-211/1');
INSERT INTO tp_face VALUES (42, '{75,74,78,79}', '01030000800100000005000000C3F528DC56B2234133333333CFD30B410000000000205B40666666E66BB223413D0AD7A302D40B410000000000205B400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A475A40C3F528DC56B2234133333333CFD30B410000000000205B40', NULL, 'MODEL- BUILDING - Emelet É-i fala-211/1');
INSERT INTO tp_face VALUES (39, '{75,72,73,74}', '01030000800100000005000000C3F528DC56B2234133333333CFD30B410000000000205B405C8FC2F565B22341EC51B81E6DD30B410000000000205B40666666667AB22341A4703D0A9DD30B410000000000205B40666666E66BB223413D0AD7A302D40B410000000000205B40C3F528DC56B2234133333333CFD30B410000000000205B40', NULL, 'MODEL- BUILDING - Ház felső lapja-211/1');
INSERT INTO tp_face VALUES (33, '{71,70,27,26}', '01030000800100000005000000C3F528DC56B2234133333333CFD30B41D7A3703D0A875940666666E66BB223413D0AD7A302D40B417B14AE47E18A5940C3F528DC95B2234185EB51B89CD40B417B14AE47E18A5940295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940C3F528DC56B2234133333333CFD30B41D7A3703D0A875940', NULL, 'MODEL- PARCEL - É-i negyed');
INSERT INTO tp_face VALUES (41, '{73,77,78,74}', '01030000800100000005000000666666667AB22341A4703D0A9DD30B410000000000205B4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A40666666E66BB223413D0AD7A302D40B410000000000205B40666666667AB22341A4703D0A9DD30B410000000000205B40', NULL, 'MODEL- BUILDING - Emelet K-i fala-211/1');
INSERT INTO tp_face VALUES (30, '{21,68,71,26}', '01030000800100000005000000CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB6159405C8FC2F565B22341EC51B81E6DD30B4152B81E85EB615940C3F528DC56B2234133333333CFD30B41D7A3703D0A875940295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB615940', NULL, 'MODEL- PARCEL - K-i negyed');
INSERT INTO tp_face VALUES (38, '{72,75,71,68}', '010300008001000000050000005C8FC2F565B22341EC51B81E6DD30B410000000000205B40C3F528DC56B2234133333333CFD30B410000000000205B40C3F528DC56B2234133333333CFD30B41D7A3703D0A8759405C8FC2F565B22341EC51B81E6DD30B4152B81E85EB6159405C8FC2F565B22341EC51B81E6DD30B410000000000205B40', NULL, 'MODEL- BUILDING - Ház NY-i fala-211/1');
INSERT INTO tp_face VALUES (29, '{55,54,67,57,58}', '010300008001000000060000008FC2F528D6B2234185EB51B8C2D10B4152B81E85EB415940CDCCCCCCBFB22341AE47E17A60D20B41EC51B81E854B5940E17A14AE22B32341666666665AD30B41B81E85EB515859401F85EB513DB32341713D0AD7B5D20B41CDCCCCCCCC4C5940F6285C0FFEB2234185EB51B820D20B4166666666664659408FC2F528D6B2234185EB51B8C2D10B4152B81E85EB415940', NULL, 'VETÜLET- PARCEL - 474/2');
INSERT INTO tp_face VALUES (28, '{56,53,54,55}', '01030000800100000005000000EC51B89EA4B22341CDCCCCCC46D10B41AE47E17A143E59400AD7A3F08BB2234152B81E85E9D10B41B81E85EB51485940CDCCCCCCBFB22341AE47E17A60D20B41EC51B81E854B59408FC2F528D6B2234185EB51B8C2D10B4152B81E85EB415940EC51B89EA4B22341CDCCCCCC46D10B41AE47E17A143E5940', NULL, 'VETÜLET- PARCEL - 474/1');
INSERT INTO tp_face VALUES (27, '{58,57,61,59}', '01030000800100000005000000F6285C0FFEB2234185EB51B820D20B4166666666664659401F85EB513DB32341713D0AD7B5D20B41CDCCCCCCCC4C5940EC51B89E50B32341333333333BD20B416666666666465940A4703D0A13B323413333333395D10B41C3F5285C8F425940F6285C0FFEB2234185EB51B820D20B416666666666465940', NULL, 'VETÜLET- PARCEL - 473/2');
INSERT INTO tp_face VALUES (18, '{44,38,51,36,35,42,52,43}', '01030000800100000009000000B81E856B33B223411F85EB51DACF0B4148E17A14AE375940C3F5285C22B223410AD7A3704DD00B41CDCCCCCCCC3C5940666666E64FB2234152B81E85C3D00B411F85EB51B83E59400000000061B2234152B81E85EFD00B418FC2F5285C3F5940713D0AD776B223413333333321D10B4114AE47E17A44594052B81E0589B223418FC2F528AAD00B418FC2F5285C3F5940E17A14AE61B22341295C8FC249D00B41295C8FC2F5385940D7A370BD43B22341D7A3703D00D00B41B81E85EB51385940B81E856B33B223411F85EB51DACF0B4148E17A14AE375940', NULL, 'VETÜLET- PARCEL - 352/2');
INSERT INTO tp_face VALUES (2, '{9,4,5,6,7,8}', '010300008001000000070000001F85EBD1DDB1234152B81E85D1D10B41E17A14AE47515940666666E60CB2234148E17A1442D20B41AE47E17A145E5940295C8F423AB2234152B81E85ADD20B41E17A14AE476159409A99999920B22341713D0AD751D30B4100000000008059403D0AD7A3E2B123413D0AD7A3B8D20B41CDCCCCCCCC7C594014AE4761C6B123419A99999977D20B4100000000007059401F85EBD1DDB1234152B81E85D1D10B41E17A14AE47515940', NULL, 'VETÜLET- PARCEL - 124');
INSERT INTO tp_face VALUES (36, '{69,70,74,73}', '01030000800100000005000000666666667AB22341A4703D0A9DD30B41F6285C8FC2655940666666E66BB223413D0AD7A302D40B417B14AE47E18A5940666666E66BB223413D0AD7A302D40B410000000000205B40666666667AB22341A4703D0A9DD30B410000000000205B40666666667AB22341A4703D0A9DD30B41F6285C8FC2655940', NULL, 'MODEL- BUILDING - Ház K-i fala-211/1');
INSERT INTO tp_face VALUES (31, '{21,29,69,68}', '01030000800100000005000000CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB61594066666666B0B223415C8FC2F5DCD30B41F6285C8FC2655940666666667AB22341A4703D0A9DD30B41F6285C8FC26559405C8FC2F565B22341EC51B81E6DD30B4152B81E85EB615940CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB615940', NULL, 'MODEL- PARCEL - D-i negyed');
INSERT INTO tp_face VALUES (40, '{76,77,73,72}', '010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A40666666667AB22341A4703D0A9DD30B410000000000205B405C8FC2F565B22341EC51B81E6DD30B410000000000205B401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40', NULL, 'MODEL- BUILDING - Emelet D-i fala-211/1');
INSERT INTO tp_face VALUES (47, '{77,69,70,78}', '0103000080010000000500000048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A40666666667AB22341A4703D0A9DD30B41F6285C8FC2655940666666E66BB223413D0AD7A302D40B417B14AE47E18A59400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A40', NULL, 'MODEL- BUILDING - földszint K-i fala-211/1');
INSERT INTO tp_face VALUES (43, '{72,75,79,76}', '010300008001000000050000005C8FC2F565B22341EC51B81E6DD30B410000000000205B40C3F528DC56B2234133333333CFD30B410000000000205B40B81E856B58B223419A999999CDD30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A405C8FC2F565B22341EC51B81E6DD30B410000000000205B40', NULL, 'MODEL- BUILDING - Emelet NY-i fala-211/1');
INSERT INTO tp_face VALUES (61, '{95,92,84,87}', '01030000800100000005000000A4703D0AE5B12341CDCCCCCC58D20B413333333333135A4052B81E05DEB1234114AE47E18AD20B413333333333135A4052B81E05DEB1234114AE47E18AD20B413333333333535940A4703D0AE5B12341CDCCCCCC58D20B413333333333535940A4703D0AE5B12341CDCCCCCC58D20B413333333333135A40', NULL, 'MODEL- BUILDING - Belső Ház K-i fala-124');
INSERT INTO tp_face VALUES (45, '{76,79,78,77}', '010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40', NULL, 'MODEL- BUILDING - Emelet alja-211/1');
INSERT INTO tp_face VALUES (88, '{120,121,103,105}', '0103000080010000000500000052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A40666666666EB223419A999999B5D20B41CDCCCCCCCCEC5A40666666666EB223419A999999B5D20B410000000000405A4052B81E859AB223410AD7A3701BD30B410000000000405A4052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A40', NULL, 'MODEL- BUILDING - 210/1/A épület emeleti folyosójának D-i fala');
INSERT INTO tp_face VALUES (118, '{97,101,98,99,100,96}', '01030000800100000007000000EC51B89E5FB223410000000018D30B4100000000008059408FC2F5A87AB2234148E17A1456D30B41000000000080594048E17A148CB22341713D0AD77DD30B4100000000008059403D0AD7A3A1B2234114AE47E1EAD20B410000000000805940F6285C8F90B22341CDCCCCCCC0D20B41000000000080594014AE476176B223411F85EB5180D20B410000000000805940EC51B89E5FB223410000000018D30B410000000000805940', NULL, '210/1 hrsz épület alsó szint alapterületének vetülete.
');
INSERT INTO tp_face VALUES (50, '{79,76,77,78}', '01030000800100000005000000B81E856B58B223419A999999CDD30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A475A40', NULL, 'MODEL- BUILDING - Földszint teteje-211/1');
INSERT INTO tp_face VALUES (53, '{88,91,83,80}', '01030000800100000005000000295C8F4219B223410AD7A37015D30B413333333333335A401F85EB5129B223417B14AE47B1D20B413333333333335A401F85EB5129B223417B14AE47B1D20B416666666666765940295C8F4219B223410AD7A37015D30B419A99999999795940295C8F4219B223410AD7A37015D30B413333333333335A40', NULL, 'MODEL- BUILDING - Ház K-i fala-124');
INSERT INTO tp_face VALUES (55, '{89,88,80,81}', '010300008001000000050000000AD7A3F007B223411F85EB51ECD20B413333333333335A40295C8F4219B223410AD7A37015D30B413333333333335A40295C8F4219B223410AD7A37015D30B419A999999997959400AD7A3F007B223411F85EB51ECD20B419A999999997959400AD7A3F007B223411F85EB51ECD20B413333333333335A40', NULL, 'MODEL- BUILDING - Ház É-i fala-124');
INSERT INTO tp_face VALUES (56, '{88,89,90,91}', '01030000800100000005000000295C8F4219B223410AD7A37015D30B413333333333335A400AD7A3F007B223411F85EB51ECD20B413333333333335A40F6285C8F17B223417B14AE4787D20B413333333333335A401F85EB5129B223417B14AE47B1D20B413333333333335A40295C8F4219B223410AD7A37015D30B413333333333335A40', NULL, 'MODEL- BUILDING - Ház teteje-124');
INSERT INTO tp_face VALUES (58, '{86,94,95,87}', '0103000080010000000500000014AE4761F3B12341295C8FC279D20B41000000000060594014AE4761F3B12341295C8FC279D20B413333333333135A40A4703D0AE5B12341CDCCCCCC58D20B413333333333135A40A4703D0AE5B12341CDCCCCCC58D20B41333333333353594014AE4761F3B12341295C8FC279D20B410000000000605940', NULL, 'MODEL- BUILDING - Belső Ház D-i fala-124');
INSERT INTO tp_face VALUES (59, '{85,93,94,86}', '0103000080010000000500000085EB51B8ECB12341D7A3703DAAD20B41000000000060594085EB51B8ECB12341D7A3703DAAD20B413333333333135A4014AE4761F3B12341295C8FC279D20B413333333333135A4014AE4761F3B12341295C8FC279D20B41000000000060594085EB51B8ECB12341D7A3703DAAD20B410000000000605940', NULL, 'MODEL- BUILDING - Belső Ház K-i fala-124');
INSERT INTO tp_face VALUES (60, '{92,93,85,84}', '0103000080010000000500000052B81E05DEB1234114AE47E18AD20B413333333333135A4085EB51B8ECB12341D7A3703DAAD20B413333333333135A4085EB51B8ECB12341D7A3703DAAD20B41000000000060594052B81E05DEB1234114AE47E18AD20B41333333333353594052B81E05DEB1234114AE47E18AD20B413333333333135A40', NULL, 'MODEL- BUILDING - Belső Ház É-i fala-124');
INSERT INTO tp_face VALUES (10, '{23,22,29,24,25}', '01030000800100000006000000EC51B81EA3B223410AD7A370E9D20B411F85EB51B85E59400AD7A3708CB22341B81E85EB83D30B41A4703D0AD763594066666666B0B223415C8FC2F5DCD30B41F6285C8FC26559408FC2F528F9B22341AE47E17A7AD40B410AD7A3703D6A5940EC51B81E0EB32341D7A3703DEAD30B4185EB51B81E655940EC51B81EA3B223410AD7A370E9D20B411F85EB51B85E5940', NULL, 'VETÜLET- PARCEL - 210/2');
INSERT INTO tp_face VALUES (63, '{84,85,86,87}', '0103000080010000000500000052B81E05DEB1234114AE47E18AD20B41333333333353594085EB51B8ECB12341D7A3703DAAD20B41000000000060594014AE4761F3B12341295C8FC279D20B410000000000605940A4703D0AE5B12341CDCCCCCC58D20B41333333333353594052B81E05DEB1234114AE47E18AD20B413333333333535940', NULL, 'MODEL- BUILDING - Belső Ház alső födém-124');
INSERT INTO tp_face VALUES (62, '{95,94,93,92}', '01030000800100000005000000A4703D0AE5B12341CDCCCCCC58D20B413333333333135A4014AE4761F3B12341295C8FC279D20B413333333333135A4085EB51B8ECB12341D7A3703DAAD20B413333333333135A4052B81E05DEB1234114AE47E18AD20B413333333333135A40A4703D0AE5B12341CDCCCCCC58D20B413333333333135A40', NULL, 'MODEL- BUILDING - Belső Ház tető fala-124');
INSERT INTO tp_face VALUES (64, '{21,20,124,127}', '01030000800100000005000000CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB615940D7A370BD75B22341713D0AD779D20B41CDCCCCCCCC5C5940D7A370BD75B22341713D0AD779D20B410000000000005B40CDCCCCCC5DB22341C3F5285C19D30B410000000000005B40CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB615940', NULL, 'MODEL- BUILDING - 210/1/A épület NY-i fala');
INSERT INTO tp_face VALUES (65, '{125,124,20,23}', '01030000800100000005000000EC51B81EA3B223410AD7A370E9D20B410000000000005B40D7A370BD75B22341713D0AD779D20B410000000000005B40D7A370BD75B22341713D0AD779D20B41CDCCCCCCCC5C5940EC51B81EA3B223410AD7A370E9D20B411F85EB51B85E5940EC51B81EA3B223410AD7A370E9D20B410000000000005B40', NULL, 'MODEL- BUILDING - 210/1/A épület D-i fala');
INSERT INTO tp_face VALUES (52, '{90,82,83,91}', '01030000800100000005000000F6285C8F17B223417B14AE4787D20B413333333333335A40F6285C8F17B223417B14AE4787D20B4133333333337359401F85EB5129B223417B14AE47B1D20B4166666666667659401F85EB5129B223417B14AE47B1D20B413333333333335A40F6285C8F17B223417B14AE4787D20B413333333333335A40', NULL, 'MODEL- BUILDING - Ház D-i fala-124');
INSERT INTO tp_face VALUES (54, '{90,89,81,82}', '01030000800100000005000000F6285C8F17B223417B14AE4787D20B413333333333335A400AD7A3F007B223411F85EB51ECD20B413333333333335A400AD7A3F007B223411F85EB51ECD20B419A99999999795940F6285C8F17B223417B14AE4787D20B413333333333735940F6285C8F17B223417B14AE4787D20B413333333333335A40', NULL, 'MODEL- BUILDING - Ház É-i fala-124');
INSERT INTO tp_face VALUES (57, '{82,81,80,83}', '01030000800100000005000000F6285C8F17B223417B14AE4787D20B4133333333337359400AD7A3F007B223411F85EB51ECD20B419A99999999795940295C8F4219B223410AD7A37015D30B419A999999997959401F85EB5129B223417B14AE47B1D20B416666666666765940F6285C8F17B223417B14AE4787D20B413333333333735940', NULL, 'MODEL- BUILDING - Ház alsó födém-124');
INSERT INTO tp_face VALUES (68, '{127,124,125,126}', '01030000800100000005000000CDCCCCCC5DB22341C3F5285C19D30B410000000000005B40D7A370BD75B22341713D0AD779D20B410000000000005B40EC51B81EA3B223410AD7A370E9D20B410000000000005B400AD7A3708CB22341B81E85EB83D30B410000000000005B40CDCCCCCC5DB22341C3F5285C19D30B410000000000005B40', NULL, 'MODEL- BUILDING - 210/1/A épület felső födém');
INSERT INTO tp_face VALUES (66, '{126,125,23,22}', '010300008001000000050000000AD7A3708CB22341B81E85EB83D30B410000000000005B40EC51B81EA3B223410AD7A370E9D20B410000000000005B40EC51B81EA3B223410AD7A370E9D20B411F85EB51B85E59400AD7A3708CB22341B81E85EB83D30B41A4703D0AD76359400AD7A3708CB22341B81E85EB83D30B410000000000005B40', NULL, 'MODEL- BUILDING - 210/1/A épület K-i fala');
INSERT INTO tp_face VALUES (121, '{85,81,7}', '0103000080010000000400000085EB51B8ECB12341D7A3703DAAD20B4100000000006059400AD7A3F007B223411F85EB51ECD20B419A999999997959403D0AD7A3E2B123413D0AD7A3B8D20B41CDCCCCCCCC7C594085EB51B8ECB12341D7A3703DAAD20B410000000000605940', NULL, 'MODEL - PARCEL - 124 hrsz-ú földrészlet a model számára');
INSERT INTO tp_face VALUES (123, '{4,82,86}', '01030000800100000004000000666666E60CB2234148E17A1442D20B41AE47E17A145E5940F6285C8F17B223417B14AE4787D20B41333333333373594014AE4761F3B12341295C8FC279D20B410000000000605940666666E60CB2234148E17A1442D20B41AE47E17A145E5940', NULL, 'MODEL - PARCEL - 124 hrsz-ú földrészlet a model számára');
INSERT INTO tp_face VALUES (67, '{20,21,22,23}', '01030000800100000005000000D7A370BD75B22341713D0AD779D20B41CDCCCCCCCC5C5940CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB6159400AD7A3708CB22341B81E85EB83D30B41A4703D0AD7635940EC51B81EA3B223410AD7A370E9D20B411F85EB51B85E5940D7A370BD75B22341713D0AD779D20B41CDCCCCCCCC5C5940', NULL, 'MODEL- BUILDING - 210/1/A épület alsó födém');
INSERT INTO tp_face VALUES (71, '{106,96,100,109}', '0103000080010000000500000014AE476176B223411F85EB5180D20B41CDCCCCCCCC2C5A4014AE476176B223411F85EB5180D20B410000000000805940F6285C8F90B22341CDCCCCCCC0D20B410000000000805940F6285C8F90B22341CDCCCCCCC0D20B41CDCCCCCCCC2C5A4014AE476176B223411F85EB5180D20B41CDCCCCCCCC2C5A40', NULL, 'MODEL- BUILDING - 210/1/A épület 1. lakásának D-i fala');
INSERT INTO tp_face VALUES (72, '{108,109,100,101}', '010300008001000000050000008FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A40F6285C8F90B22341CDCCCCCCC0D20B41CDCCCCCCCC2C5A40F6285C8F90B22341CDCCCCCCC0D20B4100000000008059408FC2F5A87AB2234148E17A1456D30B4100000000008059408FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A40', NULL, 'MODEL- BUILDING - 210/1/A épület 1. lakásának K-i fala');
INSERT INTO tp_face VALUES (73, '{107,108,101,97}', '01030000800100000005000000EC51B89E5FB223410000000018D30B41CDCCCCCCCC2C5A408FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A408FC2F5A87AB2234148E17A1456D30B410000000000805940EC51B89E5FB223410000000018D30B410000000000805940EC51B89E5FB223410000000018D30B41CDCCCCCCCC2C5A40', NULL, 'MODEL- BUILDING - 210/1/A épület 1. lakásának É-i fala');
INSERT INTO tp_face VALUES (74, '{97,101,100,96}', '01030000800100000005000000EC51B89E5FB223410000000018D30B4100000000008059408FC2F5A87AB2234148E17A1456D30B410000000000805940F6285C8F90B22341CDCCCCCCC0D20B41000000000080594014AE476176B223411F85EB5180D20B410000000000805940EC51B89E5FB223410000000018D30B410000000000805940', NULL, 'MODEL- BUILDING - 210/1/A épület 1. lakásának padlója');
INSERT INTO tp_face VALUES (75, '{107,106,109,108}', '01030000800100000005000000EC51B89E5FB223410000000018D30B41CDCCCCCCCC2C5A4014AE476176B223411F85EB5180D20B41CDCCCCCCCC2C5A40F6285C8F90B22341CDCCCCCCC0D20B41CDCCCCCCCC2C5A408FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A40EC51B89E5FB223410000000018D30B41CDCCCCCCCC2C5A40', NULL, 'MODEL- BUILDING - 210/1/A épület 1. lakásának plafonja');
INSERT INTO tp_face VALUES (70, '{107,97,96,106}', '01030000800100000005000000EC51B89E5FB223410000000018D30B41CDCCCCCCCC2C5A40EC51B89E5FB223410000000018D30B41000000000080594014AE476176B223411F85EB5180D20B41000000000080594014AE476176B223411F85EB5180D20B41CDCCCCCCCC2C5A40EC51B89E5FB223410000000018D30B41CDCCCCCCCC2C5A40', NULL, 'MODEL- BUILDING - 210/1/A épület 1. lakásának NY-i fala');
INSERT INTO tp_face VALUES (76, '{117,114,102,118}', '01030000800100000005000000EC51B89E5FB223410000000018D30B41CDCCCCCCCCEC5A40EC51B89E5FB223410000000018D30B410000000000405A40EC51B81E67B2234100000000E6D20B41D7A3703D0A475A40EC51B81E67B2234100000000E6D20B41CDCCCCCCCCEC5A40EC51B89E5FB223410000000018D30B41CDCCCCCCCCEC5A40', NULL, 'MODEL- BUILDING - 210/1/A épület 2. lakásának NY-i fala');
INSERT INTO tp_face VALUES (77, '{118,102,104,119}', '01030000800100000005000000EC51B81E67B2234100000000E6D20B41CDCCCCCCCCEC5A40EC51B81E67B2234100000000E6D20B41D7A3703D0A475A40B81E856B93B22341295C8FC24BD30B410000000000405A40B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A40EC51B81E67B2234100000000E6D20B41CDCCCCCCCCEC5A40', NULL, 'MODEL- BUILDING - 210/1/A épület 2. lakásának D-i fala');
INSERT INTO tp_face VALUES (78, '{116,119,104,115}', '0103000080010000000500000048E17A148CB22341713D0AD77DD30B41CDCCCCCCCCEC5A40B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A40B81E856B93B22341295C8FC24BD30B410000000000405A4048E17A148CB22341713D0AD77DD30B410000000000405A4048E17A148CB22341713D0AD77DD30B41CDCCCCCCCCEC5A40', NULL, 'MODEL- BUILDING - 210/1/A épület 2. lakásának K-i fala');
INSERT INTO tp_face VALUES (79, '{117,116,115,114}', '01030000800100000005000000EC51B89E5FB223410000000018D30B41CDCCCCCCCCEC5A4048E17A148CB22341713D0AD77DD30B41CDCCCCCCCCEC5A4048E17A148CB22341713D0AD77DD30B410000000000405A40EC51B89E5FB223410000000018D30B410000000000405A40EC51B89E5FB223410000000018D30B41CDCCCCCCCCEC5A40', NULL, 'MODEL- BUILDING - 210/1/A épület 2. lakásának É-i fala');
INSERT INTO tp_face VALUES (80, '{119,116,117,118}', '01030000800100000005000000B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A4048E17A148CB22341713D0AD77DD30B41CDCCCCCCCCEC5A40EC51B89E5FB223410000000018D30B41CDCCCCCCCCEC5A40EC51B81E67B2234100000000E6D20B41CDCCCCCCCCEC5A40B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A40', NULL, 'MODEL- BUILDING - 210/1/A épület 2. lakásának plafonja');
INSERT INTO tp_face VALUES (82, '{122,113,112,123}', '0103000080010000000500000014AE476176B223411F85EB5180D20B41CDCCCCCCCCEC5A4014AE476176B223411F85EB5180D20B410000000000405A403D0AD7A3A1B2234114AE47E1EAD20B410000000000405A403D0AD7A3A1B2234114AE47E1EAD20B41CDCCCCCCCCEC5A4014AE476176B223411F85EB5180D20B41CDCCCCCCCCEC5A40', NULL, 'MODEL- BUILDING - 210/1/A épület 3. lakásának D-i fala');
INSERT INTO tp_face VALUES (86, '{120,121,122,123}', '0103000080010000000500000052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A40666666666EB223419A999999B5D20B41CDCCCCCCCCEC5A4014AE476176B223411F85EB5180D20B41CDCCCCCCCCEC5A403D0AD7A3A1B2234114AE47E1EAD20B41CDCCCCCCCCEC5A4052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A40', NULL, 'MODEL- BUILDING - 210/1/A épület 3. lakásának plafonja');
INSERT INTO tp_face VALUES (87, '{103,121,118,102}', '01030000800100000005000000666666666EB223419A999999B5D20B410000000000405A40666666666EB223419A999999B5D20B41CDCCCCCCCCEC5A40EC51B81E67B2234100000000E6D20B41CDCCCCCCCCEC5A40EC51B81E67B2234100000000E6D20B41D7A3703D0A475A40666666666EB223419A999999B5D20B410000000000405A40', NULL, 'MODEL- BUILDING - 210/1/A épület emeleti folyosójának NY-i fala');
INSERT INTO tp_face VALUES (90, '{118,119,104,102}', '01030000800100000005000000EC51B81E67B2234100000000E6D20B41CDCCCCCCCCEC5A40B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A40B81E856B93B22341295C8FC24BD30B410000000000405A40EC51B81E67B2234100000000E6D20B41D7A3703D0A475A40EC51B81E67B2234100000000E6D20B41CDCCCCCCCCEC5A40', NULL, 'MODEL- BUILDING - 210/1/A épület emeleti folyosójának É-i fala');
INSERT INTO tp_face VALUES (83, '{120,123,112,105}', '0103000080010000000500000052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A403D0AD7A3A1B2234114AE47E1EAD20B41CDCCCCCCCCEC5A403D0AD7A3A1B2234114AE47E1EAD20B410000000000405A4052B81E859AB223410AD7A3701BD30B410000000000405A4052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A40', NULL, 'MODEL- BUILDING - 210/1/A épület 3. lakásának K-i fala');
INSERT INTO tp_face VALUES (92, '{119,118,121,120}', '01030000800100000005000000B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A40EC51B81E67B2234100000000E6D20B41CDCCCCCCCCEC5A40666666666EB223419A999999B5D20B41CDCCCCCCCCEC5A4052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A40B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A40', NULL, 'MODEL- BUILDING - 210/1/A épület emeleti folyosójának plafonja');
INSERT INTO tp_face VALUES (97, '{101,98,99,100}', '010300008001000000050000008FC2F5A87AB2234148E17A1456D30B41000000000080594048E17A148CB22341713D0AD77DD30B4100000000008059403D0AD7A3A1B2234114AE47E1EAD20B410000000000805940F6285C8F90B22341CDCCCCCCC0D20B4100000000008059408FC2F5A87AB2234148E17A1456D30B410000000000805940', NULL, 'MODEL- BUILDING - 210/1/A épület alsószinti közös helyiségének padlója');
INSERT INTO tp_face VALUES (81, '{102,114,115,104}', '01030000800100000005000000EC51B81E67B2234100000000E6D20B41D7A3703D0A475A40EC51B89E5FB223410000000018D30B410000000000405A4048E17A148CB22341713D0AD77DD30B410000000000405A40B81E856B93B22341295C8FC24BD30B410000000000405A40EC51B81E67B2234100000000E6D20B41D7A3703D0A475A40', NULL, 'MODEL- BUILDING - 210/1/A épület 3. lakásának padlója');
INSERT INTO tp_face VALUES (89, '{119,120,105,104}', '01030000800100000005000000B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A4052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A4052B81E859AB223410AD7A3701BD30B410000000000405A40B81E856B93B22341295C8FC24BD30B410000000000405A40B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A40', NULL, 'MODEL- BUILDING - 210/1/A épület emeleti folyosójának K-i fala');
INSERT INTO tp_face VALUES (99, '{103,113,122,121}', '01030000800100000005000000666666666EB223419A999999B5D20B410000000000405A4014AE476176B223411F85EB5180D20B410000000000405A4014AE476176B223411F85EB5180D20B41CDCCCCCCCCEC5A40666666666EB223419A999999B5D20B41CDCCCCCCCCEC5A40666666666EB223419A999999B5D20B410000000000405A40', NULL, 'MODEL- BUILDING - 210/1/A épület 3. lakásának NY-i fala');
INSERT INTO tp_face VALUES (93, '{108,101,100,109}', '010300008001000000050000008FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A408FC2F5A87AB2234148E17A1456D30B410000000000805940F6285C8F90B22341CDCCCCCCC0D20B410000000000805940F6285C8F90B22341CDCCCCCCC0D20B41CDCCCCCCCC2C5A408FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A40', NULL, 'MODEL- BUILDING - 210/1/A épület alsószinti közös helyiségének NY-i fala');
INSERT INTO tp_face VALUES (94, '{111,109,100,99}', '010300008001000000050000003D0AD7A3A1B2234114AE47E1EAD20B41CDCCCCCCCC2C5A40F6285C8F90B22341CDCCCCCCC0D20B41CDCCCCCCCC2C5A40F6285C8F90B22341CDCCCCCCC0D20B4100000000008059403D0AD7A3A1B2234114AE47E1EAD20B4100000000008059403D0AD7A3A1B2234114AE47E1EAD20B41CDCCCCCCCC2C5A40', NULL, 'MODEL- BUILDING - 210/1/A épület alsószinti közös helyiségének D-i fala');
INSERT INTO tp_face VALUES (37, '{75,74,70,71}', '01030000800100000005000000C3F528DC56B2234133333333CFD30B410000000000205B40666666E66BB223413D0AD7A302D40B410000000000205B40666666E66BB223413D0AD7A302D40B417B14AE47E18A5940C3F528DC56B2234133333333CFD30B41D7A3703D0A875940C3F528DC56B2234133333333CFD30B410000000000205B40', NULL, 'MODEL- BUILDING - Ház É-i fala-211/1');
INSERT INTO tp_face VALUES (95, '{110,111,99,98}', '0103000080010000000500000048E17A148CB22341713D0AD77DD30B41CDCCCCCCCC2C5A403D0AD7A3A1B2234114AE47E1EAD20B41CDCCCCCCCC2C5A403D0AD7A3A1B2234114AE47E1EAD20B41000000000080594048E17A148CB22341713D0AD77DD30B41000000000080594048E17A148CB22341713D0AD77DD30B41CDCCCCCCCC2C5A40', NULL, 'MODEL- BUILDING - 210/1/A épület alsószinti közös helyiségének K-i fala');
INSERT INTO tp_face VALUES (96, '{108,110,98,101}', '010300008001000000050000008FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A4048E17A148CB22341713D0AD77DD30B41CDCCCCCCCC2C5A4048E17A148CB22341713D0AD77DD30B4100000000008059408FC2F5A87AB2234148E17A1456D30B4100000000008059408FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A40', NULL, 'MODEL- BUILDING - 210/1/A épület alsószinti közös helyiségének É-i fala');
INSERT INTO tp_face VALUES (98, '{110,108,109,111}', '0103000080010000000500000048E17A148CB22341713D0AD77DD30B41CDCCCCCCCC2C5A408FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A40F6285C8F90B22341CDCCCCCCC0D20B41CDCCCCCCCC2C5A403D0AD7A3A1B2234114AE47E1EAD20B41CDCCCCCCCC2C5A4048E17A148CB22341713D0AD77DD30B41CDCCCCCCCC2C5A40', NULL, 'MODEL- BUILDING - 210/1/A épület alsószinti közös helyiségének plafonja');
INSERT INTO tp_face VALUES (84, '{121,120,105,103}', '01030000800100000005000000666666666EB223419A999999B5D20B41CDCCCCCCCCEC5A4052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A4052B81E859AB223410AD7A3701BD30B410000000000405A40666666666EB223419A999999B5D20B410000000000405A40666666666EB223419A999999B5D20B41CDCCCCCCCCEC5A40', NULL, 'MODEL- BUILDING - 210/1/A épület 3. lakásának É-i (folyosói) fala');
INSERT INTO tp_face VALUES (85, '{103,105,112,113}', '01030000800100000005000000666666666EB223419A999999B5D20B410000000000405A4052B81E859AB223410AD7A3701BD30B410000000000405A403D0AD7A3A1B2234114AE47E1EAD20B410000000000405A4014AE476176B223411F85EB5180D20B410000000000405A40666666666EB223419A999999B5D20B410000000000405A40', NULL, 'MODEL- BUILDING - 210/1/A épület 3. lakásának padlója');
INSERT INTO tp_face VALUES (106, '{140,136,137,141}', '0103000080010000000500000066666666B3B223410000000040D10B410000000000005A4066666666B3B223410000000040D10B4133333333335359400AD7A3F0BFB22341295C8FC2EBD00B4133333333335359400AD7A3F0BFB22341295C8FC2EBD00B410000000000005A4066666666B3B223410000000040D10B410000000000005A40', NULL, 'MODEL- BUILDING - 473/1/A épület alsó szintjének NY-i fala');
INSERT INTO tp_face VALUES (107, '{141,137,138,142}', '010300008001000000050000000AD7A3F0BFB22341295C8FC2EBD00B410000000000005A400AD7A3F0BFB22341295C8FC2EBD00B4133333333335359401F85EBD1CFB223418FC2F52812D10B4133333333335359401F85EBD1CFB223418FC2F52812D10B410000000000005A400AD7A3F0BFB22341295C8FC2EBD00B410000000000005A40', NULL, 'MODEL- BUILDING - 473/1/A épület alsó szintjének D-i fala');
INSERT INTO tp_face VALUES (108, '{139,143,142,138}', '0103000080010000000500000014AE47E1C2B2234185EB51B866D10B41333333333353594014AE47E1C2B2234185EB51B866D10B410000000000005A401F85EBD1CFB223418FC2F52812D10B410000000000005A401F85EBD1CFB223418FC2F52812D10B41333333333353594014AE47E1C2B2234185EB51B866D10B413333333333535940', NULL, 'MODEL- BUILDING - 473/1/A épület alsó szintjének K-i fala');
INSERT INTO tp_face VALUES (109, '{140,143,139,136}', '0103000080010000000500000066666666B3B223410000000040D10B410000000000005A4014AE47E1C2B2234185EB51B866D10B410000000000005A4014AE47E1C2B2234185EB51B866D10B41333333333353594066666666B3B223410000000040D10B41333333333353594066666666B3B223410000000040D10B410000000000005A40', NULL, 'MODEL- BUILDING - 473/1/A épület alsó szintjének É-i fala');
INSERT INTO tp_face VALUES (110, '{136,139,138,137}', '0103000080010000000500000066666666B3B223410000000040D10B41333333333353594014AE47E1C2B2234185EB51B866D10B4133333333335359401F85EBD1CFB223418FC2F52812D10B4133333333335359400AD7A3F0BFB22341295C8FC2EBD00B41333333333353594066666666B3B223410000000040D10B413333333333535940', NULL, 'MODEL- BUILDING - 473/1/A épület alsó szintjének padlója');
INSERT INTO tp_face VALUES (111, '{140,141,142,143}', '0103000080010000000500000066666666B3B223410000000040D10B410000000000005A400AD7A3F0BFB22341295C8FC2EBD00B410000000000005A401F85EBD1CFB223418FC2F52812D10B410000000000005A4014AE47E1C2B2234185EB51B866D10B410000000000005A4066666666B3B223410000000040D10B410000000000005A40', NULL, 'MODEL- BUILDING - 473/1/A épület alsó szintjének plafonja');
INSERT INTO tp_face VALUES (113, '{149,145,146,150}', '010300008001000000050000000AD7A3F0BFB22341295C8FC2EBD00B410000000000C05A400AD7A3F0BFB22341295C8FC2EBD00B413333333333135A401F85EBD1CFB223418FC2F52812D10B413333333333135A401F85EBD1CFB223418FC2F52812D10B410000000000C05A400AD7A3F0BFB22341295C8FC2EBD00B410000000000C05A40', NULL, 'MODEL- BUILDING - 473/1/A épület fels[ szintjének D-i fala');
INSERT INTO tp_face VALUES (102, '{133,134,130,129}', '01030000800100000005000000D7A3703DC3B22341000000006CD10B413333333333D35A403D0AD723D1B22341A4703D0A11D10B413333333333D35A403D0AD723D1B22341A4703D0A11D10B41EC51B81E853B5940D7A3703DC3B22341000000006CD10B41AE47E17A143E5940D7A3703DC3B22341000000006CD10B413333333333D35A40', NULL, 'MODEL- BUILDING - 473/1/A épület K-i fala');
INSERT INTO tp_face VALUES (114, '{151,150,146,147}', '0103000080010000000500000014AE47E1C2B2234185EB51B866D10B410000000000C05A401F85EBD1CFB223418FC2F52812D10B410000000000C05A401F85EBD1CFB223418FC2F52812D10B413333333333135A4014AE47E1C2B2234185EB51B866D10B413333333333135A4014AE47E1C2B2234185EB51B866D10B410000000000C05A40', NULL, 'MODEL- BUILDING - 473/1/A épület fels[ szintjének K-i fala');
INSERT INTO tp_face VALUES (115, '{148,151,147,144}', '0103000080010000000500000066666666B3B223410000000040D10B410000000000C05A4014AE47E1C2B2234185EB51B866D10B410000000000C05A4014AE47E1C2B2234185EB51B866D10B413333333333135A4066666666B3B223410000000040D10B413333333333135A4066666666B3B223410000000040D10B410000000000C05A40', NULL, 'MODEL- BUILDING - 473/1/A épület fels[ szintjének É-i fala');
INSERT INTO tp_face VALUES (116, '{144,147,146,145}', '0103000080010000000500000066666666B3B223410000000040D10B413333333333135A4014AE47E1C2B2234185EB51B866D10B413333333333135A401F85EBD1CFB223418FC2F52812D10B413333333333135A400AD7A3F0BFB22341295C8FC2EBD00B413333333333135A4066666666B3B223410000000040D10B413333333333135A40', NULL, 'MODEL- BUILDING - 473/1/A épület fels[ szintjének padlója');
INSERT INTO tp_face VALUES (117, '{148,149,150,151}', '0103000080010000000500000066666666B3B223410000000040D10B410000000000C05A400AD7A3F0BFB22341295C8FC2EBD00B410000000000C05A401F85EBD1CFB223418FC2F52812D10B410000000000C05A4014AE47E1C2B2234185EB51B866D10B410000000000C05A4066666666B3B223410000000040D10B410000000000C05A40', NULL, 'MODEL- BUILDING - 473/1/A épület felső szintjének plafonja');
INSERT INTO tp_face VALUES (112, '{144,145,149,148}', '0103000080010000000500000066666666B3B223410000000040D10B413333333333135A400AD7A3F0BFB22341295C8FC2EBD00B413333333333135A400AD7A3F0BFB22341295C8FC2EBD00B410000000000C05A4066666666B3B223410000000040D10B410000000000C05A4066666666B3B223410000000040D10B413333333333135A40', NULL, 'MODEL- BUILDING - 473/1/A épület fels[ szintjének NY-i fala');
INSERT INTO tp_face VALUES (91, '{104,105,103,102}', '01030000800100000005000000B81E856B93B22341295C8FC24BD30B410000000000405A4052B81E859AB223410AD7A3701BD30B410000000000405A40666666666EB223419A999999B5D20B410000000000405A40EC51B81E67B2234100000000E6D20B41D7A3703D0A475A40B81E856B93B22341295C8FC24BD30B410000000000405A40', NULL, 'MODEL- BUILDING - 210/1/A épület emeleti folyosójának padlója');
INSERT INTO tp_face VALUES (34, '{68,71,70,69}', '010300008001000000050000005C8FC2F565B22341EC51B81E6DD30B4152B81E85EB615940C3F528DC56B2234133333333CFD30B41D7A3703D0A875940666666E66BB223413D0AD7A302D40B417B14AE47E18A5940666666667AB22341A4703D0A9DD30B41F6285C8FC26559405C8FC2F565B22341EC51B81E6DD30B4152B81E85EB615940', NULL, 'MODEL- PARCEL - Ház alja');
INSERT INTO tp_face VALUES (119, '{115,104,105,112,113,103,102,114}', '0103000080010000000900000048E17A148CB22341713D0AD77DD30B410000000000405A40B81E856B93B22341295C8FC24BD30B410000000000405A4052B81E859AB223410AD7A3701BD30B410000000000405A403D0AD7A3A1B2234114AE47E1EAD20B410000000000405A4014AE476176B223411F85EB5180D20B410000000000405A40666666666EB223419A999999B5D20B410000000000405A40EC51B81E67B2234100000000E6D20B41D7A3703D0A475A40EC51B89E5FB223410000000018D30B410000000000405A4048E17A148CB22341713D0AD77DD30B410000000000405A40', NULL, '210/1 hrsz épület felső szint alapterületének vetülete');
INSERT INTO tp_face VALUES (103, '{132,133,129,128}', '0103000080010000000500000048E17A14B2B22341A4703D0A41D10B413333333333D35A40D7A3703DC3B22341000000006CD10B413333333333D35A40D7A3703DC3B22341000000006CD10B41AE47E17A143E594048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D594048E17A14B2B22341A4703D0A41D10B413333333333D35A40', NULL, 'MODEL- BUILDING - 473/1/A épület É-i fala');
INSERT INTO tp_face VALUES (51, '{71,68,69,70}', '01030000800100000005000000C3F528DC56B2234133333333CFD30B41D7A3703D0A8759405C8FC2F565B22341EC51B81E6DD30B4152B81E85EB615940666666667AB22341A4703D0A9DD30B41F6285C8FC2655940666666E66BB223413D0AD7A302D40B417B14AE47E18A5940C3F528DC56B2234133333333CFD30B41D7A3703D0A875940', NULL, 'MODELL - PARCELLA - 211/1');
INSERT INTO tp_face VALUES (69, '{127,126,22,21}', '01030000800100000005000000CDCCCCCC5DB22341C3F5285C19D30B410000000000005B400AD7A3708CB22341B81E85EB83D30B410000000000005B400AD7A3708CB22341B81E85EB83D30B41A4703D0AD7635940CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB615940CDCCCCCC5DB22341C3F5285C19D30B410000000000005B40', NULL, 'MODEL- BUILDING - 210/1/A épület É-i fala');
INSERT INTO tp_face VALUES (120, '{8,9,87,84}', '0103000080010000000500000014AE4761C6B123419A99999977D20B4100000000007059401F85EBD1DDB1234152B81E85D1D10B41E17A14AE47515940A4703D0AE5B12341CDCCCCCC58D20B41333333333353594052B81E05DEB1234114AE47E18AD20B41333333333353594014AE4761C6B123419A99999977D20B410000000000705940', NULL, 'MODEL - PARCEL - 124 hrsz-ú földrészlet a model számára');
INSERT INTO tp_face VALUES (122, '{80,83,5,6}', '01030000800100000005000000295C8F4219B223410AD7A37015D30B419A999999997959401F85EB5129B223417B14AE47B1D20B416666666666765940295C8F423AB2234152B81E85ADD20B41E17A14AE476159409A99999920B22341713D0AD751D30B410000000000805940295C8F4219B223410AD7A37015D30B419A99999999795940', NULL, 'MODEL - PARCEL - 124 hrsz-ú földrészlet a model számára');
INSERT INTO tp_face VALUES (46, '{76,68,69,77}', '010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A405C8FC2F565B22341EC51B81E6DD30B4152B81E85EB615940666666667AB22341A4703D0A9DD30B41F6285C8FC265594048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40', NULL, 'MODEL- BUILDING - Földszint D-i fala-211/1');
INSERT INTO tp_face VALUES (105, '{132,135,134,133}', '0103000080010000000500000048E17A14B2B22341A4703D0A41D10B413333333333D35A40F6285C8FBFB22341AE47E17AE6D00B413333333333D35A403D0AD723D1B22341A4703D0A11D10B413333333333D35A40D7A3703DC3B22341000000006CD10B413333333333D35A4048E17A14B2B22341A4703D0A41D10B413333333333D35A40', NULL, 'MODEL- BUILDING - 473/1/A épület felső födémje');
INSERT INTO tp_face VALUES (126, '{81,82,83,80}', '010300008001000000050000000AD7A3F007B223411F85EB51ECD20B419A99999999795940F6285C8F17B223417B14AE4787D20B4133333333337359401F85EB5129B223417B14AE47B1D20B416666666666765940295C8F4219B223410AD7A37015D30B419A999999997959400AD7A3F007B223411F85EB51ECD20B419A99999999795940', NULL, 'MODEL - PARCEL - 124 hrsz-ú földrészlet a model számára');
INSERT INTO tp_face VALUES (127, '{9,4,86,87}', '010300008001000000050000001F85EBD1DDB1234152B81E85D1D10B41E17A14AE47515940666666E60CB2234148E17A1442D20B41AE47E17A145E594014AE4761F3B12341295C8FC279D20B410000000000605940A4703D0AE5B12341CDCCCCCC58D20B4133333333335359401F85EBD1DDB1234152B81E85D1D10B41E17A14AE47515940', NULL, 'MODEL - PARCEL - 124 hrsz-ú földrészlet a model számára');
INSERT INTO tp_face VALUES (35, '{72,68,69,73}', '010300008001000000050000005C8FC2F565B22341EC51B81E6DD30B410000000000205B405C8FC2F565B22341EC51B81E6DD30B4152B81E85EB615940666666667AB22341A4703D0A9DD30B41F6285C8FC2655940666666667AB22341A4703D0A9DD30B410000000000205B405C8FC2F565B22341EC51B81E6DD30B410000000000205B40', NULL, 'MODEL- BUILDING - Ház D-i fala-211/1');
INSERT INTO tp_face VALUES (124, '{81,85,86,82}', '010300008001000000050000000AD7A3F007B223411F85EB51ECD20B419A9999999979594085EB51B8ECB12341D7A3703DAAD20B41000000000060594014AE4761F3B12341295C8FC279D20B410000000000605940F6285C8F17B223417B14AE4787D20B4133333333337359400AD7A3F007B223411F85EB51ECD20B419A99999999795940', NULL, 'MODEL - PARCEL - 124 hrsz-ú földrészlet a model számára');
INSERT INTO tp_face VALUES (125, '{84,87,86,85}', '0103000080010000000500000052B81E05DEB1234114AE47E18AD20B413333333333535940A4703D0AE5B12341CDCCCCCC58D20B41333333333353594014AE4761F3B12341295C8FC279D20B41000000000060594085EB51B8ECB12341D7A3703DAAD20B41000000000060594052B81E05DEB1234114AE47E18AD20B413333333333535940', NULL, 'MODEL - PARCEL - 124 hrsz-ú földrészlet a model számára');
INSERT INTO tp_face VALUES (128, '{4,5,83,82}', '01030000800100000005000000666666E60CB2234148E17A1442D20B41AE47E17A145E5940295C8F423AB2234152B81E85ADD20B41E17A14AE476159401F85EB5129B223417B14AE47B1D20B416666666666765940F6285C8F17B223417B14AE4787D20B413333333333735940666666E60CB2234148E17A1442D20B41AE47E17A145E5940', NULL, 'MODEL - PARCEL - 124 hrsz-ú földrészlet a model számára');
INSERT INTO tp_face VALUES (48, '{79,78,70,71}', '01030000800100000005000000B81E856B58B223419A999999CDD30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A40666666E66BB223413D0AD7A302D40B417B14AE47E18A5940C3F528DC56B2234133333333CFD30B41D7A3703D0A875940B81E856B58B223419A999999CDD30B41D7A3703D0A475A40', NULL, 'MODEL- BUILDING - Földszint É-i fala-211/1');
INSERT INTO tp_face VALUES (49, '{76,79,71,68}', '010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A475A40C3F528DC56B2234133333333CFD30B41D7A3703D0A8759405C8FC2F565B22341EC51B81E6DD30B4152B81E85EB6159401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40', NULL, 'MODEL- BUILDING - Földszint NY-i fala-211/1');
INSERT INTO tp_face VALUES (129, '{8,84,85,7}', '0103000080010000000500000014AE4761C6B123419A99999977D20B41000000000070594052B81E05DEB1234114AE47E18AD20B41333333333353594085EB51B8ECB12341D7A3703DAAD20B4100000000006059403D0AD7A3E2B123413D0AD7A3B8D20B41CDCCCCCCCC7C594014AE4761C6B123419A99999977D20B410000000000705940', NULL, 'MODEL - PARCEL - 124 hrsz-ú földrészlet a model számára');
INSERT INTO tp_face VALUES (130, '{81,80,6,7}', '010300008001000000050000000AD7A3F007B223411F85EB51ECD20B419A99999999795940295C8F4219B223410AD7A37015D30B419A999999997959409A99999920B22341713D0AD751D30B4100000000008059403D0AD7A3E2B123413D0AD7A3B8D20B41CDCCCCCCCC7C59400AD7A3F007B223411F85EB51ECD20B419A99999999795940', NULL, 'MODEL - PARCEL - 124 hrsz-ú földrészlet a model számára');
INSERT INTO tp_face VALUES (133, '{130,59,58,129}', '010300008001000000050000003D0AD723D1B22341A4703D0A11D10B41EC51B81E853B5940A4703D0A13B323413333333395D10B41C3F5285C8F425940F6285C0FFEB2234185EB51B820D20B416666666666465940D7A3703DC3B22341000000006CD10B41AE47E17A143E59403D0AD723D1B22341A4703D0A11D10B41EC51B81E853B5940', NULL, 'MODEL - PARCEL - 473/1 hrsz-ú földrészlet a model számára');
INSERT INTO tp_face VALUES (134, '{56,128,129,58,55}', '01030000800100000006000000EC51B89EA4B22341CDCCCCCC46D10B41AE47E17A143E594048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D5940D7A3703DC3B22341000000006CD10B41AE47E17A143E5940F6285C0FFEB2234185EB51B820D20B4166666666664659408FC2F528D6B2234185EB51B8C2D10B4152B81E85EB415940EC51B89EA4B22341CDCCCCCC46D10B41AE47E17A143E5940', NULL, 'MODEL - PARCEL - 473/1 hrsz-ú földrészlet a model számára');
INSERT INTO tp_face VALUES (104, '{128,129,130,131}', '0103000080010000000500000048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D5940D7A3703DC3B22341000000006CD10B41AE47E17A143E59403D0AD723D1B22341A4703D0A11D10B41EC51B81E853B5940F6285C8FBFB22341AE47E17AE6D00B410AD7A3703D3A594048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D5940', NULL, 'MODEL- BUILDING - 473/1/A épület alsó födémje');
INSERT INTO tp_face VALUES (101, '{135,131,130,134}', '01030000800100000005000000F6285C8FBFB22341AE47E17AE6D00B413333333333D35A40F6285C8FBFB22341AE47E17AE6D00B410AD7A3703D3A59403D0AD723D1B22341A4703D0A11D10B41EC51B81E853B59403D0AD723D1B22341A4703D0A11D10B413333333333D35A40F6285C8FBFB22341AE47E17AE6D00B413333333333D35A40', NULL, 'MODEL- BUILDING - 473/1/A épület D-i fala');
INSERT INTO tp_face VALUES (100, '{128,131,135,132}', '0103000080010000000500000048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D5940F6285C8FBFB22341AE47E17AE6D00B410AD7A3703D3A5940F6285C8FBFB22341AE47E17AE6D00B413333333333D35A4048E17A14B2B22341A4703D0A41D10B413333333333D35A4048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D5940', NULL, 'MODEL- BUILDING - 473/1/A épület NY-i fala');
INSERT INTO tp_face VALUES (131, '{56,60,131,128}', '01030000800100000005000000EC51B89EA4B22341CDCCCCCC46D10B41AE47E17A143E594014AE4761B9B22341AE47E17AC0D00B410AD7A3703D3A5940F6285C8FBFB22341AE47E17AE6D00B410AD7A3703D3A594048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D5940EC51B89EA4B22341CDCCCCCC46D10B41AE47E17A143E5940', NULL, 'MODEL - PARCEL - 473/1 hrsz-ú földrészlet a model számára');
INSERT INTO tp_face VALUES (132, '{60,59,130,131}', '0103000080010000000500000014AE4761B9B22341AE47E17AC0D00B410AD7A3703D3A5940A4703D0A13B323413333333395D10B41C3F5285C8F4259403D0AD723D1B22341A4703D0A11D10B41EC51B81E853B5940F6285C8FBFB22341AE47E17AE6D00B410AD7A3703D3A594014AE4761B9B22341AE47E17AC0D00B410AD7A3703D3A5940', NULL, 'MODEL - PARCEL - 473/1 hrsz-ú földrészlet a model számára');
INSERT INTO tp_face VALUES (135, '{128,131,130,129}', '0103000080010000000500000048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D5940F6285C8FBFB22341AE47E17AE6D00B410AD7A3703D3A59403D0AD723D1B22341A4703D0A11D10B41EC51B81E853B5940D7A3703DC3B22341000000006CD10B41AE47E17A143E594048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D5940', NULL, 'MODEL - PARCEL - 473/1 hrsz-ú földrészlet a model számára');


--
-- Data for Name: tp_node; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO tp_node VALUES (65, '010100008033333333DBB223417B14AE47E5CF0B4114AE47E17A345940', NULL);
INSERT INTO tp_node VALUES (66, '0101000080295C8F4273B323415C8FC2F556D10B41E17A14AE47015940', NULL);
INSERT INTO tp_node VALUES (67, '0101000080E17A14AE22B32341666666665AD30B41B81E85EB51585940', NULL);
INSERT INTO tp_node VALUES (81, '01010000800AD7A3F007B223411F85EB51ECD20B419A99999999795940', NULL);
INSERT INTO tp_node VALUES (57, '01010000801F85EB513DB32341713D0AD7B5D20B41CDCCCCCCCC4C5940', NULL);
INSERT INTO tp_node VALUES (54, '0101000080CDCCCCCCBFB22341AE47E17A60D20B41EC51B81E854B5940', NULL);
INSERT INTO tp_node VALUES (1, '0101000080AE47E1FA4FB22341F6285C8F1ED20B416666666666565940', NULL);
INSERT INTO tp_node VALUES (2, '01010000808FC2F52823B223415C8FC2F5B6D10B413333333333535940', NULL);
INSERT INTO tp_node VALUES (3, '0101000080713D0AD718B223415C8FC2F5F6D10B4148E17A14AE575940', NULL);
INSERT INTO tp_node VALUES (4, '0101000080666666E60CB2234148E17A1442D20B41AE47E17A145E5940', NULL);
INSERT INTO tp_node VALUES (5, '0101000080295C8F423AB2234152B81E85ADD20B41E17A14AE47615940', NULL);
INSERT INTO tp_node VALUES (6, '01010000809A99999920B22341713D0AD751D30B410000000000805940', NULL);
INSERT INTO tp_node VALUES (7, '01010000803D0AD7A3E2B123413D0AD7A3B8D20B41CDCCCCCCCC7C5940', NULL);
INSERT INTO tp_node VALUES (8, '010100008014AE4761C6B123419A99999977D20B410000000000705940', NULL);
INSERT INTO tp_node VALUES (9, '01010000801F85EBD1DDB1234152B81E85D1D10B41E17A14AE47515940', NULL);
INSERT INTO tp_node VALUES (10, '010100008000000080FDB123417B14AE4737D40B41D7A3703D0AA75940', NULL);
INSERT INTO tp_node VALUES (11, '010100008048E17A94C1B1234185EB51B8A2D30B41A4703D0AD7A35940', NULL);
INSERT INTO tp_node VALUES (12, '0101000080CDCCCCCCF1B123415C8FC2F53ED10B41CDCCCCCCCC4C5940', NULL);
INSERT INTO tp_node VALUES (13, '010100008085EB51B8E7B1234148E17A1488D10B41E17A14AE47515940', NULL);
INSERT INTO tp_node VALUES (14, '0101000080295C8FC2A8B12341EC51B81E8DD00B4152B81E85EB415940', NULL);
INSERT INTO tp_node VALUES (15, '01010000803333333394B12341A4703D0A19D10B41CDCCCCCCCC4C5940', NULL);
INSERT INTO tp_node VALUES (16, '0101000080F6285C0F7BB1234148E17A14C2D10B4185EB51B81E655940', NULL);
INSERT INTO tp_node VALUES (17, '0101000080C3F528DCABB12341E17A14AE2FD20B41EC51B81E856B5940', NULL);
INSERT INTO tp_node VALUES (18, '010100008048E17A1489B12341333333331DD30B413333333333935940', NULL);
INSERT INTO tp_node VALUES (19, '01010000803D0AD72359B12341CDCCCCCCA8D20B411F85EB51B87E5940', NULL);
INSERT INTO tp_node VALUES (20, '0101000080D7A370BD75B22341713D0AD779D20B41CDCCCCCCCC5C5940', NULL);
INSERT INTO tp_node VALUES (21, '0101000080CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB615940', NULL);
INSERT INTO tp_node VALUES (22, '01010000800AD7A3708CB22341B81E85EB83D30B41A4703D0AD7635940', NULL);
INSERT INTO tp_node VALUES (23, '0101000080EC51B81EA3B223410AD7A370E9D20B411F85EB51B85E5940', NULL);
INSERT INTO tp_node VALUES (25, '0101000080EC51B81E0EB32341D7A3703DEAD30B4185EB51B81E655940', NULL);
INSERT INTO tp_node VALUES (26, '0101000080295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940', NULL);
INSERT INTO tp_node VALUES (27, '0101000080C3F528DC95B2234185EB51B89CD40B417B14AE47E18A5940', NULL);
INSERT INTO tp_node VALUES (28, '0101000080EC51B89EDEB223417B14AE474BD50B418FC2F5285C8F5940', NULL);
INSERT INTO tp_node VALUES (29, '010100008066666666B0B223415C8FC2F5DCD30B41F6285C8FC2655940', NULL);
INSERT INTO tp_node VALUES (30, '0101000080F6285C8F32B22341EC51B81E2FD40B4185EB51B81E955940', NULL);
INSERT INTO tp_node VALUES (31, '0101000080C3F5285CCEB22341295C8FC2A7D50B413D0AD7A3709D5940', NULL);
INSERT INTO tp_node VALUES (32, '010100008052B81E0524B223418FC2F52888D40B41CDCCCCCCCCAC5940', NULL);
INSERT INTO tp_node VALUES (33, '0101000080CDCCCCCCBFB22341A4703D0A0BD60B4185EB51B81EB55940', NULL);
INSERT INTO tp_node VALUES (34, '01010000809A99991966B22341000000008ED10B411F85EB51B84E5940', NULL);
INSERT INTO tp_node VALUES (35, '0101000080713D0AD776B223413333333321D10B4114AE47E17A445940', NULL);
INSERT INTO tp_node VALUES (36, '01010000800000000061B2234152B81E85EFD00B418FC2F5285C3F5940', NULL);
INSERT INTO tp_node VALUES (37, '01010000809A99999951B22341D7A3703D5CD10B41CDCCCCCCCC4C5940', NULL);
INSERT INTO tp_node VALUES (38, '0101000080C3F5285C22B223410AD7A3704DD00B41CDCCCCCCCC3C5940', NULL);
INSERT INTO tp_node VALUES (39, '01010000800000000010B22341713D0AD7BDD00B4148E17A14AE475940', NULL);
INSERT INTO tp_node VALUES (40, '0101000080B81E856BD0B123419A99999987CF0B41F6285C8FC2355940', NULL);
INSERT INTO tp_node VALUES (41, '010100008000000000BFB12341713D0AD7F9CF0B410000000000405940', NULL);
INSERT INTO tp_node VALUES (42, '010100008052B81E0589B223418FC2F528AAD00B418FC2F5285C3F5940', NULL);
INSERT INTO tp_node VALUES (43, '0101000080D7A370BD43B22341D7A3703D00D00B41B81E85EB51385940', NULL);
INSERT INTO tp_node VALUES (44, '0101000080B81E856B33B223411F85EB51DACF0B4148E17A14AE375940', NULL);
INSERT INTO tp_node VALUES (45, '0101000080C3F528DCE1B12341B81E85EB15CF0B41713D0AD7A3305940', NULL);
INSERT INTO tp_node VALUES (46, '0101000080333333B3A2B223418FC2F52804D00B411F85EB51B83E5940', NULL);
INSERT INTO tp_node VALUES (47, '0101000080B81E856B5DB22341A4703D0A55CF0B4148E17A14AE375940', NULL);
INSERT INTO tp_node VALUES (48, '0101000080295C8F42FCB123419A9999996FCE0B410000000000305940', NULL);
INSERT INTO tp_node VALUES (49, '01010000801F85EBD1B3B223410AD7A37091CF0B417B14AE47E13A5940', NULL);
INSERT INTO tp_node VALUES (50, '01010000805C8FC2750DB2234148E17A14F8CD0B415C8FC2F5282C5940', NULL);
INSERT INTO tp_node VALUES (51, '0101000080666666E64FB2234152B81E85C3D00B411F85EB51B83E5940', NULL);
INSERT INTO tp_node VALUES (52, '0101000080E17A14AE61B22341295C8FC249D00B41295C8FC2F5385940', NULL);
INSERT INTO tp_node VALUES (53, '01010000800AD7A3F08BB2234152B81E85E9D10B41B81E85EB51485940', NULL);
INSERT INTO tp_node VALUES (55, '01010000808FC2F528D6B2234185EB51B8C2D10B4152B81E85EB415940', NULL);
INSERT INTO tp_node VALUES (56, '0101000080EC51B89EA4B22341CDCCCCCC46D10B41AE47E17A143E5940', NULL);
INSERT INTO tp_node VALUES (58, '0101000080F6285C0FFEB2234185EB51B820D20B416666666666465940', NULL);
INSERT INTO tp_node VALUES (59, '0101000080A4703D0A13B323413333333395D10B41C3F5285C8F425940', NULL);
INSERT INTO tp_node VALUES (60, '010100008014AE4761B9B22341AE47E17AC0D00B410AD7A3703D3A5940', NULL);
INSERT INTO tp_node VALUES (61, '0101000080EC51B89E50B32341333333333BD20B416666666666465940', NULL);
INSERT INTO tp_node VALUES (62, '0101000080713D0AD71FB323416666666646D10B41713D0AD7A3405940', NULL);
INSERT INTO tp_node VALUES (63, '0101000080CDCCCCCCC5B22341E17A14AE71D00B41B81E85EB51385940', NULL);
INSERT INTO tp_node VALUES (64, '0101000080A4703D0A60B323418FC2F528E2D10B4114AE47E17A445940', NULL);
INSERT INTO tp_node VALUES (83, '01010000801F85EB5129B223417B14AE47B1D20B416666666666765940', NULL);
INSERT INTO tp_node VALUES (84, '010100008052B81E05DEB1234114AE47E18AD20B413333333333535940', NULL);
INSERT INTO tp_node VALUES (85, '010100008085EB51B8ECB12341D7A3703DAAD20B410000000000605940', NULL);
INSERT INTO tp_node VALUES (72, '01010000805C8FC2F565B22341EC51B81E6DD30B410000000000205B40', 'BUILDING - 211/1');
INSERT INTO tp_node VALUES (75, '0101000080C3F528DC56B2234133333333CFD30B410000000000205B40', 'BUILDING - 211/1');
INSERT INTO tp_node VALUES (74, '0101000080666666E66BB223413D0AD7A302D40B410000000000205B40', 'BUILDING - 211/1');
INSERT INTO tp_node VALUES (71, '0101000080C3F528DC56B2234133333333CFD30B41D7A3703D0A875940', 'BUILDING - 211/1');
INSERT INTO tp_node VALUES (69, '0101000080666666667AB22341A4703D0A9DD30B41F6285C8FC2655940', 'BUILDING - 211/1');
INSERT INTO tp_node VALUES (86, '010100008014AE4761F3B12341295C8FC279D20B410000000000605940', NULL);
INSERT INTO tp_node VALUES (70, '0101000080666666E66BB223413D0AD7A302D40B417B14AE47E18A5940', 'BUILDING - 211/1');
INSERT INTO tp_node VALUES (77, '010100008048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A40', NULL);
INSERT INTO tp_node VALUES (78, '01010000800AD7A3706BB2234100000000FCD30B41D7A3703D0A475A40', NULL);
INSERT INTO tp_node VALUES (79, '0101000080B81E856B58B223419A999999CDD30B41D7A3703D0A475A40', NULL);
INSERT INTO tp_node VALUES (87, '0101000080A4703D0AE5B12341CDCCCCCC58D20B413333333333535940', NULL);
INSERT INTO tp_node VALUES (76, '01010000801F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40', NULL);
INSERT INTO tp_node VALUES (80, '0101000080295C8F4219B223410AD7A37015D30B419A99999999795940', NULL);
INSERT INTO tp_node VALUES (88, '0101000080295C8F4219B223410AD7A37015D30B413333333333335A40', NULL);
INSERT INTO tp_node VALUES (89, '01010000800AD7A3F007B223411F85EB51ECD20B413333333333335A40', NULL);
INSERT INTO tp_node VALUES (91, '01010000801F85EB5129B223417B14AE47B1D20B413333333333335A40', NULL);
INSERT INTO tp_node VALUES (92, '010100008052B81E05DEB1234114AE47E18AD20B413333333333135A40', NULL);
INSERT INTO tp_node VALUES (94, '010100008014AE4761F3B12341295C8FC279D20B413333333333135A40', NULL);
INSERT INTO tp_node VALUES (90, '0101000080F6285C8F17B223417B14AE4787D20B413333333333335A40', NULL);
INSERT INTO tp_node VALUES (93, '010100008085EB51B8ECB12341D7A3703DAAD20B413333333333135A40', NULL);
INSERT INTO tp_node VALUES (95, '0101000080A4703D0AE5B12341CDCCCCCC58D20B413333333333135A40', NULL);
INSERT INTO tp_node VALUES (96, '010100008014AE476176B223411F85EB5180D20B410000000000805940', NULL);
INSERT INTO tp_node VALUES (82, '0101000080F6285C8F17B223417B14AE4787D20B413333333333735940', NULL);
INSERT INTO tp_node VALUES (97, '0101000080EC51B89E5FB223410000000018D30B410000000000805940', NULL);
INSERT INTO tp_node VALUES (98, '010100008048E17A148CB22341713D0AD77DD30B410000000000805940', NULL);
INSERT INTO tp_node VALUES (73, '0101000080666666667AB22341A4703D0A9DD30B410000000000205B40', 'BUILDING - 211/1');
INSERT INTO tp_node VALUES (115, '010100008048E17A148CB22341713D0AD77DD30B410000000000405A40', NULL);
INSERT INTO tp_node VALUES (116, '010100008048E17A148CB22341713D0AD77DD30B41CDCCCCCCCCEC5A40', NULL);
INSERT INTO tp_node VALUES (107, '0101000080EC51B89E5FB223410000000018D30B41CDCCCCCCCC2C5A40', NULL);
INSERT INTO tp_node VALUES (114, '0101000080EC51B89E5FB223410000000018D30B410000000000405A40', NULL);
INSERT INTO tp_node VALUES (117, '0101000080EC51B89E5FB223410000000018D30B41CDCCCCCCCCEC5A40', NULL);
INSERT INTO tp_node VALUES (106, '010100008014AE476176B223411F85EB5180D20B41CDCCCCCCCC2C5A40', NULL);
INSERT INTO tp_node VALUES (113, '010100008014AE476176B223411F85EB5180D20B410000000000405A40', NULL);
INSERT INTO tp_node VALUES (122, '010100008014AE476176B223411F85EB5180D20B41CDCCCCCCCCEC5A40', NULL);
INSERT INTO tp_node VALUES (111, '01010000803D0AD7A3A1B2234114AE47E1EAD20B41CDCCCCCCCC2C5A40', NULL);
INSERT INTO tp_node VALUES (112, '01010000803D0AD7A3A1B2234114AE47E1EAD20B410000000000405A40', NULL);
INSERT INTO tp_node VALUES (123, '01010000803D0AD7A3A1B2234114AE47E1EAD20B41CDCCCCCCCCEC5A40', NULL);
INSERT INTO tp_node VALUES (109, '0101000080F6285C8F90B22341CDCCCCCCC0D20B41CDCCCCCCCC2C5A40', NULL);
INSERT INTO tp_node VALUES (108, '01010000808FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A40', NULL);
INSERT INTO tp_node VALUES (102, '0101000080EC51B81E67B2234100000000E6D20B41D7A3703D0A475A40', NULL);
INSERT INTO tp_node VALUES (118, '0101000080EC51B81E67B2234100000000E6D20B41CDCCCCCCCCEC5A40', NULL);
INSERT INTO tp_node VALUES (103, '0101000080666666666EB223419A999999B5D20B410000000000405A40', NULL);
INSERT INTO tp_node VALUES (121, '0101000080666666666EB223419A999999B5D20B41CDCCCCCCCCEC5A40', NULL);
INSERT INTO tp_node VALUES (104, '0101000080B81E856B93B22341295C8FC24BD30B410000000000405A40', NULL);
INSERT INTO tp_node VALUES (119, '0101000080B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A40', NULL);
INSERT INTO tp_node VALUES (120, '010100008052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A40', NULL);
INSERT INTO tp_node VALUES (99, '01010000803D0AD7A3A1B2234114AE47E1EAD20B410000000000805940', NULL);
INSERT INTO tp_node VALUES (100, '0101000080F6285C8F90B22341CDCCCCCCC0D20B410000000000805940', NULL);
INSERT INTO tp_node VALUES (101, '01010000808FC2F5A87AB2234148E17A1456D30B410000000000805940', NULL);
INSERT INTO tp_node VALUES (124, '0101000080D7A370BD75B22341713D0AD779D20B410000000000005B40', NULL);
INSERT INTO tp_node VALUES (125, '0101000080EC51B81EA3B223410AD7A370E9D20B410000000000005B40', NULL);
INSERT INTO tp_node VALUES (126, '01010000800AD7A3708CB22341B81E85EB83D30B410000000000005B40', NULL);
INSERT INTO tp_node VALUES (127, '0101000080CDCCCCCC5DB22341C3F5285C19D30B410000000000005B40', NULL);
INSERT INTO tp_node VALUES (110, '010100008048E17A148CB22341713D0AD77DD30B41CDCCCCCCCC2C5A40', NULL);
INSERT INTO tp_node VALUES (128, '010100008048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D5940', NULL);
INSERT INTO tp_node VALUES (129, '0101000080D7A3703DC3B22341000000006CD10B41AE47E17A143E5940', NULL);
INSERT INTO tp_node VALUES (130, '01010000803D0AD723D1B22341A4703D0A11D10B41EC51B81E853B5940', NULL);
INSERT INTO tp_node VALUES (136, '010100008066666666B3B223410000000040D10B413333333333535940', NULL);
INSERT INTO tp_node VALUES (140, '010100008066666666B3B223410000000040D10B410000000000005A40', NULL);
INSERT INTO tp_node VALUES (144, '010100008066666666B3B223410000000040D10B413333333333135A40', NULL);
INSERT INTO tp_node VALUES (148, '010100008066666666B3B223410000000040D10B410000000000C05A40', NULL);
INSERT INTO tp_node VALUES (137, '01010000800AD7A3F0BFB22341295C8FC2EBD00B413333333333535940', NULL);
INSERT INTO tp_node VALUES (141, '01010000800AD7A3F0BFB22341295C8FC2EBD00B410000000000005A40', NULL);
INSERT INTO tp_node VALUES (145, '01010000800AD7A3F0BFB22341295C8FC2EBD00B413333333333135A40', NULL);
INSERT INTO tp_node VALUES (149, '01010000800AD7A3F0BFB22341295C8FC2EBD00B410000000000C05A40', NULL);
INSERT INTO tp_node VALUES (138, '01010000801F85EBD1CFB223418FC2F52812D10B413333333333535940', NULL);
INSERT INTO tp_node VALUES (142, '01010000801F85EBD1CFB223418FC2F52812D10B410000000000005A40', NULL);
INSERT INTO tp_node VALUES (146, '01010000801F85EBD1CFB223418FC2F52812D10B413333333333135A40', NULL);
INSERT INTO tp_node VALUES (150, '01010000801F85EBD1CFB223418FC2F52812D10B410000000000C05A40', NULL);
INSERT INTO tp_node VALUES (139, '010100008014AE47E1C2B2234185EB51B866D10B413333333333535940', NULL);
INSERT INTO tp_node VALUES (143, '010100008014AE47E1C2B2234185EB51B866D10B410000000000005A40', NULL);
INSERT INTO tp_node VALUES (147, '010100008014AE47E1C2B2234185EB51B866D10B413333333333135A40', NULL);
INSERT INTO tp_node VALUES (151, '010100008014AE47E1C2B2234185EB51B866D10B410000000000C05A40', NULL);
INSERT INTO tp_node VALUES (132, '010100008048E17A14B2B22341A4703D0A41D10B413333333333D35A40', NULL);
INSERT INTO tp_node VALUES (133, '0101000080D7A3703DC3B22341000000006CD10B413333333333D35A40', NULL);
INSERT INTO tp_node VALUES (134, '01010000803D0AD723D1B22341A4703D0A11D10B413333333333D35A40', NULL);
INSERT INTO tp_node VALUES (135, '0101000080F6285C8FBFB22341AE47E17AE6D00B413333333333D35A40', NULL);
INSERT INTO tp_node VALUES (68, '01010000805C8FC2F565B22341EC51B81E6DD30B4152B81E85EB615940', 'BUILDING - 211/1');
INSERT INTO tp_node VALUES (105, '010100008052B81E859AB223410AD7A3701BD30B410000000000405A40', NULL);
INSERT INTO tp_node VALUES (24, '01010000808FC2F528F9B22341AE47E17A7AD40B410AD7A3703D6A5940', NULL);
INSERT INTO tp_node VALUES (131, '0101000080F6285C8FBFB22341AE47E17AE6D00B410AD7A3703D3A5940', NULL);


--
-- Data for Name: tp_volume; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO tp_volume VALUES (14, '{14}', 'PARCELL - 213 hrsz', '010F0000800100000001030000800100000005000000F6285C8F32B22341EC51B81E2FD40B4185EB51B81E95594052B81E0524B223418FC2F52888D40B41CDCCCCCCCCAC5940CDCCCCCCBFB22341A4703D0A0BD60B4185EB51B81EB55940C3F5285CCEB22341295C8FC2A7D50B413D0AD7A3709D5940F6285C8F32B22341EC51B81E2FD40B4185EB51B81E955940');
INSERT INTO tp_volume VALUES (13, '{13}', 'PARCELL - 212 hrsz', '010F0000800100000001030000800100000006000000295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940F6285C8F32B22341EC51B81E2FD40B4185EB51B81E955940C3F5285CCEB22341295C8FC2A7D50B413D0AD7A3709D5940EC51B89EDEB223417B14AE474BD50B418FC2F5285C8F5940C3F528DC95B2234185EB51B89CD40B417B14AE47E18A5940295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940');
INSERT INTO tp_volume VALUES (11, '{30,31,32,33}', 'PARCELL - 211/1 hrsz', '010F0000800400000001030000800100000005000000CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB6159405C8FC2F565B22341EC51B81E6DD30B4152B81E85EB615940C3F528DC56B2234133333333CFD30B41D7A3703D0A875940295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB61594001030000800100000005000000CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB61594066666666B0B223415C8FC2F5DCD30B41F6285C8FC2655940666666667AB22341A4703D0A9DD30B41F6285C8FC26559405C8FC2F565B22341EC51B81E6DD30B4152B81E85EB615940CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB6159400103000080010000000500000066666666B0B223415C8FC2F5DCD30B41F6285C8FC2655940C3F528DC95B2234185EB51B89CD40B417B14AE47E18A5940666666E66BB223413D0AD7A302D40B417B14AE47E18A5940666666667AB22341A4703D0A9DD30B41F6285C8FC265594066666666B0B223415C8FC2F5DCD30B41F6285C8FC265594001030000800100000005000000C3F528DC56B2234133333333CFD30B41D7A3703D0A875940666666E66BB223413D0AD7A302D40B417B14AE47E18A5940C3F528DC95B2234185EB51B89CD40B417B14AE47E18A5940295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940C3F528DC56B2234133333333CFD30B41D7A3703D0A875940');
INSERT INTO tp_volume VALUES (40, '{34,35,36,37,38,39}', 'BUILDING - 211/1 hrsz-on', '010F00008006000000010300008001000000050000005C8FC2F565B22341EC51B81E6DD30B4152B81E85EB615940C3F528DC56B2234133333333CFD30B41D7A3703D0A875940666666E66BB223413D0AD7A302D40B417B14AE47E18A5940666666667AB22341A4703D0A9DD30B41F6285C8FC26559405C8FC2F565B22341EC51B81E6DD30B4152B81E85EB615940010300008001000000050000005C8FC2F565B22341EC51B81E6DD30B410000000000205B405C8FC2F565B22341EC51B81E6DD30B4152B81E85EB615940666666667AB22341A4703D0A9DD30B41F6285C8FC2655940666666667AB22341A4703D0A9DD30B410000000000205B405C8FC2F565B22341EC51B81E6DD30B410000000000205B4001030000800100000005000000666666667AB22341A4703D0A9DD30B41F6285C8FC2655940666666E66BB223413D0AD7A302D40B417B14AE47E18A5940666666E66BB223413D0AD7A302D40B410000000000205B40666666667AB22341A4703D0A9DD30B410000000000205B40666666667AB22341A4703D0A9DD30B41F6285C8FC265594001030000800100000005000000C3F528DC56B2234133333333CFD30B410000000000205B40666666E66BB223413D0AD7A302D40B410000000000205B40666666E66BB223413D0AD7A302D40B417B14AE47E18A5940C3F528DC56B2234133333333CFD30B41D7A3703D0A875940C3F528DC56B2234133333333CFD30B410000000000205B40010300008001000000050000005C8FC2F565B22341EC51B81E6DD30B410000000000205B40C3F528DC56B2234133333333CFD30B410000000000205B40C3F528DC56B2234133333333CFD30B41D7A3703D0A8759405C8FC2F565B22341EC51B81E6DD30B4152B81E85EB6159405C8FC2F565B22341EC51B81E6DD30B410000000000205B4001030000800100000005000000C3F528DC56B2234133333333CFD30B410000000000205B405C8FC2F565B22341EC51B81E6DD30B410000000000205B40666666667AB22341A4703D0A9DD30B410000000000205B40666666E66BB223413D0AD7A302D40B410000000000205B40C3F528DC56B2234133333333CFD30B410000000000205B40');
INSERT INTO tp_volume VALUES (26, '{131,132,133,134,135}', 'PARCELL - 473/1 hrsz', '010F0000800500000001030000800100000005000000EC51B89EA4B22341CDCCCCCC46D10B41AE47E17A143E594014AE4761B9B22341AE47E17AC0D00B410AD7A3703D3A5940F6285C8FBFB22341AE47E17AE6D00B410AD7A3703D3A594048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D5940EC51B89EA4B22341CDCCCCCC46D10B41AE47E17A143E59400103000080010000000500000014AE4761B9B22341AE47E17AC0D00B410AD7A3703D3A5940A4703D0A13B323413333333395D10B41C3F5285C8F4259403D0AD723D1B22341A4703D0A11D10B41EC51B81E853B5940F6285C8FBFB22341AE47E17AE6D00B410AD7A3703D3A594014AE4761B9B22341AE47E17AC0D00B410AD7A3703D3A5940010300008001000000050000003D0AD723D1B22341A4703D0A11D10B41EC51B81E853B5940A4703D0A13B323413333333395D10B41C3F5285C8F425940F6285C0FFEB2234185EB51B820D20B416666666666465940D7A3703DC3B22341000000006CD10B41AE47E17A143E59403D0AD723D1B22341A4703D0A11D10B41EC51B81E853B594001030000800100000006000000EC51B89EA4B22341CDCCCCCC46D10B41AE47E17A143E594048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D5940D7A3703DC3B22341000000006CD10B41AE47E17A143E5940F6285C0FFEB2234185EB51B820D20B4166666666664659408FC2F528D6B2234185EB51B8C2D10B4152B81E85EB415940EC51B89EA4B22341CDCCCCCC46D10B41AE47E17A143E59400103000080010000000500000048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D5940F6285C8FBFB22341AE47E17AE6D00B410AD7A3703D3A59403D0AD723D1B22341A4703D0A11D10B41EC51B81E853B5940D7A3703DC3B22341000000006CD10B41AE47E17A143E594048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D5940');
INSERT INTO tp_volume VALUES (44, '{58,59,60,61,62,63}', 'BUILDING - 124 hrsz-on Beső épület', '010F000080060000000103000080010000000500000014AE4761F3B12341295C8FC279D20B41000000000060594014AE4761F3B12341295C8FC279D20B413333333333135A40A4703D0AE5B12341CDCCCCCC58D20B413333333333135A40A4703D0AE5B12341CDCCCCCC58D20B41333333333353594014AE4761F3B12341295C8FC279D20B4100000000006059400103000080010000000500000085EB51B8ECB12341D7A3703DAAD20B41000000000060594085EB51B8ECB12341D7A3703DAAD20B413333333333135A4014AE4761F3B12341295C8FC279D20B413333333333135A4014AE4761F3B12341295C8FC279D20B41000000000060594085EB51B8ECB12341D7A3703DAAD20B4100000000006059400103000080010000000500000052B81E05DEB1234114AE47E18AD20B413333333333135A4085EB51B8ECB12341D7A3703DAAD20B413333333333135A4085EB51B8ECB12341D7A3703DAAD20B41000000000060594052B81E05DEB1234114AE47E18AD20B41333333333353594052B81E05DEB1234114AE47E18AD20B413333333333135A4001030000800100000005000000A4703D0AE5B12341CDCCCCCC58D20B413333333333135A4052B81E05DEB1234114AE47E18AD20B413333333333135A4052B81E05DEB1234114AE47E18AD20B413333333333535940A4703D0AE5B12341CDCCCCCC58D20B413333333333535940A4703D0AE5B12341CDCCCCCC58D20B413333333333135A4001030000800100000005000000A4703D0AE5B12341CDCCCCCC58D20B413333333333135A4014AE4761F3B12341295C8FC279D20B413333333333135A4085EB51B8ECB12341D7A3703DAAD20B413333333333135A4052B81E05DEB1234114AE47E18AD20B413333333333135A40A4703D0AE5B12341CDCCCCCC58D20B413333333333135A400103000080010000000500000052B81E05DEB1234114AE47E18AD20B41333333333353594085EB51B8ECB12341D7A3703DAAD20B41000000000060594014AE4761F3B12341295C8FC279D20B410000000000605940A4703D0AE5B12341CDCCCCCC58D20B41333333333353594052B81E05DEB1234114AE47E18AD20B413333333333535940');
INSERT INTO tp_volume VALUES (43, '{52,53,55,54,56,57}', 'BUILDING - 124 hrsz-on Külső épület', '010F0000800600000001030000800100000005000000F6285C8F17B223417B14AE4787D20B413333333333335A40F6285C8F17B223417B14AE4787D20B4133333333337359401F85EB5129B223417B14AE47B1D20B4166666666667659401F85EB5129B223417B14AE47B1D20B413333333333335A40F6285C8F17B223417B14AE4787D20B413333333333335A4001030000800100000005000000295C8F4219B223410AD7A37015D30B413333333333335A401F85EB5129B223417B14AE47B1D20B413333333333335A401F85EB5129B223417B14AE47B1D20B416666666666765940295C8F4219B223410AD7A37015D30B419A99999999795940295C8F4219B223410AD7A37015D30B413333333333335A40010300008001000000050000000AD7A3F007B223411F85EB51ECD20B413333333333335A40295C8F4219B223410AD7A37015D30B413333333333335A40295C8F4219B223410AD7A37015D30B419A999999997959400AD7A3F007B223411F85EB51ECD20B419A999999997959400AD7A3F007B223411F85EB51ECD20B413333333333335A4001030000800100000005000000F6285C8F17B223417B14AE4787D20B413333333333335A400AD7A3F007B223411F85EB51ECD20B413333333333335A400AD7A3F007B223411F85EB51ECD20B419A99999999795940F6285C8F17B223417B14AE4787D20B413333333333735940F6285C8F17B223417B14AE4787D20B413333333333335A4001030000800100000005000000295C8F4219B223410AD7A37015D30B413333333333335A400AD7A3F007B223411F85EB51ECD20B413333333333335A40F6285C8F17B223417B14AE4787D20B413333333333335A401F85EB5129B223417B14AE47B1D20B413333333333335A40295C8F4219B223410AD7A37015D30B413333333333335A4001030000800100000005000000F6285C8F17B223417B14AE4787D20B4133333333337359400AD7A3F007B223411F85EB51ECD20B419A99999999795940295C8F4219B223410AD7A37015D30B419A999999997959401F85EB5129B223417B14AE47B1D20B416666666666765940F6285C8F17B223417B14AE4787D20B413333333333735940');
INSERT INTO tp_volume VALUES (46, '{70,71,72,73,74,75}', 'MODEL- BUILDING - UNIT - 210/1/A épület 1. lakás', '010F0000800600000001030000800100000005000000EC51B89E5FB223410000000018D30B41CDCCCCCCCC2C5A40EC51B89E5FB223410000000018D30B41000000000080594014AE476176B223411F85EB5180D20B41000000000080594014AE476176B223411F85EB5180D20B41CDCCCCCCCC2C5A40EC51B89E5FB223410000000018D30B41CDCCCCCCCC2C5A400103000080010000000500000014AE476176B223411F85EB5180D20B41CDCCCCCCCC2C5A4014AE476176B223411F85EB5180D20B410000000000805940F6285C8F90B22341CDCCCCCCC0D20B410000000000805940F6285C8F90B22341CDCCCCCCC0D20B41CDCCCCCCCC2C5A4014AE476176B223411F85EB5180D20B41CDCCCCCCCC2C5A40010300008001000000050000008FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A40F6285C8F90B22341CDCCCCCCC0D20B41CDCCCCCCCC2C5A40F6285C8F90B22341CDCCCCCCC0D20B4100000000008059408FC2F5A87AB2234148E17A1456D30B4100000000008059408FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A4001030000800100000005000000EC51B89E5FB223410000000018D30B41CDCCCCCCCC2C5A408FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A408FC2F5A87AB2234148E17A1456D30B410000000000805940EC51B89E5FB223410000000018D30B410000000000805940EC51B89E5FB223410000000018D30B41CDCCCCCCCC2C5A4001030000800100000005000000EC51B89E5FB223410000000018D30B4100000000008059408FC2F5A87AB2234148E17A1456D30B410000000000805940F6285C8F90B22341CDCCCCCCC0D20B41000000000080594014AE476176B223411F85EB5180D20B410000000000805940EC51B89E5FB223410000000018D30B41000000000080594001030000800100000005000000EC51B89E5FB223410000000018D30B41CDCCCCCCCC2C5A4014AE476176B223411F85EB5180D20B41CDCCCCCCCC2C5A40F6285C8F90B22341CDCCCCCCC0D20B41CDCCCCCCCC2C5A408FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A40EC51B89E5FB223410000000018D30B41CDCCCCCCCC2C5A40');
INSERT INTO tp_volume VALUES (47, '{76,77,78,79,80,81}', 'MODEL- BUILDING - UNIT - 210/1/A épület 2. lakás', '010F0000800600000001030000800100000005000000EC51B89E5FB223410000000018D30B41CDCCCCCCCCEC5A40EC51B89E5FB223410000000018D30B410000000000405A40EC51B81E67B2234100000000E6D20B41D7A3703D0A475A40EC51B81E67B2234100000000E6D20B41CDCCCCCCCCEC5A40EC51B89E5FB223410000000018D30B41CDCCCCCCCCEC5A4001030000800100000005000000EC51B81E67B2234100000000E6D20B41CDCCCCCCCCEC5A40EC51B81E67B2234100000000E6D20B41D7A3703D0A475A40B81E856B93B22341295C8FC24BD30B410000000000405A40B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A40EC51B81E67B2234100000000E6D20B41CDCCCCCCCCEC5A400103000080010000000500000048E17A148CB22341713D0AD77DD30B41CDCCCCCCCCEC5A40B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A40B81E856B93B22341295C8FC24BD30B410000000000405A4048E17A148CB22341713D0AD77DD30B410000000000405A4048E17A148CB22341713D0AD77DD30B41CDCCCCCCCCEC5A4001030000800100000005000000EC51B89E5FB223410000000018D30B41CDCCCCCCCCEC5A4048E17A148CB22341713D0AD77DD30B41CDCCCCCCCCEC5A4048E17A148CB22341713D0AD77DD30B410000000000405A40EC51B89E5FB223410000000018D30B410000000000405A40EC51B89E5FB223410000000018D30B41CDCCCCCCCCEC5A4001030000800100000005000000B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A4048E17A148CB22341713D0AD77DD30B41CDCCCCCCCCEC5A40EC51B89E5FB223410000000018D30B41CDCCCCCCCCEC5A40EC51B81E67B2234100000000E6D20B41CDCCCCCCCCEC5A40B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A4001030000800100000005000000EC51B81E67B2234100000000E6D20B41D7A3703D0A475A40EC51B89E5FB223410000000018D30B410000000000405A4048E17A148CB22341713D0AD77DD30B410000000000405A40B81E856B93B22341295C8FC24BD30B410000000000405A40EC51B81E67B2234100000000E6D20B41D7A3703D0A475A40');
INSERT INTO tp_volume VALUES (49, '{93,94,95,96,97,98}', 'MODEL- BUILDING - SHARED UNIT - 210/1/A épület alsó közös helyiség', '010F00008006000000010300008001000000050000008FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A408FC2F5A87AB2234148E17A1456D30B410000000000805940F6285C8F90B22341CDCCCCCCC0D20B410000000000805940F6285C8F90B22341CDCCCCCCC0D20B41CDCCCCCCCC2C5A408FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A40010300008001000000050000003D0AD7A3A1B2234114AE47E1EAD20B41CDCCCCCCCC2C5A40F6285C8F90B22341CDCCCCCCC0D20B41CDCCCCCCCC2C5A40F6285C8F90B22341CDCCCCCCC0D20B4100000000008059403D0AD7A3A1B2234114AE47E1EAD20B4100000000008059403D0AD7A3A1B2234114AE47E1EAD20B41CDCCCCCCCC2C5A400103000080010000000500000048E17A148CB22341713D0AD77DD30B41CDCCCCCCCC2C5A403D0AD7A3A1B2234114AE47E1EAD20B41CDCCCCCCCC2C5A403D0AD7A3A1B2234114AE47E1EAD20B41000000000080594048E17A148CB22341713D0AD77DD30B41000000000080594048E17A148CB22341713D0AD77DD30B41CDCCCCCCCC2C5A40010300008001000000050000008FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A4048E17A148CB22341713D0AD77DD30B41CDCCCCCCCC2C5A4048E17A148CB22341713D0AD77DD30B4100000000008059408FC2F5A87AB2234148E17A1456D30B4100000000008059408FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A40010300008001000000050000008FC2F5A87AB2234148E17A1456D30B41000000000080594048E17A148CB22341713D0AD77DD30B4100000000008059403D0AD7A3A1B2234114AE47E1EAD20B410000000000805940F6285C8F90B22341CDCCCCCCC0D20B4100000000008059408FC2F5A87AB2234148E17A1456D30B4100000000008059400103000080010000000500000048E17A148CB22341713D0AD77DD30B41CDCCCCCCCC2C5A408FC2F5A87AB2234148E17A1456D30B41CDCCCCCCCC2C5A40F6285C8F90B22341CDCCCCCCC0D20B41CDCCCCCCCC2C5A403D0AD7A3A1B2234114AE47E1EAD20B41CDCCCCCCCC2C5A4048E17A148CB22341713D0AD77DD30B41CDCCCCCCCC2C5A40');
INSERT INTO tp_volume VALUES (9, '{9}', 'PARCELL - 210/1 hrsz', '010F0000800100000001030000800100000005000000CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB615940D7A370BD75B22341713D0AD779D20B41CDCCCCCCCC5C5940EC51B81EA3B223410AD7A370E9D20B411F85EB51B85E59400AD7A3708CB22341B81E85EB83D30B41A4703D0AD7635940CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB615940');
INSERT INTO tp_volume VALUES (52, '{106,107,108,109,110,111}', 'MODEL- BUILDING - LEVEL - 473/1/A épület alsó szintje', '010F000080060000000103000080010000000500000066666666B3B223410000000040D10B410000000000005A4066666666B3B223410000000040D10B4133333333335359400AD7A3F0BFB22341295C8FC2EBD00B4133333333335359400AD7A3F0BFB22341295C8FC2EBD00B410000000000005A4066666666B3B223410000000040D10B410000000000005A40010300008001000000050000000AD7A3F0BFB22341295C8FC2EBD00B410000000000005A400AD7A3F0BFB22341295C8FC2EBD00B4133333333335359401F85EBD1CFB223418FC2F52812D10B4133333333335359401F85EBD1CFB223418FC2F52812D10B410000000000005A400AD7A3F0BFB22341295C8FC2EBD00B410000000000005A400103000080010000000500000014AE47E1C2B2234185EB51B866D10B41333333333353594014AE47E1C2B2234185EB51B866D10B410000000000005A401F85EBD1CFB223418FC2F52812D10B410000000000005A401F85EBD1CFB223418FC2F52812D10B41333333333353594014AE47E1C2B2234185EB51B866D10B4133333333335359400103000080010000000500000066666666B3B223410000000040D10B410000000000005A4014AE47E1C2B2234185EB51B866D10B410000000000005A4014AE47E1C2B2234185EB51B866D10B41333333333353594066666666B3B223410000000040D10B41333333333353594066666666B3B223410000000040D10B410000000000005A400103000080010000000500000066666666B3B223410000000040D10B41333333333353594014AE47E1C2B2234185EB51B866D10B4133333333335359401F85EBD1CFB223418FC2F52812D10B4133333333335359400AD7A3F0BFB22341295C8FC2EBD00B41333333333353594066666666B3B223410000000040D10B4133333333335359400103000080010000000500000066666666B3B223410000000040D10B410000000000005A400AD7A3F0BFB22341295C8FC2EBD00B410000000000005A401F85EBD1CFB223418FC2F52812D10B410000000000005A4014AE47E1C2B2234185EB51B866D10B410000000000005A4066666666B3B223410000000040D10B410000000000005A40');
INSERT INTO tp_volume VALUES (53, '{112,113,114,115,116,117}', 'MODEL- BUILDING - LEVEL - 473/1/A épület felső szintje', '010F000080060000000103000080010000000500000066666666B3B223410000000040D10B413333333333135A400AD7A3F0BFB22341295C8FC2EBD00B413333333333135A400AD7A3F0BFB22341295C8FC2EBD00B410000000000C05A4066666666B3B223410000000040D10B410000000000C05A4066666666B3B223410000000040D10B413333333333135A40010300008001000000050000000AD7A3F0BFB22341295C8FC2EBD00B410000000000C05A400AD7A3F0BFB22341295C8FC2EBD00B413333333333135A401F85EBD1CFB223418FC2F52812D10B413333333333135A401F85EBD1CFB223418FC2F52812D10B410000000000C05A400AD7A3F0BFB22341295C8FC2EBD00B410000000000C05A400103000080010000000500000014AE47E1C2B2234185EB51B866D10B410000000000C05A401F85EBD1CFB223418FC2F52812D10B410000000000C05A401F85EBD1CFB223418FC2F52812D10B413333333333135A4014AE47E1C2B2234185EB51B866D10B413333333333135A4014AE47E1C2B2234185EB51B866D10B410000000000C05A400103000080010000000500000066666666B3B223410000000040D10B410000000000C05A4014AE47E1C2B2234185EB51B866D10B410000000000C05A4014AE47E1C2B2234185EB51B866D10B413333333333135A4066666666B3B223410000000040D10B413333333333135A4066666666B3B223410000000040D10B410000000000C05A400103000080010000000500000066666666B3B223410000000040D10B413333333333135A4014AE47E1C2B2234185EB51B866D10B413333333333135A401F85EBD1CFB223418FC2F52812D10B413333333333135A400AD7A3F0BFB22341295C8FC2EBD00B413333333333135A4066666666B3B223410000000040D10B413333333333135A400103000080010000000500000066666666B3B223410000000040D10B410000000000C05A400AD7A3F0BFB22341295C8FC2EBD00B410000000000C05A401F85EBD1CFB223418FC2F52812D10B410000000000C05A4014AE47E1C2B2234185EB51B866D10B410000000000C05A4066666666B3B223410000000040D10B410000000000C05A40');
INSERT INTO tp_volume VALUES (42, '{46,47,48,49,50,34}', 'BUILDING - FÖLDSZINT - 211/1 hrsz', '010F00008006000000010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A405C8FC2F565B22341EC51B81E6DD30B4152B81E85EB615940666666667AB22341A4703D0A9DD30B41F6285C8FC265594048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A400103000080010000000500000048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A40666666667AB22341A4703D0A9DD30B41F6285C8FC2655940666666E66BB223413D0AD7A302D40B417B14AE47E18A59400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A4001030000800100000005000000B81E856B58B223419A999999CDD30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A40666666E66BB223413D0AD7A302D40B417B14AE47E18A5940C3F528DC56B2234133333333CFD30B41D7A3703D0A875940B81E856B58B223419A999999CDD30B41D7A3703D0A475A40010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A475A40C3F528DC56B2234133333333CFD30B41D7A3703D0A8759405C8FC2F565B22341EC51B81E6DD30B4152B81E85EB6159401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A4001030000800100000005000000B81E856B58B223419A999999CDD30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A475A40010300008001000000050000005C8FC2F565B22341EC51B81E6DD30B4152B81E85EB615940C3F528DC56B2234133333333CFD30B41D7A3703D0A875940666666E66BB223413D0AD7A302D40B417B14AE47E18A5940666666667AB22341A4703D0A9DD30B41F6285C8FC26559405C8FC2F565B22341EC51B81E6DD30B4152B81E85EB615940');
INSERT INTO tp_volume VALUES (41, '{40,41,42,43,44,45}', 'BUILDING - EMELET - 211/1 hrsz', '010F00008006000000010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A40666666667AB22341A4703D0A9DD30B410000000000205B405C8FC2F565B22341EC51B81E6DD30B410000000000205B401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A4001030000800100000005000000666666667AB22341A4703D0A9DD30B410000000000205B4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A40666666E66BB223413D0AD7A302D40B410000000000205B40666666667AB22341A4703D0A9DD30B410000000000205B4001030000800100000005000000C3F528DC56B2234133333333CFD30B410000000000205B40666666E66BB223413D0AD7A302D40B410000000000205B400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A475A40C3F528DC56B2234133333333CFD30B410000000000205B40010300008001000000050000005C8FC2F565B22341EC51B81E6DD30B410000000000205B40C3F528DC56B2234133333333CFD30B410000000000205B40B81E856B58B223419A999999CDD30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A405C8FC2F565B22341EC51B81E6DD30B410000000000205B40010300008001000000050000005C8FC2F565B22341EC51B81E6DD30B410000000000205B40666666667AB22341A4703D0A9DD30B410000000000205B40666666E66BB223413D0AD7A302D40B410000000000205B40C3F528DC56B2234133333333CFD30B410000000000205B405C8FC2F565B22341EC51B81E6DD30B410000000000205B40010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40');
INSERT INTO tp_volume VALUES (48, '{99,82,83,84,85,86}', 'MODEL- BUILDING - UNIT - 210/1/A épület 2. lakás', '010F0000800600000001030000800100000005000000666666666EB223419A999999B5D20B410000000000405A4014AE476176B223411F85EB5180D20B410000000000405A4014AE476176B223411F85EB5180D20B41CDCCCCCCCCEC5A40666666666EB223419A999999B5D20B41CDCCCCCCCCEC5A40666666666EB223419A999999B5D20B410000000000405A400103000080010000000500000014AE476176B223411F85EB5180D20B41CDCCCCCCCCEC5A4014AE476176B223411F85EB5180D20B410000000000405A403D0AD7A3A1B2234114AE47E1EAD20B410000000000405A403D0AD7A3A1B2234114AE47E1EAD20B41CDCCCCCCCCEC5A4014AE476176B223411F85EB5180D20B41CDCCCCCCCCEC5A400103000080010000000500000052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A403D0AD7A3A1B2234114AE47E1EAD20B41CDCCCCCCCCEC5A403D0AD7A3A1B2234114AE47E1EAD20B410000000000405A4052B81E859AB223410AD7A3701BD30B410000000000405A4052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A4001030000800100000005000000666666666EB223419A999999B5D20B41CDCCCCCCCCEC5A4052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A4052B81E859AB223410AD7A3701BD30B410000000000405A40666666666EB223419A999999B5D20B410000000000405A40666666666EB223419A999999B5D20B41CDCCCCCCCCEC5A4001030000800100000005000000666666666EB223419A999999B5D20B410000000000405A4052B81E859AB223410AD7A3701BD30B410000000000405A403D0AD7A3A1B2234114AE47E1EAD20B410000000000405A4014AE476176B223411F85EB5180D20B410000000000405A40666666666EB223419A999999B5D20B410000000000405A400103000080010000000500000052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A40666666666EB223419A999999B5D20B41CDCCCCCCCCEC5A4014AE476176B223411F85EB5180D20B41CDCCCCCCCCEC5A403D0AD7A3A1B2234114AE47E1EAD20B41CDCCCCCCCCEC5A4052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A40');
INSERT INTO tp_volume VALUES (50, '{87,88,89,90,91,92}', 'MODEL- BUILDING - SHARED UNIT - 210/1/A épület 2. felső folyosó', '010F0000800600000001030000800100000005000000666666666EB223419A999999B5D20B410000000000405A40666666666EB223419A999999B5D20B41CDCCCCCCCCEC5A40EC51B81E67B2234100000000E6D20B41CDCCCCCCCCEC5A40EC51B81E67B2234100000000E6D20B41D7A3703D0A475A40666666666EB223419A999999B5D20B410000000000405A400103000080010000000500000052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A40666666666EB223419A999999B5D20B41CDCCCCCCCCEC5A40666666666EB223419A999999B5D20B410000000000405A4052B81E859AB223410AD7A3701BD30B410000000000405A4052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A4001030000800100000005000000B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A4052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A4052B81E859AB223410AD7A3701BD30B410000000000405A40B81E856B93B22341295C8FC24BD30B410000000000405A40B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A4001030000800100000005000000EC51B81E67B2234100000000E6D20B41CDCCCCCCCCEC5A40B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A40B81E856B93B22341295C8FC24BD30B410000000000405A40EC51B81E67B2234100000000E6D20B41D7A3703D0A475A40EC51B81E67B2234100000000E6D20B41CDCCCCCCCCEC5A4001030000800100000005000000B81E856B93B22341295C8FC24BD30B410000000000405A4052B81E859AB223410AD7A3701BD30B410000000000405A40666666666EB223419A999999B5D20B410000000000405A40EC51B81E67B2234100000000E6D20B41D7A3703D0A475A40B81E856B93B22341295C8FC24BD30B410000000000405A4001030000800100000005000000B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A40EC51B81E67B2234100000000E6D20B41CDCCCCCCCCEC5A40666666666EB223419A999999B5D20B41CDCCCCCCCCEC5A4052B81E859AB223410AD7A3701BD30B41CDCCCCCCCCEC5A40B81E856B93B22341295C8FC24BD30B41CDCCCCCCCCEC5A40');
INSERT INTO tp_volume VALUES (45, '{64,65,66,67,68,69}', 'MODEL- BUILDING - 210/1/A épület', '010F0000800600000001030000800100000005000000CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB615940D7A370BD75B22341713D0AD779D20B41CDCCCCCCCC5C5940D7A370BD75B22341713D0AD779D20B410000000000005B40CDCCCCCC5DB22341C3F5285C19D30B410000000000005B40CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB61594001030000800100000005000000EC51B81EA3B223410AD7A370E9D20B410000000000005B40D7A370BD75B22341713D0AD779D20B410000000000005B40D7A370BD75B22341713D0AD779D20B41CDCCCCCCCC5C5940EC51B81EA3B223410AD7A370E9D20B411F85EB51B85E5940EC51B81EA3B223410AD7A370E9D20B410000000000005B40010300008001000000050000000AD7A3708CB22341B81E85EB83D30B410000000000005B40EC51B81EA3B223410AD7A370E9D20B410000000000005B40EC51B81EA3B223410AD7A370E9D20B411F85EB51B85E59400AD7A3708CB22341B81E85EB83D30B41A4703D0AD76359400AD7A3708CB22341B81E85EB83D30B410000000000005B4001030000800100000005000000D7A370BD75B22341713D0AD779D20B41CDCCCCCCCC5C5940CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB6159400AD7A3708CB22341B81E85EB83D30B41A4703D0AD7635940EC51B81EA3B223410AD7A370E9D20B411F85EB51B85E5940D7A370BD75B22341713D0AD779D20B41CDCCCCCCCC5C594001030000800100000005000000CDCCCCCC5DB22341C3F5285C19D30B410000000000005B40D7A370BD75B22341713D0AD779D20B410000000000005B40EC51B81EA3B223410AD7A370E9D20B410000000000005B400AD7A3708CB22341B81E85EB83D30B410000000000005B40CDCCCCCC5DB22341C3F5285C19D30B410000000000005B4001030000800100000005000000CDCCCCCC5DB22341C3F5285C19D30B410000000000005B400AD7A3708CB22341B81E85EB83D30B410000000000005B400AD7A3708CB22341B81E85EB83D30B41A4703D0AD7635940CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB615940CDCCCCCC5DB22341C3F5285C19D30B410000000000005B40');
INSERT INTO tp_volume VALUES (2, '{120,121,122,123,124,125,126,127,128,129,130}', 'PARCELL - 124 hrsz', '010F0000800B0000000103000080010000000500000014AE4761C6B123419A99999977D20B4100000000007059401F85EBD1DDB1234152B81E85D1D10B41E17A14AE47515940A4703D0AE5B12341CDCCCCCC58D20B41333333333353594052B81E05DEB1234114AE47E18AD20B41333333333353594014AE4761C6B123419A99999977D20B4100000000007059400103000080010000000400000085EB51B8ECB12341D7A3703DAAD20B4100000000006059400AD7A3F007B223411F85EB51ECD20B419A999999997959403D0AD7A3E2B123413D0AD7A3B8D20B41CDCCCCCCCC7C594085EB51B8ECB12341D7A3703DAAD20B41000000000060594001030000800100000005000000295C8F4219B223410AD7A37015D30B419A999999997959401F85EB5129B223417B14AE47B1D20B416666666666765940295C8F423AB2234152B81E85ADD20B41E17A14AE476159409A99999920B22341713D0AD751D30B410000000000805940295C8F4219B223410AD7A37015D30B419A9999999979594001030000800100000004000000666666E60CB2234148E17A1442D20B41AE47E17A145E5940F6285C8F17B223417B14AE4787D20B41333333333373594014AE4761F3B12341295C8FC279D20B410000000000605940666666E60CB2234148E17A1442D20B41AE47E17A145E5940010300008001000000050000000AD7A3F007B223411F85EB51ECD20B419A9999999979594085EB51B8ECB12341D7A3703DAAD20B41000000000060594014AE4761F3B12341295C8FC279D20B410000000000605940F6285C8F17B223417B14AE4787D20B4133333333337359400AD7A3F007B223411F85EB51ECD20B419A999999997959400103000080010000000500000052B81E05DEB1234114AE47E18AD20B413333333333535940A4703D0AE5B12341CDCCCCCC58D20B41333333333353594014AE4761F3B12341295C8FC279D20B41000000000060594085EB51B8ECB12341D7A3703DAAD20B41000000000060594052B81E05DEB1234114AE47E18AD20B413333333333535940010300008001000000050000000AD7A3F007B223411F85EB51ECD20B419A99999999795940F6285C8F17B223417B14AE4787D20B4133333333337359401F85EB5129B223417B14AE47B1D20B416666666666765940295C8F4219B223410AD7A37015D30B419A999999997959400AD7A3F007B223411F85EB51ECD20B419A99999999795940010300008001000000050000001F85EBD1DDB1234152B81E85D1D10B41E17A14AE47515940666666E60CB2234148E17A1442D20B41AE47E17A145E594014AE4761F3B12341295C8FC279D20B410000000000605940A4703D0AE5B12341CDCCCCCC58D20B4133333333335359401F85EBD1DDB1234152B81E85D1D10B41E17A14AE4751594001030000800100000005000000666666E60CB2234148E17A1442D20B41AE47E17A145E5940295C8F423AB2234152B81E85ADD20B41E17A14AE476159401F85EB5129B223417B14AE47B1D20B416666666666765940F6285C8F17B223417B14AE4787D20B413333333333735940666666E60CB2234148E17A1442D20B41AE47E17A145E59400103000080010000000500000014AE4761C6B123419A99999977D20B41000000000070594052B81E05DEB1234114AE47E18AD20B41333333333353594085EB51B8ECB12341D7A3703DAAD20B4100000000006059403D0AD7A3E2B123413D0AD7A3B8D20B41CDCCCCCCCC7C594014AE4761C6B123419A99999977D20B410000000000705940010300008001000000050000000AD7A3F007B223411F85EB51ECD20B419A99999999795940295C8F4219B223410AD7A37015D30B419A999999997959409A99999920B22341713D0AD751D30B4100000000008059403D0AD7A3E2B123413D0AD7A3B8D20B41CDCCCCCCCC7C59400AD7A3F007B223411F85EB51ECD20B419A99999999795940');
INSERT INTO tp_volume VALUES (51, '{100,101,102,103,104,105}', 'MODEL- BUILDING - 473/1/A épület', '010F000080060000000103000080010000000500000048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D5940F6285C8FBFB22341AE47E17AE6D00B410AD7A3703D3A5940F6285C8FBFB22341AE47E17AE6D00B413333333333D35A4048E17A14B2B22341A4703D0A41D10B413333333333D35A4048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D594001030000800100000005000000F6285C8FBFB22341AE47E17AE6D00B413333333333D35A40F6285C8FBFB22341AE47E17AE6D00B410AD7A3703D3A59403D0AD723D1B22341A4703D0A11D10B41EC51B81E853B59403D0AD723D1B22341A4703D0A11D10B413333333333D35A40F6285C8FBFB22341AE47E17AE6D00B413333333333D35A4001030000800100000005000000D7A3703DC3B22341000000006CD10B413333333333D35A403D0AD723D1B22341A4703D0A11D10B413333333333D35A403D0AD723D1B22341A4703D0A11D10B41EC51B81E853B5940D7A3703DC3B22341000000006CD10B41AE47E17A143E5940D7A3703DC3B22341000000006CD10B413333333333D35A400103000080010000000500000048E17A14B2B22341A4703D0A41D10B413333333333D35A40D7A3703DC3B22341000000006CD10B413333333333D35A40D7A3703DC3B22341000000006CD10B41AE47E17A143E594048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D594048E17A14B2B22341A4703D0A41D10B413333333333D35A400103000080010000000500000048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D5940D7A3703DC3B22341000000006CD10B41AE47E17A143E59403D0AD723D1B22341A4703D0A11D10B41EC51B81E853B5940F6285C8FBFB22341AE47E17AE6D00B410AD7A3703D3A594048E17A14B2B22341A4703D0A41D10B413D0AD7A3703D59400103000080010000000500000048E17A14B2B22341A4703D0A41D10B413333333333D35A40F6285C8FBFB22341AE47E17AE6D00B413333333333D35A403D0AD723D1B22341A4703D0A11D10B413333333333D35A40D7A3703DC3B22341000000006CD10B413333333333D35A4048E17A14B2B22341A4703D0A41D10B413333333333D35A40');


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
-- PostgreSQL database dump complete
--


