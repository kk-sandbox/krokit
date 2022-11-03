# Krokit: Tool to setup OpenGrok source code search engine

## Usage:
### `krokit [options]... /path/to/project/source`

Krokit makes it easy to set up the OpenGrok source code search engine.

## Command line options:
```
    -a  --add    <project-path>     -- Generate index and add project to Opengrok
    -d  --deploy <opengrok-package> -- Deploy Opengrok webapp to explore source code
    -D  --delete <project-name>     -- Delete project from Opengrok indexing
    -i  --init                      -- Initial setup to download and install dependencies
    -l  --list                      -- List deployed projects in Opengrok
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
2. Deploy Opengrok webapp
   - `$ krokit --deploy opengrok-1.5.12.tar.gz`
3. Added project to the Opengrok
   - `$ krokit --add    <project-path>`
4. List deployed projects
   - `$ krokit --list`
5. Delete project from the index
   - `$ krokit --delete <project-name>`
6. Refresh Opengrok index
   - `$ krokit --refresh`

Visit http://localhost:8080/source to explore the OpenGrok dashboard
