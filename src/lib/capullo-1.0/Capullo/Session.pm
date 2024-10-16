# -------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <andreas@schipplock.de> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Andreas Schipplock
# -------------------------------------------------------------------------------

package Capullo::Session;

use Moose;

  use CGI::Session;
  
  has "session_object" => (
    isa => "CGI::Session",
    is => "rw"
  );
  
  has "session_id" => (
    isa => "Str",
    is => "rw"
  );
  
  has "session_save_path" => (
    isa => "Str",
    is => "rw",
    default => "/tmp/capullo_sessions"
  );
  
  has "session_name" => (
    isa => "Str",
    is => "rw",
    default => "capullo_session"
  );
    
  sub init {
    my ($self) = @_;
    CGI::Session->name($self->session_name());
    $self->session_object(new CGI::Session(undef, undef, {Directory=>$self->session_save_path()}));
    $self->session_id($self->session_object->id());
    my $sessionHeader = $self->session_object->header();
    print $sessionHeader;
  }
    
  sub setSessionValue {
    my ($self, $paramName, $value) = @_;
    $self->session_object->param($paramName, $value);
    $self->session_object->flush();
  }
    
  sub getSessionValue {
    my ($self, $paramName) = @_;
    return $self->session_object->param($paramName);
  }
	
	sub setExpire {
		my ($self, $expire) = @_;
		$self->session_object->expire("+".$expire);
	}
	
	sub expire {
		my ($self, $expire) = @_;
		$self->setExpire($expire);
	}
	
	sub expire_in {
	  my ($self, $expire) = @_;
	  $self->setExpire($expire);
	}
    
  sub get {
    my ($self,$paramName) = @_;
    return $self->getSessionValue($paramName);
  }
    
  sub set {
    my ($self,$paramName,$value) = @_;
    $self->setSessionValue($paramName,$value);
  }
  
1;
