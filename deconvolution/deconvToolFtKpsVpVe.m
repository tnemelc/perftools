classdef deconvToolFtKpsVpVe < deconvTool
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    %%
    properties
        kps; %kps: exchange suface constant
        ve; %extraccellular volume
        kpsMap;
        veMap;
        
    end
%%
    methods (Access = public)
        %constructor
        function obj = deconvToolFtKpsVpVe()
            obj.kps = 0.0158; obj.ve = 0.2; %default phantom generation values
            obj.oversampleFact = 1;
            obj.mbfPriorMap = [];
            obj.mbvPriorMap = [];
        end%deconvToolFtKpsVpVe
        function runDeconvolution(obj)
            tic;
            obj.initPriorMaps();
%             fitflag = 'FtVp';
            fitflag = 'FtKpsVpVe';
            wb = waitbar(0, 'processing...'); cpt = 0;
            [H, W, ~] = size(obj.ctcSet);
            
            mbfMap = obj.mbfPriorMap;
            mbvMap = obj.mbfPriorMap;
            kpsMap = obj.mbfPriorMap;
            veMap = obj.mbfPriorMap;
            mbfPriorMap = obj.mbfPriorMap;
            mbvPriorMap = obj.mbvPriorMap;
            ctcSet = obj.ctcSet;
            fitCtcSet = obj.ctcSet;
            normAifCtc = obj.normAifCtc;
            tAcq = obj.tAcq;
            kps = obj.kps; ve = obj.ve;
            
            for mbfIdx = 1 : H
                waitbar(mbfIdx / H, wb, 'processing...');
                parfor mbvIdx = 1 : W
                    if ~obj.deconvMask(mbfIdx, mbvIdx)
                        continue; % if not in the deconvolution mask, just ignore 
                    end
%                    if cpt == 0; msg = 'processing.' ; cpt = cpt + 1;...
%                         elseif cpt == 1; msg = 'processing..' ; cpt = cpt + 1;...
%                         elseif cpt == 2; msg = 'processing...' ; cpt = 0;
%                    end 
                   switch fitflag
                       case 'FtVp'
                       % fit only Ft and Vp
                       p0 = [0.01 0.1];% fit only Ft and Vp
                       [mbfMap(mbfIdx, mbvIdx), mbvMap(mbfIdx, mbvIdx), ...
                           fitCtcSet(mbfIdx, mbvIdx, :)] = fitFtVp(normAifCtc,...
                                    tAcq, squeeze(ctcSet(mbfIdx, mbvIdx, :)),...
                                    p0, kps, ve);
                       case 'FtKpsVpVe'
                       % fit Ft Kps Vp and Ve
                       p0 = [mbfPriorMap(mbfIdx, mbvIdx), 0.01, ...
                           mbvPriorMap(mbfIdx, mbvIdx), 0.05];
                       
                        [mbfMap(mbfIdx, mbvIdx), mbvMap(mbfIdx, mbvIdx), ...
                           fitCtcSet(mbfIdx, mbvIdx, :), ...
                           kpsMap(mbfIdx, mbvIdx), veMap(mbfIdx, mbvIdx)] =...
                           fitFtKpsVpVe(normAifCtc(1:length(tAcq)),...
                                   tAcq, squeeze(ctcSet(mbfIdx, mbvIdx, 1:length(tAcq))),...
                                   p0);
                   end
                end
            end
            
            obj. mbfMap = mbfMap;
            obj.mbvMap = mbvMap;
            obj.fitCtcSet = fitCtcSet;
            obj.kpsMap = kpsMap;
            obj.veMap = veMap;
            obj.mbfPriorMap = []; obj.mbvPriorMap = [];
            close(wb)
            obj.processTime = obj.processTime + toc;
        end%runDeconvolution
        function obj = prepare(obj, normAifCtc, ctcSet, tAcq, opt, mask)
            obj = obj.prepare@deconvTool(normAifCtc, ctcSet, tAcq, opt, mask);
            if isfield(opt, 'kps')
                obj.kps = 0.0158; 
            end
            if isfield(opt, 've')
                obj.ve = 0.2;
            end
        end
        
% getters
        function kpsMap = getKpsMap(obj)
            kpsMap = obj.kpsMap;
        end
        function veMap = getVeMap(obj)
            veMap = obj.veMap;
        end
    end%methods (Access = public)
  %%  
    methods (Access = protected)
        function obj = initPriorMaps(obj)
            if isempty(obj.mbfPriorMap)
                [H, W, ~] = size(obj.ctcSet);
                obj.mbfPriorMap = ones(H, W) .* 0.01 .* obj.deconvMask;
            end
            if isempty(obj.mbvPriorMap)
                [H, W, ~] = size(obj.ctcSet);
                obj.mbvPriorMap = ones(H, W) .* 0.01 .* obj.deconvMask;
            end
        end %initIntermediateMaps

    end%(Access = protected)
    
end

