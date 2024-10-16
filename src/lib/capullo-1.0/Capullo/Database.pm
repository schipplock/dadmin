# -------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <andreas@schipplock.de> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Andreas Schipplock
# -------------------------------------------------------------------------------

package Capullo::Database;

use Moose;

  use DBI;
  
  has "database_object" => (
    is => "rw"
  );
  
  has "database_type" => (
    isa => "Str",
    is => "rw",
    default => "mysql"
  );
  
  has "database_host" => (
    isa => "Str",
    is => "rw"
  );
  
  has "database_user" => (
    isa => "Str",
    is => "rw"
  );
  
  has "database_password" => (
    isa => "Str",
    is => "rw"
  );
  
  has "database_database" => (
    isa => "Str",
    is => "rw"
  );
    
  sub setup {
    my ($self,$type,$host,$user,$password,$database) = @_;
    $self->database_type($type);
    $self->database_host($host);
    $self->database_user($user);
    $self->database_password($password);
    $self->database_database($database);
  }
  
  sub connected {
    my ($self) = @_;
    my $return = 1;
    if ($self->openDatabase()) {
      $return = 1;
    } else {
      $return = 0;
    }
    $self->closeDatabase() if ($return==1);
    return $return;
  }
	
  sub openDatabase {
    my ($self) = @_;
    my $host = $self->database_host();
    my $user = $self->database_user();
    my $password = $self->database_password();
    my $database = $self->database_database();
    my $type = $self->database_type();
    eval {
      if ($type eq "mysql") {
        $self->database_object(DBI->connect("DBI:mysql:database=$database;host=$host","$user", "$password", {'RaiseError' => 1}));
      }
      if ($type eq "pgsql") {
        $self->database_object(DBI->connect("DBI:Pg:dbname=$database;host=$host","$user", "$password", {AutoCommit => 0, 'RaiseError' => 1}));
      }
    };
    my $return = 1;
    $return = 0 if ($@);
    return $return;
  }
	
  sub closeDatabase {
    my ($self) = @_;
    eval {
      $self->database_object->disconnect();
    };
    my $return = 1;
    $return = 0 if ($@);
    return $return;
  }
	
  sub execute {
    my ($self, $sql) = @_;
    my $return = 1;
    eval {
      if ($self->openDatabase()) {
        eval {
          $self->database_object->do($sql);
          $self->closeDatabase();
        };
        if ($@) {
          $return = 0;
        }
      } else {
        $return = 0;
      }
    };
    if ($@) {
      $return = 0;
    }
    return $return;
  }
	
  sub query {
    my ($self, $sql) = @_;
    my @AoH;
    my $return = 1;
    if ($self->openDatabase()) {
      my $sth = $self->database_object->prepare($sql);
      eval {
        $sth->execute();
      };
      if ($@) {
        $return = 0;
        warn("execution of the statement failed");
      }
      eval {
        my $arCount = 0;
        while (my $ref = $sth->fetchrow_hashref()) {
          push @AoH, $ref;
          $arCount++;
        }
        $sth->finish();
        $self->closeDatabase();
      };
      if ($@) {
        $return = 0;
        warn("fetching the rows failed");
      }
    } else {
      $return = 0;
      warn("connection to the database could not be established");
    }
    if ($return==0) {
      die("database error: see warnings above");
    } else {
      return (@AoH);
    }
  }
  
1;
