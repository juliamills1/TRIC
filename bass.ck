// class definition for the bb instrument

// METHODS:
// gain: set oscillator gain level
// mix: set reverb mix level
// connect: attach to specified ugen
// help: print function & arg explanations
// algo(dur, int): beats of synchronized+straight patterns
// algo(dur, int, int): + specify tonic
// algo(dur, int, int, int[]): + specify pitch classes to choose from
// algo(dur, int, int, int[], int): + specify # of additional octaves

public class BB
{
    TriOsc s => JCRev j;
    0.2 => s.gain;
    0.02 => float baseMix;
    baseMix => j.mix;
    
    public void gain(float g)
    {
        g => s.gain;
    }
    
    public void mix(float m)
    {
        m => j.mix;
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
        <<<"connect(UGen): connects BB to other Chuck UGens">>>;
        <<<"algo(dur T, int x): generate x beats with dur T">>>;
        <<<"algo(dur, int, int): + specify tonic (midi number)">>>;
        <<<"algo(dur, int, int, int[]): + specify pitch classes to choose from">>>;
        <<<"algo(dur, int, int, int[], int): + specify # of additional octaves">>>;
    }

    // T: length of one beat
    // beats: how many beats in a measure
    public void algo(dur T, int beats)
    {
        // pitch classes to choose from
        [ 0, 1, 4, 7, 8, 11] @=> int scale[];
        
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
        
        0 => int i;
        float freq;
        
        for (i; i < sync; i++)
        {
            scale[0] => freq;    
            Std.mtof(43) => s.freq;
            
            // 1st n4d of bar: n4d or n8d n8d
            if (Math.randomf() < 0.2) 
            {
                1.5::T => now;
            }
            else
            {
                0.75::T => now;
                scale[ Math.random2(0,5) ] => freq;  
                Std.mtof( 43 + (Math.random2(0,1)*12 + freq) ) => s.freq;
                0.75::T => now;
            }
    
            // 2nd n4d of bar: n4d or n8d n8d
            scale[ Math.random2(0,5) ] => freq; 
            Std.mtof( 43 + (Math.random2(0,1)*12 + freq) ) => s.freq;
    
            if (Math.randomf() < 0.15) 
            {
                1.5::T => now;
            }
            else
            {
                0.75::T => now;
                scale[ Math.random2(0,5) ] => freq;  
                Std.mtof( 43 + (Math.random2(0,1)*12 + freq) ) => s.freq;
                0.75::T => now;
            }
        }
    
        for (int j; j < straight; j++)
        {
            if (straight == 3 && j == 0)
            {
                scale[0] => freq;    
                Std.mtof(43) => s.freq;
            }
            else
            {
                scale[ Math.random2(1,5) ] => freq;   
                Std.mtof( 43 + (Math.random2(0,1)*12 + freq) ) => s.freq;
            }
            
            if (Math.randomf() < 0.6) 
            {
                1::T => now;
            }
            else
            {
                0.5::T => now;
                scale[ Math.random2(0,5) ] => freq;  
                Std.mtof( 43 + (Math.random2(0,1)*12 + freq) ) => s.freq;
                0.5::T => now;
            }
        }
    }
    
    // T: length of one beat
    // beats: how many beats in a measure
    // tonic: midi note of tonic (pitch class 0)
    public void algo(dur T, int beats, int tonic)
    {
        // pitch classes to choose from
        [ 0, 1, 4, 7, 8, 11] @=> int scale[];
        
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
        
        0 => int i;
        float freq;
        
        for (i; i < sync; i++)
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
                scale[ Math.random2(0,5) ] => freq;  
                Std.mtof( tonic + (Math.random2(0,1)*12 + freq) ) => s.freq;
                0.75::T => now;
            }
            
            // 2nd n4d of bar: n4d or n8d n8d
            scale[ Math.random2(0,5) ] => freq; 
            Std.mtof( tonic + (Math.random2(0,1)*12 + freq) ) => s.freq;
            
            if (Math.randomf() < 0.15) 
            {
                1.5::T => now;
            }
            else
            {
                0.75::T => now;
                scale[ Math.random2(0,5) ] => freq;  
                Std.mtof( tonic + (Math.random2(0,1)*12 + freq) ) => s.freq;
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
                scale[ Math.random2(1,5) ] => freq;   
                Std.mtof( tonic + (Math.random2(0,1)*12 + freq) ) => s.freq;
            }
            
            if (Math.randomf() < 0.6) 
            {
                1::T => now;
            }
            else
            {
                0.5::T => now;
                scale[ Math.random2(0,5) ] => freq;  
                Std.mtof( tonic + (Math.random2(0,1)*12 + freq) ) => s.freq;
                0.5::T => now;
            }
        }
    }
    
    // T: length of one beat
    // beats: how many beats in a measure
    // tonic: midi note of tonic (pitch class 0)
    // scale[]: which pitch classes to choose from
    public void algo(dur T, int beats, int tonic, int scale[])
    {
        scale.size()-1 => int numPitches;
        
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
        
        0 => int i;
        float freq;
        
        for (i; i < sync; i++)
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
                Std.mtof( tonic + (Math.random2(0,1)*12 + freq) ) => s.freq;
                0.75::T => now;
            }
            
            // 2nd n4d of bar: n4d or n8d n8d
            scale[ Math.random2(0,numPitches) ] => freq; 
            Std.mtof( tonic + (Math.random2(0,1)*12 + freq) ) => s.freq;
            
            if (Math.randomf() < 0.15) 
            {
                1.5::T => now;
            }
            else
            {
                0.75::T => now;
                scale[ Math.random2(0,numPitches) ] => freq;  
                Std.mtof( tonic + (Math.random2(0,1)*12 + freq) ) => s.freq;
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
                Std.mtof( tonic + (Math.random2(0,1)*12 + freq) ) => s.freq;
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
                Std.mtof( tonic + (Math.random2(0,1)*12 + freq) ) => s.freq;
                0.5::T => now;
            }
        }
    }
    
    // T: length of one beat
    // beats: how many beats in a measure
    // tonic: midi note of tonic (pitch class 0)
    // scale[]: which pitch classes to choose from
    // octaves: how many additional octaves instrument has
    public void algo(dur T, int beats, int tonic, int scale[], int octaves)
    {
        scale.size()-1 => int numPitches;
        
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
        
        0 => int i;
        float freq;
        
        for (i; i < sync; i++)
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