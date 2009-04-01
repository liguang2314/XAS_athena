package Demeter::UI::Artemis;

use Demeter qw(:plotwith=gnuplot);
use Demeter::UI::Atoms;
use vars qw($demeter);
$demeter = Demeter->new;

use Cwd;
use File::Basename;
use File::Spec;

use Wx qw(:everything);
use Wx::Event qw(EVT_MENU EVT_CLOSE EVT_TOOL_ENTER EVT_CHECKBOX EVT_BUTTON EVT_TOGGLEBUTTON);
use base 'Wx::App';

use Wx::Perl::Carp;
$SIG{__WARN__} = sub {Wx::Perl::Carp::warn($_[0])};
$SIG{__DIE__}  = sub {Wx::Perl::Carp::warn($_[0])};

sub identify_self {
  my @caller = caller;
  return dirname($caller[1]);
};
use vars qw($artemis_base $icon $nset %frames %widgets);
$nset = 0;
$artemis_base = identify_self();

my %hints = (
	     gds  => "Display the Guess/Def/Set parameters dialog",
	     plot => "Display the plotting controls dialog",
	     log  => "Display the fit log",
	     fit  => "Display the fit history dialog",
	    );

sub OnInit {
  $demeter -> mo -> ui('Wx');
  $demeter -> mo -> identity('Artemis');
  #$demeter -> plot_with($demeter->co->default(qw(feff plotwith)));

  ## -------- import all of Artemis' various parts
  foreach my $m (qw(GDS Plot History Log Data Prj)) {
    next if $INC{"Demeter/UI/Artemis/$m.pm"};
    ##print "Demeter/UI/Artemis/$m.pm\n";
    require "Demeter/UI/Artemis/$m.pm";
  };

  ## -------- create a new frame and set icon
  $frames{main} = Wx::Frame->new(undef, -1, 'Artemis: EXAFS data analysis',
				[1,1], # position -- along top of screen
				[Wx::SystemSettings::GetMetric(wxSYS_SCREEN_X), 150] # size -- entire width of screen
			       );
  my $iconfile = File::Spec->catfile(dirname($INC{'Demeter/UI/Artemis.pm'}), 'Artemis', 'icons', "artemis.png");
  $icon = Wx::Icon->new( $iconfile, wxBITMAP_TYPE_ANY );
  $frames{main} -> SetIcon($icon);

  ## -------- Set up menubar
  my $bar = Wx::MenuBar->new;
  my $file = Wx::Menu->new;
  $file->Append( wxID_EXIT, "E&xit" );

  my $help = Wx::Menu->new;
  $help->Append( wxID_ABOUT, "&About..." );

  $bar->Append( $file, "&File" );
  $bar->Append( $help, "&Help" );
  $frames{main}->SetMenuBar( $bar );

  my $hbox = Wx::BoxSizer->new( wxHORIZONTAL);

  ## -------- GDS and Plot toolbar
  my $vbox = Wx::BoxSizer->new( wxVERTICAL);
  $hbox -> Add($vbox, 0, wxALL, 5);
  my $toolbar = Wx::ToolBar->new($frames{main}, -1, wxDefaultPosition, wxDefaultSize, wxTB_VERTICAL|wxTB_HORZ_TEXT);
  $frames{main}->{gds_toggle}     = $toolbar -> AddCheckTool(-1, "Show GDS",           icon("gds"),     wxNullBitmap, q{}, $hints{gds} );
  $frames{main}->{plot_toggle}    = $toolbar -> AddCheckTool(-1, "  Show plot tools",  icon("plot"),    wxNullBitmap, q{}, $hints{plot} );
  $frames{main}->{history_toggle} = $toolbar -> AddCheckTool(-1, "  Show fit history", icon("history"), wxNullBitmap, q{}, $hints{fit} );
  $toolbar -> Realize;
  $vbox -> Add($toolbar, 0, wxALL, 0);

  ## -------- Data box
  $vbox = Wx::BoxSizer->new( wxVERTICAL);
  $hbox -> Add($vbox, 0, wxALL, 5);
  my $databox       = Wx::StaticBox->new($frames{main}, -1, 'Data sets', wxDefaultPosition, wxDefaultSize);
  my $databoxsizer  = Wx::StaticBoxSizer->new( $databox, wxVERTICAL );

  my $datalist = Wx::ScrolledWindow->new($frames{main}, -1, wxDefaultPosition, wxDefaultSize, wxVSCROLL);
  # $datalist->SetScrollbars(20, 20, 50, 50);
  my $datavbox = Wx::BoxSizer->new( wxVERTICAL );
  $datalist->SetSizer($datavbox);
  my $datatool = Wx::ToolBar->new($datalist, -1, wxDefaultPosition, wxDefaultSize, wxTB_VERTICAL|wxTB_HORZ_TEXT|wxTB_LEFT);
  $datatool -> AddTool(-1, "New data", icon("add"), wxNullBitmap, wxITEM_NORMAL, q{}, "Import a new data set" );
  $datatool -> AddSeparator;
  #   $datatool -> AddCheckTool(-1, "Show data set 1", icon("pixel"), wxNullBitmap, wxITEM_NORMAL, q{}, q{} );
  $datatool -> Realize;
  $datavbox     -> Add($datatool);
  $databoxsizer -> Add($datalist, 1, wxGROW|wxALL, 0);
  $hbox         -> Add($databoxsizer, 2, wxGROW|wxALL, 0);


  ## -------- Feff box
  $vbox = Wx::BoxSizer->new( wxVERTICAL);
  $hbox -> Add($vbox, 0, wxALL, 5);
  my $feffbox       = Wx::StaticBox->new($frames{main}, -1, 'Feff calculations', wxDefaultPosition, wxDefaultSize);
  my $feffboxsizer  = Wx::StaticBoxSizer->new( $feffbox, wxVERTICAL );

  my $fefflist = Wx::ScrolledWindow->new($frames{main}, -1, wxDefaultPosition, wxDefaultSize, wxVSCROLL);
  # $fefflist->SetScrollbars(20, 20, 50, 50);
  my $feffvbox = Wx::BoxSizer->new( wxVERTICAL);
  $fefflist->SetSizer($feffvbox);
  my $fefftool = Wx::ToolBar->new($fefflist, -1, wxDefaultPosition, wxDefaultSize, wxTB_VERTICAL|wxTB_HORZ_TEXT|wxTB_LEFT);
  $fefftool -> AddTool(-1, "New Feff calculation", icon("add"), wxNullBitmap, wxITEM_NORMAL, q{}, "Import a new Feff calculation" );
  $fefftool -> AddSeparator;
  #   $fefftool -> AddCheckTool(-1, "Show feff calc 1", icon("pixel"), wxNullBitmap, q{}, q{} );
  $fefftool -> Realize;
  $feffvbox     -> Add($fefftool);
  $feffboxsizer -> Add($fefflist, 0, wxGROW|wxALL, 0);
  $hbox         -> Add($feffboxsizer, 2, wxGROW|wxALL, 0);

  ## -------- Fit box
  $vbox = Wx::BoxSizer->new( wxVERTICAL);
  $hbox -> Add($vbox, 3, wxGROW|wxLEFT|wxRIGHT|wxTOP, 5);

  my $hname = Wx::BoxSizer->new( wxHORIZONTAL);
  $vbox -> Add($hname, 0, wxGROW|wxTOP|wxBOTTOM, 0);
  my $label = Wx::StaticText->new($frames{main}, -1, "Name");
  my $name  = Wx::TextCtrl->new($frames{main}, -1, "Fit 1");
  $hname -> Add($label,      0, wxALL, 5);
  $hname -> Add($name,       1, wxALL, 2);

  my $hfit = Wx::BoxSizer->new( wxHORIZONTAL);
  $vbox -> Add($hfit, 0, wxGROW|wxTOP|wxBOTTOM, 3);
  $label = Wx::StaticText->new($frames{main}, -1, "Fit space:");
  #my $fitspace = Wx::Choice->new($frames{main}, -1, wxDefaultPosition, wxDefaultSize, [qw(k R q)]);
  my @fitspace = (Wx::RadioButton->new($frames{main}, -1, 'k', wxDefaultPosition, wxDefaultSize, wxRB_GROUP),
		  Wx::RadioButton->new($frames{main}, -1, 'R', wxDefaultPosition, wxDefaultSize),
		  Wx::RadioButton->new($frames{main}, -1, 'q', wxDefaultPosition, wxDefaultSize),
		 );


  my $sum_button = Wx::CheckBox->new($frames{main}, -1, "Do summation");
  $hfit  -> Add($label,   0, wxALL, 3);
  map {$hfit  -> Add($_,   0, wxLEFT|wxRIGHT, 2)} @fitspace;
  $hfit  -> Add($sum_button, 1, wxLEFT|wxRIGHT, 40);
  $fitspace[1]->SetValue(1) if ($demeter->co->default("fit", "space") eq 'r');
  $fitspace[2]->SetValue(2) if ($demeter->co->default("fit", "space") eq 'q');


  my $descbox      = Wx::StaticBox->new($frames{main}, -1, 'Fit description', wxDefaultPosition, wxDefaultSize);
  my $descboxsizer = Wx::StaticBoxSizer->new( $descbox, wxVERTICAL );
  my $description  = Wx::TextCtrl->new($frames{main}, -1, q{}, wxDefaultPosition, [-1, 25], wxTE_MULTILINE);
  $descboxsizer   -> Add($description,  1, wxGROW|wxALL, 0);
  $vbox           -> Add($descboxsizer, 1, wxGROW|wxALL, 0);

  $vbox = Wx::BoxSizer->new( wxVERTICAL);
  $hbox -> Add($vbox, 0, wxGROW|wxALL, 0);

  $frames{main}->{fitbutton}  = Wx::Button->new($frames{main}, -1, "Fit", wxDefaultPosition, wxDefaultSize);
  $frames{main}->{fitbutton} -> SetForegroundColour(Wx::Colour->new("#000000"));
  $frames{main}->{fitbutton} -> SetBackgroundColour(Wx::Colour->new($demeter->co->default("happiness", "average_color")));
  $frames{main}->{fitbutton} -> SetFont(Wx::Font->new( 10, wxDEFAULT, wxNORMAL, wxBOLD, 0, "" ) );
  $vbox->Add($frames{main}->{fitbutton}, 1, wxGROW|wxALL, 2);

  $frames{main}->{log_toggle} = Wx::ToggleButton -> new($frames{main}, -1, "Show log",);
  $vbox->Add($frames{main}->{log_toggle}, 0, wxGROW|wxALL, 2);



  EVT_MENU	 ($frames{main}, wxID_ABOUT, \&on_about );
  EVT_MENU	 ($frames{main}, wxID_EXIT,  sub{shift->Close} );
  EVT_CLOSE	 ($frames{main},             \&on_close);
  EVT_MENU	 ($toolbar,      -1,         sub{my ($toolbar,  $event) = @_; OnToolClick($toolbar,  $event, $frames{main})} );
  EVT_MENU	 ($datatool,     -1,         sub{my ($fefftool, $event) = @_; OnDataClick($datatool, $event, $frames{main})} );
  EVT_MENU	 ($fefftool,     -1,         sub{my ($fefftool, $event) = @_; OnFeffClick($fefftool, $event, $frames{main})} );
  EVT_TOOL_ENTER ($frames{main}, $toolbar,   sub{my ($toolbar,  $event) = @_; OnToolEnter($toolbar,  $event, 'toolbar')} );
  EVT_CHECKBOX	 ($sum_button,   -1,         sub{my ($cb,       $event) = @_; OnSumClick ($cb,       $event, $frames{main}->{fitbutton})});
  EVT_BUTTON     ($frames{main}->{fitbutton}, -1, sub{fit(@_, \%frames)});

  ## -------- status bar
  $frames{main}->{statusbar} = $frames{main}->CreateStatusBar;
  $frames{main}->{statusbar} -> SetStatusText("Welcome to Artemis (" . $demeter->identify . ")");


  $frames{main} -> SetSizer($hbox);
  #$hbox  -> Fit($toolbar);
  #$hbox  -> SetSizeHints($toolbar);

  foreach my $part (qw(GDS Plot Log History)) {
    my $pp = "Demeter::UI::Artemis::".$part;
    $frames{$part} = $pp->new($frames{main});
    $frames{$part} -> SetIcon($icon);
  };
  $frames{main} -> Show( 1 );
  $toolbar->ToggleTool($frames{main}->{plot_toggle}->GetId,1);
  $frames{Plot} -> Show( 1 );
  EVT_TOGGLEBUTTON($frames{main}->{log_toggle}, -1, sub{ $frames{Log}->Show($frames{main}->{log_toggle}->GetValue) });

  1;
}

