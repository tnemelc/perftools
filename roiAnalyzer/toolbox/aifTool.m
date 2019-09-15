classdef aifTool < baseTool
    % aifTool
    % tool that loads aif data and processes tic features
    %   -PeakVal
    %   -FootPos
    %   -peakPos
    %   -peakDate
    %   -firstPassEndPos position of the last acquisition of the first pass
    %       defined as the lowest aif point after first pass peak
    %   -footDate
    %   -firstPassEndDate
    
    properties
        tic;
        ctc;
        ctcFit;
        mask;
        timeVect;
        features;
    end%properties
    
    methods (Access = public)
        %%
        function obj = run(obj, ~)
            obj = obj.loadAif();
            obj = obj.processAifTicFeatures();
        end%run
        %%
        function obj = loadAif(obj)
            obj.tic = loadmat(fullfile(obj.dataPath, 'aif.mat'));
            obj.ctc = loadmat(fullfile(obj.dataPath, 'aifCtc.mat'));
            obj.ctcFit = loadmat(fullfile(obj.dataPath, 'aifCtcFit.mat'));
            obj.timeVect = loadmat(fullfile(obj.dataPath, 'tAcq.mat'));
            obj.mask = loadmat(fullfile(obj.dataPath, 'aifMask.mat'));
        end%loadAif  
        %%
        function plotTic(obj)
            plot(obj.timeVect, obj.tic); hold all;
            plot(obj.features.footDate, obj.tic(obj.features.footPos), 'o');
            plot(obj.features.peakDate, obj.tic(obj.features.peakPos), 'o');
            plot(obj.features.firstPassEndDate, obj.tic(obj.features.firstPassEndPos), 'o');
            xlabel('time (s)');
            ylabel('signal (A.U)');
            legend('aif signal', 'foot', 'peak', 'first pass end');
        end
        %%
        function plotCtc(obj)
            plot(obj.timeVect, obj.ctc); hold all;
            plot(obj.timeVect, obj.ctcFit);
            plot(obj.features.footDate, obj.ctc(obj.features.footPos));
            plot(obj.features.peakDate, obj.ctc(obj.features.peakPos));
            plot(obj.features.firstPassEndDate, obj.ctc(obj.features.firstPassEndPos));
            xlabel('time (s)');
            ylabel('[CA]');
            legend('aif ctc', 'foot', 'peak', 'first pass end');
        end
        %% getters
        %%
        function [tic, tAcq] = getTic(obj)
            tic = obj.tic;
            tAcq = obj.timeVect;
        end
        
        %%
        function ctc = getCtc(obj)
            ctc = obj.ctc;
        end
        
        %%
        function feat = getFeature(obj, featName)
            feat = obj.features.(featName);
        end%
    end
    
    methods (Access = protected)
        %%
        function obj = processAifTicFeatures(obj)
            obj.features.peakVal = max(obj.tic);
            obj.features.peakPos = find(obj.tic  == max(obj.tic), 1, 'first');
            %aif baseline cannot be lower than 5 RR
            obj.features.footPos = [];
            % pseudo normalize tic while by substracting min aif value found 
            % in the interval [t=0, tpeak], to be sure that a least a value
            % is lower than 5% of the peak
            % 
            minBaselineVal = min(obj.tic(1 : obj.features.peakPos));
            pseudoNormTic = obj.tic - minBaselineVal;
            obj.features.footPos = 5 + find(pseudoNormTic(5 : obj.features.peakPos) < 0.05 * obj.features.peakVal, 1, 'last') - 1;
            
            
            obj.features.firstPassEndPos = obj.features.peakPos + find(obj.tic(obj.features.peakPos : floor(2 * end / 3)) == min(obj.tic(obj.features.peakPos : floor(2 * end / 3))), 1, 'first');
            
            obj.features.peakDate = obj.timeVect(obj.features.peakPos);
            obj.features.footDate = obj.timeVect(obj.features.footPos);
            obj.features.firstPassEndDate = obj.timeVect(obj.features.firstPassEndPos);
        end
    end
end