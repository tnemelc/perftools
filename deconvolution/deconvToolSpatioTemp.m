classdef deconvToolSpatioTemp < deconvTool
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        clippingMask;
        sptOpt;
    end
    %%methods (Access = public)
     methods (Access = public)
         function obj = deconvToolSpatioTemp()
             obj.oversampleFact = 1;
             obj.mbfPriorMap = [];
             obj.mbvPriorMap = [];
         end
         function obj = prepare(obj, normAifCtc, ctcSet, tAcq, opt, mask, roiMaskSet)
            if nargin > 7
                 obj.prepare@deconvTool(normAifCtc, ctcSet, tAcq, opt, mask, roiMaskSet);
            else
                 obj.prepare@deconvTool(normAifCtc, ctcSet, tAcq, opt, mask);
            end
            [H, W] = size(mask);
            obj.clippingMask = zeros(H, W, length(tAcq)); 
            for  k = 1 : size(ctcSet, 3); obj.clippingMask(:, :, k) = mask; end
            
            obj.sptOpt.lambda_t = -2;%strength of temporal regularization
            obj.sptOpt.lambda_s = -5;%strength of 2D edge-preserving spatial regularization
            obj.sptOpt.lambda_p = 0;%non-negativity constraint
            obj.sptOpt.delta = 10^(-6);%scaling parameter tuning the value of gradient above which a discontinuity is to be detected
            obj.sptOpt.dx = 1;%360/256
            obj.sptOpt.dy = 1;
            obj.sptOpt.dt = 0.6;
            
            obj.mbfMap = zeros(H, W);
            obj.mbvMap = zeros(H, W);
         end%prepare
         
         function runDeconvolution(obj)
             start = tic;
             [obj.fitResidue, phi, psi_t, psi_s, psi_p] = launchDeconvolution(obj.ctcSet, ...
                                        obj.clippingMask, obj.normAifCtc, obj.sptOpt.lambda_t,...
                                        obj.sptOpt.lambda_s, obj.sptOpt.lambda_p,...
                                        obj.sptOpt.delta, obj.sptOpt.dx,...
                                        obj.sptOpt.dy, obj.sptOpt.dt);
            
            [H, W, ~] = size(obj.fitResidue);
            for k = 1 : H
                for l = 1 : W
                    if obj.clippingMask(k, l , 1)
                        obj.mbfMap(k,l) = max(obj.fitResidue(k, l, :));
                        if obj.mbfMap(k, l) > 0.2
                            disp('deconvToolSpatioTemp:runDeconvolution : warning overestimation!!!!');
                            obj.mbfMap(k, l) = 0.2;
                        end
                        if isnan(obj.mbfMap(k, l))
                            disp('deconvToolSpatioTemp:runDeconvolution : warning nan found!!!!');
                            obj.mbfMap(k, l) = 0.0000001;
                        end
                        obj.mbvMap(k, l) = trapezoidalSum(squeeze(obj.fitResidue(k, l, :)), 1);
                        if isnan(obj.mbvMap(k, l))
                            disp('deconvToolSpatioTemp:runDeconvolution : warning nan found!!!!');
                            obj.mbvMap(k, l) = 0.0000001;
                        end
                    end
                end
            end
            obj.processfitCtcSet();
