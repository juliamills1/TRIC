<h1>Terminal-Responsive Instrument Classes</i></h1>
<h3> An ensemble of instruments that work with a wide range of user specification</h3>

From the moment the user runs the program,
        there is a randomized beat that they can then change live. At their
        most specific, the instruments can be locked to a consistent rhythm or
        pitch. At their least specific, they play along randomly but coherently.

There are four instruments: HH (hi-hat), CC (clap), KK (kick), and BB (bass). Each have four main functions:
        <li>gain(float): change instrument gain</li>
        <li>mix(float): change instrument reverb level</li>
        <li>connect(UGen): connect the instrument to other Chuck UGens</li>
        <li>help(): print instrument's functions and argument info</li>
        <li>algo(dur, int, ...): the number of parameters varies per instrument,
            but all include the length of one beat and the number of beats per
            measure. T (0.8s) is the default duration in the terminal looper
            code; all numerical duration inputs are interpreted as being in seconds.
        </li>

KK and CC's algo() also requires the string name of a "style", i.e. basic
        rhythmic structure (4-on-the-floor, reggaeton, backbeat, etc). They also
        have the function randomStyle(), which cycles through these settings for
        however many repetitions is specified.

The way it is set up in Chuck, the duration and number of beats for
        KK controls the length of the other instruments' loops. For example, giving
        the kick 5 beats and the other instruments 4 will result in the 5th beat
        playing the kick and bass (paused on its last note) while the clap
        and hi-hat tacet.
        
        
-------------
To run the program, use <code>chuck bass.ck kick.ck clap.ck hihat.ck terminal.ck</code>
