section .data                                   ; Data section
        base_freq:      dd 27.5                 ; Frequency of note A0
        amplitude:      dd 4096.0               ; Amplitude of the waves
        const_one:      dd 1.0                  ; Const value 1
        const_two:      dd 2.0                  ; Const value 2
        const_twelve:   dq 12                   ; Const value 12
        const_pi:       dd 3.141592654          ; Const value PI
        const_freq:     dd 1.059463094          ; 2^(1/12), const val to calculate frequencies

        ; Lowercase letters represent black keys (sharps)
        ; octave <- ["A", "a", "B", "C", "c", "D", "d", "E", "F", "f", "G", "g"]
        octave:         db 65, 97, 66, 67, 99, 68, 100, 69, 70, 102, 71, 103, 0
        
        note_freqs:     times 89 dd 0.0         ; Array to store the frequency of each
                                                ; piano note
        note_size:      dd 0.0                  ; Variable to store the size of the note array
                                                ; according to its duration

        increment:      dd 0.0                  ; Value to increment at each iteration
                                                ; of the values_loop to fill the t_vector

        t_vector:       times 75600 dd 0.0      ; Array of evenly spaced numbers that
                                                ; will be used as operands to get the values
                                                ; of the note wave
        note:           times 75600 dd 0.0      ; Array of wave values of the note

section .text                                   ; Code section
global get_note_data

; get_note_data
;
; Returns an array of wave values of a corresponding note
;
; Parameters:
; rdi  <- note_char             The character that represents the note
; rsi  <- octave_number         The octave number of the note
; rdx  <- note_size             Size of the note array according to its duration
; xmm0 <- time_duration         Duration of the note in seconds
;
; Returns:
; An array of float values of the note wave
get_note_data:

        call    get_piano_notes         ; Get all frequencies of piano notes

        call    fill_t_vector           ; Fill the array of values between 0 and time_duration

        call    get_note_freq           ; Get the frequency of the corresponding note

        call    get_wave                ; Get the wave values of the note

        mov     rax, note               ; Store the note array in the return value register

        ret                             ; return

; get_piano_notes
;
; Calculates all frequencies of piano notes
get_piano_notes:

        mov     rbx, note_freqs
        mov     rcx, 87                 ; note_iteration <- 87
                                        ; Value to decrease at each iteration
                                        ; of frequencies_loop to fill the
                                        ; note_freqs array

        vmovss  xmm2, [base_freq]
        vmovss  xmm3, [const_freq]

                                        ; index <- 0
        vmovss  [rbx], xmm2             ; note_freqs[index] <- base_freq
        add     rbx, 4                  ; index <- index + 4 (4 byte increment)

frequencies_loop:                       ; while note_iteration > 0 do

        vmulss  xmm2, xmm2, xmm3        ;   base_freq <- base_freq * const_freq
        vmovss  [rbx], xmm2             ;   note_freqs[index] <- base_freq
        add     rbx, 4                  ;   index <- index + 4 (4 byte increment)
        loop    frequencies_loop        ;   note_iteration <- note_iteration - 1

        ret                             ; return

; fill_t_vector
;
; Fills t_vector with evenly spaced numbers that will be used to get the wave values
fill_t_vector:

        mov      rbx, t_vector
        mov      r9, note_size
        mov      [r9], rdx              ; Store the note array size in memory.
        mov      rcx, rdx               ; note_size will decrease at each iteration
                                        ; of values_loop to fill the t_vector

        vmovss   xmm3, [increment]
        vmovss   xmm4, [const_one]
        vmovss   xmm5, [const_two]
        vmovss   xmm6, [const_pi]

        cvtsi2ss xmm1, [note_size]      ; Convert the stored note size to float

        vmovss   xmm2, xmm0             ; current_value <- time_duration
        vdivss   xmm7, xmm2, xmm1       ; temp <- current_value / note_size

