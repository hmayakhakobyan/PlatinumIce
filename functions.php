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

/*
 * WooCommerce: products without a set price aren't purchasable (WooCommerce
 * core behavior). Rather than leave the add-to-cart area blank, point
 * visitors to the quote flow instead of inventing a price.
 */
function pls_child_quote_cta_for_unpriced_products() {
	global $product;
	if ( ! $product || $product->is_purchasable() ) {
		return;
	}
	$quote_url = home_url( '/request-a-quote/' );
	printf(
		'<a class="button alt pls-quote-cta" href="%s">%s</a>',
		esc_url( $quote_url ),
		esc_html__( 'Request a Quote', 'pls-theme-child' )
	);
}
add_action( 'woocommerce_single_product_summary', 'pls_child_quote_cta_for_unpriced_products', 30 );

/*
 * Meta description: no SEO plugin is installed (Yoast/RankMath), and
 * CLAUDE.md's development rules say not to install plugins without
 * approval — so a minimal native fallback lives here instead.
 */
function pls_child_meta_description() {
	if ( ! is_singular() ) {
		return;
	}
	$description = get_post_meta( get_the_ID(), 'pls_meta_description', true );
	if ( ! $description && is_singular( 'product' ) ) {
		global $product;
		if ( $product ) {
			$description = wp_strip_all_tags( $product->get_short_description() ?: $product->get_description() );
		}
	} elseif ( ! $description ) {
		$excerpt = get_the_excerpt();
		$description = $excerpt ? wp_strip_all_tags( $excerpt ) : '';
	}
	if ( ! $description ) {
		return;
	}
	$description = trim( preg_replace( '/\s+/', ' ', $description ) );
	if ( strlen( $description ) > 160 ) {
		$description = substr( $description, 0, 157 ) . '...';
	}
	printf( '<meta name="description" content="%s" />' . "\n", esc_attr( $description ) );
}
add_action( 'wp_head', 'pls_child_meta_description', 1 );

/*
 * Organization/WebSite JSON-LD: safe, factual identity markup only (name +
 * URL). No claims about founding date, address, or reviews are added since
 * that information hasn't been supplied yet.
 */
function pls_child_organization_schema() {
	if ( ! is_front_page() && ! is_home() ) {
		return;
	}
	$schema = array(
		'@context' => 'https://schema.org',
		'@graph'   => array(
			array(
				'@type' => 'Organization',
				'name'  => get_bloginfo( 'name' ),
				'url'   => home_url( '/' ),
			),
			array(
				'@type'           => 'WebSite',
				'name'            => get_bloginfo( 'name' ),
				'url'             => home_url( '/' ),
				'potentialAction' => array(
					'@type'       => 'SearchAction',
					'target'      => home_url( '/?s={search_term_string}' ),
					'query-input' => 'required name=search_term_string',
				),
			),
		),
	);
	echo '<script type="application/ld+json">' . wp_json_encode( $schema ) . '</script>' . "\n";
}
add_action( 'wp_head', 'pls_child_organization_schema' );

/*
 * Product JSON-LD for WooCommerce single product pages. Omits `offers`
 * entirely when no price is set yet, rather than fabricating a price -
 * Google simply won't show a price rich-result until real pricing exists.
 */
function pls_child_product_schema() {
	if ( ! function_exists( 'is_product' ) || ! is_product() ) {
		return;
	}
	global $product;
	if ( ! $product ) {
		return;
	}
	$image_id = $product->get_image_id();
	$schema   = array(
		'@context'    => 'https://schema.org',
		'@type'       => 'Product',
		'name'        => $product->get_name(),
		'description' => wp_strip_all_tags( $product->get_short_description() ?: $product->get_description() ),
		'sku'         => $product->get_sku(),
		'url'         => get_permalink( $product->get_id() ),
	);
	if ( $image_id ) {
		$schema['image'] = wp_get_attachment_image_url( $image_id, 'large' );
	}
	if ( $product->is_purchasable() && $product->get_price() !== '' ) {
		$schema['offers'] = array(
			'@type'         => 'Offer',
			'price'         => $product->get_price(),
			'priceCurrency' => get_woocommerce_currency(),
			'availability'  => $product->is_in_stock() ? 'https://schema.org/InStock' : 'https://schema.org/OutOfStock',
		);
	}
	echo '<script type="application/ld+json">' . wp_json_encode( $schema ) . '</script>' . "\n";
}
add_action( 'wp_head', 'pls_child_product_schema' );

