
# LICENSE

This software is braught to you under the EUPL-1.2 (or later) license.
The text of this license can be found in the LICENSES directory.

# Open Console

The software for Open Console is spread of multiple repositories:
  * <https://github.com/Skrodon/open-console-core> Core implementation (required)
  * <https://github.com/Skrodon/open-console-owner> Owner Website (required for now)
  * <https://github.com/Skrodon/open-console-connect> Connection provider (this repo)
  * <https://github.com/Skrodon/open-console-tasks> Batch processing

The design for the connector module is in the wiki of this repo:
  * DESIGN: <https://github.com/Skrodon/open-console-connect/wiki>

Have a look in the Wiki <https://github.com/Skrodon/open-console-connect/wiki/> for the
specs!  There is no code here, yet, but it may soon arrive.

# Open Console, Identity Provider
 
This project is part of https://open-console.eu Open Console, which is
(mainly) an initiative let website-owners communicate with service
which do something with their website, domain-name, or network.

Open Console is a larger project: this sub-project only focusses on the
identity exchange.  Actually: the identity is kept as part of the Contract
which is negotiated between an Account and a Service.  We assume that
people understand the term "identity" better than "contract".

## Installing Perl modules

  * You may be able to install most of the required Perl packages from your distribution.  (When you have tried this, please contribute that list for inclusion here.  See the `Makefile.PL` for the list of required modules.)
  * Use Perl to install it for you:
	  * in the GIT extract of this code, run "perl Makefile.PL; make install`.  (You probably need super-admin rights to do this: depends on your Perl set-up)

# Developers
