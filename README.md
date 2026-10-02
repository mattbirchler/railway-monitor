# Railway Monitor

A macOS menu bar app for keeping an eye on your cloud spend. It started as a [Railway](https://railway.com) monitor and now also tracks DigitalOcean and OpenRouter, with a combined current-period total in the menu bar.

## Supported services

| Service | What you see | Credential |
| --- | --- | --- |
| **Railway** | Current usage, credit balance, billing period, projects, services, and recent deployments | API token from [railway.com/account/tokens](https://railway.com/account/tokens) |
| **DigitalOcean** | Month-to-date usage, outstanding balance or credit, and the last three invoices | Personal access token from [cloud.digitalocean.com/account/api/tokens](https://cloud.digitalocean.com/account/api/tokens). A read-only token with the `billing:read` scope is enough. |
| **OpenRouter** | Spend for the key today, this week, this month, and all time, plus any key spending limit | API key from [openrouter.ai/settings/keys](https://openrouter.ai/settings/keys). A management key additionally shows the account's total credit balance. |

Inworld was considered but has no public billing or usage API, so it is not supported. Usage for Inworld is only available on its web portal.

## Features

- **Menu bar integration**: Lives in your menu bar with an optional combined current-period cost display.
- **Per-service sections**: Each connected service gets its own section with the details above.
- **Connect what you use**: Add or remove services independently in Settings.
- **Multi-workspace support**: Switch between Railway workspaces if your token has access to more than one.
- **Auto-refresh**: Configurable refresh interval (1–30 minutes).
- **Launch at login**: Optionally start Railway Monitor when you log in.
- **Secure**: Every token is stored in the macOS Keychain.

## Requirements

- macOS 14.0 (Sonoma) or later
- An account with at least one of the supported services above

## Setup

1. Clone this repository and open `Railway Monitor.xcodeproj` in Xcode.
2. Build and run the project (Cmd+R).
3. Click the train icon in your menu bar.
4. Pick a service and enter its token. You can connect more services later from Settings.

## Building

This project has no external dependencies. Open the Xcode project and build with Cmd+B.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
