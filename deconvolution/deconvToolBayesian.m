classdef deconvToolBayesian < deconvTool
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        sharedDir;
        opt;
    end
    
    methods (Access = public)
        function obj = deconvToolBayesian(obj)
            obj.oversampleFact = 5;
        end%deconvToolBayesian
        
        function obj = runDeconvolution(obj)
            start = tic;
            normAifCtcInterp = interp1(obj.tAcqAif, obj.normAifCtc, obj.tSim,...
                'linear', 'extrap');
            [H, W, T] = size(obj.ctcSet);
            %number of samples per curves
            nbAcq = length(obj.tAcqAif);
            % number of curves
            nbCtc = H * W;
            obj.mbfMap = zeros(H, W);
            obj.mbvMap = zeros(H, W);
            obj.fitCtcSet = zeros(H, W, T);
            
            
            % reshape curve set
            cexp = permute(obj.ctcSet, [3, 1, 2]);
            cexp = reshape(cexp, [nbAcq, nbCtc]);
            
            if ~max(obj.deconvMask(:))
                disp('deconvTool:runDeconvolution : no ctc to deconvolve');
                return;% if no ctc to deconvolve, return
            end
            %reshape mask the same way to remove the 0's curves (not in the deconv mask)
            linMask = reshape(obj.deconvMask, 1, numel(obj.deconvMask));
            nonZeroCurPos = find(linMask);
            
            %run deconvolution
            outStruct = obj.runCtcSetDeconvolution(cexp(:, nonZeroCurPos));
            
            %set bf estimates in right place of the list
            tmp = zeros(1, numel(obj.deconvMask));
            tmp(nonZeroCurPos) = outStruct.bf.em;
            % and reshape
            obj.mbfMap = reshape(tmp, [H, W]);
            
            
            %set bf estimates in right place of the list
            tmp(nonZeroCurPos) = outStruct.bv.em;
            obj.mbvMap = reshape(tmp, [H, W]);
            
            %set delay estimates in right place of the list
            outStruct.delay.em(outStruct.delay.em <= 0) = 1e-6;% differentiate 0sdelay with background
            tmp = zeros(1, numel(obj.deconvMask));
            tmp(nonZeroCurPos) = outStruct.delay.em;
            % and reshape
            obj.delayMap = reshape(tmp, [H, W]);

            if obj.processMeasUncertaintyFlag
                %obj.processMeasurementUncertainty();
                obj.processUncertaintyOnRoiRepresentativeCurve()
            else
                %set bf uncertainty in right place of the list
                tmp = zeros(1, numel(obj.deconvMask));
                tmp(nonZeroCurPos) = outStruct.bf.sig;
                obj.mbfMeasUncertaintyMap = reshape(tmp, [H, W]);
            end
            
            
            obj.processTime = obj.processTime + toc(start);
        end%runDeconvolution
        
        function obj = runRoiDeconvolution(obj, startPos, endPos)
            if nargin < 2
                startPos = 1; endPos = size(obj.roiCtcSet, 2);
            end
            obj.mbfRoiMapSet = zeros(size(obj.roiMaskSet));
            obj.mbfSigRoiMap = zeros(size(obj.roiMaskSet));
            obj.mbvRoiMapSet = zeros(size(obj.roiMaskSet));
            
            cexp = obj.roiCtcSet(:, startPos:endPos);
            
            outStruct = obj.runCtcSetDeconvolution(cexp);
            
            for k = 1 : size(cexp, 2)
                %obj.fitRoiCtcSet(k, :) = ctc.est_acq; % Not implemented
                %yet
                %get pixels of the current  ROI (since work is divided, start from starting roi pos)
                pos = find(obj.roiMaskSet == startPos - 1 + k);
                obj.mbfRoiMapSet(pos) =  outStruct.bf.em(k);
                obj.mbfSigRoiMap(pos) =  outStruct.bf.sig(k);
                obj.mbvRoiMapSet(pos) =  outStruct.bv.em(k);
            end
            
            
        end%runRoiDeconvolution
        
        function [ctc, residue, p_bf] = runOneCtcDeconvolution(obj, cexp, compDataFlag)
            if nargin < 3
                compDataFlag = false;
            end
            normAifCtcInterp = interp1(obj.tAcqAif, obj.normAifCtc, obj.tSim,...
                'linear', 'extrap');
            
            %             figureMgr.getInstance().newFig('processing'); gifplayer('D:\02_Matlab\src\test\interface\ressources\processing.gif');
            try
                %[bf, mtt, bv, epsilon, delay, r, cth, sigma, p_bf, p_delay, qualitative_parameters]
                fprintf('running with worker: %s\n', obj.sharedDir);
                [~, ~, ~,    ~  ,   ~  ,  residue,  ctc,   ~ ,   p_bf ,    ~   ,     ~ ] = ...
                    exe_perf_bayes_irr_fast_win(cexp(:), obj.tAcqSlc', normAifCtcInterp, obj.tSim', obj.opt, obj.sharedDir);
            catch e
                %                 figureMgr.getInstance().closeFigure('processing');
                msgbox(['error: ' e.message]);
                rethrow(e);
            end
            if ~compDataFlag
                ctc = ctc.est_acq;
            end
        end%runDeconvolution
        
        function obj = prepare(obj, opt)%normAifCtc, ctcSet, tAcqAif, opt, mask, roiMaskSet)
            obj = obj.prepare@deconvTool(opt);%normAifCtc, ctcSet, tAcqAif, opt, mask, roiMaskSet);
             if isfield(opt, 'sharedDir')
                 obj.sharedDir = opt.sharedDir;
             else
                 obj.sharedDir = 'D:\10_Share\olea\worker1\data\';
             end
             obj.cleanSharedDir();
             obj.opt = struct('dt', (obj.tSim(2) - obj.tSim(1)), 'delaymin', 0, 'delaymax', 10,...
                'bfmin', 0.01 / 60, 'bfmax', 4.2 / 60, 'bfsize', 50, 'bfsampling', 'loglinear' ,...
                'alphamin', 1e-3, 'alphamax', 1e10,'alphasize', 50, 'alphasampling', 'loglinear', ...
                'convolution_scheme', 4, 'prior_bf', 'uniform', ...
                'regularization_order', 2, 'trmax', obj.tSim(end) .* 0.6, 'prior_epsilon', 'jeffreys');
        end%prepare
        
        
        %getters
        function ctcFit = getCtcFit(obj, xCoor, yCoor)
             % reshape curve set
            ctcFit = obj.runOneCtcDeconvolution(squeeze(obj.ctcSet(xCoor, yCoor, :)));
        end%getCtcFit
        
        function deconvResults = getDeconvResults(obj, xCoor, yCoor)
            [deconvResults.ctcFit, deconvResults.residue,  deconvResults.p_bf] = ...
                obj.runOneCtcDeconvolution(squeeze(obj.ctcSet(xCoor, yCoor, :)), true);
        end%getdeconvData
        
        function avgRoiCtcFit = getAvgRoiCtcFit(obj, roiId)
            avgRoiCtcFit = obj.runOneCtcDeconvolution(obj.getAvgRoiCtc(roiId));
        end%getAvgRoiCtcFit
        
        function bfUncertainty = getMbfUncertainty(obj, xCoor, yCoor)
            try 
                bfUncertainty = obj.mbfMeasUncertaintyMap(xCoor, yCoor);
            catch
                bfUncertainty = ...
                    obj.processOneCtcMeasurementUncertainty(obj.getCtc(xCoor, yCoor), ...
                                                          obj.getCtcFit(xCoor, yCoor));
            end
        end%getMbfUncertainty
        
        function delayMap = getDelayMap(obj)
            delayMap = obj.delayMap;
        end%getDelayMap
        
        
        function outStruct = runCtcSetDeconvolution(obj, ctcSet)
            normAifCtcInterp = interp1(obj.tAcqAif, obj.normAifCtc, obj.tSim,...
                'linear', 'extrap');
            try
                %[bf, mtt, bv, epsilon, delay, r, cth, sigma, p_bf, p_delay, qualitative_parameters]
                fprintf('running with worker: %s\n', obj.sharedDir)
                [outStruct.bf, outStruct.mtt, outStruct.bv,    ~  ,   outStruct.delay  ,  ~,  outStruct.ctc,   ~ ,   ~ ,    ~   ,     ~ ] = ...
                    exe_perf_bayes_irr_fast_win(ctcSet, obj.tAcqSlc', normAifCtcInterp, obj.tSim', obj.opt, obj.sharedDir);
            catch e
                %                 figureMgr.getInstance().closeFigure('processing');
                msgbox(['error: ' e.message]);
                rethrow(e);
            end
        end%runCtcSetDeconvolution
        
        
    end%methods (Access = public)
