# -------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <andreas@schipplock.de> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Andreas Schipplock
# -------------------------------------------------------------------------------

package Dadmin::User;

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
   
            if ($action eq "new") {
              $self->action_new();
            }
            
            if ($action eq "new-save") {
                my $username = $self->capullo_object->request->get("username","clean");
                my $password = $self->capullo_object->request->get("password","clean");
                my $password_repeated = $self->capullo_object->request->get("password-repeated","clean");
                my $company = $self->capullo_object->request->get("company","clean");
                my $firstname = $self->capullo_object->request->get("firstname","clean");
                my $lastname = $self->capullo_object->request->get("lastname","clean");
                my $email = $self->capullo_object->request->get("email","clean");
                my $phone = $self->capullo_object->request->get("phone","clean");
                my $mobile = $self->capullo_object->request->get("mobile","clean");
                my $country = $self->capullo_object->request->get("country","clean");
                my $zipcode = $self->capullo_object->request->get("zipcode","int");
                my $city = $self->capullo_object->request->get("city","clean");
                my $street = $self->capullo_object->request->get("street","clean");
                my $pricegroup_id = $self->capullo_object->request->get("pricegroup_id","int");
                
                if ($password ne $password_repeated) {
                    print "error:password-not-matching";
                } else {
                    $self->action_new_save($username,$password,$company,$firstname,$lastname,$email,$phone,$mobile,$country,$zipcode,$city,$street,$pricegroup_id);
                }
            }
   
            if ($action eq "manage") {
              $self->action_manage();
            }
            
            if ($action eq "edit") {
                my $user_id = $self->capullo_object->request->get("user_id","int");
                if (($user_id==1) or ($user_id eq "1")) {
                    print "error:first-admin-cannot be changed";
                } else {
                    $self->action_edit($user_id);
                }
            }
            
            if ($action eq "edit-save") {
                my $user_id = $self->capullo_object->request->get("user_id","int");
                my $password = $self->capullo_object->request->get("password","clean");
                my $password_repeated = $self->capullo_object->request->get("password-repeated","clean");
                my $company = $self->capullo_object->request->get("company","clean");
                my $firstname = $self->capullo_object->request->get("firstname","clean");
                my $lastname = $self->capullo_object->request->get("lastname","clean");
                my $email = $self->capullo_object->request->get("email","clean");
                my $phone = $self->capullo_object->request->get("phone","clean");
                my $mobile = $self->capullo_object->request->get("mobile","clean");
                my $country = $self->capullo_object->request->get("country","clean");
                my $zipcode = $self->capullo_object->request->get("zipcode","int");
                my $city = $self->capullo_object->request->get("city","clean");
                my $street = $self->capullo_object->request->get("street","clean");
                my $pricegroup_id = $self->capullo_object->request->get("pricegroup_id","int");
                
                if (($user_id==1) or ($user_id eq "1")) {
                    print "error:first-admin-cannot be changed";
                } else {
                    if ($password ne $password_repeated) {
                        print "error:password-not-matching";
                    } else {
                        $self->action_edit_save($user_id,$password,$company,$firstname,$lastname,$email,$phone,$mobile,$country,$zipcode,$city,$street,$pricegroup_id);
                    }
                }
            }
            
            if ($action eq "delete") {
                my $user_id = $self->capullo_object->request->get("user_id","int");
                $self->action_delete($user_id);
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
    if ($self->capullo_object->template->open("templates/user/new.tmpl.html")) {
        # - we need a dropdown with all pricegroups so fetch the pricegroups here
        my @pricegroups_AoH = $self->capullo_object->database->query("select id,name from pricegroups order by id desc");
        # - pass it and render
        $self->capullo_object->template->passVariables(pricegroups=>\@pricegroups_AoH);
        $self->capullo_object->template->render();
    }
  }
  
  sub action_new_save {
    my ($self,$username,$password,$company,$firstname,$lastname,$email,$phone,$mobile,$country,$zipcode,$city,$street,$pricegroup_id) = @_;
    $company = "-" if (!defined $company) or ($company eq "");
    $firstname = "-" if (!defined $firstname) or ($firstname eq "");
    $lastname = "-" if (!defined $lastname) or ($lastname eq "");
    $email = "-" if (!defined $email) or ($email eq "");
    $phone = "-" if (!defined $phone) or ($phone eq "");
    $mobile = "-" if (!defined $mobile) or ($mobile eq "");
    $country = "-" if (!defined $country) or ($country eq "");
    $zipcode = 0 if (!defined $zipcode) or ($zipcode eq "");
    $city = "-" if (!defined $city) or ($city eq "");
    $street = "-" if (!defined $street) or ($street eq "");
    $pricegroup_id = 0 if (!defined $pricegroup_id) or ($pricegroup_id eq "");
    if ($self->capullo_object->database->execute("insert into users (id,username,password,groups,company,firstname,lastname,email,phone,mobile,country,zipcode,city,street,pricegroup_id) values (nextval('users_seq'),'$username',md5('$password'),'user','$company','$firstname','$lastname','$email','$phone','$mobile','$country',$zipcode,'$city','$street',$pricegroup_id);commit;")) {
        print "success";
    } else {
        print "error";
    }
  }
  
  sub action_manage {
    my ($self) = @_;
    if ($self->capullo_object->template->open("templates/user/manage.tmpl.html")) {
      my $page_number = $self->capullo_object->request->get("page", "int");
      $page_number = 1 if (!defined $page_number) or ($page_number eq "");
      my @users_results_AoH = $self->capullo_object->database->query("select id,username,firstname,lastname,email,phone,pricegroup_name,pricegroup_id,domaincount from users_results($page_number) order by id asc");
      my @page_count_AoH = $self->capullo_object->database->query("select * from users_get_pagecount() as pagecount");
      my $pagecount = $page_count_AoH[0]{pagecount};
      my @pages_AoH;
      for (my $run=1;$run<=$pagecount;$run++) {
        if ($run == $page_number) {
            push @pages_AoH, {pagenumber => $run}; 
        } else {
            push @pages_AoH, {pagenumber => "<a href=\"?page_id=user&action=manage&page=$run\">$run</a>"}; 
        }
      }
      $self->capullo_object->template->passVariables("user-list" => \@users_results_AoH); 
      $self->capullo_object->template->passVariables("pager" => \@pages_AoH); 
      $self->capullo_object->template->render();
    }
  }
  
  sub action_edit {
    my ($self,$user_id) = @_;
    if ($self->capullo_object->template->open("templates/user/edit.tmpl.html")) {
        $user_id = 0 if (!defined $user_id) or ($user_id eq "");
        # - get the pricegroups
        my @pricegroups_AoH = $self->capullo_object->database->query("select id,name from pricegroups order by id desc");
        
        # - get the current pricegroup info associated to this user
        my @curr_pricegroup = $self->capullo_object->database->query("select id,name from user_get_pricegroup($user_id)");
        
        # - get all the needed user data
        my @userdata_AoH = $self->capullo_object->database->query("select id,username,company,firstname,lastname,email,phone,mobile,country,zipcode,city,street from users where id=$user_id");
        
        # - pass all the collected info to the view and render it
        $self->capullo_object->template->passVariables("id"=>$userdata_AoH[0]{id});
        $self->capullo_object->template->passVariables("username"=>$userdata_AoH[0]{username},"company"=>$userdata_AoH[0]{company});
        $self->capullo_object->template->passVariables("firstname"=>$userdata_AoH[0]{firstname},"lastname"=>$userdata_AoH[0]{lastname});
        $self->capullo_object->template->passVariables("email"=>$userdata_AoH[0]{email});
        $self->capullo_object->template->passVariables("phone"=>$userdata_AoH[0]{phone},"mobile"=>$userdata_AoH[0]{mobile});
        $self->capullo_object->template->passVariables("country"=>$userdata_AoH[0]{country},"zipcode"=>$userdata_AoH[0]{zipcode});
        $self->capullo_object->template->passVariables("city"=>$userdata_AoH[0]{city},"street"=>$userdata_AoH[0]{street});
        $self->capullo_object->template->passVariables("pricegroups"=>\@pricegroups_AoH);
        $self->capullo_object->template->passVariables("curr_pricegroup_id"=>$curr_pricegroup[0]{id}, "curr_pricegroup_name"=>$curr_pricegroup[0]{name});
        $self->capullo_object->template->render();
    }
  }
  
  sub action_edit_save {
    my ($self,$user_id,$password,$company,$firstname,$lastname,$email,$phone,$mobile,$country,$zipcode,$city,$street,$pricegroup_id) = @_;
    $user_id = 0 if (!defined $user_id) or ($user_id eq "");
    $company = "-" if (!defined $company) or ($company eq "");
    $firstname = "-" if (!defined $firstname) or ($firstname eq "");
    $lastname = "-" if (!defined $lastname) or ($lastname eq "");
    $email = "-" if (!defined $email) or ($email eq "");
    $phone = "-" if (!defined $phone) or ($phone eq "");
    $mobile = "-" if (!defined $mobile) or ($mobile eq "");
    $country = "-" if (!defined $country) or ($country eq "");
    $zipcode = 0 if (!defined $zipcode) or ($zipcode eq "");
    $city = "-" if (!defined $city) or ($city eq "");
    $street = "-" if (!defined $street) or ($street eq "");
    $pricegroup_id = 0 if (!defined $pricegroup_id) or ($pricegroup_id eq "");
    
    # - check if a password is provided
    # - in case also update the password, otherwise -> don't!
    if ($password eq "") {
        if ($self->capullo_object->database->execute("update users set company='$company',lastname='$lastname',email='$email',phone='$phone',mobile='$mobile',country='$country',zipcode=$zipcode,city='$city',street='$street',pricegroup_id=$pricegroup_id where id=$user_id;commit;")) {
            print "success";
        } else {
            print "error";
        }
    } else {
        if ($self->capullo_object->database->execute("update users set password=md5('$password'),company='$company',lastname='$lastname',email='$email',phone='$phone',mobile='$mobile',country='$country',zipcode=$zipcode,city='$city',street='$street',pricegroup_id=$pricegroup_id where id=$user_id;commit;")) {
            print "success";
        } else {
            print "error";
        }
    }
  }
  
  sub action_delete {
    my ($self,$user_id)=@_;
    $user_id = 0 if (!defined $user_id) or ($user_id eq "");
    if (($user_id==1) or ($user_id eq "1")) {
        print "error:first-admin-cannot be deleted";
    } else {
        if ($self->capullo_object->database->execute("delete from users where id=$user_id;commit;")) {
            print "success";
        } else {
            print "error";
        }
    }
  }
  
1;