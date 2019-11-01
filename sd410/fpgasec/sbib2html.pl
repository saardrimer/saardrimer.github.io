#!/usr/bin/perl -w
use strict;

#--------------------------------------------------------
# sbib2html.pl
#
# author:  saar drimer, <first>.<last>@cl.cam.ac.uk
#
# webpage: http://www.saardrimer.com
#          http://www.cl.cam.ac.uk/~sd410
#
# project: http://www.cl.cam.ac.uk/~sd410/fpgasec
#
# See my comments in the code for guidance. In brief, if
# you want to order your entries you need to add a
# "www_section  = {foo}," field to each entry. The
# ordering of the _categories_ is determined by the
# first instance in which they appear, then by sequential 
# order in which they are ordered in the bibtex file. If 
# you run into trouble consult the raw bibtex file linked
# in the project's webpage. In a case of emergency,
# call 911 (or your local equivalent), then contact me.
#
# Copyright notice: you are welcome to use this script to
# your heart's content... but please do give some credit
# and link back. Be nice. It is supplied as-is. I believe
# in the creativity of people; therefore, someone might
# find a way to hurt themselves using this code. In that
# case I am wholly void of responsibility. Don't forget
# your safety goggles... a pint to the first person who
# emails me the words "Stanley Spadowski"!
#
# I would also appreciate any comments, suggestions and
# corrections.
#
#--------------------------------------------------------

print <<End if $#ARGV < 0;
Usage: sbib2html.pl <infile>
End
exit 1 if $#ARGV < 0;

$ARGV[0] =~ s/\..*//;
my $infile = "$ARGV[0].bib";     # input file
my $outfile = "$ARGV[0].html";   # output html file
my $outbib = "$ARGV[0]_web.bib"; # output bib file for web consumption

# slurp file
local( *IN ) ;
open( IN, $infile ) or die "Can not open $infile\n";
my $fc = do { local( $/ ) ; <IN> };
close (IN);

# remove all comments that start in a new line; this will
# avoid removing '%' in URLs for example
$fc =~ s/^%.*\n//g;

# separate all entries into array
my @bibs = $fc =~ /(\@.+?\})\s*\n/smg;

open (OUT, ">$outfile");
open (WEB, ">$outbib");
my $i = 0;

# this is a dump of an external html header information and
# tags. use it to provide the mandatory html tags, meta data
# css/script calls etc... up to and including the <body> tag.
open (TMP, "head");
while (<TMP>) { print OUT; }
close TMP;

# print header for web version of bib file
print WEB "%------------------------------------------\n% FPGA security bibliography\n% created by: saar drimer\n%             http://www.cl.cam.ac.uk/users/sd410\n%             http://www.saardrimer.com\n%------------------------------------------\n\n";

my @cat = ();
my %cat = ();
my $tmp;
my $total= 0;

# get section names
foreach my $b (@bibs)
{
  ($tmp) = ($b =~ /www_section\s*=\s*\{([^,\}]*)[,\}]/);
  
  # all entried must have a "www_section" categoty.
  if (!defined($tmp)) { 
    die "\nERROR: no \'www_section\' category found for the following entry:\n$b\n";;
  }
  else {  
    # if "www_section" = 'none' then the entry will not be processed
    if ($tmp ne 'none') {
      $total++;
      push @{$cat{$tmp}}, $b;
    
      # this is needed to get the categories ordered by when they first
      # appear in the bib file. You can not determine the ordering
      # of a hash (and sorting isn't quite what I wanted)
      if (!(grep (/$tmp/, @cat))) {
        push (@cat, $tmp);
      }
    }
  }
}

$i = 1;
my $hi;

my $type;
my $author;
my $title;
my $org;
my $year;
my $section;
my $url;
my $abstract;
my $recs;

print OUT "\n<div class=\"headers\" style=\"background-color: \#ffffff\;text-align: center\"><strong>categories</strong> | ";

foreach my $k (@cat) {
  printf OUT "<a href=\"#%s\">%s</a> | ", $k, $k;
}

print OUT "</div>\n";

print OUT "<div class=\"headers\" style=\"background-color: \#ffffff\;text-align: center\"><strong><a href=\"javascript:sweeptoggle(\'contract\', 0, 0)\">contract all</a> | <a href=\"javascript:sweeptoggle(\'expand\', 0, 0)\">expand all</a></strong></div><div class=\"headers\" style=\"background-color: \#ffffff\;\">legend: <span style=\"background-color: #fffacd\">FPGA specific</span>, <span style=\"background-color: #e8f8ff\">general security</span> (click <img src=\"plus.png\" alt=\"expand\" style=\"vertical-align: bottom\"> for abstract and bibtex entry) [$total entries]</div>";

