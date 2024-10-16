# -------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <andreas@schipplock.de> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Andreas Schipplock
# -------------------------------------------------------------------------------

package Dadmin::Expirecheck;

use Moose;
use JSON;

  has "capullo_object" => (
    isa => "Capullo",
    is => "rw",
    required => 1
  );
  
  sub run {
    my ($self) = @_;
    
    $self->capullo_object->apache_object->content_type("text/plain");
    
    my $simple_secret = $self->capullo_object->request->get("s");

    if ($simple_secret eq "whothebeepisAlice") {
        # - send info mail to the admin and user/s
        my @users_AoH = $self->capullo_object->database->query("select id from users");
        for (my $run=0;$run<(@users_AoH);$run++) {
          $self->send_email($users_AoH[$run]{id});
        }
    } else {
        print "error:unauthorized-access";
    }
  }
  
  sub send_email {
    my ($self,$user_id) = @_;
      my $configuration_parser = new JSON;
      my @configuration_content = $self->capullo_object->fileContent("config/config.json");
      my $configuration = $configuration_parser->decode("@configuration_content");
      
      my $email_user = "";
      my $email_pass = "";
      eval {
        $email_user = $configuration->{email}->{user};
        $email_pass = $configuration->{email}->{pass};
      };
      warn("error at stage _configuration_: could not read configuration options") if ($@);
      print "error:1000" if ($@);
 
      # - get all expiring or auto-renewing domainnames for the next month (+1)
      my @expiring_names_in_one_month = $self->capullo_object->database->query("select id,domainname,tld,expire_date,autorenew,(select username from users where users.id=(select user_id from domainnames where domainnames.id=domain_expire_check.id)) as username,(select validity from domainnames where domainnames.id=domain_expire_check.id) as validity,(select salesprice from prices where prices.topleveldomain_id=(select id from topleveldomains where topleveldomains.domain=domain_expire_check.tld) and prices.pricegroup_id=(select pricegroup_id from users where users.id=(select user_id from domainnames where domainnames.id=domain_expire_check.id))) as vk, (select email from users where users.id=(select user_id from domainnames where domainnames.id=domain_expire_check.id)) as useremail from domain_expire_check($user_id,1)");
 
      # - get all expiring or auto-renewing domainnames for the next two months (+2)
      my @expiring_names_in_two_months = $self->capullo_object->database->query("select id,domainname,tld,expire_date,autorenew,(select username from users where users.id=(select user_id from domainnames where domainnames.id=domain_expire_check.id)) as username,(select validity from domainnames where domainnames.id=domain_expire_check.id) as validity,(select salesprice from prices where prices.topleveldomain_id=(select id from topleveldomains where topleveldomains.domain=domain_expire_check.tld) and prices.pricegroup_id=(select pricegroup_id from users where users.id=(select user_id from domainnames where domainnames.id=domain_expire_check.id))) as vk, (select email from users where users.id=(select user_id from domainnames where domainnames.id=domain_expire_check.id)) as useremail from domain_expire_check($user_id,2)");
 
      my $email_content = "Domainnamen, die naechsten Monat auslaufen oder autom. erweitert werden:\n\n";
      
      for (my $run=0;$run<(@expiring_names_in_one_month);$run++) {
        if ($expiring_names_in_one_month[$run]{autorenew}==1) {
          $email_content .= "- ".$expiring_names_in_one_month[$run]{domainname}.".".$expiring_names_in_one_month[$run]{tld}." (VK: ".$expiring_names_in_one_month[$run]{vk}.")\tvon ".$expiring_names_in_one_month[$run]{username}." wird um ".$expiring_names_in_one_month[$run]{validity}." Jahr/e verlaengert (".$expiring_names_in_one_month[$run]{expire_date}.")\n";
        } else {
          $email_content .= "- ".$expiring_names_in_one_month[$run]{domainname}.".".$expiring_names_in_one_month[$run]{tld}." (VK: ".$expiring_names_in_one_month[$run]{vk}.")\tvon ".$expiring_names_in_one_month[$run]{username}." laeuft am ".$expiring_names_in_one_month[$run]{expire_date}." aus\n";
        }
      }
      
      $email_content .= "\n\n\n";
      
      $email_content .= "Domainnamen, die uebernaechsten Monat auslaufen oder autom. erweitert werden:\n\n";

      for (my $run=0;$run<(@expiring_names_in_two_months);$run++) {
        if ($expiring_names_in_two_months[$run]{autorenew}==1) {
          $email_content .= "- ".$expiring_names_in_two_months[$run]{domainname}.".".$expiring_names_in_two_months[$run]{tld}." (VK: ".$expiring_names_in_two_months[$run]{vk}.")\tvon ".$expiring_names_in_two_months[$run]{username}." wird um ".$expiring_names_in_two_months[$run]{validity}." Jahr/e verlaengert (".$expiring_names_in_one_month[$run]{expire_date}.")\n";
        } else {
          $email_content .= "- ".$expiring_names_in_two_months[$run]{domainname}.".".$expiring_names_in_two_months[$run]{tld}." (VK: ".$expiring_names_in_two_months[$run]{vk}.")\tvon ".$expiring_names_in_two_months[$run]{username}." laeuft am ".$expiring_names_in_two_months[$run]{expire_date}." aus\n";
        }
      }
      
      my $email = $expiring_names_in_one_month[0]{useremail};
      
      # - save the contents to a temp file
      open TEMPFILE, ">/tmp/dadmin_emailcontent.txt";
      my $attachment = "/tmp/dadmin_emailcontent.txt"; 
      print TEMPFILE $email_content;
      close TEMPFILE;
      
      my $script_path = $self->capullo_object->script_path();
      my $gsmtp_path = $script_path."/tools";
      
      # - send the contents of the file via email to the desired email
      qx|$gsmtp_path/gsmtp.pl --username="$email_user" --password="$email_pass" --from="$email_user" --to="$email" --subject="Domainnamen Report" --message="siehe Anhang" --attachments="$attachment"|;
  }
  
1;