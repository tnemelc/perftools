classdef toolBase < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        inputDataRootPath;
    end
    
    methods (Abstract, Access = public)
        prepare(obj);%prepare
        run(obj, opt);%run
    end%methods (Abstract, Access = public)
    
end