sub on_close {
  my ($self) = @_;
  foreach (values(%frames)) {$_->Destroy};
};

sub on_about {
  my ($self) = @_;

  my $info = Wx::AboutDialogInfo->new;

  $info->SetName( 'Artemis' );
  #$info->SetVersion( $demeter->version );
  $info->SetDescription( "EXAFS analysis using Feff and Ifeffit" );
  $info->SetCopyright( $demeter->identify );
  $info->SetWebSite( 'http://cars9.uchicago.edu/iffwiki/Demeter', 'The Demeter web site' );
  $info->SetDevelopers( ["Bruce Ravel <bravel\@bnl.gov>\n",
			 "Ifeffit is copyright © 1992-2009 Matt Newville"
			] );
  $info->SetLicense( slurp(File::Spec->catfile($artemis_base, 'Atoms', 'data', "GPL.dem")) );
  my $artwork = <<'EOH'
Blah blah blah

Some icons taken from the Fairytale icon set at Wikimedia commons,
http://commons.wikimedia.org/ and others from the Gartoon Redux icon
set from http:://www.gnome-look.org

All other icons icons are from the Kids icon set for
KDE by Everaldo Coelho, http://www.everaldo.com
EOH
  ;
  $info -> AddArtist($artwork);

  Wx::AboutBox( $info );
};

