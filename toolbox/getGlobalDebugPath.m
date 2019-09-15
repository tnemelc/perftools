% getGlobalDebugPath.m
% brief: 
% global debug path variable where to save variable for debuging
% this global variable is accessible from anywhere using this function
% references:
%
%
% output:
%
% path: path to the debuging folder
%
%
% keywords: debug
% author: C.Daviller
% date: 15-May-2017 


function path = getGlobalDebugPath()
    global debugPath;
    path = debugPath;
end