# Keydion

<p align=center>Tired of bad and limited default virtual keyboards in your DAW?<br/> Use your laptop keyboard as a <b>Chromatic Button Accordion</b> for Virtual MIDI instead.</b><br/><b>3 octave range accessible ergonomically without any additional hardware!</b></p>

<img width="1012" height="660" alt="Image" src="https://github.com/user-attachments/assets/64268c74-544c-43db-9700-6db5700a5cca" />

## Description

Tired of bad default virtual keyboards in your DAW? Now you can play full THREE OCTAVES ERGONOMICALLY only using your computer keyboard (and learn accordion at the same time).
Keydion turns your computer keyboard into a Chromatic Button Accordion controller, sending virtual MIDI messages.
At the moment, it assumes QWERTY layout and simulates C-Griff accordion layout.

This project is heavily inspired by [Anatole Muster](https://www.youtube.com/shorts/1kVAUZjotnE) videos.
I did try to find the software he used for quite some time, but it was just easier to DIY the tool myself.
I mostly found web-based solutions, but I could not comfortably use them in my DAW for different reasons.

Being a native app, **keydion** allows "it just works" MIDI integration, low latency, etc.
The downside is that I did this in SwiftUI for **macOS only** despite having other options which would have been cross-platform, e.g., Rust+gtk+midir.

## Features

- Maps QWERTY keyboard keys to chromatic button accordion layout (C-Griff)
- Sends virtual MIDI signals to software instruments
- Simple, reliable, configurable
- Written in Swift
- Supports dark mode (follows system theme)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/r00tman/keydion.git
```
2. Open the project in Xcode (macOS required).
3. Build and run the application.

## Usage

- Launch Keydion.
- Use your laptop keyboard to play notes in the chromatic button accordion layout.
- Connect to any DAW or software synthesizer that accepts MIDI input.

**Note:** The input only works when the app window is active. Global key capture would case horrifying number of problems, which I don't even want to think about.

## Supported Platforms

- macOS (requires Xcode for building)

## Next Steps

- Package as a GitHub release
- Better UI controls, default Stepper is *horrible to use*. You can't enter stuff as text, you can't drag it. Only click and hold +/- buttons.
- Cross-platform Rust+gtk+midir rewrite?
- Make app title, repo name, folder names and etc consistent with Keydion branding.
- Add B-Griff? I chose C-Griff consciously after figuring that there are much fewer learning materials and support for B-Griff overall. Still, despite being just mirror images of each other, both C-Griff and B-Griff are used widely. So, let's add B-Griff too.
- Note names instead of just MIDI note numbers in UI? As for myself, I play by ear and through muscle memory, hence I don't really need that. But I'm sure that for some people, it'd make it easier to use and learn the instrument. 

## Other cool stuff
If you liked this repo, then you probably would love my other repo too: [Turbopad](https://github.com/r00tman/Turbopad)!

It allows you to use your built-in multi-touch trackpad as **MPE guitar**, **velocity-sensitive drum pads**, **CC controller** and more.

## Disclaimer

The code for this specific repo is mostly ChatGPT generated, out of frustration with existing solutions. I didn't expect it to work as good as it did and I needed the solution fast, so I kept it. I had to fix and change lots of things myself, but it doesn't change that the initial code was done by ChatGPT.
