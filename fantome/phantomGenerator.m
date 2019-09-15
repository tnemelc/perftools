classdef phantomGenerator
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        % static parameters
        modelList
        tempRes;
        
        % model fixed parameters
        normAifCtc;
        normAifCtcInterp;
        tAcq;
        tSim;
        
        % simulation results
        mbfMap; mbvMap; mttMap; % Fermi
        ftMap; vpMap; psMap;        %FtKpsVpVe
        % concetration time curves
        ctcSet;
        % noised concentration time curves
        nCtcSet;
        % residue curve set
        residueSet;
    end

    %% public methods
    methods(Access = public)
        %constructor
        function obj = phantomGenerator()
            obj.tempRes = 0.7; % static
        end

% getters
        %Fermi
        function mbfMap = getMbfMap(obj)
            mbfMap = obj.mbfMap;
        end%getMbfMap
        
        function mbvMap = getMbvMap(obj)
            mbvMap = obj.mbvMap;
        end%getMbvMap
        
        function mttMap = getMttMap(obj)
            mttMap = obj.mttMap;
        end%getMttMap
        
        function mbf = getMbf(obj, xCoord, yCoord)
            mbf = obj.mbfMap(xCoord, yCoord);
        end%getMbf
        
        function mbv = getMbv(obj, xCoord, yCoord)
            mbv =obj.mbvMap(xCoord, yCoord);
        end%getMbf
        
        % FtKpsVpVe
        function ftMap = getFtMap(obj)
            ftMap = obj.ftMap;
        end%getFtMap
        
        function vpMap = getVpMap(obj)
            vpMap = obj.vpMap;
        end%getVpMap
        
        function psMap = getPsMap(obj)
            psMap = obj.psMap;
        end%getPsMap
                
        function ft = getFt(obj, xCoord, yCoord)
            ft = obj.ftMap(xCoord, yCoord);
        end%getFtMap
        
        function vp = getVp(obj, xCoord, yCoord)
            vp = obj.vpMap(xCoord, yCoord);
        end%getVpMap
        
        function psMap = getPs(obj, xCoord, yCoord)
            psMap = obj.psMap(xCoord, yCoord);
        end%getPsMap
        
        % Ctc
        function ctcSet = getCtcSet(obj)
            ctcSet = obj.ctcSet;
        end%getCtcSet
        
        function ctc = getCtc(obj, xCoord, yCoord)
            ctc = squeeze(obj.ctcSet(xCoord, yCoord, :));
        end% getCtc
        
        %time
        function tAcq = getTAcq(obj)
            tAcq = obj.tAcq;
        end%getTAcq
        
        % curves set
        function nomrAifCtc = getNormAifCtc(obj)
            nomrAifCtc = obj.normAifCtc;
        end%getNormAifCtc
        
        function nCtcSet = getnCtcSet(obj)
            nCtcSet = obj.nCtcSet;
        end%getnCtcSet
        
        %noised ctc
        function nCtc= getnCtc(obj, xCoord, yCoord)
            nCtc = squeeze(obj.nCtcSet(xCoord, yCoord, :));
        end%getnCtc
        
        function residueSet = getResidueSet(obj)
            residueSet = obj.residueSet;
        end%getResidueSet

