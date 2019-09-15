classdef deconvToolBayesianFermi < deconvToolBayesian & deconvToolFermi
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods (Access = public)
        function obj = prepare(obj, opt)
           return 
        end
        
        function runDeconvolution(obj)
            obj.runDeconvolution@deconvToolBayesian();
            obj.mbfPriorMap = obj.mbfMap;
            obj.mbvPriorMap = obj.mbvMap;
            obj.runDeconvolution@deconvToolFermi();
        end
        
        
        function runRoiDeconvolution(obj, startPos, endPos)
            return
        end%runRoiDeconvolution(obj, startPos, endPos)
    end
    
    methods (Access = protected)
        function processMeasurementUncertainty(obj)
            return
        end%function processMeasurementUncertainty(obj)
    end%methods (Access = protected)
    
end

