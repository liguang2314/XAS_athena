package Demeter::UI::Wx::Printing;
use base qw( Exporter );
our @EXPORT = qw(on_preview on_print);

sub on_preview {
  my( $this, $event, $which ) = @_;
  my $text = $this->{$which}->GetValue;
  $text =~ s{\<}{&lt;}g;
  $text =~ s{\>}{&gt;}g;
  $::app->{main}->{printer} -> PreviewText('<html><body><pre>'.$text.'</pre></body></html>');
}

sub on_print {
  my( $this, $event, $which ) = @_;
  my $text = $this->{$which}->GetValue;
  $text =~ s{\<}{&lt;}g;
  $text =~ s{\>}{&gt;}g;
  $::app->{main}->{printer} -> PrintText('<html><body><pre>'.$text.'</pre></body></html>');
}

1;

=head1 NAME

Demeter::UI::Wx::Printing - A simple printing interface for Demeter GUIs

=head1 VERSION

This documentation refers to Demeter version 0.9.25.

=head1 SYNOPSIS

This provides callbacks for use with preview and print buttons.

In the main class:

  use Wx::Html;

then, later,

  $app->{main}->{printer} = Wx::HtmlEasyPrinting -> new("Printing", $app->{main});

When preview and print buttons are needed:

  use Demeter::UI::Wx::Printing;

the, later:

  $this->{preview} = Wx::Button->new($this, wxID_PREVIEW, q{});
  EVT_BUTTON($this, $this->{preview}, sub{on_preview(@_, $widget)});

where C<$this->{$widget}> resolves to the TextCtrl window that you
want to preview or print.

=head1 DEPENDENCIES

Demeter's dependencies are in the F<Build.PL> file.

=head1 BUGS AND LIMITATIONS

Please report problems to the Ifeffit Mailing List
(L<http://cars9.uchicago.edu/mailman/listinfo/ifeffit/>)

Patches are welcome.

=head1 AUTHOR

Bruce Ravel (L<http://bruceravel.github.io/home>)

L<http://bruceravel.github.io/demeter/>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2016 Bruce Ravel (L<http://bruceravel.github.io/home>). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlgpl>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut


