#add the FID and AID numbers to the notes1 field in the db

#!/usr/bin/perl

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
  while ($db->FetchRow()) { # cycle through the ones already succesfully done...comment out entire while loop if 
    $id = $db->Data;        # starting from beginning
    last if ($id == 728245);
  }
  while ($db->FetchRow()) {
    $id = $db->Data;
# next if ($id ne "4323");   # uncomment if just working on a single troublesome golf course, comment out if iterating
    $results_file = "c:/thegolfcourses/work/results/results" . $id;
    $url = "http://www.golflink.com/golf-courses/golf-tee-times/teetime.aspx?course=$id";
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
      my $res = $ua->request($req, "$results_file");
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
  open (RESULTS, "$results_file") or die "can't open result file\n";
  &gather_data;
  close RESULTS;
}

sub gather_data {
  while ($line = <RESULTS>) {
    if ($line =~ /\&AID=(\d+)\&FID=(\d+)">/) {
      $aid = $1;
      $fid = $2;
    }
  }
  if ($aid && $fid) {
    &add_to_db;
  }
}

sub add_to_db {
  $stmt = "UPDATE Main Set Notes1='AID=$aid FID=$fid'  WHERE ID=$id";
  $rc = $db1->Sql($stmt);
  die "SQL failed \"$stmt\": $db1->Error()\n" if $rc;
  undef $aid; undef $fid;
}
