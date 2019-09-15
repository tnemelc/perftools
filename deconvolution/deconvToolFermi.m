classdef deconvToolFermi < deconvTool
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        cutOff; % CA first pass cut off time value 
        roiAnlzrTool;% roi analyzr tool runned by function prepare
                     % to obtain time curves delay
        delayMask;
        roiDelayTab; %table of delays associated to the curves stored in roiCtcSet
    end
    
    methods (Access = public)
        function obj = deconvToolFermi()
            obj.oversampleFact = 5;
            obj.mbfPriorMap = [];
            obj.mbvPriorMap = [];
        end
        
        function obj = prepare(obj, opt)
            obj = obj.prepare@deconvTool(opt);
            % cut time interval from t=0 to t1 for which  t1 > tpeak
            obj.optimizeTimeInterval();
            tmpRes = obj.tAcq(2) - obj.tAcq(1);
            %             obj.tSim = obj.tAcq(1) : (tmpRes / obj.oversampleFact) : obj.tAcq(obj.cutOff);
            obj.tSim = obj.tAcqAif(1) :  tmpRes  / obj.oversampleFact : obj.tAcqAif(obj.cutOff);
            
            switch opt.deconvMode
                case 'patient'
                    % create and prepare roi analyzer tool
                    obj.roiAnlzrTool = bullseyeSegmentRoiAnalyzerTool();
                    obj.roiAnlzrTool = obj.roiAnlzrTool.prepare(opt);
                    obj.roiAnlzrTool = obj.roiAnlzrTool.run();
                    obj.delayMask = obj.roiAnlzrTool.getFeaturesMask('voxelTicDelay', obj.slcName);
                    obj.delayMap = obj.roiAnlzrTool.getFeaturesMask('voxelTicDelay', obj.slcName);
                    %calculate roi time intensity curves delay AFTER
                    % roiAnalyzrTool.run() since ist needs its results
                    obj = obj.processRoiDelays();
                case 'phantom'
                    [H, W, ~] = size(obj.ctcSet);
                    obj.delayMask = ones(H, W) .* (opt.delay * tmpRes);
            end
        end%prepare
        %%
        function obj = runDeconvolution(obj)
            tic;
            %run roiAnalyzerTool to get delaymap        
            normAifCtcInterp = interp1(obj.tAcqAif(1 : obj.cutOff), obj.normAifCtc(1 : obj.cutOff), obj.tSim,...
                'linear', 'extrap');
%             normAifCtcInterp = interp1(obj.tAcqAif(1 : end), obj.normAifCtc(1 : end), obj.tSim,...
%                 'linear', 'extrap');

            [H, W, T] = size(obj.ctcSet);
            obj.initPriorMaps();
            
            mbfMap = zeros(H, W);
            mbvMap = zeros(H, W);
            delayMap = zeros(H, W);
            fitCtcSet = zeros(H, W, obj.cutOff);
            residueSet = zeros(H, W, obj.cutOff);
            deconvMask = obj.deconvMask; 
            %wb = waitbar(0, 'processing...'); cpt = 0;
            startPool(12);
            tSim = obj.tSim;
           parfor mbfIdx = 1 : H
%               for mbfIdx = 1 : H%uncomment this line for debug
%                 %waitbar(mbfIdx / H, wb, 'processing Fermi...');
                for mbvIdx = 1 : W
                    if deconvMask(mbfIdx, mbvIdx)
                        % input parameters for optimization
                        %  mbf                                k   t0  
                        %p = [obj.mbfPriorMap(mbfIdx, mbvIdx), 0.1, max(0, obj.delayMask(mbfIdx, mbvIdx) - 4), 0];
                        p = [obj.mbfPriorMap(mbfIdx, mbvIdx), 0.1, 3, 0];
                        try 
                            [mbfMap(mbfIdx, mbvIdx), ...
                                mbvMap(mbfIdx, mbvIdx), ...
                                fitCtc, residue, delayMap(mbfIdx, mbvIdx)] = ...
                                fitFermi(normAifCtcInterp, tSim, ...
                                interp1(obj.tAcqSlc(1 : obj.cutOff), squeeze(obj.ctcSet(mbfIdx, mbvIdx, 1 : obj.cutOff)),...
                                obj.tSim, 'linear', 'extrap'), p);
