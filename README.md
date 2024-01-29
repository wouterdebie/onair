# Onair

Command line utility that calls an [IFTTT](https://ifttt.com) webhook when any webcam turns on or off.

See it in action in [this video](https://photos.app.goo.gl/KkNWri8MQts85ScP8). I'm using an [eMylo smart relay](https://www.amazon.com/gp/product/B07FPCJ1L4/ref=ppx_yo_dt_b_search_asin_title?ie=UTF8&psc=1) inside an [On Air](https://www.amazon.com/gp/product/B00JFL0F6Y/ref=ppx_yo_dt_b_search_asin_title?ie=UTF8&psc=1) light. The [eMylo smart relay](https://www.amazon.com/gp/product/B07FPCJ1L4/ref=ppx_yo_dt_b_search_asin_title?ie=UTF8&psc=1) is compatible with the [Brilliant Smart App](https://play.google.com/store/apps/details?id=com.brilliantlighting.brain&hl=en_US) that in turn integrates with [IFTTT](https://ifttt.com/brilliant_smart)
## Background

I built this utility to toggle an "On Air" sign outside my home office when I'm on video conference calls. The utility will monitor every camera connected and will trigger configured IFTTT webhook events when any camera turns on, or when all turn off.

Since I use a laptop that I travel with, this utility supports taking optional `--local-url` and `--local-string` parameters that enable checking if you're on a local network or not. In my case, the HTML from my local router contains a reference to my local WiFi SSID, which tells me I'm home.

## Usage
```
USAGE: onair --on <event> --off <event> --key <key> [--local-url <url>] [--local-string <string>]

OPTIONS:
  --key            IFTTT Webhook key
  --local-string   (optional) String to look for to see if local
  --local-url      (optional) URL to call to see if local
  --ignore         (optional) Comma-separated list of cameras to ignore
  --off            IFTTT Webhook event to call when a camera turns off
  --on             IFTTT Webhook event to call when a camera turns on
  --help           Display available options
```

## Build
```
$ swift build -c release
$ cp .build/release/onair ~/bin
```

## Setup
- Create two [IFTTT](https//iftttt.com) applets that trigger on a [Webhook](https://ifttt.com/maker_webhooks); one that you want to trigger when any webcam turns on and one that you want to trigger when all webcams are off. The event names for both webhooks will be used as `--on` and `--off` parameter values.
- Look up your webhook key at [Webhook](https://ifttt.com/maker_webhooks) --> Documentation. Use this as the `--key` parameter value.
- In case you want to enable checking if you're on a local network or not, use the `--local-url` parameter to specify a local url you'd like to check (e.g. your router) and use `--local-string` to specify what string you want to check for to determine if you're on a local network or not.
- Some virtual devices will automatically be skipped, since they always report to be on. In case you happen to have a virtual camera that is not detected correctly, use `--ignore` to ignore that specific camera.

## Example launchd configuration
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>nl.evenflow.onair</string>
  <key>OnDemand</key>
  <false/>
  <key>Program</key>
  <string>/Users/wouterdebie/bin/onair</string>
  <key>ProgramArguments</key>
  <array>
      <string>/Users/wouterdebie/bin/onair</string>
      <string>--on</string>
      <string>on_air</string>
      <string>--off</string>
      <string>off_air</string>
      <string>--key</string>
      <string>MY_SECRET_IFTTT_KEY</string>
      <string>--local-url</string>
      <string>http://192.168.0.1/</string>
      <string>--local-string</string>
      <string>MY_SSID</string>
  </array>
</dict>
</plist>
```
