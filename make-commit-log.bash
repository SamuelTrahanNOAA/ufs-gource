#! /bin/bash

set -xue

cat<<EOF > submodules.lst
WW3
stochastic_physics
CMakeModules
CMEPS-interface/CMEPS
HYCOM-interface/HYCOM
MOM6-interface/MOM6
CICE-interface/CICE
CDEPS-interface/CDEPS
GOCART
AQM
AQM/src/model/CMAQ
NOAHMP-interface/noahmp
FV3
FV3/ccpp/physics
FV3/atmos_cubed_sphere
FV3/upp
EOF

submodules=$( cat submodules.lst )

rm -f uncorrected.log combined.log unsorted.log
touch uncorrected.log combined.log unsorted.log

for submodule in . $submodules ; do
    gource --output-custom-log $submodule/local.log $submodule > /dev/null
    if [ "$submodule" != . ] ; then
        sed -r "s#(.+)\|#\1|/$submodule#" $submodule/local.log >> uncorrected.log
    fi
done

cat uncorrected.log | perl -ne '
  @line = split(/(\|)/);

  # For consistency, everyone gets . instead of whitespace
  $line[2] =~ s/\s+/./g ;

  # Remove or correct oddities
  $line[2] =~ s/\.\.+/./g; # Comes from "Abbreviation. Name"
  $line[2] =~ s/\?//g; # Stray "?" in some commits
  $line[2] =~ s/â//g; # Spurious character in Jun.Wang commits
  $line[2] =~ s/\@noaa.*//g; # Remove @noaa and @noaa.gov since they are ubiquitous and inconsistent
  # $line[2] =~ s/\@noaa$/\@noaa.gov/g; # incomplete alternative to removing @noaa.*
  $line[2] =~ s/\.*-\.*/-/g; # comes from ".-" or just stray " " before and after a "-"

  # Sometimes automatic username generators on RDHPCS will add junk in parentheses.
  $line[2] =~ s/\.?\(NOAA.contractor\)//ig;
  $line[2] =~ s/\.?\(NOAA\)//ig;
  $line[2] =~ s/\.?\(contractor\)//ig;

  # Correct errors and inconsistencies in user names.  Some users have
  # multiple names for the same github account, or occasionally have
  # gibbersh after their name.  Correct them on a case-by-case
  # basis. I have certainly missed some.
  $line[2] =~ s/\bhaiqinli\b/Haiqin.Li/ig ;
  $line[2] =~ s/\bgrantfirl\b/Grant.Firl/ig ;
  $line[2] =~ s/\blisa-bengtsson\b/Lisa.Bengtsson/ig ;
  $line[2] =~ s/\bmvertens/Mariana.Vertenstein/ig ;
  $line[2] =~ s/\bXiaqiong.Zhou\b/XiaqiongZhou-NOAA/ig ;
  $line[2] =~ s/\bRatko.Vasic\b/RatkoVasic-NOAA/ig ;
  $line[2] =~ s/\bPhil.Pegion\b/Philip.Pegion/ig ;
  $line[2] =~ s/\bpjpegion\b/Philip.Pegion/ig ;
  $line[2] =~ s/\bJose.Henrique.Alves\b/Jose-Henrique.Alves/ig ;
  $line[2] =~ s/\bAaronDonahue\b/Aaron.Donahue/ig;
  $line[2] =~ s/\bAlperaltuntas\b/Alper.Altuntas/ig;
  $line[2] =~ s/\bAliabdolali\b/Ali.Abdolali/ig;
  $line[2] =~ s/\bBbakernoaa/Barry.Baker/ig;
  $line[2] =~ s/\bBin.Li\b/BinLi-NOAA/ig;
  $line[2] =~ s/\bGuang-Ping.Lou.*/Guang-Ping.Lou/ig;

  # Undo some changes to "(parenthetic)" data
  $line[2] =~ s/\.(\([^\)]*\))/$1/g;

  # Camel Case except @domain.names and "(parenthetic)" data
  @s=split(/([.-]|@.*\([^\)]*\))/, $line[2]);
  foreach $x(@s) {
     $x or next;
     $x =~ m/(.)(.*)/g or die "BAD ($x)";
     @m = ($1, $2);
     $m[0]=~tr/a-z/A-Z/;
     $x="$m[0]$m[1]" ;
  };
  $line[2]=join("",@s) ;

  print(join("",@line))
' > unsorted.log

sort -t '|' -nk1,1 < unsorted.log > combined.log
