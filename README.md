# Screenshot-Uploader
Just a Bash script for uploading screenshots to the file sharing service: [Cumulonimbus](https://alekeagle.me/)

(Note: While this script was written for a specific service, it should work for basically anything that has a proper upload point as it just uses Curl to make a `POST` reqeust)

The bulk of the logic is actually making the mark at the bottom- the upload was the easy part :'3  
If you don't like the mark (see [example](/README.md#example) below), there's a [simplified version](/src/ssu-simple.sh) that just does the upload.

## Dependencies
- xdpyinfo
- scrot
- convert (part of the ImageMagick package)
- jq
- curl
- xclip

the script will automatically exit if it detects any one of these is not installed.

## Usage

```plaintext
chmod +x ssu.sh
./ssu.sh
```

then just select an area with the mouse, and you're done~! Just make sure you have a valid token.

## Example

<a href="https://alekeagle.me"><img src="https://cadeh.is-cute-and.gay/Pj_-el9IYB.png" alt="goofy goober"/></a> 
