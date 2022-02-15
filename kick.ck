// class definition for the kk instrument

// METHODS:
// gain: set buffer gain level
// mix: set reverb mix level
// connect: attach to specified ugen
// help: print function & arg explanations
// trigger: [private] play sample at specified dur & gain
// constrainedRandom: [private] don't randomize gain when gain <= 0
// randomStyle: switch between different styles every X reps
// algo(dur T, int x, string style, float splits[4])

public class KK
{
    SndBuf kBuf => NRev kn;
    me.dir() + "808_Kick_Long.wav" => kBuf.read;
    
    // default settings
    0.5 => float g; 
    0.02 => float rev;
    0.8::second => dur len;
    4 => int beats;
    "club" => string style;
    [0.8, 0.6, 0.5, 0.75] @=> float splits[];
    2 => int reps;
    
    0 => int currentRep;
    0 => int styleNum;
    
    g => kBuf.gain;
    rev => kn.mix;
    
    public void gain(float gIn)
    {
        gIn => g => kBuf.gain;
    }
    
    public void mix(float m)
    {
        m => rev => kn.mix;
    }
    
    public void connect(UGen ugen)
    { 
        kn => ugen; 
    }
    
    public void help()
    {
        <<<"KK has the following functions:">>>;
        <<<"gain(float): sets gain">>>;
        <<<"mix(float): sets reverb level">>>;
        <<<"connect(UGen): connects CC to other Chuck UGens">>>;
        <<<"randomStyle(dur, int, int y): randomly re-pick a style every y measures">>>;
        <<<"algo(dur T, int x, string style, float splits[4])">>>;
        <<<"Generate x beats of dur T in specified style: club, rock, or sync">>>;
        <<<"Splits: rock (half or dotted quarter 8th, and dotted half or half quarter),">>>;
        <<<"        sync (quarter, 8th 8th, or dotted 8th 16)">>>;
        <<<"e.g. sync = splits 0.5, 0.75 --> 50% quarter, 25% 8th 8th, 25% dotted 8th 16">>>;
    }
    
    private void trigger(dur T, float len, float g)
    {
        0 => kBuf.pos;
        g => kBuf.gain;
        len::T => now;
    }
    
    private float constrainedRandom(float g, float lowAdjust, float highAdjust)
    {
        if (g <= 0)
        {
            return 0.0;
        }
        else
        {
            return Math.random2f(g + lowAdjust, g + highAdjust);
        }
    }
    
    public void randomStyle(dur T, int beats, int rep)
    {
        currentRep++;
        if (currentRep > rep)
        {
            1 => currentRep;
        }
        
        if (currentRep == 1)
        {
            Math.random2(0,2) => styleNum;
        }
            
        string style;
        if (styleNum == 0)
        {
            "club" => style;
        }
        else if (styleNum == 1)
        {
            "rock" => style;
        }
        else
        {
            "sync" => style;
        }
        
        algo(T, beats, style, splits);
    }
 
    // T: length of one beat
    // beats: how many beats in a measure
    // style: basic rhythmic structure (4-on-the-floor, onbeats, syncopated)
    // prob[]: rock = 2 splits for 2 choices; sync = 2 splits for 1 choice
    public void algo(dur T, int beats, string style, float prob[])
    {
        if (style == "club")
        {
            for (int i; i < beats; i++)
            {
                if (i == 0)
                {
                    trigger(T, 1, constrainedRandom(g, 0.2, 0.2));
                }
                else
                {
                    trigger(T, 1, constrainedRandom(g, -0.1, 0.1));
                }
            }
        }
        else if (style == "rock")
        {
            0 => int full;
            0 => int rem;
            if (beats > 1)
            {
                if (beats % 3 == 0)
                {
                    beats / 3 => rem;
                }
                else
                {
                    (beats / 2) - (beats % 2) => full;
                    beats % 2 => rem;
                }
            }
            else
            {
                trigger(T, 1, g);
            }
            
            // length 2T
            for (int i; i < full; i++)
            {
                if (i == 0)
                {
                    trigger(T, 2, constrainedRandom(g, 0.2, 0.2));
                }
                else
                {
                    Math.randomf() => float choice;
                    if (choice < prob[0])
                    {
                        trigger(T, 2, constrainedRandom(g, -0.1, 0.1));
                    }
                    else
                    {
                        trigger(T, 1.5, constrainedRandom(g, -0.1, 0.1));
                        trigger(T, 0.5, constrainedRandom(g, -0.3, -0.2));
                    }
                }
            }
            
            // length 3T
            for (int j; j < rem; j++)
            {
                Math.randomf() => float choice;
                if (choice < prob[1])
                {
                    trigger(T, 3, constrainedRandom(g, 0.2, 0.2));
                }
                else
                {
                    trigger(T, 2, constrainedRandom(g, 0.2, 0.2));
                    trigger(T, 1, constrainedRandom(g, -0.1, 0.1));
                }
            }
        }
        else if (style == "sync")
        {
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
            
            for (int i; i < sync; i++)
            {
                trigger(T, 1.5, constrainedRandom(g, 0.2, 0.2));
                trigger(T, 1.5, constrainedRandom(g, -0.1, 0.1));
            }
            
            for (int j; j < straight; j++)
            {
                Math.randomf() => float choice;
                if (choice < prob[2]) 
                {
                    trigger(T, 1, constrainedRandom(g, -0.1, 0.1));
                }
                else if (choice < prob[3])
                {
                    trigger(T, 0.5, constrainedRandom(g, -0.1, 0.1));
                    trigger(T, 0.5, constrainedRandom(g, -0.3, -0.2));
                }
                else
                {
                    trigger(T, 0.75, constrainedRandom(g, -0.1, 0.1));
                    trigger(T, 0.25, constrainedRandom(g, -0.3, -0.2));
                }
            }
        } 
    }
}