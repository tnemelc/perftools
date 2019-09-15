classdef baseTool < handle
    % tools base class
    %   all tools shal derive from this class
    % author : Clément Daviller
    % date : march 28th 2018
    
    properties
        lgr;  %logger
        dataPath;
    end
    %%
    methods (Access = public)
        %%
        function obj = prepare(obj, opt)
            obj.lgr = logger.getInstance();
            obj.dataPath = opt.dataPath;
        end%
    end
    methods (Abstract, Access = public)
        %%
        obj = run(obj, opt);
    end
end

