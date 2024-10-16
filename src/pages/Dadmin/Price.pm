# -------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <andreas@schipplock.de> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Andreas Schipplock
# -------------------------------------------------------------------------------

package Dadmin::Price;

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
              $self->action_new_group();
            }

            if ($action eq "new-group") {
              $self->action_new_group();
            }
            
            if ($action eq "new-group-save") {
              $self->action_new_group_save($self->capullo_object->request->get("name", "clean"));
            }
            
            if ($action eq "group-edit") {
                $self->action_edit_group($self->capullo_object->request->get("group_id","int"));
            }
            
            if ($action eq "edit-group-save") {
                $self->action_edit_group_save($self->capullo_object->request->get("group_id","int"),$self->capullo_object->request->get("name","clean"));
            }
            
            if ($action eq "group-delete") {
                $self->action_pricegroup_delete($self->capullo_object->request->get("group_id","int"));
            }
            
            if ($action eq "new-price") {
                $self->action_new_price();
            }
            
            if ($action eq "new-price-save") {
                my $tld_id = $self->capullo_object->request->get("tld_id","int");
                my $pricegroup_id = $self->capullo_object->request->get("pricegroup_id", "int");
                my $baseprice = $self->capullo_object->request->get("baseprice","float");
                my $salesprice = $self->capullo_object->request->get("salesprice","float");
                $self->action_new_price_save($tld_id,$baseprice,$salesprice,$pricegroup_id);
            }
            
            if ($action eq "price-edit") {
                $self->action_edit_price($self->capullo_object->request->get("price_id", "int"));
            }
            
            if ($action eq "edit-price-save") {
                my $price_id = $self->capullo_object->request->get("id","int");
                my $topleveldomain_id = $self->capullo_object->request->get("tld_id","int");
                my $baseprice = $self->capullo_object->request->get("baseprice","float");
                my $salesprice = $self->capullo_object->request->get("salesprice","float");
                my $pricegroup_id = $self->capullo_object->request->get("pricegroup_id","int");
                $self->action_edit_price_save($price_id,$topleveldomain_id,$baseprice,$salesprice,$pricegroup_id);
            }
            
            if ($action eq "price-delete") {
                my $price_id = $self->capullo_object->request->get("price_id","int");
                $self->action_delete_price($price_id);
            }
            
            if ($action eq "manage") {
              $self->action_manage();
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
    
    sub action_new_group {
      my ($self) = @_;
      if ($self->capullo_object->template->open("templates/price/new-group.tmpl.html")) {
        $self->capullo_object->template->render();
      }
    }
    
    sub action_new_group_save {
      my ($self,$name) = @_;
      if ($self->capullo_object->database->execute("insert into pricegroups (id,name) values (nextval('pricegroups_seq'), '$name');commit;")) {
        print "success";
      } else {
        print "error";
      }
    }
    
    sub action_manage {
        my ($self) = @_;
        if ($self->capullo_object->template->open("templates/price/manage.tmpl.html")) {
          my $page_number_groups = $self->capullo_object->request->get("gpage", "int");
          $page_number_groups = 1 if (!defined $page_number_groups) or ($page_number_groups eq "");
          my $page_number_prices = $self->capullo_object->request->get("ppage", "int");
          $page_number_prices = 1 if (!defined $page_number_prices) or ($page_number_prices eq "");
          my @pricegroups_results_AoH = $self->capullo_object->database->query("select id,name,users_associated from pricegroups_results($page_number_groups) order by id asc");
          my @prices_results_AoH = $self->capullo_object->database->query("select id,domain,domain_id,pricegroup,pricegroup_id,baseprice,salesprice from prices_results($page_number_prices) order by id asc");
          
          my @page_count_groups_AoH = $self->capullo_object->database->query("select * from pricegroups_get_pagecount() as pagecount");
          my $pagecount_groups = $page_count_groups_AoH[0]{pagecount};
          
          my @page_count_prices_AoH = $self->capullo_object->database->query("select * from prices_get_pagecount() as pagecount");
          my $pagecount_prices = $page_count_prices_AoH[0]{pagecount};
          
          my @pages_groups_AoH;
          my @pages_prices_AoH;
          
          for (my $run=1;$run<=$pagecount_groups;$run++) {
            if ($run == $page_number_groups) {
                push @pages_groups_AoH, {pagenumber => $run}; 
            } else {
                push @pages_groups_AoH, {pagenumber => "<a href=\"?page_id=price&amp;action=manage&amp;gpage=$run\">$run</a>"}; 
            }
          }
          
          for (my $run=1;$run<=$pagecount_prices;$run++) {
            if ($run == $page_number_prices) {
                push @pages_prices_AoH, {pagenumber => $run}; 
            } else {
                push @pages_prices_AoH, {pagenumber => "<a href=\"?page_id=price&amp;action=manage&amp;ppage=$run\">$run</a>"}; 
            }
          }
          
          $self->capullo_object->template->passVariables("pricegroup-list" => \@pricegroups_results_AoH, "price-list" => \@prices_results_AoH); 
          $self->capullo_object->template->passVariables("pager_groups" => \@pages_groups_AoH, "pager_prices" => \@pages_prices_AoH);
          $self->capullo_object->template->render();
        }
    }
    
    sub action_edit_group {
        my ($self,$group_id) = @_;
        $group_id = 1 if (!defined $group_id) or ($group_id eq "");
        if ($self->capullo_object->template->open("templates/price/edit-group.tmpl.html")) {
            my @group_resultset_AoH = $self->capullo_object->database->query("select id,name from pricegroups where id=$group_id");
            $self->capullo_object->template->passVariables(id=>$group_id, name=>$group_resultset_AoH[0]{name});
            $self->capullo_object->template->render();
        }
    }
    
    sub action_edit_group_save {
        my ($self,$group_id,$name) = @_;
        $group_id = 1 if (!defined $group_id) or ($group_id eq "");
        if ($self->capullo_object->database->execute("update pricegroups set name='$name' where id=$group_id;commit;")) {
            print "success";
        } else {
            print "error";
        }
    }
    
    sub action_pricegroup_delete {
        my ($self,$id) = @_;
        $id = 0 if (!defined $id) or ($id eq "");
        # - check if this pricegroup is set as a pricegroup on some user
        # - if so, abort deletion as it would cause an exception in the database
        my @AoH = $self->capullo_object->database->query("select count(users.id) as count from users where users.pricegroup_id=$id");
        if ($AoH[0]{count}==0) {
            if ($self->capullo_object->database->execute("delete from pricegroups where id=$id;commit;")) {
                print "success";
            } else {
                print "error";
            }
        } else {
            print "error:cant-delete-associated-pricegroup";
        }
    }
    
    sub action_new_price {
        my ($self) = @_;
        if ($self->capullo_object->template->open("templates/price/new-price.tmpl.html")) {
            my @tld_AoH = $self->capullo_object->database->query("select id,domain from topleveldomains");
            my @pricegroups_AoH = $self->capullo_object->database->query("select id,name from pricegroups order by id desc");
            $self->capullo_object->template->passVariables(tlds=>\@tld_AoH, pricegroups=>\@pricegroups_AoH);
            $self->capullo_object->template->render();
        }
    }
    
    sub action_new_price_save {
        my ($self,$tld_id,$baseprice,$salesprice,$pricegroup_id) = @_;
        $tld_id = 1 if (!defined $tld_id) or ($tld_id eq "");
        $pricegroup_id = 1 if (!defined $pricegroup_id) or ($pricegroup_id eq "");
        $baseprice = 0.00 if (!defined $baseprice) or ($baseprice eq "");
        $salesprice = 0.00 if (!defined $salesprice) or ($salesprice eq "");
        
        # - test if a price for this tld_id in the given pricegroup_id already defined
        my @a_check_AoH = $self->capullo_object->database->query("select count(id) as count from prices where topleveldomain_id=$tld_id and pricegroup_id=$pricegroup_id");
        if ($a_check_AoH[0]{count}==0) {
            if ($self->capullo_object->database->execute("insert into prices (id,topleveldomain_id,pricegroup_id,baseprice,salesprice) values (nextval('prices_seq'), $tld_id, $pricegroup_id, $baseprice, $salesprice);commit;")) {
                print "success";
            } else {
                print "error";
            }
        } else {
            print "error:tld-already-defined-with-this-group";
        }
    }
    
    sub action_edit_price {
        my ($self,$price_id) = @_;
        $price_id = 0 if (!defined $price_id) or ($price_id eq "");
        
        if ($self->capullo_object->template->open("templates/price/edit-price.tmpl.html")) {
            # - the general available topleveldomainnames and price groups
            # - used to display them in a drop down box in the "view"
            my @tld_AoH = $self->capullo_object->database->query("select id,domain from topleveldomains");
            my @pricegroups_AoH = $self->capullo_object->database->query("select id,name from pricegroups");
            
            # - the currently associated topleveldomain and pricegroup
            my @curr_tld_AoH = $self->capullo_object->database->query("select id,domain from price_get_topleveldomain($price_id)");
            my @curr_pricegroup_AoH = $self->capullo_object->database->query("select id,name from price_get_pricegroup($price_id)");
            my @curr_prices = $self->capullo_object->database->query("select baseprice,salesprice from prices where id=$price_id");
            
            $self->capullo_object->template->passVariables(id=>$price_id);
            $self->capullo_object->template->passVariables(tlds=>\@tld_AoH, pricegroups=>\@pricegroups_AoH);
            $self->capullo_object->template->passVariables(tld_id=>$curr_tld_AoH[0]{id},tld_domain=>$curr_tld_AoH[0]{domain});
            $self->capullo_object->template->passVariables(pricegroup_id=>$curr_pricegroup_AoH[0]{id},pricegroup_name=>$curr_pricegroup_AoH[0]{name});
            $self->capullo_object->template->passVariables(baseprice=>$curr_prices[0]{baseprice},salesprice=>$curr_prices[0]{salesprice});
            $self->capullo_object->template->render();
        }
    }
    
    sub action_edit_price_save {
        my ($self,$price_id,$topleveldomain_id,$baseprice,$salesprice,$pricegroup_id) = @_;
        
        # - there is never a price with id = 0, so it's safe to "try" to update the price with id 0 :)
        $price_id = 0 if (!defined $price_id) or ($price_id eq "");
        $topleveldomain_id = 0 if (!defined $topleveldomain_id) or ($topleveldomain_id eq "");
        $baseprice = 0.0 if (!defined $baseprice) or ($baseprice eq "");
        $salesprice = 0.0 if (!defined $salesprice) or ($salesprice eq "");
        $pricegroup_id = 0 if (!defined $pricegroup_id) or ($pricegroup_id eq "");
        
        if ($self->capullo_object->database->execute("update prices set topleveldomain_id=$topleveldomain_id,baseprice=$baseprice,salesprice=$salesprice,pricegroup_id=$pricegroup_id where id=$price_id;commit;")) {
            print "success";
        } else {
            print "error";
        }
    }
    
    sub action_delete_price {
        my ($self,$price_id) = @_;
        $price_id = 0 if (!defined $price_id) or ($price_id eq "");
        if ($self->capullo_object->database->execute("delete from prices where id=$price_id;commit;")) {
            print "success";
        } else {
            print "error";
        }
    }
  
1;