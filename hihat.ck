// class definition for the hh instrument

// METHODS:
// gain: set buffer gain level
// mix: set reverb mix level
// connect: attach to specified ugen
// changeFile: read new file as the instrument sample
// help: print function & arg explanations
// trigger: [private] play sample at specified dur & gain
// algo(dur T, int x, float triplets, float splits[5]);

public class HH
{
    SndBuf hBuf => NRev hn;
    "808_Hat_Closed.wav" => string sample;
    me.dir() + sample => hBuf.read;

    // default settings
    0.5 => float g;
    0.02 => float rev;
    0.8::second => dur len;
    4 => int beats;
    0.5 => float triplets;
    [0.1, 0.6, 0.1, 0.6, 0.8] @=> float splits[];
    
    g => hBuf.gain;
    rev => hn.mix;
    
    public void gain(float gIn)
    {
        gIn => g => hBuf.gain;
    }
    
    public void mix(float m)
    {
        m => rev => hn.mix;
    }
    
    public void connect(UGen ugen)
    { 
        hn => ugen; 
    }
    
    public void changeFile(string str)
    {
        
        if (str != sample)
        {
            me.dir() + str => hBuf.read;
        }
        
        str => sample;
    }
    
    public void help()
    {
        <<<"HH has the following functions:">>>;
        <<<"gain(float): sets gain">>>;
        <<<"mix(float): sets reverb level">>>;
        <<<"connect(UGen): connects HH to other Chuck UGens">>>;
        <<<"changeFile(string): reads new file as instrument sample">>>;
        <<<"algo(dur T, int x, int triplets, float splits[5])">>>;
        <<<"Generate x beats (dur T) of mixed triplet and straight rhythms">>>;
        <<<"Triplets: probability of rolling triplet 8ths vs. straight 8ths, 16ths, & 32nds">>>;
        <<<"Splits: 1st two are for 1st half of beat, next three are for 2nd half">>>;
        <<<"1st half: 8th, 16 16, or 32 32 16; 2nd half: 8th, 16 16, 32 32 16, or 32 32 32 32">>>;
        <<<"e.g. 1st half = splits 0.1, 0.6 --> 10% 8th, 50% 16 16, 40% 32 32 16">>>;
    }
    
    private void trigger(dur T, float len, float g)
    {
        0 => hBuf.pos;
        g => hBuf.gain;
        len::T => now;
    }
    
    // T: length of one beat
    // beats: how many beats in a measure
    // triplets: probability of triplets occurring (where 1 = always)
    // splits: split between different rhythms
    public void algo(dur T, int beats, float triplets, float splits[])
    {
        // for each beat in bar
        0 => int j;
        for (j; j < beats; j++)
        {
            0 => hBuf.pos;
            
            float gainFunc;
            if (g > 0)
            {
                g + (j * 0.1) => gainFunc;
            }
            
            // choose between triplets vs. n8/n16/n32
            Math.randomf() => float roll;
            1.0 / 6.0 => float t;
            
            if (roll < triplets)
            {
                for (int k; k < 6; k++)
                {
                    trigger(T, t, gainFunc);
                }
            }
            else
            {
                // 1st half of the beat
                // n8, n16 n16, or n32 n32 n16
                Math.randomf() => float choice;
                if (choice < splits[0]) 
                {
                    trigger(T, 0.5, gainFunc);
                }
                else if (choice < splits[1])
                {
                    trigger(T, 0.25, gainFunc);
                    trigger(T, 0.25, gainFunc);
                }
                else
                {
                    trigger(T, 0.125, gainFunc);
                    trigger(T, 0.125, gainFunc);
                    trigger(T, 0.25, gainFunc);
                }
                
                // 2nd half of the beat
                // n8, n16 n16, n32 n32 n16, or n32 n32 n32 n32
                Math.randomf() => float choice2;
                if (choice2 < splits[2]) 
                {
                    trigger(T, 0.5, gainFunc);
                }
                else if (choice2 < splits[3])
                {
                    trigger(T, 0.25, gainFunc);
                    trigger(T, 0.25, gainFunc);
                }
                else if (choice2 < splits[4])
                {
                    trigger(T, 0.125, gainFunc);
                    trigger(T, 0.125, gainFunc);
                    trigger(T, 0.25, gainFunc);
                }
                else
                {
                    trigger(T, 0.125, gainFunc);
                    trigger(T, 0.125, gainFunc);
                    trigger(T, 0.125, gainFunc);
                    trigger(T, 0.125, gainFunc);
                }        
            }
        }
    }
}