sub fit {
  my ($button, $event, $rframes) = @_;
  my (@data, @paths, @gds);
  $rframes->{main}->{statusbar}->SetStatusText("Fitting (please be patient, it may take a while...)");
  my $busy = Wx::BusyCursor->new();

  ## reset all relevant widgets to their initial states (i.e. assume
  ## that the last fit returned trouble and that the widgets
  ## containing the responsible data were colored in some way to
  ## indicate that)

  foreach my $k (keys(%$rframes)) {
    next unless ($k =~ m{\Adata});
    my $this = $rframes->{$k}->{data};
    $rframes->{$k}->fetch_parameters;
    push @data, $this;

    my $npath = $rframes->{$k}->{pathlist}->GetPageCount - 1;
    foreach my $p (0 .. $npath) {
      my $path = $rframes->{$k}->{pathlist}->GetPage($p);
      $path->fetch_parameters;
      push @paths, $path->{path};
    };
  };

  ## do I need to take care at this point about GDS's with the same name?
  my $grid = $rframes->{GDS}->{grid};
  foreach my $row (0 .. $grid->GetNumberRows) {
    my $name = $grid -> GetCellValue($row, 1);
    next if ($name =~ m{\A\s*\z});
    my $type = $grid -> GetCellValue($row, 0);
    my $mathexp = $grid -> GetCellValue($row, 2);
    my $thisgds = $grid->{$name} || Demeter::GDS->new(); # take care to reuse GDS objects whenever possible
    $thisgds -> set(name=>$name, gds=>$type, mathexp=>$mathexp);
    $grid->{$name} = $thisgds;
    push @gds, $thisgds;
  };

  ## get name, fom, and description + other properties
  my $fit = Demeter::Fit->new(data => \@data, paths => \@paths, gds => \@gds);
  #$fit->ignore_errors(1);
  $fit->set_mode(ifeffit=>1, screen=>0);
  my $result = $fit->fit;
  if ($result eq $fit) {
    #print $fit->logtext(q{}, q{});
    $fit->po->start_plot;
    $rframes->{Plot}->{limits}->{fit}->SetValue(1);
    $fit->po->plot_fit(1);
    $data[0]->plot('Rmr');

    $rframes->{GDS}->fill_results(@gds);

    set_happiness_color($fit->color);
    $rframes->{main}->{statusbar}->SetStatusText("Your fit is finished!");
  } else {
    $rframes->{main}->{statusbar}->SetStatusText("Your fit could not be finished due to imput errors.");
  };
  check_for_trouble($fit);
  undef $busy;
};


