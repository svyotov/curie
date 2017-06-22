use Renard::Curie::Setup;
package Renard::Curie::Component::MainWindow;
# ABSTRACT: Main window of the application

use Gtk3 -init;
use Cairo;
use Glib::Object::Introspection;
use Glib 'TRUE', 'FALSE';

use Moo 2.001001;

use Renard::Curie::Helper;
use Renard::Curie::Model::Document::PDF;
use Renard::Curie::Component::PageDrawingArea;

use MooX::Role::Logger ();

use Renard::Curie::Types qw(InstanceOf Path Str DocumentModel);

=attr window

A L<Gtk3::Window> that contains the main window for the application.

=cut
has window => ( is => 'lazy' );

method _build_window() :ReturnType(InstanceOf['Gtk3::Window']) {
	my $window = $self->builder->get_object('main-window');
}

=attr page_document_component

A L<Renard::Curie::Component::PageDrawingArea> that holds the currently
displayed document.

=for :list
* Predicate: C<has_page_document_component>
* Clearer: C<clear_page_document_component>

=for Pod::Coverage has_page_document_component clear_page_document_component

=cut
has page_document_component => (
	is => 'rw',
	isa => InstanceOf['Renard::Curie::Component::PageDrawingArea'],
	predicate => 1, # has_page_document_component
	clearer => 1 # clear_page_document_component
);

=attr content_box

A horizontal L<Gtk3::Box> which is used to split the main application area into
two different regions.

The left region contains L</outline> and the right region contains L</page_document_component>.

=cut
has content_box => (
	is => 'rw',
	isa => InstanceOf['Gtk3::Box'],
);

=method setup_window

  method setup_window()

Sets up components that make up the window shell for the application
including:

=for :list
* L</menu_bar>
* L</content_box>
* L</log_window>

=cut
method setup_window() {
	$self->content_box( Gtk3::Box->new( 'horizontal', 0 ) );
	$self->builder->get_object('application-vbox')
		->pack_start( $self->content_box, TRUE, TRUE, 0 );
}

=method run

  method run()

Displays L</window> and starts the L<Gtk3> event loop.

=cut
method run() {
	$self->window->show_all;
	$self->_logger->info("starting the Gtk main event loop");
	Gtk3::main;
}

=method BUILD

  method BUILD

Initialises the application and sets up signals.

=cut
method BUILD(@) {
	$self->setup_window;

	$self->window->signal_connect(
		destroy => \&on_application_quit_cb, $self );
	$self->window->set_default_size( 800, 600 );
}

=method open_pdf_document

  method open_pdf_document( (Path->coercibles) $pdf_filename )

Opens a PDF file stored on the disk.

=cut
method open_pdf_document( (Path->coercibles) $pdf_filename ) {
	$pdf_filename = Path->coerce( $pdf_filename );
	if( not -f $pdf_filename ) {
		Renard::Curie::Error::IO::FileNotFound
			->throw("PDF filename does not exist: $pdf_filename");
	}

	my $doc = Renard::Curie::Model::Document::PDF->new(
		filename => $pdf_filename,
	);

	# set window title
	$self->window->set_title( $pdf_filename );

	$self->open_document( $doc );
}

=method open_document

  method open_document( (DocumentModel) $doc )

Sets the document for the application's L</page_document_component>.

=cut
method open_document( (DocumentModel) $doc ) {
	if( $self->has_page_document_component ) {
		$self->content_box->remove( $self->page_document_component );
		$self->clear_page_document_component;
	}
	my $pd = Renard::Curie::Component::PageDrawingArea->new(
		document => $doc,
	);
	$self->page_document_component($pd);
	$self->content_box->pack_start( $pd, TRUE, TRUE, 0 );
	$pd->show_all;
}

# Callbacks {{{
=callback on_application_quit_cb

  callback on_application_quit_cb( $event, $self )

Callback that stops the L<Gtk3> main loop.

=cut
callback on_application_quit_cb( $event, $self ) {
	Gtk3::main_quit;
}
# }}}

with qw(
	Renard::Curie::Component::Role::FromBuilder
	Renard::Curie::Component::Role::UIFileFromPackageName
	MooX::Role::Logger

	Renard::Curie::Component::MainWindow::Role::DragAndDrop
	Renard::Curie::Component::MainWindow::Role::LogWindow
	Renard::Curie::Component::MainWindow::Role::AccelMap
	Renard::Curie::Component::MainWindow::Role::MenuBar
	Renard::Curie::Component::MainWindow::Role::Outline
);
1;
