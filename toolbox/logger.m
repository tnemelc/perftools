classdef logger < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    
    %key words log, trace error
    properties
        trace;
    end
    
    methods (Static)
        %%
        function obj = getInstance()
            persistent localObj;
            %             which isvalid;
            if isempty(localObj) || ~isvalid(localObj)
                localObj = logger;
            end
            obj = localObj;
        end
        
    end %methods (Static)
    
    methods (Access = public)
        %%
        function warn(obj, msg)
            a = dbstack;
            obj.trace = sprintf('%s%s: warning: %s:l.%d - %s\n', obj.trace, datestr(now), a(2).file, a(2).line, msg);
            cprintf('orange', sprintf('warning: %s:l.%d - %s\n', a(2).file, a(2).line, msg));
        end
        %%
        function err(obj, msg)
            a = dbstack;
            obj.trace = sprintf('%s%s: error: %s:l.%d - %s\n', obj.trace, datestr(now), a(2).file, a(2).line, msg);
            cprintf('red', sprintf('error: %s:l.%d - %s\n', a(2).file, a(2).line, msg));
        end
        %%
        function info(obj, msg)
            a = dbstack;
            obj.trace = sprintf('%s%s: info: %s:l.%d - %s\n', obj.trace, datestr(now), a(2).file, a(2).line, msg);
            cprintf('DGreen', sprintf('info: %s:l.%d - %s\n', a(2).file, a(2).line, msg));
        end
        %%
        function dumpTrace(obj, path)
            if nargin < 2
                fprintf('%s\n', obj.trace);
            else
                fid = fopen(path);
                fprintf(fid, '%s\n', obj.trace)
                fclose(fid);
            end
            obj.trace = sprintf('%s\n', datestr(now));
        end
    end%methods (Access = public)
    methods (Access = private)
       %%
       function obj = logger(obj)
           obj.trace = sprintf('%s\n', datestr(now));
       end
    end
    
end

