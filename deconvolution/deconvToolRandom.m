classdef deconvToolRandom < deconvTool
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Access = public)
        function obj = deconvToolRandom(obj)
            obj.oversampleFact = 1;
        end
        function obj = runDeconvolution(obj)
            [H, W, T] = size(obj.ctcSet);
            obj.mbfMap = (rand(H, W) ./ 60) .* obj.deconvMask;
            obj.mbvMap = rand(H, W) .* obj.deconvMask;
            obj.fitCtcSet = obj.ctcSet;
            obj.fitResidue = rand(H, W, T);
            obj.mbfMeasUncertaintyMap = rand(H, W);
        end
        function obj = runRoiDeconvolution(obj)
            nbRoi = size(obj.roiMaskSet, 3);
            obj.mbfRoiMapSet = obj.roiMaskSet;
            obj.mbvRoiMapSet = obj.roiMaskSet;
            for k = 1 : nbRoi
                 obj.mbfRoiMapSet(:, :, k) = (obj.roiMaskSet(:, :, k) ./ k) .* rand / 60;
                 obj.mbvRoiMapSet(:, :, k) = (obj.roiMaskSet(:, :, k) ./ k) .* rand;
            end
            obj.fitRoiCtcSet = obj.roiCtcSet;
        end
    end
    
end

