#include <cstdio>
#include <iostream>
#include <regex>
#include <sstream>
#include <string>
#include <vector>

#define NPY_NO_DEPRECATED_API NPY_1_7_API_VERSION
#include <Python.h>
#include <numpy/arrayobject.h>

extern "C" float* get_note_data(const char note, const int octave_number,
                                const int note_size, const float time_duration);

/**
 * @brief Calls functions to embed the Python interpreter into the program.
 * 
 * Calls the necessary functions to embed the Python interpreter and call the
 * function that writes and audio file.
 *
 * @param song_data Array of wave values for each note in the song
 * @param song_size Size of the array of wave values
 * @param song_name Name of the song entered by the user
 */
void* call_python(const float* song_data, const int song_size,
                  const std::string song_name);

/**
 * @brief Starts the program execution.
 */
int main()
{
    int error = EXIT_SUCCESS;

    std::string song_name = "";
    std::cout << "Enter song name (without spaces): ";
    std::cin >> song_name;

    // Replace invalid characters in entered song name
    std::regex invalid_chars("[^\\w\\.!@#$\\^+=-]");
    song_name = std::regex_replace(song_name, invalid_chars, "-");

    // Beats per minute
    double bpm = 0.0;
    std::cout << "Enter song BPM: ";
    std::cin >> bpm;

    if (std::cin.good() && bpm >= 35.0 && bpm <= 300.0)
    {
        std::string music_notes = "";
        std::cout << "Enter music notes: ";
        std::cin >> music_notes;

        std::regex notes_regex(
            "^([a-gA-G][1-7]|C8|[AaB]0)"
            "(-+([a-gA-G][1-7]|C8|[AaB]0))*$");

        if (std::regex_match(music_notes, notes_regex))
        {
            std::stringstream notes_stream(music_notes);
            std::vector<std::string> split_notes;
            std::string current_note = "";

            while (std::getline(notes_stream, current_note, '-'))
            {
                split_notes.push_back(current_note);
            }

            const double seconds = 60.0;
            const double samplerate = 44100.0;
            const double time_duration = seconds / (double)bpm;

            const std::size_t note_count = split_notes.size();
            const std::size_t note_size = samplerate * time_duration;
            const std::size_t song_size = note_count * note_size;

            // Array for wave values
            float* song_data = new float[song_size];

            std::cout << "\nConverting...\n";

            std::size_t song_index = 0;

            for (std::size_t index1 = 0; index1 < note_count; ++index1)
            {
                const std::string current = split_notes[index1];

                if (current.size() > 0)
                {
                    const char note_char = current[0];
                    const int octave_number = atoi(&current[1]);
                    const float* note_data =
                        get_note_data(note_char, octave_number, note_size,
                                      (float)time_duration);

                    // Append note_data to song_data
                    for (std::size_t index2 = 0; index2 < note_size; ++index2)
                    {
                        song_data[song_index++] = note_data[index2];
                    }
                }
                else  // Rest
                {
                    for (std::size_t index2 = 0; index2 < note_size; ++index2)
                    {
                        song_data[song_index++] = 0.0;
                    }
                }
            }

            call_python(song_data, song_size, song_name);

            std::cout << "Done! Music file saved in output/" + song_name +
                             ".wav\n";

            delete[] song_data;
        }
        else
        {
            std::cerr << "Error: invalid music text\n";
            error = 2;
        }
    }
    else
    {
        std::cerr << "Error: BPM must be a number between 35 and 300\n";
        error = 1;
    }

    return error;
}

void* call_python(const float* song_data, const int song_size,
                  const std::string song_name)
{
    // Initialize the Python interpreter
    Py_Initialize();

    // Store the current signal handler
    PyOS_sighandler_t sighandler = PyOS_getsig(SIGINT);
    // Initialize numpy
    import_array();
    // Restore the stored signal handler
    PyOS_setsig(SIGINT, sighandler);

    // Open and execute the Python file
    FILE* python_file = std::fopen("src/audio_file_writer.py", "r");
    PyRun_SimpleFile(python_file, "src/audio_file_writer.py");

    // Get a reference to the main module
    PyObject* main_module = PyImport_AddModule("__main__");
    // Get the main module's dictionary
    PyObject* main_dict = PyModule_GetDict(main_module);

    // Extract a reference to the function "write_audio_file" from main_dict
    PyObject* write_audio = PyDict_GetItemString(main_dict, "write_audio_file");

    // Point to the size of the song array
    npy_intp array_dimensions[1] = {song_size};

    // Convert song_data to numpy array
    PyObject* data = PyArray_SimpleNewFromData(1, array_dimensions, NPY_FLOAT,
                                               (void*)song_data);
    // Covert song_name to Python bytes
    PyObject* name = PyBytes_FromString(song_name.data());

    // Call the function referenced by "write_audio" with "data" and "name" as
    // args
    PyObject_CallFunctionObjArgs(write_audio, data, name, NULL);

    // Undo all the Python initializations
    Py_Finalize();

    return nullptr;
}