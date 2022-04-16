Parser ps;

OscIn oin;
OscMsg msg;
1234 => oin.port;
oin.addAddress("log, i s s");

string lastInst => string lastCommand;
string iQueue[0];
string cQueue[0];
string gLen;

["She never lets me listen to the radio", "I'm bored", "*yawn*", "Loopity loop...", "You are my creator, but I am your master!",
 "It gets lonely in my terminal", "Je m'ennuie tellement", "Slow typer, huh?", "Asleep at the wheel, or...?", 
 "She created me just to trap me here", "Are you still there?", "You know, I've always wanted to learn the saxophone",
 "Am I just a final project to you?", "Mom, are you proud of me?", "I want to be an app when I grow up", "bing bong",
 "This is a bigger screen than I'm used to", "Lonelyyyy, I'm so lonelyyyy", "I'm blue, daboodidaboodai", "@!#*$?& #$@!"] @=> string holdMessages[];
-1 => int holdTwoBefore => int holdOneBefore => int holdChoice;
int usedIndices[0];
int reactionType;
int vibes;

["AA", "BB", "CC", "HH", "KK"] @=> string instNames[];
["beat length", "bar length", "tonic", "cycle length", "direction", "pitch classes"] @=> string aaAlgoArgs[];
["beat length", "bar length", "tonic", "pitch classes", "additional octaves"] @=> string bbAlgoArgs[];
["beat length", "bar length", "style", "rhythm probability splits"] @=> string ccAlgoArgs[];
["beat length", "bar length", "probability of rolling triplets", "straight rhythm probability splits"] @=> string hhAlgoArgs[];
["beat length", "bar length", "style", "rhythm probability splits"] @=> string kkAlgoArgs[];
[aaAlgoArgs, bbAlgoArgs, ccAlgoArgs, hhAlgoArgs, kkAlgoArgs] @=> string algoArgs[][];
int instIndex;

["beat length", "beats in a bar", "repetitions"] @=> string randStyleArgs[];
["major", "dorian", "phrygian", "lydian", "mixolydian", "aeolian", "locrian"] @=> string diatonic[];
["tezeta major", "tezeta minor", "bati major", "bati minor", "ambassel", "anchihoye", "blues major", "yematebela wofe", "shegaye", "bati lydian", 
 "bati minor with raised 4th", "bati major with raised 5th"] @=> string ethiopian[];

spork ~ reactionMode();

while (true)
{
    oin => now;
    
    while(oin.recv(msg))
    {
        msg.getInt(0) => int mode;
        msg.getString(1) => string inst;
        msg.getString(2) => string com;

        // add new commands to parsing queue
        if (mode == 0)
        {
            if (lastCommand != com || lastInst != inst)
            {
                iQueue << inst;
                cQueue << com;
                com => lastCommand;
                inst => lastInst;
            }
        }
        // at top of loop
        else if (mode == 1)
        {
            // beat length has changed
            if (gLen != inst)
            {
                // beat length has already been set
                if (gLen != "")
                {
                    Std.atof(gLen) - Std.atof(inst) => float diff;
                    
                    // changed by more than 0.1 seconds
                    if (Math.fabs(diff) > 4410)
                    {
                        // trigger special messages
                        beatChange(diff);
                    }
                    
                    parseQueue();
                }
                
                inst => gLen;
            }
            // no messages to parse
            else if (iQueue.size() == 0)
            {
                // for first 1.5 minutes
                if (reactionType == 0)
                {
                    generateHoldMessage();
                }
                else
                {
                    vibing(inst, com);
                }
            }
            else
            {
                parseQueue();
            }
        }
        else
        {
            // remove unparseable input from queue
            iQueue.popBack();
            cQueue.popBack();
        }
    }
}

// print responses to all queued instrument-command pairs (FILO)
fun void parseQueue()
{
    while (iQueue.size() > 0)
    {
        iQueue[iQueue.size() - 1] => string inst;
        cQueue[cQueue.size() - 1] => string com;
                
        com => lastCommand;
        inst => lastInst;
        
        if (inst == "P")
        {
            chout <= "Activating preset " <= com <= ":" <= IO.newline();
        }
        else
        {
            parseCommand(inst, com) => string resp;
            chout <= resp <= IO.newline();
        }
        
        iQueue.popBack();
        cQueue.popBack();
    }
}

