// class definition for the hh instrument

// METHODS:
// gain: set buffer gain level
// mix: set reverb mix level
// connect: attach to specified ugen
// help: print function & arg explanations
// trigger: [private] play sample at specified dur & gain
// algo(dur, int): beats of randomized triplets or n8/n16/n32 patterns
// algo(dur, int, int): + specify triplets on/off
// algo(dur, int, int, float[5]): + specify probability splits between rhythms

public class HH
{
    SndBuf hBuf => NRev hn;
    me.dir() + "808_Hat_Closed.wav" => hBuf.read;
    0.2 => float baseGain;
    0.02 => hn.mix;
    
    public void gain(float g)
    {
        g => baseGain => hBuf.gain;
    }
    
    public void mix(float m)
    {
        m => hn.mix;
    }
    
    public void connect(UGen ugen)
    { 
        hn => ugen; 
    }
    
    public void help()
    {
        <<<"HH has the following functions:">>>;
        <<<"gain(float): sets gain">>>;
        <<<"mix(float): sets reverb level">>>;
        <<<"connect(UGen): connects CC to other Chuck UGens">>>;
        <<<"algo(dur T, int x): generate x beats with dur T">>>;
        <<<"algo(dur, int, int): + specify triplets on/off">>>;
        <<<"algo(dur, int, int, float[5]): + specify probability splits">>>;
    }
    
    private void trigger(dur T, float len, float g)
    {
        0 => hBuf.pos;
        g => hBuf.gain;
        len::T => now;
    }
    
    // T: length of one beat
    // beats: how many beats in a measure
    public void algo(dur T, int beats)
    {
        // for each beat in bar
        0 => int j;
        for (j; j < beats; j++)
        {
            0 => hBuf.pos;
            float gainFunc;
            if (baseGain > 0)
            {
                baseGain + (j * 0.1) => gainFunc;
            }
            
            // choose between triplets vs. n8/n16/n32
            Math.random2(0,1) => int triplets;
            1.0 / 6.0 => float t;
            
            if(triplets == 1)
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
                if (choice < 0.1) 
                {
                    trigger(T, 0.5, gainFunc);
                }
                else if (choice < 0.6)
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
                if (choice2 < 0.1) 
                {
                    trigger(T, 0.5, gainFunc);
                }
                else if (choice2 < 0.6)
                {
                    trigger(T, 0.25, gainFunc);
                    trigger(T, 0.25, gainFunc);
                }
                else if (choice2 < 0.8)
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
    
    // T: length of one beat
    // beats: how many beats in a measure
    // triplets: 0 = no triplets, 1 = triplets
    public void algo(dur T, int beats, int triplets)
    {
        // for each beat in bar
        0 => int j;
        for (j; j < beats; j++)
        {
            0 => hBuf.pos;
            float gainFunc;
            if (baseGain > 0)
            {
                baseGain + (j * 0.1) => gainFunc;
            }
            
            // choose between triplets vs. n8/n16/n32
            1.0 / 6.0 => float t;
            
            if(triplets == 1)
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
                if (choice < 0.1) 
                {
                    trigger(T, 0.5, gainFunc);
                }
                else if (choice < 0.6)
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
                if (choice2 < 0.1) 
                {
                    trigger(T, 0.5, gainFunc);
                }
                else if (choice2 < 0.6)
                {
                    trigger(T, 0.25, gainFunc);
                    trigger(T, 0.25, gainFunc);
                }
                else if (choice2 < 0.8)
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
    
    // T: length of one beat
    // beats: how many beats in a measure
    // triplets: 0 = no triplets, 1 = triplets
    // splits: split between different rhythms
    public void algo(dur T, int beats, int triplets, float splits[])
    {
        // for each beat in bar
        0 => int j;
        for (j; j < beats; j++)
        {
            0 => hBuf.pos;
            float gainFunc;
            if (baseGain > 0)
            {
                baseGain + (j * 0.1) => gainFunc;
            }
            
            // choose between triplets vs. n8/n16/n32
            1.0 / 6.0 => float t;
            
            if(triplets == 1)
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