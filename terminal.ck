// terminal input reader
ConsoleInput in;
StringTokenizer tok;

// presets reader
FileIO fio;
me.dir() + "presets.txt" => string pFile;
fio.open(pFile, FileIO.READ);
StringTokenizer pTok;
string presets[0];

// instrument classes
AA arp;
BB bass;
CC clap;
HH hihat;
KK kick;

// synchronize to period
.8::second => dur T;
T - (now % T) => now;
Gain g => dac;
T => arp.len => bass.len => hihat.len => clap.len => kick.len;

// synth modes
"" => string lastArpScaleType;
-1 => int lastArpScaleNum;
"" => string lastBassScaleType;
-1 => int lastBassScaleNum;

hihat.g => float hhGain;
0 => hihat.triplets;

clap.g => float clapGain;
0 => int clapRandomOn;

kick.g => float kickGain;
0 => int kickRandomOn;

// send instruments' output to dac
arp.connect(g);
bass.connect(g);
clap.connect(g);
hihat.connect(g);
kick.connect(g);

// TO DO: allow for preset changes on the fly
loadPresets();
spork ~ messageListen();

while (true)
{
    // send all gain and reverb level edits
    arp.gain(arp.g);
    arp.mix(arp.rev);
    bass.gain(bass.g);
    bass.mix(bass.rev);
    hihat.gain(hhGain);
    hihat.mix(hihat.rev);
    clap.gain(clapGain);
    clap.mix(clap.rev);
    kick.gain(kickGain);
    kick.mix(kick.rev);
    
    // apply changes to synth scales
    if (arp.scaleNum != lastArpScaleNum || arp.scaleType != lastArpScaleType)
    {
        arp.mode(arp.scaleType, arp.scaleNum);
        arp.scaleNum => lastArpScaleNum; 
        arp.scaleType => lastArpScaleType;
    }
    if (bass.scaleNum != lastBassScaleNum || bass.scaleType != lastBassScaleType)
    {
        bass.mode(bass.scaleType, bass.scaleNum);
        bass.scaleNum => lastBassScaleNum; 
        bass.scaleType => lastBassScaleType;
    }
    
    spork ~ arp.algo(arp.len, arp.beats, arp.tonic, arp.cycle, arp.direction, arp.pitchClasses);
    spork ~ bass.algo(bass.len, bass.beats, bass.tonic, bass.pitchClasses, bass.addOctaves);
    // TO DO: hihat triplets are not properly randomized - make arg probability, not toggle
    spork ~ hihat.algo(hihat.len, hihat.beats, hihat.triplets, hihat.splits);
    
    // spork relevant clap function
    if (clapRandomOn == 0)
    {
        spork ~ clap.algo(clap.len, clap.beats, clap.style, clap.splits);
    }
    else
    {
        spork ~ clap.randomStyle(clap.len, clap.beats, clap.reps);
    }
    
    // spork relevant kick function
    if (kickRandomOn == 0)
    {
        kick.algo(kick.len, kick.beats, kick.style, kick.splits);
    }
    else
    {
        kick.randomStyle(kick.len, kick.beats, kick.reps);
    }
}

// parse presets file into array of commands
fun void loadPresets()
{
    // check file is parseable
    if (!fio.good())
    {
        cherr <= "can't open file: " <= pFile <= " for reading..."
              <= IO.newline();
        me.exit();
    }
    
    // send each line of file to array slot
    while (fio.more())
    {
        presets << fio.readLine();
    }
}

// get input from terminal
fun void messageListen()
{
    while (true)
    {
        in.prompt("enter command:") => now;

        while (in.more())
        {
            tok.set(in.getLine());
            tok.next() => string inst;
            tok.next() => string command;
            commandRouter(inst, command);
        }
    }
}

