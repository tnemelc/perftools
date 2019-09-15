% selectPeakImage.m
% brief:
%
%
% references:
%
%
% input:
% arg1: ...
% arg2: ...
% output:
%
% arg3: ...
% arg4: ...
%
%
% keywords:
% author: C.Daviller
% date: 03-Jan-2018


function slcPos = selectPeakImage(imgSerie)
if ~nargin
    selectPeakImageUI();
    return;
end

    [H, W, T] = size(imgSerie);
    slcPos = 29;
    histOpt.brightness = 0;
    histOpt.contrast = 1;

    f = figureMgr.getInstance().newFig('selectPeakImage');
    imagesc(imgSerie(:,:,slcPos)); colormap gray; axis off image;
    set(f, 'toolbar', 'figure' )
    set(f, 'WindowScrollWheelFcn', @OnScrollCb);
    set(f, 'KeyPressFcn', @onKeyPressCb);

    uicontrol('Style', 'pushbutton',...
        'units',  'normalized',...
        'Position', [0.05 0.1 0.1 0.05],...
        'String', 'OK',...
        'Callback',  {@closeFigCb, f});

    waitfor(f);
    figureMgr.getInstance().closeFig('Curves');


    function OnScrollCb(~, arg)
        slcPos = floor(slcPos + arg.VerticalScrollCount);
        if slcPos < 1
            slcPos = 1;
        end
        if slcPos > size(imgSerie, 3)
            slcPos = size(imgSerie, 3);
        end
        xlim = get(gca, 'XLim');
        ylim = get(gca, 'YLim');
        
        imagesc(correctImage(imgSerie(:, :, slcPos))); axis off; axis image;
        dispSlicePos();
    end%OnScrollCb

    function onKeyPressCb(~, arg)
        switch arg.Key
            case 'uparrow'
                histOpt.brightness = histOpt.brightness + 1;
            case 'downarrow'
                histOpt.brightness = histOpt.brightness - 1;
            case 'leftarrow'
                histOpt.contrast = histOpt.contrast - 0.2;
            case 'rightarrow'
                histOpt.contrast = histOpt.contrast + 0.2;
        end%switch
        imHdle = imagesc(correctImage(imgSerie(:, :, slcPos))); axis off; axis image;
        dispSlicePos();
    end%onKeyPressCb

    function corrIm = correctImage(image)
        maxValue = max(image(:));
        lut(1, :) = (0 : maxValue);
        tmp = histOpt.contrast .*  lut(1, :) + histOpt.brightness;
        tmp(tmp < 0) = 0; tmp(tmp > maxValue) = maxValue;
        lut(2, :) = tmp;
        
        for k = 1 : numel(image)
            corrIm(k) = lut(2, lut(1,:) == floor(image(k)));
        end
        corrIm = reshape(corrIm, size(image));
    end%correctImage

    function dispSlicePos()
        txtPos = [0.35, 0.05];
        text('units','normalized','position', txtPos,'fontsize', 10,...
            'color', 'white', 'string', ...
            sprintf('%d/%d', slcPos, size(imgSerie, 3)))
    end%dispSlicePos

    function closeFigCb(~, ~, f)
        close(f);
    end%closeFigCb
end