classdef deconvToolBayesianFtKpsVpVe < deconvToolBayesianParallel & deconvToolFtKpsVpVe
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Access = public)
        function runDeconvolution(obj)
            obj.runDeconvolution@deconvToolBayesianParallel();
            obj.mbfPriorMap = obj.mbfMap;
            %obj.mbvPriorMap = obj.mbvMap;
            %obj.tAcq = obj.tAcq(1 : floor(length(obj.tAcq) * 0.6 ));
            obj.runDeconvolution@deconvToolFtKpsVpVe();
        end
        function obj = prepare(obj, normAifCtc, ctcSet, tAcq, opt, mask, roiMaskSet)
             obj = obj.prepare@deconvToolBayesianParallel(normAifCtc, ctcSet, tAcq, opt, mask, roiMaskSet);
             %opt.timePortion = 1;% do not resize time acquisition on second preparation
             obj = obj.prepare@deconvToolFtKpsVpVe(normAifCtc, ctcSet, tAcq, opt, mask);
        end%prepare
    end%methods (Access = public)
    
end