%% protected methods
    methods (Access = protected)
        function measStd = processOneCtcMeasurementUncertainty(obj, ctc, ctcFit)
            nbRepetitions = 100;
            baselineLength = processBaseline(ctcFit, 3, 4);
            stdBaseLine = std(ctc(1:(baselineLength - 5) ));
            %remove 5 last points to be sure not to have signal
            
            normAifCtcInterp = interp1(obj.tAcqAif, obj.normAifCtc, obj.tSim,...
                'linear', 'extrap');
            
            for k = 1 : nbRepetitions
                cexp(:, k) = normrnd(ctcFit, stdBaseLine);
            end
            try
                fprintf('running with worker: %s\n', obj.sharedDir)
                %[bf, mtt, bv, epsilon, delay, r, cth, sigma, p_bf, p_delay, qualitative_parameters]
                [bf,     ~, ~,    ~  ,   ~  ,  ~,  ~,   ~ ,   ~ ,    ~   ,     ~ ] = ...
                    exe_perf_bayes_irr_fast(cexp, obj.tAcqAif', normAifCtcInterp, obj.tSim', obj.opt, obj.sharedDir);
            catch e
                %                 figureMgr.getInstance().closeFigure('processing');
                msgbox(['error: ' e.message]);
                rethrow(e);
            end
            figureMgr.getInstance().newFig('deconvToolBayesian:processOneCtcMeasurementUncertainty');
            plot(cexp(:,1)); hold all; plot(ctc, '--');
            plot(ctcFit); %debug purpose
            legend('noised ctcFit', 'ctc', 'ctcFit');
            measStd = std(bf.em);
        end%processOneCtcMeasurementUncertainty()
        
        function processMeasurementUncertainty(obj)
            normAifCtcInterp = interp1(obj.tAcqAif, obj.normAifCtc, obj.tSim,...
                'linear', 'extrap');
            
            [H, W, T] = size(obj.ctcSet);
            obj.mbfMeasUncertaintyMap = zeros(H, W);
            obj.bsMbfMap = zeros(H, W);
            % reshape curve set
