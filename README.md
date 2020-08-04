<h1 align="center">Gdindex downloader</h1>
<p align="center">
<a href="https://github.com/Akianonymus/gdindex-downloader/actions"><img alt="Github Action Checks" src="https://img.shields.io/github/workflow/status/Akianonymus/gdindex-downloader/Checks/master?label=CI%20Checks&style=for-the-badge"></a>
</p>
<p align="center">
<a href="https://github.com/Akianonymus/gdindex-downloader/blob/master/LICENSE"><img src="https://img.shields.io/github/license/Akianonymus/gdindex-downloader.svg?style=for-the-badge" alt="License"></a>
</p>

> gdindex-downloader is a collection of bash compliant scripts to download gdindex files and folders.

- Minimal
- Download gdindex files and folders
  - Download subfolders
- Resume Interrupted downloads
- Parallel downloading
- Pretty logging
- Easy to install and update
  - Auto update
- Authentication support
  - Save credentials for automatic authentication ( see --setup flag )
  - maintain authentication for multiple urls

## Table of Contents

- [Compatibility](#compatibility)
  - [Linux or MacOS](#linux-or-macos)
  - [Android](#android)
  - [iOS](#ios)
  - [Windows](#windows)
- [Installing and Updating](#installing-and-updating)
  - [Native Dependencies](#native-dependencies)
  - [Installation](#installation)
    - [Basic Method](#basic-method)
    - [Advanced Method](#advanced-method)
  - [Updation](#updation)
- [Usage](#usage)
  - [Download Script Custom Flags](#download-script-custom-flags)
  - [Multiple Inputs](#multiple-inputs)
  - [Resuming Interrupted Downloads](#resuming-interrupted-downloads)
- [Uninstall](#Uninstall)
- [Reporting Issues](#reporting-issues)
- [Contributing](#contributing)
- [License](#license)

## Compatibility

As this repo is bash compliant, there aren't many dependencies. See [Native Dependencies](#native-dependencies) after this section for explicitly required program list.

### Linux or MacOS

For Linux or MacOS, you hopefully don't need to configure anything extra, it should work by default.

### Android

Install [Termux](https://wiki.termux.com/wiki/Main_Page).

Then, `pkg install curl` and done.

It's fully tested for all usecases of this script.

### iOS

Install [iSH](https://ish.app/)

While it has not been officially tested, but should work given the description of the app. Report if you got it working by creating an issue.

### Windows

Use [Windows Subsystem](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

Again, it has not been officially tested on windows, there shouldn't be anything preventing it from working. Report if you got it working by creating an issue.

## Installing and Updating

### Native Dependencies

The script explicitly requires the following programs:

| Program       | Role In Script                                         |
| ------------- | ------------------------------------------------------ |
| bash          | Execution of script                                    |
| curl          | All network requests in the script                     |
| xargs         | For parallel downloading                               |
| mkdir         | To create folders                                      |
| rm            | To remove temporary files                              |
| grep          | Miscellaneous                                          |
| sed           | Miscellaneous                                          |

### Installation

You can install the script by automatic installation script provided in the repository.

Default values set by automatic installation script, which are changeable:

**Repo:** `Akianonymus/gdindex-downloader`

**Command name:** `idl`

**Installation path:** `$HOME/.gdindex-downloader`

**Source value:** `master`

**Shell file:** `.bashrc` or `.zshrc` or `.profile`

For custom command name, repo, shell file, etc, see advanced installation method.

**Now, for automatic install script, there are two ways:**

#### Basic Method

To install gdindex-downloader in your system, you can run the below command:

```shell
curl --compressed -s https://raw.githubusercontent.com/Akianonymus/gdindex-downloader/master/install.sh | bash -s
```

and done.

#### Advanced Method

This section provides information on how to utilise the install.sh script for custom usescases.

These are the flags that are available in the install.sh script:

<details>

<summary>Click to expand</summary>

-   <strong>-p | --path <dir_name></strong>

    Custom path where you want to install the script.

    ---

-   <strong>-c | --cmd <command_name></strong>

    Custom command name, after installation, script will be available as the input argument.

    ---

-   <strong>-r | --repo <Username/reponame></strong>

    Install script from your custom repo, e.g --repo Akianonymus/gdindex-downloader, make sure your repo file structure is same as official repo.

    ---

-   <strong>-b | --branch <branch_name></strong>

    Specify branch name for the github repo, applies to custom and default repo both.

    ---

-   <strong>-s | --shell-rc <shell_file></strong>

    Specify custom rc file, where PATH is appended, by default script detects .zshrc, .bashrc. and .profile.

    ---

-   <strong>-t | --time 'no of days'</strong>

    Specify custom auto update time ( given input will taken as number of days ) after which script will try to automatically update itself.

    Default: 5 ( 5 days )

    ---

-   <strong>--skip-internet-check</strong>

    Do not check for internet connection, recommended to use in sync jobs.

    ---

-   <strong>-D | --debug</strong>

    Display script command trace.

    ---

-   <strong>-h | --help</strong>

    Display usage instructions.

    ---

Now, run the script and use flags according to your usecase.

E.g:

```shell
curl --compressed -s https://raw.githubusercontent.com/Akianonymus/gdindex-downloader/master/install.sh | bash -s -- -r username/reponame -p somepath -s shell_file -c command_name -b branch_name
```
</details>

### Updation

If you have followed the automatic method to install the script, then you can automatically update the script.

There are three methods:

1.  Use the script itself to update the script.

    `idl -u or idl --update`

    This will update the script where it is installed.

    <strong>If you use the this flag without actually installing the script,</strong>

    <strong>e.g just by `bash idl.sh -u` then it will install the script or update if already installed.</strong>

1.  Run the installation script again.

    Yes, just run the installation script again as we did in install section, and voila, it's done.

1.  Automatic updates

    By default, script checks for update after 3 days. Use -t / --time flag of install.sh to modify the interval.

    An update log is saved in "${HOME}/.gdindex-downloader/update.log".

**Note: Above methods always obey the values set by user in advanced installation,**
**e.g if you have installed the script with different repo, say `myrepo/gdindex-downloader`, then the update will be also fetched from the same repo.**

## Usage

After installation, no more configuration is needed.

`idl gdindex_url`

Script supports argument as gdindex_url, given those should be publicly available.

Now, we have covered the basics, move on to the next section for extra features and usage, like skipping sub folders, parallel downloads, etc.

### Download Script Custom Flags

These are the custom flags that are currently implemented:

-   <strong>--setup</strong>

    Setup authentication for gdindex urls.

    ---

-   <strong>--auth username password</strong>

    Specify username and password for given url.

    ---

-   <strong>-d | --directory 'foldername'</strong>

    Custom workspace folder where given input will be downloaded.

    ---

-   <strong>-s | --skip-subdirs</strong>

    Skip downloading of sub folders present in case of folders.

    ---

-   <strong>-p | --parallel <no_of_files_to_parallely_download></strong>

    Download multiple files in parallel.

    Note:

    - This command is only helpful if you are downloding many files which aren't big enough to utilise your full bandwidth, using it otherwise will not speed up your download and even error sometimes,
    - 5 to 10 value is recommended. If errors with a high value, use smaller number.
    - Beaware, this isn't magic, obviously it comes at a cost of increased cpu/ram utilisation as it forks multiple bash processes to download ( google how xargs works with -P option ).

    ---

-   <strong>--speed 'speed'</strong>

    Limit the download speed, supported formats: 1K, 1M and 1G.

    ---

-   <strong>-l | --log 'log_file_name'</strong>

    Save downloaded files info to the given filename.

    ---

-   <strong>-v | --verbose</strong>

    Display detailed message (only for non-parallel uploads).

    ---

-   <strong>--skip-internet-check</strong>

    Do not check for internet connection, recommended to use in sync jobs.

    ---

-   <strong>-V | --version</strong>

    Show detailed info, only if script is installed system wide.

    ---

-   <strong>-u | --update</strong>

    Update the installed script in your system, if not installed, then install.

    ---

-   <strong>--uninstall</strong>

    Uninstall the installed script in your system.

    ---

-   <strong>-h | --help</strong>

    Display usage instructions.

    ---

-   <strong>-D | --debug</strong>

    Display script command trace.

    ---

### Multiple Inputs

You can use multiple inputs without any extra hassle.

Pass arguments normally, e.g: `idl url1 url2`

where url1 and url2 is drive urls.

### Resuming Interrupted Downloads

Downloads interrupted either due to bad internet connection or manual interruption, can be resumed from the same position.

You can interrupt many times you want, it will resume ( hopefully ).

It will not download again if file is already present, thus avoiding bandwidth waste.

## Uninstall

If you have followed the automatic method to install the script, then you can automatically uninstall the script.

There are two methods:

1.  Use the script itself to uninstall the script.

    `idl --uninstall`

    This will remove the script related files and remove path change from shell file.

1.  Run the installation script again with -U/--uninstall flag

    ```shell
    curl --compressed -s https://raw.githubusercontent.com/Akianonymus/gdindex-downloader/master/install.sh | bash -s -- --uninstall
    ```

    Yes, just run the installation script again with the flag and voila, it's done.

**Note: Above methods always obey the values set by user in advanced installation.**

## Reporting Issues

| Issues Status | [![GitHub issues](https://img.shields.io/github/issues/Akianonymus/gdindex-downloader.svg?label=&style=for-the-badge)](https://GitHub.com/Akianonymus/gdindex-downloader/issues/) | [![GitHub issues-closed](https://img.shields.io/github/issues-closed/Akianonymus/gdindex-downloader.svg?label=&color=success&style=for-the-badge)](https://GitHub.com/Akianonymus/gdindex-downloader/issues?q=is%3Aissue+is%3Aclosed) |
| :-----------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: |

Use the [GitHub issue tracker](https://github.com/Akianonymus/gdindex-downloader/issues) for any bugs or feature suggestions.

## Contributing

| Total Contributers | [![GitHub contributors](https://img.shields.io/github/contributors/Akianonymus/gdindex-downloader.svg?style=for-the-badge&label=)](https://GitHub.com/Akianonymus/gdindex-downloader/graphs/contributors/) |
| :----------------: | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: |

| Pull Requests | [![GitHub pull-requests](https://img.shields.io/github/issues-pr/Akianonymus/gdindex-downloader.svg?label=&style=for-the-badge&color=orange)](https://GitHub.com/Akianonymus/gdindex-downloader/issues?q=is%3Apr+is%3Aopen) | [![GitHub pull-requests closed](https://img.shields.io/github/issues-pr-closed/Akianonymus/gdindex-downloader.svg?label=&color=success&style=for-the-badge)](https://GitHub.com/Akianonymus/gdindex-downloader/issues?q=is%3Apr+is%3Aclosed) |
| :-----------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: |

Submit patches to code or documentation as GitHub pull requests. Make sure to run format.sh before making a new pull request.

## License

[UNLICENSE](https://github.com/Akianonymus/gdindex-downloader/blob/master/LICENSE)
