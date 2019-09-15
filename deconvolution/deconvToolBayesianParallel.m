classdef deconvToolBayesianParallel < deconvTool
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        deconvToolBayesianWorkersTab; % table of standard bayesian deconvTool
        Hmid;
        Wmid;
        nbWorkers;
    end
    
    methods (Access = public)
        function obj = deconvToolBayesianParallel(obj)
            obj.deconvToolBayesianWorkersTab = deconvToolBayesian();
            for k = 2 : 4
                obj.deconvToolBayesianWorkersTab(k) = deconvToolBayesian();
            end
        end%deconvToolBayesianParallel
        
        function runDeconvolution(obj)
            disp('running pixelwise deconvolution');
            tstart = tic;
            localWorkersTab = obj.deconvToolBayesianWorkersTab(:);
            startPool(4);
            parfor k = 1 : obj.nbWorkers
                localWorkersTab(k) = obj.deconvToolBayesianWorkersTab(k).runDeconvolution();
            end
            for k = 1 : obj.nbWorkers
                obj.deconvToolBayesianWorkersTab(k) = localWorkersTab(k);
            end
            %merge the sub maps
            obj.mbfMap(1 : obj.Hmid,...
                        1 : obj.Wmid) = obj.deconvToolBayesianWorkersTab(1).getMbfMap();
            obj.mbfMap(1 : obj.Hmid,...
                            obj.Wmid + 1 : end) = obj.deconvToolBayesianWorkersTab(2).getMbfMap();
            obj.mbfMap(obj.Hmid + 1 : end,...
                            1 : obj.Wmid) = obj.deconvToolBayesianWorkersTab(3).getMbfMap();
            obj.mbfMap(obj.Hmid + 1 : end,...
                            obj.Wmid + 1 : end) = obj.deconvToolBayesianWorkersTab(4).getMbfMap();
            
            obj.mbvMap(1 : obj.Hmid,...
                        1 : obj.Wmid) = obj.deconvToolBayesianWorkersTab(1).getMbvMap();
            obj.mbvMap(1 : obj.Hmid,...
                            obj.Wmid + 1 : end) = obj.deconvToolBayesianWorkersTab(2).getMbvMap();
            obj.mbvMap(obj.Hmid + 1 : end,...
                            1 : obj.Wmid) = obj.deconvToolBayesianWorkersTab(3).getMbvMap();
            obj.mbvMap(obj.Hmid + 1 : end,...
                            obj.Wmid + 1 : end) = obj.deconvToolBayesianWorkersTab(4).getMbvMap();
            
            obj.processTime = toc(tstart);
                        
        end%runDeconvolution
        
        function obj = processBaselineLengthMap(obj)
            for k = 1 : obj.nbWorkers
                obj.deconvToolBayesianWorkersTab(k).processBaselineLengthMap();
            end
        end%processBaselineLengthMap
        
        function obj = runRoiDeconvolution(obj)
            disp('running ROI deconvolution');
            nbRois = size(obj.roiCtcSet, 2);
            if nbRois <= 7
                %only run with one worker since roi since there is not that much Ctc
                % even for one worker
                obj.deconvToolBayesianWorkersTab(1).runRoiDeconvolution(1, nbRois);
                obj.mbfRoiMapSet = obj.deconvToolBayesianWorkersTab(1).getMbfRoiMapSet();
                obj.mbvRoiMapSet = obj.deconvToolBayesianWorkersTab(1).getMbvRoiMapSet();
            else
                %split the ctcSet between each workers
                nbRoisPerWorker = floor(nbRois / 4);
                startPosTab = 1 + (0 : obj.nbWorkers - 1) * nbRoisPerWorker;
                endPosTab = (1 : obj.nbWorkers) * nbRoisPerWorker;
                endPosTab(end) = nbRois;
                
                localWorkersTab = obj.deconvToolBayesianWorkersTab(:);
                parfor k = 1 : obj.nbWorkers
                    localWorkersTab(k) = localWorkersTab(k).runRoiDeconvolution(startPosTab(k), endPosTab(k));
                end
                for k = 1 : obj.nbWorkers
                    obj.deconvToolBayesianWorkersTab(k) = localWorkersTab(k);
                end
                %merge the parameters Map Sets
                obj.mbfRoiMapSet = obj.deconvToolBayesianWorkersTab(1).getMbfRoiMapSet() + ...
                    obj.deconvToolBayesianWorkersTab(2).getMbfRoiMapSet() + ...
                    obj.deconvToolBayesianWorkersTab(3).getMbfRoiMapSet() + ...
                    obj.deconvToolBayesianWorkersTab(4).getMbfRoiMapSet();
                
                obj.mbvRoiMapSet = obj.deconvToolBayesianWorkersTab(1).getMbvRoiMapSet() + ...
                    obj.deconvToolBayesianWorkersTab(2).getMbvRoiMapSet() + ...
                    obj.deconvToolBayesianWorkersTab(3).getMbvRoiMapSet() + ...
                    obj.deconvToolBayesianWorkersTab(4).getMbvRoiMapSet();
                
            end
        end%runRoiDeconvolution
        
        function obj = prepare(obj, normAifCtc, ctcSet, tAcq, opt, mask, roiMaskSet)
            nbAcq = floor(length(tAcq) * opt.timePortion);
            obj = obj.setTAcq(tAcq(1:1:nbAcq));
            obj = obj.setCtcSet(ctcSet(:, :, 1:nbAcq));
            obj.normAifCtc = normAifCtc;
            obj.nbWorkers = 4;
            [H, W, ~] = size(ctcSet);
            %prepare mbf and mbv maps
            obj.mbfMap = zeros(H, W);
            obj.mbvMap = zeros(H, W);
            % divide the ctcSet in 4 parts approximately equals
            [obj.Wmid, obj.Hmid] = obj.getmaskCenterPos(mask);
