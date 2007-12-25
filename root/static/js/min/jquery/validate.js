jQuery.extend(jQuery.fn,{validate:function(options){var validator=jQuery.data(this[0],'validator');if(validator){return validator;}validator=new jQuery.validator(options,this[0]);jQuery.data(this[0],'validator',validator);if(validator.settings.onsubmit){this.find("input.cancel:submit").click(function(){validator.cancelSubmit=true;});this.submit(function(event){if(validator.settings.debug)event.preventDefault();function handle(){if(validator.settings.submitHandler){validator.settings.submitHandler.call(validator,validator.currentForm);return false;}return true;}if(validator.cancelSubmit){validator.cancelSubmit=false;return handle();}if(validator.form()){if(this.pendingRequest){this.formSubmitted=true;return false;}return handle();}else{validator.focusInvalid();return false;}});}return validator;},valid:function(){if(jQuery(this[0]).is('form')){return jQuery(this).validate().form();}else{var valid=true;var validator=jQuery(this.form).validate();this.each(function(){valid=validator.element(this)&&valid;});return valid;}},push:function(t){return this.setArray(jQuery.merge(this.get(),t));}});jQuery.extend(jQuery.expr[":"],{blank:"!jQuery.trim(a.value)",filled:"!!jQuery.trim(a.value)",unchecked:"!a.checked"});jQuery.format=function(source,params){if(arguments.length==1)return function(){var args=jQuery.makeArray(arguments);args.unshift(source);return jQuery.format.apply(this,args);};if(arguments.length>2&&params.constructor!=Array){params=jQuery.makeArray(arguments).slice(1);}if(params.constructor!=Array){params=[params];}jQuery.each(params,function(i,n){source=source.replace(new RegExp("\\{"+i+"\\}","g"),n);});return source;};jQuery.validator=function(options,form){this.settings=jQuery.extend({},jQuery.validator.defaults,options);this.currentForm=form;this.labelContainer=jQuery(this.settings.errorLabelContainer);this.errorContext=this.labelContainer.length&&this.labelContainer||jQuery(form);this.containers=jQuery(this.settings.errorContainer).add(this.settings.errorLabelContainer);this.submitted={};this.valueCache={};this.pendingRequest=0;this.invalid={};this.reset();this.refresh();};jQuery.extend(jQuery.validator,{defaults:{messages:{},errorClass:"error",errorElement:"label",focusInvalid:true,errorContainer:jQuery([]),errorLabelContainer:jQuery([]),onsubmit:true,ignore:[],onblur:function(element){if(!this.checkable(element)&&(element.name in this.submitted||!this.optional(element))){this.element(element);}},onkeyup:function(element){if(element.name in this.submitted||element==this.lastElement){this.element(element);}},onclick:function(element){if(element.name in this.submitted)this.element(element);},highlight:function(element,errorClass){jQuery(element).addClass(errorClass);},unhighlight:function(element,errorClass){jQuery(element).removeClass(errorClass);}},setDefaults:function(settings){jQuery.extend(jQuery.validator.defaults,settings);},messages:{required:"This field is required.",remote:"Please fix this field.",email:"Please enter a valid email address.",url:"Please enter a valid URL.",date:"Please enter a valid date.",dateISO:"Please enter a valid date (ISO).",dateDE:"Bitte geben Sie ein gültiges Datum ein.",number:"Please enter a valid number.",numberDE:"Bitte geben Sie eine Nummer ein.",digits:"Please enter only digits",creditcard:"Please enter a valid credit card.",equalTo:"Please enter the same value again.",accept:"Please enter a value with a valid extension.",maxLength:jQuery.format("Please enter a value no longer than {0} characters."),minLength:jQuery.format("Please enter a value of at least {0} characters."),rangeLength:jQuery.format("Please enter a value between {0} and {1} characters long."),rangeValue:jQuery.format("Please enter a value between {0} and {1}."),maxValue:jQuery.format("Please enter a value less than or equal to {0}."),minValue:jQuery.format("Please enter a value greater than or equal to {0}.")},prototype:{form:function(){this.prepareForm();for(var i=0;this.elements[i];i++){this.check(this.elements[i]);}jQuery.extend(this.submitted,this.errorMap);this.invalid=jQuery.extend({},this.errorMap);this.settings.invalidHandler&&this.settings.invalidHandler.call(this);this.showErrors();return this.valid();},element:function(element){element=this.clean(element);this.lastElement=element;this.prepareElement(element);var result=this.check(element);if(result){delete this.invalid[element.name];}else{this.invalid[element.name]=true;}if(!this.numberOfInvalids()){this.toHide.push(this.containers);}this.showErrors();return result;},showErrors:function(errors){if(errors){jQuery.extend(this.errorMap,errors);this.errorList=[];for(name in errors){this.errorList.push({message:errors[name],element:jQuery("[@name='"+name+"']:first",this.currentForm)[0]});}this.successList=jQuery.grep(this.successList,function(element){return!(element.name in errors);});}this.settings.showErrors?this.settings.showErrors.call(this,this.errorMap,this.errorList):this.defaultShowErrors();},resetForm:function(){if(jQuery.fn.resetForm)jQuery(this.currentForm).resetForm();this.prepareForm();this.hideErrors();this.elements.removeClass(this.settings.errorClass);},numberOfInvalids:function(){var count=0;for(i in this.invalid)count++;return count;},hideErrors:function(){this.addWrapper(this.toHide).hide();},valid:function(){return this.size()==0;},size:function(){return this.errorList.length;},focusInvalid:function(){if(this.settings.focusInvalid){try{jQuery(this.findLastActive()||this.errorList.length&&this.errorList[0].element||[]).filter(":visible").focus();}catch(e){}}},findLastActive:function(){var lastActive=this.lastActive;return lastActive&&jQuery.grep(this.errorList,function(n){return n.element.name==lastActive.name;}).length==1&&lastActive;},refresh:function(selection){var validator=this;validator.rulesCache={};function focused(){validator.lastActive=this;if(validator.settings.focusCleanup&&!validator.blockFocusCleanup){jQuery(this).removeClass(validator.settings.errorClass);validator.errorsFor(this).hide();}}if(selection){jQuery(selection).each(function(){if(validator.elements.index(this)>-1){validator.elements.add(this);}validator.rulesCache[this.name]=validator.rules(this);}).focus(focused);}this.elements=jQuery(this.currentForm).find("input, select, textarea").not(":submit, :reset").not("[@disabled]").not(this.settings.ignore).filter(function(){!this.name&&validator.settings.debug&&window.console&&console.error("%o has no name assigned",this);if(this.name in validator.rulesCache||!validator.rules(this).length)return false;validator.rulesCache[this.name]=validator.rules(this);return true;});this.elements.focus(focused);validator.settings.onblur&&validator.elements.blur(function(){validator.settings.onblur.call(validator,this);});validator.settings.onkeyup&&validator.elements.keyup(function(){validator.settings.onkeyup.call(validator,this);});if(validator.settings.onclick){var checkables=jQuery([]);validator.elements.each(function(){if(validator.checkable(this))checkables.push(validator.checkableGroup(this));});checkables.click(function(){validator.settings.onclick.call(validator,this);});}},clean:function(selector){return jQuery(selector)[0];},errors:function(){return jQuery(this.settings.errorElement+"."+this.settings.errorClass,this.errorContext);},reset:function(){this.successList=[];this.errorList=[];this.errorMap={};this.toShow=jQuery([]);this.toHide=jQuery([]);this.formSubmitted=false;},prepareForm:function(){this.reset();this.toHide=this.errors().push(this.containers);},prepareElement:function(element){this.reset();this.toHide=this.errorsFor(this.clean(element));},check:function(element){element=this.clean(element);this.settings.unhighlight.call(this,element,this.settings.errorClass);var rules=this.rulesCache[element.name];for(var i=0;rules[i];i++){var rule=rules[i];try{var result=jQuery.validator.methods[rule.method].call(this,jQuery.trim(element.value),element,rule.parameters);if(result===-1)break;if(!result){this.settings.highlight.call(this,element,this.settings.errorClass);this.formatAndAdd(rule,element);return false;}}catch(e){this.settings.debug&&window.console&&console.warn("exception occured when checking element "+element.id
+", check the '"+rule.method+"' method");throw e;}}if(rules.length&&this.settings.success)this.successList.push(element);return true;},configuredMessage:function(id,method){var m=this.settings.messages[id];return m&&(m.constructor==String?m:m[method]);},defaultMessage:function(element,method){return this.configuredMessage(element.name,method)||element.title||jQuery.validator.messages[method]||"<strong>Warning: No message defined for "+element.name+"</strong>";},formatAndAdd:function(rule,element){var message=this.defaultMessage(element,rule.method);if(typeof message=="function")message=message.call(this,rule.parameters,element);this.errorList.push({message:message,element:element});this.errorMap[element.name]=message;this.submitted[element.name]=message;},addWrapper:function(toToggle){if(this.settings.wrapper)toToggle.push(toToggle.parents(this.settings.wrapper));return toToggle;},defaultShowErrors:function(){for(var i=0;this.errorList[i];i++){var error=this.errorList[i];this.showLabel(error.element,error.message);}if(this.errorList.length){this.toShow.push(this.containers);}for(var i=0;this.successList[i];i++){this.showLabel(this.successList[i]);}this.toHide=this.toHide.not(this.toShow);this.hideErrors();this.addWrapper(this.toShow).show();},showLabel:function(element,message){var label=this.errorsFor(element);if(label.length){label.removeClass().addClass(this.settings.errorClass);if(this.settings.overrideErrors||label.attr("generated")){label.html(message);}}else{label=jQuery("<"+this.settings.errorElement+"/>").attr({"for":this.idOrName(element),generated:true}).addClass(this.settings.errorClass).html(message||"");if(this.settings.wrapper){label=label.hide().show().wrap("<"+this.settings.wrapper+">").parent();}if(!this.labelContainer.append(label).length)this.settings.errorPlacement?this.settings.errorPlacement(label,jQuery(element)):label.insertAfter(element);}if(!message&&this.settings.success){label.text("");typeof this.settings.success=="string"?label.addClass(this.settings.success):this.settings.success(label);}this.toShow.push(label);},errorsFor:function(element){return this.errors().filter("[@for='"+this.idOrName(element)+"']");},idOrName:function(element){return this.checkable(element)?element.name:element.id||element.name;},rules:function(element){var data=this.data(element);if(!data)return[];var rules=[];if(typeof data=="string"){var transformed={};transformed[data]=true;data=transformed;}jQuery.each(data,function(key,value){rules[rules.length]={method:key,parameters:value};});return rules;},data:function(element){return this.settings.rules?this.settings.rules[element.name]:this.settings.meta?jQuery(element).metadata()[this.settings.meta]:jQuery(element).metadata();},checkable:function(element){return/radio|checkbox/i.test(element.type);},checkableGroup:function(element){return jQuery(element.form||document).find('[@name="'+element.name+'"]');},getLength:function(value,element){switch(element.nodeName.toLowerCase()){case'select':return jQuery("option:selected",element).length;case'input':if(this.checkable(element))return this.checkableGroup(element).filter(':checked').length;}return value.length;},depend:function(param,element){if(this.settings.subformRequired){if(this.settings.subformRequired(jQuery(element)))return false;}return this.dependTypes[typeof param]?this.dependTypes[typeof param](param,element):true;},dependTypes:{"boolean":function(param,element){return param;},"string":function(param,element){return!!jQuery(param,element.form).length;},"function":function(param,element){return param(element);}},optional:function(element){return!jQuery.validator.methods.required.call(this,jQuery.trim(element.value),element);},startRequest:function(){this.pendingRequest++;},stopRequest:function(valid){this.pendingRequest--;if(valid&&this.pendingRequest==0&&this.formSubmitted&&this.form()){jQuery(this.currentForm).submit();}}},methods:{required:function(value,element,param){if(!this.depend(param,element))return-1;switch(element.nodeName.toLowerCase()){case'select':var options=jQuery("option:selected",element);return options.length>0&&(element.type=="select-multiple"||(jQuery.browser.msie&&!(options[0].attributes['value'].specified)?options[0].text:options[0].value).length>0);case'input':if(this.checkable(element))return this.getLength(value,element)>0;default:return value.length>0;}},remote:function(value,element,param){if(this.optional(element))return true;var cached=this.valueCache[element.name];if(!cached){this.valueCache[element.name]=cached={old:null,valid:true,message:this.defaultMessage(element,"remote")};}this.settings.messages[element.name].remote=typeof cached.message=="function"?cached.message(value):cached.message;if(cached.old!==value){cached.old=value;var validator=this;this.startRequest();var data={};data[element.name]=value;jQuery.ajax({url:param,mode:"abort",port:"validate",dataType:"json",data:data,success:function(response){if(!response){var errors={};errors[element.name]=validator.defaultMessage(element,"remote");validator.showErrors(errors);}cached.valid=response;validator.stopRequest(response);}});return false;}return cached.valid;},minLength:function(value,element,param){return this.optional(element)||this.getLength(value,element)>=param;},maxLength:function(value,element,param){return this.optional(element)||this.getLength(value,element)<=param;},rangeLength:function(value,element,param){var length=this.getLength(value,element);return this.optional(element)||(length>=param[0]&&length<=param[1]);},minValue:function(value,element,param){return this.optional(element)||value>=param;},maxValue:function(value,element,param){return this.optional(element)||value<=param;},rangeValue:function(value,element,param){return this.optional(element)||(value>=param[0]&&value<=param[1]);},email:function(value,element){return this.optional(element)||/^[^\s,;]+@([^\s.,;]+\.)+[\w-]{2,}$/i.test(value);},url:function(value,element){return this.optional(element)||/^(https?|ftp):\/\/((([A-Za-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\dA-Fa-f][\dA-Fa-f])|[!\$&'\(\)\*\+,;=]|:)*@)?((\[(|(v[\dA-Fa-f]{1,}\.(([A-Za-z]|\d|-|\.|_|~)|[!\$&'\(\)\*\+,;=]|:){1,}))\])|((\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]))|((([A-Za-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([A-Za-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([A-Za-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([A-Za-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)*(([A-Za-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([A-Za-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([A-Za-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([A-Za-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?)(:\d*)?(\/((([A-Za-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\dA-Fa-f][\dA-Fa-f])|[!\$&'\(\)\*\+,;=]|:|@){1,}(\/(([A-Za-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\dA-Fa-f][\dA-Fa-f])|[!\$&'\(\)\*\+,;=]|:|@)*)*)?)?(\?((([A-Za-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\dA-Fa-f][\dA-Fa-f])|[!\$&'\(\)\*\+,;=]|:|@)|[\uE000-\uF8FF]|\/|\?)*)?(\#((([A-Za-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\dA-Fa-f][\dA-Fa-f])|[!\$&'\(\)\*\+,;=]|:|@)|\/|\?)*)?$/i.test(value);},date:function(value,element){return this.optional(element)||!/Invalid|NaN/.test(new Date(value));},dateISO:function(value,element){return this.optional(element)||/^\d{4}[\/-]\d{1,2}[\/-]\d{1,2}$/.test(value);},dateDE:function(value,element){return this.optional(element)||/^\d\d?\.\d\d?\.\d\d\d?\d?$/.test(value);},number:function(value,element){return this.optional(element)||/^-?(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d+)?$/.test(value);},numberDE:function(value,element){return this.optional(element)||/^-?(?:\d+|\d{1,3}(?:\.\d{3})+)(?:,\d+)?$/.test(value);},digits:function(value,element){return this.optional(element)||/^\d+$/.test(value);},creditcard:function(value,element){if(this.optional(element))return true;var nCheck=0,nDigit=0,bEven=false;value=value.replace(/\D/g,"");for(n=value.length-1;n>=0;n--){var cDigit=value.charAt(n);var nDigit=parseInt(cDigit,10);if(bEven){if((nDigit*=2)>9)nDigit-=9;}nCheck+=nDigit;bEven=!bEven;}return(nCheck%10)==0;},accept:function(value,element,param){param=typeof param=="string"?param:"png|jpe?g|gif";return this.optional(element)||value.match(new RegExp(".("+param+")$","i"));},equalTo:function(value,element,param){return value==jQuery(param).val();}},addMethod:function(name,method,message){jQuery.validator.methods[name]=method;jQuery.validator.messages[name]=message;}});