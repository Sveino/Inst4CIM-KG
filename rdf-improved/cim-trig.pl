#!perl -w
# Converts CIM XML file to Trig (Turtle with graphs).

# Assumptions:
# - Relies on a repeatable CIM XML layout as lines (uses simple string manipulation).
#   If needed, I can change it to work with proper XML access. This module seems suitable:
# use XML::DT; # https://metacpan.org/pod/XML::DT
# - A file has exactly one model: md:FullModel|dcat:Dataset or dm:DifferenceModel|dcat-cim:DifferenceSet
# - dm:DifferenceModel has exactly two sections dm:reverseDifferences and dm:forwardDifferences in this order
# - Uses "owl write" (non-streaming) for nicer formatting
# - For very large files, use Jena riot in --stream mode (streaming)

use warnings;
use autodie;
use UUID qw(uuid4); # https://metacpan.org/pod/UUID
  # CIM UUIDs are version 4: https://github.com/Sveino/Spec4CIM-KG/issues/10
use Getopt::Std;
our $opt_r;
getopts("r");

# owl.bat prints some junk on STDERR that I can't suppress on Cygwin, so we need to use explicit in/out filenames
my $in = shift or die <<"EOF";
Usage: $0 -r in.rdf > out.trig
      By default uses "owl write" for prettier output
  -r: Use riot in streaming mode for bigger output
EOF
open(STDIN,$in);

# slurp STDIN
$/ = undef;
my $xml = <STDIN>;

## remove parasitic underscore from start of relative URLs
# $xml =~ s{(rdf:(about|resource)=\"#)_+}{$1}g;

# Add base
my ($rdf_open, $body, $rdf_close) =
  $xml =~ m{(.*?<rdf:RDF.*?>)(.*?)(</rdf:RDF>)}s
  or die "Can't find rdf:RDF element\n";
my ($base) =
  $body =~ m{(?:<md:Model.modelingAuthoritySet>|<dcat:isVersionOf rdf:resource=")(.*?)[<"]}
  or warn qq{WARN: can't find md:Model.modelingAuthoritySet|dcat:isVersionOf rdf:resource\n};
$rdf_open =~ s{xml:base="http://iec.ch/TC57/CIM100"}{}
  and warn qq{WARN: xml:base="http://iec.ch/TC57/CIM100" is inappropriate for instance URLs\n};
$rdf_open =~ s{<rdf:RDF}{<rdf:RDF xml:base="$base#"} if $base;

# extract Model element and its attributes
my ($model, $model_type, $model_uri) =
  $body =~ m{(<(md:FullModel|dcat:Dataset|dm:DifferenceModel|dcat-?cim:DifferenceSet) rdf:about="(.*?)".*?</\2>)}s
  or die "Can't find md:FullModel|dcat:Dataset or dm:DifferenceModel|dcatcim:DifferenceSet\n";

if ($model_type =~ "dm:DifferenceModel|dcat-?cim:DifferenceSet") {
  my ($model_open, $reverse_tag, $reverse, $reverse_tag1, $forward_tag, $forward, $forward_tag1, $model_close) =
    $model =~ m{(.*?)
\s*<(dm:reverseDifferences|dcat-?cim:reverseDifferenceSet) rdf:parseType="Statements">(.*?)</(dm:reverseDifferences|dcat-?cim:reverseDifferenceSet)>
\s*<(dm:forwardDifferences|dcat-?cim:forwardDifferenceSet) rdf:parseType="Statements">(.*?)</(dm:forwardDifferences|dcat-?cim:forwardDifferenceSet)>
(.*)}s
    or die "Can't find dm:reverseDifferences|dcat-cim:reverseDifferenceSet FOLLOWED BY dm:forwardDifferences|dcat-cim:forwardDifferenceSet\n";
  my $reverse_uri = "urn:uuid:" . uuid4();
  my $forward_uri = "urn:uuid:" . uuid4();
  my $reverse_ref = qq{<$reverse_tag rdf:resource="$reverse_uri"/>};
  my $forward_ref = qq{<$forward_tag rdf:resource="$forward_uri"/>};
  $model = ttl_insert_after_prefixes
    ("$rdf_open$model_open$reverse_ref$forward_ref$model_close$rdf_close",
    "<$model_uri> { # model metadata\n");
  $reverse = ttl_no_prefixes("$rdf_open$reverse$rdf_close");
  $forward = ttl_no_prefixes("$rdf_open$forward$rdf_close");
  $output = qq{
$model\}

<$reverse_uri> { # reverseDifferences
$reverse
}

<$forward_uri> { # forwardDifferences
$forward
}}} else {
  $model = ttl_insert_after_prefixes
    ("$rdf_open$body$rdf_close",
     "<$model_uri> { # model graph\n\n");
  $output = "$model}";
};

print $output;

sub ttl {
  # https://perldoc.perl.org/functions/open#Opening-a-filehandle-into-a-command
  my $input = shift;
  my $fh;
  my $tmp = "tmp$$";
  open ($fh,">$tmp.rdf");
  print $fh $input;
  close $fh;
  system ($opt_r ? "riot.bat --syntax=rdfxml --stream=ttl $tmp.rdf > $tmp.ttl":
          "owl.bat write --keepUnusedPrefixes -i rdfxml $tmp.rdf $tmp.ttl");
  open ($fh, "$tmp.ttl");
  my $output = <$fh>; # $/ is undef, so it slurps
  close $fh;
  unlink "$tmp.rdf";
  unlink "$tmp.ttl";
  $output
}

sub ttl_no_prefixes {
  my $x = ttl(shift);
  $x =~ s{^(\@base|\@prefix|BASE|PREFIX).*\n}{}gm;
  $x =~ s{^\n+}{};
  $x =~ s{\n+$}{};
  $x
}

sub ttl_insert_after_prefixes {
  my $x = ttl(shift);
  my $insert = shift;
  $x =~ s{^((\@base|\@prefix|BASE|PREFIX).*\n\n)}{$1$insert}m;
  $x
}
