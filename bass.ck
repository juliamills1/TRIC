// class definition for the bb instrument

// METHODS:
// gain: set buffer gain level
// mix: set reverb mix level
// mode: set scale type (diatonic vs. Ethiopian) and number
// connect: attach to specified ugen
// help: print function & arg explanations
// modeHelp: print list of available modes
// fadeGain: [private] interpolate between given gain values
// fadeMix: [private] interpolate between given reverb values
// algo(dur T, int x, int tonic, int pitchClasses[], int addOctaves)

public class BB
{
    TriOsc s => JCRev j;
    
    // diatonic modes
    [0, 2, 4, 7, 9] @=> int major[];
    [0, 2, 3, 7, 10] @=> int dorian[];
    [0, 1, 3, 7, 8] @=> int phrygian[];
    [0, 4, 6, 7, 9] @=> int lydian[];
    [0, 4, 7, 9, 10] @=> int mixolydian[];
    [0, 2, 3, 7, 8] @=> int aeolian[];
    [0, 3, 5, 6, 10] @=> int locrian[];
    [major, dorian, phrygian, lydian, mixolydian, aeolian, locrian] @=> int diaModes[][];
    
    // ethiopian modes
    [0, 2, 3, 7, 8] @=> int tezMin[];
    [0, 4, 5, 7, 11] @=> int batiMaj[];
    [0, 3, 5, 7, 10] @=> int batiMin[];
    [0, 1, 5, 7, 8] @=> int amb[];
    [0, 1, 5, 6, 9] @=> int anch[];
    [0, 2, 5, 7, 9] @=> int bluesMaj[];
    [0, 2, 5, 6, 10] @=> int yema[];
    [0, 3, 5, 8, 10] @=> int sheg[];
    [0, 4, 6, 7, 11] @=> int batiLyd[];
    [0, 3, 6, 7, 11] @=> int batiMinR4[];
    [0, 4, 5, 8, 11] @=> int batiMajR5[];
    [major, tezMin, batiMaj, batiMin, amb, anch, bluesMaj, yema, sheg, batiLyd, batiMinR4, batiMajR5] @=> int ethModes[][];
    
    // default settings
    0.15 => float g;
    0.02 => float rev;
    0.8::second => dur len;
    4 => int beats;
    43 => int tonic;
    [0, 2, 4, 7, 9] @=> int pitchClasses[];
    1 => int addOctaves;
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
        <<<"BB has the following functions:">>>;
        <<<"gain(float): sets gain">>>;
        <<<"mix(float): sets reverb level">>>;
        <<<"mode(string, int): set scale type (diatonic vs. Ethiopian) and number">>>;
        <<<"connect(UGen): connects AA to other Chuck UGens">>>;
        <<<"algo(dur T, int x, int tonic, int pitchClasses[], int addOctaves)">>>;
        <<<"Mix of x syncopated and straight beats (dur T); tonic = MIDI number">>>;
        <<<"Additional octaves: 1 = all pitch classes can be +12 MIDI notes up from tonic">>>;
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
    
    // T: length of one beat
    // beats: how many beats in a measure
    // tonic: midi note of tonic (pitch class 0)
    // scale[]: which pitch classes to choose from
    // octaves: how many additional octaves instrument has
    public void algo(dur T, int beats, int tonic, int scale[], int octaves)
    {
        scale.size() - 1 => int numPitches;
        
        int sync;
        int straight;
        if (beats != 3)
        {
            beats / 3 => sync;
            beats % 3 => straight;
        }
        else
        {
            0 => sync;
            3 => straight;
        }
        
        float freq;    
        for (int i; i < sync; i++)
        {
            scale[0] => freq;    
            Std.mtof(tonic) => s.freq;
            
            // 1st n4d of bar: n4d or n8d n8d
            if (Math.randomf() < 0.2) 
            {
                1.5::T => now;
            }
            else
            {
                0.75::T => now;
                scale[ Math.random2(0,numPitches) ] => freq;  
                Std.mtof( tonic + (Math.random2(0,octaves)*12 + freq) ) => s.freq;
                0.75::T => now;
            }
            
            // 2nd n4d of bar: n4d or n8d n8d
            scale[ Math.random2(0,numPitches) ] => freq; 
            Std.mtof( tonic + (Math.random2(0,octaves)*12 + freq) ) => s.freq;
            
            if (Math.randomf() < 0.15) 
            {
                1.5::T => now;
            }
            else
            {
                0.75::T => now;
                scale[ Math.random2(0,numPitches) ] => freq;  
                Std.mtof( tonic + (Math.random2(0,octaves)*12 + freq) ) => s.freq;
                0.75::T => now;
            }
        }
        
        for (int j; j < straight; j++)
        {
            if (straight == 3 && j == 0)
            {
                scale[0] => freq;    
                Std.mtof(tonic) => s.freq;
            }
            else
            {
                if (numPitches > 0)
                {
                    scale[ Math.random2(1,numPitches) ] => freq;   
                }   
                Std.mtof( tonic + (Math.random2(0,octaves)*12 + freq) ) => s.freq;
            }
            
            if (Math.randomf() < 0.6) 
            {
                1::T => now;
            }
            else
            {
                0.5::T => now;
                if (numPitches > 0)
                {
                    scale[ Math.random2(1,numPitches) ] => freq;   
                }  
                Std.mtof( tonic + (Math.random2(0,octaves)*12 + freq) ) => s.freq;
                0.5::T => now;
            }
        }
    }
}