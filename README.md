# vpn-lab
Complete VPN mobile and backend application written in Flutter and Phalcon Framework

## Overview
Extends a private network across a public network and enables users to send and receive data across shared or public networks as if their computing devices were directly connected to the private network. The benefits of a VPN include increases in functionality, security, and management of the private network. It provides access to resources that are inaccessible on the public network and is typically used for remote workers. Encryption is common, although not an inherent part of a VPN connection.
### Use cases
* Bypass geo-restrictions / censorship
* Avoid ISP monitoring
* Ensure general anonymity 
### Features
* Cross-platform mobile app
* OpenVPN support 
* Built-in VPN crawler (currently crawling www.vpngate.net)
* Simple VPN validator and filter
* Subscriptions support
* Beautiful design
* Registartion by mail with password recover
* VPN load calculation
* Feedback page
### What needs to be done
* Add support for another VPN protocols (such as Wireguard, IPSec/IKEv2, etc)
* Add full support of subsciptions on Android
* Add more VPN validators, so dead servers didn't come to clients
## Getting Started
### Requirements
* Android or IOS phone
* Linux server
* Phalcon 5.0.0RC3+
* PHP 8.1+
### Installation
#### Backend
Clone project:
```
git clone https://github.com/SamLatsin/icon-themer.git
```
Copy `src/backend` to your default site location (for example `/var/www/vpn-lab`).

Import `db snapshot/main.sql` to your Database.

Add all lines from `cron/crontab.txt` to your crontab.

Edit file `/var/www/vpn-lab/app/app.php` and put your Database credentials.

After all steps done you can check if API works, check [API documentation](https://sam-latsin.gitbook.io/vpn-lab-rest-api/).
#### Mobile
Clone project:
```
git clone https://github.com/SamLatsin/icon-themer.git
```
Open `src/mobile/vpn-lab` project in your IDE.
Edit `src/mobile/vpn_lab/lib/components/async_tasks.dart` and put your backaend domain name in 'domain' variable (NOTE: your backend should have SSL installed).

Now you can just build the project.

### Screenshots
<p float="left">
</p>

## License

Vpn-lab is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)
