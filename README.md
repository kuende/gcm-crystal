# GCM

Send push notifications to Android or iOS devices using [Google Cloud Messaging](https://developers.google.com/cloud-messaging/gcm).

This is a Crystal port of ruby [gcm](https://github.com/spacialdb/gcm) gem.

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  gcm:
    github: kuende/gcm-crystal
```

## Requirements

An Android device running 2.3 (or newer) or an iOS device and an API key as per GCM getting started guide.

## Usage

For your server to send a message to one or more devices, you must first initialise a new GCM class with your Api key, and then call the send method on this and give it 1 or more (up to 1000) registration tokens as an array of strings. You can also optionally send further HTTP message parameters like data or time_to_live etc. as a hash via the second optional argument to send.


```crystal
require "gcm"

gcm = GCM.new("my_api_key")

registration_ids= ["12", "13"] # an array of one or more client registration tokens
options = {
  "data": {
    "score": "123"
  },
  "collapse_key": "updated_score"
}
response = gcm.send(registration_ids, options)
```

Response is an object containing body, headers, status and canonical_ids/not_registered_ids. Check [here](https://developers.google.com/cloud-messaging/http#response) to see how to interpret the responses.

## Contributing

1. Fork it ( https://github.com/kuende/gcm-crystal/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request
