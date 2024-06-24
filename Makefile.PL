# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

use ExtUtils::MakeMaker;

use 5.016;

WriteMakefile
 ( NAME     => 'Open-Console-Id'
 , VERSION  => '0.01'

 , PREREQ_PM    => { 
	# Common purpose modules
	'Data::Dumper'           => 0,
	'Devel::GlobalDestruction' => 0,
	'List::Util'             => 0,
	'Log::Report'            => 0,
   }
 , EXE_FILES    => []
 , AUTHOR       => 'Open Console <team@open-console.eu>'
 , ABSTRACT     => 'Open Console Identities'
 , LICENSE      => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/Skrodon/open-console-id.git'
              , web  => 'https://github.com/Skrodon/open-console-id'
              }
          , homepage => 'http://open-console.eu'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = /tmp/OpenConsoleId/raw
DISTDIR         = /tmp/OpenConsoleId/source

# for POD
FIRST_YEAR      = 2024
EMAIL           = mark@open-console.eu
EXTENDS         = 
WEBSITE         = http://perl.overmeer.net/open-console

__POSTAMBLE
