#!/usr/bin/perl

use Demeter qw(:plotwith=gnuplot :ui=screen);
my $demeter = Demeter->new;
unlink 'script.iff';
$demeter -> set_mode(screen=>0, file=>'>script.iff');

## -------- These commented out lines were used to generate a feff.inp
##          file from crystal data and then to calculate potentials with
##          Feff and to run Demeter's pathfinder

# my $atoms = Demeter::Atoms->new(file => "Au.inp");
# open my $F, ">Au_feff.inp";
# print $F $atoms->Write("feff6");
# close $F;

# my $feff = Demeter::Feff -> new(file => "Au_feff.inp");
# $feff->set(workspace=>"./", screen=>0,);

# $feff -> potph;         # use Feff to compute potnetials
# $feff -> pathfinder;    # use Demeter's pathfinder
# $feff->freeze("Au_feff.yaml");

## -------- Import the results of the Feff calculation

my $feff = Demeter::Feff->new(yaml=>'Au_feff.yaml');
$feff->set(workspace=>"./", screen=>0,);
my @list_of_paths = @{ $feff->pathlist };

## -------- Import some data
my $data  = Demeter::Data::Prj->new(file=>'Aunano.prj') -> record(5);
$data->po->kweight(1);
$data -> set(
	     fft_kmin=>3, fft_kmax=>13,
	     bft_rmin=>1.992, bft_rmax=>3.399,
	     #fft_kmin=>2, fft_kmax=>20, bft_rmin=>0.5, bft_rmax=>10,
	     fit_k1=>1,   fit_k2=>1,    fit_k3=>1,
	    );

## -------- Some parameters
my @gds = (
	   Demeter::GDS->new(gds=>'guess', name=>'amp',    mathexp=>1),
	   #Demeter::GDS->new(gds=>'set', name=>'amp2',   mathexp=>6*exp(1)),
	   Demeter::GDS->new(gds=>'guess', name=>'enot',   mathexp=>0),
	   #Demeter::GDS->new(gds=>'set',   name=>'alpha',  mathexp=>0),
	   Demeter::GDS->new(gds=>'guess',   name=>'sigsqr', mathexp=>0.0),
	  );
$data->po->title("without sigma2");
$_->push_ifeffit foreach @gds;

## -------- Import the first scattering path object and use it
##          to populate a histogram defined by an external file.
##          Also define a VPath containing the entire first
##          shell of the histogram.
my $firstshell = $list_of_paths[1];

my ($rx, $ry) = $firstshell->histogram_from_file('RDFDAT20K', 1, 2, 2.5, 3.1);

#my $common = [sigma2 => 'sigsqr', e0 => 'enot', data=>$data];
#my $paths = $firstshell -> make_histogram($rx, $ry, 'amp', q{}, $common);

my $common = [s02 => 'amp', sigma2 => 'sigsqr', e0 => 'enot', data=>$data];
my $p = $firstshell -> make_histogram($rx, $ry, q{}, q{});
my $composite = $firstshell -> chi_from_histogram($p, $common);
#$composite->plot('k');
#$composite->source->plot('k');

#my $vpath = Demeter::VPath->new(name=>'histo');
#$vpath->include(@$paths);
#$vpath->plot('k');

#$data->plot('k');
#$data->pause;
#exit;


## -------- Do the fit
#my $fit = Demeter::Fit->new(gds=>\@gds, data=>[$data], paths=>$paths);
my $fit = Demeter::Fit->new(gds=>\@gds, data=>[$data], paths=>[$composite]);
$fit->fit;
$fit->logfile("filtered.log");

$demeter -> set_mode(plotscreen=>0);
$data->po->start_plot;
$data->po->r_pl('r');
$data->po->plot_fit(1);
$data->po->showlegend(0);
$data->po->title("with sigma2");
$_->plot('r') foreach ($data); #,@$paths);
$data -> pause;
#$fit->interview;
