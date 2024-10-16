# -------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <andreas@schipplock.de> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Andreas Schipplock
# -------------------------------------------------------------------------------

package Capullo::Form;

use Moose;

  use Capullo::Request;

  has "root_directory" => (
    isa => "Str",
    is => "rw"
  );
  
  has "request_object" => (
    isa => "Capullo::Request",
    is => "rw"
  );
  
  has "error_count" => (
    isa => "Int",
    is => "rw",
    default => 0
  );
  
  has "file" => (
    is => "rw"
  );
  
  has "required_errors" => (
    isa => "Str",
    is => "rw",
    default => ""
  );
  
  has "available_names" => (
    isa => "Str",
    is => "rw",
    default => ""
  );
  
  has "ignore_elements" => (
    isa => "Str",
    is => "rw",
    default => ""
  );
  
  has "dynamic_options" => (
    is => "rw"
  );
    
  sub setup {
    my ($self,$formfile) = @_;
    $self->request_object(Capullo::Request->new());
    $self->request_object->init();
    $self->file($formfile);
  }
    
  sub show {
    my ($self) = @_;
    return $self->load();
  }
	
  sub error {
    my ($self) = @_;
    return $self->showErrorForm();
  }
    
  sub load {
    my ($self) = @_;
    my $file = $self->root_directory()."/".$self->file();
		
    open SOMEFILE, "$file";
    my @lines = <SOMEFILE>;
    	
    my @names;
    	
    my $content = "@lines";
    my @ksplit = split(/</, $content);
    my $length = @ksplit;
    # wipe out all form template tags
    for (my $run=0;$run<$length;$run++) {
      if ((index(lc($ksplit[$run]), "input")!=-1) or (index(lc($ksplit[$run]), "textarea")!=-1) or (index(lc($ksplit[$run]), "select")!=-1)) {
        my $string_kwd_pos = index(lc($ksplit[$run]), ":string");
        my $limitedstring_kwd_pos = index(lc($ksplit[$run]), ":limitedstring");
        my $email_kwd_pos = index(lc($ksplit[$run]), ":email");
        my $int_kwd_pos = index(lc($ksplit[$run]), ":int");
        my $html_kwd_pos = index(lc($ksplit[$run]), ":html");
        my $float_kwd_pos = index(lc($ksplit[$run]), ":float");
        # :string
        my ($name_string,$type_string,$required_string) = $self->getVarInfo("string", $ksplit[$run], $string_kwd_pos);
        if ($name_string ne "0") {
          push @names, $name_string;
          if (index($self->ignore_elements(), $name_string)==-1) {
            $content =~ s/<!-- $name_string.value \/\/-->//g;
            $content =~ s/<!-- $name_string.error \/\/-->//g;
          }
        }
        # :limitedstring
        my ($name_lstring,$type_lstring,$required_lstring) = $self->getVarInfo("limitedstring", $ksplit[$run], $limitedstring_kwd_pos);
        if ($name_lstring ne "0") {
          push @names, $name_lstring;
          if (index($self->ignore_elements(), $name_lstring)==-1) {
            $content =~ s/<!-- $name_lstring.value \/\/-->//g;
            $content =~ s/<!-- $name_lstring.error \/\/-->//g;
          }
        }
        # :int
        my ($name_int,$type_int,$required_int) = $self->getVarInfo("int", $ksplit[$run], $int_kwd_pos);
        if ($name_int ne "0") {
          push @names, $name_int;
          if (index($self->ignore_elements(), $name_int)==-1) {
            $content =~ s/<!-- $name_int.value \/\/-->//g;
            $content =~ s/<!-- $name_int.error \/\/-->//g;
          }
        }
        # :email
        my ($name_email,$type_email,$required_email) = $self->getVarInfo("email", $ksplit[$run], $email_kwd_pos);
        if ($name_email ne "0") {
          push @names, $name_email;
          if (index($self->ignore_elements(), $name_email)==-1) {
            $content =~ s/<!-- $name_email.value \/\/-->//g;
            $content =~ s/<!-- $name_email.error \/\/-->//g;
          }
        }
        # :html
        my ($name_html,$type_html,$required_html) = $self->getVarInfo("html", $ksplit[$run], $html_kwd_pos);
        if ($name_html ne "0") {
          push @names, $name_html;
          if (index($self->ignore_elements(), $name_html)==-1) {
            $content =~ s/<!-- $name_html.value \/\/-->//g;
            $content =~ s/<!-- $name_html.error \/\/-->//g;
          }
        }
        # :float
        my ($name_float,$type_float,$required_float) = $self->getVarInfo("float", $ksplit[$run], $float_kwd_pos);
        if ($name_float ne "0") {
          push @names, $name_float;
          if (index($self->ignore_elements(), $name_float)==-1) {
            $content =~ s/<!-- $name_float.value \/\/-->//g;
            $content =~ s/<!-- $name_float.error \/\/-->//g;
          }
        }
      }
    }
    	
    # parse for dynamic option values or preset values
    $length = @lines;
    for (my $run=0;$run<$length;$run++) {
      my $nameCount = @names;
      if ((@names)>0) {
        for (my $i=0;$i<$nameCount;$i++) {
          if (index(lc($lines[$run]), $names[$i].".dynamic.value")!=-1) {
            my $elementName = $names[$i];
            my $testCount;
            eval {
              $testCount = @{$self->{dynamicoptions}{$elementName}};
            };
            print "form template dynamic data error" if ($@);
            my $replaceString = "";
            my $originString = lc($lines[$run]);
            for (my $bla=0;$bla<$testCount;$bla++) {
						  my $tempString = $originString;
						  my $value = ${$self->{dynamicoptions}{$elementName}}[$bla]{value};
						  my $label = ${$self->{dynamicoptions}{$elementName}}[$bla]{label};
						  $tempString =~ s/<!-- $elementName.dynamic.value \/\/-->/$value/g;
						  $tempString =~ s/<!-- $elementName.dynamic.label \/\/-->/$label/g;
						  $replaceString .= $tempString;
					  }
					  # replace originString by replaceString
					  $content =~ s/$originString/$replaceString/g;
				  }
			  }
			}
		}
		
		# set preset values here
    my @namesplit = split(/,/, $self->available_names());
    for (my $run=0;$run<(@namesplit);$run++) {
      my $name = $namesplit[$run];
      my $value = $self->request_object->unescapeString($self->get($name));
      if (defined $value) {
        $content =~ s/<!-- $name.value \/\/-->/$value/g;
      } else {
        $content =~ s/<!-- $name.value \/\/-->//g;
      }
      # the next code pre sets <select ... <option selected="selected" ... 
      if (defined $self->{dynamic}{$name."_optional"}) {
        my $optionCaption = $self->{dynamic}{$name."_optional"};
        my $optionConstruct = "<option selected=\"selected\" value=\"$value\">$optionCaption</option>";
        $content =~ s/<!-- $name.selected \/\/-->/$optionConstruct/g;
      }
    }
    	
    # wipe out all form template datatypes
    $content =~ s/:string//g;
    $content =~ s/:limitedstring//g;
    $content =~ s/:email//g;
    $content =~ s/:int//g;
    $content =~ s/:html//g;
    $content =~ s/:float//g;
    $content =~ s/ required="true"//g;

    close SOMEFILE;
    	
    $self->file($file);
    	
    #return $altcontent;
    return $content;
  }
    
  sub validate {
    my ($self) = @_;
    my $file = $self->root_directory()."/".$self->file();
    	
    my $return = 1;
		
    open SOMEFILE, "$file";
    my @lines = <SOMEFILE>;
    my $content = "@lines";
    my @ksplit = split(/</, $content);
    for (my $run=0;$run<(@ksplit);$run++) {
      if ((index(lc($ksplit[$run]), "input")!=-1) or (index(lc($ksplit[$run]), "textarea")!=-1) or (index(lc($ksplit[$run]), "select")!=-1)) {
        my $string_kwd_pos = index(lc($ksplit[$run]), ":string");
        my $limitedstring_kwd_pos = index(lc($ksplit[$run]), ":limitedstring");
        my $email_kwd_pos = index(lc($ksplit[$run]), ":email");
        my $int_kwd_pos = index(lc($ksplit[$run]), ":int");
        my $html_kwd_pos = index(lc($ksplit[$run]), ":html");
        my $float_kwd_pos = index(lc($ksplit[$run]), ":float");
        # :string
        my ($name_string,$type_string,$required_string) = $self->getVarInfo("string", $ksplit[$run], $string_kwd_pos);
        if ($name_string ne "0") {
          $self->available_names($self->available_names().$name_string.",");
					if ($self->request_object->get($name_string) ne "") {
						$self->{dynamic}{$name_string} = $self->request_object->escapeString($self->request_object->get($name_string));
					} else {
						if ($required_string eq "true") {
							$self->error_count($self->error_count()+1);
							$self->required_errors($self->required_errors().",".$name_string);
						}
					}
    			}
    			# :limitedstring
    			my ($name_lstring,$type_lstring,$required_lstring) = $self->getVarInfo("limitedstring", $ksplit[$run], $limitedstring_kwd_pos);
    			if ($name_lstring ne "0") {
    				$self->available_names($self->available_names().$name_lstring.",");
					if ($self->request_object->get($name_lstring) ne "") {
						$self->{dynamic}{$name_lstring} = $self->request_object->makeExtremeCleanString($self->request_object->get($name_lstring));
					} else {
						if ($required_lstring eq "true") {
							$self->error_count($self->error_count()+1);
							$self->required_errors($self->required_errors().",".$name_lstring);
						}
					}
    			}
				# :int
				my ($name_int,$type_int,$required_int) = $self->getVarInfo("int", $ksplit[$run], $int_kwd_pos);
				if ($name_int ne "0") {
					$self->available_names($self->available_names().$name_int.",");
					if ($self->request_object->get($name_int) ne "") {
						$self->{dynamic}{$name_int} = $self->request_object->makeNumberString($self->request_object->get($name_int));
					} else {
						if ($required_int eq "true") {
							$self->error_count($self->error_count()+1);
							$self->required_errors($self->required_errors().",".$name_int);
						}
					}
    			}
				# :email
				my ($name_email,$type_email,$required_email) = $self->getVarInfo("email", $ksplit[$run], $email_kwd_pos);
				if ($name_email ne "0") {
					$self->available_names($self->available_names().$name_email.",");
					if ($self->request_object->get($name_email) ne "") {
						$self->{dynamic}{$name_email} = $self->request_object->escapeString($self->request_object->get($name_email));
					} else {
						if ($required_email eq "true") {
							$self->error_count($self->error_count()+1);
							$self->required_errors($self->required_errors().",".$name_email);
						}
					}
				}
				# :html
				my ($name_html,$type_html,$required_html) = $self->getVarInfo("html", $ksplit[$run], $html_kwd_pos);
				if ($name_html ne "0") {
					$self->available_names($self->available_names().$name_html.",");
					if ($self->request_object->get($name_html) ne "") {
						$self->{dynamic}{$name_html} = $self->request_object->makeHtmlString($self->request_object->get($name_html));
					} else {
						if ($required_html eq "true") {
							$self->error_count($self->error_count()+1);
							$self->required_errors($self->required_errors().",".$name_html);
						}
					}
				}
				# :float
				my ($name_float,$type_float,$required_float) = $self->getVarInfo("float", $ksplit[$run], $float_kwd_pos);
				if ($name_float ne "0") {
					$self->available_names($self->available_names().$name_float.",");
					if ($self->request_object->get($name_float) ne "") {
						$self->{dynamic}{$name_float} = $self->request_object->makeFloatString($self->request_object->get($name_float));
					} else {
						if ($required_float eq "true") {
							$self->error_count($self->error_count()+1);
							$self->required_errors($self->required_errors().",".$name_float);
						}
					}
				}
    		}
    	}
    	close SOMEFILE;
    	# if we hit errors in the form, we return 0 => false
    	if ($self->error_count() > 0) {
    		$return = 0;
    	} else {
    		# otherwise we return a 1 => true
    		$return = 1;
    	}
 		return $return;
    }
    
    sub getVarInfo {
    	my ($self, $dataType, $content, $keywordPosition) = @_;
    	my $dataTypeLength = length($dataType);
    	if ($keywordPosition ne -1) {
    		# extract name and type
    		my $name_pos = index(lc($content), "name=\"");
    		my $varcombi = substr $content, ($name_pos+6), ((($keywordPosition-$name_pos)+1)-(6-$dataTypeLength));
    		my @varsplit = split(/:/, $varcombi);
    		# extract if it's a required value or not
    		my @reqsplit = split(/required="/, $content);
    		my @finalsplit;
    		if ((@reqsplit)>1) {
    		  @finalsplit = split(/"/, $reqsplit[1]);
    		  if ($finalsplit[0] eq "") {
    			  $finalsplit[0] = "false";
    		  }
    		}
    		return ($varsplit[0],$varsplit[1],$finalsplit[0]);
    	} else {
    		return "0";
    	}
    }
    
    sub showErrorForm {
    	my ($self) = @_;
    	my $formfile = $self->root_directory()."/".$self->file();
    	open SOMEFILE, $formfile;
    	my @lines = <SOMEFILE>;
    	
    	my @names;
    	
    	my $content = "@lines";
    	my @ksplit = split(/</, $content);
    	my $length = @ksplit;
    	# collect names
    	for (my $run=0;$run<$length;$run++) {
    		if ((index(lc($ksplit[$run]), "input")!=-1) or (index(lc($ksplit[$run]), "textarea")!=-1) or (index(lc($ksplit[$run]), "select")!=-1)) {
    			my $string_kwd_pos = index(lc($ksplit[$run]), ":string");
    			my $limitedstring_kwd_pos = index(lc($ksplit[$run]), ":limitedstring");
    			my $email_kwd_pos = index(lc($ksplit[$run]), ":email");
    			my $int_kwd_pos = index(lc($ksplit[$run]), ":int");
    			my $html_kwd_pos = index(lc($ksplit[$run]), ":html");
    			my $float_kwd_pos = index(lc($ksplit[$run]), ":float");
    			# :string
    			my ($name_string,$type_string,$required_string) = $self->getVarInfo("string", $ksplit[$run], $string_kwd_pos);
    			if ($name_string ne "0") {
    				push @names, $name_string;
    			}
    			# :limitedstring
    			my ($name_lstring,$type_lstring,$required_lstring) = $self->getVarInfo("limitedstring", $ksplit[$run], $limitedstring_kwd_pos);
    			if ($name_lstring ne "0") {
    				push @names, $name_lstring;
    			}
				# :int
				my ($name_int,$type_int,$required_int) = $self->getVarInfo("int", $ksplit[$run], $int_kwd_pos);
				if ($name_int ne "0") {
					push @names, $name_int;
    			}
				# :email
				my ($name_email,$type_email,$required_email) = $self->getVarInfo("email", $ksplit[$run], $email_kwd_pos);
				if ($name_email ne "0") {
					push @names, $name_email;
				}
				# :html
				my ($name_html,$type_html,$required_html) = $self->getVarInfo("html", $ksplit[$run], $html_kwd_pos);
				if ($name_html ne "0") {
					push @names, $name_html;
				}
				# :float
				my ($name_float,$type_float,$required_float) = $self->getVarInfo("html", $ksplit[$run], $float_kwd_pos);
				if ($name_float ne "0") {
					push @names, $name_float;
				}
    		}
    	}
    	
    	# parse for dynamic option values
    	for (my $run=0;$run<(@lines);$run++) {
    		my $nameCount = @names;
    		for (my $i=0;$i<$nameCount;$i++) {
    			if (index(lc($lines[$run]), $names[$i].".dynamic.value")!=-1) {
					my $elementName = $names[$i];
					my $testCount;
					eval {
						$testCount = @{$self->{dynamicoptions}{$elementName}};
					};
					print "form template dynamic data error<br />" if ($@);
					my $replaceString = "";
					my $originString = lc($lines[$run]);
					for (my $bla=0;$bla<$testCount;$bla++) {
						my $tempString = $originString;
						my $value = ${$self->{dynamicoptions}{$elementName}}[$bla]{value};
						my $label = ${$self->{dynamicoptions}{$elementName}}[$bla]{label};
						$tempString =~ s/<!-- $elementName.dynamic.value \/\/-->/$value/g;
						$tempString =~ s/<!-- $elementName.dynamic.label \/\/-->/$label/g;
						$replaceString .= $tempString;
					}
					# replace originString by replaceString
					$content =~ s/$originString/$replaceString/g;
				}
			}	
		}
    	
    	# remove our keywords, we don't need them here
    	$content =~ s/:string//g;
    	$content =~ s/:limitedstring//g;
    	$content =~ s/:email//g;
    	$content =~ s/:int//g;
    	$content =~ s/:html//g;
    	$content =~ s/:float//g;
    	$content =~ s/ required="true"//g;
    	
    	# set the error messages
    	my @reqsplit = split(/,/, $self->required_errors());
    	for (my $run=0;$run<(@reqsplit);$run++) {
    		my $name = $reqsplit[$run];
    		$content =~ s/<!-- $name.error \/\/-->/required!/g;
    	}
    	
    	# set the value for each input so the user don't need to enter em again
    	my @namesplit = split(/,/, $self->available_names());
    	for (my $run=0;$run<(@namesplit);$run++) {
    		my $name = $namesplit[$run];
    		my $value = "";
    		$value = $self->request_object->unescapeString($self->get($name));
    		if (defined $value) {
    		  $content =~ s/<!-- $name.value \/\/-->/$value/g;
    		} else {
    		  $content =~ s/<!-- $name.value \/\/-->//g;
    		}
    		# setting the value for a <select option list is a bit more difficult
    		my $startpos_select = 0;
        my $endpos_select = 0;
        for (my $iirun=0;$iirun<(@lines);$iirun++) {
          my @optionSplit = split(/value=/, $lines[$iirun]);
          if ((@optionSplit)>1) {
            my @optionValueSplit = split(/>/, $optionSplit[1]);
            if ((@optionValueSplit)>0) {
              my @optionCaptionSplit = split(/<\/option/, $optionValueSplit[1]);
              my $optionValue = $optionValueSplit[0];
              my $optionCaption = $optionCaptionSplit[0];
              if (defined $value) {
                my $optionConstruct = "";
                $optionValue =~ s/"//g;
                $optionValue =~ s/'//g;
                if ($value eq $optionValue) {
                  $optionConstruct = "<option selected=\"selected\" value=\"$value\">$optionCaption</option>";
                  $content =~ s/<!-- $name.selected \/\/-->/$optionConstruct/g;
                }
              }
            }
          }
          # the next code pre sets DYNAMIC <select ... 
          if (defined $self->{dynamicoptions}) {
            my $testCount;
					  eval {
						  $testCount = @{$self->{dynamicoptions}{$name}};
					  };
            if (!$@) {
					    my $replaceString = "";
					    my $originString = lc($lines[$iirun]);
					    for (my $bla=0;$bla<$testCount;$bla++) {
						    my $db_value = ${$self->{dynamicoptions}{$name}}[$bla]{value};
						    my $db_label = ${$self->{dynamicoptions}{$name}}[$bla]{label};
						    my $optionConstruct = "";
						    if ((defined $value) and (defined $db_value)) {
                  if ($value eq $db_value) {
                   $optionConstruct = "<option selected=\"selected\" value=\"$value\">$db_label</option>";
                   $content =~ s/<!-- $name.selected \/\/-->/$optionConstruct/g;
                  }
                }
					    }
					  }
          }
        }
        # END parsing the <select fields
    	}
    	
    	close SOMEFILE;
    	
    	return $content;
    }
    
    sub get {
    	my ($self,$name) = @_;
    	return $self->{dynamic}{$name};
    }
    
    sub set {
    	my ($self,$name,$value,$optional) = @_;
    	$value =~ s/\n//g;
    	$self->{dynamic}{$name} = $value;
    	if (defined $optional) {
    	  $self->{dynamic}{$name."_optional"} = $optional; 
    	}
    	$self->available_names($self->available_names().$name.",");
    }
    
    sub presetSingle {
    	my ($self,$name,$value,$optional) = @_;
    	$self->set($name,$value,$optional);
    	$self->ignore_elements($self->ignore_elements().$name.",");
    }
    
    sub presetMulti {
    	my ($self, $name, @optionsAoH) = @_;
    	@{$self->{dynamicoptions}{$name}} = @optionsAoH;
    	$self->available_names($self->available_names().$name.",");
    	$self->ignore_elements($self->ignore_elements().$name.",");
	}
    
    sub showForm {
    	my ($self) = @_;
    	return $self->load();
    }
    
1;
