function [labelsMask, labelsMaskStack] = manualSegmentation(slcSerie, serieName)

    if ~nargin
        manualSegmentationUI();
        return;
    end

    [H, W, nbImages] = size(slcSerie);
    labelsMask = zeros(H, W);
    slcPos = 20;
    nbRegions = 0;
    
    fm = figureMgr.getInstance();
    figHdle = fm.newFig(serieName); subplot(1, 2, 1); colormap gray;
    ha = tight_subplot(1,2,[.05 .03],[.15 .01],[.01 .01]);
    axes(ha(1));
    imgHdle = imagesc(slcSerie(:, :, slcPos)); axis off; axis image;
    dispSlicePos();
    set(imgHdle,'ButtonDownFcn', @createRoiCb);
    set(figHdle,'WindowScrollWheelFcn', @OnScrollCb);
    
    
    %go button
    uicontrol('Style', 'pushbutton',...
        'Units',  'normalized',...
        'Position', [0.1 0.05 0.1 0.1],...
        'String', '+',...
        'Callback', @addRoi);
    %OK button
    uicontrol('Style', 'pushbutton',...
        'Units',  'normalized',...
        'Position', [0.5 0.05 0.1 0.1],...
        'String', 'OK',...
        'Callback', @closeFig);
    
    %colormap button
    cmBnHdle = uicontrol('Style', 'checkbox',...
        'Units',  'normalized', 'Position', [0.25 0.05 0.2 0.1], ...
        'String',   'colormap', 'Value',    0, 'Callback', @setColormap);
    
    waitfor(figHdle);
    
    
    %% Callback function
    function addRoi(~,~)
        nbRegions = nbRegions + 1;
        fm.newFig('roi draw');
        minVal = min(min(slcSerie(:, :, slcPos)));
        maxVal = max(max(slcSerie(:, :, slcPos)));
        
        img = (slcSerie(:, :, slcPos) + abs(minVal)) / maxVal - minVal;
        mask = roipoly(img);
        fm.closeFig('roi draw');
        labelsMask = mask .* nbRegions + labelsMask;
        axes(ha(2)); 
        img = overlay(img, labelsMask);
        imagesc(img); axis off; axis image
        setColormap();
    end

    function OnScrollCb(~, arg)
        slcPos = floor(slcPos + arg.VerticalScrollCount);
        if slcPos < 1
            slcPos = 1;
        end
        if slcPos > size(slcSerie, 3)
            slcPos = size(slcSerie, 3);
        end
        xlim = get(ha(1), 'XLim');
        ylim = get(ha(1), 'YLim');
        axes(ha(1));
        imagesc(slcSerie(:, :, slcPos)); axis off; axis image;
        setColormap();
        dispSlicePos();
        set(ha(1), 'XLim', xlim);
        set(ha(1), 'YLim', ylim);
        %title (get(editInputDcm, 'String'));
    end

    function closeFig(~, ~)
        close(figHdle);
    end%closeFig

    function setColormap(~, ~)
        if ~get(cmBnHdle, 'Value')
            axes(ha(1)); colormap gray;
        else
            axes(ha(1)); colormap jet;
        end
    end%setColormap

     function dispSlicePos()
         txtPos = [0.85, 0.05];
         text('units','normalized','position', txtPos,'fontsize', 10, 'color', 'white', 'string', sprintf('%d/%d', slcPos, size(slcSerie, 3)))
     end%dispSlicePos

end%manualSegmentation