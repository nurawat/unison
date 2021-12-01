# Unison Script

The `unison script` will help with synchronize the folders in multiple DC/Server, This script can be used for multiple directories as well.

## Getting Started
This guide is for `unison script` version 1.0.0

### Requirements
This `unison script` cli works only with the following requirement(s):
- unison tool(rpm) should be installed on servers
- A user with the same id across multiple server should exist which will be used to sync the folders/servers
- SSH port should be opened b/w servers
- A directory structure inbetween server with same user as directory owner

### Stakeholders
The following individuals have a material interest in the state of this module and must be directly notified whenever changes to the production (master) branch are made:

* Arun Rawat <RawatArun65@gmail.com>
### Limitations
And here goes the limitation(s):
- `unison script` is created to sync folders in between multiple servers, its written in shell script and doesn't have any limitation till now.


### Installation
The easiest way to install is - On your terminal run the following commands -

using git clone with https(no private key setup)

Navigate to the directory where you want to copy the script/folder

    ❯ git clone https://github.com/nurawat/unison.git

or using git clone with ssh

    ❯ git clone git@github.com:nurawat/unison.git

Update the Folders(if Required)
In the script navigate to `directory_paths` variable and update it with the folders that needs to be sync'd

> you are good to go.

### Note and Usages:
on your Linux based environment -- proper permissions needs to be provided in the `usage`.

Usage Guide:
`sh syncScript.sh Options`.

    OPTIONS:
      Unison Lock Folder Path e.g. /nfs_share
      Server List - File which will have Entry for the DC
        server.txt -
            dc1=dc1_servers1.fairisaac.com,dc1_servers2.fairisaac.com
            dc2=dc2_servers1.fairisaac.com,dc2_servers2.fairisaac.com
            dc3=dc3_servers1.fairisaac.com,dc3_servers2.fairisaac.com

    Update the Directory_Paths variable with the list of directories to Sync
    directory_paths="/some/folder/path/
        /some/folder/paths
        /some/folder/pathss

    mail_id="YOUR EMAIL ID"

`To Change  The Folders to Sync`.
- Go to Script [syncScript.sh](syncScript.sh)
- Find the variable `directory_paths`
- Change the Values for the variables  with folder path.
- You are good to go

### Basic Commands
You are run the following commands in order to run the script.

    ❯ syncScript.sh /nfs_path server_list

for help message

    Usage:
    syncScript.sh <COMMAND>
    syncScript.sh [OPTIONS]

### Common Acronyms
    [INFO]     - [INFORMATION]: Related to What the Script is Doing
    [ERR]      - [ERROR] - Mostly Because Script is Given Wrong Inputs
    [END]      - [END]: Script executing end
    [SUCCESS]  - [SUCCESS]: SUCCESS Alert
    [FAILURE]  - [FAILURE]: FAILURE Alert

## More Resources
- https://github.com/bcpierce00/unison/wiki/Downloading-Unison
- https://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html
- https://www.cis.upenn.edu/~bcpierce/unison/
