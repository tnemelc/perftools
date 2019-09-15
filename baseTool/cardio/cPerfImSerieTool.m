classdef cPerfImSerieTool < baseImgSerieTool
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        myoMaskMap;
        cavityMaskMap;
    end
    
    methods (Access = protected)
        %%
        function obj = loadMyoMask(obj)
            for k = 1 : length(obj.isKS)
                isName = char(obj.isKS(k));
                mask = loadmat(fullfile(obj.dataPath, 'dataPrep', isName, 'mask.mat'));
                obj.myoMaskMap = mapInsert(obj.myoMaskMap, isName, mask);
            end
            obj = obj.processCavityMask();
        end%loadMyoMask(obj)
        %%
        function obj = processCavityMask(obj)
            for k = 1 : length(obj.isKS)
                cavityMask = imfill(obj.myoMaskMap(obj.isKS{k}), 'holes') - obj.myoMaskMap(obj.isKS{k});
                obj.cavityMaskMap = mapInsert(obj.cavityMaskMap, obj.isKS{k}, cavityMask);
            end
            
        end
    end
    
    methods (Access = public)
        %% getters
        %%
        function myoMask = getMyoMask(obj, isName)
            myoMask = obj.myoMaskMap(isName);
        end
        %%
        function cavityMask = getCavityMask(obj, isName)
            cavityMask = obj.cavityMaskMap(isName);
        end
    end%methods (Access = public)
    
    
end

