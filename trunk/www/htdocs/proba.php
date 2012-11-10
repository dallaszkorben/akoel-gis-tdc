<?php

@trigger_error("");

	//
	//  Változók
	//
	$parcel_normal_color = "<Material transparency='0.1' diffuseColor='0.0 0.4 0.0' emissiveColor='0.0 0.4 0.0'/>";
	$parcel_normal_color = "<Material transparency='0.1' diffuseColor='0.0 0.6 0.0' emissiveColor='0.0 0.6 0.1'/>";

	$building_normal_color =  "<Material transparency='0.0' diffuseColor='0.0 0.2 0.2' emissiveColor='0.0 0.2 0.2'/>";
	$building_selected_color = "<Material transparency='0.0' diffuseColor='0.1 0.4 0.4' emissiveColor='0.1 0.4 0.4'/>";

	$building_individual_unit_normal_color = " <Material transparency='0' diffuseColor='0.2 0 0' emissiveColor='0.2 0 0'/>";
	$building_individual_unit_selected_color = " <Material transparency='0' diffuseColor='0.4 0 0' emissiveColor='0.4 0 0'/>";

	$building_shared_unit_normal_color = "<Material transparency='0' diffuseColor='0.2 0.4 0.3' emissiveColor='0.2 0.4 0.3'/>";
	$building_shared_unit_selected_color = "<Material transparency='0' diffuseColor='0.4 0.8 0.6' emissiveColor='0.4 0.8 0.6'/>";

	$point_normal_color = "<Material diffuseColor='1.0 1.0 0.0' emissiveColor='1.0 1.0 0.0'/>";
	$point_selected_color = "<Material diffuseColor='2.0 2.0 0.0' emissiveColor='2.0 2.0 0.0'/>";

	//
	// Paraméterek átvétele
	//
	$selected_name = $_REQUEST['selected_name'];
	$selected_nid = $_REQUEST['selected_nid'];
	$immovable_type = $_REQUEST['immovable_type'];
	$x = $_REQUEST['x'];
	$y = $_REQUEST['y'];
	$lon = $_REQUEST['lon'];
	$lat = $_REQUEST['lat'];

	//Uj map objektum letrehozasa	a map file alapján
	$map_path="";
	$map_file="tdc.map";	
	$map = ms_newMapObj($map_path.$map_file);		


	//Paraméterek átadása a MAP fájlnak
	$selected_layer=$map->getLayerByName( "query_x3d_building" );

	//DATA változó kiolvasása a MAP fájlból és a paraméterek behelyettesítése
	$data = str_replace( "%selected_nid%", $selected_nid, $selected_layer->data );
	$data = str_replace( "%immovable_type%", $immovable_type, $data );
	$selected_layer->data = $data;

	//aktuális pozició elõállítása
	$search_point = ms_newpointObj();
	$search_point->setXY(	$lon, $lat );

	//Lekérdezés az adott pontban
	$result = $selected_layer->queryByPoint( $search_point, MS_MULTIPLE, -1 );

	$x3d_string = "";

	//Ha volt találat
	if( $result == MS_SUCCESS ){

		//Template végrehajtása és az eredmény szétdarabolása
		$result_xml_string = "<block>" . $map->processquerytemplate( array(), MS_FALSE ) . "</block>";
	
		//XMLSimple objektumot készít a megkapott XML stringből
		$result_xml_object = simplexml_load_string( $result_xml_string );

		//Végig megyek az egyes objektumokot és legyártom hozzá a megfelelő X3D <Translation> tag-eket
		foreach ( $result_xml_object as $object_tag ):
			
			//Egy objektum adatainak begyüjtése
			$query_object_name = $object_tag -> query_object_name;
			$query_object_nid = $object_tag -> query_object_nid;
			$query_object_selected = $object_tag -> query_object_selected;
			$query_object_x3d = $object_tag -> query_object_x3d;

			// -------------------------------------------------------
			// -- Building parcellájához tartozó épületek pontjai --
			//-------------------------------------------------------
			if( $query_object_name == "sv_survey_point" ){

				$x3d_string .= "\n" .
					"		<Transform translation='" . $query_object_x3d . "'>\n" .
					"			<Shape>\n" .
					"				<Appearance>\n" .
					"					" . $point_normal_color . "\n" .
					"				</Appearance>\n" .
					"				<Sphere radius='0.1'></Sphere>\n" .
					"			</Shape>\n" .
					"		</Transform>";

			//-------------------------------------
			//-- Épülethez tartozó Parcella(k) --
			//------------------------------------
			}else if( $query_object_name == "im_parcel" ){

				$x3d_string .= "\n" .
					"		<Transform>\n" .
					"			<Shape>\n" . 
					"				<Appearance>\n" .
					"					" . $parcel_normal_color . "\n" .
					"				</Appearance>\n" .
					"				" .  $query_object_x3d . "\n" .
					"			</Shape>\n" .
					"		</Transform>";

			//-----------------------------------------------
			//-- Building parcellájához tartozó épületek --
			//----------------------------------------------  
			}else if( $query_object_name == 'im_building' ){

				$x3d_string .= "\n" .
					"		<Transform>\n" .
					"			<Shape>\n" .
					"				<Appearance>\n".
					"					". ( ( $query_object_selected == 't' ) ? $building_selected_color : $building_normal_color ) .  "\n" .
					"				</Appearance>\n" .
					"				" .  $query_object_x3d . "\n" .
					"			</Shape>\n" .
					"		</Transform>" ;
			}// if

		endforeach;

		//-----------------------------------------------
		//-- x3d kiegészítése, hogy valid legyen  ------
		//----------------------------------------------  
		$x3d_string = "" .
			"<?xml version='1.0' encoding='UTF-8'?>\n" .
			"<!DOCTYPE X3D PUBLIC 'ISO//Web3D//DTD X3D 3.0//EN' 'http://www.web3d.org/specifications/x3d-3.0.dtd'>\n" .
			"<X3D profile='Interchange'>\n" .
			"	<head>\n" .
			"		<component name='Lighting' level='3'></component>\n" .
			"	</head>\n" .
			"	<Scene>" . $x3d_string;

		$x3d_string .= "\n" .
			"		<Viewpoint orientation='0 1 0 0' position='" . $lon . " " . $lat . " " . "160' >\n" .
			"		</Viewpoint>\n" .
			"	</Scene>\n" .
			"</X3D>";

	}else{

		$x3d_string = "Hiba történt.\nNem volt találat.\n" . $result;

	}

	$myFile = "tmp/tdc.x3d";
	$fh = fopen( $myFile, 'w' ) or die( "can't open file" );

	//fwrite(  $fh,    implode(",", error_get_last() ) ."--------------------" . $x3d_string );

	//Belehelyezem a létrehozott fájlba az X3D modelt
	fwrite(  $fh, $x3d_string );
	fclose( $fh );

	echo $myFile;

?>
