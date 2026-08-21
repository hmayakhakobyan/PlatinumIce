<?php
/**
 * Child-theme override of Alukas's header logo template part.
 *
 * TEMPORARY: renders the site title as a plain text wordmark instead of the
 * parent theme's default "ALUKAS & CO" SVG, since final Platinum Ice logo
 * files don't exist yet. This does not touch the parent theme file — WordPress's
 * template-part lookup (locate_template(), used by pls_get_template()) checks
 * the child theme first, so this file simply shadows the parent's version.
 *
 * Safety net: if a real logo is ever uploaded via Theme Options > Header > Logo,
 * this file automatically defers back to the parent's normal image-based
 * rendering below, so there is nothing to remember to delete when the real
 * Platinum Ice SVG logo is ready — only remove this file if you want the
 * override gone entirely regardless of Theme Options state.
 *
 * @package pls-theme-child
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

$logo_url = pls_get_option( 'header-logo', array( 'url' => '' ) );

if ( ! empty( $logo_url['url'] ) ) {
	require PLS_DIR . '/template-parts/header/elements/logo.php';
	return;
}

$site_title = get_bloginfo( 'name', 'display' );
?>
<div class="pls-header-logo">
	<a href="<?php echo esc_url( home_url( '/' ) ); ?>" rel="home">
		<span class="pls-logo platinum-text-logo"><?php echo esc_html( $site_title ); ?></span>
		<span class="pls-logo-light platinum-text-logo"><?php echo esc_html( $site_title ); ?></span>
		<span class="pls-mobile-logo platinum-text-logo"><?php echo esc_html( $site_title ); ?></span>
	</a>
</div>