/*
 * Request a Quote: Elementor Free has no form widget (that's Elementor Pro),
 * and CLAUDE.md's rules say not to install a forms plugin without approval.
 * This registers a minimal native handler instead: a plain <form> (built with
 * Elementor's HTML widget on the Request a Quote page) posts to
 * admin-post.php, gets sanitized, emailed to the site admin via wp_mail(),
 * and stored as a private 'pls_quote_request' post so submissions aren't
 * lost if an email doesn't arrive.
 */
function pls_child_register_quote_request_cpt() {
	register_post_type( 'pls_quote_request', array(
		'label'           => __( 'Quote Requests', 'pls-theme-child' ),
		'public'          => false,
		'show_ui'         => true,
		'show_in_menu'    => true,
		'menu_icon'       => 'dashicons-email-alt',
		'supports'        => array( 'title', 'editor' ),
		'capability_type' => 'post',
	) );
}
add_action( 'init', 'pls_child_register_quote_request_cpt' );

function pls_child_handle_quote_request() {
	if ( ! isset( $_POST['pls_quote_nonce'] ) || ! wp_verify_nonce( $_POST['pls_quote_nonce'], 'pls_quote_request' ) ) {
		wp_die( esc_html__( 'Security check failed. Please go back and try again.', 'pls-theme-child' ) );
	}

	$fields = array(
		'name'             => sanitize_text_field( $_POST['name'] ?? '' ),
		'company'          => sanitize_text_field( $_POST['company'] ?? '' ),
		'email'            => sanitize_email( $_POST['email'] ?? '' ),
		'phone'            => sanitize_text_field( $_POST['phone'] ?? '' ),
		'customer_type'    => sanitize_text_field( $_POST['customer_type'] ?? '' ),
		'product_interest' => sanitize_text_field( $_POST['product_interest'] ?? '' ),
		'custom_logo'      => sanitize_text_field( $_POST['custom_logo'] ?? '' ),
		'quantity'         => sanitize_text_field( $_POST['quantity'] ?? '' ),
		'event_date'       => sanitize_text_field( $_POST['event_date'] ?? '' ),
		'message'          => sanitize_textarea_field( $_POST['message'] ?? '' ),
	);

	if ( empty( $fields['name'] ) || ! is_email( $fields['email'] ) ) {
		wp_safe_redirect( add_query_arg( 'quote', 'error', wp_get_referer() ?: home_url( '/request-a-quote/' ) ) );
		exit;
	}

	$body_lines = array();
	foreach ( $fields as $key => $value ) {
		if ( $value !== '' ) {
			$body_lines[] = ucwords( str_replace( '_', ' ', $key ) ) . ': ' . $value;
		}
	}
	$body = implode( "\n", $body_lines );

	wp_insert_post( array(
		'post_type'    => 'pls_quote_request',
		'post_title'   => sprintf( '%s - %s', $fields['name'], date_i18n( 'Y-m-d H:i' ) ),
		'post_content' => $body,
		'post_status'  => 'private',
	) );

	wp_mail(
		get_option( 'admin_email' ),
		sprintf( '[Platinum Ice] New quote request from %s', $fields['name'] ),
		$body,
		array( 'Reply-To: ' . $fields['email'] )
	);

	wp_safe_redirect( add_query_arg( 'quote', 'success', wp_get_referer() ?: home_url( '/request-a-quote/' ) ) );
	exit;
}
add_action( 'admin_post_nopriv_pls_quote_request', 'pls_child_handle_quote_request' );
add_action( 'admin_post_pls_quote_request', 'pls_child_handle_quote_request' );

/*
 * The quote request form markup lives in a shortcode rather than an
 * Elementor HTML widget - Elementor's HTML widget runs its content through
 * wp_kses_post(), which strips <form>/<input>/<select>/<style> entirely.
 * A shortcode's output isn't re-sanitized, so it's the correct native way
 * to get real form markup onto an Elementor Free page without a plugin.
 */
