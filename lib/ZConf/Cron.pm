package ZConf::Cron;

use ZConf;
use warnings;
use strict;

=head1 NAME

ZConf::Cron - Handles storing cron tabs in ZConf.

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

    use ZConf::Cron;

    my $zccron = ZConf::Cron->new();
    ...

=head1 FUNCTIONS

=head2 new

Initiates the module. No arguements are currently taken.

=cut

sub new{
	my $self={error=>undef, set=>undef};
	bless $self;

	$self->{zconf}=ZConf->new();
	if(defined($self->{zconf}->{error})){
		warn("ZConf-Cron new:1: Could not initiate ZConf. It failed with '"
			 .$self->{zconf}->{error}."', '".$self->{zconf}->{errorString}."'");
		$self->{error}=1;
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

	$self->errorblank;

	#checks if it exists
	my $configExists = $self->{zconf}->configExists("zccron");

	#creates the config if needed
	if (!$configExists){
		if ($self->{zconf}->createConfig('zccron')){
			warn('ZConf-Cron create:8: Failed to create the ZConf config "zccron"');
			$self->{error}=8;
			return undef;
		}
	}

	my $returned=$self->{zconf}->writeSetFromHash({config=>"zccron", set=>$set},{});
	if ($self->{zconf}->{error}){
		warn('ZConf-Cron create:9: Failed to create set. set="'.$set.'" error="'.
			 $self->{zconf}->{error}.'"');
		$self->{error}=9;
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

	$self->errorblank();

	my $returned=$self->{zconf}->delSet("zccron",$set);
	if (defined($self->{zconf}->{error})){
		warn('ZConf-Cron delSet:10: Failed to delete set. set="'.$set.'" error="'.
			 $self->{zconf}->{error}.'"');
		$self->{error}=10;
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

	$self->errorblank();

	$self->{zconf}->regexVarDel("zccron", '^tabs/'.$tab.'$');
	if (defined($self->{zconf}->{error})) {
		warn('ZConf-Cron delTab:11: Failed to delete tab, "'.$tab.'", for the set, "'.
			 $self->{zconf}->{set}{zccron}.'". error="'.$self->{zconf}->{error}.'"');
		$self->{error}=11;
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

	$self->errorblank();

	my @sets=$self->{zconf}->getAvailableSets("zccron");
	if ($self->{zconf}->{error}){
		warn('ZConf-Cron getSets:4: Failed with a error of"'.
			 $self->{zconf}->{error}.'"');
		$self->{error}=4;
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

	$self->errorblank();

	if (!defined($set)){
		my $set=$self->{zconf}->chooseSet("zccron");
	}

	if(!$self->{zconf}->setNameLegit($set)){
		warn("ZConf-Cron setSet:2: '".$set."' is not a legit ZConf set name");
		$self->{error}=2;
		return undef;
	}

	$self->{zconf}->read({config=>"zccron", set=>$set});
	if($self->{zconf}->{error}){
		warn("ZConf-Cron setSets:3: Could not read config, set '".$set."'. It failed with '"
			 .$self->{zconf}->{error}."', '".$self->{zconf}->{errorString}."'.");
		$self->{error}=3;
		return undef;
	}

	my @sets=$self->{zconf}->getAvailableSets("zccron");
	if ($self->{zconf}->{error}){
		warn('ZConf-Cron getSets:4: Failed with a error of"'.
			 $self->{zconf}->{error}.'"');
		$self->{error}=4;
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

	$self->errorblank();

	my @matched = $self->{zconf}->regexVarSearch("zccron", "^tabs/");

	my $matchedInt=0;
	while (defined($matched[$matchedInt])){
		$matched[$matchedInt]=~s/^tabs\///;
		$matchedInt++;
	}

	return @matched;
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

	$self->errorblank();

	$tab='tabs/'.$tab;

	#errors if the tab is not defined
	if (!defined($self->{zconf}->{conf}{zccron}{$tab})){
		warn('ZConf-Cron readTab:5: The tab "'.$tab.'" is not defined');
		$self->{error}=5;
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

	$self->errorblank();

	#tries to save it and error upon failure
	if (!$self->{zconf}->writeSetFromLoadedConfig("zccron")){
		warn('ZConf-Cron save:7: Save failed with "'
			 .$self->{zconf}->{error}.'"');
		$self->{error}=7;
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

	$self->errorblank;

	if (!defined($value)){
		warn("ZConf-Cron writeTab: No value specified for the value of the tab.");
		$self->{error}=6;
		return undef;
	}

	if($self->{zconf}->varNameCheck($tab)){
		warn("ZConf-Cron writeTab:2: '".$tab."' is not a legit ZConf variable name");
		$self->{error}=2;
		return undef;
	}

	$self->{zconf}->{conf}{zccron}{$tab}=$value;

	$self->{zconf}->writeSetFromLoadedConfig({config=>'zccron'});
	if ($self->{zconf}->{error}){
		warn('ZConf-Cron writeTab:10: Could not write ZConf config "zccron". It errored with "'.
			 $self->{zconf}->{error}.'"');
	}

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

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::Cron
