ConsoleInput in;
StringTokenizer tok;

BB bass;
CC clap;
HH hihat;
KK kick;

// synchronize to period
.8::second => dur T;
T - (now % T) => now;
Gain g => dac;

// Bass state variables
0.2 => float bassGain;
0.02 => float bassMix;
2 => int bassAlgoArgs;
T => dur bassDur;
4 => int bassBeats;
45 => int bassTonic;
[ 0, 1, 4, 7, 8, 11] @=> int bassPitchClasses[];
1 => int bassOctaves;

// Clap state variables
0.5 => float clapGain;
0.02 => float clapMix;
3 => int clapAlgoArgs;
0 => int clapRandomOn;
T => dur clapDur;
4 => int clapBeats;
"backbeat" => string clapStyle;
[0.8, 0.5] @=> float clapProbs[];
2 => int clapReps;

// Hi-hat state variables
0.2 => float hhGain;
0.02 => float hhMix;
2 => int hhAlgoArgs;
T => dur hhDur;
4 => int hhBeats;
0 => int hhTriplets;
[0.1, 0.6, 0.1, 0.6, 0.8] @=> float hhProbs[];

// Kick state variables
0.5 => float kickGain;
0.02 => float kickMix;
3 => int kickAlgoArgs;
0 => int kickRandomOn;
T => dur kickDur;
4 => int kickBeats;
"club" => string kickStyle;
[0.5, 0.75] @=> float kickProbs[];
2 => int kickReps;

bass.connect(g);
clap.connect(g);
hihat.connect(g);
kick.connect(g);

spork ~ messageListen();

while(true)
{
    bass.gain(bassGain);
    bass.mix(bassMix);
    clap.gain(clapGain);
    clap.mix(clapMix);
    hihat.gain(hhGain);
    hihat.mix(hhMix);
    kick.gain(kickGain);
    kick.mix(kickMix);
    
    // ----- BASS FUNCTION MAPPING -----
    if (bassAlgoArgs == 2)
    {
        spork ~ bass.algo(bassDur, bassBeats);
    }
    else if (bassAlgoArgs == 3)
    {
        spork ~ bass.algo(bassDur, bassBeats, bassTonic);
    }
    else if (bassAlgoArgs == 4)
    {
        spork ~ bass.algo(bassDur, bassBeats, bassTonic, bassPitchClasses);
    }
    else if (bassAlgoArgs == 5)
    {
        spork ~ bass.algo(bassDur, bassBeats, bassTonic, bassPitchClasses, bassOctaves);
    }
    else
    {
        <<<"That number of args is not supported!">>>;
        2 => bassAlgoArgs;
    }
    
    // ----- CLAP FUNCTION MAPPING -----
    if (clapRandomOn == 0)
    {
        if (clapAlgoArgs == 3)
        {
            spork ~ clap.algo(clapDur, clapBeats, clapStyle);
        }
        else if (clapAlgoArgs == 4)
        {
            spork ~ clap.algo(clapDur, clapBeats, clapStyle, clapProbs);
        }
        else
        {
            <<<"That number of args is not supported!">>>;
            3 => clapAlgoArgs;
        }
    }
    else
    {
        spork ~ clap.randomStyle(clapDur, clapBeats, clapReps);
    }
    
    // ----- HI-HAT FUNCTION MAPPING -----
    if (hhAlgoArgs == 2)
    {
        spork ~ hihat.algo(hhDur, hhBeats);
    }
    else if (hhAlgoArgs == 3)
    {
        spork ~ hihat.algo(hhDur, hhBeats, hhTriplets);
    }
    else if (hhAlgoArgs == 4)
    {
        spork ~ hihat.algo(hhDur, hhBeats, hhTriplets, hhProbs);
    }
    else
    {
        <<<"That number of args is not supported!">>>;
        2 => hhAlgoArgs;
    }
    
    // ----- KICK FUNCTION MAPPING -----
    if (kickRandomOn == 0)
    {
        if (kickAlgoArgs == 3)
        {
            kick.algo(kickDur, kickBeats, kickStyle);
        }
        else if (kickAlgoArgs == 4)
        {
            kick.algo(kickDur, kickBeats, kickStyle, kickProbs);
        }
        else
        {
            <<<"That number of args is not supported!">>>;
            3 => kickAlgoArgs;
        }
    }
    else
    {
        kick.randomStyle(kickDur, kickBeats, kickReps);
    }
}

