classdef bootstrapTool
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        mode; % bootstrap mode to use
        ctcSet; % curves ctcSet
        fitCtcSet;
        nbRepetitions;% number of versions
        aif;
        mask;
        nonZeroCurPos; %position of curves to deconvolve
    end
    
    methods (Access = public)
        function obj = bootstrapTool(mode, ctcSet, fitCtcSet, mask, aif, nbRepetitions)
            obj.mode = mode;
            obj.ctcSet = ctcSet;
            obj.fitCtcSet = fitCtcSet;
            obj.mask = mask;
            obj.nbRepetitions = nbRepetitions;
            obj.aif = aif;
            %reshape
            obj.nonZeroCurPos = find(reshape(mask, 1, numel(mask)));
        end %bootstrapTool
        
        function bsCtc = run(obj)
            switch obj.mode
                case 'rNoise'
                    bsCtc = obj.generateRdmCurvesFromBaselineNoiseFeatures();
                case 'residual'
                    bsCtc = obj.generateRdmCurvesFromResidualBootstrap();
                case 'wild'
                    if 3 == ndims(obj.ctcSet)
                        bsCtc = obj.generateRdmCurves3DSetFromWildBootstrap();
                    elseif 2 == ndims(obj.ctcSet)
                        bsCtc = obj.generateRdmCurves2DSetFromWildBootstrap();
                    end
            end%switch
        end%run
    end%methods (Access = public)
    
    methods (Access = protected)
        function bsCtc = generateRdmCurvesFromBaselineNoiseFeatures(obj)
            disp('to be done'); bsCtc = 0;
            %             rCexp = [];
            %             for k = 1 : obj.nbRepetitions
            %                 %noise curces
            %                 tmp = zeros(nbAcq, length(obj.nonZeroCurPos));
            %                 for l = 1 : length(obj.nonZeroCurPos)
            %                     tmp(:, l) = normrnd(cexp(:, obj.nonZeroCurPos(l)), obj.blSigmaMap(obj.nonZeroCurPos(l)));
            %                 end
            %                 rCexp = [rCexp tmp];
            %             end
        end%generateRdmCurvesFromBaselineNoiseFeatures
        
        function bsCtc = generateRdmCurvesFromResidualBootstrap(obj)
            [H, W, T] = size(obj.ctcSet);
            nbCtc = length(obj.nonZeroCurPos);
            bsCtc = zeros(T, obj.nbRepetitions * nbCtc);
            [xCoor, yCoor] = ind2sub([H, W], obj.nonZeroCurPos);
            for l = 1 : nbCtc
                residueCtc = squeeze(obj.ctcSet(xCoor(l), yCoor(l), :) - obj.fitCtcSet(xCoor(l), yCoor(l), :));
                for k = 1 : obj.nbRepetitions
                    bsResidueCtc = datasample(residueCtc, T);
                    bsCtc(:, nbCtc * (k - 1) + l) = ...
                        squeeze(obj.fitCtcSet(xCoor(l), yCoor(l), :)) + ...
                        bsResidueCtc;
                end
            end
        end%generateRdmCurvesFromResidualBootstrap
        
        function bsCtc = generateRdmCurves3DSetFromWildBootstrap(obj)
            %F. Calamante, Perfusion Precision in Bolus-Tracking MRI: Estimation Using the Wild-Bootstrap Method
            [H, W, T] = size(obj.ctcSet);
            nbCtc = length(obj.nonZeroCurPos);
            bsCtc = zeros(T, obj.nbRepetitions * nbCtc);
            [xCoor, yCoor] = ind2sub([H, W], obj.nonZeroCurPos);
            a = obj.generateHccme();
            for l = 1 : nbCtc
                residueCtc = squeeze(obj.ctcSet(xCoor(l), yCoor(l), :) - obj.fitCtcSet(xCoor(l), yCoor(l), :))';
                % heteroscedasticity consistent covariance matrix estimator
                % (HCCME)
                for k = 1 : obj.nbRepetitions
                    %Rademacher distribution
                    epsilon = (rand(1, T) < .5) * 2 - 1;
                    bsResidueCtc = (a .* epsilon .* residueCtc)';
                    bsCtc(:, nbCtc * (k - 1) + l) = ...
                        squeeze(obj.fitCtcSet(xCoor(l), yCoor(l), :)) + ...
                        bsResidueCtc;
                end
            end
        end%generateRdmCurves3DSetFromWildBootstrap
        
        function bsCtc = generateRdmCurves2DSetFromWildBootstrap(obj)
            [T, H] = size(obj.ctcSet);
            nbCtc = H;
            bsCtc = zeros(T, obj.nbRepetitions * nbCtc);
            a = obj.generateHccme();
            for l = 1 : nbCtc
                residueCtc = (squeeze(obj.ctcSet(:, l) - obj.fitCtcSet(:, l)))';
                % heteroscedasticity consistent covariance matrix estimator
                % (HCCME)
                for k = 1 : obj.nbRepetitions
                    %Rademacher distribution
                    epsilon = (rand(1, T) < .5) * 2 - 1;
                    bsResidueCtc = (a .* epsilon .* residueCtc)';
                    bsCtc(:, nbCtc * (k - 1) + l) = ...
                        squeeze(obj.fitCtcSet(:, l)) + ...
                        bsResidueCtc;
                end
            end
        end%generateRdmCurves2DSetFromWildBootstrap
        
        function hccmeVect = generateHccme(obj)
            %generate heteroscedasticity consistent covariance matrix estimator
            A = tril(toeplitz(obj.aif(1:size(obj.ctcSet, 1))));
            H = A * invSvd(A' * A) * A';
            for k = 1 : size(H)
                hccmeVect(k) = 1 / sqrt(1 - H(k, k));
            end
        end%generateHccme
    end%methods (Access = public)
    
end