%% main run
        function obj = runSimulation(obj, opt)
            obj = obj.clearAttributes();
            obj = obj.loadAif(opt);
            
            switch opt.model
                case 'Fermi'
                    obj = obj.runFermi(opt);
                case  'KtransVpeVe'
                    obj = obj.runKtransVpVe(opt);
                case 'FtKpsVpVe'
                    obj = obj.runKpsVpVe(opt);
                case 'Comp2Exchange'
                    obj = obj.runComp2Exchange(opt);
                case 'Comp2Exchange_Fp_PS'
                    obj = obj.Comp2Exchange_Fp_PS(opt);
                otherwise
                    throw(MException('phantomGenrator:runSimulation', sprintf('no model for %s', opt.model)));
            end
            if ~isfield(opt, 'delay');
                opt.delay = 0;
            end
            obj = obj.processDelay(opt.delay);
        end%runSimulation
        
    end%methods (Access = public)

    %% private methods
    methods (Access = private)
        
        % clear model fixed parameters and restults before starting new simulation
        function obj = clearAttributes(obj)
            obj.normAifCtc = '';   obj.normAifCtcInterp = '';
            obj.tAcq = '';   obj.tSim = '';
            obj.mbfMap = '';   obj.mbvMap = '';
            obj.mttMap = '';   obj.ctcSet = '';
            obj.nCtcSet = '';   obj.normAifCtc = '';
            obj.normAifCtc = '';   obj.residueSet = '';
        end %clearAttributes
        
        function obj = loadAif(obj, opt)
            obj.normAifCtc = loadmat(opt.aifPath);
            obj.tAcq = 0 : obj.tempRes : (length(obj.normAifCtc) - 1) * obj.tempRes;
            if isfield(opt, 'oversampleFactor')
                obj.tSim = 0 : (obj.tempRes / opt.oversampleFactor) : obj.tAcq(end);
                obj.normAifCtcInterp = interp1(obj.tAcq, obj.normAifCtc, obj.tSim, 'linear', 'extrap');
            end
        end % loadAif
        
        
        %% Fermi model
        function obj = runFermi(obj, opt)
            %close all;
            if  (opt.mbfMin > opt.mbfMax) || (opt.mbvMin > opt.mbvMax)
                throw(MException('cartesianPhantom:argError', 'minimums shall be lower than maximums'))
            end
            opt.bvDirection = 'diagonal';
            switch opt.shape
                case 'square'
                    mask = ones(opt.sideLength * opt.patchWidth);
                    obj.mbfMap = generateBFMap(opt.mbfMin, opt.mbfMax, opt.sideLength, opt.patchWidth);
                    obj.mbvMap = generateBVMap(opt.mbvMin, opt.mbvMax, opt.sideLength, opt.patchWidth, opt.bvDirection);
                    obj.mttMap = zeros(opt.sideLength, opt.sideLength);
                    
                case 'myocardium'
                    obj.mbfMap = loadmat(opt.mbfMapPath) / 60;
                    obj.mbvMap = loadmat(opt.mbvMapPath);
                    
                    mask = obj.mbfMap; mask(mask > 0) = 1;
                    blobMeasurements = regionprops(mask, 'BoundingBox');
                    bBox = floor(blobMeasurements.BoundingBox);
                    %square bBox;
                    if bBox(4) > bBox(3)
                        bBox(3) = bBox(4);
                    else
                        bBox(4) = bBox(3);
                    end
                    opt.sideLength =   bBox(4);
                    
                    mask = mask(bBox(2):bBox(2) + bBox(4), bBox(1):bBox(1) + bBox(3));
                    obj.mbfMap = obj.mbfMap(bBox(2):bBox(2) + bBox(4), bBox(1):bBox(1) + bBox(3));
                    obj.mbvMap = obj.mbvMap(bBox(2):bBox(2) + bBox(4), bBox(1):bBox(1) + bBox(3));
                    
                    % set mbv in accordance with physilogical values
                    bvMin =  min(obj.mbvMap(obj.mbvMap(:)>0)); bvMax = max(obj.mbvMap(obj.mbvMap(:)>0));
                    obj.mbvMap = (obj.mbvMap - bvMin) / (bvMax - bvMin);
                    obj.mbvMap = (obj.mbvMap * (opt.mbvMax - opt.mbvMin)) + opt.mbvMin;
            end%switch
            
            
            obj.ctcSet = zeros(opt.sideLength, opt.sideLength, length(obj.tAcq));
            obj.nCtcSet = zeros(opt.sideLength, opt.sideLength, length(obj.tAcq));
            obj.residueSet = zeros(opt.sideLength, opt.sideLength, length(obj.tAcq));
            for l = 1 : opt.patchWidth : opt.sideLength * opt.patchWidth %
                for j = 1 : opt.patchWidth : opt.sideLength * opt.patchWidth %
                    if mask(l, j)
                        [KineticTissue, res] = convFermi([obj.mbfMap(l, j), obj.mbvMap(l, j), opt.t0 , opt.td],...
                            obj.tSim, obj.normAifCtcInterp);
                        KineticTissue = interp1(obj.tSim, KineticTissue, obj.tAcq);
                        for ll = 0 : opt.patchWidth - 1
                            for jj = 0 : opt.patchWidth - 1
                                obj.ctcSet(l + ll, j + jj, 1 : length(KineticTissue)) = KineticTissue';
                                tmp = normrnd(KineticTissue', opt.sigma); % test variabilité ok
                                obj.nCtcSet(l + ll, j + jj, 1 : length(KineticTissue)) = tmp;
                                obj.residueSet(l + ll, j + jj, : ) = interp1(obj.tSim, res, obj.tAcq) * obj.mbfMap(l, j); 
                            end
                        end
                    end
                end
            end%for l = 1 : opt.patchWidth : opt.sideLength * opt.patchWidth
            
            obj.mttMap = obj.mbvMap ./ obj.mbfMap;
        end%runFermi
        %% Ktrans
        
        %% Ft Kps Vp Ve model
        function obj = runKpsVpVe(obj, opt)
            
            switch opt.shape
                case 'square'
                    mask = ones(opt.sideLength * opt.patchWidth);
                    obj.ftMap = generateBFMap(opt.FtMin, opt.FtMax, opt.sideLength, opt.patchWidth);
                    obj.vpMap = generateBVMap(opt.VpMin, opt.VpMax, opt.sideLength, opt.patchWidth, 'diagonal');
                case 'myocardium'
                    obj.ftMap = loadmat(opt.mbfMapPath) / 60;
                    obj.vpMap = loadmat(opt.mbvMapPath);
                    
                    mask = obj.ftMap; mask(mask > 0) = 1;
                    blobMeasurements = regionprops(mask, 'BoundingBox');
                    bBox = floor(blobMeasurements.BoundingBox);
                    %square bBox;
                    if bBox(4) > bBox(3)
                        bBox(3) = bBox(4);
                    else
                        bBox(4) = bBox(3);
                    end
                    opt.sideLength =   bBox(4) + 1;
                    
                    mask = mask(bBox(2):bBox(2) + bBox(4), bBox(1):bBox(1) + bBox(3));
                    obj.ftMap = obj.ftMap(bBox(2):bBox(2) + bBox(4), bBox(1):bBox(1) + bBox(3));
                    obj.vpMap = obj.vpMap(bBox(2):bBox(2) + bBox(4), bBox(1):bBox(1) + bBox(3));
                    
                    % set mbv in accordance with physilogical values
                    vpMin =  min(obj.vpMap(obj.vpMap(:)>0)); vpMax = max(obj.vpMap(obj.vpMap(:)>0));
                    obj.vpMap = (obj.vpMap - vpMin) / (vpMax - vpMin);
                    obj.vpMap = (obj.vpMap * (opt.VpMax - opt.VpMin)) + opt.VpMin;
            end
            sideLen = opt.sideLength * opt.patchWidth;
            
            obj.ctcSet = zeros(sideLen, sideLen, length(obj.tAcq));
            obj.nCtcSet = zeros(sideLen, sideLen, length(obj.tAcq));
            obj.residueSet = zeros(opt.sideLength, opt.sideLength, length(obj.tAcq));
            
            for k = 1 : opt.patchWidth : opt.sideLength * opt.patchWidth %
                for l = 1 : opt.patchWidth : opt.sideLength * opt.patchWidth
                    if mask(k, l)
                        %             Ft              Kps  ,     Vp,           ve
                        Params0 = [obj.ftMap(k, l), opt.Kps, obj.vpMap(k, l), opt.Ve];
                        [KineticTissue, ~] = DceTool_Model_FtKpsVpVe_LM(Params0, obj.tAcq, obj.normAifCtc);
%                         KineticTissue = interp1(obj.tSim, KineticTissue, obj.tAcq);
                        for kk = 0 : opt.patchWidth - 1
                            for ll = 0 : opt.patchWidth - 1
                                %                             KineticTissue = normrnd(KineticTissue', opt.sigma);
                                obj.ctcSet(k + kk, l + ll, :) = KineticTissue(:);
                                obj.nCtcSet(k + kk, l + ll , :) = normrnd(KineticTissue(:), opt.sigma);
                                residue = obj.processResidueFunction(KineticTissue);
                                obj.residueSet(k + kk, l + ll, :) = residue;
                                if max(residue(:)) > 1
                                    disp(sprintf('warning: max of residue function is : %f', max(residue(:)) ));
                                end
                            end
                        end
                    end
                end
            end
        end
        
        
        %% Comp2Exchange
        
        function obj = runComp2Exchange(obj, opt)
            
            switch opt.shape
                case 'square'
                    mask = ones(opt.sideLength * opt.patchWidth);
                    obj.ftMap = generateBFMap(opt.FpMin, opt.FpMax, opt.sideLength, opt.patchWidth);
                    obj.vpMap = generateBVMap(opt.VpMin, opt.VpMax, opt.sideLength, opt.patchWidth, 'diagonal');
                case 'myocardium'
                    obj.ftMap = loadmat(opt.mbfMapPath) / 60;
                    obj.vpMap = loadmat(opt.mbvMapPath);
                    
                    mask = obj.ftMap; mask(mask > 0) = 1;
                    blobMeasurements = regionprops(mask, 'BoundingBox');
                    bBox = floor(blobMeasurements.BoundingBox);
                    %square bBox;
                    if bBox(4) > bBox(3)
                        bBox(3) = bBox(4);
                    else
                        bBox(4) = bBox(3);
                    end
                    opt.sideLength =   bBox(4) + 1;
                    
                    mask = mask(bBox(2):bBox(2) + bBox(4), bBox(1):bBox(1) + bBox(3));
                    obj.ftMap = obj.ftMap(bBox(2):bBox(2) + bBox(4), bBox(1):bBox(1) + bBox(3));
                    obj.vpMap = obj.vpMap(bBox(2):bBox(2) + bBox(4), bBox(1):bBox(1) + bBox(3));
                    
                    % set mbv in accordance with physilogical values
                    vpMin =  min(obj.vpMap(obj.vpMap(:)>0)); vpMax = max(obj.vpMap(obj.vpMap(:)>0));
                    obj.vpMap = (obj.vpMap - vpMin) / (vpMax - vpMin);
                    obj.vpMap = (obj.vpMap * (opt.VpMax - opt.VpMin)) + opt.VpMin;
            end%switch
            
            sideLen = opt.sideLength * opt.patchWidth;
            obj.ctcSet = zeros(sideLen, sideLen, length(obj.tAcq));
            obj.nCtcSet = zeros(sideLen, sideLen, length(obj.tAcq));
            obj.residueSet = zeros(opt.sideLength, opt.sideLength, length(obj.tAcq));
            
            
            obj.aif2textFile(obj.normAifCtc, obj.tAcq , 'C:\Users\daviller\Downloads\JSim_win32\data\aifSimu.tac');
            
            for k = 1 : opt.patchWidth : opt.sideLength * opt.patchWidth %
                for l = 1 : opt.patchWidth : opt.sideLength * opt.patchWidth
                    if mask(k, l)
                        params.Fp = 60 * obj.ftMap(k, l); params.PS = 60 * opt.PS;
                        params.vp = obj.vpMap(k, l); params.ve = opt.Ve;
                        [KineticTissue, residue] = TwoCXM(obj.normAifCtc, obj.tAcq, params, false);
                        for kk = 0 : opt.patchWidth - 1
                            for ll = 0 : opt.patchWidth - 1
                                %                             KineticTissue = normrnd(KineticTissue', opt.sigma);
                                obj.ctcSet(k + kk, l + ll, :) = KineticTissue(:);
                                obj.nCtcSet(k + kk, l + ll , :) = normrnd(KineticTissue(:), opt.sigma);
                                
                                obj.residueSet(k + kk, l + ll, :) = residue;
                                if max(residue(:)) > 1
                                    disp(sprintf('warning: max of residue function is : %f', max(residue(:)) ));
                                end
                            end
                        end
                    end
                end
            end
            
            %calculate extraction efficiency
%             E = 1 - exp(-params.PS ./ (60 * obj.ftMap));
%             obj.mbfMap = obj.ftMap .* E;
%             
        end%Comp2Exchange
      
        %% Comp2Exchange with Fp and PS as variables
        function obj = Comp2Exchange_Fp_PS(obj, opt)
            
            switch opt.shape
                case 'square'
                    mask = ones(opt.sideLength * opt.patchWidth);
                    obj.ftMap = generateBFMap(opt.FpMin, opt.FpMax, opt.sideLength, opt.patchWidth);
                    obj.psMap = generateBVMap(opt.PSMin, opt.PSMax, opt.sideLength, opt.patchWidth, 'diagonal');
                case 'myocardium'
                    fprintf('to be done');
                    return;
            end%switch
            
            sideLen = opt.sideLength * opt.patchWidth;
            obj.ctcSet = zeros(sideLen, sideLen, length(obj.tAcq));
            obj.nCtcSet = zeros(sideLen, sideLen, length(obj.tAcq));
            obj.residueSet = zeros(opt.sideLength, opt.sideLength, length(obj.tAcq));
            
            
            obj.aif2textFile(obj.normAifCtc, obj.tAcq , 'C:\Users\daviller\Downloads\JSim_win32\data\aifSimu.tac');
            
            for k = 1 : opt.patchWidth : opt.sideLength * opt.patchWidth %
                for l = 1 : opt.patchWidth : opt.sideLength * opt.patchWidth
                    if mask(k, l)
                        params.Fp = obj.ftMap(k, l); params.PS = obj.psMap(k, l);
                        params.vp = opt.Vp; params.ve = opt.Ve;
                        [KineticTissue, residue] = TwoCXM(obj.normAifCtc, obj.tAcq, params, false, true);
                        for kk = 0 : opt.patchWidth - 1
                            for ll = 0 : opt.patchWidth - 1
                                %                             KineticTissue = normrnd(KineticTissue', opt.sigma);
                                obj.ctcSet(k + kk, l + ll, :) = KineticTissue(:);
                                obj.nCtcSet(k + kk, l + ll , :) = normrnd(KineticTissue(:), opt.sigma);
                                
                                obj.residueSet(k + kk, l + ll, :) = residue;
                                if max(residue(:)) > 1
                                    disp(sprintf('warning: max of residue function is : %f', max(residue(:)) ));
                                end
                            end
                        end
                    end
                end
            end
            
            %calculate extraction efficiency
            %             E = 1 - exp(-params.PS ./ (60 * obj.ftMap));
            %             obj.mbfMap = obj.ftMap .* E;
            %
        end%Comp2Exchange
        
        
        %% residue function
        
        function residue = processResidueFunction(obj, ctc)
            oversampleFact = 5;
            ltSim = obj.tAcq(1) : (obj.tempRes / oversampleFact) : obj.tAcq(end);
            TRSim = (obj.tAcq(2) - obj.tAcq(1)) / oversampleFact;
            %             is_on_time = ismember(tSim, obj.tAcq);
            is_on_time=zeros(1, length(ltSim));
            for k = 1 : length(obj.tAcq)
                is_on_time((k - 1) * oversampleFact + 1) = 1;
            end
            aifSim = interp1(obj.tAcq, obj.normAifCtc, ltSim, 'linear', 'extrap');
            ctcSim = interp1(obj.tAcq, ctc, ltSim, 'linear', 'extrap');
            
            A = tril(toeplitz(aifSim));
            Ainv = invSvd(A);
            %             Ainv = Ainv(is_on_time, :)
            residueSim = Ainv * ctcSim';
            residue = residueSim(find(is_on_time));
            
            %             debug
            %             ctc2 = interp1(ltSim, A*residueSim, obj.tAcq, 'linear', 'extrap');
            %             figure; plot(ctc); hold all; plot(ctc2, '*'); legend('phantom ctc', 'reconstructed ctc');
            %             end of debug
        end
        
        
        function obj = aif2textFile(obj, aif, timeVect, filePath)
            fd = fopen(filePath, 'w');
            for k = 1 : length(aif)
                fprintf(fd, '%.1f\t%f\n', timeVect(k), aif(k));
            end
            fclose(fd);
        end
%% delay

        function obj = processDelay(obj, delay)
            obj.ctcSet =  cat(3,  obj.ctcSet(:, :, 1 : delay),  obj.ctcSet(:, :, 1 : end - delay));
            obj.nCtcSet = cat(3,  obj.nCtcSet(:, :, 1 : delay), obj.nCtcSet(:, :, 1 : end - delay));
        end
        
    end%methods (Access = private)
    
end

