classdef featuresDisplayRoiAnalyzerTool < roiAnalyzerTool
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Access = protected)
        %%
        function obj = loadRoisMask(obj, opt)
            if ~isfield(opt, 'subfolderPath')
                subfolderPath = fullfile('featuresDisplay', 'autoRoiClustering');
                maskFileName = 'roisMask.mat';
                for k = 1 : length(obj.isKS)
                    isName = char(obj.isKS(k));
                    mask = loadmat(fullfile(obj.dataPath, subfolderPath, isName, maskFileName));
                    obj.roisMaskMap = mapInsert(obj.roisMaskMap, isName, mask);
                end
            else
                obj.lgr.warn('dirty trick for plugin Segmentation (tool: ManualMultiRoiMapDisplay)');
                %todo: plugin segementation shall save slices files in
                %separate folders
                subfolderPath = opt.subfolderPath;
                for k = 1 : length(obj.isKS)
                    isName = char(obj.isKS(k));
                    maskFileName = [opt.maskFileName isName];
                    mask = loadmat(fullfile(obj.dataPath, subfolderPath, maskFileName));
                    obj.roisMaskMap = mapInsert(obj.roisMaskMap, isName, mask);
                end
            end
        end%loadMyoMask(obj)
    end
    
end

