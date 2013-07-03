Description
-------------------------
A lightweight OSX/Linux command line utility for the [Teradata](http://www.teradata.com/) database server modeled after the Postgres [psql](http://www.postgresql.org/docs/9.2/static/app-psql.html) utility. Built with JRuby to take advantage of JDBC interoperability.


Installation Instructions
-------------------------
* Ensure rvm and jruby are installed
* Make sure teradata_cli has execute permissions: 
  chmod +x teradata-cli
* Create a symlink in /usr/local/bin replacing "~/src" with your clone path:
  ln -s ~/src/teradata-cli/teradata-cli /usr/local/bin/teradata-cli

Usage
--------------------------
Type teradata-cli --help for a list of parameters.
DB connection information can be provided either with the individual command line args --host, --username, and --password or a path to a yaml file via the --creds arg. The format of the creds file is like so:

```yaml
host: [db_host_name]
username: [db_username]
password: [db_password]
```

Roadmap
--------------------------
* Tests!
* REPL support
* Automated install via homebrew