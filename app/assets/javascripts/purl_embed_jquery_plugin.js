// jQuery.XDomainRequest.js | https://github.com/MoonScript/jQuery-ajaxTransport-XDomainRequest
// Implements CORS support for IE8+
if(!jQuery.support.cors&&window.XDomainRequest){var httpRegEx=/^https?:\/\//i;var getOrPostRegEx=/^get|post$/i;var sameSchemeRegEx=new RegExp("^"+location.protocol,"i");var jsonRegEx=/\/json/i;var xmlRegEx=/\/xml/i;jQuery.ajaxTransport("text html xml json",function(e,t,n){if(e.crossDomain&&e.async&&getOrPostRegEx.test(e.type)&&httpRegEx.test(t.url)&&sameSchemeRegEx.test(t.url)){var r=null;var i=(t.dataType||"").toLowerCase();return{send:function(n,s){r=new XDomainRequest;if(/^\d+$/.test(t.timeout)){r.timeout=t.timeout}r.ontimeout=function(){s(500,"timeout")};r.onload=function(){var e="Content-Length: "+r.responseText.length+"\r\nContent-Type: "+r.contentType;var t={code:200,message:"success"};var n={text:r.responseText};try{if(i==="json"||i!=="text"&&jsonRegEx.test(r.contentType)){try{n.json=$.parseJSON(r.responseText)}catch(o){t.code=500;t.message="parseerror"}}else if(i==="xml"||i!=="text"&&xmlRegEx.test(r.contentType)){var u=new ActiveXObject("Microsoft.XMLDOM");u.async=false;try{u.loadXML(r.responseText)}catch(o){u=undefined}if(!u||!u.documentElement||u.getElementsByTagName("parsererror").length){t.code=500;t.message="parseerror";throw"Invalid XML: "+r.responseText}n.xml=u}}catch(a){throw a}finally{s(t.code,t.message,n,e)}};r.onerror=function(){s(500,"error",{text:r.responseText})};var o=t.data&&$.param(t.data)||"";r.open(e.type,e.url);r.send(o)},abort:function(){if(r){r.abort()}}}}})}

(function($) {
  var serverUrls = {
    'test': '//purl-test.stanford.edu',
    'prod': '//purl.stanford.edu',
    'local': 'http://localhost:3000'
  };

  $.fn.embedPurl = function(config) {
    var serverURL = serverUrls[config.server],
        height = parseInt(config.height, 10),
        width = parseInt(config.width, 10),
        $this = $(this);

    if (!isNaN(width)) $this.width(width);
    if (!isNaN(height)) $this.height(height);

    $.ajax({
      type: "GET",
      url: serverURL + '/' + config.druid + '/embed-js',
      contentType: "text/html",
      data: { peContainerWidth: $this.width(), peContainerHeight: $this.height() },
      dataType: "html",

      success: function(html) {
        $.each(['purl_embed', 'zpr'], function(index, value) {
          $('head').append('<link rel="stylesheet" href="' + serverURL + '/stylesheets/' + value + '.css" type="text/css" />')
        });

        $.getScript(serverURL + '/javascripts/zpr.js', function() {
          $.getScript(serverURL + '/javascripts/cselect.js', function() {
            $.getScript(serverURL + '/javascripts/purl_embed.js', function() {
              $this.html(html);
              var pe = new purlEmbed(peImgInfo, pePid, peStacksURL, config, $this.selector);
            });
          });
        });

      },
      error: function(xhr, status, errorThrown) {
        $this.html("Error loading images for " + config.druid);
      }
    });
  };


})(jQuery);