sub set_happiness_color {
  my $color = $_[0] || $demeter->co->default("happiness", "average_color");
  $frames{main}->{fitbutton} -> SetBackgroundColour(Wx::Colour->new($color));
  $frames{Plot}->{k_button}  -> SetBackgroundColour(Wx::Colour->new($color));
  $frames{Plot}->{r_button}  -> SetBackgroundColour(Wx::Colour->new($color));
  $frames{Plot}->{q_button}  -> SetBackgroundColour(Wx::Colour->new($color));
  foreach my $k (keys(%frames)) {
    next unless ($k =~ m{\Adata});
    $frames{$k}->{'plot_k123'} -> SetBackgroundColour(Wx::Colour->new($color));
    $frames{$k}->{plot_r123} -> SetBackgroundColour(Wx::Colour->new($color));
    $frames{$k}->{plot_rmr}  -> SetBackgroundColour(Wx::Colour->new($color));
    $frames{$k}->{plot_kq}   -> SetBackgroundColour(Wx::Colour->new($color));
  };
};

sub check_for_trouble {
  my ($fit) = @_;
  local $| = 1;
  foreach my $obj (@{ $fit->gds }, @{ $fit->data }, @{ $fit->paths }) {
    next if not $obj->trouble;
    printf("%-15s : %s\n", $obj->name, $obj->translate_trouble($obj->trouble));
  };
};

