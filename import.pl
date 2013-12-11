# perl script to import from soucesforge into mantis

use strict;
use warnings;

use Data::Dumper;

use File::Slurp;

use Text::CSV;

use XML::LibXML;

use Text::Trim;


sub map_reporter
{
    my ($mantis, $reporter, @users) = @_;

    my $mnts_reporter = $mantis->createElement('reporter');

#print Dumper(@users);

    if (defined($reporter)) {

	foreach my $user(@users) {
	    if ($user->[2] eq $reporter) {

		$mnts_reporter->appendTextNode($user->[1]);
		$mnts_reporter->setAttribute("id", $user->[0]);

		return $mnts_reporter;

	    }
	}
    }
    $mnts_reporter->appendTextNode('import');
    $mnts_reporter->setAttribute("id", "7");

    return $mnts_reporter;
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

    # load
    open $fh, '<', 'netsurf-project-export.xml';
    binmode $fh; # drop all PerlIO layers possibly created by a use open pragma
    my $dom = XML::LibXML->load_xml(IO => $fh);


    # setup mantis document and root node
    my $mantis = XML::LibXML::Document->createDocument( "1.0", "UTF-8" );
    my $root = $mantis->createElement( "mantis" );
    $mantis->setDocumentElement( $root );
    $root->setAttribute("version", "1.2.15");
    $root->setAttribute("urlbase", "http://bugs.netsurf-browser.org/mantis/");
    $root->setAttribute("issuelink", "#");
    $root->setAttribute("notelink", "~");
    $root->setAttribute("format", "1");

    my $bcount=380;

    foreach my $artifact ($dom->findnodes('/project_export/artifacts/artifact')) {
	$bcount = $bcount + 1;

	my $issue = XML::LibXML::Element->new( "issue" );

	# id people
	my $sf_id = $artifact->findnodes('./field[@name="artifact_id"]/text()');
	$issue->appendTextChild('id', $sf_id);

	# project stanza
	my $mnts_project = $mantis->createElement('project');
	$mnts_project->appendTextNode('NetSurf');
	$mnts_project->setAttribute("id", "1");
	$issue->appendChild($mnts_project);

	# reporter
	my $sf_submitter = $artifact->findnodes('./field[@name="submitted_by"]/text()');
	my $mnts_reporter = map_reporter($mantis, $sf_submitter, @users);
	$issue->appendChild($mnts_reporter);

	# handler stanza
	my $mnts_handler = $mantis->createElement('handler');
	$mnts_handler->appendTextNode('import');
	$mnts_handler->setAttribute("id", "7");
	$issue->appendChild($mnts_handler);

	# priority stanza
	my $mnts_priority = $mantis->createElement('priority');
	$mnts_priority->appendTextNode('normal');
	$mnts_priority->setAttribute("id", "30");
	$issue->appendChild($mnts_priority);

	# severity
	my $mnts_severity = $mantis->createElement('severity');
	my $sf_type = $artifact->findnodes('./field[@name="artifact_type"]/text()');
	if (defined($sf_type) && $sf_type eq "Feature Requests") {
	    $mnts_severity->appendTextNode('feature');
	    $mnts_severity->setAttribute("id", "10");
	} else {
	    $mnts_severity->appendTextNode('minor');
	    $mnts_severity->setAttribute("id", "50");
	}
	$issue->appendChild($mnts_severity);

	# reproducibility
	my $mnts_reproducibility = $mantis->createElement('reproducibility');
	$mnts_reproducibility->appendTextNode('have not tried');
	$mnts_reproducibility->setAttribute("id", "70");
	$issue->appendChild($mnts_reproducibility);

	# status
	my $mnts_status = $mantis->createElement('status');
	my $sf_status = $artifact->findnodes('./field[@name="status"]/text()');
	if (defined($sf_status) && $sf_status eq "Open") {
	    $mnts_status->appendTextNode('new');
	    $mnts_status->setAttribute("id", "10");
	} else {
	    $mnts_status->appendTextNode('closed');
	    $mnts_status->setAttribute("id", "90");
	}
	$issue->appendChild($mnts_status);

	# resolution
	my $mnts_resolution = $mantis->createElement('resolution');
	my $sf_resolution = $artifact->findnodes('./field[@name="resolution"]/text()');
	if (defined($sf_resolution) && $sf_resolution eq "Fixed") {
	    $mnts_resolution->appendTextNode('fixed');
	    $mnts_resolution->setAttribute("id", "20");
	} elsif (defined($sf_resolution) && $sf_resolution eq "Wont Fix") {
	    $mnts_resolution->appendTextNode('wont fix');
	    $mnts_resolution->setAttribute("id", "90");
	} elsif (defined($sf_resolution) && $sf_resolution eq "Works For Me") {
	    $mnts_resolution->appendTextNode('unable to reproduce');
	    $mnts_resolution->setAttribute("id", "40");

	    $mnts_reproducibility->appendTextNode('unable to reproduce');
	    $mnts_reproducibility->setAttribute("id", "90");

	} elsif (defined($sf_resolution) && (($sf_resolution eq "Invalid") || ($sf_resolution eq "Out of Date") || ($sf_resolution eq "Rejected"))) {
	    $mnts_resolution->appendTextNode('not fixable');
	    $mnts_resolution->setAttribute("id", "50");
	} elsif (defined($sf_resolution) && $sf_resolution eq "Duplicate") {
	    $mnts_resolution->appendTextNode('duplicate');
	    $mnts_resolution->setAttribute("id", "60");
	} elsif (defined($sf_resolution) && $sf_resolution eq "None") {
	    $mnts_resolution->appendTextNode('no change needed');
	    $mnts_resolution->setAttribute("id", "70");
	} else {
	    $mnts_resolution->appendTextNode('open');
	    $mnts_resolution->setAttribute("id", "10");
	}
	$issue->appendChild($mnts_resolution);


	# projection
	my $mnts_projection = $mantis->createElement('projection');
	$mnts_projection->appendTextNode('none');
	$mnts_projection->setAttribute("id", "10");
	$issue->appendChild($mnts_projection);

	# category
	my $mnts_category = $mantis->createElement('category');
	$mnts_category->appendTextNode('General');
	$mnts_category->setAttribute("id", "1");
	$issue->appendChild($mnts_category);

	# submission date
	my $sf_opendate = $artifact->findnodes('./field[@name="open_date"]/text()');
	$issue->appendTextChild('date_submitted', $sf_opendate);

	# last update 
	my $mnts_last_updated = $mantis->createElement('last_updated');
	my $sf_last_updated = $artifact->findnodes('./field[@name="artifact_history"]/history[1]/field[@name="entrydate"]/text()');
	if (defined($sf_last_updated) && $sf_last_updated ne "") {
	    $mnts_last_updated->appendTextNode($sf_last_updated);
	} else {
	    $mnts_last_updated->appendTextNode($sf_opendate);
	}
	$issue->appendChild($mnts_last_updated);

#hack to create db update text because the bug dates get fucked ove rin the import
#	print "update mantis_bug_table set date_submitted='" . $sf_opendate . "', last_updated='" . $mnts_last_updated->textContent() . "' WHERE id=" . $bcount . ";\n";
	# eta
	my $mnts_eta = $mantis->createElement('eta');
	$mnts_eta->appendTextNode('none');
	$mnts_eta->setAttribute("id", "10");
	$issue->appendChild($mnts_eta);

	# view state
	my $mnts_viewstate = $mantis->createElement('view_state');
	$mnts_viewstate->appendTextNode('public');
	$mnts_viewstate->setAttribute("id", "10");
	$issue->appendChild($mnts_viewstate);

	# summary
	my $sf_summary = $artifact->findnodes('./field[@name="summary"]/text()');
	$issue->appendTextChild('summary', $sf_summary);

	# due date
	my $mnts_duedate = $mantis->createElement('due_date');
	$mnts_duedate->appendTextNode('1');
	$issue->appendChild($mnts_duedate);

	# description
	my $sf_description = $artifact->findnodes('./field[@name="details"]/text()');
	if (defined($sf_description) && trim($sf_description) ne "") {
	    $issue->appendTextChild('description', $sf_description);
	} else {
	    $issue->appendTextChild('description', $sf_summary);
	}


	# additional information

	# would have liked to do this as bugnotes but teh xml importer
	# in current mantis doesnt allow that

	my $mnts_additional_information = $mantis->createElement('additional_information');
	foreach my $sf_message ($artifact->findnodes('./field[@name="artifact_messages"]/message')) {

	    my $sf_adddate = $sf_message->findnodes('./field[@name="adddate"]/text()');
	    my $sf_user_name = $sf_message->findnodes('./field[@name="user_name"]/text()');
	    my $sf_body = $sf_message->findnodes('./field[@name="body"]/text()');

	    my $note_time = localtime($sf_adddate);


	    $mnts_additional_information->appendTextNode($sf_user_name . " added a note on " . $note_time . "\n\n" . $sf_body . "\n\n");
	     
	}

	$mnts_additional_information->appendTextNode("Imported from sourceforge bug #" . $sf_id . " on " . localtime() . "\n\n");

	$issue->appendChild($mnts_additional_information);


	$root->addChild($issue);
    }

    # save
    $mantis->toFile('sf2mantis.xml', '1');

}

main();



