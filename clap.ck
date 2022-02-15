// class definition for the cc instrument

// METHODS:
// gain: set buffer gain level
// mix: set reverb mix level
// connect: attach to specified ugen
// help: print function & arg explanations
// trigger: [private] play sample at specified dur & gain
// constrainedRandom: [private] don't randomize gain when gain <= 0
// randomStyle: switch between different styles every X reps
// algo(dur T, int x, string style, float splits[4])

public class CC
{
    SndBuf cBuf => NRev cn;
    me.dir() + "808_Clap.wav" => cBuf.read;
    
    // default settings
    0.7 => float g; 
    0.02 => float rev;
    0.8::second => dur len;
    4 => int beats;
    "backbeat" => string style;
    [0.8, 0.8, 0.5, 0.3] @=> float splits[];
    2 => int reps;
    
    0 => int currentRep;
    0 => int styleNum;
    
    g => cBuf.gain;
    rev => cn.mix;
    
    public void gain(float gIn)
    {
        gIn => g => cBuf.gain;
    }
    
    public void mix(float m)
    {
        m => rev => cn.mix;
    }
    
    public void connect(UGen ugen)
    { 
        cn => ugen; 
    }
    
    public void help()
    {
        <<<"CC has the following functions:">>>;
        <<<"gain(float): sets gain">>>;
        <<<"mix(float): sets reverb level">>>;
        <<<"connect(UGen): connects CC to other Chuck UGens">>>;
        <<<"randomStyle(dur, int, int y): randomly re-pick a style every y measures">>>;
        <<<"algo(dur T, int x, string style, float splits[4])">>>;
        <<<"Generate x beats of dur T in specified style: backbeat, doubletime, or sync">>>;
        <<<"Splits: backbeat (quarter or dotted 8th 16), doubletime (8th or 16 16),">>>;
        <<<"        sync (dotted 8th 8th or dotted 8th 16 16, and 8th 8th or quarter)">>>;
        <<<"e.g. backbeat = split 0.8 --> 80% quarter, 20% dotted 8th 16">>>;
    }
    
    private void trigger(dur T, float len, float g)
    {
        0 => cBuf.pos;
        g => cBuf.gain;
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
            "backbeat" => style;
        }
        else if (styleNum == 1)
        {
            "doubletime" => style;
        }
        else
        {
            "sync" => style;
        }
        
        algo(T, beats, style, splits);
    }
    
    // T: length of one beat
    // beats: how many beats in a measure
    // style: basic rhythmic structure (backbeats, doubletime, syncopated)
    // prob[]: splits for rhythm choices; sync uses two floats, other styles use one
    public void algo(dur T, int beats, string style, float prob[])
    {
        if (style == "backbeat")
        {
            for (int i; i < beats; i++)
            {
                if ((i != 0) && (i % 2 != 0))
                {
                    Math.randomf() => float choice;
                    if (choice < prob[0])
                    {
                        trigger(T, 1, constrainedRandom(g, 0, 0.2));
                    }
                    else
                    {
                        trigger(T, 0.75, constrainedRandom(g, 0, 0.2));
                        trigger(T, 0.25, constrainedRandom(g, -0.2, 0));
                    }
                }
                else
                {
                    trigger(T, 1, 0);
                }
            }
        }
        else if (style == "doubletime")
        {
            for (int i; i < beats; i++)
            {
                if (i == 0)
                {
                    trigger(T, 0.5, 0);
                    trigger(T, 1, constrainedRandom(g, 0, 0.2));
                }
                else if (i == beats-1)
                {
                    Math.randomf() => float choice;
                    if (choice < prob[1])
                    {
                        trigger(T, 0.5, constrainedRandom(g, -0.1, 0.1));
                    }
                    else
                    {
                        trigger(T, 0.25, constrainedRandom(g, -0.1, 0));
                        trigger(T, 0.25, constrainedRandom(g, 0, 0.1));
                    }
                }
                else
                {
                    trigger(T, 1, constrainedRandom(g, -0.1, 0.1));
                }
            }
        }
        else if (style == "sync")
        {
            beats / 2 => int on;
            beats % 2 => int off;
            
            for (int i; i < on; i++)
            {
                if (i == 0)
                {
                    trigger(T, 0.75, 0);
                    trigger(T, 0.75, constrainedRandom(g, 0, 0.2));
                    trigger(T, 0.5, constrainedRandom(g, -0.1, 0.1));
                }
                else if (i == on-1)
                {
                    trigger(T, 0.75, 0);
                    
                    Math.randomf() => float choice;
                    if (choice < prob[2])
                    {
                        trigger(T, 0.75, constrainedRandom(g, 0, 0.2));
                        trigger(T, 0.5, constrainedRandom(g, -0.1, 0.1));
                    }
                    else
                    {
                        trigger(T, 0.75, constrainedRandom(g, 0, 0.2));
                        trigger(T, 0.25, constrainedRandom(g, -0.1, 0));
                        trigger(T, 0.25, constrainedRandom(g, 0, 0.1));
                    }
                }
                else
                {
                    trigger(T, 0.75, 0);
                    trigger(T, 0.75, constrainedRandom(g, 0, 0.2));
                    trigger(T, 0.5, constrainedRandom(g, -0.1, 0.1));
                }
            }
            
            for (int j; j < off; j++)
            {
                Math.randomf() => float choice;
                if (choice < prob[3] || beats == 1)
                {
                    trigger(T, 0.5, 0);
                    trigger(T, 0.5, constrainedRandom(g, -0.1, 0));
                }
                else
                {
                    trigger(T, 1, 0);
                }
            }
        } 
    }
}