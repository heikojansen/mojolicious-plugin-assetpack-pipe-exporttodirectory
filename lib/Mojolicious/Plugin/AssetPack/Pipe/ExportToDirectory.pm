
package Mojolicious::Plugin::AssetPack::Pipe::ExportToDirectory;

use Mojo::Base 'Mojolicious::Plugin::AssetPack::Pipe';
use Mojo::File;

use File::Basename 'dirname';
use File::Path 'make_path';
use File::Spec;

has 'export_dir' => sub { $ENV{MOJO_ASSETPACK_EXPORT_DIRECTORY} || '' };
has 'use_checksum_subdir' => 1;


sub process {
	my ( $self, $assets ) = @_;

	my $dir = $self->export_dir;
	unless ( defined $dir and -e -w -d $dir ) {
		die "Missing or inaccesable export base directory '$dir'";
	}

	$assets->each(
		sub {
			my $asset = shift;

			my ( $file, $path ) = ( '',  '' );
			if ( $self->use_checksum_subdir ) {
				$file = sprintf( "%s.%s", $asset->name, $asset->format );
				$path = File::Spec->catfile( $dir, $asset->checksum );
			}
			else {
				$file = sprintf( "%s-%s.%s", $asset->name, $asset->checksum, $asset->format );
				$path = $dir;
			}

			my $p = Mojo::File->new($path);
			$p->make_path;
			$p->child($file)->spurt( $asset->content );
		}
	);
} ## end sub process

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::AssetPack::Pipe::ExportToDirectory - Export processed
assets to directory

=head1 SYNOPSIS

  use Mojolicious::Lite;
  
  # "Export" comes last!
  plugin AssetPack => {pipes => [qw(... ExportToDirectory)]};
  app->asset->pipe('ExportToDirectory')->export_dir("/some/path/in/webroot");
  # app->asset->pipe('ExportToDirectory')->use_checksum_subdir(0);

=head1 DESCRIPTION

L<Mojolicious::Plugin::AssetPack::Pipe::ExportToDirectory> will export the 
processed assets to the given directory so you can have them served directly
by your webserver instead of going through the Mojolicious app.
Note that when using a webserver like Nginx or Apache as reverse proxy, these
can also be configured to cache the data they receive from your app so after
answering the first request follow-up requests will usually not get through
to your app.

=head1 ATTRIBUTES

=head2 export_dir

  $dir_path = $self->export_dir;
  $self = $self->export_dir("/path/to/some/dir");

Sets the base directory the assets will be exported to.
If you do not configure this, the environment variable 
C<MOJO_ASSETPACK_EXPORT_DIRECTORY> will be used as fallback. If neither value
is available, processing will fail with an exception (C<die()>).

=head2 use_checksum_subdir

  $bool = $self->use_checksum_subdir;
  $self = $self->use_checksum_subdir(0);

Controls how the exported assets are named.

By default and by setting this to a C<true> value, assets will be exported
to
"E<lt>export_dirE<gt>/E<lt>checksumE<gt>/E<lt>nameE<gt>.E<lt>formatE<gt>".
This corresponds to the route the C<asset>-helper generates by default.

Alternatively you can set C<use_checksum_subdir> to C<false> in which case
the assets will be exported as 
"E<lt>export_dirE<gt>/E<lt>nameE<gt>-E<lt>checksumE<gt>.E<lt>formatE<gt>".
This way, you can have a better overview of the exported files and their
versions.

=head1 METHODS

=head2 process

See L<Mojolicious::Plugin::AssetPack::Pipe/process>.

=head1 SEE ALSO

L<Mojolicious::Plugin::AssetPack>.

=cut
