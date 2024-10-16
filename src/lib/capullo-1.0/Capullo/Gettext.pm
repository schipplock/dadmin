# -------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <andreas@schipplock.de> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Andreas Schipplock
# -------------------------------------------------------------------------------

package Capullo::Gettext;

use Moose;

  has "root_directory" => (
    isa => "Str",
    is => "rw"
  );
  
  has "locale_directory" => (
    isa => "Str",
    is => "rw"
  );
  
  has "language" => (
    isa => "Str",
    is => "rw"
  );
    
  sub get {
    my ($self, $msgid) = @_;
    my $file = $self->root_directory()."/".$self->locale_directory()."/".$self->language().".po";
    my $returnVal = undef;
    eval {
      open PO, $file;
      my @poLines = <PO>;
      for (my $run=0;$run<(@poLines);$run++) {
        my @lineSplit = split(/msgid/, $poLines[$run]);
        my @msgidContentSplit = split(/"/, $lineSplit[1]);
        if ($msgidContentSplit[1] eq $msgid) {
          my @msgstrLineSplit = split(/msgstr/, $poLines[$run+1]);
          my @msgstrContentSplit = split(/"/, $msgstrLineSplit[1]);
          $returnVal = $msgstrContentSplit[1];
        }
      }
      close PO;
    };
    $returnVal = "gettext error in get" if ($@);
    return $returnVal;
  }
  
1;
