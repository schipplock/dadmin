# -------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <andreas@schipplock.de> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Andreas Schipplock
# -------------------------------------------------------------------------------

package Dadmin::Domainname;

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
        # - 
        # - ADMINS section
        # -
        
        # - ONLY Admin users can add,edit and delete
        if ($self->capullo_object->authentication->isInGroup($sess_username, "admin")) {
            $self->view_admin_header();

            if ($action eq "_") {
                $self->action_new();
            }

            if ($action eq "new") {
              $self->action_new();
            }
            
            if ($action eq "new-save") {
              my $domainname = $self->capullo_object->request->get("domainname","clean");
              my $topleveldomain_id = $self->capullo_object->request->get("topleveldomain_id","int");
              my $daynumber = $self->capullo_object->request->get("daynumber","int");
              my $monthnumber = $self->capullo_object->request->get("monthnumber","int");
              my $yearnumber = $self->capullo_object->request->get("yearnumber","int");
              if (($daynumber < 10) and (length($daynumber)<2)) { $daynumber = "0".$daynumber; }
              if (($monthnumber < 10) and (length($monthnumber)<2)) { $monthnumber = "0".$monthnumber; }
              # - pgsql prefers an ISO8601 date format, so here it gets it
              my $registration_date = "$yearnumber-$monthnumber-$daynumber";
              my $validity = $self->capullo_object->request->get("validity","int");
              my $autorenew = $self->capullo_object->request->get("autorenew","int");
              my $status_id = $self->capullo_object->request->get("status_id","int");
              my $user_id = $self->capullo_object->request->get("user_id","int");
              
              $self->action_new_save($domainname,$topleveldomain_id,$registration_date,$validity,$autorenew,$status_id,$user_id);
            }
            
            if ($action eq "manage") {
              $self->action_manage();
            }
            
            if ($action eq "edit") {
              my $domainname_id = $self->capullo_object->request->get("domain_id","int");
              $self->action_edit($domainname_id);
            }
            
            if ($action eq "edit-save") {
              my $domainname_id = $self->capullo_object->request->get("domainname_id","int");
              my $validity = $self->capullo_object->request->get("validity","int");
              my $autorenew = $self->capullo_object->request->get("autorenew","int");
              my $status_id = $self->capullo_object->request->get("status_id","int");
              my $user_id = $self->capullo_object->request->get("user_id","int");
              $self->action_edit_save($domainname_id,$validity,$autorenew,$status_id,$user_id);
            }
            
            if ($action eq "delete") {
              my $domainname_id = $self->capullo_object->request->get("domain_id","int");
              $self->action_delete($domainname_id);
            }

            $self->view_admin_footer();
        } 
        
        # - 
        # - USERs section
        # -
        if ($self->capullo_object->authentication->isInGroup($sess_username, "user")) {    
            # - USER area
            $self->view_user_header();
            
            my @user_info_AoH = $self->capullo_object->database->query("select id from users where username='$sess_username'");
            my $user_id = $user_info_AoH[0]{id};
            
            if ($action eq "manage") {
              $self->action_user_manage($user_id);
            }
            
            $self->view_user_footer();
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
  
  sub view_user_header {
    my ($self) = @_;
    if ($self->capullo_object->template->open("templates/header.user.tmpl.html")) {
      $self->capullo_object->template->render();
    }
  }
  
  sub view_user_footer {
    my ($self) = @_;
    if ($self->capullo_object->template->open("templates/footer.tmpl.html")) {
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
    if ($self->capullo_object->template->open("templates/domainname/new.tmpl.html")) {
      # - we need a list of all topleveldomainnames for the drop down
      my @tlds_AoH = $self->capullo_object->database->query("select id,domain from topleveldomains");
      
      # - we need a list of all usernames for the drop down
      my @users_AoH = $self->capullo_object->database->query("select id,username from users");
      
      # - we need a list of all status codes
      my @status_AoH = $self->capullo_object->database->query("select id,code,description from status");
      
      # - pass the data to the view and render it
      $self->capullo_object->template->passVariables(tlds=>\@tlds_AoH);
      $self->capullo_object->template->passVariables(users=>\@users_AoH);
      $self->capullo_object->template->passVariables(status=>\@status_AoH);
      $self->capullo_object->template->render();
    }
  }
  
  sub action_new_save {
    my ($self,$domainname,$topleveldomain_id,$registration_date,$validity,$autorenew,$status_id,$user_id) = @_;
    $topleveldomain_id = 0 if (!defined $topleveldomain_id) or ($topleveldomain_id eq "");
    $status_id = 0 if (!defined $status_id) or ($status_id eq "");
    $user_id = 0 if (!defined $user_id) or ($user_id eq "");
    
    $autorenew = "false" if ($autorenew==0);
    $autorenew = "true" if ($autorenew==1);
    
    # - check if this domainname has already been saved with this topleveldomain_id
    # - confess in case it's true
    my @tld_a_check_AoH = $self->capullo_object->database->query("select count(id) as count from domainnames where domainname='$domainname' and topleveldomain_id=$topleveldomain_id");
    if ($tld_a_check_AoH[0]{count}==0) {
      # - check if there is a price available for this topleveldomain_id and pricegroup_id
      # - in case true, save the domainname, in case false, confess
      my @price_check_AoH = $self->capullo_object->database->query("select count(id) as count from prices where topleveldomain_id=$topleveldomain_id and pricegroup_id=(select pricegroup_id from users where users.id=$user_id)");
      if ($price_check_AoH[0]{count}!=0) {
        if ($self->capullo_object->database->execute("insert into domainnames (id,user_id,domainname,topleveldomain_id,registrationdate,validity,autorenew,status_id) values (nextval('domainnames_seq'),$user_id,'$domainname',$topleveldomain_id,'$registration_date',$validity,$autorenew,$status_id);commit;")) {
          print "success";
        } else {
          print "error";
        }
      } else {
        print "error:no-price-defined-for-this-pricegroup-and-topleveldomain";
      }
    } else {
      print "error:domainname-already-in-this-database";
    }
  }
  
  sub action_manage {
    my ($self) = @_;
    if ($self->capullo_object->template->open("templates/domainname/manage.tmpl.html")) {
      my $page_number = $self->capullo_object->request->get("page", "int");
      $page_number = 1 if (!defined $page_number) or ($page_number eq "");
      
      my $user_id = $self->capullo_object->request->get("user_id", "int");
      $user_id = 1 if (!defined $user_id) or ($user_id eq "");
      
      my $domainnamesearchstring = $self->capullo_object->request->get("domainname", "clean");
      $domainnamesearchstring = "" if (!defined $domainnamesearchstring) or ($domainnamesearchstring eq "");
      
      my @domainnames_results_AoH = $self->capullo_object->database->query("select id,domainname,topleveldomain,username,registrationdate,validity,autorenew,status_code,status_name,costs from domainnames_results($page_number,$user_id,'$domainnamesearchstring') order by id asc");
      my @page_count_AoH = $self->capullo_object->database->query("select * from domainnames_get_pagecount($user_id,'$domainnamesearchstring') as pagecount");
      my $pagecount = $page_count_AoH[0]{pagecount};
      my @pages_AoH;
      for (my $run=1;$run<=$pagecount;$run++) {
        if ($run == $page_number) {
            push @pages_AoH, {pagenumber => $run}; 
        } else {
            push @pages_AoH, {pagenumber => "<a href=\"?page_id=domainname&amp;action=manage&page=$run&amp;user_id=$user_id\">$run</a>"}; 
        }
      }
      my @users_AoH = $self->capullo_object->database->query("select id,username from users");
      $self->capullo_object->template->passVariables("domainname-list" => \@domainnames_results_AoH); 
      $self->capullo_object->template->passVariables("pager" => \@pages_AoH); 
      $self->capullo_object->template->passVariables("users"=>\@users_AoH);
      $self->capullo_object->template->passVariables("domainname"=>$domainnamesearchstring);
      $self->capullo_object->template->render();
    }
  }
  
  sub action_edit {
    my ($self, $domainname_id) = @_;
    
    $domainname_id = 0 if (!defined $domainname_id) or ($domainname_id eq "");
    
    if ($self->capullo_object->template->open("templates/domainname/edit.tmpl.html")) {
      # - get domain relevant data
      my @domain_data_AoH = $self->capullo_object->database->query("select id,domainname,validity,autorenew,registrationdate from domainnames where id=$domainname_id");
      # - get all topleveldomains
      my @tlds_AoH = $self->capullo_object->database->query("select id, domain from topleveldomains");
      # - get all status codes
      my @status_AoH = $self->capullo_object->database->query("select id, code, description from status");
      # - get all users
      my @users_AoH = $self->capullo_object->database->query("select id,username from users");
      
      # - get the current topleveldomain id and name for this domainname
      my @curr_tld_AoH = $self->capullo_object->database->query("select id,domain from topleveldomains where id=(select topleveldomain_id from domainnames where domainnames.id=$domainname_id)");
      # - get the current status code and name (description)
      my @curr_status_AoH = $self->capullo_object->database->query("select id,code,description as name from status where id=(select status_id from domainnames where domainnames.id=$domainname_id)");
      # - get the current user id and name for this domainname
      my @curr_user_AoH = $self->capullo_object->database->query("select id,username from users where id=(select user_id from domainnames where domainnames.id=$domainname_id)");
      
      # - prepare the registrationdate string. It's saved as "2009-12-31". Needed: separated
      my @date_split = split(/-/, $domain_data_AoH[0]{registrationdate});
      
      # - and finally pass the data to the view
      $self->capullo_object->template->passVariables(id=>$domain_data_AoH[0]{id},domainname=>$domain_data_AoH[0]{domainname});
      $self->capullo_object->template->passVariables(curr_topleveldomain_id=>$curr_tld_AoH[0]{id});
      $self->capullo_object->template->passVariables(curr_topleveldomain_domain=>$curr_tld_AoH[0]{domain});
      $self->capullo_object->template->passVariables(tlds=>\@tlds_AoH);
      $self->capullo_object->template->passVariables(yearnumber=>$date_split[0],monthnumber=>$date_split[1],daynumber=>$date_split[2]);
      $self->capullo_object->template->passVariables(curr_validity=>$domain_data_AoH[0]{validity});
      $self->capullo_object->template->passVariables(curr_autorenew=>$domain_data_AoH[0]{autorenew});
      $self->capullo_object->template->passVariables(curr_status_id=>$curr_status_AoH[0]{id});
      $self->capullo_object->template->passVariables(curr_status_code=>$curr_status_AoH[0]{code});
      $self->capullo_object->template->passVariables(curr_status_name=>$curr_status_AoH[0]{name});
      $self->capullo_object->template->passVariables(curr_user_id=>$curr_user_AoH[0]{id});
      $self->capullo_object->template->passVariables(curr_username=>$curr_user_AoH[0]{username});
      $self->capullo_object->template->passVariables(users=>\@users_AoH);
      $self->capullo_object->template->passVariables(status=>\@status_AoH);
      # - and render it
      $self->capullo_object->template->render();
    }
  }
  
  sub action_edit_save {
    my ($self,$domainname_id,$validity,$autorenew,$status_id,$user_id) = @_;
    
    $autorenew = "false" if ($autorenew==0);
    $autorenew = "true" if ($autorenew==1);
    
    $domainname_id = 0 if (!defined $domainname_id) or ($domainname_id eq "");
    
    if ($self->capullo_object->database->execute("update domainnames set validity=$validity,autorenew=$autorenew,status_id=$status_id,user_id=$user_id where id=$domainname_id;commit;")) {
      print "success";
    } else {
      print "error";
    }
  }
  
  sub action_delete {
    my ($self,$domainname_id) = @_;
    $domainname_id = 0 if (!defined $domainname_id) or ($domainname_id eq "");
    if ($self->capullo_object->database->execute("delete from domainnames where id=$domainname_id;commit;")) {
      print "success";
    } else {
      print "error";
    }
  }
  
  sub action_user_manage {
    my ($self,$user_id) = @_;
    $user_id = 0 if (!defined $user_id) or ($user_id eq "");
    if ($self->capullo_object->template->open("templates/domainname/manage.user.tmpl.html")) {
      my $page_number = $self->capullo_object->request->get("page", "int");
      $page_number = 1 if (!defined $page_number) or ($page_number eq "");
      my @domainnames_results_AoH = $self->capullo_object->database->query("select id,domainname,topleveldomain,registrationdate,validity,autorenew,status_code,status_name,costs from domainnames_user_results($page_number,$user_id) order by id asc");
      my @page_count_AoH = $self->capullo_object->database->query("select * from domainnames_user_get_pagecount($user_id) as pagecount");
      my $pagecount = $page_count_AoH[0]{pagecount};
      my @pages_AoH;
      for (my $run=1;$run<=$pagecount;$run++) {
        if ($run == $page_number) {
            push @pages_AoH, {pagenumber => $run}; 
        } else {
            push @pages_AoH, {pagenumber => "<a href=\"?page_id=domainname&action=manage&page=$run\">$run</a>"}; 
        }
      }
      $self->capullo_object->template->passVariables("domainname-list" => \@domainnames_results_AoH); 
      $self->capullo_object->template->passVariables("pager" => \@pages_AoH); 
      $self->capullo_object->template->render();
    }
  }
  
1;