# -------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <andreas@schipplock.de> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Andreas Schipplock
# -------------------------------------------------------------------------------

package Dadmin::Dashboard;

use Moose;
use JSON;

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
        # - ADMINs section
        # -
        if ($self->capullo_object->authentication->isInGroup($sess_username, "admin")) {
            $self->view_admin_header();

            if ($action eq "_") {
                $self->view_admin_dashboard();
            }

            if ($action eq "") {
                $self->view_admin_dashboard();
            }

            $self->view_admin_footer();
        } 

        # - 
        # - USERs section
        # -
        if ($self->capullo_object->authentication->isInGroup($sess_username, "user")) {    
            $self->view_user_header();

            my @user_info_AoH = $self->capullo_object->database->query("select id from users where username='$sess_username'");
            my $user_id = $user_info_AoH[0]{id};

            if ($action eq "_") {
                $self->view_user_dashboard($user_id);
            }

            if ($action eq "") {
                $self->view_user_dashboard($user_id);
            }
            
            if ($action eq "request-domainname") {
                my $domainname = $self->capullo_object->request->get("domainname","clean");
                my $tld = $self->capullo_object->request->get("tld","clean");
                my $confirmation = $self->capullo_object->request->get("confirmation","int");
                if ($confirmation eq "1") {
                        $self->request_domainname($domainname,$tld,$sess_username);
                }
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
  
  sub view_user_dashboard {
    my ($self,$user_id) = @_;
    $user_id = 0 if (!defined $user_id) or ($user_id eq "");
    if ($self->capullo_object->template->open("templates/dashboard/user.view.tmpl.html")) {
        # - get the domain count for the current user_id
        my @domaincount_info_AoH = $self->capullo_object->database->query("select count(id) as count from domainnames where user_id=$user_id");
        
        # - get the last registered domainnames
        my @last_inserted_domainnames = $self->capullo_object->database->query("select domainname,(select domain from topleveldomains where topleveldomains.id=domainnames.topleveldomain_id) as domain from domainnames where domainnames.user_id=$user_id order by domainnames.id desc limit 10");
        
        # - calculate the overall costs of all the users' domainnames
        my @expense_info_AoH = $self->capullo_object->database->query("select user_get_overall_domain_costs from user_get_overall_domain_costs($user_id)");
        
        # - get all topleveldomains
        my @tlds_AoH = $self->capullo_object->database->query("select domain,(select salesprice from prices where prices.topleveldomain_id=topleveldomains.id and prices.pricegroup_id=(select pricegroup_id from users where users.id=$user_id)) as price from topleveldomains where (select salesprice from prices where prices.topleveldomain_id=topleveldomains.id and prices.pricegroup_id=(select pricegroup_id from users where users.id=$user_id))>0");
        
        # - get all expiring or auto-renewing domainnames for the next month (+1)
        my @expiring_names_in_one_month = $self->capullo_object->database->query("select id,domainname,tld,expire_date,autorenew from domain_expire_check($user_id,1)");
        
        # - get all expiring or auto-renewing domainnames for the next two months (+2)
        my @expiring_names_in_two_months = $self->capullo_object->database->query("select id,domainname,tld,expire_date,autorenew from domain_expire_check($user_id,2)");
        
        $self->capullo_object->template->passVariables(domaincount=>$domaincount_info_AoH[0]{count});
        $self->capullo_object->template->passVariables(overall_costs=>$expense_info_AoH[0]{user_get_overall_domain_costs});
        $self->capullo_object->template->passVariables(tlds=>\@tlds_AoH);
        $self->capullo_object->template->passVariables(tlds_expire_in_one_month=>\@expiring_names_in_one_month);
        $self->capullo_object->template->passVariables(tlds_expire_in_two_months=>\@expiring_names_in_two_months);
        $self->capullo_object->template->passVariables(lastdomainnames=>\@last_inserted_domainnames);
        $self->capullo_object->template->render();
    }
  }
  
  sub view_admin_dashboard {
    my ($self,$user_id) = @_;
    $user_id = 0 if (!defined $user_id) or ($user_id eq "");
    if ($self->capullo_object->template->open("templates/dashboard/admin.view.tmpl.html")) {
        # - get the domain count for the current user_id
        my @domaincount_info_AoH = $self->capullo_object->database->query("select count(id) as count from domainnames");

        # - get the last registered domainnames
        my @last_inserted_domainnames = $self->capullo_object->database->query("select domainname,(select domain from topleveldomains where topleveldomains.id=domainnames.topleveldomain_id) as domain from domainnames order by domainnames.id desc limit 10");

        # - calculate the overall costs of all the users' domainnames
        my @expense_info_AoH = $self->capullo_object->database->query("select user_get_overall_domain_costs from user_get_overall_domain_costs(1)");

        # - get all expiring or auto-renewing domainnames for the next month (+1)
        my @expiring_names_in_one_month = $self->capullo_object->database->query("select id,domainname,tld,expire_date,autorenew,(select username from users where users.id=(select user_id from domainnames where domainnames.id=domain_expire_check.id)) as username from domain_expire_check(1,1)");

        # - get all expiring or auto-renewing domainnames for the next two months (+2)
        my @expiring_names_in_two_months = $self->capullo_object->database->query("select id,domainname,tld,expire_date,autorenew,(select username from users where users.id=(select user_id from domainnames where domainnames.id=domain_expire_check.id)) as username from domain_expire_check(1,2)");
        
        # - get the amount of customers
        my @customer_stats_AoH = $self->capullo_object->database->query("select count(id) as count from users where id>1");
        
        # - get the costs per customer (baseprice here as we are admin)
        my @expenses_AoH = $self->capullo_object->database->query("select user_id,sum((select baseprice from prices where prices.pricegroup_id=(select pricegroup_id from users where users.id=domainnames.user_id) and prices.topleveldomain_id=domainnames.topleveldomain_id)) as sum, (select username from users where users.id=domainnames.user_id) as username from domainnames group by domainnames.user_id order by sum desc");

        $self->capullo_object->template->passVariables(domaincount=>$domaincount_info_AoH[0]{count});
        $self->capullo_object->template->passVariables(overall_costs=>$expense_info_AoH[0]{user_get_overall_domain_costs});
        $self->capullo_object->template->passVariables(tlds_expire_in_one_month=>\@expiring_names_in_one_month);
        $self->capullo_object->template->passVariables(tlds_expire_in_two_months=>\@expiring_names_in_two_months);
        $self->capullo_object->template->passVariables(lastdomainnames=>\@last_inserted_domainnames);
        $self->capullo_object->template->passVariables(usercount=>$customer_stats_AoH[0]{count});
        $self->capullo_object->template->passVariables(user_costs=>\@expenses_AoH);
        $self->capullo_object->template->render();
    }
  }
  
  sub request_domainname {
        my ($self,$domainname,$tld,$username) = @_;
        my $configuration_parser = new JSON;
        my @configuration_content = $self->capullo_object->fileContent("config/config.json");
        my $configuration = $configuration_parser->decode("@configuration_content");
        
        my $domain = $domainname.".".$tld;
 
        my $email_user = "";
        my $email_pass = "";
        my $targetemail = "";
        eval {
          $email_user = $configuration->{email}->{user};
          $email_pass = $configuration->{email}->{pass};
          $targetemail = $configuration->{domainrequest}->{targetemail};
        };
        warn("error at stage _configuration_: could not read configuration options") if ($@);
        print "error:1000" if ($@);
        
        my $script_path = $self->capullo_object->script_path();
        my $gsmtp_path = $script_path."/tools";
        
        qx|$gsmtp_path/gsmtp.pl --username="$email_user" --password="$email_pass" --from="$email_user" --to="$targetemail" --subject="Bitte $domain f. $username registrieren und abrechnen" --message="..."|;
        
        print "<h2>Vielen Dank! Wir werden Sie kontaktieren.</h2>";
  }
  
1;