classdef testTool < cPerfImSerieTool
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Access = public)
        function obj = run(obj, ~)
            obj = obj.run@cPerfImSerieTool();
            obj = obj.loadMyoMask();
        end
    end
    
    methods (Access = protected)
        function obj = loadMyoMask(obj)
            try
                loadMyoMask@cPerfImSerieTool()
            catch
                for k = 1 : length(obj.isKS)
                    isName = char(obj.isKS(k));
                    imSerie = obj.imSerieMap(isName);
                    mask = ones(size(imSerie(:,:, 1)));
                    obj.myoMaskMap = mapInsert(obj.myoMaskMap, isName, mask);
                end
            end
        end%loadMyoMask(ob
    end
    
end