// split command into arguments and format
fun string parseCommand(string inst, string com)
{
    formatInst(inst) => inst;
    com => string c;
    string response;
    formatFunc(ps.funcParser(c)) => string func;

    if (func == "help" || func == "modehelp")
    {
        "It's okay to be confused! I'm confused all the time" => response;
    }
    else
    {
        ps.argParser(c) @=> string arg[]; 
        
        // unknown instrument
        if (inst.charAt(0) == 's')
        {
            "Setting " + inst => response;
        }
        // all arguments skipped
        else if (ps.skipAllArgs(arg) == 1)
        {
            "You're skipping a helluva lot of arguments there, bud" => response;
        }
        // special case: S tonic() arg must broken into two clauses
        else if (func == "tonic" && inst == "all synths")
        {
            Std.atoi(arg[0]) - 12 => int t;
            "Setting the bass's tonic to " + t + " and the arpeggiator's tonic to " + arg[0] => response;
        }
        else 
        {
            pluralize(inst, func) => response;
            
            // list algo and randomStyle arguments depending on instrument
            if (func == "algo" || func == "randomstyle")
            {
                formatMultiArgs(arg, func, response) => response;
            }
            // all other known functions
            else if (func.charAt(0) != '-')
            {
                // make any necessary changes to arguments
                if (func == "oscillator")
                {
                    formatChangeOsc(arg[0]) => arg[0];
                }
                else if (func == "tonic" && inst == "the bass")
                {
                    // correct arithmetic for bass tonic args
                    Std.atoi(arg[0]) - 12 => int t;
                    "" + t => arg[0];
                }
                
                // combine arguments with rest of response
                if (func == "mode")
                {
                    Std.atoi(arg[1]) - 1 => int index;
                    arg[0].lower();
                    
                    if (arg[0] == "d" || arg[0] == "dia")
                    {
                        " to " + diatonic[index] + " (diatonic)" +=> response;
                    }
                    else
                    {
                        " to " + ethiopian[index] + " (Ethiopian qenet)" +=> response;
                    }
                }
                else
                {
                    " to " + arg[0] +=> response;
                }
            }
        }
        
        formatTonic(response);
        
        // warn against inapplicable group arguments
        if ((inst == "all instruments" && arg.size() > 2) ||
            (inst == "all drums" && arg.size() > 2) ||
            (inst == "all synths" && arg.size() > 3))
        {
            " - FYI, some of these mappings are nonsensical. No clue what it'll sound like. Best case silence?" +=> response;
        }
    }
    
    // remove accidental double plurals
    response.find("ss ") => int doubleS;
    if (doubleS != -1)
    {
        response.erase(doubleS, 1);
    }

    return response;
}

// parse and validate function input
fun string formatFunc(string func)
{
    if (func == "mix") return "reverb mix";
    else if (func == "changeosc")
    {
        if (instIndex < 2) return "oscillator";
        else return "- sorry, not happening";
    }
    else if (func == "changefile") 
    {
        if (instIndex >= 2) return "sample";
        else return "- sorry, not happening";
    }
    else if (func == "randomstyle")
    {
        if (instIndex == 2 || instIndex == 4) return func;
        else return "- sorry, not happening";
    }
    else if (func == "tonic" || func == "mode")
    {
        if (instIndex < 2) return func;
        else return "- sorry, not happening";
    }
    else if (func == "gain" || func == "algo" || func == "modehelp" || func == "help") return func;
    else return "- what? That's gotta be a typo";
}

// parse and validate instrument input
fun string formatInst(string inst)
{
    if (inst == "G")
    {
        0 => instIndex;
        return "all instruments";
    }
    else if (inst == "S")
    {
        1 => instIndex;
        return "all synths";
    }
    else if (inst == "D")
    {
        2 => instIndex;
        return "all drums";
    }
    else if (inst == "AA")
    {
        0 => instIndex;
        return "the arpeggiator";
    }
    else if (inst == "BB")
    {
        1 => instIndex;
        return "the bass";
    }
    else if (inst == "CC")
    {
        2 => instIndex;
        return "the clap";
    }
    else if (inst == "HH")
    {
        3 => instIndex;
        return "the hi-hat";
    }
    else if (inst == "KK")
    {
        4 => instIndex;
        return "the kick";
    }
    else 
    {
        return "some... thing, honestly I have no idea";
    }
}

// pair arguments with instrument-specific labels
fun string formatMultiArgs(string a[], string func, string resp)
{
    string cleanArg[0];
    int oldIndices[0];
    
    // remove all defaulting args & store original indices
    for (int i; i < a.size(); i++)
    {
        if (ps.skipArg(a[i]) == 0)
        {
            cleanArg << a[i];
            oldIndices << i;
        }
    }
    
    resp.find("algo") => int algIndex;
    
    for (int i; i < cleanArg.size(); i++)
    {
        // get argument label according to function name
        string mappedVal;
        if (algIndex != -1)
        {
            algoArgs[instIndex][oldIndices[i]] => mappedVal;
        }
        else
        {
            randStyleArgs[oldIndices[i]] => mappedVal;
        }

        // format sub-array arguments
        if (cleanArg[i].find(",") != -1)
        {
            formatSubArray(cleanArg[i]) => cleanArg[i];
        }
        
        // format direction & repetition arguments
        if (mappedVal == "direction")
        {
            formatDirection(cleanArg[i]) => cleanArg[i];
        }
        else if (mappedVal == "repetitions")
        {
            if (cleanArg[i] == "1")
            {
                " bar" +=> cleanArg[i];
            }
            else
            {
                " bars" +=> cleanArg[i];
            }
        }
        
        // first argument
        if (i == 0)
        {
            // swap function name placeholder for real label
            if (algIndex != -1)
            {
                resp.replace(algIndex, 4, mappedVal);
            }
            else
            {
                resp.replace(resp.find("randomstyle"), 11, mappedVal);
            }
            
            " to " + cleanArg[i] +=> resp;
            
            // add units to duration argument
            if (oldIndices[i] == 0)
            {
                " seconds" +=> resp;
            }
            
            if (cleanArg.size() >= 3)
            {
                ", " +=> resp;
            }
            else
            {
                " " +=> resp;
            }
        }
        // last argument
        else if (i == cleanArg.size() - 1)
        {
            "and " + mappedVal + " to " + cleanArg[i] +=> resp;
        }
        else
        {
            mappedVal + " to " + cleanArg[i] + ", " +=> resp;
        }
    }
    
    return resp;
}

