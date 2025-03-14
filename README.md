# Zpotify

[![Build Status](https://github.com/hosackm/zpotify/actions/workflows/zig-ci.yml/badge.svg)](https://github.com/hosackm/zpotify/actions/workflows/zig-ci.yml)

This is a zig module for interacting with the Spotify [Web API](https://developer.spotify.com/web-api/).

By using this library you agree to [Spotify's Developer Terms of Use](https://developer.spotify.com/developer-terms-of-use/).

## Installation

To use the module, run the following command to save it as a dependency:

```bash
zig fetch --save git+https://github.com/hosackm/zpotify.git
```

And add the module to your `build.zig` to import the dependency:

```zig
const zpotifty = b.dependency("zpotify", .{});
exe.root_module.addImport("zpotify", zpotify);
```

## Examples

Examples of the API can be found in the [examples](/examples) directory. The list of available examples can be found in [build.zig](build.zig).

To build one run:

```bash
zig build examples -Dexample=playlist
```

Or to build all, run:

```bash
zig build examples -Dexample=all
```

### Authentication

The example [auth.zig](/examples/auth.zig) shows the authorization process laid out in Spotify's [Documentation](https://developer.spotify.com/documentation/web-api/concepts/authorization). The example assumes that you've already created an application through the Spotify [Developer Dashboard](https://developer.spotify.com/dashboard).


You can run it using:
```bash
zig build examples -Dexample=auth
```

After following the URL and logging in, a token will be provided and printed as output. This token should be stored for use in your application.

### Credentials

The examples require your Spotify credentials to be stored as environment variables, but again, you can store these however suits your needs in your application. The following variables must be set to run the examples:

|                      |                                            |
|----------------------|--------------------------------------------|
| `ZPOTIFY_ID`         | Your application's `client_id`             |
| `ZPOTIFY_SECRET`     | Your application's `secret_key`            |
| `ZPOTIFY_REDIRECT`   | Your application's `redirect_uri`          |
| `ZPOTIFY_TOKEN_FILE` | Path to a file containing the token acquired when successfully logging in with auth.zig |

### Creating a Client

The example module [client.zig](/examples/client.zig) shows how to exchange the Spotify credentials for a token that can be used to initialize a client. This client can authenticate requests and refresh the provided token when it expires.

## Tests

There are two groups of tests provided:

1. Unit tests (`zig build unit`) which test the `zpotify` module
2. Integration tests (`zig build test`) which test if the module can consume real-world content

### Unit Tests

To run the unit tests, run the following command:

```bash
zig build unit
```

This will execute the test and (if they pass) will return a code of 0.

Or to install the unit test executable you can run:

```bash
zig build unit install

# then you can run with verbose output
./zig-out/bin/unit_tests 2>&1 | cat
```

### Integration Tests

To run the unit tests, run the following command:

```bash
zig build test
```
This will execute the tests and (if they pass) will return a code of 0.

Or to install the test executable you can run:

```bash
zig build test install

# then you can run with verbose output
./zig-out/bin/run_tests 2>&1 | cat
```

## Todo

Currently, 75 of the 84 [endpoints](https://developer.spotify.com/web-api/endpoint-reference/) are supported.

- [ ] Transfer Playback
- [ ] Get Recently Played Tracks
- [ ] Get the User's Queue
- [ ] Add Item to Playback Queue
- [ ] Create Playlist
- [ ] Get Featured Playlists
- [ ] Get Category's Playlists
- [ ] Get Playlist Cover Image
- [ ] Add Custom Playlist Cover Image

- [x] ~~Get Several Browse Categories~~
- [x] ~~Get Single Browse Category~~
- [x] ~~Search for Item~~
- [x] ~~Set Repeat Mode~~
- [x] ~~Set Playback Volume~~
- [x] ~~Toggle Playback Shuffle~~
- [x] ~~Seek To Position~~
- [x] ~~Get Current User's Playlists~~
- [x] ~~Get User's Playlists~~
- [x] ~~Change Playlist Details~~
- [x] ~~Add Items to Playlist~~
- [x] ~~Remove Playlist Items~~
- [x] ~~Get Playlist Items~~
- [x] ~~Get Playlist~~
- [x] ~~Update Playlist Items~~
- [x] ~~Get Available Devices~~
- [x] ~~Get Currently Playing Track~~
- [x] ~~Start/Resume Playback~~
- [x] ~~Pause Playback~~
- [x] ~~Skip To Next~~
- [x] ~~Skip To Previous~~
- [x] ~~Get Playback State~~
- [x] ~~Get Album~~
- [x] ~~Get Several Albums~~
- [x] ~~Get Album Tracks~~
- [x] ~~Get User's Saved Albums~~
- [x] ~~Save Albums for Current User~~
- [x] ~~Remove Users' Saved Albums~~
- [x] ~~Check User's Saved Albums~~
- [x] ~~Get New Releases~~
- [x] ~~Get Artist~~
- [x] ~~Get Several Artists~~
- [x] ~~Get Artist's Albums~~
- [x] ~~Get Artist's Top Tracks~~
- [x] ~~Get Artist's Related Artists~~
- [x] ~~Get an Audiobook~~
- [x] ~~Get Several Audiobooks~~
- [x] ~~Get Audiobook Chapters~~
- [x] ~~Get User's Saved Audiobooks~~
- [x] ~~Save Audiobooks for Current User~~
- [x] ~~Remove User's Saved Audiobooks~~
- [x] ~~Check User's Saved Audiobooks~~
- [x] ~~Get a Chapter~~
- [x] ~~Get Several Chapters~~
- [x] ~~Get Episode~~
- [x] ~~Get Several Episodes~~
- [x] ~~Get User's Saved Episodes~~
- [x] ~~Save Episodes for Current User~~
- [x] ~~Remove User's Saved Episodes~~
- [x] ~~Check User's Saved Episodes~~
- [x] ~~Get Available Genre Seeds~~
- [x] ~~Get Available Markets~~
- [x] ~~Get Show~~
- [x] ~~Get Several Shows~~
- [x] ~~Get Show Episodes~~
- [x] ~~Get User's Saved Shows~~
- [x] ~~Save Shows for Current User~~
- [x] ~~Remove User's Saved Shows~~
- [x] ~~Check User's Saved Shows~~
- [x] ~~Get Track~~
- [x] ~~Get Several Tracks~~
- [x] ~~Get User's Saved Tracks~~
- [x] ~~Save Tracks for Current User~~
- [x] ~~Remove User's Saved Tracks~~
- [x] ~~Check User's Saved Tracks~~
- [x] ~~Get Current User's Profile~~
- [x] ~~Get User's Top Items~~
- [x] ~~Get User's Profile~~
- [x] ~~Follow Playlist~~
- [x] ~~Unfollow Playlist~~
- [x] ~~Get Followed Artists~~
- [x] ~~Follow Artists or Users~~
- [x] ~~Unfollow Artists or Users~~
- [x] ~~Check If User Follows Artists or Users~~
- [x] ~~Check if Current User Follows Playlist~~
