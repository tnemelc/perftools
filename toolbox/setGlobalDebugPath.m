% setGlobalDebugPath.m
% brief: 
%   set global debug path variable where to save variable for debuging
%   this global variable is set in deconvtooUI only and is accessible with 
%   getGlobalDebugPath function
% references:
%
%
% input:
% path: path to the debuging folder
%
%
% keywords: debug
% author: C.Daviller
% date: 15-May-2017 


function setGlobalDebugPath(path)
    global debugPath;
    debugPath = path;
end