// send command info to corresponding instrument(s)
fun void commandRouter(string instIn, string command)
{
    instIn.upper() => string inst;
    
    if (inst == "P")
    {
        sendPreset(command);
    }
    else if (inst == "G")
    {
        sendAAEdit(command);
        sendBBEdit(command);
        sendCCEdit(command);
        sendHHEdit(command);
        sendKKEdit(command);
    }
    else if (inst == "S")
    {
        sendAAEdit(command);
        sendBBEdit(command);
    }
    else if (inst == "D")
    {
        sendCCEdit(command);
        sendHHEdit(command);
        sendKKEdit(command);
    }
    else if (inst == "AA")
    {
        sendAAEdit(command);
    }
    else if (inst == "BB")
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

// return function name
fun string funcParser(string command)
{
    if (command == "")
    {
        <<<"Cannot find a command">>>;
        return "";
    }
    
    string funcName;
    command.find('(') => int fp;
    command.lower() => command;
    
    // check for parentheses
    if (fp == -1)
    {
        if (command == "help" || command == "modehelp")
        {
            // no arguments required
            return command;
        }
        else
        {
            <<<"Argument(s) required or function does not exist!">>>;
            return "";
        }
    }
    else
    {
        // return string up to first parentheses
        command.substring(0, fp) => funcName;
    }
    return funcName;
}

// return array of arguments from input
fun string[] argParser(string command)
{
    // find argument list boundaries
    command.find('(') => int fp;
    command.find(')') => int sp;
    
    // look for any sub-arrays
    command.find('[') => int fb;
    command.find(']') => int sb;
    string subArray;
    int subArrayIndex;
    
    // if there is a sub-array
    if (fb != -1 && sb != -1)
    {
        // transfer sub-array contents to new string & replace with placeholder
        command.substring(fb + 1, sb - fb - 1) => subArray;
        command.replace(fb, sb - fb + 1, "subArray");
    }
    else if (fb != -1 && sb == -1)
    {
        <<<"Incomplete sub-array: skipping this argument and any following">>>;
        "-" => subArray;
        command.replace(fb, command.length() - fb, "-");
    }
    else if (sb != -1 && fb == -1)
    {
        <<<"Incomplete sub-array: erasing bracket & assuming all single value arguments">>>;
        command.erase(sb, 1);
    }

    int commas[0];
    -1 => int lastIndexFound;
    
    // if has closed parentheses, recalculate location
    if (sp != -1)
    {
        command.find(')') => sp;
    }
    else
    {
        // if not, use command.length() as proxy value
        command.length() => sp;
    }
    
    // remove any lagging commas
    while (command.charAt(sp - 1) == 44)
    {
        command.erase(sp - 1, 1);
        1 -=> sp;
    }
    
    // look through full argument list
    for(int i; i < sp; i++)
    {
        command.find(',', i) => int indexFound;
        
        // check index is new, extant, and not trailing
        if ((indexFound != -1) && (indexFound != lastIndexFound))
        {
            // update array
            commas << command.find(',', i);
            indexFound => lastIndexFound;
        }
    }
    
    string arg[0];
    int numArgs;
    if (fp != sp - 1)
    {
        commas.size() + 1 => numArgs;
    }
    
    // separate each argument according to comma indices
    for(int i; i < numArgs; i++)
    {
        string thisArg;
        
        // first argument
        if (i == 0)
        {
            // only argument
            if (numArgs == 1)
            {
                command.substring(fp + 1, sp - fp - 1) => thisArg;
            }
            else
            {
                command.substring(fp + 1, commas[i] - fp - 1) => thisArg;
            }
        }
        // last argument
        else if (i == numArgs - 1)
        {
            command.substring(commas[i-1] + 1, sp - commas[i-1] - 1) => thisArg;
        }
        else
        {
            command.substring(commas[i-1] + 1, commas[i] - commas[i-1] - 1) => thisArg;
        }
        
        // validate incoming argument before adding to array
        if (thisArg == "" || thisArg == ",")
        {
            arg << "-";
        }
        else
        {
            arg << thisArg;
        }
        
        if (thisArg == "subArray")
        {
            subArray @=> arg[arg.size() - 1];
        }
    }
    return arg;
}

// convert sub-array argument into array of ints
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

// convert sub-array argument into array of n floats
fun float[] floatSubArrayParser(string str, int n, float fallback[])
{
    argParser("(" + str + ")") @=> string subArgs[];
    float floatArgs[subArgs.size()];
    
    if (subArgs.size() != n) 
    {
        <<<"Incorrect number of sub-array items:", n, "required">>>;
        return fallback;
    }
    
    for (int i; i < subArgs.size(); i++)
    {
        Std.atof(subArgs[i]) => floatArgs[i];
    }
    return floatArgs;
}

// convert string argument to number of seconds (or global T)
fun dur strToDur(string str, dur fallback)
{
    if (str.upper() == "T")
    {
        return T;
    }
    else if (Std.atof(str) <= 0)
    {
        <<<"Argument cannot be converted to a duration!">>>;
        return fallback;
    }
    
    return Std.atof(str)::second;
}

// return 0 if argument is real
fun int skipArg(string str)
{
    if (str == "-") return 1;
    else return 0;
}

// return 0 if any arguments in array are real
fun int skipAllArgs(string arg[])
{
    for (int i; i < arg.size(); i++)
    {
        if (skipArg(arg[i]) == 0) return 0;
    }
    return 1;
}

// convert string argument to int if is a single value
fun int checkSingleVal(string str)
{
    if (str.find(',') != -1)
    {
        <<<"Sub-array located where single value should be! Skipping argument">>>;
        return 0;
    }
    return 1;
}

// print warning if more arguments than mapped parameters
fun void checkForExtra(string arg[], int max)
{
    if (arg.size() > max)
    {
        <<<"Warning: function received more arguments than useable">>>;
    }
}

// return 0 if array meets minimum size threshold
fun int checkForMin(string arg[], int min)
{
    if (arg.size() < min)
    {
        <<<"This function requires at least", min, "arguments">>>;
        return 1;
    }
    return 0;
}

// return 1 if array is non-null and contains real args
fun int hasRealArgs(string arg[])
{
    if (arg.size() < 1)
    {
        <<<"Argument(s) required or function does not exist!">>>;
        return 0;
    }
    else if (skipAllArgs(arg) == 1)
    {
        <<<"All arguments have been skipped!">>>;
        return 0;
    }
    return 1;
}

// parse presets.txt into corresponding command lines
fun void sendPreset(string command)
{
    Std.atoi(command) => int p;
    
    if (p >= presets.size())
    {
        <<<"That preset does not exist!">>>;
        return;
    }
    
    pTok.set(presets[p]);
    
    while (pTok.more())
    {
        pTok.next() => string inst;
        pTok.next() => string command;
        <<<inst, command>>>;
        commandRouter(inst, command);
    }
}

// AA class function & arg parsing
fun void sendAAEdit(string command)
{
    funcParser(command) => string funcName;
    
    // functions without arguments
    if (funcName == "help")
    {
        arp.help();
        return;
    }
    else if (funcName == "modehelp")
    {
        arp.modeHelp();
        return;
    }

    string arg[];
    
    // check function & arguments exist
    if (funcName != "" && command != funcName)
    {
        argParser(command) @=> arg;
        
        if (hasRealArgs(arg) == 0) return;
        
        if (funcName == "algo")
        {
            for (int i; i < arg.size(); i++)
            {
                if (skipArg(arg[i]) == 0)
                {   
                    if (i != 5 && checkSingleVal(arg[i]) == 0) return;
                    
                    if (i == 0)
                    {
                        strToDur(arg[0], arp.len) => arp.len;
                    }
                    else if (i == 1)
                    {
                        Std.atoi(arg[1]) => arp.beats;
                    }
                    else if (i == 2)
                    {
                        Std.atoi(arg[2]) => arp.tonic;
                    }
                    else if (i == 3)
                    {
                        Std.atoi(arg[3]) => arp.cycle;
                    }
                    else if (i == 4)
                    {
                        Std.atoi(arg[4]) => arp.direction;
                    }
                    else if (i == 5)
                    {
                        intSubArrayParser(arg[5]) @=> arp.pitchClasses;
                    }
                }
            }
            
            checkForExtra(arg, 6);
        }
        else if (funcName == "mix")
        {
            Std.atof(arg[0]) => arp.rev;
        }
        else if (funcName == "gain")
        {
            Std.atof(arg[0]) => arp.g;
        }
        else if (funcName == "mode")
        {
            if (checkForMin(arg, 2) == 1) return;
            
            if (skipArg(arg[0]) == 0)
            {
                arg[0] => arp.scaleType;
            }
            
            if (skipArg(arg[1]) == 0)
            {
                Std.atoi(arg[1]) => arp.scaleNum;
            }
        }
        else if (funcName == "tonic")
        {
            Std.atoi(arg[0]) => arp.tonic;
        }
        else
        {
            <<<"AA cannot find that function">>>;
        }
    }
}

// BB class function & arg parsing
fun void sendBBEdit(string command)
{
    funcParser(command) => string funcName;
    
    // functions without arguments
    if (funcName == "help")
    {
        bass.help();
        return;
    }
    else if (funcName == "modehelp")
    {
        bass.modeHelp();
        return;
    }
    
    string arg[];
    
    // check function & arguments exist
    if (funcName != "" && command != funcName)
    {
        argParser(command) @=> arg;
        
        if (hasRealArgs(arg) == 0) return;
        
        if (funcName == "algo")
        {   
            for (int i; i < arg.size(); i++)
            {
                if (skipArg(arg[i]) == 0)
                {
                    if (i != 3 && checkSingleVal(arg[i]) == 0) return;
                    
                    if (i == 0)
                    {
                        strToDur(arg[0], bass.len) => bass.len;
                    }
                    else if (i == 1)
                    {
                        Std.atoi(arg[1]) => bass.beats;
                    }
                    else if (i == 2)
                    {
                        Std.atoi(arg[2]) => bass.tonic;
                    }
                    else if (i == 3)
                    {
                        intSubArrayParser(arg[3]) @=> bass.pitchClasses;
                    }
                    else if (i == 4)
                    {
                        Std.atoi(arg[4]) => bass.addOctaves;
                    }
                }
            }
            
            checkForExtra(arg, 5);
        }
        else if (funcName == "mix")
        {
            Std.atof(arg[0]) => bass.rev;
        }
        else if (funcName == "gain")
        {
            Std.atof(arg[0]) => bass.g;
        }
        else if (funcName == "mode")
        {
            if (checkForMin(arg, 2) == 1) return;
            
            if (skipArg(arg[0]) == 0)
            {
                arg[0] => bass.scaleType;
            }
            
            if (skipArg(arg[1]) == 0)
            {
                Std.atoi(arg[1]) => bass.scaleNum;
            }
        }
        else if (funcName == "tonic")
        {
            Std.atoi(arg[0]) - 12 => bass.tonic;
        }
        else
        {
            <<<"BB cannot find that function">>>;
        }
    }
}
    
// CC class function & arg parsing 
fun void sendCCEdit(string command)
{
    funcParser(command) => string funcName;
    
    // functions without arguments
    if (funcName == "help")
    {
        clap.help();
        return;
    }
    
    string arg[];
    
    // check function & arguments exist
    if (funcName != "" && command != funcName)
    {
        argParser(command) @=> arg;
        
        if (arg.size() < 1)
        {
            <<<"Argument(s) required or function does not exist!">>>;
            return;
        }
        else if (skipAllArgs(arg) == 1)
        {
            // allow lack of arguments when switching between algo and randomStyle
            if ((funcName == "algo" && clapRandomOn == 0) ||
            (funcName == "randomstyle" && clapRandomOn == 1) ||
            (funcName == "gain") ||
            (funcName == "mix"))
            {
                <<<"All arguments have been skipped!">>>;
                return;
            }
        }
        
        if (funcName == "algo")
        {   
            for (int i; i < arg.size(); i++)
            {
                if (skipArg(arg[i]) == 0)
                {
                    if (i != 3 && checkSingleVal(arg[i]) == 0) return;
                    
                    if (i == 0)
                    {
                        strToDur(arg[0], clap.len) => clap.len;
                    }
                    else if (i == 1)
                    {
                        Std.atoi(arg[1]) => clap.beats;
                    }
                    else if (i == 2)
                    {
                        if (arg[2] == "backbeat" || arg[2] == "doubletime" || arg[2] == "sync")
                        {
                            arg[2] => clap.style;
                        }
                        else
                        {
                            <<<"Invalid CC style; valid choices: backbeat, doubletime, sync">>>;
                        }
                    }
                    else if (i == 3)
                    {
                        floatSubArrayParser(arg[3], 4, clap.splits) @=> clap.splits;
                    }
                }
            }
            
            checkForExtra(arg, 4);
        }
        else if (funcName == "randomstyle")
        {
            1 => clapRandomOn;
            
            for (int i; i < arg.size(); i++)
            {
                if (skipArg(arg[i]) == 0)
                {
                    if (checkSingleVal(arg[i]) == 0) return;
                    
                    if (i == 0)
                    {
                        strToDur(arg[0], kick.len) => clap.len;
                    }
                    else if (i == 1)
                    {
                        Std.atoi(arg[1]) => clap.beats;
                    }
                    else if (i == 2)
                    {
                        Std.atoi(arg[2]) => clap.reps;
                    }
                }
            } 
            
            checkForExtra(arg, 3);
        }
        else if (funcName == "mix")
        {
            Std.atof(arg[0]) => clap.rev;
        }
        else if (funcName == "gain")
        {
            Std.atof(arg[0]) => clapGain;
        }
        else
        {
            <<<"CC cannot find that function">>>;
        }
    }
}
    
// HH class function & arg parsing
fun void sendHHEdit(string command)
{
    funcParser(command) => string funcName;
    
    // functions without arguments
    if (funcName == "help")
    {
        hihat.help();
        return;
    }
    
    string arg[];
    
    // check function & arguments exist
    if (funcName != "" && command != funcName)
    {
        argParser(command) @=> arg;
        
        if (hasRealArgs(arg) == 0) return;
    
        if (funcName == "algo")
        {
            for (int i; i < arg.size(); i++)
            {
                if (skipArg(arg[i]) == 0)
                {
                    if (i != 3 && checkSingleVal(arg[i]) == 0) return;
                    
                    if (i == 0)
                    {
                        strToDur(arg[0], hihat.len) => hihat.len;
                    }
                    else if (i == 1)
                    {
                        Std.atoi(arg[1]) => hihat.beats;
                    }
                    else if (i == 2)
                    {
                        Std.atoi(arg[2]) => hihat.triplets;
                    }
                    else if (i == 3)
                    {
                        floatSubArrayParser(arg[3], 5, hihat.splits) @=> hihat.splits;
                    }
                }
            }
            
            checkForExtra(arg, 4);
        }
        else if (funcName == "mix")
        {
            Std.atof(arg[0]) => hihat.rev;
        }
        else if (funcName == "gain")
        {
            Std.atof(arg[0]) => hhGain;
        }
        else
        {
            <<<"HH cannot find that function">>>;
        }
    }
}

// KK class function & arg parsing
fun void sendKKEdit(string command)
{
    funcParser(command) => string funcName;
    
    // functions without arguments
    if (funcName == "help")
    {
        kick.help();
        return;
    }
    
    string arg[];
    
    // check function & arguments exist
    if (funcName != "" && command != funcName)
    {
        argParser(command) @=> arg;
        
        if (arg.size() < 1)
        {
            <<<"Argument(s) required or function does not exist!">>>;
            return;
        }
        else if (skipAllArgs(arg) == 1)
        {
            // allow lack of arguments when switching between algo and randomStyle
            if ((funcName == "algo" && kickRandomOn == 0) ||
                (funcName == "randomstyle" && kickRandomOn == 1) ||
                (funcName == "gain") ||
                (funcName == "mix"))
            {
                <<<"All arguments have been skipped!">>>;
                return;
            }
        }
    
        if (funcName == "algo")
        {
            0 => kickRandomOn;
        
            for (int i; i < arg.size(); i++)
            {
                if (skipArg(arg[i]) == 0)
                {
                    if (i != 3 && checkSingleVal(arg[i]) == 0) return;
                    
                    if (i == 0)
                    {
                        strToDur(arg[0], kick.len) => kick.len;
                    }
                    else if (i == 1)
                    {
                        Std.atoi(arg[1]) => kick.beats;
                    }
                    else if (i == 2)
                    {
                        if (arg[2] == "club" || arg[2] == "rock" || arg[2] == "sync")
                        {
                            arg[2] => kick.style;
                        }
                        else
                        {
                            <<<"Invalid KK style; valid choices: club, rock, sync">>>;
                        }
                    }
                    else if (i == 3)
                    {
                        floatSubArrayParser(arg[3], 4, kick.splits) @=> kick.splits;
                    }
                }
            }
            
            checkForExtra(arg, 4);
        }
        else if (funcName == "randomstyle")
        {
            1 => kickRandomOn;
            
            for (int i; i < arg.size(); i++)
            {
                if (skipArg(arg[i]) == 0)
                {
                    if (checkSingleVal(arg[i]) == 0) return;
                    
                    if (i == 0)
                    {
                        strToDur(arg[0], kick.len) => kick.len;
                    }
                    else if (i == 1)
                    {
                        Std.atoi(arg[1]) => kick.beats;
                    }
                    else if (i == 2)
                    {
                        Std.atoi(arg[2]) => kick.reps;
                    }
                }
            }  
            
            checkForExtra(arg, 3);
        }
        else if (funcName == "mix")
        {
            Std.atof(arg[0]) => kick.rev;
        }
        else if (funcName == "gain")
        {
            Std.atof(arg[0]) => kickGain;
        }
        else
        {
            <<<"KK cannot find that function">>>;
        }
    }
}
