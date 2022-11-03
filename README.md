# Krokit: Tool to setup OpenGrok source code search engine

## Usage:
### `krokit [options]... /path/to/project/source`

Krokit makes it easy to setup OpenGrok source code search engine.

## Command line options:
```
    -a  --add    <project-path>     -- Generate index and add project to opengrok
    -d  --deploy <opengrok-package> -- Deploy Opengrok before adding projects
    -D  --delete <project-name>     -- Delete project from Opengrok indexing
    -i  --init                      -- Initial setup to download and install dependencies
    -r  --refresh                   -- Refresh Opengrok indexer
    -V  --verbose                   -- Enable verbose mode
    -v  --version                   -- Print package version
    -h  --help                      -- Show this help menu
```
### Requirements:
	 OpenGrok <= 1.5.12, OpenJRE-8 and Tomcat-9 servelet
### Demo:
1. Initialize the setup
   - `$ krokit --init` 
2. Deploy Opengrok package
   - `$ krokit --deploy opengrok-1.5.12.tar.gz`
3. Added project to the webapp
   - `$ krokit --add    <project-path>`
4. Delete project from the webapp
   - `$ krokit --delete <project-name>`
5. Refresh Opengrok index
   - `$ krokit --refresh`

Visit http://localhost:8080/source to explore the OpenGrok dashboard
