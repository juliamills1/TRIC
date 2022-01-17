// class definition for the cc instrument

// METHODS:
// gain: set buffer gain level
// mix: set reverb mix level
// connect: attach to specified ugen
// help: print function & arg explanations
// trigger: [private] play sample at specified dur & gain;
// randomStyle: switch between different styles every X reps
// algo(dur, int, string): 3 styles of beats
// algo(dur, int, string, float[2]): + specify probability splits

public class CC
{
    SndBuf cBuf => NRev cn;
    me.dir() + "808_Clap.wav" => cBuf.read;
    0.5 => float baseGain;
    0.02 => cn.mix;
    0 => int currentRep;
    0 => int styleNum;
    
    public void gain(float g)
    {
        g => baseGain => cBuf.gain;
    }
    
    public void mix(float m)
    {
        m => cn.mix;
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
        <<<"randomStyle(dur, int, int x): randomly re-pick a style every x measures">>>;
        <<<"algo(dur T, int x, string y): generate x beats with dur T in style y (backbeat, doubletime, sync)">>>;
        <<<"algo(dur, int, string, float[2]): + specify probability splits">>>;
    }
    
    private void trigger(dur T, float len, float g)
    {
        0 => cBuf.pos;
        g => cBuf.gain;
        len::T => now;
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
        
        algo(T, beats, style);
    }
    
    // T: length of one beat
    // beats: how many beats in a measure
    // style: basic rhythmic structure (backbeats, doubletime, syncopated)
    public void algo(dur T, int beats, string style)
    {
        if (style == "backbeat")
        {
            for (int i; i < beats; i++)
            {
                if ((i != 0) && (i % 2 != 0))
                {
                    Math.randomf() => float choice;
                    if (choice < 0.8)
                    {
                        trigger(T, 1, Math.random2f(baseGain, baseGain + 0.2));
                    }
                    else
                    {
                        trigger(T, 0.75, Math.random2f(baseGain, baseGain + 0.2));
                        trigger(T, 0.25, Math.random2f(baseGain - 0.2, baseGain));
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
                    trigger(T, 1, Math.random2f(baseGain, baseGain + 0.2));
                }
                else if (i == beats-1)
                {
                    Math.randomf() => float choice;
                    if (choice < 0.8)
                    {
                        trigger(T, 0.5, Math.random2f(baseGain - 0.1, baseGain + 0.1));
                    }
                    else
                    {
                        trigger(T, 0.25, Math.random2f(baseGain - 0.1, baseGain));
                        trigger(T, 0.25, Math.random2f(baseGain, baseGain + 0.1));
                    }
                }
                else
                {
                    trigger(T, 1, Math.random2f(baseGain - 0.1, baseGain + 0.1));
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
                    trigger(T, 0.75, Math.random2f(baseGain, baseGain + 0.2));
                    trigger(T, 0.5, Math.random2f(baseGain - 0.1, baseGain + 0.1));
                }
                else if (i == on-1)
                {
                    trigger(T, 0.75, 0);
                    
                    Math.randomf() => float choice;
                    if (choice < 0.5)
                    {
                        trigger(T, 0.75, Math.random2f(baseGain, baseGain + 0.2));
                        trigger(T, 0.5, Math.random2f(baseGain - 0.1, baseGain + 0.1));
                    }
                    else
                    {
                        trigger(T, 0.75, Math.random2f(baseGain, baseGain + 0.2));
                        trigger(T, 0.25, Math.random2f(baseGain - 0.1, baseGain));
                        trigger(T, 0.25, Math.random2f(baseGain, baseGain + 0.1));
                    }
                }
                else
                {
                    trigger(T, 0.75, 0);
                    trigger(T, 0.75, Math.random2f(baseGain, baseGain + 0.2));
                    trigger(T, 0.5, Math.random2f(baseGain - 0.1, baseGain + 0.1));
                }
            }
            
            for (int j; j < off; j++)
            {
                Math.randomf() => float choice;
                if (choice < 0.3 || beats == 1)
                {
                    trigger(T, 0.5, 0);
                    trigger(T, 0.5, Math.random2f(baseGain - 0.1, baseGain));
                }
                else
                {
                    trigger(T, 1, 0);
                }
            }
        } 
    }
    
    // T: length of one beat
    // beats: how many beats in a measure
    // style: basic rhythmic structure (4-on-the-floor, onbeats, syncopated)
    // prob[]: splits for rhythm choices; "sync" uses two floats, other styles use one
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
                        trigger(T, 1, Math.random2f(baseGain, baseGain + 0.2));
                    }
                    else
                    {
                        trigger(T, 0.75, Math.random2f(baseGain, baseGain + 0.2));
                        trigger(T, 0.25, Math.random2f(baseGain - 0.2, baseGain));
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
                    trigger(T, 1, Math.random2f(baseGain, baseGain + 0.2));
                }
                else if (i == beats-1)
                {
                    Math.randomf() => float choice;
                    if (choice < prob[0])
                    {
                        trigger(T, 0.5, Math.random2f(baseGain - 0.1, baseGain + 0.1));
                    }
                    else
                    {
                        trigger(T, 0.25, Math.random2f(baseGain - 0.1, baseGain));
                        trigger(T, 0.25, Math.random2f(baseGain, baseGain + 0.1));
                    }
                }
                else
                {
                    trigger(T, 1, Math.random2f(baseGain - 0.1, baseGain + 0.1));
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
                    trigger(T, 0.75, Math.random2f(baseGain, baseGain + 0.2));
                    trigger(T, 0.5, Math.random2f(baseGain - 0.1, baseGain + 0.1));
                }
                else if (i == on-1)
                {
                    trigger(T, 0.75, 0);
                    
                    Math.randomf() => float choice;
                    if (choice < prob[0])
                    {
                        trigger(T, 0.75, Math.random2f(baseGain, baseGain + 0.2));
                        trigger(T, 0.5, Math.random2f(baseGain - 0.1, baseGain + 0.1));
                    }
                    else
                    {
                        trigger(T, 0.75, Math.random2f(baseGain, baseGain + 0.2));
                        trigger(T, 0.25, Math.random2f(baseGain - 0.1, baseGain));
                        trigger(T, 0.25, Math.random2f(baseGain, baseGain + 0.1));
                    }
                }
                else
                {
                    trigger(T, 0.75, 0);
                    trigger(T, 0.75, Math.random2f(baseGain, baseGain + 0.2));
                    trigger(T, 0.5, Math.random2f(baseGain - 0.1, baseGain + 0.1));
                }
            }
            
            for (int j; j < off; j++)
            {
                Math.randomf() => float choice;
                if (choice < prob[1] || beats == 1)
                {
                    trigger(T, 0.5, 0);
                    trigger(T, 0.5, Math.random2f(baseGain - 0.1, baseGain));
                }
                else
                {
                    trigger(T, 1, 0);
                }
            }
        } 
    }
}