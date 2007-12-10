/**
 * History/Remote - jQuery plugin for enabling history support and bookmarking
 * @requires jQuery v1.0.3
 *
 * http://stilbuero.de/jquery/history/
 *
 * Copyright (c) 2006 Klaus Hartl (stilbuero.de)
 * Dual licensed under the MIT and GPL licenses:
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.gnu.org/licenses/gpl.html
 *
 * Version: 0.2.3
 */
(function($){$.ajaxHistory=new function(){var RESET_EVENT='historyReset';var _currentHash=location.hash;var _intervalId=null;var _observeHistory;this.update=function(){};var _defaultReset=function(){$('.remote-output').empty();};$(document).bind(RESET_EVENT,_defaultReset);if($.browser.msie){var _historyIframe,initialized=false;$(function(){_historyIframe=$('<iframe style="display: none;"></iframe>').appendTo(document.body).get(0);var iframe=_historyIframe.contentWindow.document;iframe.open();iframe.close();if(_currentHash&&_currentHash!='#'){iframe.location.hash=_currentHash.replace('#','');}});this.update=function(hash){_currentHash=hash;var iframe=_historyIframe.contentWindow.document;iframe.open();iframe.close();iframe.location.hash=hash.replace('#','');};_observeHistory=function(){var iframe=_historyIframe.contentWindow.document;var iframeHash=iframe.location.hash;if(iframeHash!=_currentHash){_currentHash=iframeHash;if(iframeHash&&iframeHash!='#'){$('a[@href$="'+iframeHash+'"]').click();location.hash=iframeHash;}else if(initialized){location.hash='';$(document).trigger(RESET_EVENT);}}initialized=true;};}else if($.browser.mozilla||$.browser.opera){this.update=function(hash){_currentHash=hash;};_observeHistory=function(){if(location.hash){if(_currentHash!=location.hash){_currentHash=location.hash;$('a[@href$="'+_currentHash+'"]').click();}}else if(_currentHash){_currentHash='';$(document).trigger(RESET_EVENT);}};}else if($.browser.safari){var _backStack,_forwardStack,_addHistory;$(function(){_backStack=[];_backStack.length=history.length;_forwardStack=[];});var isFirst=false,initialized=false;_addHistory=function(hash){_backStack.push(hash);_forwardStack.length=0;isFirst=false;};this.update=function(hash){_currentHash=hash;_addHistory(_currentHash);};_observeHistory=function(){var historyDelta=history.length-_backStack.length;if(historyDelta){isFirst=false;if(historyDelta<0){for(var i=0;i<Math.abs(historyDelta);i++)_forwardStack.unshift(_backStack.pop());}else{for(var i=0;i<historyDelta;i++)_backStack.push(_forwardStack.shift());}var cachedHash=_backStack[_backStack.length-1];$('a[@href$="'+cachedHash+'"]').click();_currentHash=location.hash;}else if(_backStack[_backStack.length-1]==undefined&&!isFirst){if(document.URL.indexOf('#')>=0){$('a[@href$="'+'#'+document.URL.split('#')[1]+'"]').click();}else if(initialized){$(document).trigger(RESET_EVENT);}isFirst=true;}initialized=true;};}this.initialize=function(callback){if(typeof callback=='function'){$(document).unbind(RESET_EVENT,_defaultReset).bind(RESET_EVENT,callback);}if(location.hash&&typeof _addHistory=='undefined'){$('a[@href$="'+location.hash+'"]').trigger('click');}if(_observeHistory&&_intervalId==null){_intervalId=setInterval(_observeHistory,200);}};};$.fn.remote=function(output,settings,callback){callback=callback||function(){};if(typeof settings=='function'){callback=settings;}settings=$.extend({hashPrefix:'remote-'},settings||{});var target=$(output).size()&&$(output)||$('<div></div>').appendTo('body');target.addClass('remote-output');return this.each(function(i){var href=this.href,hash='#'+(this.title&&this.title.replace(/\s/g,'_')||settings.hashPrefix+(i+1)),a=this;this.href=hash;$(this).click(function(e){if(!target['locked']){if(e.clientX){$.ajaxHistory.update(hash);}target.load(href,function(){target['locked']=null;callback.apply(a);});}});});};$.fn.history=function(callback){return this.click(function(e){if(e.clientX){$.ajaxHistory.update(this.hash);}typeof callback=='function'&&callback();});};})(jQuery);