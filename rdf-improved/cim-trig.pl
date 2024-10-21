#!perl -w
# Converts CIM XML file to Trig (Turtle with graphs).

# Assumptions:
# - Relies on a repeatable CIM XML layout as lines (uses simple string manipulation).
#   If needed, I can change it to work with proper XML access. This module seems suitable:
# use XML::DT; # https://metacpan.org/pod/XML::DT
# - A file has exactly one model: md:FullModel or dm:DifferenceModel
# - dm:DifferenceModel has exactly two sections dm:reverseDifferences and dm:forwardDifferences in this order
# - Uses "owl write" (non-streaming) for nicer formatting
# - For very large files, use Jena riot in  --output mode (streaming)

use warnings;
use autodie;
use UUID qw(uuid4); # https://metacpan.org/pod/UUID
  # CIM UUIDs are version 4: https://github.com/Sveino/Spec4CIM-KG/issues/10

# owl.bat prints some junk on STDERR that I can't suppress on Cygwin, so we need to use explicit in/out filenames
my $in = shift;
my $out = shift or die "Usage: $0 in.rdf out.trig\n";
open(STDIN,$in);

# slurp STDIN
$/ = undef;
my $xml = <STDIN>;

# remove parasitic underscore from start of relative URLs
$xml =~ s{(rdf:(about|resource)=\"#)_+}{$1}g;

# Add base
my ($rdf_open, $body, $rdf_close) =
  $xml =~ m{(.*?<rdf:RDF.*?>)(.*?)(</rdf:RDF>)}s
  or die "Can't find rdf:RDF element\n";
my ($base) =
  $body =~ m{<md:Model.modelingAuthoritySet>(.*?)<}
  or die "Can't find md:Model.modelingAuthoritySet\n";
$rdf_open =~ s{<rdf:RDF}{<rdf:RDF xml:base="$base"};

# extract Model element and its attributes
my ($model, $model_type, $model_uri) =
  $body =~ m{(<(md:FullModel|dm:DifferenceModel) rdf:about="(.*?)".*?</\2>)}s
  or die "Can't find md:FullModel or dm:DifferenceModel\n";

if ($model_type eq "dm:DifferenceModel") {
  my ($model_open, $reverse, $forward, $model_close) =
    $model =~ m{(.*?)
\s*<dm:reverseDifferences rdf:parseType="Statements">(.*?)</dm:reverseDifferences>
\s*<dm:forwardDifferences rdf:parseType="Statements">(.*?)</dm:forwardDifferences>
(.*)}s
    or die "Can't find dm:reverseDifferences FOLLOWED BY dm:forwardDifferences\n";
  my $reverse_uri = "urn:uri:" . uuid4();
  my $forward_uri = "urn:uri:" . uuid4();
  my $reverse_ref = qq{<dm:reverseDifferences rdf:resource="$reverse_uri"/>};
  my $forward_ref = qq{<dm:forwardDifferences rdf:resource="$forward_uri"/>};
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

open(STDOUT,">$out");
print $output;

sub ttl {
  # https://perldoc.perl.org/functions/open#Opening-a-filehandle-into-a-command
  my $input = shift;
  my $fh;
  my $tmp = "tmp$$";
  open ($fh,">$tmp.rdf");
  print $fh $input;
  close $fh;
  system("owl.bat write --keepUnusedPrefixes -i rdfxml $tmp.rdf $tmp.ttl");
  ## riot.bat --syntax=rdfxml --output=ttl $infile > $outfile
  open ($fh, "$tmp.ttl");
  my $output = <$fh>; # $/ is undef, so it slurps
  close $fh;
  unlink "$tmp.rdf";
  unlink "$tmp.ttl";
  $output
}

sub ttl_no_prefixes {
  my $x = ttl(shift);
  $x =~ s{\@prefix.*}{}g;
  $x =~ s{^\n+}{}g;
  $x =~ s{\n+$}{}g;
  $x
}

sub ttl_insert_after_prefixes {
  my $x = ttl(shift);
  my $insert = shift;
  $x =~ s{(\@prefix.*\n\n)}{$1$insert};
  $x
}
