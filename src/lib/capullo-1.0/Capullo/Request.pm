# -------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <andreas@schipplock.de> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Andreas Schipplock
# -------------------------------------------------------------------------------

package Capullo::Request;

use Moose;

use CGI::Minimal;
use HTML::Strip;
use URI::Escape;

  has "request_object" => (
    isa => "CGI::Minimal",
    is => "rw"
  );
    
  sub init {
    my ($self) = @_;
    $self->request_object(CGI::Minimal->new());
  }
    
  sub getParam {
    my ($self, $paramName) = @_;
    return $self->request_object->param($paramName);
  }
	
  sub get {
    my ($self,$paramName, $mode) = @_;
    my $return = "";
    if (lc($mode) eq "escape") {
      $return = $self->escapeString($self->getParam($paramName));
    }
    if (lc($mode) eq "clean") {
      $return = $self->makeExtremeCleanString($self->getParam($paramName));
    }
    if (lc($mode) eq "float") {
      $return = $self->makeFloatString($self->getParam($paramName));
    }
    if (lc($mode) eq "int") {
      $return = $self->makeNumberString($self->getParam($paramName));
    }
    if (lc($mode) eq "") {
      $return = $self->getParam($paramName);
    }
    return $return;
  }
    
  sub stripHtml {
    my ($self, $rawHtml) = @_;
    my $hs = HTML::Strip->new();
    my $cleanText = $hs->parse($rawHtml);
    $hs->eof;
    return $cleanText;
  }
    
  sub makeExtremeCleanString {
    my ($self, $uncleanString) = @_;
    $uncleanString = $self->stripHtml($uncleanString);
    my @allowedChars = ("0","1","2","3","4","5","6","7","8","9",
                        "A","B","C","D","E","F","G","H","I","J",
                        "K","L","M","N","O","P","Q","R","S","T",
                        "U","V","W","X","Y","Z",
                        "a","b","c","d","e","f","g","h","i","j", 
                        "k","l","m","n","o","p","q","r","s","t",
                        "u","v","w","x","y","z",".","-","@"," ");     
             
    my $cleanString = "";
    my @splitAr = split(//, $uncleanString);
    my $splitArCount = @splitAr;
    my $run=0;
    for ($run=0;$run<$splitArCount;$run++) {
      if(grep $_ eq $splitAr[$run], @allowedChars) {
        $cleanString .= $splitAr[$run];
      }
    }
    return $cleanString;
  }
    
  sub makeNumberString {
    my ($self, $uncleanString) = @_;
    $uncleanString = $self->stripHtml($uncleanString);
    my @allowedChars = ("0","1","2","3","4","5","6","7","8","9");     
             
    my $cleanString = "";
    my @splitAr = split(//, $uncleanString);
    my $splitArCount = @splitAr;
    my $run=0;
    for ($run=0;$run<$splitArCount;$run++) {
      if(grep $_ eq $splitAr[$run], @allowedChars) {
        $cleanString .= $splitAr[$run];
      }
    }
    return $cleanString;
  }
    
  sub makeFloatString {
    my ($self, $uncleanString) = @_;
    $uncleanString = $self->stripHtml($uncleanString);
    my @allowedChars = ("0","1","2","3","4","5","6","7","8","9",".");     
             
    my $cleanString = "";
    my @splitAr = split(//, $uncleanString);
    my $splitArCount = @splitAr;
    my $run=0;
    for ($run=0;$run<$splitArCount;$run++) {
      if(grep $_ eq $splitAr[$run], @allowedChars) {
        $cleanString .= $splitAr[$run];
      }
    }
    return $cleanString;
  }
    
  sub makeHtmlString {
    my ($self, $uncleanString) = @_;      
    my $cleanString = uri_escape($uncleanString,"\0-\377");
    return $cleanString;
  }
    
  sub escapeString {
    my ($self, $uncleanString) = @_;
    $uncleanString = $self->stripHtml($uncleanString);
    my $cleanString = uri_escape($uncleanString,"\0-\377");
    return $cleanString;
  }
    
  sub unescapeString {
    my ($self, $cleanString) = @_;
    return uri_unescape($cleanString);
  }
  
1;
