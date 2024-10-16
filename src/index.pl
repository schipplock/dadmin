#!/usr/bin/env perl
# -------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <andreas@schipplock.de> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Andreas Schipplock
# -------------------------------------------------------------------------------

use strict;
use Moose;
use JSON;

# --
# -- BEGIN setting additional include paths
# --

  use lib "/opt/capullo";
  use lib "/opt/dadmin/pages";

# --
# -- END setting additional include paths
# --

# --
# -- BEGIN pagecontroller
# --
 
  # -- 
  # -- BEGIN init of capullo
  # --
  
    use Capullo;
    # -- INIT Capullo
    my $app = Capullo->new(
      script_path => "/opt/dadmin",
      document_type => "text/html",
      apache_object => shift
    );
    $app->init();
    
  # --
  # -- END init of capullo
  # --
  
  # -- 
  # -- BEGIN init of sessions
  # --
  
    $app->session->session_save_path("/tmp/dadmin_sessions");
    $app->session->session_name("dadmin_session");
    $app->session->init();
    
  # -- 
  # -- END init of sessions
  # --
  
  # -- 
  # -- BEGIN reading the configuration
  # --
  
    my $configuration_parser = new JSON;
    my @configuration_content = $app->fileContent("config/config.json");
    my $configuration = $configuration_parser->decode("@configuration_content");
  
  # -- 
  # -- BEGIN reading the configuration
  # --
  
  # -- 
  # -- BEGIN setting up the database
  # --
    
    eval {
      my $db_host = $configuration->{database}->{host};
      my $db_user = $configuration->{database}->{user};
      my $db_pass = $configuration->{database}->{pass};
      my $db_database = $configuration->{database}->{database};
      $app->database->setup("pgsql", $db_host, $db_user, $db_pass, $db_database);
    };
    warn("error at stage _configuration_: could not read configuration options") if ($@);
    print "error:1000" if ($@);
  
  # -- 
  # -- END setting up the database
  # --
  
  # --
  # -- BEGIN setting up the auth component
  # --
  
    $app->authentication->setup($app->database, "users");
    
  # --
  # -- END setting up the auth component
  # --
  
  if ($app->database->connected()) {
  
    # --
    # -- BEGIN page components
    # --
 
      # -- LOAD the packages
      use Dadmin::Dashboard;
      use Dadmin::Login;
      use Dadmin::Logout;
      use Dadmin::Status;
      use Dadmin::Price;
      use Dadmin::User;
      use Dadmin::Domainname;
      use Dadmin::Expirecheck;
 
      # -- 
      # -- BEGIN evaluate the get request
      # --
      
        my $page_id = $app->request->get("page_id");
        if (!defined $page_id) { 
          $page_id = "_";
        }
 
        SWITCH: {
          # - COMPONENT: LOGIN
          if (($page_id eq "_") or ($page_id eq "login")) {
            my $login_component = Dadmin::Login->new(capullo_object => $app);
            $login_component->run();
            last SWITCH;
          }
          # - COMPONENT: LOGOUT
          if ($page_id eq "logout") {
            my $logout_component = Dadmin::Logout->new(capullo_object => $app);
            $logout_component->run();
            last SWITCH;
          }
          # - COMPONENT: DASHBOARD
          if ($page_id eq "dashboard") {
            my $dashboard_component = Dadmin::Dashboard->new(capullo_object => $app);
            $dashboard_component->run();
            last SWITCH;
          }
          # - COMPONENT: STATUS
          if ($page_id eq "status") {
            my $status_component = Dadmin::Status->new(capullo_object => $app);
            $status_component->run();
            last SWITCH;
          }
          # - COMPONENT: PRICE
          if ($page_id eq "price") {
            my $price_component = Dadmin::Price->new(capullo_object => $app);
            $price_component->run();
            last SWITCH;
          }
          # - COMPONENT: USER
          if ($page_id eq "user") {
            my $user_component = Dadmin::User->new(capullo_object => $app);
            $user_component->run();
            last SWITCH;
          }
          # - COMPONENT: DOMAINNAME
          if ($page_id eq "domainname") {
            my $domainname_component = Dadmin::Domainname->new(capullo_object => $app);
            $domainname_component->run();
            last SWITCH;
          }
          # - COMPONENT: EXPIRECHECK
          if ($page_id eq "expirecheck") {
            my $expirecheck_component = Dadmin::Expirecheck->new(capullo_object => $app);
            $expirecheck_component->run();
            last SWITCH;
          }
        }
 
      # --
      # -- END evaluate the get request
      # --
 
    # --
    # -- END page components
    # --
    
  } else {
    warn("error in stage _database_: could not connect to it");
    print "error:1001";
  }
  
# -- 
# -- END pagecontroller
# --