function hpol = polardb( varargin )

%POLARDB  Polar coordinate plot for logarithmic data.

%   POLARDB(THETA,RHO,LIM,S) uses the linestyle specified in string S.
%   See PLOT for a description of legal linestyles.
%
%   POLARDB(AX,...) plots into AX instead of GCA.
%
%   H = POLARDB(...) returns a handle to the plotted object in H.
%
%   Example:
%      t = 0:.01:2*pi;
%      polardb(t,sin(2*t).*cos(2*t),'--r')
%
%   See also PLOT, LOGLOG, SEMILOGX, SEMILOGY.

theta=varargin{1};
rho=varargin{2};
lim=varargin{3};
line_style=varargin{4};

if ischar(theta) | ischar(rho)
	error('Input arguments must be numeric.');
end
if any(size(theta) ~= size(rho))
	error('THETA and RHO must be the same size.');
end

% adjust rho to minimum
nr = size(rho,2);
tck = -floor(lim/10);
lim = -tck*10;
I=find(rho<lim);
ni=size(I,2);
rho(I)=lim*ones(1,ni);
rho = rho/10+tck*ones(1,nr);

% get hold state
cax = newplot;
next = lower(get(cax,'NextPlot'));
hold_state = ishold;

% get x-axis text color so grid is in same color
tc = get(cax,'xcolor');
ls = get(cax,'gridlinestyle');

% Hold on to current Text defaults, reset them to the
% Axes' font attributes so tick marks use them.
fAngle  = get(cax, 'DefaultTextFontAngle');
fName   = get(cax, 'DefaultTextFontName');
fSize   = get(cax, 'DefaultTextFontSize');
fWeight = get(cax, 'DefaultTextFontWeight');
fUnits  = get(cax, 'DefaultTextUnits');
set(cax, 'DefaultTextFontAngle',  get(cax, 'FontAngle'), ...
	'DefaultTextFontName',   get(cax, 'FontName'), ...
	'DefaultTextFontSize',   get(cax, 'FontSize'), ...
	'DefaultTextFontWeight', get(cax, 'FontWeight'), ...
    'DefaultTextUnits', 'data' )

% only do grids if hold is off
if ~hold_state

% make a radial grid
	hold(cax, 'on');
	hhh=plot([0 max(theta(:))],[0 max(abs(rho(:)))],'parent',cax);
	v = [get(cax,'xlim') get(cax,'ylim')];
	ticks = length(get(cax,'ytick'));
	delete(hhh);
% check radial limits and ticks
	rmin = 0; rmax = v(4); rticks = ticks-1;
	if rticks > 5	% see if we can reduce the number
		if rem(rticks,2) == 0
			rticks = rticks/2;
		elseif rem(rticks,3) == 0
			rticks = rticks/3;
		end
	end

% define a circle
	th = 0:pi/50:2*pi;
	xunit = cos(th);
	yunit = sin(th);
% now really force points on x/y axes to lie on them exactly
    inds = [1:(length(th)-1)/4:length(th)];
    xunits(inds(2:2:4)) = zeros(2,1);
    yunits(inds(1:2:5)) = zeros(3,1);
% plot background if necessary
    if ~ischar(get(cax,'color')),
       patch('xdata',xunit*rmax,'ydata',yunit*rmax, ...
             'edgecolor',tc,'facecolor',get(cax,'color'),...
             'handlevisibility','off','parent',cax);
    end

%	rinc = (rmax-rmin)/rticks;
        rinc = 1;
%	for i=(rmin+rinc):rinc:rmax
	for i=[1:1:tck]
%	for i=rmax:rmax
		plot(xunit*i,yunit*i,'linestyle',ls,'color',tc,'linewidth',1,'parent',cax);
%		text(0,i+rinc/20,['  ' num2str(10*(i-tck))],'verticalalignment','bottom' );
		text((-i+rinc/100),0,['  ' num2str(10*(i-tck))],'verticalalignment','bottom','parent',cax);
	end

% plot spokes
	th = (1:6)*2*pi/12;
	cst = cos(th); snt = sin(th);
	cs = [-cst; cst];
	sn = [-snt; snt];
%	plot(rmax*cs,rmax*sn,'--','color',tc,'linewidth',0.5,'parent',cax);
	plot(rmax*cs,rmax*sn,'linestyle',ls,'color',tc,'linewidth',1,'parent',cax);

% annotate spokes in degrees
	rt = 1.1*rmax;
%	rt = 1.15*rmax;
	for i = 1:max(size(th))
	    text(rt*snt(i),rt*cst(i),int2str(i*30),'horizontalalignment','center','parent',cax);

  		loc = int2str(i*30-180);
%		if i == max(size(th))
%			loc = int2str(0);
% 		end
		text(-rt*snt(i),-rt*cst(i),loc,'horizontalalignment','center','parent',cax);
	end

% set viewto 2-D
	view(cax,2);
% set axis limits
	axis(cax,rmax*[-1 1 -1.15 1.15]);
end

% Reset defaults.
set(cax, 'DefaultTextFontAngle', fAngle , ...
	'DefaultTextFontName',   fName , ...
	'DefaultTextFontSize',   fSize, ...
	'DefaultTextFontWeight', fWeight, ...
    'DefaultTextUnits', fUnits );

% transform data to Cartesian coordinates.
yy = rho.*cos(theta);
xx = rho.*sin(theta);

% plot data on top of grid
if strcmp(line_style,'auto')
	q = plot(xx,yy,'parent',cax);
else
	q = plot(xx,yy,line_style,'parent',cax);
end

%set(q,'LineWidth',1.0);
if nargout > 0
	hpol = q;
end

if ~hold_state
	axis('equal');axis('off');
end

% reset hold state
if ~hold_state
    set(cax,'NextPlot',next);
end