%             obj.processBaselineLengthMap();
            
            if obj.processMeasUncertaintyFlag
                obj.processMeasurementUncertainty();
            end
            obj.processTime = toc(start);
         end%runDeconvolution
         
         function runRoiDeconvolution(obj)
            %msgbox('Not applicable for this method');
         end%runRoiDeconvolution
         
         function obj = processfitCtcSet(obj)
             [H, W, T] = size(obj.fitResidue);
             fitCtcSet = zeros(H, W, T);
             dt = (obj.tAcq(2) - obj.tAcq(1)) / 5; 
             tSim = obj.tAcq(1) : dt : obj.tAcq(end);
                          
             ca = interp1(obj.tAcq, obj.normAifCtc, tSim, 'linerar', 'extrap');
             tAcq = obj.tAcq;
             fitResidue = obj.fitResidue;
             mask = obj.deconvMask;
             for k = 1 : H
                 for l = 1 : W
                     if mask(k, l)
                         r = interp1(tAcq, squeeze(fitResidue(k, l, :)), tSim, 'linerar', 'extrap');
                         for t = 2 : length(tSim)
                             ct(t) = trapz(tSim(1:t), r(1:t) .* ca(t : -1 : 1));
                         end
                         fitCtcSet(k, l, :) = interp1(tSim, ct, tAcq, 'linerar', 'extrap');
                     end
                 end
             end
             obj.fitCtcSet = fitCtcSet;
         end
         
         %getters
         function ls = getLambdaS(obj)
             ls = obj.sptOpt.lambda_s;
         end%getLambdaS
         
         function lt = getLambdaT(obj)
             lt = obj.sptOpt.lambda_t;
         end%getLambdaS
         
         function delta = getDelta(obj)
             delta = obj.sptOpt.delta;
         end% getDelta
         
         function roiId = getRoiId(obj, x, y)
             disp('deconvToolSpatioTemp:getRoiId : not applicable');
             roiId = -1;
         end%getRoiId
         
         function bfUncertainty = getMbfUncertainty(obj, xCoor, yCoor)
             bfUncertainty = obj.processOneCtcMeasurementUncertainty(obj.getCtc(xCoor, yCoor), ...
                                                          obj.getCtcFit(xCoor, yCoor));
         end%getMbfUncertainty
         
         function measStd = processOneCtcMeasurementUncertainty(obj, ctc, ctcFit)
             disp('deconvToolSpatioTemp:processOneCtcMeasurementUncertainty: this feature is not implemented yet');
             measStd = 0;
         end%processOneCtcMeasurementUncertainty
         
         function processCtcMeasurementUncertainty(obj)
             [H, W, T] = size(obj.ctcSet);
             mbfMeasStack = zeros(H, W, obj.nbBsIterations);
             dummyCtcSet = zeros(H, W, T);
             for k = 1 : obj.nbBsIterations
                 % measure the noise deviation on the baseline curve
                 % and generate new noised curved set from ctcSet
                 for l = 1 : H
                     for m = 1 : W
                         stdBaseLine  = std(squeeze(obj.ctcSet(l, m, 1 : obj.blLenMap(l, m))));
                         dummyCtcSet(l, m, :) = normrnd(squeeze(obj.fitCtcSet(l, m, :)), stdBaseLine);
                     end
                 end%for l = 1 : H
                 % process deconvolution and measure the mbf
                 [obj.fitResidue, ~, ~, ~, ~] = launchDeconvolution(obj.ctcSet, ...
                                        obj.clippingMask, obj.normAifCtc, obj.sptOpt.lambda_t,...
                                        obj.sptOpt.lambda_s, obj.sptOpt.lambda_p,...
                                        obj.sptOpt.delta, obj.sptOpt.dx,...
                                        obj.sptOpt.dy, obj.sptOpt.dt);
                for l = 1 : H
                    for m = 1 : W
                        mbfMeasStack(l, m, k) = max(obj.fitResidue(l, m, :));
                        if mbfMeasStack(l, m, k) > 0.2
                            mbfMeasStack(l, m, k) = 0.2;
                        end
                     end
                end%for l = 1 : H
             end%for k = 1 : nbRepetitions
             obj.mbfMeasUncertaintyMap = zeros(H, W);
             for l = 1 : H
                    for m = 1 : W
                        obj.mbfMeasUncertaintyMap(l, m) = std(mbfMeasStack(l, m, :));
                    end
             end% for l = 1 : H
         end%processCtcMeasurementUncertainty
         
         function processMeasurementUncertainty(obj)
             %ctc locations
             nonZeroCurPos = find(reshape(obj.deconvMask, 1, numel(obj.deconvMask)));
             
             bsTool = bootstrapTool('wild', obj.ctcSet, obj.fitCtcSet, obj.deconvMask, obj.normAifCtc, 1);
             [H, W] = size(obj.deconvMask);
             mbfMapStack = zeros(H, W, obj.nbBsIterations);
             for k = 1 : obj.nbBsIterations
                 %generate boostrap curves ctcSet
                 bsCtcSet = obj.restructureCtc(bsTool.run());
                 mbfMapStack(:, :, k) = obj.processPerfusionIndexes(bsCtcSet);
             end
            obj.mbfMeasUncertaintyMap = std(mbfMapStack, 0, 3);
            obj.mbfMeasUncertaintyMap = std(mbfMapStack, 0, 3);
         end%processMeasurementUncertainty
         
         
         function ctcSet = restructureCtc(obj, ctcList)
             [H, W] = size(obj.deconvMask);
             nonZeroCurPos = find(reshape(obj.deconvMask, 1, numel(obj.deconvMask)));
             [xCoor, yCoor] = ind2sub([H, W], nonZeroCurPos);
             if numel(xCoor) ~= size(ctcList, 2)
                 throw(MException('deconvToolSpatioTemp:restructureCtc', ...
                     'numbers of Ctc and locations mismatch'));
             end
             ctcSet = zeros(H, W, size(ctcList, 1));
             for k = 1 : numel(nonZeroCurPos)
                 ctcSet(xCoor(k), yCoor(k), :) = ctcList(:, k)';
             end
         end%restructureCtc
         
         function [mbfMap, mbvMap] = processPerfusionIndexes(obj, ctcSet)
             [obj.fitResidue, ~, ~, ~, ~] = launchDeconvolution(ctcSet, ...
                 obj.clippingMask, obj.normAifCtc, obj.sptOpt.lambda_t,...
                 obj.sptOpt.lambda_s, obj.sptOpt.lambda_p,...
                 obj.sptOpt.delta, obj.sptOpt.dx,...
                 obj.sptOpt.dy, obj.sptOpt.dt);
             
             [H, W, ~] = size(obj.fitResidue);
             
             mbfMap = zeros(H, W);
             mbvMap = zeros(H, W);
             
             for k = 1 : H
                 for l = 1 : W
                     if obj.clippingMask(k, l , 1)
                         mbfMap(k,l) = max(obj.fitResidue(k, l, :));
                         if mbfMap(k, l) > 0.2
                             disp('deconvToolSpatioTemp:runDeconvolution : warning overestimation!!!!');
                             mbfMap(k, l) = 0.2;
                         end
                         if isnan(obj.mbfMap(k, l))
                             disp('deconvToolSpatioTemp:runDeconvolution : warning nan found!!!!');
                             mbfMap(k, l) = 0.0000001;
                         end
                         mbvMap(k, l) = trapezoidalSum(squeeze(obj.fitResidue(k, l, :)), 1);
                         if isnan(obj.mbvMap(k, l))
                             disp('deconvToolSpatioTemp:runDeconvolution : warning nan found!!!!');
                             mbvMap(k, l) = 0.0000001;
                         end
                     end
                 end
             end
         end%processPerfusionIndexes
     end%methods(Access = public)
end%classdef deconvToolSpatioTemp < deconvTool
