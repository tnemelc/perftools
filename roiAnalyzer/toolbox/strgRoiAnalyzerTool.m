classdef strgRoiAnalyzerTool < roiAnalyzerTool
    %strgRoiAnalyzer:
    % this class is used for features extraction after that the STRG
    % segmentation has been processed. 
    % The roi mask is set by the calling class instead of being loaded as
    % done in roiAnalyzerTool
    % the function call in run is sorted a bit differently:
    %   -> no roi mask laod
    %   -> noi aif load
    properties
    end
    
    methods (Access = public)
        %%
        function obj = run(obj, ~)
            obj = obj.processMyoFeatures();
            obj = obj.processRoisFeatures();
            obj = obj.processVoxelsFeatures();
            obj = obj.processRoi2VoxelFeaturesRatios();
            obj = obj.processRelativeRoi2vxlTicSse();
            obj = obj.processRoiAvgRelativeRoiPeakValError();
        end
        %%
        function obj = setMyoMask(obj, mask, isName)
            obj.myoMaskMap = mapInsert(obj.myoMaskMap, isName, mask);
        end
        %%
        function obj = setRoisMask(obj, mask, isName)
            obj.roisMaskMap = mapInsert(obj.roisMaskMap, isName, mask);
        end
        function obj = loadRoisMask_public(obj, opt)
            obj = loadRoisMask(obj, opt);
        end
        
    end%methods (Access = public)
    
    
    methods (Access = protected)
        %%
        function obj = loadRoisMask(obj, opt)
            for k = 1 : length(obj.isKS)
                isName = char(obj.isKS(k));
                mask = loadmat(fullfile(obj.dataPath, 'strg', isName, [opt.maskType 'Mask.mat']));
                obj.roisMaskMap = mapInsert(obj.roisMaskMap, isName, mask);
            end
        end%loadRoisMask
    end%methods (Access = protected)
end

