# -------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <andreas@schipplock.de> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Andreas Schipplock
# -------------------------------------------------------------------------------

package Dadmin::Login;

use Moose;

  has "capullo_object" => (
    isa => "Capullo",
    is => "rw",
    required => 1
  );
  
  sub run {
    my ($self) = @_;
    
    my $action = $self->capullo_object->request->get("action");
    if (!defined $action) {
      $action = "_";
    }
    
    if ($action eq "_") {
      if ($self->capullo_object->template->open("templates/login.tmpl.html")) {
        $self->capullo_object->template->render();
      }
    }
    
    if ($action eq "do-login") {
      my $post_username = $self->capullo_object->request->get("username", "clean");
      my $post_password = $self->capullo_object->request->get("password", "clean");
      
      # - check if the username exists
      my @countCheckAoH = $self->capullo_object->database->query("select count(username) as COUNT from users where username='$post_username'");
      if ($countCheckAoH[0]{count}==1) {
        my @dbAoH = $self->capullo_object->database->query("select password as dbpassword, md5('$post_password') as postpassword from users where username='$post_username'");
        # - check if the submitted password matches the password in the database
        if ($dbAoH[0]{dbpassword} eq $dbAoH[0]{postpassword}) {
          # - password matches, so save the md5 string in a server session file
          $self->capullo_object->session->set("username", $post_username);
          $self->capullo_object->session->set("password", $dbAoH[0]{postpassword});
          $self->capullo_object->session->expire_in("20m");
          # - and finally redirect to the dashboard module
          $self->capullo_object->redirect("?page_id=dashboard");
        } else {
          warn("user $post_username tried to login with a wrong password");
          print "error:user-password-error";
        }
      } else {
        warn("user $post_username tried to login but does not exist in database");
        print "error:no-user-there";
      }
    }
  }
  
1;