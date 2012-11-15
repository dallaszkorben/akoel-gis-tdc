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
	identify_cultivation_name text,
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
	view_nid bigint,
	view_angle numeric(4,2),
	view_hrsz_unit text
);


ALTER TYPE main.view_building_individual_unit OWNER TO tdc;

--
-- Name: view_parcel; Type: TYPE; Schema: main; Owner: tdc
--

CREATE TYPE view_parcel AS (
	view_geom public.geometry,
	view_nid bigint,
	view_hrsz text,
	view_angle numeric(4,2),
	view_cultivation_nid bigint,
	view_cultivation_name text
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
      cultivation.name AS identify_cultivation_name,
      parcel.area AS identify_registered_area,
      st_area(face.geom) AS identify_measured_area
    FROM 
      main.im_parcel parcel, 
      main.rt_right r,
      main.tp_face face,
      main.im_cultivation cultivation
    WHERE 
       parcel.nid=r.im_parcel AND      
       r.rt_type=1 AND 
       cultivation.nid=parcel.im_cultivation AND
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
      cultivation.name AS identify_cultivation_name,
      parcel.area AS identify_registered_area,
      st_area(face.geom) AS identify_measured_area
    FROM 
      main.im_parcel parcel, 
      main.rt_right r, 
      main.im_building building,
      main.tp_face face,
      main.im_cultivation cultivation
    WHERE 
      parcel.nid=r.im_parcel AND 
      face.gid=parcel.projection AND
      r.rt_type=1 AND
      cultivation.nid=parcel.im_cultivation AND
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
      cultivation.name AS identify_cultivation_name,
      parcel.area AS identify_registered_area,
      st_area(face.geom) AS identify_measured_area

    FROM 
      main.im_parcel parcel, 
      main.rt_right r, 
      main.im_building building,
      main.tp_face face,
      main.im_cultivation cultivation
    WHERE 
       parcel.nid=r.im_parcel AND 
       face.gid=parcel.projection AND
       r.rt_type=1 AND
       cultivation.nid=parcel.im_cultivation AND
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
      cultivation.name AS identify_cultivation_name,
      parcel.area AS identify_registered_area,
      st_area(face.geom) AS identify_measured_area
    FROM 
      main.im_parcel parcel, 
      main.im_building building, 
      main.im_building_individual_unit indunit, 
      main.rt_right r,
      main.tp_face face,
      main.im_cultivation cultivation
    WHERE 
      cultivation.nid=parcel.im_cultivation AND
      face.gid=parcel.projection AND
      building.im_settlement=parcel.im_settlement AND 
      main.hrsz_concat(building.hrsz_main,  building.hrsz_fraction)=main.hrsz_concat(parcel.hrsz_main,parcel.hrsz_fraction) AND
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
      unit.nid AS view_nid,
      unit.title_angle AS view_angle,
      unit.hrsz_unit AS view_hrsz_unit
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
      parcel.title_angle AS view_angle,
      parcel.im_cultivation AS view_cultivation_nid,
      cultivation.name AS view_cultivation_name
    FROM 
      main.im_parcel parcel, 
      main.tp_face face,
      main.im_cultivation cultivation
    WHERE 
      cultivation.nid=parcel.im_cultivation AND
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
    share_numerator integer NOT NULL,
    title_angle numeric(4,2)
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
-- Name: im_cultivation; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_cultivation (
    nid bigint NOT NULL,
    name text NOT NULL
);


ALTER TABLE main.im_cultivation OWNER TO tdc;

--
-- Name: TABLE im_cultivation; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_cultivation IS 'Művelési ág';


--
-- Name: im_cultivation_nid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE im_cultivation_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.im_cultivation_nid_seq OWNER TO tdc;

--
-- Name: im_cultivation_nid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE im_cultivation_nid_seq OWNED BY im_cultivation.nid;


SET default_with_oids = true;

--
-- Name: im_individual_shared; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_individual_shared (
    im_underpass_individual_unit bigint NOT NULL,
    im_underpass_shared_unit bigint NOT NULL,
    share_numerator integer NOT NULL
);


ALTER TABLE main.im_individual_shared OWNER TO tdc;

--
-- Name: TABLE im_individual_shared; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_individual_shared IS 'Ez a táblaköti össze az üzlethelyiségeket a közös helyiségekkel egy tulajdoni hányad-on keresztül';


SET default_with_oids = false;

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
    title_angle numeric(4,2) DEFAULT 0,
    im_cultivation bigint
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
-- Name: im_underpass_individual_unit; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass_individual_unit (
    nid bigint NOT NULL,
    hrsz_unit integer NOT NULL,
    area numeric(12,1),
    volume numeric(12,1),
    model bigint,
    im_underpass bigint NOT NULL
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
    im_underpass bigint NOT NULL,
    im_levels numeric(4,1) NOT NULL,
    area integer,
    volume integer,
    projection bigint,
    hrsz_unit integer NOT NULL
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
    im_underpass bigint NOT NULL,
    im_levels numeric(4,1) NOT NULL,
    projection bigint
);


ALTER TABLE main.im_underpass_levels OWNER TO tdc;

--
-- Name: TABLE im_underpass_levels; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_underpass_levels IS 'Egy adott aluljáróban előforduló szintek felsorolása';


SET default_with_oids = true;

--
-- Name: im_underpass_shared_unit; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass_shared_unit (
    nid bigint NOT NULL,
    name text NOT NULL,
    im_underpass bigint NOT NULL,
    hrsz_unit integer NOT NULL,
    share_denominator integer NOT NULL,
    area integer,
    volume integer,
    model bigint
);


ALTER TABLE main.im_underpass_shared_unit OWNER TO tdc;

--
-- Name: TABLE im_underpass_shared_unit; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_underpass_shared_unit IS 'Ez a tábla reprezentálja a közös tulajdonú helységeket, melyeket az egyes üzletek adott csoportja használ, üzemeltet';


--
-- Name: im_underpass_shared_unit_level; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass_shared_unit_level (
    im_underpass bigint NOT NULL,
    hrsz_unit integer NOT NULL,
    im_levels numeric(4,1),
    area integer,
    volume integer,
    projection bigint
);


ALTER TABLE main.im_underpass_shared_unit_level OWNER TO tdc;

--
-- Name: TABLE im_underpass_shared_unit_level; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_underpass_shared_unit_level IS 'Ez reprezentálja a közös helyiségeket egy adott szinten';


--
-- Name: im_underpass_shared_unit_nid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE im_underpass_shared_unit_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.im_underpass_shared_unit_nid_seq OWNER TO tdc;

--
-- Name: im_underpass_shared_unit_nid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE im_underpass_shared_unit_nid_seq OWNED BY im_underpass_shared_unit.nid;


SET default_with_oids = false;

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

ALTER TABLE ONLY im_cultivation ALTER COLUMN nid SET DEFAULT nextval('im_cultivation_nid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_individual_unit ALTER COLUMN nid SET DEFAULT nextval('im_underpass_individual_unit_nid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_shared_unit ALTER COLUMN nid SET DEFAULT nextval('im_underpass_shared_unit_nid_seq'::regclass);


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
-- Name: im_cultivation_name_key; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_cultivation
    ADD CONSTRAINT im_cultivation_name_key UNIQUE (name);


--
-- Name: im_cultivation_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_cultivation
    ADD CONSTRAINT im_cultivation_pkey PRIMARY KEY (nid);


--
-- Name: im_individual_shared_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_individual_shared
    ADD CONSTRAINT im_individual_shared_pkey PRIMARY KEY (im_underpass_individual_unit, im_underpass_shared_unit);


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
    ADD CONSTRAINT im_underpass_individual_unit_level_pkey PRIMARY KEY (im_underpass, hrsz_unit, im_levels);


--
-- Name: im_underpass_individual_unit_level_unique_im_underpass_hrsz_uni; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_individual_unit_level
    ADD CONSTRAINT im_underpass_individual_unit_level_unique_im_underpass_hrsz_uni UNIQUE (im_underpass, hrsz_unit, im_levels);


--
-- Name: im_underpass_individual_unit_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_individual_unit
    ADD CONSTRAINT im_underpass_individual_unit_pkey PRIMARY KEY (nid);


--
-- Name: im_underpass_individual_unit_unique_im_underpass_hrsz_unit; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_individual_unit
    ADD CONSTRAINT im_underpass_individual_unit_unique_im_underpass_hrsz_unit UNIQUE (im_underpass, hrsz_unit);


--
-- Name: im_underpass_levels_pkey_im_underpass_block_im_levels; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_levels
    ADD CONSTRAINT im_underpass_levels_pkey_im_underpass_block_im_levels PRIMARY KEY (im_underpass, im_levels);


--
-- Name: im_underpass_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_pkey PRIMARY KEY (nid);


--
-- Name: im_underpass_shared_unit_level_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_shared_unit_level
    ADD CONSTRAINT im_underpass_shared_unit_level_pkey PRIMARY KEY (im_underpass, hrsz_unit);


--
-- Name: im_underpass_shared_unit_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_shared_unit
    ADD CONSTRAINT im_underpass_shared_unit_pkey PRIMARY KEY (nid);


--
-- Name: im_underpass_shared_unit_unique_im_underpass_hrsz_unit; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_shared_unit
    ADD CONSTRAINT im_underpass_shared_unit_unique_im_underpass_hrsz_unit UNIQUE (im_underpass, hrsz_unit);


--
-- Name: im_underpass_unigue_projection; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_unigue_projection UNIQUE (projection);


--
-- Name: im_underpass_unique_model; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_unique_model UNIQUE (model);


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
-- Name: im_individual_shared_fkey_im_underpass_individual_unit; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_individual_shared
    ADD CONSTRAINT im_individual_shared_fkey_im_underpass_individual_unit FOREIGN KEY (im_underpass_individual_unit) REFERENCES im_underpass_individual_unit(nid);


--
-- Name: im_individual_shared_fkey_im_underpass_shared_unit; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_individual_shared
    ADD CONSTRAINT im_individual_shared_fkey_im_underpass_shared_unit FOREIGN KEY (im_underpass_shared_unit) REFERENCES im_underpass_shared_unit(nid);


--
-- Name: im_individual_unit_level_fkey_im_building_hrsz_unit; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_individual_unit_level
    ADD CONSTRAINT im_individual_unit_level_fkey_im_building_hrsz_unit FOREIGN KEY (im_building, hrsz_unit) REFERENCES im_building_individual_unit(im_building, hrsz_unit);


--
-- Name: im_parcel_fkey_im_cultivation; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_fkey_im_cultivation FOREIGN KEY (im_cultivation) REFERENCES im_cultivation(nid);


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
-- Name: im_underpass_individual_unit_fkey_im_inderpass; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_individual_unit
    ADD CONSTRAINT im_underpass_individual_unit_fkey_im_inderpass FOREIGN KEY (im_underpass) REFERENCES im_underpass(nid);


--
-- Name: im_underpass_individual_unit_level_fkey_im_underpass_leveles; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_individual_unit_level
    ADD CONSTRAINT im_underpass_individual_unit_level_fkey_im_underpass_leveles FOREIGN KEY (im_underpass, im_levels) REFERENCES im_underpass_levels(im_underpass, im_levels);


--
-- Name: im_underpass_individual_unit_level_fkey_projection; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_individual_unit_level
    ADD CONSTRAINT im_underpass_individual_unit_level_fkey_projection FOREIGN KEY (projection) REFERENCES tp_face(gid);


--
-- Name: im_underpass_individual_unit_level_fkey_um_underpass_individual; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_individual_unit_level
    ADD CONSTRAINT im_underpass_individual_unit_level_fkey_um_underpass_individual FOREIGN KEY (im_underpass, hrsz_unit) REFERENCES im_underpass_individual_unit(im_underpass, hrsz_unit);


--
-- Name: im_underpass_levels_fkey_im_underpass; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_levels
    ADD CONSTRAINT im_underpass_levels_fkey_im_underpass FOREIGN KEY (im_underpass) REFERENCES im_underpass(nid);


--
-- Name: im_underpass_levels_fkey_projection; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_levels
    ADD CONSTRAINT im_underpass_levels_fkey_projection FOREIGN KEY (projection) REFERENCES tp_face(gid);


--
-- Name: im_underpass_shared_unit_fkey_im_underpass; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_shared_unit
    ADD CONSTRAINT im_underpass_shared_unit_fkey_im_underpass FOREIGN KEY (im_underpass) REFERENCES im_underpass(nid);


--
-- Name: im_underpass_shared_unit_level_fkey_im_underpass_hrsz_unit; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_shared_unit_level
    ADD CONSTRAINT im_underpass_shared_unit_level_fkey_im_underpass_hrsz_unit FOREIGN KEY (im_underpass, hrsz_unit) REFERENCES im_underpass_shared_unit(im_underpass, hrsz_unit);


--
-- Name: im_underpass_shared_unit_level_fkey_im_underpass_im_levels; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_shared_unit_level
    ADD CONSTRAINT im_underpass_shared_unit_level_fkey_im_underpass_im_levels FOREIGN KEY (im_underpass, im_levels) REFERENCES im_underpass_levels(im_underpass, im_levels);


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


