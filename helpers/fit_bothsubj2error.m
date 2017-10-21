function [estb0,estb1,varargout] = fit_bothsubj2error(x,y,varargin)
% function [estb0,estb1,varargout] = fit_bothsubj2error(x,y,varargin)
% In the limit lambda=infinity, there is no error on the x-values, and this algorithm becomes the standard linear regression.
% I find its calling syntax easier than that of Matlab's regress function.
% Example: 
% x=rand(1,100); y= rand(1,100); lambda = 2;
% [estb0,estb1] = fit_bothsubj2error(x,y)
% [estb0,estb1] = fit_bothsubj2error(x,y,lambda)
% [estb0,estb1,b0CI,b1CI] = fit_bothsubj2error(x,y)
% [estb0,estb1,b0CI,b1CI] = fit_bothsubj2error(x,y,lambda,5000)
% NB:
% [estb0,estb1] = fit_bothsubj2error(x,y,Inf) gives the same answer as Matlab's own b = regress(y',[ones(size(x));x]')
% with a more convenient syntax.
%
% Jenny Read 2/4/2003

if length(x)~=length(y)
ybar = mean(y);
if isinf(lambda)
if nargout==4