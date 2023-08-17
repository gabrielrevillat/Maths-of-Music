# Maths of Music: A basic text-to-music converter with mathematics in x86 assembly

This is a Console Application that reads a group of musical notes by their scientific pitch notation, calculates their frequencies, generates waves with those frequencies, builds a virtual piano and creates an audio with the musical piece resulting from the generated waves.

This application was based on this [article](https://towardsdatascience.com/mathematics-of-music-in-python-b7d838c84f72) explanation.

> Note: In 2023, the author of the article made it available to *Medium* members only. However, the source code presented in the article is available in [this repository](https://github.com/weeping-angel/Mathematics-of-Music).

This was developed in the second half of 2020 as a project for the course *Assembly Language* of the School of Computer Science and Informatics of the University of Costa Rica. In 2023, for this version of the project, new features were added, such as the availability of all piano notes instead of a single octave and the possibility of choosing the tempo of the piece.

## Usage

### Dependencies

To install the program dependencies on Debian-based Linux distributions, use the `make instdeps` command.

### Assembly, compilation and linking

To assemble, compile and link the program, just use the `make` command.

### Running the program

To run the program, you can use the `bin/maths_of_music` command, or simply the `make run` command.

When the program runs, it will ask for three inputs: The name of the song, the beats per minute (BPM) of the song and a group of notes of the song in its scientific pitch notation (i. e. the musical note name and a number identifying the pitch's octave). Each note will be read as a crochet (quarter note) relative to the selected BPM. **Note:** For this program, natural notes are represented with **uppercase letters** and sharp notes are represented with **lowercase letters**.

Execution example:
```
$ bin/maths_of_music
Enter song name (without spaces): twinkle-twinkle
Enter song BPM: 120
Enter music notes: C4-C4-G4-G4-A4-A4-G4--F4-F4-E4-E4-D4-D4-C4

```

You can have the musical piece data in a text file and redirect it as the program input.

File example (`input/ode-to-joy.txt`):
```
ode-to-joy
160
f3-f3-G3-A3-A3-G3-f3-E3-D3-D3-E3-f3-f3--E3--f3-f3-G3-A3-A3-G3-f3-E3-D3-D3-E3-f3-E3--D3
```

Execution example:
```
$ bin/maths_of_music < input/ode-to-joy.txt
```

The resulting musical piece file will be saved as a WAV audio file in the `output` folder.