fun void messageListen()
{
    while( true )
    {
        in.prompt( "enter command:" ) => now;

        while( in.more() )
        {
            tok.set( in.getLine() );
            tok.next() => string inst;
            tok.next() => string command;
            
            if (inst == "BB")
            {
                sendBBEdit(command);
            }
            else if (inst == "CC")
            {
                sendCCEdit(command);
            }
            else if (inst == "HH")
            {
                sendHHEdit(command);
            }
            else if (inst == "KK")
            {
                sendKKEdit(command);
            }
        }
    }
}

fun string funcParser(string command)
{
    string funcName;
    command.find('(') => int fp;
    command.find(')') => int sp;
    
    if (fp == -1 || sp == -1)
    {
        <<<"Incorrect format: requires complete ()">>>;
        return "";
    }
    else
    {
        command.substring(0, fp) => funcName;
    }
    return funcName;
}

fun string[] argParser(string command)
{
    command.find('(') => int fp;
    command.find(')') => int sp;
    
    command.find('[') => int fb;
    command.find(']') => int sb;
    string subArray;
    int subArrayIndex;
    
    if (fb != -1 && sb != -1)
    {
        command.substring(fb+1, sb-fb-1) => subArray;
        command.erase(fb, sb-fb+1);
        command.insert(fb, "subArray");
        command.find(')') => sp;
    }
    
    int commas[0];
    -1 => int lastIndexFound;
    for(int i; i < sp; i++)
    {
        command.find(',', i) => int indexFound;
        if (indexFound != -1 && indexFound != lastIndexFound)
        {
            commas << command.find(',', i);
            indexFound => lastIndexFound;
        }
    }
    
    commas.size() + 1 => int numArgs;
    string arg[0];
    for(int i; i < numArgs; i++)
    {
        string thisArg;
        if (i == 0)
        {
            if (numArgs == 1)
            {
                command.substring(fp+1,sp-fp-1) => thisArg;
            }
            else
            {
                command.substring(fp+1,commas[i]-fp-1) => thisArg;
            }
        }
        else if (i == numArgs-1)
        {
            command.substring(commas[i-1]+1, sp-commas[i-1]-1) => thisArg;
        }
        else
        {
            command.substring(commas[i-1]+1,commas[i]-commas[i-1]-1) => thisArg;
        }
        
        arg << thisArg;
        if (thisArg == "subArray")
        {
            arg.size()-1 => subArrayIndex;
        }
    }
    
    if (subArray != "")
    {
        subArray @=> arg[subArrayIndex];
    }
    
    return arg;
}

fun int[] intSubArrayParser(string str)
{
    argParser("(" + str + ")") @=> string subArgs[];
    int intArgs[subArgs.size()];
    
    for (int i; i < subArgs.size(); i++)
    {
        Std.atoi(subArgs[i]) => intArgs[i];
    }
    return intArgs;
}

fun float[] floatSubArrayParser(string str)
{
    argParser("(" + str + ")") @=> string subArgs[];
    float floatArgs[subArgs.size()];
    
    for (int i; i < subArgs.size(); i++)
    {
        Std.atof(subArgs[i]) => floatArgs[i];
    }
    return floatArgs;
}

fun dur strToDur(string str, dur fallback)
{
    if (str == "T")
    {
        return T;
    }
    else if (Std.atof(str) == 0)
    {
        <<<"arg[0] cannot be converted to dur!">>>;
        return fallback;
    }
    
    return Std.atof(str)::second;
}

fun void sendBBEdit(string command)
{
    funcParser(command) => string funcName;
    string arg[];
    if (funcName != "")
    {
        argParser(command) @=> arg;
    }
    
    if (funcName == "algo")
    {
        arg.size() => bassAlgoArgs;
        for (int i; i < bassAlgoArgs; i++)
        {
            if (i == 0)
            {
                strToDur(arg[0], bassDur) => bassDur;
            }
            else if (i == 1)
            {
                Std.atoi(arg[1]) => bassBeats;
            }
            else if (i == 2)
            {
                Std.atoi(arg[2]) => bassTonic;
            }
            else if (i == 3)
            {
                intSubArrayParser(arg[3]) @=> bassPitchClasses;
            }
            else if (i == 4)
            {
                Std.atoi(arg[4]) => bassOctaves;
            }
        }
    }
    else if (funcName == "mix")
    {
        Std.atof(arg[0]) => bassMix;
    }
    else if (funcName == "gain")
    {
        Std.atof(arg[0]) => bassGain;
    }
    else if (funcName == "help")
    {
        bass.help();
    }
    else
    {
        <<<"BB does not have that function">>>;
    }
}
    
