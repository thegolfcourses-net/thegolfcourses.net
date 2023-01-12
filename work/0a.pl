#continue populating the golf course database with additional data from each web link found from the first scrape in 0.pl
use Win32::ODBC;
use LWP::UserAgent;
$ua = new LWP::UserAgent;
$ua->agent('Mozilla/4.0 (compatible; MSIE 4.01; Windows 95)');
$SIG{'ALRM'} = "timeout";

$DSN = "golfcourses";
if (!($db = new Win32::ODBC($DSN))) {
  print "Error connecting to $DSN\n";
  print "Error: " . Win32::ODBC::Error() . "\n";
  exit;
}
if (!($db1 = new Win32::ODBC($DSN))) {
  print "Error connecting to $DSN\n";
  print "Error: " . Win32::ODBC::Error() . "\n";
  exit;
}
$saved_place = 0;
&findLink;

sub findLink {
  $stmt = "SELECT ID from Main";
  $rc = $db->Sql($stmt);
  die "SQL failed \"$stmt\": $db->Error()\n" if $rc;
  while ($db->FetchRow()) {
    $id = $db->Data; 
    last if ($id == 1779456);  # cycle through the ones already succesfully done
  }
  while ($db->FetchRow()) {
    $id = $db->Data;
# next if ($id ne "4323");
    $url = "http://www.golflink.com/golf-courses/course.aspx?course=$id";
    &send;    
  }
}
    
sub send {
    if ($saved_place) {
      $nexturl = "$url";
      $saved_place = 0;
    }
    else {
      $nexturl = "$url";
    }
    $success = 0; $conn_tries = 0;
    while ($success == 0) {
        my $req = new HTTP::Request 'GET' => $nexturl;
       $req->header('Accept' => 'text/html');
        my $res = $ua->request($req, "results");
        if (!$res->is_success) {
           $conn_tries++;
           die "Connection failure\n" if ($conn_tries == 5);
        }
        else { 
           $success = 1;
           &process;
        }
   }
}

sub process {
  open (RESULTS, "results") or die "can't open results\n";
  &gather_data;
  close RESULTS;
}

sub gather_data {
  while ($line = <RESULTS>) {
    if ($line =~ /About this course:/) {
      $line = <RESULTS>;
      if ($line =~ /\| (\d+) slope<\/p><p>(.+) rating/) {
        $slope = $1;
	$rating = $2;
      }
    }
    if ($line =~ /\.  Designed by (.+), /) {
      $designer = $1;
      if (length ($designer) < 2) {
	undef $designer;
      }
      if ($designer =~ /(,.{10,})/) {
	$excess = $1; # limit the number of characters after the comma to 10, if it's more than 10, there's another comma later in the sentence
      #  $excess =~ s/\)$//;  # part of a quick patch for isolated instances, see below
	if ($excess =~ /^,.{2,9}(,.+)/) { # if there's 9 or fewer characters after the first comma and then there's one more comma, chances are
	  $excess = $1;                   # the first part is a legitimate part of the designer's name, for example Robert Trent Jones, Jr
	}
      #  $designer =~ s/\)$//; # a quick patch...further code needs to be written that will take care of other stray parenteses marks that aren't matched by their opposite
	$designer =~ s/$excess//;
        if (length ($designer) < 2) {
	  undef $designer;
        }
      }
      $designer =~ s/'/''/g;
    }
    if ($line =~ / on (.+) grass\./) {
      $grass = $1;
      $lengthOfGrass = length ($grass);
      if ($grass eq "?" or $grass eq "Other" or $lengthOfGrass > 9) {
	undef $grass;
      }
    }
    if ($line =~ /opened in (\d{4})\./) {
      $yrbuilt = $1;
    }
    elsif ($line =~ /<div id="tab_course_staff/) {
      $line = <RESULTS>;
      if ($line =~ /<br\/>.+<br\/>/) {
	@staff = split ('<br/>', $line);
	foreach $staffmember (@staff) {
	  &get_staff;
	}
      }
      else {
       if ($line =~ />(.+), .*General Manager(<*?)/ or $line =~ /\s+(.+), .*General Manager(<*?)/) {
	$genmanager = $1;
        $genmanager =~ s/'/''/g;
       }
       if ($line =~ />(.+), .*Superintendent(<*?)/ or $line =~ /\s+(.+), .*Superintendent(<*?)/) {
	$super = $1;
        $super =~ s/'/''/g;
       }
       if ($line =~ />(.+), .*Owner(<*?)/ or $line =~ /\s+(.+), .*Owner(<*?)/) {
	$owner = $1;
        $owner =~ s/'/''/g;
       }
       if ($line =~ />(.+), .*Golf Professional(<*?)/ or $line =~ /\s+(.+), .*Golf Professional(<*?)/) {
	$pro = $1;
        $pro =~ s/'/''/g;
       }
       if ($line =~ />(.+), .*Director of Golf(<*?)/ or $line =~ /\s+(.+), .*Director of Golf(<*?)/) {
	$dirgolf = $1;
        $dirgolf =~ s/'/''/g;
       }
      }
    }
  }
  &add_to_db;
}

sub get_staff {
  if ($staffmember =~ /\s*(.+), .*General Manager/) {
    $genmanager = $1;
    $genmanager =~ s/'/''/g;
  }
  if ($staffmember =~ /\s*(.+), .*Superintendent/) {
    $super = $1;
    $super =~ s/'/''/g;
  }
  if ($staffmember =~ /\s*(.+), .*Owner/) {
    $owner = $1;
    $owner =~ s/'/''/g;
  }
  if ($staffmember =~ /\s*(.+), .*Golf Professional/) {
    $pro = $1;
    $pro =~ s/'/''/g;
  }
  if ($staffmember =~ /\s*(.+), .*Director of Golf/) {
    $dirgolf = $1;
    $dirgolf =~ s/'/''/g;
  }
}

sub add_to_db {
  $stmt = "UPDATE Main Set Rating='$rating', Slope='$slope', Built='$yrbuilt', Grass='$grass', Designer='$designer', Pro='$pro', Super='$super', Manager='$genmanager', Owner='$owner', DirGolf='$dirgolf'  WHERE ID=$id";
  $rc = $db1->Sql($stmt);
  die "SQL failed \"$stmt\": $db1->Error()\n" if $rc;
  undef $rating; undef $slope; undef $genmanager; undef $super; undef $owner; undef $yrbuilt; undef $grass; undef $designer; undef $pro; undef $super; undef $genmanager; undef $owner; undef $dirgolf;
}