foreach my $k (@cat)
{

  # print categoty header for web version of bib file
  printf WEB "%%------------------------------------------\n%% category: %s\n%%------------------------------------------\n\n", $k;

  $recs = @{$cat{$k}}-1;

  printf OUT "\n<div class=\"headers\" style=\"background-color: \#ffffff\;border: 1px solid lightgrey\"><a name=\"%s\"></a><h3>%s</h3>&nbsp;(<a href=\"javascript:sweeptoggle(\'contract\', %s, %s)\">contract all</a> | <a href=\"javascript:sweeptoggle(\'expand\', %s, %s)\">expand all</a>)</div>\n", $k, $k, $i, $i+$recs, $i, $i+$recs;

  foreach my $b (@{$cat{$k}})
  {
  
    printf WEB "%s\n\n", $b;

    # HTML validators complain when they see '&' in the URL. Therefore,
    # it needs to be changed to '&amp;'
    ($b) =~ s/\&/\&amp\;/g;

    ($type)     = ($b =~ /\@(.*)\{/);
    ($author)   = ($b =~ /author\s*=\s*\{(.*?)\},\s*\n/);
    ($title)    = ($b =~ /title\s*=\s*\{(.*?)\},\s*\n/);
    ($org)      = ($b =~ /organization\s*=\s*\{(.*?)\},\s*\n/);
    ($year)     = ($b =~ /year\s*=\s*\{(.*?)\},\s*\n/);
    ($section)  = ($b =~ /www_section\s*=\s*\{(.*?)\},\s*\n/);
    ($url)      = ($b =~ /url\s*=\s*\{(.*?)\},\s*\n/);
    ($abstract) = ($b =~ /abstract\s*=\s*\{(.*?)\},\s*\n/s);
    
    if ($author)   {
       ($author)   =~ s/\{\\.\{(.)\}\}/$1/g; # replace accents
       ($author)   =~ s/\{\\ss\{\}\}/ss/g;   # replace \ss{} accent
       ($author)   =~ s/[\{\}]//g;
       ($author)   =~ s/ and /, /g;
       ($author)   =~ s/(.*),/$1 and/;
    }

    # some entries, like web pages, do not have a title (the reason that what
    # would be the title appear in the author field is because it makes it easier
    # for sorting by the .bst definition file); this uses the author as the 
    # title for placing the link.
    if ($title eq '') {
      $title = $author;
    }
    
    ($title)    =~ s/\\EUR\{(.*?)\}/&\#8364 $1/g;
    ($title)    =~ s/[\{\}]//g;
    
    if ($abstract) {
      ($abstract) =~ s/\n/<br>/g;
    }
    
    # remove abstract from bib entry
    $b =~ s/ *abstract\s*=\s*\{.*\}, *\n//smg;
    $b =~ s/\n/\<br\>/g;
  
    # highlight item if it is FPGA specific
    if ($section =~ /FPGA/) {
      $hi = ' style="background-color: #fffacd;"';
    }
    else {
      $hi = '';
    }
  
    printf OUT "<div class=\"headers\"%s>\n<img src=\"minus.png\" alt=\"contract\" class=\"showstate\" onClick=\"expandcontent(this, \'sc$i\')\">\n", $hi;
    
    if ($author)   { printf OUT "%s: ", $author;}
    elsif ($org)   { printf OUT "%s: ", $org;}   
    if ($url)      { printf OUT "\"<a href=\"%s\">%s</a>\"", $url, $title;}
    else           { printf OUT "\"%s\"", $title;}
    if ($year)     { printf OUT ", %s.", $year};
    
    printf OUT "\n</div>\n<div id=\"sc$i\" class=\"switchcontent\">\n<table>";
  
    # output abstract if exist
    if ($abstract) {
      printf OUT "<tr><td class=\"abstract\"><strong>Abstract. </strong>\n%s\n</td></tr>", $abstract;
    }  
    
    # output bib entry for cut-and-paste
    printf OUT "<tr><td class=\"bibtex\">%s</td></tr></table>\n</div>", $b;  
    $i++;
  }
}

print "processed $total entries\n";

# provide closing tags and info
open (TMP, "foot");
while (<TMP>) {
  print OUT;
}
close TMP;

my ($y, $m, $d) = (localtime)[5,4,3];

$y += 1900;
$m += 1;

print OUT "<p>last modified $y\/$m\/$d<br>\n";

print OUT '</body></html>';

close (OUT);
close (WEB);


