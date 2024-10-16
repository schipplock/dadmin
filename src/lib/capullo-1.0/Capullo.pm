# -------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <andreas@schipplock.de> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Andreas Schipplock
# -------------------------------------------------------------------------------

package Capullo;

use Moose;

  use Capullo::Request;
  use Capullo::Template;
  use Capullo::Session;
  use Capullo::Gettext;
  use Capullo::Database;
  use Capullo::Authentication;
  use Capullo::Form;

  has "script_path" => (
    isa => "Str",
    is => "rw",
    required => 1
  );
  
  has "document_type" => (
    isa => "Str",
    is => "rw",
    required => 1
  );
  
  has "apache_object" => (
    is => "rw",
    required => 1
  );
  
  has "request" => (
    isa => "Capullo::Request",
    is => "rw"
  );
  
  has "template" => (
    isa => "Capullo::Template",
    is => "rw"
  );
  
  has "session" => (
    isa => "Capullo::Session",
    is => "rw"
  );
  
  has "gettext" => (
    isa => "Capullo::Gettext",
    is => "rw"
  );
  
  has "authentication" => (
    isa => "Capullo::Authentication",
    is => "rw"
  );
  
  has "database" => (
    isa => "Capullo::Database",
    is => "rw"
  );
  
  has "form" => (
    isa => "Capullo::Form",
    is => "rw"
  );
  
  sub init {
    my ($self) = @_;
		# set doctype
		$self->apache_object->content_type($self->document_type());
		# create and init the request module
		$self->request(Capullo::Request->new());
		$self->request->init();
		# create the template module
		$self->template(Capullo::Template->new());
		$self->template->root_directory($self->script_path());
		# create the session module
		$self->session(Capullo::Session->new());
		# create the gettext module
		$self->gettext(Capullo::Gettext->new());
		$self->gettext->root_directory($self->script_path());
		# create the authentication module
		$self->authentication(Capullo::Authentication->new());
		# create the database module
		$self->database(Capullo::Database->new());
		# create the form module
		$self->form(Capullo::Form->new());
		$self->form->root_directory($self->script_path());
  }
	
  sub redirect {
    my ($self,$url) = @_;
    if (length($url)>0) {
      $self->apache_object->headers_out->set(Location => $url);
      $self->apache_object->status(Apache2::Const::REDIRECT);
    }
  }
	
  sub fileContent {
    my ($self,$name) = @_;
    my $filename = $self->script_path()."/".$name;
    open SOMEFILE, $filename;
    my @lines = <SOMEFILE>;
    close SOMEFILE;
    return @lines;
  }
     
1;
