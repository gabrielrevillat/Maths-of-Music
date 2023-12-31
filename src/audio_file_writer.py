import numpy as np
import os

from IPython.lib.display import Audio

def write_audio_file(song_data: np.ndarray, song_name: bytes) -> None:
    """Gets the song data and writes a WAV audio file.
    
    Args:
        song_data (numpy.ndarray): Array of waves generated by the frequencies
          of musical notes that represent the song.
        song_name (bytes): Song name, enconded in bytes. 
    """

    # Convert song_name from bytes to str
    decoded_name = song_name.decode("utf-8")
    path_name = "output"

    # Create output folder if doesn't exist
    if (not os.path.exists(path_name)):
        os.makedirs(path_name)

    file_name = path_name + "/" + decoded_name + ".wav"

    # Create audio from song_data array with a sample rate of 44100
    samplerate = 44100
    audio = Audio(song_data.astype(np.int16), rate=samplerate)

    # Write audio file with the created audio data
    with open(file_name, "wb") as file:
        file.write(audio.data)