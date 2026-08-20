<?php
/* 	
 * Functions file for Alukas child
 */
 
/*
 * Enqueue script and styles
 */
function alukas_child_enqueue_styles() {
	$theme   = wp_get_theme( 'alukas' );
	$version = $theme->get( 'Version' );
	wp_enqueue_style( 'pls-child-style', get_stylesheet_directory_uri() . '/style.css', $version );
}
add_action( 'wp_enqueue_scripts', 'alukas_child_enqueue_styles', 101 );