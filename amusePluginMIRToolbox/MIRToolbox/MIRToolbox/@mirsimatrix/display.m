function display(m,ax,tracks)
% DISSIMATRIX/DISPLAY display of a dissimilarity matrix
disp(' ');
d = get(m,'Data');
nam = get(m,'Name');
fp = get(m,'FramePos');
cha = get(m,'Channels');
t = get(m,'Title');
tp = get(m,'TrackPos');
tv = get(m,'TrackVal');
pp = get(m,'PeakPos');
g = get(m,'Graph');
b = get(m,'Branch');
wr = get(m,'Warp');
if isnan(get(m,'DiagWidth'))    % Similarity matrix between 2 files
    figure
    fp1 = cell2mat(fp{1});
    fp2 = cell2mat(fp{2});
    fp1 = (fp1(1,:,:,:)+fp1(2,:,:,:))/2;
    fp2 = (fp2(1,:,:,:)+fp2(2,:,:,:))/2;
    imagesc(fp2,fp1,d{1}{1});
    if not(isempty(wr))
        hold on
        paths = wr{1};
        bests = wr{2};
        bestsindex = wr{3};
        [i j] = find(bests);
        for k = 1:length(i)
            best = bests(i(k),j(k));
            bestindex = bestsindex(i(k),j(k));
            path = paths{real(best)+1,imag(best)+1}{bestindex};
            score = 0;
            for l = 1:size(path,2)-1
                if path(1,l+1)-path(1,l) == 1 && ...
                        path(2,l+1)-path(2,l) == 1
                    score = score+1;
                end
            end
            if score > 25
                for m = 1:size(path,2)
                    plot(fp2(path(2,m)),fp1(path(1,m)),...
                        'k+','LineWidth',2)
                end
                %i(k),j(k)
                %best
                %path(:,[1 end])
                %pause
                %for m = 1:size(path,2)
                %    plot(fp2(path(2,m)),fp1(path(1,m)),...
                %        'w+','LineWidth',2)
                %end
            end
        end
    end
    set(gca,'YDir','normal')
    title(t)
    xlabel('temporal location of frame centers (in s.)')
    ylabel('temporal location of frame centers (in s.)')
    fig = get(0,'CurrentFigure');
    disp(['The ',t,' between files ',nam{1},' and ',nam{2},...
        ' is displayed in Figure ',num2str(fig),'.']);
