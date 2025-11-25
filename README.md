# Bash Screensavers

![Logo](spotlight/logos/logo.320x160.png)

Welcome to **Bash Screensavers**, a collection of animated ASCII art for your terminal. This project brings classic screensaver fun to the command line, written entirely in `bash`.

This fork builds upon the original by introducing performance optimizations for macOS, new visualizers, and enhanced features to ensure a seamless experience.

[Key Features](#key-features) -
[Gallery](#gallery) -
[Quickstart](#quickstart) -
[Contributing](#contributing) -
[Spotlight](#spotlight)

[![Release](https://img.shields.io/github/v/release/attogram/bash-screensavers?style=flat)](https://github.com/attogram/bash-screensavers/releases)
[![License](https://img.shields.io/github/license/attogram/bash-screensavers?style=flat)](./LICENSE)
![Bash ≥3.2](https://img.shields.io/badge/bash-%3E=3.2-blue?style=flat)

## Key Features

*   **Pure Bash:** No external dependencies required, just a `bash` shell (v3.2+).
*   **macOS Optimizations:** The main script is optimized for macOS, ensuring smooth performance and compatibility.
*   **Automatic `caffeinate`:** On macOS, the script automatically uses `caffeinate -d` to prevent the display from sleeping, allowing for an uninterrupted screensaver experience.
*   **Perlin Noise Engine:** Includes a custom-built, integer-based Perlin noise implementation written in pure Bash, powering generative animations like "Dunes".
*   **New Screensaver: Dunes:** A mesmerizing, animated landscape generated using Perlin noise, creating the illusion of rolling sand dunes.

## Gallery

The [Gallery README](./gallery/README.md) has details on all available screensavers.

[![Dunes](gallery/dunes/dunes.gif)](./gallery/README.md)

## Quickstart

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/attogram/bash-screensavers.git
    cd bash-screensavers
    ```

2.  **Run the main script:**
    ```bash
    ./screensaver.sh
    ```
    This will display a menu where you can choose a screensaver.

## Command-Line Usage

You can also run screensavers directly from the command line.

| Command                           | Description                            |
| --------------------------------- | -------------------------------------- |
| `./screensaver.sh`                | Show the interactive menu.             |
| `./screensaver.sh <name>`         | Run a specific screensaver by name.    |
| `./screensaver.sh <number>`       | Run a specific screensaver by number.  |
| `./screensaver.sh -r`             | Start a random screensaver.            |
| `./screensaver.sh -h`             | Display the help message.              |
| `./screensaver.sh -v`             | Show the current version.              |
| `./gallery/<name>/<name>.sh`      | Run a screensaver script directly.     |

## Contributing

Contributions are welcome! If you have an idea for a new screensaver or an improvement, please see [CONTRIBUTING.md](./CONTRIBUTING.md). AI assistants and creative coders are encouraged to participate.

## Project Structure

*   **[Gallery](./gallery/README.md):** Contains all the screensaver scripts.
*   **[Jury](./jury/README.md):** The testing suite that ensures everything works as expected.
*   **[Library](./library/README.md):** Supporting scripts and functions.
*   **[Spotlight](./spotlight/README.md):** Tools for creating previews and marketing materials.

---

*Made with ❤️ and a lot of bash.*
