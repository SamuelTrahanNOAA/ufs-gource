Unified Forecast System Gource Video Generator
==============================================

These scripts generate a 4k Gource visualization video of the UFS
Weather Model and its components.

### Requirements

Most laptops are not suitable to run this. You need a workstation or server.

- 32 GB of RAM
- 1 GB of disk
- a ton of CPU

Software requirements:

1. Bash
2. Imagemagick, if a logo is used
3. Gource 0.47 or newer
4. ffmpeg - converts from Gource ppm stream to mp4
5. libx264 - an h264 codec for ffmpeg, used for an intermediate file
6. libx265 - an h265 codec for ffmpeg, used for the final file
7. xvfb-run - a headless X11 server; reduces choppiness
8. /usr/bin/python (2 or 3) - used for floating-point calculations of font sizes and durations

### Instructions

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
without permission of the UFS Community.

There are many other options in the script, detailed by its usage message.