use inc::Module::Install 1.00;
use strict;
use warnings;

# to deal wuth x.y.z versions properly
configure_requires 'ExtUtils::MakeMaker' => 6.54;

my $deps = {
  requires => {
    'Class::Base'              => 0,
    'Class::Data::Inheritable' => 0.02,
    'Class::MakeMethods'       => 0,
    'Digest::SHA1'             => 2.00,
    'Carp::Clan'               => 0,
    'IO::Dir'                  => 0,
    'IO::Scalar'               => 2.110,
    'Parse::RecDescent'        => 1.962002,
    'Pod::Usage'               => 0,
    'Class::Accessor::Fast'    => 0,
    'DBI'                      => 0,
    'File::ShareDir'           => 1.0,
    'File::Spec'               => 0,
    'Scalar::Util'             => 0,
    'XML::Writer'              => 0.500,
    'Moo'                      => 0.009007,
  },
  recommends => {
    'Template'                 => 2.20,
    'GD'                       => 0,
    'GraphViz'                 => 0,
    'Graph::Directed'          => 0,
    'Spreadsheet::ParseExcel'  => 0.41,
    'Text::ParseWords'         => 0,
    'Text::RecordParser'       => 0.02,
    'XML::LibXML'              => 1.69,
  },
  test_requires => {
    'YAML'                     => 0.66,
    'File::Basename'           => 0,
    'Test::More'               => 0.6,
    'Test::Differences'        => 0,
    'Test::Exception'          => 0,
  },
};

perl_version '5.005';

name        'SQL-Translator';
author      'Ken Youens-Clark <kclark@cpan.org>';
abstract    'SQL DDL transformations and more';
license     'gpl';
repository  'git://git.shadowcat.co.uk/dbsrgits/SQL-Translator.git';
bugtracker  'http://rt.cpan.org/NoAuth/Bugs.html?Dist=SQL-Translator';

resources Ratings => 'http://cpanratings.perl.org/d/SQL-Translator';

all_from    'lib/SQL/Translator.pm';

for my $type (qw/requires recommends test_requires/) {
  no strict qw/refs/;
  my $f = \&$type;
  for my $mod (keys %{$deps->{$type} || {} }) {
    $f->($mod, $deps->{$type}{$mod});
  }
}

tests_recursive ();

install_script (qw|
  script/sqlt-diagram
  script/sqlt-diff
  script/sqlt-diff-old
  script/sqlt-dumper
  script/sqlt-graph
  script/sqlt
|);

install_share();

auto_provides();

auto_install();

if ($Module::Install::AUTHOR) {
  _recompile_grammars();
  _recreate_rt_source();
}

WriteAll();

sub _recompile_grammars {
  # placeholder, will be used to recompile P::RD parsers before shipping
  # will also allow to lose dependency on P::RD
}

sub _recreate_rt_source {
  my $base_xml = "t/data/roundtrip.xml";
  my $autogen_yaml = "t/data/roundtrip_autogen.yaml";

  print "Updating $autogen_yaml\n";

  unlink $autogen_yaml;

  eval {

    use lib 'lib';

    require SQL::Translator;
    require SQL::Translator::Parser::XML;

    open (my $fh, '>', $autogen_yaml) or die "$autogen_yaml: $!\n";

    my $tr = SQL::Translator->new;
    my $yaml = $tr->translate (
      parser => 'XML',
      file => $base_xml,
      producer => 'YAML',
    ) or  die sprintf ("Unable to translate %s to YAML: %s\n",
              $base_xml,
              $tr->error || 'error unknown'
          );

    print $fh $yaml;
    close $fh;
  };

  if ($@) {
    warn <<EOE;

=========================================================================
===============              WARNING !!!                =================
=========================================================================

Unable to update the roundtrip schema (attempt triggered by AUTHOR mode).
We will still generate a Makefile, but be aware that if you build a dist
this way, it *WILL* be broken.

-------------------------------------------------------------------------
$@

Press Enter to continue.
EOE
  <>;
  }
}
