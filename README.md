<h1>Terminal-Responsive Instrument Classes</i></h1>
<h3> An ensemble of instruments that work with a wide range of user specification</h3>

From the moment the user runs the program,
        there is a randomized beat that they can then change live. At their
        most specific, the instruments can be locked to a consistent rhythm or
        pitch. At their least specific, they play along randomly but coherently.

The system also comes with an optional "conscience" log, the personification of TRIC.
        All input into the audio-side terminal results in feedback, either a
        description of the parsed command, waiting message, specialized tempo
        change reactions, or an error response.

There are five instruments: HH (hi-hat), CC (clap), KK (kick), BB (bass), and AA
        (arpeggiator). Each have four main functions:
        <li>gain(float): change instrument gain</li>
        <li>mix(float): change instrument reverb level</li>
        <li>connect(UGen): connect the instrument to other Chuck UGens</li>
        <li>help(): print instrument's functions and argument info</li>
        <li>algo(dur, int, ...): the number of parameters varies per instrument,
            but all include the length of one beat and the number of beats per
            measure. T (0.8s) is the default duration in the terminal looper
            code; all numerical duration inputs are interpreted as being in seconds.
        </li>

KK and CC also have the function randomStyle(), which cycles through these settings
        for however many repetitions is specified.

AA and BB can use either mode settings or user-specified pitch classes. There are
        7 Western diatonic modes or 12 Ethiopian qenet to choose from. The function
        modeHelp() prints a list of all available modes. The other synth-specific
        function is tonic(), which sends the same MIDI note to AA and BB an octave
        apart.

Any argument can be skipped by using a hyphen. Most functions require a minimum
        of one "real" argument, but both of mode()'s arguments are mandatory.

Global changes can be sent with the "instrument" name G, while synth changes can
        be sent using S and drum changes with D. Commands can be saved as presets
        using the presets.txt file and accessed using "P x", where x is the line
        number.

NOTE: the way it is currently set up in Chuck, the duration and number of beats for
        KK controls the length of the other instruments' loops. For example, giving
        the kick 5 beats and the other instruments 4 will result in the 5th beat
        playing the kick and bass (paused on its last note) while the clap
        and hi-hat tacet.

-------------
To run TRIC audio, use <code>chuck tri.ck</code>. To run the conscience log,
use <code>chuck conscience.ck</code> in another terminal.

-------------
<h3>Slated feature requests</h3>
<li>Output state changes to .txt</li>
<li>Poly synth stab instrument</li>
<li>Improve terminal.ck efficiency</li>
<li>All classes extending tricClass parent</li>
<li>Loop independence from kick loop length</li>
<li>Add lilypond rhythm input mode: a separate function from algo() for all
    instruments in which lilypond notation is parsed as rhythmic input (e.g. n4d
    n4d r4 = two dotted quarter notes and a quarter rest); would allow for switching
    between algo() and tutti sections</li>
<li>Infrastructure for multiple AA instantiations created on the fly</li>