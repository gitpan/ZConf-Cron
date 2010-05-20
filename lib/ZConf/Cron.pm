package ZConf::Cron;

use ZConf;
use warnings;
use strict;

=head1 NAME

ZConf::Cron - Handles storing cron tabs in ZConf.

=head1 VERSION

Version 1.1.0

=cut

our $VERSION = '1.1.0';

=head1 SYNOPSIS

    use ZConf::Cron;

    my $zccron = ZConf::Cron->new();
    ...

=head1 FUNCTIONS

=head2 new

Initiates the module. No arguements are currently taken.

=cut

sub new{
	my $self={error=>undef,
			  set=>undef,
			  perror=>undef,
			  errorString=>'',
			  zconfconfig=>'zccron',
			  module=>'ZConf-Cron'};
	bless $self;
	my $function='function';

	$self->{zconf}=ZConf->new();
	if(defined($self->{zconf}->{error})){
		$self->{error}=1;
		$self->{perror}=1;
		$self->{errorString}="Could not initiate ZConf. It failed with '"
		                     .$self->{zconf}->{error}."', '".$self->{zconf}->{errorString}."'";
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#sets $self->{init} to a Perl boolean value...
	#true=config does exist
	#false=config does not exist
	if (!$self->{zconf}->configExists("zccron")){
		$self->{init}=undef;
	}else {
		$self->{init}=1;
	}

	#tries to load the config
	if ($self->{init}){
		$self->{zconf}->read({config=>"zccron"});
	}

	#gets what the default set is
	$self->{set}=$self->{zconf}->chooseSet("zccron");

	my @sets=$self->{zconf}->getAvailableSets("zccron");
	$self->{sets}=[@sets];

	$self->{tabs}=[$self->getTabs];

	return $self;
}

=head2 create

Used for creating a specified set, or initializing.

    $zccron->create('someSet');
    if($zccron->{error}){
        print "Error\n";
    }

=cut

sub create{
	my $self=$_[0];
	my $set=$_[1];
	my $function='create';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}


	#checks if it exists
	my $configExists = $self->{zconf}->configExists("zccron");

	#creates the config if needed
	if (!$configExists){
		if ($self->{zconf}->createConfig('zccron')){
			$self->{errorString}='Failed to create the ZConf config "zccron"';
			$self->{error}=8;
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return undef;
		}
	}

	my $returned=$self->{zconf}->writeSetFromHash({config=>"zccron", set=>$set},{});
	if ($self->{zconf}->{error}){
		$self->{errorString}='Failed to create set. set="'.$set.'" error="'.
		                     $self->{zconf}->{error}.'"';
		$self->{error}=9;
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#we call this to update the list of sets
	my @sets=$self->getSets();

	return 1;
}

=head2 delSet

This deletes a set.

    $zccron->delSet('someSet');
    if($zccron->{error}){
        print "Error\n";
    }

=cut

sub delSet{
	my $self=$_[0];
	my $set=$_[1];
	my $function='delSet';

	$self->errorblank();
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	my $returned=$self->{zconf}->delSet("zccron",$set);
	if ($self->{zconf}->{error}){
		$self->{errorString}='Failed to delete set. set="'.$set.'" error="'.
		                     $self->{zconf}->{error}.'"';
		$self->{error}=10;
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#we call this to update the list of sets
	my @sets=$self->getSets();
	
	return 1;
}

=head2 delTab

This removes a tab.

    $zccron->delTab('someTab');
    if($zccron->{error}){
        print "Error\n";
    }

=cut

sub delTab{
	my $self=$_[0];
	my $tab=$_[1];
	my $function='delTab';

	$self->errorblank();
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	$self->{zconf}->regexVarDel("zccron", '^tabs/'.$tab.'$');
	if ($self->{zconf}->{error}) {
		$self->{errorString}='Failed to delete tab, "'.$tab.'", for the set, "'.
			                 $self->{zconf}->{set}{zccron}.'". error="'.$self->{zconf}->{error}.'"';
		$self->{error}=11;
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return 1;
}

=head2 getSets

This gets a list of of sets for the config 'cron'.

    my @sets=$zccron->getSets();
    if($zccron->{error}){
        print "Error\n";
    }

=cut

sub getSets{
	my $self=$_[0];
	my $function='getSets';

	$self->errorblank();
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	my @sets=$self->{zconf}->getAvailableSets("zccron");
	if ($self->{zconf}->{error}){
		$self->{errorString}='Failed with a error of"'.$self->{zconf}->{error}.'"';
		$self->{error}=4;
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	};

	$self->{sets}=[@sets];

	return @sets;
}

=head2 setSet

Sets what set is being worked on. It will also read it when this is called.

    $zccron->setSet('someSet');
    if($zccron->{error}){
        print "Error\n";
    }

=cut

sub setSet{
	my $self=$_[0];
	my $set=$_[1];
	my $function='setSet';

	$self->errorblank();
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	if (!defined($set)){
		my $set=$self->{zconf}->chooseSet("zccron");
	}

	if(!$self->{zconf}->setNameLegit($set)){
		$self->{errorString}="'".$set."' is not a legit ZConf set name";
		$self->{error}=2;
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	$self->{zconf}->read({config=>"zccron", set=>$set});
	if($self->{zconf}->{error}){
		$self->{errorString}="Could not read config, set '".$set."'. It failed with '"
			                 .$self->{zconf}->{error}."', '".$self->{zconf}->{errorString}."'.";
		$self->{error}=3;
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	my @sets=$self->{zconf}->getAvailableSets("zccron");
	if ($self->{zconf}->{error}){
		$self->{errorString}='Failed with a error of"'.$self->{zconf}->{error}.'"';
		$self->{error}=4;
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	};

	$self->{sets}=[@sets];

	$self->{tabs}=[$self->getTabs];

	$self->{set}=$set;

	$self->{tabs}=[$self->getTabs];

	return 1;
}

=head2 getTabs

Gets a list of tabs for the current set.

    my @tabs=$zccron->getTabs();
    if($zccron->{error}){
        print "Error\n";
    }

=cut

sub getTabs{
	my $self=$_[0];
	my $function='getTabs';

	$self->errorblank();
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	my @matched = $self->{zconf}->regexVarSearch("zccron", "^tabs/");

	my $matchedInt=0;
	while (defined($matched[$matchedInt])){
		$matched[$matchedInt]=~s/^tabs\///;
		$matchedInt++;
	}

	return @matched;
}

=head2 readSet

This reads the specified set or rereads the current one.

One arguement is taken is the name of the set.

    $zccron->readSet($set);
    if($zccron->{error}){
        print "Error!\n";
    }

=cut

sub readSet{
	my $self=$_[0];
	my $set=$_[1];
	my $function='readSet';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	$self->{zconf}->read({config=>'zccron', set=>$set});
	if ($self->{zconf}->{error}) {
		$self->{error}=3;
		$self->{errorString}='ZConf error reading the config "zccron".'.
		                     ' ZConf error="'.$self->{zconf}->{error}.'" '.
		                     'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return 1;
}

=head2 readTab

Gets a specified tab.

    my $tab=zccron->readTab("sometab");
    if($zccron->{error}){
        print 'error: '.$zccron->{error}."\n";
    }

=cut

sub readTab{
	my $self=$_[0];
	my $tab=$_[1];
	my $function='readTab';

	$self->errorblank();
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	$tab='tabs/'.$tab;

	#errors if the tab is not defined
	if (!defined($self->{zconf}->{conf}{zccron}{$tab})){
		$self->{errorString}='The tab "'.$tab.'" is not defined';
		$self->{error}=5;
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return $self->{zconf}->{conf}{zccron}{$tab};
}

=head2 save

This saves the currently loaded set.

    $zccron->save();
    if($zccron->{error}){
        print "Error\n";
    }

=cut

sub save{
	my $self=$_[0];
	my $function='save';

	$self->errorblank();
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	#tries to save it and error upon failure
	if (!$self->{zconf}->writeSetFromLoadedConfig("zccron")){
		$self->{errorString}='Save failed with "'.$self->{zconf}->{error}.'"';
		$self->{error}=7;
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return 1;
}

=head2 writeTab

Saves a tab. The return is a Perl boolean value.

Two values are required. The first one is the name of the tab.
The second one is the value of the tab.

    #checks it using the return
    if(!$zccron->writeTab("someTab", $tabValuexs)){
        print "it failed\n";
    }
    
    #checks it using the error interface
    $zccron->writeTab("someTab", $tabValuexs);
    if($zccron->{error}){
        print "it failed\n";
    }

=cut

sub writeTab{
	my $self=$_[0];
	my $tab=$_[1];
	my $value=$_[2];
	my $function='writeTab';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	if (!defined($value)){
		$self->{errorString}="No value specified for the value of the tab.";
		$self->{error}=6;
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	if($self->{zconf}->varNameCheck($tab)){
		$self->{errorString}="'".$tab."' is not a legit ZConf variable name";
		$self->{error}=2;
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#$self->{zconf}->{conf}{zccron}{'tabs/'.$tab}=$value;
	$tab='tabs/'.$tab;
	$self->{zconf}->setVar('zccron', $tab , $value);
	if ($self->{zconf}->{error}) {
		$self->{error}=12;
		$self->{errorString}='setVar failed. error="'.$self->{zconf}->{error}.'" errorString="'.$self->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#saves it
	$self->{zconf}->writeSetFromLoadedConfig({config=>'zccron'});
	if ($self->{zconf}->{error}){
		$self->{error}=10;
		$self->{errorString}='setVar failed. error="'.$self->{zconf}->{error}.'" errorString="'.$self->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	print "saved\n";

	return 1;
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

=cut

#blanks the error flags
sub errorblank{
	my $self=$_[0];

	if ($self->{perror}) {
		return undef;
	}

	$self->{error}=undef;
	$self->{errorString}="";
	
	return 1;
};

=head1 ZConf Keys

The keys for this are stored in the config 'zccron'.

=head2 tabs/<tab>

Any thing under tabs is considered a tab.

=head1 ERROR CODES

This is reported in '$zccron->{error}'.

=head2 1

Failed to intiate ZConf.

=head2 2

Illegal set name specified.

=head2 3

Could not read the ZConf config 'zccron'.

=head2 4

Failed to get the available sets for 'zccron'.

=head2 5

No tab specified.

=head2 6

No value for the tab specified.

=head2 8

Failed to create the ZConf config 'zccron'.

=head2 9

Failed to create set.

=head2 10

Failed to delete the set.

=head2 11

Failed to delete the tab.

=head2 12

Failed to write the tab to ZConf.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-cron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-Cron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::Cron


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-Cron>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-Cron>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-Cron>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-Cron>

=item * SVN

L<http://eesdp.org/svnweb/index.cgi/pubsvn/browse/Perl/ZConf%3A%3ACron>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::Cron
