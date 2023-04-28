Unified Forecast System Gource Video Generator
==============================================

These configurable scripts generate a Gource visualization of the UFS
Weather Model and its components.

## Requirements

### Suggested Resolution

I strongly recommend generating the full-resolution (4k) video
since Google can't process lower resolutions effectively. Google will
convert this to lower-resolution videos. The 1080p (HD) video
Google generates is of high quality, and the 720p still allows usernames
to be clearly visible.

### System Requirements for Full Resolution Video

Most laptops are not suitable to run this. You need a workstation or
server. A full node on a cloud provider or supercomputer should be
sufficient.

For the 4k video:

- 32 GB of RAM
- 1 GB of disk
- a ton of CPU
- ideally, a high-end GPU (or several tons of CPU)

The development machine had 96 GB of RAM, 16 Intel Skylake physical
cores (32 logical), one NVIDIA 2080 GPU with 8GB of video RAM, and an
NVMe drive. It took 43 minutes to generate the full-resolution video.

### Software Requirements

1. Bash
2. Imagemagick, if a logo is used
3. Gource 0.47 or newer
4. ffmpeg - converts from Gource ppm stream to mp4
5. libx264 - an h264 codec for ffmpeg, used for an intermediate file
6. libx265 - an h265 codec for ffmpeg, used for the final file
7. xvfb-run - a headless X11 server; reduces choppiness
8. /usr/bin/python - any version; only used for floating-point calculations of font sizes and durations

## UFS Logo Usage Restrictions

Although this software is CC0 (public domain), the UFS logo
in `UFS-logo-recolored-150dpi.png` has usage restrictions. It is a
trademark, and the CC0 public domain declaration does not release
trademark rights. Read the LICENSE.md for details. Do not use the
UFS logo without permission from the UFS Community
(https://ufscommunity.org). Read `UFS-logo-recolored-150dpi.license`
for details.

## Instructions

1. Clone the UFS Weather Model recursively: `git clone --recursive https://github.com/ufs-community/ufs-weather-model`
2. Generate the combined commit log: `./make-commit-log.sh $PWD/ufs-weather-model`
3. Run Gource: `./run-gource.sh -i $PWD/ufs-weather-model/combined.log`

To get a logo in the lower-right corner, use the `-l` option:

```
./run_gource.sh -l /path/to/logo.png -i $PWD/ufs-weather-model/combined.log
```

You can specify alternative resolutions and output file
directories. This will render a 1440p video in `/path/to/output.mp4`:

```
./run_gource.sh -o /path/to/output.mp4 -p 1440 -i $PWD/ufs-weather-model/combined.log
```

The UFS logo is in `UFS-logo-recolored-150dpi.png`. Do not use it
without permission of the UFS Community (https://ufscommunity.org).

There are many other options in the script, detailed by its usage message.

### Implementation Notes

I strongly recommend generating the video at 2160p (4K) viewing the
video at 1080p (HD) or higher. The usernames are still clearly visible
at 720p, but the directory names are hard to read. It looks
spectacular at 4k on a 4k monitor.

By default, the scripts do not include the UFS logo. You have to
provide the path to the logo to the "-l" option. The logo is a UFS
trademark and cannot be used without the permission of the UFS
Community (https://ufscommunity.org).

Google Drive and Google Photos will only display videos at 360p, 720p,
and 1080p. If this is uploaded to youtube, it'll be viewable at
resolutions from 180p to 2160p (4k).

It takes Google Drive a few hours to display a newly-uploaded video at
1080p. This is because Google re-processes the videos using their
internal software. You can expect similar delays on youtube, for the
same reason.

Gource's bloom (the glow around nodes) reduces compression artifacts
and improves the compression ratio. It is most effective when rendered
at full resolution (2160p AKA 4k).

Although I'm calling 4k "full resolution," you can generate higher-resolution
videos. Make sure you only use standard resolutions such as 4320p (8k).
Otherwise, Google won't know what to do with the video and you may get
unexpected results.
