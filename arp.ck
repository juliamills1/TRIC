// class definition for the aa instrument

// METHODS:
// gain: set buffer gain level
// mix: set reverb mix level
// mode: set scale type (diatonic vs. Ethiopian) and number
// connect: attach to specified ugen
// help: print function & arg explanations
// modeHelp: print list of available modes
// fadeGain: [private] interpolate between given gain values
// fadeMix: [private] interpolate between given reverb values
// calcPitchClass: [private] return pitch class based on current settings
// algo(dur T, int beats, int tonic, int cycleLength, int direction, int pitchClasses[])

public class AA
{
    SinOsc s => JCRev j;
    
    // diatonic sevenths/modes
    [0, 4, 7, 11] @=> int majSev[];
    [0, 3, 7, 10] @=> int minSev[];
    [0, 4, 7, 10] @=> int domSev[];
    [0, 3, 6, 10] @=> int halfDimSev[];
    [majSev, minSev, minSev, majSev, domSev, minSev, halfDimSev] @=> int diaModes[][];
    
    // ethiopian modes
    [0, 4, 7, 9] @=> int tezMaj[];
    [0, 3, 7, 8] @=> int tezMin[];
    [0, 1, 5, 7] @=> int amb[];
    [0, 1, 6, 9] @=> int anch[];
    [0, 2, 5, 9] @=> int bluesMaj[];
    [0, 5, 6, 10] @=> int yema[];
    [0, 5, 8, 10] @=> int sheg[];
    [0, 3, 7, 11] @=> int batiMinR4[];
    [0, 4, 8, 11] @=> int batiMajR5[];
    [tezMaj, tezMin, majSev, minSev, amb, anch, bluesMaj, yema, sheg, majSev, batiMinR4, batiMajR5] @=> int ethModes[][];
    
    // default settings
    0.15 => float g;
    0.02 => float rev;
    0.8::second => dur len;
    4 => int beats;
    55 => int tonic;
    4 => int cycle;
    0 => int direction;
    majSev @=> int pitchClasses[];
    "d" => string scaleType;
    1 => int scaleNum;
    
    g => s.gain;
    rev => j.mix;
    
    public void gain(float gIn)
    {
        if (Math.fabs(gIn - s.gain()) > 0.05)
        {
            spork ~ fadeGain(s.gain(), gIn);
        }
    }
    
    public void mix(float m)
    {
        if (Math.fabs(m - j.mix()) > 0.05)
        {
            spork ~ fadeMix(j.mix(), m);
        }
    }
    
    public void mode(string t, int m)
    {
        t => scaleType;
        m => scaleNum;
        
        if (t == "d" || t == "dia")
        {
            diaModes[m-1] @=> pitchClasses;
        }
        else
        {
            ethModes[m-1] @=> pitchClasses;
        }
    }
    
    public void connect(UGen ugen)
    { 
        j => ugen; 
    }
    
    public void help()
    {
        <<<"AA has the following functions:">>>;
        <<<"gain(float): sets gain">>>;
        <<<"mix(float): sets reverb level">>>;
        <<<"mode(string, int): set scale type (diatonic vs. Ethiopian) and number">>>;
        <<<"connect(UGen): connects AA to other Chuck UGens">>>;
        <<<"algo(dur T, int x, int tonic, int cycleLength, int direction, int pitchClasses[])">>>;
        <<<"0.25 * T constant rhythm arpeggio for x beats; tonic = MIDI number">>>;
        <<<"If cycle length > # of pitch classes, an octave above will be added">>>;
        <<<"Directions: 0 = ascending; 1 = descending; 2 = asc-des; 3 = des-asc">>>;
    }
    
    public void modeHelp()
    {
        <<<"There are 7 Western diatonic modes and 12 Ethiopian scales (qenet)">>>;
        <<<"Diatonic: (1) major, (2) dorian, (3) phrygian, (4) lydian, (5) mixolydian, (6) aeolian, (7) locrian">>>;
        <<<"Ethiopian: (1) tezeta major, (2) tezeta minor, (3) bati major, (4) bati minor, (5) ambassel, (6) anchihoye, (7) blues major,">>>;
        <<<"           (8) yematebela wofe, (9) shegaye, (10) bati lydian, (11) bati minor w/ raised 4th, (12) bati major w/ raised 5th">>>;
    }
    
    private void fadeGain(float start, float target)
    {
        for (1 => int i; i <= 20; i++)
        {
            start + ((i / 20.0) * (target - start)) => g => s.gain;
            5::ms => now;
        }
    }
    
    private void fadeMix(float start, float target)
    {
        for (1 => int i; i <= 100; i++)
        {
            start + ((i / 100.0) * (target - start)) => rev => j.mix;
            1::ms => now;
        }
    }
    
    private int calcPitchClass(int i, int s[], int cL, int dir)
    {
        if (dir == 1)
        {
            return s[i % cL];
        }
        else
        {
            return s[s.size() - 1 - (i % cL)];
        }
    }
    
    // T: length of one beat
    // beats: how many beats in a measure
    // tonic: midi note of tonic (pitch class 0)
    // cycleLength: how many pitches before restarting arp
    // direction: ascending, descending, asc-des, des-asc
    // scale: which pitch classes to choose from
    public void algo(dur T, int beats, int tonic, int cycleLength, int direction, int scale[])
    {
        int j;
        while (cycleLength > scale.size())
        {
            scale << 12 + scale[j];
            j++;
        }
        
        1 => int dir;
        if (direction == 1 || direction == 3)
        {
            -1 => dir;
        }
        
        for (int i; i < beats * 4; i++)
        {   
            // TO DO: no repeated top/bottom note
            if (direction == 2 || direction == 3)
            {
                if (i > 0 && (i % cycleLength == 0))
                {
                    -1 *=> dir;
                }
            }
            
            Std.mtof(tonic + calcPitchClass(i, scale, cycleLength, dir)) => s.freq;
            0.25::T => now;
        }
    }
}