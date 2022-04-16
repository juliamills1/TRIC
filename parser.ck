// terminal input parsing support for terminal.ck
public class Parser
{
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
            command.replace(fb, command.length() - fb, "-)");
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
    fun dur strToDur(string str, dur T, dur fallback)
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
    
    // return 1 if argument is a single value (not a sub-array)
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

}