%             cexp = permute(obj.ctcSet, [3, 1, 2]);
%             cexp = reshape(cexp, [nbAcq, nbCtc]);
            
            %reshape mask the same way to remove the 0's curves (not in the deconv mask)
            linMask = reshape(obj.deconvMask, 1, numel(obj.deconvMask));
            nonZeroCurPos = find(linMask);
            
            %generate boostrap curves
            bsTool = bootstrapTool('wild', obj.ctcSet, obj.fitCtcSet, obj.deconvMask, obj.normAifCtc, obj.nbBsIterations);
            rCexp = bsTool.run();
            
            try
                fprintf('running with worker: %s\n', obj.sharedDir)
                %[bf, mtt, bv, epsilon, delay, r, cth, sigma, p_bf, p_delay, qualitative_parameters]
                [bf, mtt, bv,    ~  ,   ~  ,  ~,  ~,   ~ ,   ~ ,    ~   ,     ~ ] = ...
                    exe_perf_bayes_irr_fast_win(rCexp, obj.tAcqAif', normAifCtcInterp, obj.tSim', obj.opt, obj.sharedDir);
            catch e
                %                 figureMgr.getInstance().closeFigure('processing');
                msgbox(['error: ' e.message]);
                rethrow(e);
            end
            
            % reshape estimation vector as a matrix dimensioned 
            % [repetition nbEstimations]
            tmp = reshape(bf.em, numel(nonZeroCurPos), obj.nbBsIterations)';
            % measure deviation of each measurement, and store it to its
            % location in mbfMeasUncertaintyMap
            obj.mbfMeasUncertaintyMap(nonZeroCurPos) = std(tmp);
            obj.bsMbfMap(nonZeroCurPos) = mean(tmp);
        end%processMeasurementUncertainty
        
        function cleanSharedDir(obj)
            %remove possible remaining old subdirectories
            dirList = dir(obj.sharedDir);
            for k = 3 : length(dirList)
                if strcmp(dirList(k).name(end-2:end), 'raw')
                    try
                        delete(fullfile(obj.sharedDir, dirList(k).name));
                    catch e
                        cprintf('red','error with worker : %s, \n trying to remove dir %s',...
                            obj.sharedDir, fullfile(obj.sharedDir, dirList(k).name));
                        rethrow(e);
                    end
                end
            end
        end%cleanSharedDir
        

       
    end%methods (Access = protected)
     
end

