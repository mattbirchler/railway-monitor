# Railway Monitor

A macOS menu bar app for monitoring your [Railway](https://railway.com) projects, deployments, and billing at a glance.

## Features

- **Menu bar integration** — Lives in your menu bar with an optional current-period cost display.
- **Billing overview** — See your current usage, credit balance, and billing period.
- **Project list** — View all projects and services in your workspace.
- **Deployment status** — Track recent deployments with real-time status indicators.
- **Multi-workspace support** — Switch between workspaces if your token has access to more than one.
- **Auto-refresh** — Configurable refresh interval (1–30 minutes).
- **Launch at login** — Optionally start Railway Monitor when you log in.
- **Secure** — Your API token is stored in the macOS Keychain.

## Requirements

- macOS 14.0 (Sonoma) or later
- A [Railway](https://railway.com) account
- A Railway API token

## Setup

1. Clone this repository and open `Railway Monitor.xcodeproj` in Xcode.
2. Build and run the project (Cmd+R).
3. Click the train icon in your menu bar.
4. Enter your Railway API token. You can create one at [railway.com/account/tokens](https://railway.com/account/tokens).

## Building

This project has no external dependencies. Open the Xcode project and build with Cmd+B.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
