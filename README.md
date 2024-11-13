[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

# DLSPhoebus

A container for launching CSS Phoebus with the configuration we want.

Here we package the config files - e.g classes and colours, and publish them alongside phoebus in a container.

Usage: `phoebus-launch.sh [options]`

Options:
  `--bobfiles <dirs>`    Comma-separated list of directories to mount
  `--help`               Shows a help message.

All directories passed in `--bobfiles` as well as the user directory, are mounted in `/phoebus` in the container. The `/tmp` is mounted in `/tmp`.


Source          | <https://github.com/evalott100/DLSPhoebus>
:---:           | :---:
Releases        | <https://github.com/evalott100/DLSPhoebus/releases>
