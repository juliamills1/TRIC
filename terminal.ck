// terminal input reader
ConsoleInput in;
StringTokenizer tok;
Parser ps;
FileIO sampleChecker;

// presets reader
FileIO fio;
me.dir() + "presets.txt" => string pFile;
StringTokenizer pTok;
string presets[0];

// instrument classes
AA arp;
BB bass;
CC clap;
HH hihat;
KK kick;

// synchronize to period
0.7::second => dur T;
T - (now % T) => now;
Gain g => dac;
T => arp.len => bass.len => hihat.len => clap.len => kick.len;

// intra-loop value placeholders
"" => string lastArpScaleType => string lastBassScaleType;
-1 => int lastArpScaleNum => int lastBassScaleNum;
"sin" => string arpOsc;
"tri" => string bassOsc;
hihat.g => float hhGain;
hihat.sample => string hhSamp;

// musical statement starting values
10 => arp.scaleNum => bass.scaleNum;
"eth" => arp.scaleType => bass.scaleType;
"sync" => clap.style;
"club" => kick.style;
0 => hhGain => arp.g => clap.tempGain => bass.g => kick.g => kick.tempGain => hihat.triplets;
arp.gain(arp.g);
bass.gain(bass.g);
hihat.gain(hhGain);
clap.gain(clap.tempGain);
kick.gain(kick.tempGain);
0.11::second => now;

// send instruments' output to dac
arp.connect(g);
bass.connect(g);
clap.connect(g);
hihat.connect(g);
kick.connect(g);

// OSC settings
"localhost" => string hostname;
1234 => int port;
OscOut xmit;
xmit.dest(hostname, port);
string lastInst;
string lastCommand;
int errorFlag;

spork ~ messageListen();

