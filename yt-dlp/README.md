# bash-things - yt-dlp

Script for downloading videos and playlists from files containing URLs.

Using [yt-dlp (github.com)](https://github.com/yt-dlp/yt-dlp).

## Usage

```shell
$ ./download -h

[Script] [Info] Usage: -f FILENAME -v|-s [-u] [-p] [-h]
	-f	Speficy file from which to read URLs
	-v	Download best video and audio combined
	-s	Only download audio
	-u	Login with this account ID
	-p	Account password. If this option is left out, yt-dlp will ask interactively
	-h	Print this help string
```

### Example

```shell
$ ./download -s -f music-playlist.txt
```

Will download the sound only files of all videos in the `music-playlist.txt` file and save them to `/music-playlist/`

