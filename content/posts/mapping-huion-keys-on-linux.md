+++
title = "Mapping Huion Keys on Linux"
date = "2022-04-14T01:24:49+03:00"
author = "Timothy Karani"
authorTwitter = "c3n7_luc"
tags = ["krita", "drawing", "linux"]
keywords = ["krita", "drawing", "linux"]
description = "Using xsetwacom to map huion's tablet and pen buttons"
draft = false
+++

## Introduction

This post assumes you already have the tablet working and the `xsetwacom` command already exists on your linux installation.  
For this post I'll be mapping the buttons on my HS611 Tablet. A HS611 tablet has 8 buttons on the pad and 2 buttons on the stylus.

## Setting Things Up

Let us get the name of the graphics tablet:

```shell
$ xsetwacom --list
```

The command above gives the output below if the connected tablet is a HS611

```txt
HUION Huion Tablet_HS611 stylus         id: 15  type: STYLUS
HUION Huion Tablet_HS611 Pad pad        id: 16  type: PAD
HUION Huion Tablet_HS611 Touch Strip pad        id: 17  type: PAD
```

Of importance to us are `HUION Huion Tablet_HS611 stylus` and `HUION Huion Tablet_HS611 Pad pad`

## Mapping

Fire up your favorite text editor, and create bash script file with a name of your choice. For this post I'll choose `set_keys.sh`

_in **`set_keys.sh`:**_

```shell
#!/bin/sh

# PAD MAPPINGS
#top set
xsetwacom --set 'HUION Huion Tablet_HS611 Pad pad' Button 1 "key ctrl shift z"
xsetwacom --set 'HUION Huion Tablet_HS611 Pad pad' Button 2 "key ctrl z"
xsetwacom --set 'HUION Huion Tablet_HS611 Pad pad' Button 3 "key ctrl p"
xsetwacom --set 'HUION Huion Tablet_HS611 Pad pad' Button 8 "key ctrl shift ="
xsetwacom --set 'HUION Huion Tablet_HS611 Pad pad' Button 9 "key ctrl -"

#bottom set
# https://askubuntu.com/a/1193029
xsetwacom --set 'HUION Huion Tablet_HS611 Pad pad' Button 10 "key +ISO_Level3_Shift +9"
xsetwacom --set 'HUION Huion Tablet_HS611 Pad pad' Button 11 "key 4"
xsetwacom --set 'HUION Huion Tablet_HS611 Pad pad' Button 12 "key del"
xsetwacom --set 'HUION Huion Tablet_HS611 Pad pad' Button 13 "key 6"
xsetwacom --set 'HUION Huion Tablet_HS611 Pad pad' Button 14 "key +ISO_Level3_Shift +8"


# STYLUS MAPPINGS
# xsetwacom --set 'HUION Huion Tablet_HS611 stylus' Button 1 "key h" # on click
# button 1 on the stylus is triggerd when you tap the stylus tip on the tab. Simulates a "click" by default.
xsetwacom --set 'HUION Huion Tablet_HS611 stylus' Button 2 "key b"
xsetwacom --set 'HUION Huion Tablet_HS611 stylus' Button 3 "key e"
```

The mappings are configured with Krita in mind:

1. Pad Mappings:

   | Button    | Mapping                                               | Function            |
   | :-------- | :---------------------------------------------------- | :------------------ |
   | Button 1  | `Ctrl` + `Shift` + `Z`                                | Redo                |
   | Button 2  | `Ctrl` + `Z`                                          | Undo                |
   | Button 3  | `Ctrl` + `P`                                          | Pan Mode            |
   | Button 8  | `Ctrl` + `Shift` + `=` (equivalent to `ctrl` + `+`)   | Zoom In             |
   | Button 9  | `Ctrl` + `-`                                          | Zoom Out            |
   | --        | --                                                    | --                  |
   | Button 10 | `+ISO_Level3_Shift` + `+9` (aka `altgr` + `9` or `]`) | Increase brush size |
   | Button 11 | `4`                                                   | Rotate Left         |
   | Button 12 | `del`                                                 | Clear Canvas        |
   | Button 13 | `6`                                                   | Rotate Right        |
   | Button 14 | `+ISO_Level3_Shift` + `+8` (aka `altgr` + `8` or `[`) | Decrease brush size |

2. Stylus Mappings:

   | Button   | Mapping | Function    |
   | :------- | :------ | :---------- |
   | Button 1 | `b`     | Brush Tool  |
   | Button 2 | `e`     | Eraser Tool |

With that done, let us now give execution permissions to our script file:

```shell
$ chmod +x set_keys.sh
```

Now we can run the file every time we connect the tablet so as to map the keys:

```shell
$ ./set_keys.sh
```

Once you've mapped the keys, you can fire open Krita and draw to your heart's content :).

## Tips

You can view all mappable keys/modifires with the command below. Sometimes they don't map as we expect (example `[`, `]` and `+`), but with a bit of Googling you will find your solution:

```shell
$ xsetwacom --list modifiers
```

To test in a terminal which key is being input by the button after mapping, you could monitor either using the `xev` command or `showkey -a`.

Happy drawing :)

## Further Reading

- [Archlinux docs on Wacom Tablets](https://wiki.archlinux.org/title/Wacom_tablet)
- [Mapping HUION H610 Drawing Tablet Buttons](https://isaacs.pw/2020/06/mapping-huion-h610-drawing-tablet-buttons/)