fun void sendCCEdit(string command)
{
    funcParser(command) => string funcName;
    string arg[];
    if (funcName != "")
    {
        argParser(command) @=> arg;
    }
    
    if (funcName == "algo")
    {
        0 => clapRandomOn;
        arg.size() => clapAlgoArgs;
        for (int i; i < clapAlgoArgs; i++)
        {
            if (i == 0)
            {
                strToDur(arg[0], clapDur) => clapDur;
            }
            else if (i == 1)
            {
                Std.atoi(arg[1]) => clapBeats;
            }
            else if (i == 2)
            {
                if (arg[2] == "backbeat" || arg[2] == "doubletime" || arg[2] == "sync")
                {
                    arg[2] => clapStyle;
                }
                else
                {
                    <<<"Invalid CC style; valid choices: backbeat, doubletime, sync">>>;
                }
            }
            else if (i == 3)
            {
                floatSubArrayParser(arg[3]) @=> clapProbs;
            }
        }
    }
    else if (funcName == "randomStyle")
    {
        1 => clapRandomOn;
        strToDur(arg[0], clapDur) => clapDur;
        Std.atoi(arg[1]) => clapBeats;
        Std.atoi(arg[2]) => clapReps;
    }
    else if (funcName == "mix")
    {
        Std.atof(arg[0]) => clapMix;
    }
    else if (funcName == "gain")
    {
        Std.atof(arg[0]) => clapGain;
    }
    else if (funcName == "help")
    {
        clap.help();
    }
    else
    {
        <<<"CC does not have that function">>>;
    }
}
    
fun void sendHHEdit(string command)
{
    funcParser(command) => string funcName;
    string arg[];
    if (funcName != "")
    {
        argParser(command) @=> arg;
    }
    
    if (funcName == "algo")
    {
        arg.size() => hhAlgoArgs;
        for (int i; i < hhAlgoArgs; i++)
        {
            if (i == 0)
            {
                strToDur(arg[0], hhDur) => hhDur;
            }
            else if (i == 1)
            {
                Std.atoi(arg[1]) => hhBeats;
            }
            else if (i == 2)
            {
                Std.atoi(arg[2]) => hhTriplets;
            }
            else if (i == 3)
            {
                floatSubArrayParser(arg[3]) @=> hhProbs;
            }
        }
    }
    else if (funcName == "mix")
    {
        Std.atof(arg[0]) => hhMix;
    }
    else if (funcName == "gain")
    {
        Std.atof(arg[0]) => hhGain;
    }
    else if (funcName == "help")
    {
        hihat.help();
    }
    else
    {
        <<<"HH does not have that function">>>;
    }
}
    
fun void sendKKEdit(string command)
{
    funcParser(command) => string funcName;
    string arg[];
    if (funcName != "")
    {
        argParser(command) @=> arg;
    }
    
    if (funcName == "algo")
    {
        0 => kickRandomOn;
        arg.size() => kickAlgoArgs;
        for (int i; i < kickAlgoArgs; i++)
        {
            if (i == 0)
            {
                strToDur(arg[0], kickDur) => kickDur;
            }
            else if (i == 1)
            {
                Std.atoi(arg[1]) => kickBeats;
            }
            else if (i == 2)
            {
                if (arg[2] == "club" || arg[2] == "rock" || arg[2] == "sync")
                {
                    arg[2] => kickStyle;
                }
                else
                {
                    <<<"Invalid KK style; valid choices: club, rock, sync">>>;
                }
            }
            else if (i == 3)
            {
                floatSubArrayParser(arg[3]) @=> kickProbs;
            }
        }
    }
    else if (funcName == "randomStyle")
    {
        1 => kickRandomOn;
        if (arg.size() >= 3)
        {
            strToDur(arg[0], kickDur) => kickDur;
            Std.atoi(arg[1]) => kickBeats;
            Std.atoi(arg[2]) => kickReps;
        }
        else
        {
            <<<"Invalid number of args for given function">>>;
        }
    }
    else if (funcName == "mix")
    {
        Std.atof(arg[0]) => kickMix;
    }
    else if (funcName == "gain")
    {
        Std.atof(arg[0]) => kickGain;
    }
    else if (funcName == "help")
    {
        kick.help();
    }
    else
    {
        <<<"KK does not have that function">>>;
    }
}
