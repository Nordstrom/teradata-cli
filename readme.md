Description
-------------------------
A lightweight OSX/Linux command line utility for the [Teradata](http://www.teradata.com/)database server modeled after the Postgres [psql](http://www.postgresql.org/docs/9.2/static/app-psql.html) utility. Built with JRuby to take advantage of JDBC interoperability.

Installation Instructions
-------------------------
* Ensure rvm and jruby are installed
* Make sure teradata_cli has execute permissions: 
  chmod +x teradata-cli
* Create a symlink in /usr/local/bin replacing "~/src" with your clone path:
  ln -s ~/src/teradata-cli/teradata-cli /usr/local/bin/teradata-cli

Roadmap
--------------------------
* Tests!
* REPL support
* Automated install via homebrew