sub button_label {
  my ($string) = @_;
  my $this =  sprintf("%-40s", $string);
  return $string;
};

sub icon {
  my ($which) = @_;
  my $icon = File::Spec->catfile($Demeter::UI::Artemis::artemis_base, 'Artemis', 'icons', "$which.png");
  return wxNullBitmap if (not -e $icon);
  return Wx::Bitmap->new($icon, wxBITMAP_TYPE_ANY)
};

sub slurp {
  my $file = shift;
  local $/;
  open(my $FH, $file);
  my $text = <$FH>;
  close $FH;
  return $text;
};

sub _doublewide {
  my ($widget) = @_;
  my ($w, $h) = $widget->GetSizeWH;
  $widget -> SetSizeWH(2*$w, $h);
};


sub OnToolEnter {
  1;
};
sub OnToolClick {
  my ($toolbar, $event, $self) = @_;
  my $which = (qw(GDS Plot History))[$toolbar->GetToolPos($event->GetId)];
  $frames{$which}->Show($toolbar->GetToolState($event->GetId));
};

sub OnDataClick {
  my ($databar, $event, $self) = @_;
  my $which = $databar->GetToolPos($event->GetId);
  if ($which == 0) {
    my $fd = Wx::FileDialog->new( $self, "Import an Athena project", cwd, q{},
				  "Athena project (*.prj)|*.prj|All files|*.*",
				  wxFD_OPEN|wxFD_FILE_MUST_EXIST|wxFD_CHANGE_DIR|wxFD_PREVIEW,
				  wxDefaultPosition);
    if ($fd->ShowModal == wxID_CANCEL) {
      $frames{main}->{statusbar}->SetStatusText("Data import cancelled.");
      return;
    };
    my $file = File::Spec->catfile($fd->GetDirectory, $fd->GetFilename);

    ##
    my $selection = 0;
    $frames{prj} =  Demeter::UI::Artemis::Prj->new($frames{main}, $file);
    my $result = $frames{prj} -> ShowModal;

    if (
	($result == wxID_CANCEL) or     # cancel button clicked
	($frames{prj}->{record} == -1)  # import button without selecting a group
       ) {
      $frames{main}->{statusbar}->SetStatusText("Data import cancelled.");
      return;
    };

    my $data = $frames{prj}->{prj}->record($frames{prj}->{record});
    $data->po->start_plot;
    $data->plot('k');
    $data->plot_window('k') if $data->po->plot_win;
    my $newtool = $databar -> AddCheckTool(-1, "Show ".$data->name, icon("pixel"), wxNullBitmap, q{}, q{} );
    do_the_size_dance($self);
    my $idata = $newtool->GetId;
    my $dnum = sprintf("data%s", $idata);
    $frames{$dnum}  = Demeter::UI::Artemis::Data->new($self, $nset++);
    $frames{$dnum} -> SetTitle("Artemis: ".$data->name);
    $frames{$dnum} -> SetIcon($icon);
    $frames{$dnum} -> populate($data);
    $frames{$dnum} -> Show(1);
    $databar->ToggleTool($idata,1);
    delete $frames{prj};
    set_happiness_color();
    $frames{main}->{statusbar}->SetStatusText("Imported data \"" . $data->name . "\" from $file.");
  } else {
    my $this = sprintf("data%s", $event->GetId);
    return if not exists($frames{$this});
    $frames{$this}->Show($databar->GetToolState($event->GetId));
  };
};
sub OnFeffClick {
  my ($feffbar, $event, $self) = @_;
  my $which = $feffbar->GetToolPos($event->GetId);

  if ($which == 0) {

    ## also yaml data
    my $fd = Wx::FileDialog->new( $self, "Import crystal or Feff data", cwd, q{},
				  "input and CIF files (*.inp;*.cif)|*.inp;*.cif|input file (*.inp)|*.inp|CIF file (*.cif)|*.cif|All files|*.*",
				  wxFD_OPEN|wxFD_FILE_MUST_EXIST|wxFD_CHANGE_DIR|wxFD_PREVIEW,
				  wxDefaultPosition);
    if ($fd->ShowModal == wxID_CANCEL) {
      $frames{main}->{statusbar}->SetStatusText("Crystal/Feff data import cancelled.");
      return;
    };
    my $file = File::Spec->catfile($fd->GetDirectory, $fd->GetFilename);

    my $name = basename($file);	# ok for importing an atoms or CIF file

    my $newtool = $feffbar -> AddCheckTool(-1, "Show $name", icon("pixel"), wxNullBitmap, q{}, q{} );
    #$feffbar -> Realize;
    do_the_size_dance($self);
    my $ifeff = $newtool->GetId;
    my $fnum = sprintf("feff%s", $ifeff);
    $frames{$fnum} =  Demeter::UI::AtomsApp->new;
    $frames{$fnum} -> SetTitle('Artemis: Atoms and Feff');
    $frames{$fnum} -> SetIcon($icon);
    $frames{$fnum} -> Show(1);
    $feffbar->ToggleTool($ifeff,1);
    $frames{$fnum}->{Atoms}->Demeter::UI::Atoms::Xtal::open_file($file);
    #$newtool -> SetLabel( $frames{$fnum}->{Atoms}->{name}->GetValue );
    $frames{main}->{statusbar}->SetStatusText("Imported crystal data \"$name\".");

  } else {
    my $this = sprintf("feff%s", $event->GetId);
    return if not exists($frames{$this});
    $frames{$this}->Show($feffbar->GetToolState($event->GetId));
  };

};