%                                 ctSim  = interp1(obj.tAcqSlc, squeeze(obj.ctcSet(mbfIdx, mbvIdx, :))',  obj.tSim, 'linear', 'extrap');
%                                 [mbfMap(mbfIdx, mbvIdx), ...
%                                 mbvMap(mbfIdx, mbvIdx), ...
%                                 fitCtc, residue] = fitFermiUnitaryFFT(normAifCtcInterp, obj.tSim, ctSim, [2 / 60, 1,  5]);
                        catch e
                            fprintf('error with function at position (%d, %d)', mbfIdx, mbvIdx);
                            rethrow(e);
                        end
                        fitCtcSet(mbfIdx, mbvIdx, :) = interp1(obj.tSim, fitCtc, obj.tAcqSlc(1 : obj.cutOff), 'linear', 'extrap');
                        residueSet(mbfIdx, mbvIdx, :) = interp1(obj.tSim, residue, obj.tAcqSlc(1 : obj.cutOff), 'linear', 'extrap');
                    end
                end
            end
            
              obj.mbfMap = mbfMap;
              obj.mbvMap = mbvMap;
              obj.delayMap = delayMap;
              obj.delayMask = delayMap;
              obj.fitCtcSet = fitCtcSet;
              obj.fitResidue = residueSet;
              
              %close(wb);
              obj.processTime = obj.processTime + toc;
              
              % process time to peak
              obj.processTimeToPeak();
              %process measure uncertainty maps
            if obj.processMeasUncertaintyFlag
                obj.processUncertaintyOnRoiRepresentativeCurve();
            end
             % empty prior maps for following run
              obj.mbfPriorMap = []; obj.mbvPriorMap = [];
              
              obj.processTime = obj.processTime + toc;
        end% runDeconvolution(obj)
        %%
        function obj = runRoiDeconvolution(obj)
            normAifCtcInterp = interp1(obj.tAcqAif(1 : obj.cutOff), obj.normAifCtc(1 : obj.cutOff), obj.tSim,...
                                        'linear', 'extrap');
            nbRoi = size(obj.roiCtcSet, 2);
            obj.fitRoiCtcSet = zeros(obj.cutOff, nbRoi);
            obj.mbfRoiMapSet = zeros(size(obj.roiMaskSet));
            obj.mbvRoiMapSet = zeros(size(obj.roiMaskSet));
            
            for k = 1 : nbRoi;
                % input parameters for optimization
                %  mbf                                k   t0
                p = [0.01, 0.1, max(0, obj.roiDelayTab(k) - 4), 0];
                [mbf, mbv, ...
                    fitCtc] = ...
                    fitFermi(normAifCtcInterp, obj.tSim, ...
                    interp1(obj.tAcqSlc(1 : obj.cutOff), squeeze(obj.roiCtcSet(1:obj.cutOff, k))',...
                    obj.tSim, 'linear', 'extrap'), p);
                obj.fitRoiCtcSet(:, k) = interp1(obj.tSim, fitCtc, obj.tAcqSlc(1:obj.cutOff), 'linear', 'extrap')';
                % place mbf were roi is on roimbf map
                pos = find(obj.roiMaskSet == k);
                obj.mbfRoiMapSet(pos) = mbf;
                obj.mbvRoiMapSet(pos) = mbv;
            end
                                    
        end%runRoiDeconvolution
        %% 
        function outStruct = runCtcSetDeconvolution(obj, ctcSet)
            normAifCtcInterp = interp1(obj.tAcqAif(1 : obj.cutOff), obj.normAifCtc(1 : obj.cutOff), obj.tSim,...
                'linear', 'extrap');

            %%%%%
            %satisfy parfor requirements
            parforTSim = obj.tSim;
            parforTAcqSlc = obj.tAcqSlc(1 : obj.cutOff);
            %%%
            parfor k = 1 : size(ctcSet, 2)
                try
                    [bf(k), ...
                        bv(k), ...
                        fit(:, k), residue(:, k)] = ...
                        fitFermi(normAifCtcInterp, parforTSim, ...
                        interp1(parforTAcqSlc, squeeze(ctcSet(:, k)),...
                        parforTSim, 'linear', 'extrap'));
                catch e
                    cprintf('red', 'deconvToolFermi::runCtcSetDeconvolution error with ctc at position %d)', k);
                    rethrow(e);
                end
            end
            
            for k = 1 : size(ctcSet, 2)
                outStruct.bf.em(k) = bf(k);
                outStruct.bv.em(k) = bv(k);
                outStruct.fit(:, k) = fit(:, k);
                outStruct.residue(:, k) = residue(:, k);
            end
        end%runCtcSetDeconvolution
        
        %%
        function obj = processRoiDelays(obj)
            nbRoi = max(obj.roiMaskSet(:));
            for k = 1 : nbRoi
                delayVect = obj.delayMask(obj.roiMaskSet == k);
                obj.roiDelayTab(k) = mean(delayVect);
            end
        end
        %%
        function obj = processTimeToPeak(obj)
            [H, W, ~] = size(obj.ctcSet);
            obj.ttpMap = zeros(H, W);
            for k = 1 : H
                for l = 1: W
                    if obj.deconvMask(k, l)
                        pkVal = max(squeeze(obj.fitCtcSet(k, l, :)));
                        pos = find(squeeze(obj.fitCtcSet(k, l, :)) == pkVal, 1, 'first');
                        obj.ttpMap(k, l) = obj.tAcq(pos);
                    end
                end
            end
        end%processTimeToPeak
    end%(Access = public)
    
    
    methods (Access = protected)
        function obj = initPriorMaps(obj)
            if isempty(obj.mbfPriorMap)
                [H, W, ~] = size(obj.ctcSet);
                obj.mbfPriorMap = ones(H, W) .* 0.01;
                obj.mbvPriorMap = ones(H, W) .* 0.01;
            end
        end %initPriorMaps
        
        function optimizeTimeInterval(obj)
            % cut time interval from t=0 to t1 for which  t1 > tpeak 
            % Ca(t1) = min(Ca(t))
            pkPos = find(obj.normAifCtc == max(obj.normAifCtc));
            
            obj.cutOff = pkPos + find(obj.normAifCtc(pkPos:end) == min(obj.normAifCtc(pkPos:end)), 1, 'first') - 1;
        end
        
        function obj = processMeasurementUncertainty(obj)
            [H, W, ~] = size(obj.ctcSet);
             normAifCtcInterp = interp1(obj.tAcq(1 : obj.cutOff), obj.normAifCtc(1 : obj.cutOff), obj.tSim,...
                                        'linear', 'extrap');
            %generate boostrap curves
            bsTool = bootstrapTool('wild', obj.ctcSet(:,:,1:obj.cutOff), obj.fitCtcSet, obj.deconvMask, obj.normAifCtc(1:obj.cutOff), obj.nbBsIterations);
            bsCtc = bsTool.run();
            
            nonZeroCurPos = find(reshape(obj.deconvMask, 1, numel(obj.deconvMask)));
            nbCtc = numel(nonZeroCurPos);
            mbfVect = zeros(1, nbCtc);
            mbvVect = zeros(1, nbCtc);
            mbfMapStack = zeros(H, W, obj.nbBsIterations);
            mbvMapStack = zeros(H, W, obj.nbBsIterations);
            
            [xCoor, yCoor] = ind2sub([H, W], nonZeroCurPos);
            
            for k = 1 : obj.nbBsIterations
                parfor l = 1 : nbCtc
%                   for l = 1 : nbCtc
                    try
                        [mbfVect(l), mbvVect(l),  ~] = ...
                            fitFermi(normAifCtcInterp, obj.tSim, ...
                            interp1(obj.tAcq(1 : obj.cutOff), bsCtc(:, (k - 1) * nbCtc + l)',...
                            obj.tSim, 'linear', 'extrap'), ...
                            [obj.mbfPriorMap(xCoor(l), yCoor(l)), obj.mbvPriorMap(xCoor(l), yCoor(l)), 0, 1]);
                    catch e
                        fprintf('error with function at position (%d, %d)', xCoor(l), yCoor(l));
                        rethrow(e);
                    end
                end
                for l = 1 : nbCtc
                    mbfMapStack(xCoor(l), yCoor(l), k) = mbfVect(l);
                    mbvMapStack(xCoor(l), yCoor(l), k) = mbvVect(l);
                end
            end
            obj.bsMbfMap = mean(mbfMapStack, 3);
            obj.bsMbvMap = mean(mbvMapStack, 3);
            obj.mbfMeasUncertaintyMap = std(mbfMapStack, 0, 3);
            obj.mbvMeasUncertaintyMap = std(mbvMapStack, 0, 3);
        end %processMeasurementUncertainty
        
        %%
        function processRoiRepresentativeCtc(obj)
            obj.processRoiRepresentativeCtc@deconvTool();
            %[T, nbCtc] =  size(obj.roiRepresentativeCtcSet);
            %paddingTab = zeros(T - obj.cutOff, nbCtc);
            obj.roiRepresentativeCtcSet = obj.roiRepresentativeCtcSet(1 : obj.cutOff , :);
        end%processRoiRepresentativeCtc
        
    end%(Access = protected)
    
end%classdef