function pls_child_quote_form_shortcode() {
	$nonce      = wp_create_nonce( 'pls_quote_request' );
	$action_url = esc_url( admin_url( 'admin-post.php' ) );
	$notice     = '';

	if ( isset( $_GET['quote'] ) && $_GET['quote'] === 'success' ) {
		$notice = '<div class="pls-quote-notice success">' . esc_html__( 'Thank you - your request has been received. We will follow up shortly.', 'pls-theme-child' ) . '</div>';
	} elseif ( isset( $_GET['quote'] ) && $_GET['quote'] === 'error' ) {
		$notice = '<div class="pls-quote-notice error">' . esc_html__( 'Please provide your name and a valid email address, then try again.', 'pls-theme-child' ) . '</div>';
	}

	ob_start();
	?>
	<style>
	.pls-quote-form{max-width:640px;margin:0 auto;}
	.pls-quote-form label{display:block;font-size:13px;letter-spacing:1px;text-transform:uppercase;color:#8E9499;margin:20px 0 6px;}
	.pls-quote-form input,.pls-quote-form select,.pls-quote-form textarea{width:100%;box-sizing:border-box;padding:12px 14px;border:1px solid #8E9499;background:#0A0A0A;color:#F4F7F8;font-size:15px;}
	.pls-quote-form textarea{min-height:120px;}
	.pls-quote-form button{margin-top:32px;padding:16px 32px;background:#F4F7F8;color:#0A0A0A;border:1px solid #F4F7F8;text-transform:uppercase;letter-spacing:1px;font-size:14px;cursor:pointer;}
	.pls-quote-notice{max-width:640px;margin:0 auto 24px;padding:16px 20px;font-size:15px;}
	.pls-quote-notice.success{background:#1a3a1a;color:#c8e6c9;}
	.pls-quote-notice.error{background:#3a1a1a;color:#f8bbd0;}
	</style>
	<?php echo $notice; ?>
	<form class="pls-quote-form" method="post" action="<?php echo $action_url; ?>">
		<input type="hidden" name="action" value="pls_quote_request">
		<input type="hidden" name="pls_quote_nonce" value="<?php echo esc_attr( $nonce ); ?>">

		<label for="pls-name"><?php esc_html_e( 'Name *', 'pls-theme-child' ); ?></label>
		<input type="text" id="pls-name" name="name" required>

		<label for="pls-company"><?php esc_html_e( 'Company', 'pls-theme-child' ); ?></label>
		<input type="text" id="pls-company" name="company">

		<label for="pls-email"><?php esc_html_e( 'Email *', 'pls-theme-child' ); ?></label>
		<input type="email" id="pls-email" name="email" required>

		<label for="pls-phone"><?php esc_html_e( 'Phone', 'pls-theme-child' ); ?></label>
		<input type="tel" id="pls-phone" name="phone">

		<label for="pls-customer-type"><?php esc_html_e( 'Customer Type', 'pls-theme-child' ); ?></label>
		<select id="pls-customer-type" name="customer_type">
			<option value="Hospitality"><?php esc_html_e( 'Hospitality (bar, restaurant, hotel)', 'pls-theme-child' ); ?></option>
			<option value="Event"><?php esc_html_e( 'Event (wedding, private, corporate)', 'pls-theme-child' ); ?></option>
			<option value="Personal"><?php esc_html_e( 'Personal', 'pls-theme-child' ); ?></option>
		</select>

		<label for="pls-product"><?php esc_html_e( 'Product Interest', 'pls-theme-child' ); ?></label>
		<select id="pls-product" name="product_interest">
			<option value="Signature Cube">Signature Cube</option>
			<option value="Clear Sphere">Clear Sphere</option>
			<option value="Collins Spear">Collins Spear</option>
			<option value="Custom Ice"><?php esc_html_e( 'Custom / Logo Ice', 'pls-theme-child' ); ?></option>
			<option value="Not sure yet"><?php esc_html_e( 'Not sure yet', 'pls-theme-child' ); ?></option>
		</select>

		<label for="pls-logo"><?php esc_html_e( 'Custom Logo / Monogram Needed?', 'pls-theme-child' ); ?></label>
		<select id="pls-logo" name="custom_logo">
			<option value="No"><?php esc_html_e( 'No', 'pls-theme-child' ); ?></option>
			<option value="Yes"><?php esc_html_e( 'Yes', 'pls-theme-child' ); ?></option>
		</select>

		<label for="pls-quantity"><?php esc_html_e( 'Estimated Quantity', 'pls-theme-child' ); ?></label>
		<input type="text" id="pls-quantity" name="quantity" placeholder="e.g. 200 cubes / week">

		<label for="pls-date"><?php esc_html_e( 'Event or Delivery Date', 'pls-theme-child' ); ?></label>
		<input type="date" id="pls-date" name="event_date">

		<label for="pls-message"><?php esc_html_e( 'Message', 'pls-theme-child' ); ?></label>
		<textarea id="pls-message" name="message" placeholder="<?php esc_attr_e( 'Tell us about what you need', 'pls-theme-child' ); ?>"></textarea>

		<button type="submit"><?php esc_html_e( 'Send Request', 'pls-theme-child' ); ?></button>
	</form>
	<?php
	return ob_get_clean();
}
add_shortcode( 'pls_quote_form', 'pls_child_quote_form_shortcode' );