else
    if nargin<3 || isempty(tracks)
        tracks=1:length(d);
    end
    
    for track = 1:length(tracks)  %For each audio file
        i=tracks(track);
        
        if nargin<2 || isempty(ax)
            figure
        else
            axes(ax)
        end
        
        if iscell(d{i})
            d{i} = d{i}{1};
        end
        l = size(d{1},3);     % Number of channels
        il = (1-0.15)/l;
        for k = 1:l         % For each channel
            if l>1
                subplot('Position',[0.1 (k-1)*il+0.1 0.89 il-0.02])
            end
            fpi = cell2mat(fp{i});
            if size(fpi,1) == 2
                fpi = (fpi(1,:,:,:)+fpi(2,:,:,:))/2;
            end
            if strcmp(m.view,'l')
                h = imagesc(fpi,fpi(1:size(d{i},1))-fpi(1),d{i}(:,:,k));
            else
                h = imagesc(fpi,fpi,d{i}(:,:,k));
            end
            if not(isempty(g))
                hold on
                pi = cell(1,size(g{i}{1},2));
                for j = 1:size(g{i}{1},2)
                    pi{j} = sort(pp{i}{1}{j});
                end
                for j = 1:size(g{i}{1},2)
                    for h = 1:length(g{i}{1}{1,j,l})
                        next = g{i}{1}{1,j,l}{h};
                        if length(next)>1
                            for n = 1:size(next,1)
                                plot([fpi(j) fpi(next(n,1))],...
                                    [fpi(pi{j}(h)) - fpi(1), ...
                                    fpi(pi{next(n,1)}(next(n,2))) - fpi(1)],...
                                    'k','LineWidth',1)
                                %plot([fpi(j) fpi(next(n,1))],...
                                %     [fpi(pi{j}(h)) - fpi(1), ...
                                %      fpi(pi{next(n,1)}(next(n,2))) - fpi(1)],...
                                %     'w+','MarkerSize',10)
                                plot([fpi(j) fpi(next(n,1))],...
                                    [fpi(pi{j}(h)) - fpi(1), ...
                                    fpi(pi{next(n,1)}(next(n,2))) - fpi(1)],...
                                    'kx','MarkerSize',10)
                            end
                        end
                    end
                end
                bi = b{i}{1}{1};
                for j = 1:size(bi,1)-1
                    plot([fpi(bi(j,1)) fpi(bi(j+1,1))],...
                        [fpi(pi{bi(j,1)}(bi(j,2))) - fpi(1), ...
                        fpi(pi{bi(j+1,1)}(bi(j+1,2))) - fpi(1)],...
                        'w','LineWidth',1.5)
                    plot([fpi(bi(j,1)) fpi(bi(j+1,1))],...
                        [fpi(pi{bi(j,1)}(bi(j,2))) - fpi(1), ...
                        fpi(pi{bi(j+1,1)}(bi(j+1,2))) - fpi(1)],...
                        'w+','MarkerSize',15)
                    plot([fpi(bi(j,1)) fpi(bi(j+1,1))],...
                        [fpi(pi{bi(j,1)}(bi(j,2))) - fpi(1), ...
                        fpi(pi{bi(j+1,1)}(bi(j+1,2))) - fpi(1)],...
                        'kx','MarkerSize',15)
                end
            elseif not(isempty(tp)) && not(isempty(tp{i}))
                hold on
                for k = 1:size(tp{i}{1}{1},1)
                    prej = 0;
                    for j = 1:size(tp{i}{1}{1},2)
                        if tv{i}{1}{1}(k,j)
                            if prej% && not(isempty(tp(k,j)))
                                plot([fpi(prej) fpi(j)],...
                                    [fpi(tp{i}{1}{1}(k,prej)) - fpi(1) ...
                                    fpi(tp{i}{1}{1}(k,j)) - fpi(1)],...
                                    'k','LineWidth',1)
                                plot([fpi(prej) fpi(j)],...
                                    [fpi(tp{i}{1}{1}(k,prej)) - fpi(1) ...
                                    fpi(tp{i}{1}{1}(k,j)) - fpi(1)],...
                                    'w+','MarkerSize',10)
                                plot([fpi(prej) fpi(j)],...
                                    [fpi(tp{i}{1}{1}(k,prej)) - fpi(1) ...
                                    fpi(tp{i}{1}{1}(k,j)) - fpi(1)],...
                                    'kx','MarkerSize',10)
                            end
                            prej = j;
                        end
                    end
                end
            elseif not(isempty(pp)) && not(isempty(pp{i}))
                hold on
                for k = 1:length(pp{i}{1})
                    for j = 1:length(pp{i}{1}{k})
                        plot(fpi(k),fpi(pp{i}{1}{k}(j)) - fpi(1), ...
                            'w+','MarkerSize',10)
                    end
                end
            end
            set(gca,'YDir','normal')
            if k == l
                title(t)
            end
            if k == 1
                xlabel('temporal location of frame centers (in s.)')
            end
            if k == ceil(l/2)
                if strcmp(m.view,'h')
                    ylabel('relative distance between compared frames (in s.)')
                elseif strcmp(m.view,'l')
                    ylabel('temporal lag (in s.)')
                else
                    ylabel('temporal location of frame centers (in s.)')
                end
            end
            if l > 1
                pos = get(gca,'Position');
                hfig = axes('Position',[pos(1)-.05 pos(2)+pos(4)/2 .01 .01],...
                    'Visible','off');
                text(0,0,num2str(cha{i}(k)),'FontSize',12,'Color','r')
            end
        end
        fig = get(0,'CurrentFigure');
        disp(['The ',t,' related to file ',nam{i},' is displayed in Figure ',num2str(fig),'.']);
    end
end
disp(' ');
drawnow