values_loop:                            ; while note_size > 0 do

        vmovss  xmm2, xmm7              ;   current_value <- temp
        vmulss  xmm2, xmm2, xmm3        ;   current_value <- current_value * increment
        vmulss  xmm2, xmm2, xmm5        ;   current_value <- current_value * 2
        vmulss  xmm2, xmm2, xmm6        ;   current_value <- current_value * pi
        vaddss  xmm3, xmm3, xmm4        ;   increment <- increment + 1
        vmovss  [rbx], xmm2             ;   t_vector[index] <- current_value
        add     rbx, 4                  ;   index <- index + 4 (4 byte increment)
        loop    values_loop             ;   note_size <- note_size - 1

        ret                             ; return

; get_note_freq
;
; Identifies the letter and the octave number of the note and gets the corresponding frequency
get_note_freq:

        mov     rbx, octave
        mov     rcx, 0                  ; oct_index <- 0
        mov     r8, 0                   ; octave_counter <- 0
        mov     r9, note_freqs
        mov     r10, 0                  ; note_index <- 0 (Piano note index)
        mov     r11, [const_twelve]

search_char:                            ; Search note_char in octave array
                                        ; do
        cmp     dil, [rbx + rcx]        ;   if note_char = octave[oct_index] then
        je      search_number           ;     call search_number()
                                        ;   else
        inc     rcx                     ;     oct_index <- oct_index + 1
        jmp     search_char             ; while note_char != octave[oct_index] 

search_number:                          ; Identify the octave number
                                        ; do
        cmp     rsi, r8                 ;   if octave_counter = octave_number then
        je      adjust_octave           ;     call adjust_octave()
                                        ;   else
        inc     r8                      ;     octave_counter <- octave_counter + 1
        jmp     search_number           ; while octave_counter < octave_number 

adjust_octave:                          ; Adjust the octave counter to calculate note_index

        cmp     rcx, 3                  ; if oct_index > 3 then (If the note is not A, a or B)
        jl      get_note_index          ;   call add_octave()
                                        ; else (Substract an octave)
        dec     r8                      ;   octave_counter <- octave_counter - 1

get_note_index:                         ; Calculate the note index (Add 12 for each octave)
                                        ; do
        cmp     r8, 0                   ;   if octave_counter = 0 then
        je      assign_note_freq        ;     call assign_note_freq()
                                        ;   else
        add     r10, r11                ;     note_index <- note_index + 12
        dec     r8                      ;     octave_counter <- octave_counter - 1
        jmp     get_note_index          ; while octave_counter > 0

assign_note_freq:                       ; Assign the corresponding note frequency

        add     r10, rcx                ; note_index <- note_index + oct_index
        lea     r12, [r9 + r10 * 4]     ; Load current note frequency effective address in r12
                                        ; (&note_freqs[note_index * 4])
        vmovss  xmm1, [r12]             ; Move its content to the floating point register xmm1
                                        ; to be used by the wave_loop function
                                        ; (note_frequency)

        ret                             ; return

; get_wave
;
; Uses the obtained frequency to perform the remaining operations to calculate the wave
get_wave:

        mov     rbx, t_vector
        mov     rcx, rdx                ; note_size will decrease at each iteration
                                        ; of wave_loop to fill the note array
        mov     r8, note                ; Point to the note array (note_ptr)
        vmovss  xmm3, [amplitude]

wave_loop:                              ; index <- 0
                                        ; while note_size > 0 do
        vmovss  xmm2, [rbx]             ;   current <- t_vector[index]
        vmulss  xmm2, xmm2, xmm1        ;   current <- current * note_frequency
        vmovss  [r8], xmm2              ;   *note_ptr <- current

        fld     long [r8]
        fsin                            ;   sin(*note_ptr)
        fstp    long [r8]

        vmovss  xmm2, [r8]              ;   current <- *note_ptr
        vmulss  xmm2, xmm2, xmm3        ;   current <- current * amplitude
        vmovss  [r8], xmm2              ;   *note_ptr <- current

        add     rbx, 4                  ;   index <- index + 4 (4 byte increment)
        add     r8, 4                   ;   note_ptr <- *(note_ptr + 4) (Point to next dword)

        loop    wave_loop               ;   note_size <- note_size - 1

        ret                             ; return


