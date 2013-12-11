# perl script to import from soucesforge into mantis

use strict;
use warnings;

use open ':std', ':encoding(UTF-8)';

use XML::Simple;

use Data::Dumper;

use File::Slurp;

use Text::CSV;


# Turn off output buffering
$|=1;

sub output_reporter
{
    my ($reporter, @users) = @_;

#print Dumper(@users);

    if (defined($reporter)) {

	foreach my $user(@users) {
	    if ($user->[2] eq $reporter) {
		print "<reporter id=\"" . $user->[0] . "\">" . $user->[1] . "</reporter>\n";
		return;
	    }
	}
    }
    print "<reporter id=\"7\">import</reporter>\n";
}

sub main
{
    my @users;
    my $csv = Text::CSV->new ( { binary => 1 } ) # should set binary attribute.
	or die "Cannot use CSV: ".Text::CSV->error_diag ();

    open my $fh, "<:encoding(utf8)", "usermap.csv" or die "usermap.csv: $!";
    while ( my $user = $csv->getline( $fh ) ) {
	push @users, $user;
    }
    $csv->eof or $csv->error_diag();
    close $fh;

    $csv->eol ("\r\n");

#print Dumper(@users);

    my $data = read_file("netsurf-project-export.xml");

    my $parser = new XML::Simple;
 
    my $dom = $parser->XMLin($data);

# Debug output.
#print Dumper($dom);

    my @artifacts = @{$dom->{'artifacts'}->{'artifact'} } ;

    my $hdr = <<END;
<?xml version="1.0" encoding="UTF-8"?>
<mantis version="1.2.15" urlbase="http://bugs.netsurf-browser.org/mantis/" issuelink="#" notelink="~" format="1">
END
print $hdr;


    foreach my $artifact(@artifacts) {

	#print Dumper($artifact);
	my $fields = $artifact->{'field'};

#print Dumper($fields);

	print "<issue>\n";
	print "<id>" . $fields->{'artifact_id'}->{'content'} . "</id>\n";

        print "<project id=\"1\">NetSurf</project>\n";

	output_reporter( $fields->{'submitted_by'}->{'content'}, @users);

        print "<handler id=\"0\"></handler>\n";

        print "<priority id=\"30\">normal</priority>\n";

	if ($fields->{'artifact_type'}->{'content'} eq "Feature Requests") {
	    print "<severity id=\"10\">feature</severity>\n";
	} else {
	    print "<severity id=\"50\">minor</severity>\n";
	}

        print "<reproducibility id=\"70\">have not tried</reproducibility>\n";

	if ($fields->{'status'}->{'content'} eq "Open") {
	    print "<status id=\"10\">new</status>\n";
	} else {
	    print "<status id=\"90\">closed</status>\n";
	}

	if ($fields->{'resolution'}->{'content'} eq "Fixed") {
	    print "<resolution id=\"20\">fixed</resolution>\n";
	} elsif ($fields->{'resolution'}->{'content'} eq "Wont Fix") {
	    print "<resolution id=\"90\">wont fix</resolution>\n";
	} elsif ($fields->{'resolution'}->{'content'} eq "Works For Me") {
	    print "<resolution id=\"40\">unable to reproduce</resolution>\n";
	} else {
	    print "<resolution id=\"10\">open</resolution>\n";
	}

        print "<projection id=\"10\">none</projection>\n";

        print "<category id=\"1\">General</category>\n";

	print "<date_submitted>" . $fields->{'open_date'}->{'content'} . "</date_submitted>\n";

	if (ref $fields->{'artifact_history'} eq ref {}) {

	    if (ref $fields->{'artifact_history'}->{'history'} eq ref {}) {
		print "<last_updated>" . $fields->{'artifact_history'}->{'history'}->{'field'}->{'entrydate'}->{'content'} . "</last_updated>\n";
	    } else {
		print "<last_updated>" . $fields->{'artifact_history'}->{'history'}->[0]->{'field'}->{'entrydate'}->{'content'} . "</last_updated>\n";
	    }
	} else {
	    print "<last_updated>" . $fields->{'open_date'}->{'content'} . "</last_updated>\n";
	}

        print "<eta id=\"10\">none</eta>\n";

        print "<view_state id=\"10\">public</view_state>\n";

	print "<summary>" . $fields->{'summary'}->{'content'} . "</summary>\n";

        print "<due_date>1</due_date>\n";

	if (defined($fields->{'details'}->{'content'})) {
	    print "<description>" . $fields->{'details'}->{'content'} . "</description>\n";
	} else {
	    print "<description></description>\n";
	}

        print "<steps_to_reproduce></steps_to_reproduce>\n";

	if (ref $fields->{'artifact_messages'} eq ref {}) {
	    if (ref $fields->{'artifact_messages'}->{'message'} eq ref {}) {
#print Dumper($fields->{'artifact_messages'}->{'message'});

		print "<additional_information>";

		if ($fields->{'artifact_messages'}->{'message'}->{'field'}->{'user_name'}->{'content'} ne "nobody" ) {
		    print "Note added by " . $fields->{'artifact_messages'}->{'message'}->{'field'}->{'user_name'}->{'content'} . "\n\n";
		}

		print $fields->{'artifact_messages'}->{'message'}->{'field'}->{'body'}->{'content'} . "</additional_information>\n";
	    } else {
		print "<additional_information>";
		my @msgs = @{$fields->{'artifact_messages'}->{'message'}};


		foreach my $msg(@msgs) {
#print Dumper($msg);

		    print "Note added by " . $msg->{'field'}->{'user_name'}->{'content'} . "\n\n" .$msg->{'field'}->{'body'}->{'content'} ."\n\n";
		}
		print "</additional_information>\n";
	    }
	} else {
	    print "<additional_information></additional_information>\n";
	}

	print "</issue>\n";

	

    }

    print "</mantis>\n";

}

main();