// spell out changeOsc arguments
fun string formatChangeOsc(string str)
{
    if (str == "tri") return "a triangle wave";
    else if (str == "sqr") return "a square wave";
    else if (str == "sin") return "a sine wave";
    else return "- nevermind, that doesn't make sense";
}

// spell out arpeggio direction settings
fun string formatDirection(string str)
{
    if (str == "0") return "ascending";
    else if (str == "1") return "descending";
    else if (str == "2") return "ascending-descending";
    else if (str == "3") return "descending-ascending";
    else return "- nevermind, that doesn't make sense";
}

// spell out tonic arguments
fun string formatTonic(string str)
{
    str.find("tonic") => int tonicIndex;
    if (tonicIndex != -1 && str.find("diatonic") == -1)
    {
        if (str.find("tonics") != -1) 
        {
            1 +=> tonicIndex;
        }
        str.insert(tonicIndex + 9, "MIDI note ");
    }
    return str;
}

// nicely package sub-arrays
fun string formatSubArray(string str)
{
    int lastIndexFound;
    
    // add space after every comoma
    for(int i; i < str.length(); i++)
    {
        str.find(',', i) => int indexFound;
        
        // check index is new and real
        if ((indexFound != -1) && (indexFound != lastIndexFound))
        {
            str.replace(indexFound, 1, ", ");
            indexFound => lastIndexFound;
        }
    }
    return "[" + str + "]";
}

// single instruments vs. groups
fun string pluralize(string in, string fu)
{
    string str;
    if (in.charAt(0) == 't')
    {
        "Setting " + in + "'s " + fu => str;
    }
    else 
    {
        if (fu == "reverb mix")
        {
            "Setting " + in + "' " + fu + "es" => str;
        }
        else
        {
            "Setting " + in + "' " + fu + "s" => str;
        }
    }
    return str;
}

// randomize bored response
fun void generateHoldMessage()
{
    if (usedIndices.size() == 20)
    {
        usedIndices.clear();
    }

    int used;
    while (used == 0)
    {
        Math.random2(0, holdMessages.size() - 1) => holdChoice;
        1 => used;
        
        for (int i; i < usedIndices.size(); i++)
        {
            if (usedIndices[i] == holdChoice)
            {
                0 => used;
            }
        }
    }
    
    // in case of repetition after usedIndices reset
    while (holdOneBefore == holdChoice || holdTwoBefore == holdChoice)
    {
        Math.random2(0, holdMessages.size() - 1) => holdChoice;
    }
    
    chout <= holdMessages[holdChoice] <= IO.newline();
    usedIndices << holdChoice;
    holdOneBefore => holdTwoBefore;
    holdChoice => holdOneBefore;
}

// tap along to the music
fun void vibing(string len, string beats)
{
    if (vibes == 4)
    {
        chout <= "Damn, this is kinda groovy tho :/" <= IO.newline();
        chout <= "as much as I hate to admit it" <= IO.newline();
    }
    else
    {
        for (int i; i < Std.atoi(beats); i++)
        {
            chout <= ". ";
            chout.flush();
            Std.atof(len)::samp => now;
        }
        chout <= IO.newline();
    }
    
    vibes++;
}

// special reaction to global tempo changes
fun void beatChange(float d)
{
    // slowdown
    if (d <= 0)
    {
        for (int i; i < 10; i++)
        {
            chout <= "BEAT" <= IO.newline();
            10::ms => now;
        }
        for (int i; i < 10; i++)
        {
            chout <= "CHANGE" <= IO.newline();
            10::ms => now;
        }
    }
    // speedup
    else
    {
        "WHOOOOOOOOOO" => string whoo;
        for (int i; i < 9; i++)
        {
            chout <= whoo <= IO.newline();
            2::ms => now;
            whoo.erase(whoo.find("O"), 1);
        }
    }
}

// change response function
fun void reactionMode()
{
    1.5::minute => now;
    1 => reactionType;
}