%             
%             obj.Hmid = floor(H / 2);
%             obj.Wmid = floor(W / 2);
            for k = 1 : obj.nbWorkers
                switch k
                    case 1
                        subCtcSet = ctcSet(1 : obj.Hmid,...
                            1 : obj.Wmid, :);
                        subMask = mask(1 : obj.Hmid,...
                            1 : obj.Wmid);
                    case 2
                        subCtcSet = ctcSet(1 : obj.Hmid,...
                            (obj.Wmid + 1) : end, :);
                        subMask = mask(1 : obj.Hmid,...
                            (obj.Wmid + 1) : end);
                    case 3
                        subCtcSet = ctcSet((obj.Hmid + 1) : end,...
                            1 : obj.Wmid, :);
                        subMask = mask((obj.Hmid + 1) : end,...
                            1 : obj.Wmid);
                    case 4
                        subCtcSet = ctcSet((obj.Hmid + 1) : end,...
                            (obj.Wmid + 1) : end, :);
                        subMask = mask((obj.Hmid + 1) : end,...
                            (obj.Wmid + 1) : end);
                    otherwise
                        throw(MException('deconvToolBayesianParallel:prepare', 'only 4 parallel workers'));
                end
                
                opt.sharedDir = sprintf('D:\\10_Share\\olea\\worker%d\\data\\', k);
                obj.deconvToolBayesianWorkersTab(k).prepare(normAifCtc, subCtcSet, tAcq, opt, subMask);
                obj.patchWidth = opt.patchWidth;
                obj.deconvMask = mask;
            end%for k = 1 : obj.nbWorkers
            %static attrbutes
            obj.nbBsIterations = obj.deconvToolBayesianWorkersTab(1).getNbBsIterations;
            obj.roiMaskSet = roiMaskSet;
            obj = obj.createRoiCtc();
            for k = 1 : obj.nbWorkers
                obj.deconvToolBayesianWorkersTab(k).setRoiMaskSet(roiMaskSet);
                obj.deconvToolBayesianWorkersTab(k).setRoiCtcSet(obj.roiCtcSet);
            end
        end%prepare
        
        function ctc = getCtc(obj, xCoor, yCoor)
            if yCoor <= obj.Wmid
                if xCoor <= obj.Hmid; worker = 1;
                else worker = 3; xCoor = xCoor - obj.Hmid; end
            else
                yCoor = yCoor - obj.Wmid;
                if xCoor <= obj.Hmid; worker = 2; 
                else worker = 4; xCoor = xCoor - obj.Hmid; end
            end
            ctc = obj.deconvToolBayesianWorkersTab(worker).getCtc(xCoor, yCoor);
        end%getCtc
        
        
        function tAcq = getTAcq(obj)
            %tAcq is the same for all workers
            tAcq = obj.deconvToolBayesianWorkersTab(1).getTAcq();
        end%getTAcq
        
        function ctc = getCtcFit(obj, xCoor, yCoor)
            %find responsible worker and shift coordinates
            if yCoor <= obj.Wmid
                if xCoor <= obj.Hmid; worker = 1; 
                else worker = 3; xCoor = xCoor - obj.Hmid; end
            else
                yCoor = yCoor - obj.Wmid;
                if xCoor <= obj.Hmid; worker = 2; 
                else worker = 4; xCoor = xCoor - obj.Hmid; end
            end
                ctc = obj.deconvToolBayesianWorkersTab(worker).getCtcFit(xCoor, yCoor);
        end%getCtcFit
        
        function fitCtcSet = getFitCtcSet(obj)
            [H, W, T] = size(obj.ctcSet);
            fitCtcSet = zeros(H, W, T);
            
            fitCtcSet(1 : obj.Hmid, 1 : obj.Wmid, :) = ...
                obj.deconvToolBayesianWorkersTab(1).getFitCtcSet();
            fitCtcSet(1 : obj.Hmid, obj.Wmid + 1 : end, :) = ...
                obj.deconvToolBayesianWorkersTab(2).getFitCtcSet();
            fitCtcSet(obj.Hmid + 1 : end, 1 : obj.Wmid, :) = ...
                obj.deconvToolBayesianWorkersTab(3).getFitCtcSet();
            fitCtcSet(obj.Hmid + 1 : end, obj.Wmid + 1 : end, :) = ...
                obj.deconvToolBayesianWorkersTab(4).getFitCtcSet();
            
        end%getFitCtcSet
        
        
        function avgRoiCtcFit = getAvgRoiCtcFit(obj, roiId)
            ctc = obj.getAvgRoiCtc(roiId);
            avgRoiCtcFit = obj.deconvToolBayesianWorkersTab(1).getAvgRoiCtcFit(ctc);
        end%getAvgRoiCtcFit
        
        function bfUncertainty = getMbfUncertainty(obj, xCoor, yCoor)
            %find responsible worker and shift coordinates
            if yCoor <= obj.Wmid
                if xCoor <= obj.Hmid; worker = 1; 
                else worker = 3; xCoor = xCoor - obj.Hmid; end
            else
                yCoor = yCoor - obj.Wmid;
                if xCoor <= obj.Hmid; worker = 2; 
                else worker = 4; xCoor = xCoor - obj.Hmid; end
            end
            bfUncertainty = obj.deconvToolBayesianWorkersTab(worker).getMbfUncertainty(xCoor, yCoor);
        end%getMbfUncertainty
        
        function bfUncertaintyMap = getMbfUncertaintyMap(obj, unit)
            if nargin < 2
                unit = 'ml/min/g';
            end
            tmp = obj.mbfMap;
            [H, W] = size(tmp);
            
            bfUncertaintyMap = zeros(H,W);
            bfUncertaintyMap(1 : obj.Hmid, 1 : obj.Wmid, :) = ...
                obj.deconvToolBayesianWorkersTab(1).getMbfUncertaintyMap(unit);
            bfUncertaintyMap(1 : obj.Hmid, obj.Wmid + 1 : end, :) = ...
                obj.deconvToolBayesianWorkersTab(2).getMbfUncertaintyMap(unit);
            bfUncertaintyMap(obj.Hmid + 1 : end, 1 : obj.Wmid, :) = ...
                obj.deconvToolBayesianWorkersTab(3).getMbfUncertaintyMap(unit);
            bfUncertaintyMap(obj.Hmid + 1 : end, obj.Wmid + 1 : end, :) = ...
                obj.deconvToolBayesianWorkersTab(4).getMbfUncertaintyMap(unit);
        end%getMbfUncertaintyMap
        
        function bsMbfMap = getBsMbfMap(obj)
            tmp = obj.mbfMap;
            [H, W] = size(tmp);
            bsMbfMap = zeros(H,W);
            bsMbfMap(1 : obj.Hmid, 1 : obj.Wmid, :) = ...
                obj.deconvToolBayesianWorkersTab(1).getBsMbfMap();
            bsMbfMap(1 : obj.Hmid, obj.Wmid + 1 : end, :) = ...
                obj.deconvToolBayesianWorkersTab(2).getBsMbfMap();
            bsMbfMap(obj.Hmid + 1 : end, 1 : obj.Wmid, :) = ...
                obj.deconvToolBayesianWorkersTab(3).getBsMbfMap();
            bsMbfMap(obj.Hmid + 1 : end, obj.Wmid + 1 : end, :) = ...
                obj.deconvToolBayesianWorkersTab(4).getBsMbfMap();
        end%getBsMbfMap
        
        function [x, y] = getmaskCenterPos(obj, mask)
             bm = regionprops(mask, 'centroid');
             x = floor(bm.Centroid(1)); y = floor(bm.Centroid(2));
        end%getmaskCenterPos
        
    end%methods (Access = public)
    
    %% methods protected
    methods (Access = protected)
        
%         function processMeasurementUncertainty(obj)
%             disp('to be done');
%         end
        
    end
    
end

