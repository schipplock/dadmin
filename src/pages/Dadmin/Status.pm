# -------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <andreas@schipplock.de> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Andreas Schipplock
# -------------------------------------------------------------------------------

package Dadmin::Status;

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

    my $sess_username = $self->capullo_object->session->get("username");
    my $sess_password = $self->capullo_object->session->get("password");

    if ($self->capullo_object->authentication->isAuthorized($sess_username, $sess_password)) {
        # - ONLY Admin users
        if ($self->capullo_object->authentication->isInGroup($sess_username, "admin")) {
            $self->view_admin_header();

            if ($action eq "_") {
              $self->action_new();
            }
            
            # - show the form
            if ($action eq "new") {
              $self->action_new();
            }
            
            # - save the submitted form values
            if ($action eq "new-save") {
              $self->action_new_save();
            }

            if ($action eq "manage") {
              $self->action_manage();
            }
            
            if ($action eq "status-edit") {
              $self->action_status_edit($self->capullo_object->request->get("status_id", "int"));
            }
            
            if ($action eq "status-edit-save") {
              my $id = $self->capullo_object->request->get("status_id", "int");
              my $code = $self->capullo_object->request->get("code", "int");
              my $name = $self->capullo_object->request->get("name", "clean");
              $self->action_status_edit_save($id,$code,$name);
            }
            
            if ($action eq "status-delete") {
              my $id = $self->capullo_object->request->get("status_id", "int");
              $self->action_status_delete($id);
            }
            
            $self->view_admin_footer();
        } else {
            warn("user $sess_username tried to access the admin area");
            print "error:user-rights-error";
        }
    } else {
        warn("unauthorized user $sess_username tried to access the dashboard");
        print "error:unauthorized-access";
    }
  }
  
  sub view_admin_header {
    my ($self) = @_;
    if ($self->capullo_object->template->open("templates/header.admin.tmpl.html")) {
      $self->capullo_object->template->render();
    }
  }
  
  sub view_admin_footer {
    my ($self) = @_;
    if ($self->capullo_object->template->open("templates/footer.tmpl.html")) {
      $self->capullo_object->template->render();
    }
  }
  
  sub action_new {
    my ($self) = @_;
    if ($self->capullo_object->template->open("templates/status/new.tmpl.html")) {
      $self->capullo_object->template->render();
    }
  }
  
  sub action_new_save {
    my ($self) = @_;
    my $code = $self->capullo_object->request->get("code", "int");
    my $description = $self->capullo_object->request->get("name", "clean");
    if ($self->capullo_object->database->execute("insert into status (id,code,description) values (nextval('status_seq'),$code,'$description');commit;")) {
      print "success";
    } else {
      print "error";
    }
  }
  
  sub action_manage {
    my ($self) = @_;
    if ($self->capullo_object->template->open("templates/status/manage.tmpl.html")) {
      my $page_number = $self->capullo_object->request->get("page", "int");
      $page_number = 1 if (!defined $page_number) or ($page_number eq "");
      my @status_results_AoH = $self->capullo_object->database->query("select id,code,description,domains_associated from status_results($page_number) order by id asc");
      my @page_count_AoH = $self->capullo_object->database->query("select * from status_get_pagecount() as pagecount");
      my $pagecount = $page_count_AoH[0]{pagecount};
      my @pages_AoH;
      for (my $run=1;$run<=$pagecount;$run++) {
        if ($run == $page_number) {
            push @pages_AoH, {pagenumber => $run}; 
        } else {
            push @pages_AoH, {pagenumber => "<a href=\"?page_id=status&action=manage&page=$run\">$run</a>"}; 
        }
      }
      $self->capullo_object->template->passVariables("status-list" => \@status_results_AoH); 
      $self->capullo_object->template->passVariables("pager" => \@pages_AoH); 
      $self->capullo_object->template->render();
    }
  }
  
  sub action_status_edit {
    my ($self, $id) = @_;
    if ($self->capullo_object->template->open("templates/status/edit.tmpl.html")) {
        $id = 0 if (!defined $id) or ($id eq "");
        my @status_set_AoH = $self->capullo_object->database->query("select id,code,description from status where id=$id");
        $self->capullo_object->template->passVariables(id=>$status_set_AoH[0]{id},
                                                       code=>$status_set_AoH[0]{code},
                                                       description=>$status_set_AoH[0]{description});
        $self->capullo_object->template->render();
    } 
  }
  
  sub action_status_edit_save {
    my ($self, $id,$code,$name) = @_;
    $id = 0 if (!defined $id) or ($id eq "");
    if ($self->capullo_object->database->execute("update status set code=$code,description='$name' where id=$id;commit;")) {
        print "success";
    } else {
        print "error";
    }
  }
  
  sub action_status_delete {
    my ($self,$id) = @_;
    $id = 0 if (!defined $id) or ($id eq "");
    # - check if this status is set as a status on some domainname
    # - if so, abort deletion as it would cause an exception in the database
    my @AoH = $self->capullo_object->database->query("select count(id) as count from domainnames where status_id=$id");
    if ($AoH[0]{count}==0) {
        if ($self->capullo_object->database->execute("delete from status where id=$id;commit;")) {
            print "success";
        } else {
            print "error";
        }
    } else {
        print "error:cant-delete-associated-status-code";
    }
  }
  
1;