while (true)
{
    sendOSC(1, durToString(kick.len), Std.itoa(kick.beats));
    
    // send all top-of-loop edits
    arp.gain(arp.g);
    arp.mix(arp.rev);
    arp.changeOsc(arpOsc);
    bass.gain(bass.g);
    bass.mix(bass.rev);
    bass.changeOsc(bassOsc);
    hihat.gain(hhGain);
    hihat.mix(hihat.rev);
    hihat.changeFile(hhSamp);
    clap.gain(clap.tempGain);
    clap.mix(clap.rev);
    clap.changeFile(clap.tempSample);
    kick.gain(kick.tempGain);
    kick.mix(kick.rev);
    kick.changeFile(kick.tempSample);
    
    // send changes to synth scales
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
    
    // spork next beat
    spork ~ arp.algo(arp.len, arp.beats, arp.tonic, arp.cycle, arp.direction, arp.pitchClasses);
    spork ~ bass.algo(bass.len, bass.beats, bass.tonic, bass.pitchClasses, bass.addOctaves);
    spork ~ hihat.algo(hihat.len, hihat.beats, hihat.triplets, hihat.splits);
    
    // spork relevant clap function
    if (clap.randomOn == 0)
    {
        spork ~ clap.algo(clap.len, clap.beats, clap.style, clap.splits);
    }
    else
    {
        spork ~ clap.randomStyle(clap.len, clap.beats, clap.reps);
    }
    
    // spork relevant kick function
    if (kick.randomOn == 0)
    {
        kick.algo(kick.len, kick.beats, kick.style, kick.splits);
    }
    else
    {
        kick.randomStyle(kick.len, kick.beats, kick.reps);
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

fun void sendOSC(int mode, string i, string c)
{
    xmit.start("log");
    xmit.add(mode);
    xmit.add(i);
    xmit.add(c);
    xmit.send();
}

// send command info to corresponding instrument(s)
fun void commandRouter(string instIn, string command)
{
    instIn.upper() => string inst;
    sendOSC(0, inst, command);
    
    if (inst == "P")
    {
        // remove from start of OSC queue
        sendOSC(2, "", "");
        sendPreset(command);
    }
    else if (inst == "G")
    {
        sendAAEdit(command);
        sendBBEdit(command);
        sendHHEdit(command);
        sendRanDrumEdit(clap, command);
        sendRanDrumEdit(kick, command);
    }
    else if (inst == "S")
    {
        sendAAEdit(command);
        sendBBEdit(command);
    }
    else if (inst == "D")
    {
        sendHHEdit(command);
        sendRanDrumEdit(clap, command);
        sendRanDrumEdit(kick, command);
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
        sendRanDrumEdit(clap, command);
    }
    else if (inst == "HH")
    {
        sendHHEdit(command);
    }
    else if (inst == "KK")
    {
        sendRanDrumEdit(kick, command);
    }
    else 
    {
        <<<"Instrument or group not found">>>;
        sendOSC(2, "", "");
    }
}

// fetch command from presets.txt lines
fun void sendPreset(string command)
{
    loadPresets();
    
    Std.atoi(command) => int p;
    pTok.set(presets[p]);
    
    while (pTok.more())
    {
        pTok.next() => string inst;
        pTok.next() => string command;
        <<<inst, command>>>;
        commandRouter(inst, command);
    }
    
    // make last in OSC queue (i.e. first to print)
    sendOSC(0, "P", command);
    presets.clear();
}

// parse presets file into array of commands
fun void loadPresets()
{
    fio.open(pFile, FileIO.READ);
    
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

// AA function & arg parsing
fun void sendAAEdit(string c)
{
    c => string command;
    ps.funcParser(c) => string funcName;
    
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
        ps.argParser(command) @=> arg;
        
        if (ps.hasRealArgs(arg) == 0) return;
        
        if (funcName == "algo")
        {
            for (int i; i < arg.size(); i++)
            {
                if (ps.skipArg(arg[i]) == 0)
                {   
                    if (i != 5 && ps.checkSingleVal(arg[i]) == 0)
                    {
                        sendOSC(2, "", "");
                        return;
                    }
                    
                    if (i == 0)
                    {
                        ps.strToDur(arg[0], T, arp.len) => dur d;
                        if (d == arp.len)
                        {
                            sendOSC(2, "", "");
                        }
                        d => arp.len;
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
                        Std.atoi(arg[4]) => int d;
                        if (d < 4)
                        {
                            d => arp.direction;
                        }
                        else
                        {
                            <<<"Invalid arp direction: (0) ascending, (1) descending, (2) asc-des, (3) des-asc">>>;
                            sendOSC(2, "", "");
                        }
                    }
                    else if (i == 5)
                    {
                        ps.intSubArrayParser(arg[5]) @=> arp.pitchClasses;
                    }
                }
            }
            
            ps.checkForExtra(arg, 6);
        }
        else if (funcName == "mix")
        {
            Std.atof(arg[0]) => arp.rev;
        }
        else if (funcName == "gain")
        {
            Std.atof(arg[0]) => arp.g;
        }
        else if (funcName == "changeosc")
        {
            arg[0].lower() => arg[0];
            if (arg[0] == "tri" || arg[0] == "sin" || arg[0] == "sqr")
            {
                arg[0] => arpOsc;
            }
            else
            {
                <<<"Invalid osc type; valid choices: tri, sin, sqr">>>;
            }
        }
        else if (funcName == "mode")
        {
            if (ps.checkForMin(arg, 2) == 1)
            {
                sendOSC(2, "", "");
                return;
            }
            
            arg[0].lower();
            Std.atoi(arg[1]) => int n;
            
            if ((arg[0].charAt(0) == 'd' && n > 7) || (n > 12))
            {
                <<<"Invalid scale number: (1-7) diatonic, (1-12) Ethiopian qenet">>>;
                sendOSC(2, "", "");
                return;
            }
            
            if (ps.skipArg(arg[0]) == 0)
            {
                arg[0] => arp.scaleType;
            }
            
            if (ps.skipArg(arg[1]) == 0)
            {
                n => arp.scaleNum;
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
    else 
    {
        sendOSC(2, "", "");
    }
}

// BB function & arg parsing
fun void sendBBEdit(string c)
{
    c => string command;
    ps.funcParser(c) => string funcName;
    
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
        ps.argParser(command) @=> arg;
        
        if (ps.hasRealArgs(arg) == 0) return;
        
        if (funcName == "algo")
        {   
            for (int i; i < arg.size(); i++)
            {
                if (ps.skipArg(arg[i]) == 0)
                {
                    if (i != 3 && ps.checkSingleVal(arg[i]) == 0)
                    {
                        sendOSC(2, "", "");
                        return;
                    }
                    
                    if (i == 0)
                    {
                        ps.strToDur(arg[0], T, bass.len) => dur d;
                        if (d == bass.len)
                        {
                            sendOSC(2, "", "");
                        }
                        d => bass.len;
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
                        ps.intSubArrayParser(arg[3]) @=> bass.pitchClasses;
                    }
                    else if (i == 4)
                    {
                        Std.atoi(arg[4]) => bass.addOctaves;
                    }
                }
            }
            
            ps.checkForExtra(arg, 5);
        }
        else if (funcName == "mix")
        {
            Std.atof(arg[0]) => bass.rev;
        }
        else if (funcName == "gain")
        {
            Std.atof(arg[0]) => bass.g;
        }
        else if (funcName == "changeosc")
        {
            arg[0].lower() => arg[0];
            if (arg[0] == "tri" || arg[0] == "sin" || arg[0] == "sqr")
            {
                arg[0] => bassOsc;
            }
            else
            {
                <<<"Invalid osc type; valid choices: tri, sin, sqr">>>;
            }
        }
        else if (funcName == "mode")
        {
            if (ps.checkForMin(arg, 2) == 1)
            {
                sendOSC(2, "", "");
                return;
            }
            
            arg[0].lower();
            Std.atoi(arg[1]) => int n;
            
            if ((arg[0].charAt(0) == 'd' && n > 7) || (n > 12))
            {
                <<<"Invalid scale number: (1-7) diatonic, (1-12) Ethiopian qenet">>>;
                sendOSC(2, "", "");
                return;
            }
            
            if (ps.skipArg(arg[0]) == 0)
            {
                arg[0] => bass.scaleType;
            }
            
            if (ps.skipArg(arg[1]) == 0)
            {
                n => bass.scaleNum;
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
    else 
    {
        sendOSC(2, "", "");
    }
}

// HH function & arg parsing
fun void sendHHEdit(string c)
{
    c => string command;
    ps.funcParser(c) => string funcName;
    
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
        ps.argParser(command) @=> arg;
        
        if (ps.hasRealArgs(arg) == 0) return;
        
        if (funcName == "algo")
        {
            for (int i; i < arg.size(); i++)
            {
                if (ps.skipArg(arg[i]) == 0)
                {
                    if (i != 3 && ps.checkSingleVal(arg[i]) == 0)
                    {
                        sendOSC(2, "", "");
                        return;
                    }
                    
                    if (i == 0)
                    {
                        ps.strToDur(arg[0], T, hihat.len) => dur d;
                        if (d == hihat.len)
                        {
                            sendOSC(2, "", "");
                        }
                        d => hihat.len;
                    }
                    else if (i == 1)
                    {
                        Std.atoi(arg[1]) => hihat.beats;
                    }
                    else if (i == 2)
                    {
                        Std.atof(arg[2]) => hihat.triplets;
                    }
                    else if (i == 3)
                    {
                        ps.floatSubArrayParser(arg[3], 5, hihat.splits) @=> float sp[];
                        if (sp == hihat.splits)
                        {
                            sendOSC(2, "", "");
                        }
                        sp @=> hihat.splits;
                    }
                }
            }
            
            ps.checkForExtra(arg, 4);
        }
        else if (funcName == "mix")
        {
            Std.atof(arg[0]) => hihat.rev;
            ps.checkForExtra(arg, 1);
        }
        else if (funcName == "gain")
        {
            Std.atof(arg[0]) => hhGain;
            ps.checkForExtra(arg, 1);
        }
        else if (funcName == "changefile")
        {
            // test file exists
            sampleChecker.open(me.dir() + arg[0], FileIO.READ);
            if (sampleChecker.good())
            {
                arg[0] => hhSamp;
            }
            else 
            {
                <<<"Cannot open file", arg[0]>>>;
                sendOSC(2, "", "");
            }
        }
        else
        {
            <<<"HH cannot find that function">>>;
        }
    }
    else 
    {
        sendOSC(2, "", "");
    }
}

// CC and KK joint function & arg parsing
fun void sendRanDrumEdit(RanDrum u, string c)
{
    c => string command;
    ps.funcParser(c) => string funcName;
    
    // functions without arguments
    if (funcName == "help")
    {
        // TO DO: how to properly overwrite object help()?
        if (u.id == "kk")
        {
            kick.help();
        }
        else 
        {
            clap.help();
        }
        return;
    }
    
    string arg[];
    
    // check function & arguments exist
    if (funcName != "" && command != funcName)
    {
        ps.argParser(command) @=> arg;
        
        if (arg.size() < 1)
        {
            <<<"Argument(s) required or function does not exist!">>>;
            sendOSC(2, "", "");
            return;
        }
        else if (ps.skipAllArgs(arg) == 1)
        {
            // allow lack of arguments when switching between algo and randomStyle
            if ((funcName == "algo" && u.randomOn == 0) ||
            (funcName == "randomstyle" && u.randomOn == 1) ||
            (funcName == "gain") ||
            (funcName == "mix"))
            {
                <<<"All arguments have been skipped!">>>;
                return;
            }
        }
        
        if (funcName == "algo")
        {
            0 => u.randomOn;
            
            for (int i; i < arg.size(); i++)
            {
                if (ps.skipArg(arg[i]) == 0)
                {
                    if (i != 3 && ps.checkSingleVal(arg[i]) == 0)
                    {
                        sendOSC(2, "", "");
                        return;
                    }
                    
                    if (i == 0)
                    {
                        ps.strToDur(arg[0], T, u.len) => dur d;
                        if (d == u.len)
                        {
                            sendOSC(2, "", "");
                        }
                        d => u.len;
                    }
                    else if (i == 1)
                    {
                        Std.atoi(arg[1]) => u.beats;
                    }
                    else if (i == 2)
                    {
                        if (u.id == "kk" && checkKKStyles(arg[2]) != "")
                        {
                            arg[2] => u.style;
                        }
                        else if (u.id == "cc" && checkCCStyles(arg[2]) != "")
                        {
                            arg[2] => u.style;
                        }
                    }
                    else if (i == 3)
                    {
                        ps.floatSubArrayParser(arg[3], 4, u.splits) @=> float sp[];
                        if (sp == u.splits)
                        {
                            sendOSC(2, "", "");
                        }
                        sp @=> u.splits;
                    }
                }
            }
            
            ps.checkForExtra(arg, 4);
        }
        else if (funcName == "randomstyle")
        {
            1 => u.randomOn;
            
            for (int i; i < arg.size(); i++)
            {
                if (ps.skipArg(arg[i]) == 0)
                {
                    if (ps.checkSingleVal(arg[i]) == 0)
                    {
                        sendOSC(2, "", "");
                        return;
                    }
                    
                    if (i == 0)
                    {
                        ps.strToDur(arg[0], T, u.len) => u.len;
                    }
                    else if (i == 1)
                    {
                        Std.atoi(arg[1]) => u.beats;
                    }
                    else if (i == 2)
                    {
                        Std.atoi(arg[2]) => u.reps;
                    }
                }
            }  
            
            ps.checkForExtra(arg, 3);
        }
        else if (funcName == "mix")
        {
            Std.atof(arg[0]) => u.rev;
        }
        else if (funcName == "gain")
        {
            Std.atof(arg[0]) => u.tempGain;
        }
        else if (funcName == "changefile")
        {
            // test file exists
            sampleChecker.open(me.dir() + arg[0], FileIO.READ);
            if (sampleChecker.good())
            {
                arg[0] => u.tempSample;
            }
            else 
            {
                <<<"Cannot open file", arg[0]>>>;
                sendOSC(2, "", "");
            }
        }
        else
        {
            <<<"Function not found">>>;
        }
    }
    else 
    {
        sendOSC(2, "", "");
    }
}
    
// validate style argument for CC
fun string checkCCStyles(string s)
{
    if (s == "sync" || s == "doubletime" || s == "backbeat")
    {
        return s;
    }
    else
    {
        <<<"Invalid CC style; valid choices: backbeat, doubletime, sync">>>;
        sendOSC(2, "", "");
        return "";
    }
}

// validate style argument for KK
fun string checkKKStyles(string s)
{
    if (s == "club" || s == "rock" || s == "sync")
    {
        return s;
    }
    else
    {
        <<<"Invalid KK style; valid choices: club, rock, sync">>>;
        sendOSC(2, "", "");
        return "";
    }
}

// convert duration to string # of samples
fun string durToString(dur d) 
{
    return "" + ((d / (1::samp)));
}