## the tool bars only seem to update after a resize.  I could not
## figure out how to force an update without resizing, so this sub
## jiggles the window and voila! the new tool button appears.
sub do_the_size_dance {
  my ($top) = @_;
  my @size = $top->GetSizeWH;
  $top -> SetSize($size[0], $size[1]+1);
  $top -> SetSize($size[0], $size[1]);
};


sub OnSumClick {
  my ($check, $event, $fb) = @_;
  if ($check->IsChecked) {
    $fb -> SetLabel("Sum");
  } else {
    $fb -> SetLabel("Fit");
  };
};



1;


=head1 NAME

Demeter::UI::Artemis - EXAFS analysis using Feff and Ifeffit

=head1 VERSION

This documentation refers to Demeter version 0.3.

=head1 SYNOPSIS

This short program launches Artemis:

  use Wx;
  use Demeter::UI::Artemis;
  Wx::InitAllImageHandlers();
  my $window = Demeter::UI::Artemis->new;
  $window -> MainLoop;

=head1 DESCRIPTION

Artemis...

=head1 USE

Using ...

=head1 CONFIGURATION

Many aspects of Artemis and its UI are configurable using the
configuration ...

=head1 DEPENDENCIES

This is a Wx application.  Demeter's dependencies are in the
F<Bundle/DemeterBundle.pm> file.

=head1 BUGS AND LIMITATIONS

=over 4

=item *

blah blah

=back

Please report problems to Bruce Ravel (bravel AT bnl DOT gov)

Patches are welcome.

=head1 AUTHOR

Bruce Ravel (bravel AT bnl DOT gov)

L<http://cars9.uchicago.edu/~ravel/software/>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2009 Bruce Ravel (bravel AT bnl DOT gov). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlgpl>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
