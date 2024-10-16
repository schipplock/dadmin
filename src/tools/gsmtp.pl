#!/usr/bin/perl
# GSmtp release 1
# smtp mailer for gmail with multipe attachment support

# -------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <andreas@schipplock.de> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Andreas Schipplock
# -------------------------------------------------------------------------------

use strict;
use Net::SMTP::TLS;
use URI::Escape;
use MIME::Lite;

my $debug = 0;

my $request = new AsRequest();

my $host = "smtp.gmail.com";
my $username = $request->get("username");
my $password = $request->get("password");
my $from = $request->get("from");
my $to = $request->get("to");
my $subject = $request->get("subject");
my $message = $request->get("message");
my $attachments = $request->get("attachments");
my $mimetype = "application/octet-stream";

print "error: missing username\n" and &help() and exit() if ($username eq "");
print "error: missing password\n" and &help() and exit() if ($password eq "");
print "error: missing to\n" and &help() and exit() if ($to eq "");
print "error: missing from\n" and &help() and exit() if ($from eq "");
print "error: missing subject\n" and &help() and exit() if ($subject eq "");
print "error: missing message\n" and &help() and exit() if ($message eq "");

my $mailer = new AsGMailer();
$mailer->setHost($host);
$mailer->setUsername($username);
$mailer->setPassword($password);
$mailer->setAttachments($attachments);

$mailer->send($from,$to,$subject,$message);

sub help {
	print "Example:\n./gmailer.pl --username=\"testuser\@gmail.com\" --password=thePassword --from=\"info\@webbiz.org\" --to=\"targetuser\@host.com\" --subject=\"Testemail dude\" --message=\"what I am here for is...\" --attachments=\"/tmp/file1.txt,/tmp/file2.txt\"\n";
}

package AsGMailer;

    sub new {
        my $class = shift;
        my $self = {};
        
        $self->{_host} = undef;
        $self->{_username} = undef;
        $self->{_password} = undef;
        $self->{_attachments} = undef;
            
        bless $self, $class;
        return $self;
    }
    
    sub setHost {
        my ($self, $host) = @_;
        $self->{_host} = $host;
    }
    
    sub getHost {
        my ($self) = @_;
        return $self->{_host};
    }
    
    sub setUsername {
        my ($self, $username) = @_;
        $self->{_username} = $username;
    }
    
    sub getUsername {
        my ($self) = @_;
        return $self->{_username};
    }
    
    sub setPassword {
        my ($self, $password) = @_;
        $self->{_password} = $password;
    }
    
    sub getPassword {
        my ($self) = @_;
        return $self->{_password};
    }
    
    sub setAttachments {
    	my ($self, $attachments) = @_;
    	$self->{_attachments} = $attachments;
	}
    
    sub send {
        my ($self,$from,$to,$subject,$body) = @_;
        my $host = $self->getHost();
        my $username = $self->getUsername();
        my $password = $self->getPassword();
        
        eval {
            my $mailer = new Net::SMTP::TLS($host, Timeout => 60, Port => 587, User => $username, Password => $password, Debug => $debug);
            
            $mailer->mail($from);
            $mailer->to($to);
            
            $mailer->data();
            
            my $message = MIME::Lite->new(
				From    => $from,
				To      => $to,
				Subject => $subject,
				Type    =>'multipart/mixed'
			);
			
			# TEXT
			$message->attach(
				Type => "TEXT",
				Data => $body
			);

			# ATTACHMENTS (if any)
			my @aSplit = split(/,/, $self->{_attachments});
			my $attachmentCount = @aSplit;
			for (my $arun=0;$arun<$attachmentCount;$arun++) {
				my $filepath = $aSplit[$arun];
				my @fileNameSplit = split(/\//, $filepath);
				my $fCount = @fileNameSplit;
				my $filename = $fileNameSplit[$fCount-1];
				$message->attach(
					Type        => $mimetype,
					Path        => $filepath,
					Filename    => $filename,
					Disposition => "attachment"
				);
			}
           
            $mailer->datasend($message->as_string);
            
            $mailer->dataend();
            $mailer->quit();
        };
        # net::smtp::tls _will_ trigger an error when _disconnecting_ from
        # google's smtp server, so when you set $debug to 1 you will get
        # a "error sending email" though it's sent successfully already
        print "error sending email!" if ($debug==1);
        print $@ if ($debug==1);
    }


package AsRequest;

    sub new {
    	my $self = {};
    	$self->{_root} = undef;
        bless $self, shift;
        $self->init();
        return $self;
    }
    
    sub init {
        my ($self) = @_;
    }
    
    sub getParam {
    	my ($self, $paramName) = @_;
    	my $length = @ARGV;
    	my $return = "";
    	for (my $run=0;$run<$length;$run++) {
    		my @argSplit = split(/=/,$ARGV[$run]);
    		$argSplit[0] =~ s/--//g;
    		if ($argSplit[0] eq $paramName) {
    			$return = $argSplit[1];
    		}
    	}
    	return $return;
	}
	
	sub count {
		my ($self) = @_;
		my $count = @ARGV;
		return $count;
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
    
    sub makeExtremeCleanString {
        my ($self, $uncleanString) = @_;
        my @allowedChars = ("0","1","2","3","4","5","6","7","8","9",
        					"A","B","C","D","E","F","G","H","I","J",
        					"K","L","M","N","O","P","Q","R","S","T",
        					"U","V","W","X","Y","Z",
        					"a","b","c","d","e","f","g","h","i","j", 
        					"k","l","m","n","o","p","q","r","s","t",
        					"u","v","w","x","y","z",".");     
             
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
    
    sub escapeString {
        my ($self, $uncleanString) = @_;
        my $cleanString = uri_escape($uncleanString,"\0-\377");
        return $cleanString;
    }
    
    sub unescapeString {
    	my ($self, $cleanString) = @_;
    	return uri_unescape($cleanString);
    }
