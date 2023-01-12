#populate the golf course database with name of course, address, city, state/zip, and phone,
#and other important stuff
#for next time, be sure and keep track of the closed courses
use Win32::ODBC;
use WWW::Mechanize;
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
# 'AL', 'AK', 'AR', 'AZ', 'CA', 'CO', 'CT', 'DC', 'DE', 'FL', 'GA', 'HI', 'IA', 'ID', 'IL', 'IN', 'KS', 'KY', 'LA', 'MA', 'MD', 'ME', 'MI', 'MN', 'MO', 'MS', 'MT', 'NC', 'ND', 'NE', 'NH', 'NJ', 'NM', 'NV', 'NY', 'OH', 'OK', 
@st = ('OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VA', 'VT', 'WA', 'WI', 'WV', 'WY');
# @alpha = ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z');
open (ERRORFILE, ">>../golflinkErrors.txt") or die "can't open error file\n";
foreach $state(@st) {
#  next if ($state ne "DC");
  &findState;
  $url = "https://www.golflink.com/golf-courses/$st/";
  &send;
}
close ERRORFILE;


sub send {
    $success = 0; $conn_tries = 0;
    while ($success == 0) {
        my $req = new HTTP::Request 'GET' => $url;
        $req->header('Accept' => 'text/html');
        my $res = $ua->request($req, "results/$st");
        $resp = $res->as_string();
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

sub send_for_city {	
    $success = 0; $conn_tries = 0;
    while ($success == 0) {
        my $req = new HTTP::Request 'GET' => $next_url;
        $req->header('Accept' => 'text/html');
	$resultsCityFile = $st . "-" . $city;
        my $res = $ua->request($req, "results/$resultsCityFile");
        $resp = $res->as_string();
        if (!$res->is_success) {
           $conn_tries++;
           die "Connection failure\n" if ($conn_tries == 5);
        }
        else { 
           $success = 1; 
           &processCity; 
        }
   }
}

sub send_for_course {	
  $success = 0; $conn_tries = 0;
  while ($success == 0) {
    my $req = new HTTP::Request 'GET' => $course_url;
    $req->header('Accept' => 'text/html');
    $resultsCourseFile = $st . "-" . $city . "-" . $course;
    my $res = $ua->request($req, "results/$resultsCourseFile");
    $resp = $res->as_string();
    if (!$res->is_success) {
      $conn_tries++;
      die "Connection failure\n" if ($conn_tries == 5);
    }
    else { 
      $success = 1; 
      &processCourse;
    }
  }
}

sub process {
  open (RESULTS, "results/$st") or die "can't open state results file\n";
  &get_cityURL;
  close RESULTS;
}

sub processCity {
  open (RESULTSCITY, "results/$resultsCityFile") or die "can't open city results file\n";
a:  while ($line2 = <RESULTSCITY>) {
    if ($line2 =~ /<h3><a class="fly" href="(.+?)">(.+),/) {
      $course_url = $1;
      $courseName = $2;
next if ($state eq "OK" && $course_url =~ /golf-club-at-surrey-hills/);
      $course_url = "https://www.golflink.com" . $course_url;
      if ($course_url =~ /\/golf-courses\/$st\/$city\/(.+)/) {
        $course = $1;
      }
      else { # else it's a different city (or even state) and we only want the courses in a certain city
        last;
      }
      &send_for_course;
    }
  }
  close RESULTSCITY;
}

sub processCourse {
  open (RESULTSCOURSE, "results/$resultsCourseFile") or die "can't open course results file\n";
  while ($line3 = <RESULTSCOURSE>) {
    if ($line3 =~ /<title>$/) {
      $line3 = <RESULTSCOURSE>;
      if ($line3 =~ /\t(.+) \((.+)\)/) {
        $facil = $1;
        $course = $2;
        if ($facil ne $courseName) {
          print ERRORFILE "$state, $city, $facil, $line3\n\n";
          print "SOMETHING WRONG WITH COURSE FILE, LINE IS $line3\n\n";
          next a;
        }
      }
      else {
        print ERRORFILE "$state, $city, $facil, $line3\n\n";
        print "SOMETHING WRONG WITH COURSE FILE, LINE IS $line3\n\n";
        next a;
      }
    }
    elsif ($line3 =~ /<meta name="State" content="$state"/) {
      $stateVerified = 1;
      if ($line3 =~ /<meta name="Address" content="(.*?)"/) {
        $addr = $1;
      }
      if ($line3 =~ /<meta name="City" content="(.+?)"/) {
        $capturedCity = $1;
        $lcCapturedCity = lc $capturedCity;
        $lcCapturedCity =~ s/ /-/g;
        if ($city ne $lcCapturedCity) {
          print ERRORFILE "something wrong with city, $city, $lcCapturedCity\n\n";
          print  "SOMETHING WRONG WITH CITY, $city, $lcCapturedCity\n";
          next a;
        }
      }
      if ($line3 =~ /<meta name="Phone" content="(.*?)"/) {
        $phone = $1;
        $phone =~ s/\(//;
        $phone =~ s/\) /-/;
      }
      if ($line3 =~ /<meta name="Zip" content="(\d{5})/) {
        $zip = $1;
      }
      if ($line3 =~ /<meta name="NumHoles" content="(\d*)"/) {
        $holes = $1;
      }
      if ($line3 =~ /<meta name="Yardage" content="(.*?)"/) {
        $yards = $1;
        $yards =~ s/,//;
      }
      if ($line3 =~ /<meta name="Par" content="(\d*)"/) {
        $par = $1;
      }
      if ($line3 =~ /<meta name="AccessType" content="(.*?)"/) {
        $type = $1;
      }
    }
    elsif ($line3 =~ /<meta property='og:url'.+course=(\d+)'/) {
      $id = $1;
    }
    elsif ($line3 =~ /<meta property='og:description'/) {
      if ($line3 =~ /The course rating is (\S+) and it has a slope rating of (\d+)/) {
        $rating = $1;
        $slope = $2;
        undef $rating if ($rating == 0.0);
        undef $slope if ($slope == 0);
      }
      if ($line3 =~ /.+ on (.+?) grass\./) {
        $grass = $1;
      }
      if ($line3 =~ /Designed by (.+), the /) {
        $designer = $1;
        $designer =~ s/\((.+?)\)//g;
        $designer =~ s/\//; /g;
        $designer =~ s/'/''/g;
        if (length ($designer) < 2) {
          undef $designer;
        }
      }
      if ($line3 =~ /opened in (\d{4})\./) {
        $built = $1;
      }
    }
    elsif ($line3 =~ />Other golf courses at this facility/) {
      while ($line3 = <RESULTSCOURSE> =~ /<option value="(.+)">(.+)<\/option>/) {
        $golflinkURL = $1;
	$golflinkCourse = $2;
        $otherCourses .= "$golflinkCourse" . "_" . $golflinkURL . "; ";
      }
      $otherCourses =~ s/'/''/g;
      $otherCourses =~ s/; $//;
    }
    elsif ($line3 =~ /<a href="(.+?)" class="popup">/) {
      $web = $1;
    }
    elsif ($line3 =~ /<div class="tab_block" id="tab_course_details">/) {
      $line3 = <RESULTSCOURSE>; $line3 = <RESULTSCOURSE>;
      if ($line3 =~ /<p>\d+ tees driving range<\/p><p>\d+ (.+) holes<\/p>/) {
        $drivingRange = "yes";
        $style = $1;
        $style =~ s/holes//g;
        $style =~ s/\|/\//g;
        if ($holes >= 18 && $yards >= 7000) {
          $style = "championship";
        }
      }
      elsif ($line3 =~ /<p>\d+ (.+) holes<\/p>/) {
        $style = $1;
        $style =~ s/holes//g;
        $style =~ s/\|/\//g;
        if ($holes >= 18 && $yards >= 7000) {
          $style = "championship";
        }
      }
    }
    elsif ($line3 =~ /<h3>Course Staff<\/h3>/) {
      $line3 = <RESULTSCOURSE>;
      if ($line3 =~ /<br\/>/) {
	@staff = split (/<br\/>/, $line3);
	foreach $staffmember (@staff) {
          chomp $staffmember;
	  &get_staff if ($staffmember);
	}
      }
    }
  }
  print "$id, $facil, $course, $addr, $capturedCity, $state, $zip, $phone, $holes, $yards, $par, $type, $rating, $slope, $grass, $web, $built, $designer, $drivingRange, $style, $genmanager, $super, $owner, $pro, $dirgolf, $president, $otherCourses\n\n";
  if (!$stateVerified) {
    print "State not verified, $state\n";
    print ERRORFILE "wrong state, $id, $facil, something other than $state\n\n";
    next a;
  }
  &add_to_db;
}

sub get_cityURL {
  while ($line = <RESULTS>) {
    if ($line =~ /^<li><a href=(\/golf-courses\/$st\/.+?\/)>/) {
      $next_url = $1;
      if ($next_url =~ /\/golf-courses\/$st\/(.+?)\//) {
        $city = $1;
#next if ($st eq "ok" && $city lt "yukon");
      }
      $next_url = "http://www.golflink.com" . $next_url;
      &send_for_city;
    }
  }
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
  if ($staffmember =~ /\s*(.+), .*President/) {
    $president = $1;
    $president =~ s/'/''/g;
  }
}

sub findState {
  open (STATES, "states") or die "can't open states file\n";
  $st = lc ($state);
  while ($line = <STATES>) {
    if ($line =~ /$st-(.+)$/) {
      $statefullname = $1;
      if ($statefullname eq "DC") {
	$statefullname = "District of Columbia";
      }
      last;
    }
  }
  close STATES;
}

sub add_to_db {
  $facil =~ s/\&amp\;/\&/g;
  $facil =~ s/'/''/g;
  $course =~ s/\&amp\;/\&/g;
  $course =~ s/'/''/g;
  $stmt = "INSERT INTO Main (ID, Facility, Course, Addr, City, St, Zip, Phone, Holes, Yards, Par, Type, Rating, Slope, Built, Grass, Web, Designer, Pro, Super, Manager, Owner, DirGolf, DrivingRange, President, Style, OtherCourses) VALUES ($id, '$facil', '$course', '$addr', '$capturedCity', '$state', '$zip', '$phone', '$holes', '$yards', '$par', '$type', '$rating', '$slope', '$built', '$grass', '$web', '$designer', '$pro', '$super', '$genmanager', '$owner', '$dirgolf', '$drivingRange', '$president', '$style', '$otherCourses')";
  $rc = $db->Sql($stmt);
  die "SQL failed \"$stmt\": $db->Error()\n" if $rc;
  &undefValues;
}

sub undefValues {
  undef $id; undef $facil; undef $course; undef $addr; undef $zip; undef $phone; undef $holes;
  undef $yards; undef $par; undef $type; undef $stateVerified; undef $capturedCity; undef $lcCapturedCity;
  undef $designer; undef $rating; undef $slope; undef $grass; undef $web; undef $built; undef @staff;
  undef $genmanager; undef $super; undef $owner; undef $pro; undef $dirgolf; undef $president; 
  undef $drivingRange; undef $style; undef $golflinkURL; undef $golflinkCourse; undef $otherCourses;
}
